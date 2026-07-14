// supabase/functions/scan-receipt/index.ts
//
// Alur:
// 1. Verifikasi user yang manggil sudah login (pakai token Authorization).
// 2. Terima foto struk (base64) dari body request.
// 3. Kirim ke Gemini API dengan responseSchema, minta balik JSON
//    terstruktur (merchant_name, receipt_date, items).
// 4. Balikin JSON itu ke Flutter.

import { createClient } from "jsr:@supabase/supabase-js@2";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY")!;
// Pakai alias "-latest", bukan nomor versi spesifik (mis. gemini-2.5-flash),
// supaya otomatis ikut versi terbaru dan tidak perlu update kode tiap kali
// Google merilis model baru / deprecate model lama.
const GEMINI_MODEL = "gemini-flash-lite-latest";
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

// Skema JSON yang WAJIB diikuti Gemini saat menjawab.
// Disesuaikan persis dengan struktur receipts + receipt_items di database.
const RECEIPT_SCHEMA = {
  type: "OBJECT",
  properties: {
    merchant_name: {
      type: "STRING",
      description: "Nama toko/merchant yang tertera di struk",
    },
    receipt_date: {
      type: "STRING",
      description: "Tanggal transaksi, format YYYY-MM-DD. Kosongkan string jika tidak terbaca.",
    },
    items: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          item_name: { type: "STRING", description: "Nama barang" },
          qty: { type: "NUMBER", description: "Jumlah barang, default 1 jika tidak tertera" },
          unit_price: { type: "NUMBER", description: "Harga satuan per barang, dalam Rupiah" },
        },
        required: ["item_name", "qty", "unit_price"],
      },
    },
  },
  required: ["merchant_name", "items"],
};

const PROMPT = `
Kamu adalah asisten yang membaca struk belanja Indonesia dari foto.
Ekstrak informasi berikut dari gambar struk yang diberikan:
- Nama merchant/toko
- Tanggal transaksi (format YYYY-MM-DD)
- Daftar barang: nama barang, qty, dan harga satuan (unit_price)

Aturan penting:
- unit_price adalah harga PER SATUAN barang, bukan harga total baris.
  Jika struk hanya menampilkan harga total per baris, hitung mundur:
  unit_price = harga_total_baris / qty.
- Abaikan baris yang bukan barang, seperti "SUBTOTAL", "PPN", "PAJAK",
  "TOTAL", "TUNAI", "KEMBALI", nomor struk, dll.
- Jika qty tidak tertera secara eksplisit, asumsikan 1.
- Jika ada baris diskon yang menempel ke 1 barang, kurangkan ke unit_price
  barang tersebut.
- Jika tanggal tidak terbaca jelas, kembalikan string kosong "".
`.trim();

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // Preflight (dibutuhkan kalau nanti dipanggil dari web/Flutter web)
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ---------------------------------------------------------
    // 1. Verifikasi user sudah login, biar endpoint ini tidak
    //    bisa dipakai sembarangan orang buat "gratisan" kuota AI.
    // ---------------------------------------------------------
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Unauthorized: token tidak ditemukan." }, 401);
    }

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: userData, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !userData.user) {
      return jsonResponse({ error: "Unauthorized: token tidak valid." }, 401);
    }

    // ---------------------------------------------------------
    // 2. Ambil foto dari body request.
    // ---------------------------------------------------------
    const body = await req.json();
    const imageBase64: string | undefined = body.image_base64;
    const mimeType: string = body.mime_type ?? "image/jpeg";

    if (!imageBase64) {
      return jsonResponse({ error: "image_base64 wajib diisi." }, 400);
    }

    // ---------------------------------------------------------
    // 3. Panggil Gemini API dengan responseSchema.
    // ---------------------------------------------------------
    const geminiResponse = await fetch(GEMINI_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY,
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: PROMPT },
              { inline_data: { mime_type: mimeType, data: imageBase64 } },
            ],
          },
        ],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: RECEIPT_SCHEMA,
        },
      }),
    });

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      console.error("Gemini API error:", errText);
      return jsonResponse(
        { error: "Gagal memproses gambar dengan AI. Coba lagi." },
        502,
      );
    }

    const geminiJson = await geminiResponse.json();
    const rawText = geminiJson.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!rawText) {
      return jsonResponse({ error: "AI tidak mengembalikan hasil." }, 502);
    }

    // rawText sudah dijamin berupa JSON string sesuai RECEIPT_SCHEMA
    const parsed = JSON.parse(rawText);

    return jsonResponse({ data: parsed }, 200);
  } catch (err) {
    console.error("Unexpected error:", err);
    return jsonResponse({ error: "Terjadi kesalahan tak terduga." }, 500);
  }
});

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}