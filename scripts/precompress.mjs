// Writes .br and .gz copies next to compressible frontend files, so the server sends
// them as-is (app/server/web serves name.br / name.gz by Accept-Encoding).
//   node scripts/precompress.mjs <dir>
import { readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join, extname } from 'node:path';
import { brotliCompressSync, constants, gzipSync } from 'node:zlib';

const dir = process.argv[2];
if (!dir) {
  console.error('usage: node scripts/precompress.mjs <dir>');
  process.exit(2);
}
const types = new Set(['.html', '.js', '.css', '.svg', '.json', '.webmanifest', '.txt', '.map', '.ttf']);
let files = 0;
let before = 0;
let after = 0;

function walk(path) {
  for (const name of readdirSync(path)) {
    const full = join(path, name);
    if (statSync(full).isDirectory()) {
      walk(full);
      continue;
    }
    if (!types.has(extname(name)) || name.endsWith('.br') || name.endsWith('.gz')) continue;
    const data = readFileSync(full);
    if (data.length < 1024) continue; // not worth a second request path
    const br = brotliCompressSync(data, { params: { [constants.BROTLI_PARAM_QUALITY]: 11 } });
    const gz = gzipSync(data, { level: 9 });
    // keep a copy only when it actually saves bytes
    if (br.length < data.length) writeFileSync(full + '.br', br);
    if (gz.length < data.length) writeFileSync(full + '.gz', gz);
    files++;
    before += data.length;
    after += br.length;
  }
}

walk(dir);
console.log(`precompressed ${files} files: ${(before / 1024).toFixed(0)} KB → ${(after / 1024).toFixed(0)} KB (brotli)`);
