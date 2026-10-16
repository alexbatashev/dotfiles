#!/usr/bin/env node
// outline.mjs — print a plan as markdown for an agent that implements it
//   node outline.mjs plan.html
// Reads the page as it is, packed or not, and prints the numbered claim tree with its code, schemas and decisions.
// Mockups print only their caption and pins: open plan.html to see them.
import { readFileSync } from 'node:fs';

const path = process.argv[2];
if (!path) { console.error('usage: node outline.mjs plan.html'); process.exit(2); }
const page = readFileSync(path, 'utf8');
const body = page.slice(Math.max(0, page.search(/<body\b/i)));

const attrs = (s) => { const o = {}; s.replace(/([\w:.-]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+)))?/g, (m, k, a, b, c) => { o[k.toLowerCase()] = a ?? b ?? c ?? ''; return ''; }); return o; };
const unent = (s) => s.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&');
const inline = (html) => unent(html
  .replace(/<code>([\s\S]*?)<\/code>/gi, '`$1`')
  .replace(/<\/?(b|strong)>/gi, '**')
  .replace(/<small>([\s\S]*?)<\/small>/gi, ' — $1')
  .replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ').replace(/ ([.,;:])/g, '$1').trim();
const dedent = (text) => {
  const lines = text.replace(/<\\\/script/gi, '</script').replace(/^\s*\n|\n\s*$/g, '').split('\n');
  const indent = Math.min(...lines.filter((l) => l.trim()).map((l) => l.match(/^ */)[0].length));
  return lines.map((l) => l.slice(indent)).join('\n');
};
/** a block's text: its source <script> (never a call-row excerpt), else its own text without pins and templates */
const source = (inner) => {
  const script = inner.match(/<script\s+type=["']?text\/(?:plain|source)["']?(?![^>]*data-excerpt)[^>]*>([\s\S]*?)<\/script>/i);
  if (script) return dedent(script[1]);
  return dedent(unent(inner.replace(/<doc-pin[\s\S]*?<\/doc-pin>|<template[\s\S]*?<\/template>|<[^>]+>/g, '')));
};

const out = [];
const say = (...lines) => out.push('', ...lines);
const fence = (text, lang = '') => { const ticks = '`'.repeat(Math.max(3, ...[...text.matchAll(/`+/g)].map((m) => m[0].length + 1))); say(ticks + lang, text, ticks); };
const caption = (a) => { if (a.caption) say(`_${a.caption}_`); };
const pins = (inner) => {
  const list = [...inner.matchAll(/<doc-pin\b([^>]*)>([\s\S]*?)<\/doc-pin>/g)].map(([, raw, text]) => {
    const a = attrs(raw); const where = a.line ? `line ${a.line}` : a.old ? `old line ${a.old}` : '';
    return `- ${[where, a.title, inline(text)].filter(Boolean).join(': ')}`;
  });
  if (list.length) say(...list);
};

function code(kind, a, inner) {
  const file = a.file || a.src;
  say(`**${kind}:** ${[a.title, file !== a.title && file, a.lines && `lines ${a.lines}`, a.sha && `@${a.sha}`].filter(Boolean).join(' · ')}`);
  caption(a);
  const text = source(inner);
  if (text.trim()) fence(text, 'diff' in a ? 'diff' : a.lang || (file || '').split('.').pop() || '');
  else if (a.src) say(`Not packed yet: read \`${a.src}\`${a.lines ? ` lines ${a.lines}` : ''}.`);
  pins(inner);
}

function diagram(kind, a, inner) {
  say(`**${kind}${a.title ? `: ${a.title}` : ''}**`);
  caption(a);
  fence(source(inner), 'text');
  pins(inner);
}

function ask(a, inner) {
  const paragraphs = [...inner.matchAll(/<(p|h3|h4)\b[^>]*>([\s\S]*?)<\/\1>/gi)].map((m) => inline(m[2]));
  say(`**Decision${a.id ? ` \`${a.id}\`` : ''}:** ${paragraphs.shift() || a.q || ''}`, ...paragraphs);
  const answers = [];
  for (const [, label] of inner.matchAll(/<label\b[^>]*>([\s\S]*?)<\/label>/gi)) {
    const input = label.match(/<input\b([^>]*)>/i); if (!input) continue;
    const ia = attrs(input[1]);
    answers.push(ia.type === 'radio' || ia.type === 'checkbox' ? `- [${'checked' in ia ? 'x' : ' '}] ${inline(label)}` : `- ${inline(label)}: ${ia.value ?? ''}`);
  }
  for (const [, raw, text] of inner.matchAll(/<textarea\b([^>]*)>([\s\S]*?)<\/textarea>/gi)) answers.push(`- ${attrs(raw).name}: ${inline(text) || '(empty)'}`);
  for (const [, items] of inner.matchAll(/<ol\b[^>]*class=["'][^"']*\brank\b[^>]*>([\s\S]*?)<\/ol>/gi)) [...items.matchAll(/<li\b[^>]*>([\s\S]*?)<\/li>/gi)].forEach((li, i) => answers.push(`${i + 1}. ${inline(li[1])}`));
  if (answers.length) say(...answers);
}

const blocks = {
  'doc-code': (a, inner) => code('Code', a, inner),
  'doc-schema': (a, inner) => code('Schema', a, inner),
  'doc-calls': (a, inner) => diagram('Calls', a, inner),
  'doc-machine': (a, inner) => diagram('State machine', a, inner),
  'doc-flow': (a, inner) => diagram('Flow', a, inner),
  'doc-seq': (a, inner) => diagram('Sequence', a, inner),
  'doc-tree': (a, inner) => diagram('Files', a, inner),
  'doc-draft': (a, inner) => diagram('Draft', a, inner),
  'doc-mock': (a, inner) => { say(`**Mockup${a.title ? `: ${a.title}` : ''}** (open plan.html to see it)`); caption(a); pins(inner); },
  'doc-shot': (a, inner) => { say(`**Screenshot${a.title ? `: ${a.title}` : ''}** (open plan.html to see it)`); caption(a); pins(inner); },
  'doc-ask': ask,
  'doc-note': (a, inner) => say(`> **Note:** ${inline(inner)}`),
  'doc-quote': (a, inner) => say(`> ${inline(inner)}`, `> — ${[a.from, a.via].filter(Boolean).join(', ')}`),
  'doc-changes': (a) => say(`Files: ${['new', 'changed', 'deleted'].filter((k) => +a[k]).map((k) => `${a[k]} ${k}`).join(', ')}`),
};

// A claim's heading waits for its first <p>, the claim sentence. aux claims are headed by their sentence alone.
const stack = [{ no: '', level: 0, kids: 0 }];
const heading = (claim, text = '') => {
  if (claim.headed) return; claim.headed = true;
  say(`${'#'.repeat(claim.level + 1)} ${claim.aux ? text || claim.aux : `${claim.no} ${text}`.trim()}`);
  if (claim.at) say(`Place: \`${claim.at}\``);
};
const TOKEN = /<!--[\s\S]*?-->|<(?<skip>style|script|template)\b[\s\S]*?<\/\k<skip>>|<(?<close>\/?)doc-claim\b(?<claimAttrs>[^>]*)>|<(?<block>doc-(?!plan\b|claim\b)[a-z]+)\b(?<blockAttrs>[^>]*)>(?<inner>[\s\S]*?)<\/\k<block>>|<(?<text>h[1-3]|p|ul|ol)\b[^>]*>(?<textInner>[\s\S]*?)<\/\k<text>>/gi;

let quotes = 0;
for (const { groups: g } of body.matchAll(TOKEN)) {
  const claim = stack[stack.length - 1];
  if (g.close === '/') { if (stack.length > 1) stack.pop(); }
  else if (g.close === '') {
    const a = attrs(g.claimAttrs);
    const no = a.aux || (claim.no && !claim.aux ? `${claim.no}.` : '') + ++claim.kids;
    stack.push({ no, level: claim.level + 1, kids: 0, aux: a.aux, at: a.at });
  }
  else if (g.block) {
    if (!blocks[g.block]) continue;
    if (stack.length > 1) heading(claim);
    if (g.block === 'doc-quote' && !quotes++) say('## Why');
    blocks[g.block](attrs(g.blockAttrs), g.inner);
  }
  else if (g.text) {
    const tag = g.text.toLowerCase();
    if (tag[0] === 'h') say(`${'#'.repeat(+tag[1])} ${inline(g.textInner)}`);
    else if (tag === 'p' && stack.length > 1 && !claim.headed) heading(claim, inline(g.textInner));
    else if (tag === 'p') say(inline(g.textInner));
    else { if (stack.length > 1) heading(claim); say(...[...g.textInner.matchAll(/<li\b[^>]*>([\s\S]*?)<\/li>/gi)].map((li, i) => `${tag === 'ol' ? `${i + 1}.` : '-'} ${inline(li[1])}`)); }
  }
}
console.log(out.join('\n').trim());
