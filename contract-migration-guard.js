#!/usr/bin/env node
// Simple guard: prevent dropping columns in contract stage without allowlist
const fs = require('fs');
const path = require('path');

const contractDir = path.join(process.cwd(), 'db', 'migrations', 'contract');
if (!fs.existsSync(contractDir)) {
  console.log('No contract migrations; skipping');
  process.exit(0);
}

const files = fs.readdirSync(contractDir).filter(f => f.endsWith('.sql'));
const forbidden = [/DROP\s+COLUMN/i, /DROP\s+TABLE/i];
for (const f of files) {
  const sql = fs.readFileSync(path.join(contractDir, f), 'utf8');
  for (const rule of forbidden) {
    if (rule.test(sql)) {
      console.error(`Forbidden DDL in ${f}: ${rule}`);
      process.exit(1);
    }
  }
}

console.log('Contract migration guard OK');
