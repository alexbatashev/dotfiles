# Plan: make AI-provider config declarative (`home.nix` fix #2)

Extract the imperative `home.activation.configureAiProviders` block in `home.nix`
into a proper module with a single Nix source of truth.

## Key insight — the fix is asymmetric

Evidence from the on-disk files:

- **`~/.codex/config.toml` is tool-mutated and must stay writable.** Beyond
  hand-set `model`/`approval_policy`, codex itself writes `[projects."..."]`
  `trust_level` blocks and `[tui.model_availability_nux]` at runtime. A
  read-only store symlink would break codex recording trusted projects. This is
  almost certainly why the earlier declarative attempt was abandoned (the
  `.bak`/symlink-migration code). → **inject-only, keep the file writable.**
- **`~/.config/opencode/opencode.json` contains only generated content**
  (`$schema` + the `aperture` provider, no hand edits, no other providers).
  opencode reads it and doesn't rewrite it. → **Nix can own it fully.**

## `modules/ai-providers.nix`

**Single source of truth (`let`):** define the aperture provider (`name`,
`baseURL`, `envKey`) and the model map once. Both outputs derive from it — no
duplicated URL, no 120-line inline Python.

```nix
let
  aperture = { name = "Tailscale Aperture";
               baseURL = "http://ai.siren-pollux.ts.net/v1";
               envKey  = "TAILSCALE_APERTURE_API_KEY"; };
  models = { "anthropic/claude-sonnet-4.6" = "Claude Sonnet 4.6"; /* … */ };
in { … }
```

### 1. opencode → fully declarative

```nix
home.file.".config/opencode/opencode.json".text = builtins.toJSON {
  "$schema" = "https://opencode.ai/config.json";
  provider.aperture = {
    inherit (aperture) name; id = "aperture";
    npm = "@ai-sdk/openai-compatible"; api = aperture.baseURL;
    env = [ aperture.envKey ];
    models  = lib.mapAttrs (id: name: { inherit id name; }) models;
    options.baseURL = aperture.baseURL;
  };
};
```

Use `home.file` (not `xdg.configFile`) to stay robust on hosts where
`xdg.enable = false`, matching the nuc pattern. Deletes the entire Python block.

### 2. codex → data-in-Nix, thin idempotent inject

```nix
codexFragment = pkgs.writeText "codex-aperture.toml" ''
  [model_providers.aperture]
  name = "${aperture.name}"
  baseURL = "${aperture.baseURL}"
  envKey = "${aperture.envKey}"
'';
# activation (entryAfter writeBoundary):
#   undo any legacy symlink, touch if missing,
#   grep -q '^\[model_providers\.aperture\]$' || cat ${codexFragment} >> config.toml
```

Same grep-guard as today, but the payload comes from the Nix-generated fragment.
The ~20 lines of `.bak`/symlink-restore cruft fold into one `[ -L ] && rm` line.

### 3. Wire-up

- Add `./modules/ai-providers.nix` to `imports` in `home.nix`.
- Delete `home.activation.configureAiProviders` entirely.
- Leave `migrateLegacyDarwinAppsLink` (unrelated).

## Rollout note (one-time)

`~/.config/opencode/opencode.json` is currently a real file, so home-manager
refuses to clobber it on first apply. First switch after the change:
`home-manager switch -b backup …` (or `rm` it once). Subsequent switches are
clean.

## Trade-offs / open decision

- **codex stays inject-only** — non-negotiable; it self-writes trust blocks.
  Downside: if the provider def changes, the append won't *update* the existing
  block. Could add marker-delimited replace-in-place later, but it's more code
  touching a tool-owned file; leave simple.
- **opencode goes fully declarative** (recommended — file is 100% generated
  today). Only fails if opencode starts writing its own config (it doesn't).
  Hedge if desired: keep it writable and merge with `jq -s '.[0] * .[1]'` (jq is
  already on the system) — but that reintroduces imperative merge for no current
  benefit.

Net: `home.nix` drops ~120 lines, the model list becomes real Nix data, and the
only remaining imperative surface is the ~5-line codex inject that genuinely
needs to stay writable.
