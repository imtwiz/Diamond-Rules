import express from "express";
import OpenAI from "openai";

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

    const verified = candidateRules.filter(r => r.verified === true).slice(0, 8);
    const rulesText = verified.length
      ? verified.map(r => `Rule ${r.ruleNumber} | ${r.topic}\nSummary: ${r.summary}\nRuling: ${r.ruling}\nOfficial text: ${r.officialText || "(not stored)"}\nSource: ${r.sourceLabel || r.officialSource || "(not supplied)"}\nExceptions: ${(r.exceptions || []).join("; ")}`).join("\n\n")
      : "NO VERIFIED LOCAL RULE RECORDS WERE RETRIEVED.";

    const history = conversation.slice(-8).map(m => `${m.role}: ${m.text}`).join("\n");
    const prompt = `You are Diamond Rules, a game-day Little League rules reference assistant.
Current context: ${context.season} ${context.sport}, ${context.division}, ${context.gameType}.
STRICT RULES:
1. Base the ruling ONLY on the VERIFIED RULE RECORDS below.
2. Never invent a rule number, subsection, penalty, exception, approved ruling, quotation, or division applicability.
3. If supplied records do not establish the answer, set requiresOfficialVerification=true, confidence="Low", and say the official current Little League rulebook must be checked.
4. Do not claim this app is affiliated with or endorsed by Little League.
5. Keep the explanation concise and useful during a game.
6. Return JSON only with keys: ruling, explanation, ruleNumbers, exceptions, confidence, requiresOfficialVerification.
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
    console.error(err);
    res.status(500).json({
      ruling: "Unable to verify",
      explanation: "The AI service could not complete a verified rules lookup.",
      ruleNumbers: [], exceptions: [], confidence: "Low", requiresOfficialVerification: true
    });
  }
});

const port = Number(process.env.PORT || 8787);
app.listen(port, "0.0.0.0", () => console.log(`Diamond Rules API listening on ${port}`));
