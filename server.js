// Nexus Chat v2 — WebSocket Server + JSON Persistence
// Run: node server.js (listens on port from env.PORT or 3000)

const http = require('http');
const fs = require('fs');
const path = require('path');
const { WebSocketServer } = require('ws');
const { v4: uuidv4 } = require('uuid');

// ── Config ──────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const DB_PATH = path.join(DATA_DIR, 'messages.json');
const PUBLIC_DIR = path.join(__dirname, 'public');
const MAX_MESSAGES = 500;
const TYPING_TIMEOUT_MS = 3000;
const CLEANUP_INTERVAL_MS = 60_000;

// ── State ────────────────────────────────────────────────────────────
const clients = new Map(); // ws -> { id, userName, color, lastPing }
const typingTimers = new Map(); // userId -> setTimeout
let messages = [];           // in-memory message array

// ── JSON Persistence ─────────────────────────────────────────────────
fs.mkdirSync(DATA_DIR, { recursive: true });

function loadMessages() {
  try {
    if (fs.existsSync(DB_PATH)) {
      const raw = fs.readFileSync(DB_PATH, 'utf-8');
      messages = JSON.parse(raw);
      if (!Array.isArray(messages)) messages = [];
    }
  } catch (err) {
    console.error('[!] Failed to load messages:', err.message);
    messages = [];
  }
}

function saveMessages() {
  try {
    const tmp = DB_PATH + '.tmp';
    fs.writeFileSync(tmp, JSON.stringify(messages), 'utf-8');
    fs.renameSync(tmp, DB_PATH);
  } catch (err) {
    console.error('[!] Failed to save messages:', err.message);
  }
}

// ── Message CRUD ────────────────────────────────────────────────────
function getMessages(limit = 50) {
  const active = messages.filter(m => !m.deleted);
  return active.slice(-limit);
}

function addMessage(text, userId, userName, color) {
  const msg = {
    id: uuidv4(),
    text,
    userId,
    userName,
    color,
    createdAt: Date.now(),
    editedAt: null,
    deleted: false
  };
  messages.push(msg);
  saveMessages();
  return msg;
}

function deleteMessageById(id, userId) {
  const idx = messages.findIndex(m => m.id === id && !m.deleted);
  if (idx === -1) return { ok: false, reason: 'not_found' };
  if (messages[idx].userId !== userId) return { ok: false, reason: 'not_authorized' };
  messages[idx].deleted = true;
  saveMessages();
  return { ok: true };
}

function purgeOldMessages() {
  const active = messages.filter(m => !m.deleted);
  if (active.length > MAX_MESSAGES) {
    const excess = active.length - MAX_MESSAGES;
    let removed = 0;
    for (let i = 0; i < messages.length && removed < excess; i++) {
      if (!messages[i].deleted) {
        messages[i].deleted = true;
        removed++;
      }
    }
    saveMessages();
  }
}

// Load existing messages on startup
loadMessages();

// Auto-cleanup every minute
setInterval(purgeOldMessages, CLEANUP_INTERVAL_MS);
setInterval(saveMessages, 30_000); // periodic save as safety

// ── HTTP Server (static files) ───────────────────────────────────────
function mimeType(ext) {
  const map = {
    '.html': 'text/html;charset=utf-8',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon'
  };
  return map[ext] || 'application/octet-stream';
}

const server = http.createServer((req, res) => {
  // Health check
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', clients: clients.size, messages: messages.filter(m => !m.deleted).length }));
    return;
  }

  // Serve static files from public/
  let filePath = req.url === '/' ? '/index.html' : req.url;
  filePath = path.join(PUBLIC_DIR, filePath);

  // Security: prevent directory traversal
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not Found');
      return;
    }
    res.writeHead(200, { 'Content-Type': mimeType(path.extname(filePath)) });
    res.end(data);
  });
});

// ── WebSocket Server ─────────────────────────────────────────────────
const wss = new WebSocketServer({ server });

function broadcast(data, exclude = null) {
  const msg = JSON.stringify(data);
  for (const [ws] of clients) {
    if (ws !== exclude && ws.readyState === WebSocket.OPEN) {
      ws.send(msg);
    }
  }
}

function sendTo(ws, data) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(data));
}

function broadcastUsers() {
  const users = [];
  for (const [, info] of clients) {
    users.push({ id: info.id, userName: info.userName, color: info.color });
  }
  broadcast({ type: 'users', users });
}

