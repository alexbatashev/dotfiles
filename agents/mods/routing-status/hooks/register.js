const UNAVAILABLE = 'Routing state unavailable';
const EMPTY = 'No playbook · 0 principles';

function routingLabel(raw) {
  const value = JSON.parse(raw);
  if (!value || value.version !== 1 || !Array.isArray(value.loaded_principles) ||
      !(value.selected_playbook === null || typeof value.selected_playbook === 'string')) {
    throw new Error('Invalid routing state');
  }
  const ids = new Set();
  for (const entry of value.loaded_principles) {
    if (!entry || typeof entry.id !== 'string' || !entry.id || ids.has(entry.id) ||
        typeof entry.path !== 'string' || !entry.path.startsWith('/')) {
      throw new Error('Invalid principle state');
    }
    ids.add(entry.id);
  }
  const slug = value.selected_playbook;
  const name = slug === null ? 'No playbook' : slug.replace(/[-_]+/g, ' ').replace(/^./, c => c.toUpperCase());
  return `${name} · ${ids.size} ${ids.size === 1 ? 'principle' : 'principles'}`;
}

function fitLabel(label, width) {
  if (!width || label.length <= width) return label;
  const separator = label.lastIndexOf(' · ');
  if (separator < 0) return label.slice(0, Math.max(0, width - 1)) + '…';
  const count = label.slice(separator + 3);
  const available = width - count.length - 3;
  if (available < 2) return count;
  return label.slice(0, available - 1) + '… · ' + count;
}

async function publish($, state, label) {
  if (state.label === label) return;
  state.label = label;
  await $.ui.invalidate('ui.render');
}

async function readRouting($) {
  const session = await $.session.id();
  const home = await $.env.get('HOME');
  let root = await $.env.get('AGENT_ROUTER_STATE_DIR');
  if (root === undefined) root = `${home}/.local/state/agent-routing`;
  if (root === '~' || root.startsWith('~/')) root = home + root.slice(1);
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(session));
  const hash = Array.from(new Uint8Array(digest), byte => byte.toString(16).padStart(2, '0')).join('');
  const path = `${root || '.'}/claude/${hash}.json`;
  const label = await $.fs.exists(path) ? routingLabel(await $.fs.read(path)) : EMPTY;
  return { session, label };
}

async function refresh($, state) {
  if (state.pending) return state.pending;
  const generation = state.generation;
  state.pending = (async () => {
    let label = UNAVAILABLE;
    try {
      const result = await readRouting($);
      if (result.session === await $.session.id()) label = result.label;
    } catch {}
    if (generation === state.generation) await publish($, state, label);
  })();
  try { await state.pending; } finally { state.pending = null; }
}

export function register(on) {
  const state = { label: UNAVAILABLE, generation: 0, pending: null, timer: null };
  on('session.start', async ($, e, next) => {
    await refresh($, state);
    if (!state.timer) state.timer = $.clock.every(1000, () => refresh($, state));
    return next(e);
  });
  on('classic.SessionStart', async ($, e, next) => {
    state.generation += 1;
    await publish($, state, UNAVAILABLE);
    if (state.pending) await state.pending;
    await refresh($, state);
    return next(e);
  });
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const { Box, Text } = $.ui.resolve(e);
    return Box({ flexDirection: 'column', children: [
      await next(e),
      Text({ dimColor: true, children: fitLabel(state.label, e.props.bodyColumns ?? e.viewport?.columns) }),
    ] });
  });
}
