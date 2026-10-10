import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenAI } from "@google/genai";
import { processMultimodalIntentWithGemini, MediaInput } from "./services/gemini_service";

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
    const rawText = typeof request.data?.text === "string" ? request.data.text.trim() : "";
    const storagePath = request.data?.storagePath;
    const mediaBase64 = request.data?.mediaBase64;
    const mimeType = request.data?.mimeType;

    let mediaInput: MediaInput | undefined;

    if (typeof storagePath === "string" && storagePath.trim().length > 0) {
      try {
        const bucket = admin.storage().bucket();
        const file = bucket.file(storagePath.trim());
        const [buffer] = await file.download();
        const resolvedMime =
          mimeType ||
          (storagePath.endsWith(".m4a")
            ? "audio/m4a"
            : storagePath.endsWith(".png")
            ? "image/png"
            : "image/jpeg");

        mediaInput = {
          mimeType: resolvedMime,
          data: buffer.toString("base64"),
        };
      } catch (storageErr) {
        throw new HttpsError(
          "not-found",
          `Storage media download error: ${storageErr instanceof Error ? storageErr.message : String(storageErr)}`
        );
      }
    } else if (typeof mediaBase64 === "string" && typeof mimeType === "string") {
      mediaInput = {
        mimeType,
        data: mediaBase64,
      };
    }

    if (!rawText && !mediaInput) {
      throw new HttpsError("invalid-argument", "Text prompt or media file input is required.");
    }

    const apiKey = geminiApiKey.value() || process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "GEMINI_API_KEY secret is not configured.");
    }

    const ai = createGeminiClient(apiKey);
    const model = request.data?.model ?? "gemini-3.8-flash";

    try {
      const intentResult = await processMultimodalIntentWithGemini(
        ai,
        rawText || undefined,
        mediaInput,
        model
      );
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
