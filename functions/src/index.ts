import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenAI } from "@google/genai";

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
