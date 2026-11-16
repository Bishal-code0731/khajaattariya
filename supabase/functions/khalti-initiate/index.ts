// Starts a Khalti payment for a customer's unpaid order(s).
import { adminClient, callerUser, corsHeaders, fail, json, KHALTI_BASE, khaltiKey } from "../_shared/common.ts";

// Where Khalti may send the customer back to.
const APP_RETURN = "khajaattariya://payment/khalti-callback";
const allowedReturnOrigins = (Deno.env.get("ALLOWED_RETURN_ORIGINS") ?? "")
  .split(",").map((o) => o.trim()).filter(Boolean);
const WEBSITE_URL = Deno.env.get("WEBSITE_URL") ?? "https://khajaattariya.com";

function safeReturnUrl(requested: unknown): string {
  if (typeof requested !== "string") return APP_RETURN;
  if (requested === APP_RETURN) return requested;
  try {
    const url = new URL(requested);
    if (allowedReturnOrigins.includes(url.origin)) return requested;
  } catch (_) { /* fall through */ }
  return APP_RETURN;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders(req) });
  if (req.method !== "POST") return fail(req, 405, "method_not_allowed");

  const user = await callerUser(req);
  if (!user) return fail(req, 401, "not_signed_in");

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch (_) {
    return fail(req, 400, "invalid_body");
  }
  const primaryId = typeof body.order_id === "string" ? body.order_id : null;
  if (!primaryId) return fail(req, 400, "order_required");

  const db = adminClient();
  const { data: primary, error: primaryErr } = await db
    .from("orders")
    .select("id, checkout_id, customer_id")
    .eq("id", primaryId)
    .maybeSingle();
  if (primaryErr) return fail(req, 500, "lookup_failed", primaryErr);
  if (!primary || primary.customer_id !== user.id) return fail(req, 404, "order_not_found");

  const { data: orders, error: ordersErr } = await db
    .from("orders")
    .select("id, total_amount, payment_status, status")
    .eq("checkout_id", primary.checkout_id)
    .eq("customer_id", user.id);
  if (ordersErr) return fail(req, 500, "lookup_failed", ordersErr);

  const payable = (orders ?? []).filter((o) => o.payment_status !== "paid" && o.status !== "cancelled");
  if (payable.length === 0) return fail(req, 409, "nothing_to_pay");

  const amountPaisa = payable.reduce((sum, o) => sum + Math.round(Number(o.total_amount) * 100), 0);
  if (amountPaisa < 1000) return fail(req, 400, "amount_too_small"); // Khalti minimum: Rs 10

  let khalti: Response;
  try {
    khalti = await fetch(`${KHALTI_BASE}/epayment/initiate/`, {
      method: "POST",
      headers: { Authorization: `Key ${khaltiKey()}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        return_url: safeReturnUrl(body.return_url),
        website_url: WEBSITE_URL,
        amount: amountPaisa,
        purchase_order_id: primary.checkout_id,
        purchase_order_name: typeof body.purchase_order_name === "string"
          ? body.purchase_order_name.slice(0, 100)
          : "Khaja Attariya order",
      }),
    });
  } catch (e) {
    return fail(req, 502, "gateway_unreachable", e);
  }

  const data = await khalti.json().catch(() => ({}));
  if (!khalti.ok || typeof data.pidx !== "string") return fail(req, 502, "gateway_error", data);

  return json(req, {
    pidx: data.pidx,
    payment_url: data.payment_url,
    expires_at: data.expires_at,
    amount: amountPaisa,
    order_ids: payable.map((o) => o.id),
  });
});
