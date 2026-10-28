import { test, expect, mock } from 'claude-code/testing';

const HASH = 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
const BAND = {
  plugin: 'routing-status', component: 'AbovePrompt', requestId: 'routing',
  viewport: { columns: 100, rows: 30, isFullscreen: false },
  props: { hasSurvey: false, isWorking: false, maxRows: 4, bodyColumns: 100,
    scroll: { offset: 0, bodyRows: 4 }, view: {} },
} as const;
const state = (count: number, playbook: string | null = 'bug-fix') => JSON.stringify({
  version: 1, selected_playbook: playbook,
  loaded_principles: Array.from({ length: count }, (_, i) => ({ id: `p${i}`, path: `/skills/p${i}` })),
});

function fixtures(on, env = { HOME: '/home/test' }) {
  const clock = mock.clock(on);
  mock.env(on, env);
  const source = { id: 'abc', exists: true, raw: state(7), denied: false, paths: [] as string[], hold: null as null | Promise<void>, readStarted: null as null | (() => void) };
  on('session.id', () => ({ value: source.id }));
  on('fs.exists', ($, e) => { source.paths.push(e.path); return { value: source.exists }; });
  on('fs.read', async () => {
    const raw = source.raw;
    source.readStarted?.();
    if (source.hold) await source.hold;
    return source.denied ? { deny: 'Unreadable source' } : { value: raw };
  });
  on('session.start', () => ({ cwd: '/work' }));
  on('classic.SessionStart', () => ({}));
  on('ui.render', () => ({ type: 'Text', props: {}, children: ['Existing band'] }));
  return { clock, source };
}
const start = $ => $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' });

for (const surface of ['terminal', 'desktop', 'vscode'] as const) {
  test(`ready label preserves existing band while idle and working on ${surface}`, async ($, on) => {
    fixtures(on);
    await start($);
    for (const isWorking of [false, true]) {
      const ui = await $.ui.mount({ ...BAND, surface, props: { ...BAND.props, isWorking } });
      expect(await ui.find({ type: 'Text', text: 'Bug fix · 7 principles' })).toBeDefined();
      expect(await ui.find({ type: 'Text', text: 'Existing band' })).toBeDefined();
      await ui.unmount();
    }
  });
}

test('missing state shows no playbook, then polls updates and singular count', async ($, on) => {
  const { source, clock } = fixtures(on);
  source.exists = false;
  await start($);
  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' });
  expect(await ui.find({ type: 'Text', text: 'No playbook · 0 principles' })).toBeDefined();
  source.exists = true;
  source.raw = state(1, null);
  await clock.advance(1000);
  expect(await ui.find({ type: 'Text', text: 'No playbook · 1 principle' })).toBeDefined();
  source.raw = state(3, 'feature');
  await clock.advance(1000);
  expect(await ui.find({ type: 'Text', text: 'Feature · 3 principles' })).toBeDefined();
  expect(await ui.find({ type: 'Text', text: 'Existing band' })).toBeDefined();
  expect(source.paths[0]).toBe(`/home/test/.local/state/agent-routing/claude/${HASH}.json`);
});

test('malformed and unreadable state show unavailable and recover', async ($, on) => {
  const { source, clock } = fixtures(on);
  source.raw = '{';
  await start($);
  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' });
  expect(await ui.find({ type: 'Text', text: 'Routing state unavailable' })).toBeDefined();
  for (const raw of [state(2).replace('"p1"', '"p0"'), '{"version":2}', state(1).replace('/skills/p0', 'relative')]) {
    source.raw = raw;
    await clock.advance(1000);
    expect(await ui.find({ type: 'Text', text: 'Routing state unavailable' })).toBeDefined();
  }
  source.raw = state(2);
  source.denied = true;
  await clock.advance(1000);
  expect(await ui.find({ type: 'Text', text: 'Routing state unavailable' })).toBeDefined();
  source.denied = false;
  await clock.advance(1000);
  expect(await ui.find({ type: 'Text', text: 'Bug fix · 2 principles' })).toBeDefined();
});

test('clear and session changes discard old labels; compact does not inflate count', async ($, on) => {
  const { source, clock } = fixtures(on);
  await start($);
  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' });
  source.id = 'new-session';
  source.exists = false;
  await $.classic.SessionStart({ source: 'clear' });
  expect(await ui.find({ type: 'Text', text: 'No playbook · 0 principles' })).toBeDefined();
  expect(await ui.find({ type: 'Text', text: 'Bug fix · 7 principles' })).toBeUndefined();
  source.exists = true;
  source.raw = state(2);
  await $.classic.SessionStart({ source: 'compact' });
  await clock.advance(2000);
  expect(await ui.find({ type: 'Text', text: 'Bug fix · 2 principles' })).toBeDefined();
});

test('override root expands home exactly like the router', async ($, on) => {
  const { source } = fixtures(on, { HOME: '/home/test', AGENT_ROUTER_STATE_DIR: '~/routing' });
  await start($);
  expect(source.paths).toEqual([`/home/test/routing/claude/${HASH}.json`]);
});

test('a stale in-flight read cannot restore the previous session label', async ($, on) => {
  const { source, clock } = fixtures(on);
  await start($);
  const ui = await $.ui.mount({ ...BAND, surface: 'terminal' });
  let release!: () => void;
  source.raw = state(9);
  source.hold = new Promise<void>(resolve => { release = resolve; });
  const entered = new Promise<void>(resolve => { source.readStarted = resolve; });
  const pending = clock.advance(1000);
  await entered;
  source.id = 'new-session';
  source.exists = false;
  const clearing = $.classic.SessionStart({ source: 'clear' });
  release();
  source.hold = null;
  await pending;
  await clearing;
  expect(await ui.find({ type: 'Text', text: 'No playbook · 0 principles' })).toBeDefined();
  expect(await ui.find({ type: 'Text', text: 'Bug fix · 9 principles' })).toBeUndefined();
});


test('narrow layouts keep the principle count visible', async ($, on) => {
  const { source } = fixtures(on);
  source.raw = state(7, 'a-very-long-playbook-name');
  await start($);
  const ui = await $.ui.mount({ ...BAND, surface: 'terminal', viewport: { ...BAND.viewport, columns: 22 },
    props: { ...BAND.props, bodyColumns: 22 } });
  expect(await ui.find({ type: 'Text', text: 'A very… · 7 principles' })).toBeDefined();
});
