import { Type } from "@google/genai";

export interface TransactionData {
  title: string;
  amount: number;
  type: "EXPENSE" | "INCOME";
  category: string;
  paymentMethod: string;
}

export interface FinancialIntentResponse {
  intent: "RECORD_TRANSACTION" | "QUERY_REPORT" | "GENERAL_CHAT";
  isClarificationNeeded: boolean;
  clarificationQuestion?: string;
  transaction?: TransactionData;
  bankerNarrative: string;
}

export const financialResponseSchema = {
  type: Type.OBJECT,
  properties: {
    intent: {
      type: Type.STRING,
      enum: ["RECORD_TRANSACTION", "QUERY_REPORT", "GENERAL_CHAT"],
      description: "Primary intent identified from user input",
    },
    isClarificationNeeded: {
      type: Type.BOOLEAN,
      description: "True if amount, category, or transaction nature is ambiguous",
    },
    clarificationQuestion: {
      type: Type.STRING,
      description: "Polite question from banker if details are missing",
    },
    transaction: {
      type: Type.OBJECT,
      description: "Structured transaction details when recording expense or income",
      properties: {
        title: { type: Type.STRING, description: "Descriptive label of item or service" },
        amount: { type: Type.NUMBER, description: "Monetary amount in IDR" },
        type: { type: Type.STRING, enum: ["EXPENSE", "INCOME"], description: "Expense or income" },
        category: { type: Type.STRING, description: "Standard category name" },
        paymentMethod: { type: Type.STRING, description: "Payment method detected or default Cash/Transfer" },
      },
    },
    bankerNarrative: {
      type: Type.STRING,
      description: "Courteous Private Wealth Banker response in Indonesian",
    },
  },
  required: ["intent", "isClarificationNeeded", "bankerNarrative"],
};
