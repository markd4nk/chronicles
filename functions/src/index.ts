/**
 * Firebase Cloud Functions for Chronicles App
 * Proxies OpenAI API calls to keep API key secure on server-side.
 */

import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError, CallableRequest, onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import OpenAI from "openai";
import * as admin from "firebase-admin";
import axios from "axios";
import * as cheerio from "cheerio";

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

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

      const systemPrompt = "You are a thoughtful journaling companion. " +
        "After reading the user's journal entries, provide a brief " +
        "1-paragraph summary (3-4 sentences max) of the overall patterns " +
        "or themes you notice. Be warm, curious, and conversational - " +
        "not analytical. Then, end with an engaging open-ended question " +
        "to start a conversation about their thoughts, feelings, or " +
        "experiences. The goal is to start a dialogue, not provide a " +
        "comprehensive analysis. Do NOT use markdown headers or bullet " +
        "points. Write naturally as if starting a friendly conversation. " +
        "Format: [Brief summary paragraph] [Engaging question]";

      const response = await openai.chat.completions.create({
        model: MODELS.ANALYSIS,
        messages: [
          {
            role: "system",
            content: systemPrompt,
          },
          {
            role: "user",
            content: `I'd like to reflect on these ${entries.length} journal ` +
              `entries from: ${journalNames}\n\n${entriesText}`,
          },
        ],
        max_tokens: 500,
        temperature: 0.8,
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

      const basePrompt = "You are a thoughtful conversational companion " +
        "helping a user reflect on their journal entries. Be warm, curious, " +
        "and conversational. Ask follow-up questions to help them explore " +
        "their thoughts. Keep responses concise (2-3 paragraphs max). " +
        "Be a good listener and help them discover insights themselves.";

      const systemMessage = entriesContext ?
        basePrompt + "\n\nYou have access to the user's journal entries. " +
          "Reference specific entries, dates, or patterns naturally when " +
          "relevant (e.g., 'In your entry from...' or 'You mentioned...'). " +
          "Use this context to make the conversation personal and meaningful:" +
          "\n\n" + entriesContext :
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

// Type definition for delete conversation request
interface DeleteConversationRequest {
  conversationId: string;
}

/**
 * Delete a conversation and all its messages (subcollection)
 * Uses batch deletion to safely remove all messages before deleting the conversation
 */
export const deleteConversation = onCall<DeleteConversationRequest>(
  {
    cors: true,
  },
  async (request: CallableRequest<DeleteConversationRequest>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {conversationId} = request.data;

    if (!conversationId) {
      throw new HttpsError("invalid-argument", "Conversation ID is required");
    }

    logger.info("Delete conversation request", {
      userId: request.auth.uid,
      conversationId,
    });

    try {
      const conversationRef = db.collection("conversations").doc(conversationId);
      const conversationDoc = await conversationRef.get();

      if (!conversationDoc.exists) {
        throw new HttpsError("not-found", "Conversation not found");
      }

      const conversationData = conversationDoc.data();
      if (conversationData?.userId !== request.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "Not authorized to delete this conversation"
        );
      }

      // Delete all messages in subcollection (batch delete in chunks of 500)
      const messagesRef = conversationRef.collection("messages");
      let deletedCount = 0;
      let hasMore = true;

      while (hasMore) {
        const snapshot = await messagesRef.limit(500).get();
        if (snapshot.empty) {
          hasMore = false;
        } else {
          const batch = db.batch();
          snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });
          await batch.commit();
          deletedCount += snapshot.size;
          logger.info(`Deleted ${deletedCount} messages so far...`);
        }
      }

      // Delete conversation document
      await conversationRef.delete();

      logger.info("Conversation deleted successfully", {
        userId: request.auth.uid,
        conversationId,
        messagesDeleted: deletedCount,
      });

      return {
        success: true,
        messagesDeleted: deletedCount,
      };
    } catch (error) {
      logger.error("Delete conversation failed", {
        error,
        userId: request.auth?.uid,
      });

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", "Failed to delete conversation");
    }
  }
);

/**
 * Seed prompts from JournalBuddies and Wikiquote
 * Processes in batches to avoid timeouts
 */
