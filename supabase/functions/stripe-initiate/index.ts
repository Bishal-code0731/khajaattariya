import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    }});
  }
  try {
    const { order_id, amount, currency, customer_email } = await req.json();
    const secretKey = Deno.env.get("STRIPE_SECRET_KEY");
    if (!secretKey) throw new Error("STRIPE_SECRET_KEY not set");
    // amount must be in smallest unit — paisa for NPR, cents for USD
    const params = new URLSearchParams({
      amount: String(amount),
      currency: currency ?? "usd",
      "metadata[order_id]": order_id,
      ...(customer_email ? { receipt_email: customer_email } : {}),
    });
    const resp = await fetch("https://api.stripe.com/v1/payment_intents", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${secretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params.toString(),
    });
    const data = await resp.json();
    // Returns { id, client_secret, ... }
    return new Response(JSON.stringify(data), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});