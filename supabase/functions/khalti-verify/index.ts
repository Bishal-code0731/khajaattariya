import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const KHALTI_BASE = "https://a.khalti.com/api/v2"; // sandbox

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    }});
  }
  try {
    const { pidx } = await req.json();
    const secretKey = Deno.env.get("KHALTI_SECRET_KEY");
    if (!secretKey) throw new Error("KHALTI_SECRET_KEY not set");

    const resp = await fetch(`${KHALTI_BASE}/epayment/lookup/`, {
      method: "POST",
      headers: { Authorization: `Key ${secretKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ pidx }),
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