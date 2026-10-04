import express from "express";
import OpenAI from "openai";

const nullableFields = ["penalty", "award", "ballStatus", "example", "decisionType", "hardRule", "judgment", "appeal"];
const answerProperties = {
  ruling: { type: "string" }, explanation: { type: "string" },
  ruleNumbers: { type: "array", items: { type: "string" } },
  exceptions: { type: "array", items: { type: "string" } },
  confidence: { type: "string", enum: ["Low", "Medium", "High"] },
  requiresOfficialVerification: { type: "boolean" },
  ...Object.fromEntries(nullableFields.map(key => [key, { type: ["string", "null"] }]))
};
const answerSchema = { type: "object", properties: answerProperties, required: Object.keys(answerProperties), additionalProperties: false };

const app = express();
app.use(express.json({ limit: "256kb" }));

app.get("/", (_req, res) => res.json({ status: "ok", service: "Diamond Rules API" }));
app.get("/health", (_req, res) => res.json({
  status: "ok",
  service: "Diamond Rules API",
  openaiConfigured: Boolean(process.env.OPENAI_API_KEY),
  model: process.env.OPENAI_MODEL || "gpt-5.6"
}));
app.get("/health/openai", async (_req, res) => {
  if (!process.env.OPENAI_API_KEY) {
    return res.status(503).json({ status: "error", openaiConfigured: false, openaiReachable: false, reason: "OPENAI_API_KEY is not configured" });
  }
  try {
    const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    await client.models.list();
    res.json({ status: "ok", openaiConfigured: true, openaiReachable: true, model: process.env.OPENAI_MODEL || "gpt-5.6" });
  } catch (err) {
    res.status(503).json({ status: "error", openaiConfigured: true, openaiReachable: false, reason: err?.status === 401 ? "API key rejected" : "OpenAI connection failed" });
  }
});

