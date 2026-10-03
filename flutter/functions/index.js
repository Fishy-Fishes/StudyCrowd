const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

// Define secrets using Firebase Secret Manager
const typesafeApiKey = defineSecret("TYPESAFE_API_KEY");
const clientAuthToken = defineSecret("CLIENT_AUTH_TOKEN");

exports.classifyDiscordMessage = onRequest(
  { secrets: [typesafeApiKey, clientAuthToken], invoker: "public" },
  async (req, res) => {
    // Only accept POST requests
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed. Use POST." });
      return;
    }

    const expectedAuthToken = (clientAuthToken.value() || "").trim();
    if (expectedAuthToken) {
      const authHeader = req.headers.authorization;
      const apiKeyHeader = req.headers["x-api-key"];

      const bearerToken =
        authHeader && authHeader.startsWith("Bearer ")
          ? authHeader.slice(7).trim()
          : null;

      const providedToken = (apiKeyHeader || bearerToken || "").trim();

      if (!providedToken || providedToken !== expectedAuthToken) {
        logger.warn("Unauthorized request attempt to classifyDiscordMessage");
        res.status(401).json({
          error: "Unauthorized: Invalid or missing authentication token.",
        });
        return;
      }
    }

    const messageContent = req.body && req.body.message;
    if (!messageContent || typeof messageContent !== "string") {
      res.status(400).json({ error: 'Missing or invalid "message" in request body.' });
      return;
    }

    logger.info(`Classifying message: "${messageContent}"`);

    const typesafeKey = (typesafeApiKey.value() || "").trim();
    if (!typesafeKey) {
      logger.error("TYPESAFE_API_KEY secret is not set.");
      res.status(500).json({
        error: "Server configuration error: TYPESAFE_API_KEY is missing.",
      });
      return;
    }

    try {
      const criteria = req.body.criteria || {
        ignore: "Casual conversation, off-topic, banter, or unhelpful messages",
        new_event: "Proposing a new study session, meeting, hangout, meal, or event",
        accept_event: "Agreeing to join, confirming attendance, RSVPing yes, or accepting an event",
      };

      const instructions =
        req.body.instructions ||
        "Classify this Discord message into exactly one of the categories based on the user's intent.";

      const payload = {
        model: "jev-latest",
        state: messageContent,
        questions: {
          category: {
            type: "choice",
            instructions: instructions,
            criteria: criteria,
          },
        },
      };

      const response = await fetch("https://api.typesafe.ai/v1/systemone", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${typesafeKey}`,
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const errorText = await response.text();
        logger.error(`TypeSafe AI API error (${response.status}):`, errorText);
        res.status(response.status).json({
          error: "TypeSafe AI API error",
          status: response.status,
          details: errorText,
        });
        return;
      }

      const data = await response.json();

      // TypeSafe AI answers format: data.answers.category.choice
      const categoryAnswer = data.answers && data.answers.category;
      const category =
        categoryAnswer?.choice ||
        categoryAnswer?.result ||
        data.choice ||
        "ignore";

      const confidence =
        categoryAnswer?.confidence !== undefined
          ? categoryAnswer.confidence
          : null;

      logger.info(`Classification result: ${category}`);

      res.status(200).json({
        message: messageContent,
        category: category,
        confidence: confidence,
        raw: data,
      });
    } catch (error) {
      logger.error("Error during message classification:", error);
      res.status(500).json({
        error: "Internal Server Error",
        message: error.message,
      });
    }
  }
);
