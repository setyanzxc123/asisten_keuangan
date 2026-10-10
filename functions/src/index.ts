import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenAI } from "@google/genai";
import { processIntentWithGemini } from "./services/gemini_service";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const geminiApiKey = defineSecret("GEMINI_API_KEY");

export const healthCheck = onCall({ cors: true }, (request) => {
  return {
    status: "ok",
    timestamp: new Date().toISOString(),
    authenticated: Boolean(request.auth?.uid),
    uid: request.auth?.uid ?? null,
  };
});

export function createGeminiClient(apiKey: string): GoogleGenAI {
  if (!apiKey) {
    throw new HttpsError("failed-precondition", "Gemini API key is required");
  }
  return new GoogleGenAI({ apiKey });
}

export const processFinancialIntent = onCall(
  {
    secrets: [geminiApiKey],
    cors: true,
  },
  async (request) => {
    const rawText = request.data?.text;
    if (typeof rawText !== "string" || rawText.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Text prompt is required and cannot be empty.");
    }

    const apiKey = geminiApiKey.value() || process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "GEMINI_API_KEY secret is not configured.");
    }

    const ai = createGeminiClient(apiKey);
    const model = request.data?.model ?? "gemini-3.8-flash";

    try {
      const intentResult = await processIntentWithGemini(ai, rawText.trim(), model);
      return {
        success: true,
        data: intentResult,
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to process financial intent";
      throw new HttpsError("internal", message);
    }
  }
);
