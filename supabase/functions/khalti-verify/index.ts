import { adminClient, callerUser, corsHeaders, fail, json, KHALTI_BASE, khaltiKey } from "../_shared/common.ts";

const FAILED_STATUSES = new Set(["Expired", "User canceled", "Refunded"]);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders(req) });
  if (req.method !== "POST") return fail(req, 405, "method_not_allowed");

  const user = await callerUser(req);
  if (!user) return fail(req, 401, "not_signed_in");

  let pidx: unknown;
  try {
    ({ pidx } = await req.json());
  } catch (_) {
    return fail(req, 400, "invalid_body");
  }
  if (typeof pidx !== "string" || !/^[A-Za-z0-9]{8,64}$/.test(pidx)) return fail(req, 400, "invalid_pidx");

  const db = adminClient();
  const { data: payments, error: payErr } = await db
    .from("payments")
    .select("id, order_id, customer_id, amount, status")
    .eq("method", "khalti")
    .eq("gateway_ref", pidx);
  if (payErr) return fail(req, 500, "lookup_failed", payErr);
  if (!payments || payments.length === 0) return fail(req, 404, "payment_not_found");
  if (payments.some((p) => p.customer_id !== user.id)) return fail(req, 404, "payment_not_found");

  // Already confirmed earlier → nothing to do.
  if (payments.every((p) => p.status === "completed")) return json(req, { status: "Completed", confirmed: true });

  let lookup: Record<string, unknown>;
  try {
    const resp = await fetch(`${KHALTI_BASE}/epayment/lookup/`, {
      method: "POST",
      headers: { Authorization: `Key ${khaltiKey()}`, "Content-Type": "application/json" },
      body: JSON.stringify({ pidx }),
    });
    lookup = await resp.json();
    if (!resp.ok) return fail(req, 502, "gateway_error", lookup);
  } catch (e) {
    return fail(req, 502, "gateway_unreachable", e);
  }

  const status = String(lookup.status ?? "");
  const pending = payments.filter((p) => p.status === "pending");

  if (status === "Completed") {
    const expected = pending.reduce((sum, p) => sum + Math.round(Number(p.amount) * 100), 0);
    const paid = Number(lookup.total_amount);
    if (!Number.isFinite(paid) || paid !== expected) {
      // Never mark paid when the amounts don't match — needs a human look.
      console.error("amount_mismatch", { pidx, expected, paid });
      return json(req, { status, confirmed: false, error: "amount_mismatch" }, 409);
    }
    const ids = pending.map((p) => p.id);
    const orderIds = pending.map((p) => p.order_id);
    const { error: upErr } = await db
      .from("payments")
      .update({ status: "completed", gateway_payload: lookup })
      .in("id", ids)
      .eq("status", "pending");
    if (upErr) return fail(req, 500, "update_failed", upErr);
    const { error: orderErr } = await db.from("orders").update({ payment_status: "paid" }).in("id", orderIds);
    if (orderErr) return fail(req, 500, "update_failed", orderErr);
    await db.from("payment_logs").insert(ids.map((id) => ({ payment_id: id, event: "verified", payload: lookup })));
    return json(req, { status, confirmed: true });
  }

  if (FAILED_STATUSES.has(status) && pending.length > 0) {
    await db
      .from("payments")
      .update({ status: status === "Expired" ? "expired" : "failed", gateway_payload: lookup })
      .in("id", pending.map((p) => p.id))
      .eq("status", "pending");
  }
  return json(req, { status, confirmed: false });
});
