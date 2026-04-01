const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const DECK_DIR = path.join(__dirname, 'decks');

app.use((req, res, next) => { const start = Date.now(); res.on('finish', () => console.log(`${req.method} ${req.url} ${res.statusCode} ${Date.now() - start}ms`)); next(); });

app.get('/healthz', (_, res) => res.send('ok'));

function flattenCards(data) {
  if (data.cards) return data.cards;
  if (data.sections) return data.sections.flatMap(s => s.cards.map(c => ({ ...c, section: s.name })));
  return [];
}

function getDecks() {
  return fs.readdirSync(DECK_DIR).filter(f => f.endsWith('.json')).map(f => {
    const id = f.replace('.json', '');
    const slug = id.replace(/-\d{4}-\d{2}-\d{2}$/, '');
    const data = JSON.parse(fs.readFileSync(path.join(DECK_DIR, f)));
    return { id, slug, name: data.name, count: flattenCards(data).length };
  });
}

app.get('/api/decks', (_, res) => res.json(getDecks()));

app.get('/api/decks/:id', (req, res) => {
  const file = path.join(DECK_DIR, `${req.params.id}.json`);
  if (!fs.existsSync(file)) return res.status(404).json({ error: 'deck not found' });
  const data = JSON.parse(fs.readFileSync(file));
  res.json({ name: data.name, cards: flattenCards(data) });
});

// Root: list available decks
app.get('/', (_, res) => {
  const decks = getDecks();
  const links = decks.map(d => `<li><a href="/${d.slug}">${d.name}</a> (${d.count} cards)</li>`).join('');
  res.send(`<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Flash Cards</title>
    <style>body{font-family:system-ui,sans-serif;background:#1a1a2e;color:#eee;padding:2rem}
    a{color:#e94560;text-decoration:none;font-size:1.2rem}a:hover{text-decoration:underline}
    li{margin:0.5rem 0}h1{margin-bottom:1rem}</style></head>
    <body><h1>⚡ Flash Cards</h1><ul>${links}</ul></body></html>`);
});

// Deck page: serve deck.html for any valid slug
app.get('/:slug', (req, res) => {
  const deck = getDecks().find(d => d.slug === req.params.slug);
  if (!deck) return res.status(404).send('Deck not found');
  res.sendFile(path.join(__dirname, 'public', 'deck.html'));
});

app.listen(PORT, () => console.log(`Flash cards app listening on :${PORT}`));
