'use strict';

const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const PORT = Number(process.env.PORT || 3000);
const PUBLIC_DIR = path.join(__dirname, 'public');
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml'
};

function json(res, status, data) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(data, null, 2));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => {
      body += chunk;
      if (body.length > 1e6) reject(new Error('Payload too large'));
    });
    req.on('end', () => {
      try { resolve(body ? JSON.parse(body) : {}); }
      catch (error) { reject(error); }
    });
    req.on('error', reject);
  });
}

function loadMachines() {
  const file = path.join(DATA_DIR, 'machines.json');
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    return [];
  }
}

function saveMachines(machines) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  fs.writeFileSync(path.join(DATA_DIR, 'machines.json'), JSON.stringify(machines, null, 2));
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (url.pathname === '/api/health') {
    return json(res, 200, {
      status: 'ok',
      version: '1.0.0',
      uptime: Math.round(process.uptime()),
      time: new Date().toISOString()
    });
  }

  if (url.pathname === '/api/config') {
    return json(res, 200, {
      proxmoxConfigured: Boolean(process.env.PVE_URL && process.env.PVE_TOKEN_SECRET),
      truenasConfigured: Boolean(process.env.TRUENAS_URL && process.env.TRUENAS_API_KEY),
      refreshSeconds: Number(process.env.REFRESH_SECONDS || 15)
    });
  }

  if (url.pathname === '/api/machines' && req.method === 'GET') {
    return json(res, 200, loadMachines());
  }

  if (url.pathname === '/api/machines' && req.method === 'POST') {
    try {
      const machine = await readBody(req);
      if (!machine.hostname || !machine.vmid) {
        return json(res, 400, { error: 'hostname and vmid are required' });
      }
      const machines = loadMachines();
      const existing = machines.findIndex(item => String(item.vmid) === String(machine.vmid));
      const record = {
        vmid: String(machine.vmid),
        hostname: machine.hostname,
        status: machine.status || 'unknown',
        ip: machine.ip || '',
        node: machine.node || '',
        category: machine.category || 'utilities',
        tags: Array.isArray(machine.tags) ? machine.tags : [],
        url: machine.url || '',
        cpu: Number(machine.cpu || 0),
        memoryUsed: Number(machine.memoryUsed || 0),
        memoryTotal: Number(machine.memoryTotal || 0),
        diskUsed: Number(machine.diskUsed || 0),
        diskTotal: Number(machine.diskTotal || 0)
      };
      if (existing >= 0) machines[existing] = record;
      else machines.push(record);
      saveMachines(machines);
      return json(res, 200, record);
    } catch (error) {
      return json(res, 400, { error: error.message });
    }
  }

  let filePath = path.join(PUBLIC_DIR, url.pathname === '/' ? 'index.html' : url.pathname);
  filePath = path.normalize(filePath);
  if (!filePath.startsWith(PUBLIC_DIR)) return json(res, 403, { error: 'Forbidden' });

  fs.readFile(filePath, (error, content) => {
    if (error) return json(res, 404, { error: 'Not found' });
    res.writeHead(200, { 'Content-Type': MIME[path.extname(filePath)] || 'application/octet-stream' });
    res.end(content);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Homelab Dashboard listening on http://0.0.0.0:${PORT}`);
});