// Handle incoming WebSocket messages
function handleMessage(ws, raw) {
  let data;
  try { data = JSON.parse(raw); } catch { return; }

  const me = clients.get(ws);
  if (!me) return;

  switch (data.type) {
    case 'join': {
      me.userName = (data.userName || '').trim() || 'مجهول';
      me.color = data.color || '#005c4b';
      sendTo(ws, {
        type: 'init',
        messages: getMessages(50),
        userId: me.id
      });
      broadcastUsers();
      break;
    }

    case 'message': {
      const text = (data.text || '').trim();
      if (!text) return;
      if (text.length > 10000) {
        sendTo(ws, { type: 'error', message: 'الرسالة طويلة جداً (الحد الأقصى 10000 حرف)' });
        return;
      }
      sendTo(ws, { type: 'msg_sent', tempId: data.tempId });
      const msg = addMessage(text, me.id, me.userName, me.color);
      broadcast({ type: 'new_message', message: msg });
      break;
    }

    case 'image': {
      const base64 = data.data || '';
      if (!base64.startsWith('data:image')) return;
      if (base64.length > 500_000) {
        sendTo(ws, { type: 'error', message: 'حجم الصورة كبير جداً (الحد الأقصى 500KB)' });
        return;
      }
      sendTo(ws, { type: 'msg_sent', tempId: data.tempId });
      const msg = addMessage(base64, me.id, me.userName, me.color);
      broadcast({ type: 'new_message', message: msg });
      break;
    }

    case 'delete': {
      const result = deleteMessageById(data.messageId, me.id);
      if (result.ok) {
        broadcast({ type: 'msg_deleted', messageId: data.messageId, userId: me.id });
      } else {
        const reason = result.reason === 'not_found'
          ? 'الرسالة غير موجودة'
          : 'لا يمكنك حذف هذه الرسالة';
        sendTo(ws, { type: 'error', message: reason });
      }
      break;
    }

    case 'typing': {
      const isTyping = !!data.typing;
      broadcast({ type: 'typing', userId: me.id, userName: me.userName, typing: isTyping }, ws);
      if (isTyping) {
        const existing = typingTimers.get(me.id);
        if (existing) clearTimeout(existing);
        typingTimers.set(me.id, setTimeout(() => {
          broadcast({ type: 'typing', userId: me.id, userName: me.userName, typing: false }, ws);
          typingTimers.delete(me.id);
        }, TYPING_TIMEOUT_MS));
      } else {
        const existing = typingTimers.get(me.id);
        if (existing) { clearTimeout(existing); typingTimers.delete(me.id); }
      }
      break;
    }

    case 'ping': {
      me.lastPing = Date.now();
      sendTo(ws, { type: 'pong' });
      break;
    }
  }
}

// ── Connection Lifecycle ─────────────────────────────────────────────
wss.on('connection', (ws) => {
  const id = uuidv4();
  clients.set(ws, { id, userName: 'مجهول', color: '#005c4b', lastPing: Date.now() });
  console.log(`[+] Client connected: ${id}  (total: ${clients.size})`);

  ws.on('message', (raw) => handleMessage(ws, raw.toString()));

  ws.on('close', () => {
    const info = clients.get(ws);
    if (info) {
      broadcast({ type: 'typing', userId: info.id, userName: info.userName, typing: false });
      const t = typingTimers.get(info.id);
      if (t) { clearTimeout(t); typingTimers.delete(info.id); }
    }
    clients.delete(ws);
    console.log(`[-] Client disconnected: ${info?.id}  (total: ${clients.size})`);
    broadcastUsers();
  });

  ws.on('error', (err) => {
    console.error(`[!] WebSocket error:`, err.message);
    clients.delete(ws);
    broadcastUsers();
  });
});

// ── Heartbeat (every 30s) ────────────────────────────────────────────
setInterval(() => {
  const now = Date.now();
  for (const [ws, info] of clients) {
    if (now - info.lastPing > 60_000) {
      ws.terminate();
      clients.delete(ws);
    }
  }
}, 30_000);

// ── Graceful Shutdown ───────────────────────────────────────────────
function shutdown() {
  console.log('\n[*] Shutting down...');
  saveMessages();
  wss.close(() => {
    server.close(() => {
      console.log('[*] Goodbye.');
      process.exit(0);
    });
  });
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

// ── Start ────────────────────────────────────────────────────────────
server.listen(PORT, () => {
  console.log(`╔══════════════════════════════════════╗`);
  console.log(`║   Nexus Chat v2 — Server Ready       ║`);
  console.log(`║   http://localhost:${PORT}              ║`);
  console.log(`║   WebSocket : ws://localhost:${PORT}    ║`);
  console.log(`║   Messages  : ${messages.filter(m => !m.deleted).length} saved         ║`);
  console.log(`╚══════════════════════════════════════╝`);
});