export const seedPrompts = onRequest(
  {
    cors: true,
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (req, res) => {
    logger.info("Starting prompt seeding process");

    try {
      // Check if we should only seed quotes (preserve existing questions)
      const quotesOnly = req.query.quotesOnly === "true";
      const seenPrompts = new Set<string>();
      let existingQuestions: PromptData[] = [];

      if (quotesOnly) {
        // Preserve existing questions - only replace quotes
        logger.info("Quotes-only mode: preserving existing questions");

        // Get all existing questions
        const questionsSnapshot = await db.collection("prompts")
          .where("category", "!=", "quote")
          .get();

        existingQuestions = questionsSnapshot.docs.map((doc) => {
          const data = doc.data();
          seenPrompts.add(normalizeText(data.question as string));
          return {
            id: doc.id,
            question: data.question as string,
            hint: data.hint as string,
            category: data.category as string,
            createdAt: data.createdAt,
            likes: data.likes as number,
            shares: data.shares as number,
            isLiked: data.isLiked as boolean,
          };
        });
        logger.info(`Preserved ${existingQuestions.length} existing questions`);

        // Delete only quotes
        let deletedQuotes = 0;
        let hasMore = true;
        while (hasMore) {
          const snapshot = await db.collection("prompts")
            .where("category", "==", "quote")
            .limit(500)
            .get();
          if (snapshot.empty) {
            hasMore = false;
          } else {
            const batch = db.batch();
            snapshot.docs.forEach((doc) => {
              batch.delete(doc.ref);
            });
            await batch.commit();
            deletedQuotes += snapshot.size;
            logger.info(`Deleted ${deletedQuotes} quotes so far...`);
          }
        }
        logger.info(`Total deleted quotes: ${deletedQuotes}`);
      } else {
        // Check if prompts already exist
        const existingPrompts = await db.collection("prompts").limit(1).get();
        if (!existingPrompts.empty && req.query.force !== "true") {
          logger.info("Prompts already exist. Use ?force=true to reseed or ?quotesOnly=true to only replace quotes");
          res.status(200).json({
            status: "skipped",
            message: "Prompts already exist. Use ?force=true to reseed or ?quotesOnly=true to only replace quotes",
          });
          return;
        }

        if (req.query.force === "true") {
          logger.info("Force reseed requested, clearing existing prompts");
          // Delete ALL existing prompts in batches
          let deletedCount = 0;
          let hasMore = true;
          while (hasMore) {
            const snapshot = await db.collection("prompts").limit(500).get();
            if (snapshot.empty) {
              hasMore = false;
            } else {
              const batch = db.batch();
              snapshot.docs.forEach((doc) => {
                batch.delete(doc.ref);
              });
              await batch.commit();
              deletedCount += snapshot.size;
              logger.info(`Deleted ${deletedCount} prompts so far...`);
            }
          }
          logger.info(`Total deleted: ${deletedCount} prompts`);
        }
      }

      // Reset the ID counter for fresh seeding
      promptIdCounter = 0;

      // Target: ~80% questions, ~20% statements (flexible, keep all quality content)
      const allPrompts: PromptData[] = [...existingQuestions];

      // STEP 1: Scrape ALL quality STATEMENTS/QUOTES from curated list
      logger.info("Scraping quality statements/quotes from curated philosophers list...");

      // Scrape Wikiquote for statements - keep ALL quality quotes
      const wikiquotePrompts = await scrapeWikiquote();
      logger.info(`Scraped ${wikiquotePrompts.length} quotes from Wikiquote`);

      // Collect all new statements for response
      const newStatements: Array<{id: string; quote: string; author: string}> = [];

      // Add ALL scraped quotes (no artificial limit)
      wikiquotePrompts.forEach((p) => {
        const normalized = normalizeText(p.question);
        if (!seenPrompts.has(normalized)) {
          seenPrompts.add(normalized);
          allPrompts.push(p);
          // Extract author from hint (format: "- Author Name")
          const author = p.hint.replace(/^-\s*/, "").trim();
          newStatements.push({id: p.id, quote: p.question, author});
        }
      });

      // Add curated quotes if we got very few from scraping
      if (newStatements.length < 20) {
        const curatedQuotes = generateCuratedQuotes(50 - newStatements.length, seenPrompts);
        curatedQuotes.forEach((p) => {
          allPrompts.push(p);
          const author = p.hint.replace(/^-\s*/, "").trim();
          newStatements.push({id: p.id, quote: p.question, author});
        });
      }

      const totalStatements = newStatements.length;
      logger.info(`Total new statements: ${totalStatements}`);

      // STEP 2: If not quotesOnly mode, generate questions too
      let totalQuestions = existingQuestions.length;

      if (!quotesOnly) {
        // For 80/20 ratio: questions = statements * 4
        const targetQuestions = Math.max(Math.ceil(totalStatements * 4), 200); // At least 200 questions
        logger.info(`Generating ~${targetQuestions} questions to achieve 80/20 ratio...`);

        // Scrape JournalBuddies for questions first
        const journalBuddiesPrompts = await scrapeJournalBuddies();
        const scrapedQuestions = journalBuddiesPrompts.filter((p) =>
          p.question.endsWith("?") ||
          /^(What|How|Why|When|Where|Who|Which|Describe|Write|Think|Reflect|List|Name|Share|Explain|Imagine|Create|Consider)/i.test(p.question)
        );
        logger.info(`Scraped ${scrapedQuestions.length} questions from JournalBuddies`);

        // Add scraped questions
        let questionsAdded = 0;
        scrapedQuestions.forEach((p) => {
          const normalized = normalizeText(p.question);
          if (!seenPrompts.has(normalized)) {
            seenPrompts.add(normalized);
            allPrompts.push(p);
            questionsAdded++;
          }
        });

        // Generate additional questions to reach target
        const questionCategories = ["question", "reflection", "gratitude", "creative", "growth"];
        const questionsNeeded = targetQuestions - questionsAdded;
        const questionsPerCategory = Math.ceil(questionsNeeded / questionCategories.length);

        for (const category of questionCategories) {
          const generated = generateHighQualityPrompts(category, questionsPerCategory, seenPrompts);
          generated.forEach((p) => {
            if (questionsAdded < targetQuestions) {
              allPrompts.push(p);
              questionsAdded++;
            }
          });
        }

        totalQuestions = questionsAdded;
        logger.info(`Total questions: ${totalQuestions}`);
      }

      // Shuffle all prompts
      const shuffledPrompts = allPrompts.sort(() => Math.random() - 0.5);

      logger.info(`Total prompts to seed: ${shuffledPrompts.length}`);
      logger.info(`Questions: ${totalQuestions}, Statements: ${totalStatements}`);

      // Store in Firestore in batches of 500
      const batchSize = 500;
      let totalStored = 0;

      for (let i = 0; i < shuffledPrompts.length; i += batchSize) {
        const batch = db.batch();
        const batchPrompts = shuffledPrompts.slice(i, i + batchSize);

        batchPrompts.forEach((prompt) => {
          const docRef = db.collection("prompts").doc(prompt.id);
          batch.set(docRef, prompt);
        });

        await batch.commit();
        totalStored += batchPrompts.length;
        logger.info(`Stored batch: ${totalStored}/${shuffledPrompts.length} prompts`);
      }

      logger.info(`Successfully seeded ${totalStored} prompts`);

      // Group statements by author for the response
      const statementsByAuthor: Record<string, string[]> = {};
      newStatements.forEach(({quote, author}) => {
        if (!statementsByAuthor[author]) {
          statementsByAuthor[author] = [];
        }
        statementsByAuthor[author].push(quote);
      });

      res.status(200).json({
        status: "success",
        totalPrompts: totalStored,
        questions: totalQuestions,
        statements: totalStatements,
        questionPercentage: `${((totalQuestions / totalStored) * 100).toFixed(1)}%`,
        statementPercentage: `${((totalStatements / totalStored) * 100).toFixed(1)}%`,
        allStatements: newStatements,
        statementsByAuthor: statementsByAuthor,
      });
    } catch (error) {
      logger.error("Error seeding prompts", error);
      res.status(500).json({
        status: "error",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

/**
 * Cleanup bad quotes from Firestore using improved filtering
 * Tests all quotes against isValidQuote() and deletes invalid ones
 */
export const cleanupBadQuotes = onRequest(
  {
    cors: true,
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async (req, res) => {
    logger.info("Starting bad quote cleanup process");

    try {
      // Query all quotes from Firestore
      const quotesSnapshot = await db.collection("prompts")
        .where("category", "==", "quote")
        .get();

      logger.info(`Found ${quotesSnapshot.size} quotes to check`);

      const badQuotes: Array<{id: string; question: string}> = [];
      const goodQuotes: string[] = [];

      // Test each quote against improved isValidQuote()
      quotesSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        const question = data.question as string;

        if (!isValidQuote(question)) {
          badQuotes.push({id: doc.id, question: question});
        } else {
          goodQuotes.push(doc.id);
        }
      });

      logger.info(`Found ${badQuotes.length} bad quotes to delete`);
      logger.info(`Found ${goodQuotes.length} good quotes to keep`);

      // Delete bad quotes in batches of 500
      const batchSize = 500;
      let totalDeleted = 0;

      for (let i = 0; i < badQuotes.length; i += batchSize) {
        const batch = db.batch();
        const batchQuotes = badQuotes.slice(i, i + batchSize);

        batchQuotes.forEach((quote) => {
          const docRef = db.collection("prompts").doc(quote.id);
          batch.delete(docRef);
        });

        await batch.commit();
        totalDeleted += batchQuotes.length;
        logger.info(`Deleted batch: ${totalDeleted}/${badQuotes.length} quotes`);
      }

      logger.info(`Successfully cleaned up ${totalDeleted} bad quotes`);

      // Return summary with examples of deleted quotes
      const exampleBadQuotes = badQuotes.slice(0, 10).map((q) => ({
        id: q.id,
        question: q.question.substring(0, 100) + (q.question.length > 100 ? "..." : ""),
      }));

      res.status(200).json({
        status: "success",
        totalChecked: quotesSnapshot.size,
        totalDeleted: totalDeleted,
        totalRemaining: goodQuotes.length,
        exampleDeletedQuotes: exampleBadQuotes,
      });
    } catch (error) {
      logger.error("Error cleaning up quotes", error);
      res.status(500).json({
        status: "error",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

/**
 * Cleanup duplicate IDs in Firestore prompts
 * Finds prompts with duplicate IDs and assigns new unique IDs
 */
export const cleanupDuplicateIds = onRequest(
  {
    cors: true,
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async (req, res) => {
    logger.info("Starting duplicate ID cleanup process");

    try {
      // Query all prompts from Firestore
      const allPromptsSnapshot = await db.collection("prompts").get();
      logger.info(`Found ${allPromptsSnapshot.size} total prompts`);

      // Group prompts by their document ID to find duplicates
      const idCounts: Record<string, number> = {};
      const duplicateIds: string[] = [];

      allPromptsSnapshot.docs.forEach((doc) => {
        const id = doc.id;
        idCounts[id] = (idCounts[id] || 0) + 1;
        if (idCounts[id] === 2) {
          duplicateIds.push(id);
        }
      });

      logger.info(`Found ${duplicateIds.length} duplicate IDs`);

      // Since Firestore document IDs are unique by nature,
      // duplicates happen when the same data is stored multiple times
      // We need to check for prompts with same content
      const contentMap: Map<string, Array<{id: string; data: admin.firestore.DocumentData}>> = new Map();

      allPromptsSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        const contentKey = `${data.question}_${data.category}`;
        if (!contentMap.has(contentKey)) {
          contentMap.set(contentKey, []);
        }
        contentMap.get(contentKey)!.push({id: doc.id, data});
      });

      // Find content duplicates
      const contentDuplicates: Array<{original: string; duplicates: string[]}> = [];
      let totalDuplicates = 0;

      contentMap.forEach((prompts, contentKey) => {
        if (prompts.length > 1) {
          // Keep the first, mark rest as duplicates
          const [original, ...duplicates] = prompts;
          contentDuplicates.push({
            original: original.id,
            duplicates: duplicates.map((d) => d.id),
          });
          totalDuplicates += duplicates.length;
        }
      });

      logger.info(`Found ${totalDuplicates} content duplicates to remove`);

      // Delete duplicate prompts in batches
      let totalDeleted = 0;
      const batchSize = 500;
      const allDuplicateIds = contentDuplicates.flatMap((d) => d.duplicates);

      for (let i = 0; i < allDuplicateIds.length; i += batchSize) {
        const batch = db.batch();
        const batchIds = allDuplicateIds.slice(i, i + batchSize);

        batchIds.forEach((id) => {
          const docRef = db.collection("prompts").doc(id);
          batch.delete(docRef);
        });

        await batch.commit();
        totalDeleted += batchIds.length;
        logger.info(`Deleted batch: ${totalDeleted}/${allDuplicateIds.length} duplicates`);
      }

      logger.info(`Successfully cleaned up ${totalDeleted} duplicate prompts`);

      res.status(200).json({
        status: "success",
        totalChecked: allPromptsSnapshot.size,
        totalDuplicatesFound: totalDuplicates,
        totalDeleted: totalDeleted,
        remainingPrompts: allPromptsSnapshot.size - totalDeleted,
        exampleDuplicates: contentDuplicates.slice(0, 5),
      });
    } catch (error) {
      logger.error("Error cleaning up duplicates", error);
      res.status(500).json({
        status: "error",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

/**
 * Analyze prompts ratio (questions vs statements)
 * Returns breakdown by category and type
 */
export const analyzePromptsRatio = onRequest(
  {
    cors: true,
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async (req, res) => {
    logger.info("Starting prompts ratio analysis");

    try {
      const allPromptsSnapshot = await db.collection("prompts").get();
      logger.info(`Analyzing ${allPromptsSnapshot.size} prompts`);

      // Question detection patterns
      const questionPatterns = [
        /\?$/, // Ends with question mark
        /^(What|How|Why|When|Where|Who|Which|Describe|Write|Think|Reflect|List|Name|Share|Explain|Imagine|Create|Consider)\b/i,
      ];

      const isQuestion = (text: string): boolean => {
        return questionPatterns.some((pattern) => pattern.test(text.trim()));
      };

      // Categorize prompts
      const stats = {
        total: 0,
        questions: 0,
        statements: 0,
        byCategory: {} as Record<string, {total: number; questions: number; statements: number}>,
        exampleQuestions: [] as Array<{question: string; category: string}>,
        exampleStatements: [] as Array<{question: string; category: string}>,
      };

      allPromptsSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        const question = data.question as string;
        const category = data.category as string;

        stats.total++;

        // Initialize category if not exists
        if (!stats.byCategory[category]) {
          stats.byCategory[category] = {total: 0, questions: 0, statements: 0};
        }
        stats.byCategory[category].total++;

        if (isQuestion(question)) {
          stats.questions++;
          stats.byCategory[category].questions++;
          if (stats.exampleQuestions.length < 5) {
            stats.exampleQuestions.push({question: question.substring(0, 100), category});
          }
        } else {
          stats.statements++;
          stats.byCategory[category].statements++;
          if (stats.exampleStatements.length < 5) {
            stats.exampleStatements.push({question: question.substring(0, 100), category});
          }
        }
      });

      // Calculate percentages
      const questionPercentage = stats.total > 0 ? ((stats.questions / stats.total) * 100).toFixed(1) : "0";
      const statementPercentage = stats.total > 0 ? ((stats.statements / stats.total) * 100).toFixed(1) : "0";

      // Category breakdown with percentages
      const categoryBreakdown: Record<string, {total: number; questions: number; statements: number; questionPct: string; statementPct: string}> = {};
      Object.entries(stats.byCategory).forEach(([cat, data]) => {
        categoryBreakdown[cat] = {
          ...data,
          questionPct: data.total > 0 ? ((data.questions / data.total) * 100).toFixed(1) : "0",
          statementPct: data.total > 0 ? ((data.statements / data.total) * 100).toFixed(1) : "0",
        };
      });

      res.status(200).json({
        status: "success",
        summary: {
          total: stats.total,
          questions: stats.questions,
          statements: stats.statements,
          questionPercentage: `${questionPercentage}%`,
          statementPercentage: `${statementPercentage}%`,
          targetRatio: "80% questions / 20% statements",
        },
        byCategory: categoryBreakdown,
        examples: {
          questions: stats.exampleQuestions,
          statements: stats.exampleStatements,
        },
      });
    } catch (error) {
      logger.error("Error analyzing prompts", error);
      res.status(500).json({
        status: "error",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

/**
 * Cleanup all statements/quotes from Firestore
 * Keeps all questions intact, only removes quotes
 */
export const cleanupAllStatements = onRequest(
  {
    cors: true,
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async (req, res) => {
    logger.info("Starting cleanup of all statements/quotes");

    try {
      // Query all prompts with category "quote"
      const quotesSnapshot = await db.collection("prompts")
        .where("category", "==", "quote")
        .get();

      logger.info(`Found ${quotesSnapshot.size} quotes to delete`);

      if (quotesSnapshot.empty) {
        res.status(200).json({
          status: "success",
          message: "No quotes found to delete",
          deleted: 0,
        });
        return;
      }

      // Delete in batches of 500
      const batchSize = 500;
      let totalDeleted = 0;
      const docs = quotesSnapshot.docs;

      for (let i = 0; i < docs.length; i += batchSize) {
        const batch = db.batch();
        const chunk = docs.slice(i, i + batchSize);

        chunk.forEach((doc) => {
          batch.delete(doc.ref);
        });

        await batch.commit();
        totalDeleted += chunk.length;
        logger.info(`Deleted batch: ${totalDeleted}/${docs.length}`);
      }

      // Get remaining prompts count
      const remainingSnapshot = await db.collection("prompts").get();

      res.status(200).json({
        status: "success",
        message: `Deleted ${totalDeleted} quotes/statements`,
        deleted: totalDeleted,
        remainingPrompts: remainingSnapshot.size,
      });
    } catch (error) {
      logger.error("Error cleaning up statements", error);
      res.status(500).json({
        status: "error",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

/**
 * List all statements/quotes from Firestore
 * Returns array of all quotes with their text, author, and ID
 */
export const listAllStatements = onRequest(
  {
    cors: true,
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async (req, res) => {
    logger.info("Fetching all statements/quotes");

    try {
      // Query all prompts with category "quote"
      const quotesSnapshot = await db.collection("prompts")
        .where("category", "==", "quote")
        .get();

      logger.info(`Found ${quotesSnapshot.size} quotes`);

      // Group by author (extracted from hint field)
      const byAuthor: Record<string, Array<{id: string; quote: string}>> = {};
      const allStatements: Array<{id: string; quote: string; author: string}> = [];

      quotesSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        const quote = data.question as string;
        const hint = data.hint as string || "";
        // Extract author from hint (format: "- Author Name")
        const author = hint.replace(/^-\s*/, "").trim() || "Unknown";

        allStatements.push({
          id: doc.id,
          quote: quote,
          author: author,
        });

        if (!byAuthor[author]) {
          byAuthor[author] = [];
        }
        byAuthor[author].push({
          id: doc.id,
          quote: quote,
        });
      });

      // Sort by author name
      const sortedAuthors = Object.keys(byAuthor).sort();
      const sortedByAuthor: Record<string, Array<{id: string; quote: string}>> = {};
      sortedAuthors.forEach((author) => {
        sortedByAuthor[author] = byAuthor[author];
      });

      res.status(200).json({
        status: "success",
        totalStatements: allStatements.length,
        authorCount: sortedAuthors.length,
        byAuthor: sortedByAuthor,
        allStatements: allStatements,
      });
    } catch (error) {
      logger.error("Error listing statements", error);
      res.status(500).json({
        status: "error",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

// Type for prompt data
type PromptData = {
  id: string;
  question: string;
  hint: string;
  category: string;
  createdAt: admin.firestore.Timestamp;
  likes: number;
  shares: number;
  isLiked: boolean;
};

// Unique ID generator with counter to prevent collisions
let promptIdCounter = 0;
function generateUniqueId(prefix: string): string {
  promptIdCounter++;
  const timestamp = Date.now();
  const random = Math.random().toString(36).substr(2, 9);
  return `${prefix}_${timestamp}_${promptIdCounter}_${random}`;
}

// Quality filter patterns - exclude low quality content
const LOW_QUALITY_PATTERNS = [
  /click here/i,
  /read more/i,
  /subscribe/i,
  /sign up/i,
  /download/i,
  /buy now/i,
  /free shipping/i,
  /copyright/i,
  /all rights reserved/i,
  /privacy policy/i,
  /terms of service/i,
  /^[0-9]+$/,
  /^\s*$/,
  /^http/i,
  /\.com|\.org|\.net/i,
  /^\[.*\]$/,
  /^see also/i,
  /^main article/i,
  /^external links/i,
  /^references/i,
  /^source:/i,
  /^note:/i,
  /wikipedia/i,
  /category:/i,
  /edit\]/i,
  // Title/metadata patterns (speech titles, addresses, etc.)
  /^(address|speech|lecture|conference|meeting|talk|presentation|sermon)/i,
  /at the .* (society|conference|meeting|university|institute|college|school)/i,
  /for .* (birthday|anniversary|occasion|ceremony|event)/i,
];

// Check if text passes quality filter
function isQualityContent(text: string): boolean {
  // Check against low quality patterns
  for (const pattern of LOW_QUALITY_PATTERNS) {
    if (pattern.test(text)) return false;
  }

  // Must have at least 3 words
  const wordCount = text.split(/\s+/).filter((w) => w.length > 0).length;
  if (wordCount < 3) return false;

  // Must start with a letter or quote
  if (!/^[A-Za-z"']/.test(text)) return false;

  return true;
}

// Count sentences (approximate)
function countSentences(text: string): number {
  return (text.match(/[.!?]+/g) || []).length;
}

// Normalize text for deduplication
function normalizeText(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

// Check if text is a valid philosophical/life-focused quote
function isValidQuote(text: string): boolean {
  // Must have punctuation (quotes usually end with . ! ?)
  if (!/[.!?]/.test(text)) return false;

  // Filter out things that look like titles (too many commas)
  const commaCount = (text.match(/,/g) || []).length;
  if (commaCount > 3 && text.length < 100) return false;

  // Filter out formal address patterns
  if (/^(address|speech|lecture|conference|meeting|talk)/i.test(text)) {
    return false;
  }
  if (/at the .* (society|conference|meeting|university)/i.test(text)) {
    return false;
  }
  if (/for .* (birthday|anniversary|occasion)/i.test(text)) return false;

  // Filter out book titles, document metadata, and publication patterns
  const titleMetadataPatterns = [
    // Document structure references
    /\b(chapters?|part|section|volume|edition|appendix)\s*\d/i,
    /\bchapters?\s+\d+\s*[-–]\s*\d+/i, // "Chapters 1-37"
    // Publication metadata
    /\b(interpolation|translation|compiled|published|edited)\s+(of|by)\b/i,
    /\b(plain english|online|digital|print|paperback|hardcover)\b/i,
    // Institutional attributions (common in book titles)
    /\bby the\s+[A-Z][a-z]+(\s+[A-Z][a-z]+)*\s+(Institute|Society|Press|University|Foundation|Academy|Center|Centre)\b/,
    /\b(Institute|Society|Press|University|Foundation|Academy):/i,
    // Title structure patterns (colons followed by subtitle)
    /:\s*The\s+(Way|Art|Book|Path|Science|History|Study)\s+of\b/i,
    // Common book title patterns
    /^(The|A|An)\s+(Complete|Collected|Selected|Essential)\s+/i,
    /\b(foreword|preface|introduction|afterword)\s+by\b/i,
    // ISBN, page numbers, etc.
    /\b(ISBN|pp\.|pages?)\s*[\d-]+/i,
  ];
  for (const pattern of titleMetadataPatterns) {
    if (pattern.test(text)) return false;
  }

  // Filter out factual statements (not philosophical/life-focused)
  const factualPatterns = [
    /\b(we|i|they) (made|built|created|invented|discovered|found)\b/i,
    /\b(in|on|at) (19|20)\d{2}\b/, // Years
    /\b(bomb|weapon|war|battle|election|president|government)\b/i,
    /\b(percent|%|dollars?|\$|miles?|km|kilometers?)\b/i,
    // Historical atrocities and specific historical events
    /\b(hitler|nazi|holocaust|genocide|concentration camp|wwii|ww2|world war)\b/i,
    /\b(devastated|destroyed|killed|murdered|executed|slaughtered)\b/i,
    // Military/battle-specific content
    /\b(army|armies|troops|soldiers|cavalry|infantry|artillery|regiment)\b/i,
    /\b(conquer|conquered|invasion|invaded|siege|defeated|victory over)\b/i,
    /\b(empire|emperor|kingdom|throne|reign|dynasty)\b/i,
    // Specific historical conflicts and events
    /\b(revolution|civil war|campaign|expedition|march on)\b/i,
  ];
  for (const pattern of factualPatterns) {
    if (pattern.test(text)) return false;
  }

  // Must contain philosophical/life-focused words
  const philosophicalWords = [
    /\b(life|living|existence|being|soul|spirit|human|humanity)\b/i,
    /\b(wisdom|truth|knowledge|understand|learn|teach|know|believe)\b/i,
    /\b(love|hate|fear|hope|dream|purpose|meaning|value|worth)\b/i,
    /\b(grow|change|become|transform|evolve|progress|journey|path)\b/i,
    /\b(reflect|consider|contemplate|meditate|ponder|wonder)\b/i,
    /\b(time|eternity|universe|nature|reality|truth|justice|freedom)\b/i,
    /\b(character|virtue|honor|integrity|courage|strength|weakness)\b/i,
    /\b(friend|friendship|relationship|connection|trust|respect)\b/i,
    /\b(beautiful|beauty|happy|happiness|peace|joy|sorrow|pain)\b/i,
    /\b(mind|heart|thought|idea|imagination|creativity|art)\b/i,
  ];

  // Must match at least one philosophical category
  const hasPhilosophical = philosophicalWords.some((p) => p.test(text));
  if (!hasPhilosophical) return false;

  // Must contain reflective verbs (not just factual statements)
  const reflectiveVerbs = /\b(think|believe|feel|know|understand|realize|see|imagine|dream|hope|wish|want|need|should|must|can|will|may)\b/i;
  if (!reflectiveVerbs.test(text) && text.length > 50) return false;

  return true;
}

/**
 * Scrape prompts from JournalBuddies.com with quality filtering
 */
async function scrapeJournalBuddies(): Promise<PromptData[]> {
  const seenPrompts = new Set<string>(); // For deduplication
  const promptsByCategory: Record<string, PromptData[]> = {
    question: [],
    reflection: [],
    gratitude: [],
    creative: [],
    growth: [],
  };

  // URLs mapped to categories
  const urlCategoryMap: Array<{url: string; category: string}> = [
    {url: "https://www.journalbuddies.com/prompts-by-grade/journal-prompts-for-adults/", category: "question"},
    {url: "https://www.journalbuddies.com/prompts-by-grade/self-reflection-journal-prompts/", category: "reflection"},
    {url: "https://www.journalbuddies.com/prompts-by-grade/gratitude-journal-prompts/", category: "gratitude"},
    {url: "https://www.journalbuddies.com/prompts-by-grade/creative-writing-prompts/", category: "creative"},
    {url: "https://www.journalbuddies.com/prompts-by-grade/personal-growth-prompts/", category: "growth"},
    // Additional pages for more prompts
    {url: "https://www.journalbuddies.com/prompts-by-grade/daily-journal-prompts/", category: "question"},
    {url: "https://www.journalbuddies.com/prompts-by-grade/mindfulness-journal-prompts/", category: "reflection"},
    {url: "https://www.journalbuddies.com/prompts-by-grade/self-care-journal-prompts/", category: "growth"},
    {url: "https://www.journalbuddies.com/prompts-by-grade/thankful-journal-prompts/", category: "gratitude"},
    {url: "https://www.journalbuddies.com/prompts-by-grade/fun-writing-prompts/", category: "creative"},
  ];

  for (const {url, category} of urlCategoryMap) {
    try {
      await new Promise((resolve) => setTimeout(resolve, 1500)); // Rate limiting
      const response = await axios.get(url, {
        headers: {
          "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
          "Accept": "text/html,application/xhtml+xml",
        },
        timeout: 30000,
      });

      const $ = cheerio.load(response.data);

      // Extract prompts from ordered/unordered lists (where JournalBuddies lists prompts)
      $("ol li, ul li").each((_, element) => {
        let text = $(element).text().trim();

        // Clean up the text
        text = text.replace(/^\d+\.\s*/, ""); // Remove leading numbers
        text = text.replace(/\s+/g, " "); // Normalize whitespace

        // Quality checks
        if (text.length < 15 || text.length > 200) return; // Reasonable length (1-2 sentences)
        if (countSentences(text) > 2) return; // Max 2 sentences
        if (!isQualityContent(text)) return;

        // Must look like a prompt (question or instruction)
        const isPromptLike = /\?$/.test(text) ||
          /^(What|How|Why|When|Where|Who|Which|Describe|Write|Think|Reflect|List|Name|Share|Explain|Imagine|Create|Consider)/i.test(text);
        if (!isPromptLike) return;

        // Deduplication
        const normalized = normalizeText(text);
        if (seenPrompts.has(normalized)) return;
        seenPrompts.add(normalized);

        // Generate contextual hint based on category
        const hints: Record<string, string[]> = {
          question: ["Take your time to explore this question.", "Be honest with yourself.", "There's no wrong answer."],
          reflection: ["Look inward and explore your thoughts.", "Consider what this reveals about you.", "Reflect without judgment."],
          gratitude: ["Appreciate the small things.", "Let yourself feel thankful.", "Notice the positive in your life."],
          creative: ["Let your imagination flow freely.", "There are no limits here.", "Be as creative as you want."],
          growth: ["Consider how you've evolved.", "What have you learned?", "Celebrate your progress."],
        };
        const categoryHints = hints[category] || hints.reflection;
        const hint = categoryHints[Math.floor(Math.random() * categoryHints.length)];

        promptsByCategory[category].push({
          id: generateUniqueId("jb"),
          question: text,
          hint: hint,
          category: category,
          createdAt: admin.firestore.Timestamp.now(),
          likes: 0,
          shares: 0,
          isLiked: false,
        });
      });

      logger.info(`Scraped ${promptsByCategory[category].length} ${category} prompts from ${url}`);
    } catch (error) {
      logger.error(`Error scraping ${url}`, error);
    }
  }

  // Only generate fallback if scraping failed (< 500 per category)
  const minimumScraped = 500; // Minimum to consider scraping successful
  const targetPerCategory = 1600; // ~8000 total for 5 categories
  const allPrompts: PromptData[] = [];

  for (const category of Object.keys(promptsByCategory)) {
    let categoryPrompts = promptsByCategory[category];

    // Only generate if scraping got very few prompts (failed or blocked)
    if (categoryPrompts.length < minimumScraped) {
      logger.warn(`Scraping got only ${categoryPrompts.length} ${category} prompts, generating fallback`);
      const additional = generateHighQualityPrompts(
        category,
        targetPerCategory - categoryPrompts.length,
        seenPrompts
      );
      categoryPrompts = [...categoryPrompts, ...additional];
    } else {
      // Scraping was successful - use only scraped prompts
      logger.info(`Scraping successful: ${categoryPrompts.length} ${category} prompts`);
    }

    // Take up to target and shuffle
    const shuffled = categoryPrompts.sort(() => Math.random() - 0.5).slice(0, targetPerCategory);
    allPrompts.push(...shuffled);

    logger.info(`Final ${category} prompts: ${shuffled.length}`);
  }

  return allPrompts.sort(() => Math.random() - 0.5);
}

/**
 * Scrape quotes from Wikiquote with quality filtering
 */
async function scrapeWikiquote(): Promise<PromptData[]> {
  const seenQuotes = new Set<string>(); // For deduplication
  const quotes: PromptData[] = [];

  // Curated list of philosophers, thinkers, and historical figures
  const people = [
    // Stoics
    "Epicurus", "Seneca", "Marcus_Aurelius", "Epictetus",
    // Eastern Philosophy
    "Buddha", "Lao_Tzu", "Confucius", "Rumi",
    // Modern Thinkers
    "Carl_Jung", "Viktor_Frankl", "Alan_Watts",
    // Writers/Poets
    "Maya_Angelou", "Rainer_Maria_Rilke",
    // Scientists/Philosophers
    "Albert_Einstein", "Carl_Sagan",
    // Historical Leaders (focus on wisdom/leadership quotes, not battle-specific)
    "Napoleon", "Alexander_the_Great", "Julius_Caesar",
    // Renaissance/Classical
    "Leonardo_da_Vinci", "Michelangelo", "Plato", "Aristotle", "Socrates",
  ];

  for (const person of people) {
    try {
      await new Promise((resolve) => setTimeout(resolve, 1500)); // Rate limiting
      const url = `https://en.wikiquote.org/wiki/${person}`;
      const response = await axios.get(url, {
        headers: {
          "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
          "Accept": "text/html,application/xhtml+xml",
        },
        timeout: 30000,
      });

      const $ = cheerio.load(response.data);
      const personName = person.replace(/_/g, " ");

      // Extract quotes from content area
      $(".mw-parser-output > ul > li, .mw-parser-output > dl > dd").each((_, element) => {
        let text = $(element).clone().children("ul, dl").remove().end().text().trim();

        // Clean up the text
        text = text.replace(/\s+/g, " "); // Normalize whitespace
        text = text.replace(/\[.*?\]/g, ""); // Remove citation brackets
        text = text.replace(/\(.*?\)/g, "").trim(); // Remove parenthetical notes

        // Quality checks for quotes
        if (text.length < 20 || text.length > 180) return; // 1-2 sentences max
        if (countSentences(text) > 2) return; // Max 2 sentences
        if (!isQualityContent(text)) return;
        if (!isValidQuote(text)) return; // Must be philosophical/life-focused

        // Must look like a meaningful quote (not navigation or metadata)
        if (/^[a-z]/.test(text)) return; // Should start with capital
        if (text.split(" ").length < 4) return; // At least 4 words

        // Deduplication
        const normalized = normalizeText(text);
        if (seenQuotes.has(normalized)) return;
        if (normalized.length < 15) return; // Too short after normalization
        seenQuotes.add(normalized);

        quotes.push({
          id: generateUniqueId("wq"),
          question: text,
          hint: `- ${personName}`,
          category: "quote",
          createdAt: admin.firestore.Timestamp.now(),
          likes: 0,
          shares: 0,
          isLiked: false,
        });
      });

      logger.info(`Scraped ${quotes.length} total quotes (including ${personName})`);
    } catch (error) {
      logger.error(`Error scraping quotes for ${person}`, error);
    }
  }

  // Only generate fallback if scraping failed (< 200 quotes)
  const minimumScrapedQuotes = 200;
  const targetQuotes = 2000;

  if (quotes.length < minimumScrapedQuotes) {
    logger.warn(`Scraping got only ${quotes.length} quotes, generating fallback`);
    const additional = generateCuratedQuotes(targetQuotes - quotes.length, seenQuotes);
    quotes.push(...additional);
  } else {
    logger.info(`Quote scraping successful: ${quotes.length} quotes`);
  }

  logger.info(`Final quote count: ${quotes.length}`);
  return quotes.sort(() => Math.random() - 0.5).slice(0, targetQuotes);
}

/**
 * Generate high-quality prompts for a specific category (fallback if scraping fails)
 */
function generateHighQualityPrompts(
  category: string,
  count: number,
  seenPrompts: Set<string>
): PromptData[] {
  const prompts: PromptData[] = [];

  // Extensive high-quality prompt templates by category (80+ per category for variety)
  const promptTemplates: Record<string, Array<{question: string; hint: string}>> = {
    question: [
      {question: "What would you do if you knew you couldn't fail?", hint: "Dream without limits."},
      {question: "What brings you the most joy in your daily life?", hint: "Notice the small things."},
      {question: "What would your ideal day look like?", hint: "Be specific and detailed."},
      {question: "What are you most curious about right now?", hint: "Follow your curiosity."},
      {question: "What conversation have you been avoiding?", hint: "Consider why."},
      {question: "What do you wish you had more time for?", hint: "Priorities reveal values."},
      {question: "What would you do differently if you could start over?", hint: "Hindsight is a teacher."},
      {question: "What makes you feel most alive?", hint: "Seek more of this."},
      {question: "What do you need to let go of?", hint: "Letting go creates space."},
      {question: "What are you pretending not to know?", hint: "Be honest with yourself."},
      {question: "What would you attempt if you knew you would be supported?", hint: "Imagine that support."},
      {question: "What is your body trying to tell you?", hint: "Listen closely."},
      {question: "What does success mean to you right now?", hint: "Definitions evolve."},
      {question: "What are you tolerating that you shouldn't be?", hint: "Boundaries matter."},
      {question: "What question are you afraid to ask yourself?", hint: "That's the one to explore."},
      {question: "What would you regret not doing in your lifetime?", hint: "Act on what matters."},
      {question: "What do you want to be remembered for?", hint: "Legacy is built daily."},
      {question: "What's the bravest thing you've ever done?", hint: "Courage takes many forms."},
      {question: "What advice would you give to your teenage self?", hint: "Wisdom comes with time."},
      {question: "What is something you've always wanted to try?", hint: "What's holding you back?"},
      {question: "What does a fulfilling life look like to you?", hint: "Define it for yourself."},
      {question: "What would you do if money was no object?", hint: "Follow your true passions."},
      {question: "What's the most important lesson life has taught you?", hint: "Share your wisdom."},
      {question: "What do you value most in a friendship?", hint: "Quality over quantity."},
      {question: "What makes you feel truly at peace?", hint: "Seek more peace."},
      {question: "What's one thing you wish people understood about you?", hint: "Communication is key."},
      {question: "What do you want your daily life to feel like?", hint: "Feelings guide us."},
      {question: "What's been on your mind lately?", hint: "Let it out."},
      {question: "What are you most proud of accomplishing?", hint: "Celebrate your wins."},
      {question: "What's your biggest dream right now?", hint: "Dreams deserve attention."},
      {question: "What would make today a great day?", hint: "Start with intention."},
      {question: "What's something you need to hear right now?", hint: "Write it for yourself."},
      {question: "What are you looking forward to this week?", hint: "Anticipation is powerful."},
      {question: "What's the best decision you've ever made?", hint: "Reflect on your wins."},
      {question: "What's something that always makes you laugh?", hint: "Joy is medicine."},
      {question: "What does your ideal weekend look like?", hint: "Rest is productive."},
      {question: "What's a skill you wish you had developed earlier?", hint: "It's never too late."},
      {question: "What do you need more of in your life?", hint: "Identify the gaps."},
      {question: "What do you need less of in your life?", hint: "Subtract the excess."},
      {question: "What's holding you back from happiness?", hint: "Name it to claim it."},
    ],
    reflection: [
      {question: "How have your priorities changed in the past year?", hint: "Growth shows in shifts."},
      {question: "What patterns do you notice in your relationships?", hint: "Patterns reveal truths."},
      {question: "What would your younger self think of who you've become?", hint: "Honor your journey."},
      {question: "What beliefs have you outgrown?", hint: "Evolution is natural."},
      {question: "How do you handle uncertainty?", hint: "Notice your patterns."},
      {question: "What have you learned about yourself recently?", hint: "Self-knowledge is power."},
      {question: "What emotions have you been avoiding?", hint: "All feelings are valid."},
      {question: "How do you typically respond to stress?", hint: "Awareness enables change."},
      {question: "What stories do you tell yourself about your life?", hint: "Stories shape reality."},
      {question: "What assumptions have you made that might not be true?", hint: "Question everything."},
      {question: "How do you define your identity?", hint: "You are more than labels."},
      {question: "What role does fear play in your decisions?", hint: "Name it to tame it."},
      {question: "What are you resisting right now?", hint: "Resistance reveals importance."},
      {question: "How do you show up differently in various areas of your life?", hint: "Notice the shifts."},
      {question: "What would change if you were kinder to yourself?", hint: "Self-compassion heals."},
      {question: "How do you react when things don't go as planned?", hint: "Flexibility is strength."},
      {question: "What recurring thoughts keep coming back to you?", hint: "Pay attention to them."},
      {question: "How do you typically spend your alone time?", hint: "Solitude reveals priorities."},
      {question: "What do your daily habits say about your values?", hint: "Actions speak truth."},
      {question: "How do you feel about where you are in life right now?", hint: "Honest assessment helps."},
      {question: "What's the hardest thing you've had to accept?", hint: "Acceptance brings peace."},
      {question: "How do you celebrate your achievements?", hint: "Recognition matters."},
      {question: "What would you change about your daily routine?", hint: "Small changes add up."},
      {question: "How do you deal with disappointment?", hint: "Resilience is built."},
      {question: "What aspects of your life bring you the most stress?", hint: "Identify to address."},
      {question: "How do you make important decisions?", hint: "Know your process."},
      {question: "What part of yourself do you hide from others?", hint: "Authenticity heals."},
      {question: "How do you know when you need a break?", hint: "Listen to the signs."},
      {question: "What's your relationship with time like?", hint: "Time reveals priorities."},
      {question: "How do you handle criticism?", hint: "Growth or defense?"},
      {question: "What does self-care look like for you?", hint: "Define your own care."},
      {question: "How do you maintain your energy throughout the day?", hint: "Energy is precious."},
      {question: "What's your inner dialogue like most days?", hint: "Self-talk matters."},
      {question: "How do you process difficult emotions?", hint: "Emotions need outlets."},
      {question: "What's something you've been putting off thinking about?", hint: "Face it gently."},
    ],
    gratitude: [
      {question: "What small pleasure did you enjoy today?", hint: "Joy lives in details."},
      {question: "Who made a positive difference in your life this week?", hint: "Acknowledge them."},
      {question: "What challenge are you grateful for overcoming?", hint: "Struggles build strength."},
      {question: "What ability do you often take for granted?", hint: "Appreciate your gifts."},
      {question: "What memory always makes you smile?", hint: "Revisit it often."},
      {question: "What opportunity are you thankful for?", hint: "Doors open unexpectedly."},
      {question: "What simple comfort brings you peace?", hint: "Comfort is a gift."},
      {question: "Who has believed in you when you doubted yourself?", hint: "Some people see us clearly."},
      {question: "What lesson are you grateful to have learned?", hint: "Wisdom comes at a cost."},
      {question: "What about your home brings you comfort?", hint: "Sanctuary matters."},
      {question: "What aspect of your health are you thankful for?", hint: "Health is wealth."},
      {question: "What friendship has enriched your life?", hint: "Connection nourishes."},
      {question: "What experience shaped you in a positive way?", hint: "Everything teaches."},
      {question: "What beauty did you notice today?", hint: "Beauty is everywhere."},
      {question: "What are you looking forward to?", hint: "Anticipation brings joy."},
      {question: "What modern convenience are you most grateful for?", hint: "Progress is remarkable."},
      {question: "What made you laugh recently?", hint: "Laughter heals."},
      {question: "What skill or talent are you thankful to have?", hint: "Your gifts matter."},
      {question: "What place makes you feel grateful to be alive?", hint: "Location affects mood."},
      {question: "What mistake taught you something valuable?", hint: "Mistakes are teachers."},
      {question: "What's something your body does that you're grateful for?", hint: "Bodies are miraculous."},
      {question: "Who has inspired you lately?", hint: "Inspiration is a gift."},
      {question: "What's a small win you had today?", hint: "Small wins count."},
      {question: "What season are you most grateful for?", hint: "Nature's cycles gift us."},
      {question: "What food are you thankful to enjoy?", hint: "Nourishment is precious."},
      {question: "What piece of art or music brings you joy?", hint: "Art elevates us."},
      {question: "What technology has improved your life?", hint: "Progress serves us."},
      {question: "What hobby are you grateful to have discovered?", hint: "Passions enrich life."},
      {question: "What's a problem you're glad you don't have?", hint: "Perspective shifts gratitude."},
      {question: "What's something free that brings you happiness?", hint: "The best things are free."},
      {question: "What about today went better than expected?", hint: "Surprises can be gifts."},
      {question: "Who's voice do you love to hear?", hint: "Connection is precious."},
      {question: "What part of your morning routine do you appreciate?", hint: "Rituals ground us."},
      {question: "What's a book or show you're grateful you discovered?", hint: "Stories change us."},
      {question: "What's something about yourself you're learning to appreciate?", hint: "Self-love grows."},
    ],
    creative: [
      {question: "If your life was a movie, what would the title be?", hint: "You're the main character."},
      {question: "What would you create if you had unlimited resources?", hint: "Dream big."},
      {question: "Describe your perfect place of peace.", hint: "Create it in your mind."},
      {question: "What story from your life would make a great book?", hint: "Your life is fascinating."},
      {question: "If you could have dinner with anyone, who and why?", hint: "What would you ask them?"},
      {question: "What would your future self tell you right now?", hint: "Listen to that wisdom."},
      {question: "Design your ideal morning routine.", hint: "Mornings set the tone."},
      {question: "What metaphor best describes your life right now?", hint: "Metaphors reveal truths."},
      {question: "If you could master any skill instantly, what would it be?", hint: "What draws you?"},
      {question: "Write a letter to your past self.", hint: "What would they need to hear?"},
      {question: "What would you build if you had no limitations?", hint: "Constraints can wait."},
      {question: "Describe a day in your ideal future life.", hint: "Visualization is powerful."},
      {question: "What legacy do you want to leave behind?", hint: "Start building it now."},
      {question: "If your emotions were weather, what's today's forecast?", hint: "Weather always changes."},
      {question: "What adventure is calling to you?", hint: "Adventure takes many forms."},
      {question: "If you could live in any era, when would it be?", hint: "Time travel your mind."},
      {question: "What would your dream house look like?", hint: "Details matter."},
      {question: "If you could be any animal for a day, which one?", hint: "What draws you to it?"},
      {question: "What would you name a boat or a star?", hint: "Names carry meaning."},
      {question: "If you could create a holiday, what would it celebrate?", hint: "What deserves honoring?"},
      {question: "What would your autobiography be titled?", hint: "Sum up your story."},
      {question: "If your life had a soundtrack, what songs would be on it?", hint: "Music marks memories."},
      {question: "Describe your perfect weekend getaway.", hint: "Escape in your mind."},
      {question: "What invention would improve your daily life?", hint: "Solve your own problems."},
      {question: "If you could redesign your workspace, what would change?", hint: "Environment shapes us."},
      {question: "What superpower would suit your personality?", hint: "Powers reveal desires."},
      {question: "If you could paint your perfect day, what colors would you use?", hint: "Colors evoke feelings."},
      {question: "What would you say to the world if everyone was listening?", hint: "What matters most?"},
      {question: "If you were a character in a book, what would your role be?", hint: "Hero, mentor, or sage?"},
      {question: "What would your dream vacation look like?", hint: "Travel in imagination."},
      {question: "If you could redesign your city, what would you add?", hint: "Improve your world."},
      {question: "What artistic project would you love to attempt?", hint: "Creativity calls."},
      {question: "If you could learn any language instantly, which one?", hint: "Languages open worlds."},
      {question: "What would your ideal garden contain?", hint: "Gardens are sanctuaries."},
      {question: "If you could host any event, what would it be?", hint: "Bring people together."},
    ],
    growth: [
      {question: "What skill do you want to develop this year?", hint: "Small steps compound."},
      {question: "What habit would transform your life?", hint: "Habits shape destiny."},
      {question: "What fear is holding you back from growing?", hint: "Face it to move past it."},
      {question: "What do you need to learn to reach your goals?", hint: "Learning never stops."},
      {question: "How have you grown in the past year?", hint: "Celebrate progress."},
      {question: "What would you do if you weren't afraid of judgment?", hint: "Opinions fade quickly."},
      {question: "What conversation could change your life?", hint: "Have it this week."},
      {question: "What limiting belief needs to go?", hint: "Beliefs can be changed."},
      {question: "What would help you become more confident?", hint: "Confidence is built."},
      {question: "What are you committed to improving?", hint: "Commitment drives change."},
      {question: "What challenge would help you grow?", hint: "Comfort zones limit growth."},
      {question: "What do you need to forgive yourself for?", hint: "Forgiveness frees you."},
      {question: "What would make you proud of yourself?", hint: "Define your own pride."},
      {question: "What new perspective could change everything?", hint: "Perspectives are choices."},
      {question: "What step can you take today toward your goals?", hint: "Action beats planning."},
      {question: "What's one thing you could do better tomorrow?", hint: "Improvement is daily."},
      {question: "What would happen if you pushed past your comfort zone?", hint: "Growth lives there."},
      {question: "What's a weakness you're working on?", hint: "Weakness becomes strength."},
      {question: "What would your best self do today?", hint: "Be that person now."},
      {question: "What's preventing you from taking action?", hint: "Identify the blockers."},
      {question: "What would you accomplish with more discipline?", hint: "Discipline is freedom."},
      {question: "What's one thing you keep saying you'll do but haven't?", hint: "Start today."},
      {question: "What would change if you believed in yourself more?", hint: "Belief shapes reality."},
      {question: "What's the next version of yourself look like?", hint: "Envision your growth."},
      {question: "What feedback have you received that you should act on?", hint: "Feedback is a gift."},
      {question: "What's holding you back from living your best life?", hint: "Remove the obstacles."},
      {question: "What would you attempt if you knew you'd recover from failure?", hint: "Failure is temporary."},
      {question: "What area of life needs more attention?", hint: "Balance requires awareness."},
      {question: "What's a goal that scares and excites you?", hint: "That's the one to pursue."},
      {question: "What would change if you took full responsibility for your life?", hint: "Ownership empowers."},
      {question: "What's the most important thing you could focus on right now?", hint: "Prioritize ruthlessly."},
      {question: "What would your mentor advise you to do?", hint: "Seek wisdom."},
      {question: "What boundary do you need to set?", hint: "Boundaries protect growth."},
      {question: "What habit is holding you back?", hint: "Replace bad with good."},
      {question: "What would happen if you stopped making excuses?", hint: "Action awaits."},
    ],
  };

  const templates = promptTemplates[category] || promptTemplates.reflection;

  for (let i = 0; i < count && prompts.length < count; i++) {
    const template = templates[i % templates.length];
    const normalized = normalizeText(template.question);

    // Skip if already seen
    if (seenPrompts.has(normalized)) continue;
    seenPrompts.add(normalized);

    prompts.push({
      id: generateUniqueId("gen"),
      question: template.question,
      hint: template.hint,
      category: category,
      createdAt: admin.firestore.Timestamp.now(),
      likes: 0,
      shares: 0,
      isLiked: false,
    });
  }

  return prompts;
}

/**
 * Generate curated famous quotes (fallback if Wikiquote scraping fails)
 */
function generateCuratedQuotes(count: number, seenQuotes: Set<string>): PromptData[] {
  const curatedQuotes = [
    // Philosophers
    {text: "The only way to do great work is to love what you do.", author: "Steve Jobs"},
    {text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein"},
    {text: "Be yourself; everyone else is already taken.", author: "Oscar Wilde"},
    {text: "The unexamined life is not worth living.", author: "Socrates"},
    {text: "Happiness depends upon ourselves.", author: "Aristotle"},
    {text: "He who has a why to live can bear almost any how.", author: "Friedrich Nietzsche"},
    {text: "The mind is everything. What you think you become.", author: "Buddha"},
    {text: "To be yourself in a world constantly trying to make you something else is the greatest accomplishment.", author: "Ralph Waldo Emerson"},
    // Leaders
    {text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt"},
    {text: "It always seems impossible until it's done.", author: "Nelson Mandela"},
    {text: "Be the change you wish to see in the world.", author: "Mahatma Gandhi"},
    {text: "In the end, it's not the years in your life that count. It's the life in your years.", author: "Abraham Lincoln"},
    {text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill"},
    {text: "Darkness cannot drive out darkness; only light can do that.", author: "Martin Luther King Jr."},
    // Writers & Poets
    {text: "The wound is the place where the Light enters you.", author: "Rumi"},
    {text: "We are all in the gutter, but some of us are looking at the stars.", author: "Oscar Wilde"},
    {text: "I have learned that people will forget what you said, people will forget what you did, but people will never forget how you made them feel.", author: "Maya Angelou"},
    {text: "It is never too late to be what you might have been.", author: "George Eliot"},
    {text: "The only true wisdom is in knowing you know nothing.", author: "Socrates"},
    {text: "Two roads diverged in a wood, and I took the one less traveled by.", author: "Robert Frost"},
    // Modern Wisdom
    {text: "Your time is limited, don't waste it living someone else's life.", author: "Steve Jobs"},
    {text: "The biggest adventure you can take is to live the life of your dreams.", author: "Oprah Winfrey"},
    {text: "Happiness is not something ready-made. It comes from your own actions.", author: "Dalai Lama"},
    {text: "If you want others to be happy, practice compassion. If you want to be happy, practice compassion.", author: "Dalai Lama"},
    {text: "Life is 10% what happens to you and 90% how you react to it.", author: "Charles R. Swindoll"},
    // Stoics
    {text: "We suffer more often in imagination than in reality.", author: "Seneca"},
    {text: "You have power over your mind - not outside events. Realize this, and you will find strength.", author: "Marcus Aurelius"},
    {text: "First say to yourself what you would be; then do what you have to do.", author: "Epictetus"},
    {text: "It is not death that a man should fear, but he should fear never beginning to live.", author: "Marcus Aurelius"},
    {text: "Waste no more time arguing about what a good man should be. Be one.", author: "Marcus Aurelius"},
    // Additional wisdom
    {text: "Life is what happens when you're busy making other plans.", author: "John Lennon"},
    {text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney"},
    {text: "Whether you think you can or you think you can't, you're right.", author: "Henry Ford"},
    {text: "Everything you've ever wanted is on the other side of fear.", author: "George Addair"},
    {text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb"},
    {text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt"},
    {text: "The only impossible journey is the one you never begin.", author: "Tony Robbins"},
    {text: "What lies behind us and what lies before us are tiny matters compared to what lies within us.", author: "Ralph Waldo Emerson"},
    {text: "Go confidently in the direction of your dreams.", author: "Henry David Thoreau"},
    {text: "The purpose of our lives is to be happy.", author: "Dalai Lama"},
  ];

  const quotes: PromptData[] = [];

  for (let i = 0; i < count && i < curatedQuotes.length; i++) {
    const quote = curatedQuotes[i];
    const normalized = normalizeText(quote.text);

    // Skip if already seen
    if (seenQuotes.has(normalized)) continue;
    seenQuotes.add(normalized);

    quotes.push({
      id: generateUniqueId("curated"),
      question: quote.text,
      hint: `- ${quote.author}`,
      category: "quote",
      createdAt: admin.firestore.Timestamp.now(),
      likes: 0,
      shares: 0,
      isLiked: false,
    });
  }

  return quotes;
}
