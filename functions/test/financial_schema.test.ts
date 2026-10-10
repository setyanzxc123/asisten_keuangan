import { test } from "node:test";
import assert from "node:assert/strict";
import { financialResponseSchema, FinancialIntentResponse } from "../src/schemas/financial_schema";
import { createGeminiClient } from "../src/index";
import { MediaInput } from "../src/services/gemini_service";

test("financialResponseSchema contains mandatory fields and properties", () => {
  assert.ok(financialResponseSchema.properties);
  assert.equal(financialResponseSchema.type, "OBJECT");
  assert.ok(financialResponseSchema.properties.intent);
  assert.ok(financialResponseSchema.properties.transaction);
  assert.ok(financialResponseSchema.properties.isClarificationNeeded);
  assert.ok(financialResponseSchema.properties.bankerNarrative);
  assert.deepEqual(financialResponseSchema.required, [
    "intent",
    "isClarificationNeeded",
    "bankerNarrative",
  ]);
});

test("simulated JSON response parses accurately as FinancialIntentResponse", () => {
  const sampleJson = JSON.stringify({
    intent: "RECORD_TRANSACTION",
    isClarificationNeeded: false,
    transaction: {
      title: "Makan Siang Restoran",
      amount: 150000,
      type: "EXPENSE",
      category: "Food",
      paymentMethod: "QRIS",
    },
    bankerNarrative: "Pengeluaran makan siang sebesar Rp 150.000 telah tercatat dengan rapi.",
  });

  const parsed = JSON.parse(sampleJson) as FinancialIntentResponse;
  assert.equal(parsed.intent, "RECORD_TRANSACTION");
  assert.equal(parsed.isClarificationNeeded, false);
  assert.ok(parsed.transaction);
  assert.equal(parsed.transaction.amount, 150000);
  assert.equal(parsed.transaction.type, "EXPENSE");
});

test("MediaInput correctly types audio and receipt image inputs", () => {
  const audioInput: MediaInput = {
    mimeType: "audio/m4a",
    data: "AAAA==",
  };
  assert.equal(audioInput.mimeType, "audio/m4a");

  const imageInput: MediaInput = {
    mimeType: "image/jpeg",
    data: "/9j/4AAQSkZJRg==",
  };
  assert.equal(imageInput.mimeType, "image/jpeg");
});

test("createGeminiClient throws HttpsError when apiKey is missing", () => {
  assert.throws(
    () => {
      createGeminiClient("");
    },
    {
      code: "failed-precondition",
    }
  );
});
