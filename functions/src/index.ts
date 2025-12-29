/**
 * Firebase Cloud Functions for Chronicles App
 * Proxies OpenAI API calls to keep API key secure on server-side.
 */

import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import OpenAI from "openai";

// Define the secret for OpenAI API key
const openaiApiKey = defineSecret("OPENAI_API_KEY");

// Set global options for all functions
setGlobalOptions({
  maxInstances: 10,
  region: "us-central1",
});

// Initialize OpenAI client with API key from secret
const getOpenAIClient = (): OpenAI => {
  const apiKey = openaiApiKey.value();
  if (!apiKey) {
    throw new HttpsError(
      "failed-precondition",
      "OpenAI API key not configured"
    );
  }
  return new OpenAI({apiKey});
};

// Model configuration
const MODELS = {
  OCR: "gpt-4o",
  ANALYSIS: "gpt-4o",
  CHAT: "gpt-4o",
  TITLE: "gpt-4o-mini",
  PROMPTS: "gpt-4o",
  WHISPER: "whisper-1",
} as const;

// Type definitions
interface OCRRequest {
  imageBase64: string;
  mimeType?: string;
}

interface AnalysisRequest {
  entries: Array<{
    id: string;
    title: string;
    content: string;
    createdAt: string;
    journalId: string;
  }>;
  journals: Array<{
    id: string;
    name: string;
  }>;
}

interface ChatRequest {
  message: string;
  conversationHistory: Array<{
    role: "user" | "assistant" | "system";
    content: string;
  }>;
  entriesContext?: string;
}

interface TitleRequest {
  content: string;
}

interface PromptRequest {
  recentEntries: Array<{
    content: string;
    createdAt: string;
  }>;
}

interface TranscribeRequest {
  audioBase64: string;
  mimeType?: string;
}

/**
 * Extract text from image using GPT-4o Vision
 */
export const extractTextFromImage = onCall<OCRRequest>(
  {
    cors: true,
    secrets: [openaiApiKey],
  },
  async (request: CallableRequest<OCRRequest>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {imageBase64, mimeType = "image/jpeg"} = request.data;

    if (!imageBase64) {
      throw new HttpsError("invalid-argument", "Image data is required");
    }

    logger.info("OCR request received", {userId: request.auth.uid});

    try {
      const openai = getOpenAIClient();

      const response = await openai.chat.completions.create({
        model: MODELS.OCR,
        messages: [
          {
            role: "system",
            content: "You are an OCR assistant. Extract all text from the " +
              "image exactly as written, preserving formatting and line " +
              "breaks. Return only the extracted text, nothing else.",
          },
          {
            role: "user",
            content: [
              {
                type: "image_url",
                image_url: {
                  url: `data:${mimeType};base64,${imageBase64}`,
                  detail: "high",
                },
              },
              {
                type: "text",
                text: "Extract all text from this image. Preserve the " +
                  "original formatting and line breaks. Return only the " +
                  "extracted text.",
              },
            ],
          },
        ],
        max_tokens: 4096,
        temperature: 0.1,
      });

      const extractedText = response.choices[0]?.message?.content?.trim();

      if (!extractedText) {
        throw new HttpsError("not-found", "No text found in image");
      }

      logger.info("OCR completed successfully", {
        userId: request.auth.uid,
        textLength: extractedText.length,
      });

      return {text: extractedText};
    } catch (error) {
      logger.error("OCR failed", {error, userId: request.auth?.uid});

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", "Failed to extract text from image");
    }
  }
);

/**
 * Analyze journal entries and provide insights
 */
