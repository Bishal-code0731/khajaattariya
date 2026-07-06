import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// Mirrors khalti-verify: the client only tells us "the payment sheet
// didn't throw" — it can't be trusted to mark an order paid on its own,
// since a client-side crash/tamper/replay could report success for a
// charge Stripe never actually confirmed. This re-checks the
// PaymentIntent's real status directly with Stripe before the caller is
// allowed to treat the payment as completed.
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    }});
  }
  try {
    const { payment_intent_id } = await req.json();
    const secretKey = Deno.env.get("STRIPE_SECRET_KEY");
    if (!secretKey) throw new Error("STRIPE_SECRET_KEY not set");
    if (!payment_intent_id) throw new Error("payment_intent_id is required");

    const resp = await fetch(
      `https://api.stripe.com/v1/payment_intents/${payment_intent_id}`,
      { headers: { Authorization: `Bearer ${secretKey}` } },
    );
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
