// Collect authored UI strings. Never collect runtime account, chat or room data.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sources = new Set();
for (const file of fs.readdirSync(path.join(root, 'scripts'))) {
  if (!file.endsWith('.gd') || ['app_language.gd', 'language_core.gd', 'language_malay.gd'].includes(file)) continue;
  for (const match of fs.readFileSync(path.join(root, 'scripts', file), 'utf8').matchAll(/"(?:[^"\\\n]|\\.)*"/g)) {
    let text;
    try { text = JSON.parse(match[0]); } catch { continue; }
    if (!/[A-Za-z]/.test(text) || text.length > 4000) continue;
    if (['res://', 'user://', 'https://', 'http://', 'shader_type'].some(part => text.includes(part))) continue;
    if (text.includes(' ') || text === text.toUpperCase() || /^[A-Z][a-z]+$/.test(text)) sources.add(text);
  }
}
fs.mkdirSync(path.join(root, 'localization'), {recursive:true});
fs.writeFileSync(path.join(root, 'localization/sources.json'), JSON.stringify([...sources].sort(), null, 2)+'\n');
console.log(`Collected ${sources.size} authored UI strings`);