export const analyzeJournals = onCall<AnalysisRequest>(
  {
    cors: true,
    secrets: [openaiApiKey],
  },
  async (request: CallableRequest<AnalysisRequest>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {entries, journals} = request.data;

    if (!entries || entries.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "At least one entry is required"
      );
    }

    logger.info("Analysis request received", {
      userId: request.auth.uid,
      entryCount: entries.length,
    });

    try {
      const openai = getOpenAIClient();

      const journalNames = journals.map((j) => j.name).join(", ");
      const entriesText = entries.map((e) =>
        `[${e.createdAt}] ${e.title}\n${e.content}`
      ).join("\n\n---\n\n");

      const systemPrompt = "You are a thoughtful journaling companion and " +
        "analyst. Analyze the user's journal entries and provide meaningful " +
        "insights. Be warm, supportive, and insightful. Focus on:\n" +
        "1. Key themes and patterns across entries\n" +
        "2. Emotional trends and wellbeing indicators\n" +
        "3. Progress on goals or personal growth\n" +
        "4. Actionable suggestions for deeper reflection\n" +
        "Format your response with clear sections using markdown headers.";

      const response = await openai.chat.completions.create({
        model: MODELS.ANALYSIS,
        messages: [
          {
            role: "system",
            content: systemPrompt,
          },
          {
            role: "user",
            content: `Please analyze these ${entries.length} journal ` +
              `entries from: ${journalNames}\n\n${entriesText}`,
          },
        ],
        max_tokens: 2048,
        temperature: 0.7,
      });

      const analysis = response.choices[0]?.message?.content?.trim();

      if (!analysis) {
        throw new HttpsError("internal", "Failed to generate analysis");
      }

      logger.info("Analysis completed successfully", {
        userId: request.auth.uid,
      });

      return {analysis};
    } catch (error) {
      logger.error("Analysis failed", {error, userId: request.auth?.uid});

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", "Failed to analyze journals");
    }
  }
);

/**
 * Generate AI chat response
 */
export const generateChatResponse = onCall<ChatRequest>(
  {
    cors: true,
    secrets: [openaiApiKey],
  },
  async (request: CallableRequest<ChatRequest>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {message, conversationHistory, entriesContext} = request.data;

    if (!message) {
      throw new HttpsError("invalid-argument", "Message is required");
    }

    logger.info("Chat request received", {userId: request.auth.uid});

    try {
      const openai = getOpenAIClient();

      const basePrompt = "You are a thoughtful AI companion for a journaling " +
        "app. Be warm, empathetic, and helpful. Help users reflect on their " +
        "thoughts and feelings.";

      const systemMessage = entriesContext ?
        basePrompt + " You have access to the user's journal entries to " +
          "provide personalized insights and support. Here is context from " +
          "the user's journals:\n\n" + entriesContext :
        basePrompt;

      const messages: OpenAI.ChatCompletionMessageParam[] = [
        {role: "system", content: systemMessage},
        ...conversationHistory.map((msg) => ({
          role: msg.role as "user" | "assistant" | "system",
          content: msg.content,
        })),
        {role: "user", content: message},
      ];

      const response = await openai.chat.completions.create({
        model: MODELS.CHAT,
        messages,
        max_tokens: 1024,
        temperature: 0.8,
      });

      const reply = response.choices[0]?.message?.content?.trim();

      if (!reply) {
        throw new HttpsError("internal", "Failed to generate response");
      }

      logger.info("Chat response generated", {userId: request.auth.uid});

      return {response: reply};
    } catch (error) {
      logger.error("Chat failed", {error, userId: request.auth?.uid});

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", "Failed to generate chat response");
    }
  }
);

/**
 * Generate title for journal entry
 */
