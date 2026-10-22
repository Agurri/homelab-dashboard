'use strict';

const fs = require('node:fs');
const path = require('node:path');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, '..', 'data');
const MACHINES_FILE = path.join(DATA_DIR, 'machines.json');

fs.mkdirSync(DATA_DIR, { recursive: true });

if (!fs.existsSync(MACHINES_FILE)) {
  fs.writeFileSync(MACHINES_FILE, JSON.stringify([], null, 2));
  console.log('Created machine inventory:', MACHINES_FILE);
} else {
  console.log('Machine inventory already exists:', MACHINES_FILE);
}

console.log('Migration complete.');