app.post("/ask", async (req, res) => {
  try {
    if (!process.env.OPENAI_API_KEY) return res.status(503).json({ error: "AI service is not configured" });

    const { question, context, candidateRules = [], conversation = [] } = req.body ?? {};
    if (!question || !context) return res.status(400).json({ error: "Missing question/context" });

    const verified = candidateRules.filter(r =>
      r.verified === true &&
      r.organization === context.organization &&
      r.sport === context.sport &&
      r.season === context.season &&
      Array.isArray(r.divisions) && r.divisions.includes(context.division) &&
      Array.isArray(r.gameTypes) && r.gameTypes.includes(context.gameType)
    ).slice(0, 8);
    const allowedNumbers = [...new Set(verified.map(r => String(r.ruleNumber)))];
    const responseSchema = {
      ...answerSchema,
      properties: {
        ...answerProperties,
        ruleNumbers: { type: "array", items: allowedNumbers.length ? { type: "string", enum: allowedNumbers } : { type: "string" } }
      }
    };
    const rulesText = verified.length
      ? verified.map(r => `Rule ${r.ruleNumber} | ${r.topic}\nSummary: ${r.summary}\nRuling: ${r.ruling}\nDecision type: ${r.decisionType || "(not established)"}\nRule requirement: ${r.hardRule || "(not established)"}\nUmpire judgment: ${r.judgment || "(none specified)"}\nAppeal/protest: ${r.appeal || "(not established)"}\nDetails: ${r.details || "(not established)"}\nPenalty: ${r.penalty || "(not established)"}\nBase award: ${r.award || "(not established)"}\nBall status: ${r.ballStatus || "(not established)"}\nExample: ${r.example || "(not supplied)"}\nOfficial text: ${r.officialText || "(not stored)"}\nSource: ${r.sourceLabel || r.officialSource || "(not supplied)"}\nExceptions: ${(r.exceptions || []).join("; ")}`).join("\n\n")
      : "NO VERIFIED LOCAL RULE RECORDS WERE RETRIEVED.";

    const history = conversation.slice(-8).map(m => `${m.role}: ${m.text}`).join("\n");
    const prompt = `You are Diamond Rules, a game-day baseball and softball rules reference assistant.
Current context: ${context.organization}, ${context.season} ${context.sport}, ${context.division}, ${context.gameType}.
STRICT RULES:
1. Base the ruling ONLY on the VERIFIED RULE RECORDS below.
2. Never invent a rule number, subsection, penalty, exception, approved ruling, quotation, or division applicability.
3. If supplied records do not establish the answer, set requiresOfficialVerification=true, confidence="Low", and say the official current governing organization rulebook must be checked.
4. Never mix governing organizations. Use only records matching the selected organization.\n5. Do not claim this app is affiliated with or endorsed by Little League or USSSA.
6. Explain the conditions and practical application in a few clear sentences. Include what happens to the batter and runners.
7. Return JSON only with keys: ruling, explanation, ruleNumbers, exceptions, confidence, requiresOfficialVerification, penalty, award, ballStatus, example, decisionType, hardRule, judgment, appeal. All added fields must be strings or null.
8. State the established penalty, base award (who receives which base and from what reference point), and live/dead-ball status separately. Never treat an absent consequence as "no penalty" or "no award". Use null for unestablished fields, explicitly identify missing consequences in the explanation, and set requiresOfficialVerification=true if needed to answer the question.
10. Separate rule requirements from facts judged by the umpire. Copy appeal/protest limitations only from supplied records. Never claim every judgment can be challenged, or confuse a defensive runner/batting-order appeal with a protest.
9. An example must illustrate only conditions established by the supplied records. Do not generalize a specific case to every interference or obstruction situation.
VERIFIED RULE RECORDS:
${rulesText}
RECENT CONVERSATION:
${history}
QUESTION:
${question}`;

    const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    const response = await client.responses.create({
      model: process.env.OPENAI_MODEL || "gpt-5.6",
      input: prompt,
      text: { format: { type: "json_schema", name: "rules_answer", strict: true, schema: responseSchema } },
      store: false
    });

    const raw = response.output_text.trim().replace(/^\`\`\`json\s*/i, "").replace(/\`\`\`$/i, "").trim();
    const parsed = JSON.parse(raw);
    const allowed = new Set(verified.map(r => String(r.ruleNumber)));
    parsed.ruleNumbers = Array.isArray(parsed.ruleNumbers) ? parsed.ruleNumbers.filter(n => allowed.has(String(n))) : [];
    if (parsed.ruleNumbers.length === 0) {
      parsed.requiresOfficialVerification = true;
      parsed.confidence = "Low";
    }
    res.json(parsed);
  } catch (err) {
    const code = err?.code || err?.error?.code;
    console.error("Rules lookup failed", { status: err?.status, code });
    if (["credit_balance_exhausted", "insufficient_quota"].includes(code) || err?.type === "insufficient_quota") {
      return res.status(503).json({ error: "AI service credits exhausted", code: "AI_CREDITS_EXHAUSTED" });
    }
    if (err?.status === 429) {
      return res.status(429).json({ error: "AI service request limit reached", code: "AI_RATE_LIMITED" });
    }
    res.status(500).json({
      ruling: "Unable to verify",
      explanation: "The AI service could not complete a verified rules lookup.",
      ruleNumbers: [], exceptions: [], confidence: "Low", requiresOfficialVerification: true
    });
  }
});

const port = Number(process.env.PORT || 8787);
app.listen(port, "0.0.0.0", async () => {
  console.log(`Diamond Rules API listening on ${port}`);
  if (!process.env.OPENAI_API_KEY) {
    console.log("OpenAI startup check: NOT CONFIGURED");
    return;
  }
  try {
    const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    await client.models.list();
    console.log("OpenAI startup check: CONNECTED");
  } catch (err) {
    console.log(`OpenAI startup check: FAILED (${err?.status || "connection error"})`);
  }
});
