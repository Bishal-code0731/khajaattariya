import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// SANDBOX URL — change to https://a.khalti.com/api/v2 for production
const KHALTI_BASE = "https://a.khalti.com/api/v2";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    }});
  }
  try {
    const { order_id, amount, purchase_order_name, return_url, website_url } = await req.json();
    const secretKey = Deno.env.get("KHALTI_SECRET_KEY");
    if (!secretKey) throw new Error("KHALTI_SECRET_KEY not set");

    const resp = await fetch(`${KHALTI_BASE}/epayment/initiate/`, {
      method: "POST",
      headers: { Authorization: `Key ${secretKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        return_url, website_url, amount,
        purchase_order_id: order_id,
        purchase_order_name: purchase_order_name ?? "KhajaAttariya Order",
      }),
    });

    const data = await resp.json();
    return new Response(JSON.stringify(data), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});