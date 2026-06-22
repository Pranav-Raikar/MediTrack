// ─────────────────────────────────────────────────────────────────────────────
// functions/index.js  —  Firebase Cloud Function (Node.js)
//
// This runs on Firebase servers — NOT in the Flutter app.
// Your Claude API key stays here, safe from users.
//
// WHAT IT DOES:
//  - Receives a prompt from the Flutter app
//  - Verifies the user is logged in (Firebase Auth token)
//  - Calls Claude API and returns the summary
//
// SETUP (one-time):
//  1.  npm install -g firebase-tools
//  2.  firebase login
//  3.  cd functions && npm install
//  4.  firebase functions:secrets:set CLAUDE_API_KEY
//      (paste your Claude API key when prompted)
//  5.  firebase deploy --only functions
// ─────────────────────────────────────────────────────────────────────────────

const functions  = require('firebase-functions/v2');
const admin      = require('firebase-admin');
const Anthropic  = require('@anthropic-ai/sdk');

admin.initializeApp();

// Claude API key is stored as a Firebase Secret (never hardcoded)
const CLAUDE_KEY = functions.params.defineSecret('CLAUDE_API_KEY');

exports.generateHealthSummary = functions.https.onRequest(
  { secrets: [CLAUDE_KEY] },
  async (req, res) => {

    // ── CORS ────────────────────────────────────────────────────────────────
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      return res.status(204).send('');
    }

    // ── Verify Firebase Auth token ──────────────────────────────────────────
    const authHeader = req.headers.authorization || '';
    const token = authHeader.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    try {
      await admin.auth().verifyIdToken(token);
    } catch {
      return res.status(401).json({ error: 'Invalid token' });
    }

    // ── Call Claude API ─────────────────────────────────────────────────────
    const { prompt } = req.body;
    if (!prompt) {
      return res.status(400).json({ error: 'No prompt provided' });
    }

    try {
      const client = new Anthropic({ apiKey: CLAUDE_KEY.value() });

      const message = await client.messages.create({
        model:      'claude-sonnet-4-20250514',
        max_tokens: 600,
        system:     'You are a clinical AI assistant helping doctors in India. Be concise, factual, and always recommend professional judgment over AI output.',
        messages:   [{ role: 'user', content: prompt }],
      });

      const summary = message.content
        .filter(b => b.type === 'text')
        .map(b => b.text)
        .join('\n');

      return res.status(200).json({ summary });

    } catch (err) {
      console.error('Claude API error:', err);
      return res.status(500).json({ error: 'AI service error' });
    }
  }
);

// ── Drug interaction checker endpoint ───────────────────────────────────────
exports.checkDrugInteractions = functions.https.onRequest(
  { secrets: [CLAUDE_KEY] },
  async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      return res.status(204).send('');
    }

    const authHeader = req.headers.authorization || '';
    try {
      await admin.auth().verifyIdToken(authHeader.replace('Bearer ', ''));
    } catch {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { medicines } = req.body;
    const client = new Anthropic({ apiKey: CLAUDE_KEY.value() });

    const message = await client.messages.create({
      model:      'claude-sonnet-4-20250514',
      max_tokens: 300,
      messages:   [{
        role:    'user',
        content: `Check for drug interactions between: ${medicines.join(', ')}. List any risks in plain simple English. Max 80 words.`
      }],
    });

    return res.status(200).json({
      result: message.content.filter(b => b.type === 'text').map(b => b.text).join('')
    });
  }
);
