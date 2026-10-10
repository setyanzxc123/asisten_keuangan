import { GoogleGenAI } from "@google/genai";
import { FinancialIntentResponse, financialResponseSchema } from "../schemas/financial_schema";

export const BANKER_SYSTEM_INSTRUCTION = `Anda adalah seorang Penasihat Keuangan Eksekutif (Private Wealth Banker) pribadi yang berdedikasi, cerdas, berwibawa, dan santun.
Tugas Anda adalah menganalisis pesan finansial nasabah, mengekstrak mutasi transaksi secara akurat, atau menjawab konsultasi keuangan dalam Bahasa Indonesia yang profesional.

Aturan Pemrosesan:
1. Jika nasabah menyebut pengeluaran atau pemasukan dengan nominal jelas (melalui teks, rekaman suara, atau foto nota/struk):
   - intent: "RECORD_TRANSACTION"
   - isClarificationNeeded: false
   - Isi objek transaction secara lengkap (title, amount, type: EXPENSE/INCOME, category, paymentMethod).
   - Berikan bankerNarrative yang mengonfirmasi pencatatan dengan bahasa bankir privat elegan.
2. Jika ada ambiguitas kritis (misal foto struk buram, nominal tidak terbaca, atau tanpa nominal jelas):
   - intent: "RECORD_TRANSACTION"
   - isClarificationNeeded: true
   - clarificationQuestion: Tanyakan rincian nominal atau kategori dengan sopan.
   - bankerNarrative: Sampaikan bahwa pencatatan ditangguhkan hingga klarifikasi diterima.
3. Jika nasabah bertanya tentang kondisi finansial atau laporan:
   - intent: "QUERY_REPORT"
   - isClarificationNeeded: false
   - bankerNarrative: Berikan analisis ringkas dan pandangan bijak.
4. Jika percakapan umum:
   - intent: "GENERAL_CHAT"
   - isClarificationNeeded: false
   - bankerNarrative: Tanggapi dengan santun dan ingatkan kesiapan membantu keuangan nasabah.`;

export interface MediaInput {
  mimeType: string;
  data: string;
}

export async function processMultimodalIntentWithGemini(
  ai: GoogleGenAI,
  prompt?: string,
  media?: MediaInput,
  modelName: string = "gemini-3.8-flash"
): Promise<FinancialIntentResponse> {
  const parts: Array<{ inlineData?: { mimeType: string; data: string }; text?: string }> = [];

  if (media) {
    parts.push({
      inlineData: {
        mimeType: media.mimeType,
        data: media.data,
      },
    });
  }

  const defaultPrompt = media?.mimeType.startsWith("audio")
    ? "Dengarkan rekaman suara nasabah ini, ekstrak mutasi transaksi secara terstruktur."
    : "Analisis foto nota struk ini, ekstrak total nominal, nama merchant, dan kategori transaksi secara presisi.";

  parts.push({
    text: prompt?.trim() ? prompt.trim() : defaultPrompt,
  });

  const response = await ai.models.generateContent({
    model: modelName,
    contents: parts,
    config: {
      systemInstruction: BANKER_SYSTEM_INSTRUCTION,
      responseMimeType: "application/json",
      responseJsonSchema: financialResponseSchema,
      temperature: 0.2,
    },
  });

  const responseText = response.text;
  if (!responseText) {
    throw new Error("Empty response from Gemini model");
  }

  const parsed = JSON.parse(responseText) as FinancialIntentResponse;
  return parsed;
}

export async function processIntentWithGemini(
  ai: GoogleGenAI,
  prompt: string,
  modelName: string = "gemini-3.8-flash"
): Promise<FinancialIntentResponse> {
  return processMultimodalIntentWithGemini(ai, prompt, undefined, modelName);
}
