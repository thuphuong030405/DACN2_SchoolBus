// @ts-nocheck  (file chạy trên Deno/Supabase; dòng này chỉ để VS Code không báo lỗi đỏ)
// Supabase Edge Function: gemini-chat
// Nhận lịch sử hội thoại từ app Flutter, gọi Gemini và trả về câu trả lời.
// API key nằm trong Secrets của Supabase, KHÔNG nằm trong app.
//
// Secrets:
//   GEMINI_API_KEY         (bắt buộc)
//   GEMINI_MODEL           (model chính)
//   GEMINI_FALLBACK_MODEL  (tuỳ chọn: model dự phòng khi model chính quá tải)

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.8-flash";
const GEMINI_FALLBACK_MODEL = Deno.env.get("GEMINI_FALLBACK_MODEL");

const MAX_MESSAGES = 20; // chỉ gửi 20 tin gần nhất
const MAX_CHARS = 4000; // giới hạn độ dài mỗi tin

// Mỗi lần gọi chờ tối đa 18 giây; tối đa 2 lần (+1 giây nghỉ) < 45 giây của app.
const ATTEMPT_TIMEOUT_MS = 18000;
const RETRYABLE_STATUS = new Set([500, 502, 503, 504]);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const BASE_PROMPT = `Bạn là trợ lý AI của ứng dụng "Bus An Toàn" - hệ thống điểm danh và theo dõi xe đưa đón học sinh. Người dùng có thể là phụ huynh, giáo viên, tài xế hoặc quản lý nhà trường.

Quy tắc:
- Luôn trả lời bằng tiếng Việt, ngắn gọn, thân thiện, rõ ràng.
- Chỉ hỗ trợ các chủ đề về đưa đón học sinh, điểm danh, an toàn trên xe và cách dùng ứng dụng. Với câu hỏi ngoài phạm vi, hãy lịch sự từ chối và gợi ý quay lại chủ đề chính.
- Bạn KHÔNG có quyền truy cập dữ liệu thật (vị trí xe, danh sách học sinh, lịch chuyến...). Tuyệt đối không bịa số liệu; nếu được hỏi, hướng dẫn người dùng xem trong ứng dụng hoặc liên hệ nhà trường.
- Tình huống khẩn cấp (tai nạn, học sinh bị thương, mất tích): khuyên gọi ngay nhà trường và số khẩn cấp 113, 114 hoặc 115.
- Trả lời bằng văn bản thuần, không dùng markdown (không dùng dấu * hay #). Cần liệt kê thì dùng gạch đầu dòng "-".`;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

type InMessage = { role?: string; text?: string };

/// Gọi Gemini một lần. Trả về { ok: true, data } hoặc { ok: false, status, reason }.
async function callGemini(model: string, payload: unknown) {
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": GEMINI_API_KEY,
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(ATTEMPT_TIMEOUT_MS),
      },
    );

    if (res.ok) {
      return { ok: true, data: await res.json() };
    }

    const detail = await res.text();
    console.error("Gemini error", model, res.status, detail);

    // Lý do lỗi từ Gemini (không chứa API key)
    let reason = "";
    try {
      reason = JSON.parse(detail)?.error?.message ?? "";
    } catch (_) {
      reason = detail;
    }
    return { ok: false, status: res.status, reason: String(reason).slice(0, 300) };
  } catch (e) {
    if (e instanceof DOMException && e.name === "TimeoutError") {
      console.error("Gemini không phản hồi kịp", model);
      return { ok: false, status: 504, reason: "Gemini không phản hồi kịp." };
    }
    throw e;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (!GEMINI_API_KEY) {
      console.error("Thiếu secret GEMINI_API_KEY");
      return json({ error: "Server chưa được cấu hình." }, 500);
    }

    const body = await req.json();
    const messages: InMessage[] = Array.isArray(body?.messages)
      ? body.messages
      : [];
    const userRole = typeof body?.role === "string"
      ? body.role.slice(0, 30)
      : "";

    const contents = messages
      .slice(-MAX_MESSAGES)
      .map((m) => ({
        role: m.role === "model" ? "model" : "user",
        parts: [{ text: String(m.text ?? "").slice(0, MAX_CHARS) }],
      }))
      .filter((c) => c.parts[0].text.trim().length > 0);

    // Gemini yêu cầu lượt đầu tiên phải là của người dùng
    while (contents.length > 0 && contents[0].role !== "user") {
      contents.shift();
    }

    if (contents.length === 0) {
      return json({ error: "Thiếu nội dung tin nhắn." }, 400);
    }

    const systemPrompt = userRole
      ? `${BASE_PROMPT}\n\nNgười dùng hiện tại là: ${userRole}.`
      : BASE_PROMPT;

    const payload = {
      systemInstruction: { parts: [{ text: systemPrompt }] },
      contents,
      generationConfig: { temperature: 0.6, maxOutputTokens: 2048 },
    };

    // Lần 1: model chính. Nếu quá tải / lỗi tạm thời thì thử lại 1 lần
    // (bằng model dự phòng nếu có, không thì cùng model).
    let result = await callGemini(GEMINI_MODEL, payload);
    if (!result.ok && RETRYABLE_STATUS.has(result.status)) {
      await new Promise((r) => setTimeout(r, 1000));
      result = await callGemini(GEMINI_FALLBACK_MODEL || GEMINI_MODEL, payload);
    }

    if (!result.ok) {
      // 429 và 503 (quá tải) báo về app là 429 để app hiện "đang quá tải".
      const overloaded = result.status === 429 || result.status === 503;
      return json(
        {
          error: "Trợ lý đang gặp sự cố.",
          geminiStatus: result.status,
          reason: result.reason,
        },
        overloaded ? 429 : 502,
      );
    }

    const reply: string = (result.data?.candidates?.[0]?.content?.parts ?? [])
      .map((p: { text?: string }) => p.text ?? "")
      .join("")
      .trim();

    if (!reply) {
      return json({
        reply:
          "Xin lỗi, mình chưa trả lời được câu này. Bạn thử hỏi lại theo cách khác nhé.",
      });
    }

    return json({ reply });
  } catch (e) {
    console.error("gemini-chat failed", e);
    return json({ error: "Có lỗi xảy ra." }, 500);
  }
});