export const generateTitle = onCall<TitleRequest>(
  {
    cors: true,
    secrets: [openaiApiKey],
  },
  async (request: CallableRequest<TitleRequest>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {content} = request.data;

    if (!content || content.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Content is required");
    }

    logger.info("Title generation request", {userId: request.auth.uid});

    try {
      const openai = getOpenAIClient();

      const response = await openai.chat.completions.create({
        model: MODELS.TITLE,
        messages: [
          {
            role: "system",
            content: "Generate a concise, meaningful title (max 50 " +
              "characters) for a journal entry. Return only the title, " +
              "nothing else. Do not use quotation marks.",
          },
          {
            role: "user",
            content: "Generate a title for this journal entry:\n\n" +
              content.substring(0, 1000),
          },
        ],
        max_tokens: 50,
        temperature: 0.7,
      });

      let title = response.choices[0]?.message?.content?.trim() || "";

      // Remove any quotes if present
      title = title.replace(/^["']|["']$/g, "");

      // Truncate if still too long
      if (title.length > 50) {
        title = title.substring(0, 47) + "...";
      }

      if (!title) {
        throw new HttpsError("internal", "Failed to generate title");
      }

      logger.info("Title generated", {userId: request.auth.uid});

      return {title};
    } catch (error) {
      logger.error("Title generation failed", {
        error,
        userId: request.auth?.uid,
      });

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", "Failed to generate title");
    }
  }
);

/**
 * Generate personalized journal prompt
 */
export const generatePersonalizedPrompt = onCall<PromptRequest>(
  {
    cors: true,
    secrets: [openaiApiKey],
  },
  async (request: CallableRequest<PromptRequest>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {recentEntries} = request.data;

    logger.info("Prompt generation request", {
      userId: request.auth.uid,
      entryCount: recentEntries?.length || 0,
    });

    try {
      const openai = getOpenAIClient();

      let context = "";
      if (recentEntries && recentEntries.length > 0) {
        context = "Based on the user's recent journal themes:\n" +
          recentEntries.map((e) => e.content.substring(0, 200)).join("\n---\n");
      }

      const systemPrompt = "You are a journaling prompt generator. Create " +
        "thoughtful, introspective prompts that encourage self-reflection " +
        "and personal growth.\n\nReturn a JSON object with this exact " +
        "structure:\n{\n  \"prompt\": \"The main prompt question " +
        "(compelling and thought-provoking)\",\n  \"category\": \"One of: " +
        "gratitude, reflection, growth, creativity, relationships, goals, " +
        "mindfulness\",\n  \"followUp\": \"A follow-up question to dig " +
        "deeper\"\n}";

      const userPrompt = context ?
        "Generate a personalized journal prompt. " + context :
        "Generate an engaging journal prompt for self-reflection.";

      const response = await openai.chat.completions.create({
        model: MODELS.PROMPTS,
        messages: [
          {
            role: "system",
            content: systemPrompt,
          },
          {
            role: "user",
            content: userPrompt,
          },
        ],
        max_tokens: 300,
        temperature: 0.9,
        response_format: {type: "json_object"},
      });

      const responseContent = response.choices[0]?.message?.content;

      if (!responseContent) {
        throw new HttpsError("internal", "Failed to generate prompt");
      }

      const promptData = JSON.parse(responseContent);

      logger.info("Prompt generated", {userId: request.auth.uid});

      return promptData;
    } catch (error) {
      logger.error("Prompt generation failed", {
        error,
        userId: request.auth?.uid,
      });

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "Failed to generate personalized prompt"
      );
    }
  }
);

/**
 * Transcribe audio using Whisper API
 */
export const transcribeAudio = onCall<TranscribeRequest>(
  {
    cors: true,
    secrets: [openaiApiKey],
  },
  async (request: CallableRequest<TranscribeRequest>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {audioBase64, mimeType = "audio/m4a"} = request.data;

    if (!audioBase64) {
      throw new HttpsError("invalid-argument", "Audio data is required");
    }

    logger.info("Transcription request received", {userId: request.auth.uid});

    try {
      const openai = getOpenAIClient();

      // Convert base64 to buffer
      const audioBuffer = Buffer.from(audioBase64, "base64");

      // Create a File-like object for the OpenAI API
      const audioFile = new File([audioBuffer], "audio.m4a", {type: mimeType});

      const response = await openai.audio.transcriptions.create({
        model: MODELS.WHISPER,
        file: audioFile,
        language: "en",
        response_format: "text",
      });

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const transcription = (response as any).text || String(response);

      if (!transcription) {
        throw new HttpsError("not-found", "No speech detected in audio");
      }

      logger.info("Transcription completed", {
        userId: request.auth.uid,
        textLength: transcription.length,
      });

      return {transcription};
    } catch (error) {
      logger.error("Transcription failed", {error, userId: request.auth?.uid});

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", "Failed to transcribe audio");
    }
  }
);

/**
 * Health check endpoint
 */
export const healthCheck = onRequest(
  {cors: true},
  (req, res) => {
    logger.info("Health check");
    res.status(200).json({
      status: "ok",
      timestamp: new Date().toISOString(),
      models: MODELS,
    });
  }
);
