const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

// Define secrets using Firebase Secret Manager
const typesafeApiKey = defineSecret("TYPESAFE_API_KEY");
const clientAuthToken = defineSecret("CLIENT_AUTH_TOKEN");

// Discord OAuth client credentials are held server-side only.
// Set with: firebase functions:secrets:set DISCORD_CLIENT_SECRET
const discordClientSecret = defineSecret("DISCORD_CLIENT_SECRET");
const DISCORD_CLIENT_ID = "1555853808955822120";
const DISCORD_TOKEN_URL = "https://discord.com/api/oauth2/token";
const DISCORD_REVOKE_URL = "https://discord.com/api/oauth2/token/revoke";
const DISCORD_REDIRECT_URI = "https://studycrowd-51fdd.web.app/auth-callback";

exports.discordOauth = onRequest(
  { secrets: [discordClientSecret], invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed. Use POST." });
      return;
    }

    const secret = (discordClientSecret.value() || "").trim();
    if (!secret) {
      logger.error("DISCORD_CLIENT_SECRET is not set.");
      res.status(500).json({ error: "Server configuration error." });
      return;
    }

    const { action, code, redirect_uri, refresh_token, token } = req.body || {};
    const body = new URLSearchParams({
      client_id: DISCORD_CLIENT_ID,
      client_secret: secret,
    });

    let url;
    if (action === "exchange") {
      if (!code || typeof code !== "string") {
        res.status(400).json({ error: 'Missing "code".' });
        return;
      }
      body.set("grant_type", "authorization_code");
      body.set("code", code);
      body.set("redirect_uri", typeof redirect_uri === "string" && redirect_uri ? redirect_uri : DISCORD_REDIRECT_URI);
      url = DISCORD_TOKEN_URL;
    } else if (action === "refresh") {
      if (!refresh_token || typeof refresh_token !== "string") {
        res.status(400).json({ error: 'Missing "refresh_token".' });
        return;
      }
      body.set("grant_type", "refresh_token");
      body.set("refresh_token", refresh_token);
      url = DISCORD_TOKEN_URL;
    } else if (action === "revoke") {
      if (!token || typeof token !== "string") {
        res.status(400).json({ error: 'Missing "token".' });
        return;
      }
      body.set("token", token);
      body.set("token_type_hint", "access_token");
      url = DISCORD_REVOKE_URL;
    } else {
      res.status(400).json({ error: 'Invalid "action". Use "exchange", "refresh", or "revoke".' });
      return;
    }

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body,
      });
      const text = await response.text();
      res.status(response.status).set("Content-Type", "application/json").send(text || "{}");
    } catch (error) {
      logger.error("discordOauth upstream error:", error);
      res.status(502).json({ error: "Upstream Discord request failed." });
    }
  }
);

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
