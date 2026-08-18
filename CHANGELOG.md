# Changelog

All notable changes to Darkian Studio public releases are documented here. This file follows a simplified keep-a-changelog style. Releases are published on GitHub Releases; APKs are attached there.

## [1.0.0-beta.6] - 2026-08-18

### Added
- **Voice-to-text input**: speak a prompt; it is transcribed in-app via the Web Speech API and streamed into an inverted top dropdown, then formatted to markdown by the small "big-pickle" model before being sent to chat.
- **User skills**: skills from `~/.agents/skills` are now loaded via dsterm's `silentRun` (no SAF grant required).
- **Vision**: image-capable models can now see images read from files in agent chat.
- **MCP management screen** with an add-dialog and optional description; MCP servers are now wired as agent tools and forward configured environment variables.
- **GitHub agent tools**: issues, pull requests, workflows, and commits.
- **Full internationalization**: hardcoded UI strings wired to `AppLocalizations` across the marketplace, hamburger menus, and settings; all 16 non-English locales completed (370/370 keys).
- **Adaptive Material 3 responsive layout system**; persistent panels embedded via `DsPaneHost` docking and `DsAdaptiveSheet`.
- **Editor**: toggle breakpoints at the cursor (Ctrl+Shift+B); in-document word completions with color icons by kind; CM6 as the single completion UI (Flutter overlay dropped); LSP completion results echoed back via a `requestId` bridge channel.
- **Theme**: per-theme accent derivation for CM6 bundle themes.
- **Marketplace**: Hugging Face logo on model cards.
- **Clone**: dsterm pre-check and simplified clone input (owner/repo + ssh/https).
- **Compact (phone) UI**: smaller editor/terminal/chat font defaults.
- Nav bar and command palette icons migrated to codicons.

### Changed
- Marketplace install taxonomy clarified; on-disk extensions are the source of truth.
- Extension-host message handling replaced with a dispatch table; node/netcat discovery memoized and kill/error helpers de-duplicated.
- Extensions nav label renamed to Marketplace.
- Welcome screen action block and recent projects centered on wide screens.
- Token estimator aligned with opencode; heavy directories excluded from ingestion.
- Welcome screen palette kept in sync with darkian/light editor themes.

### Fixed
- Chat: `ref.listen` moved into `build` (startup assertion crash fixed); voice-mode codicon used for the voice button.
- LSP: tolerate a null range in content changes (full-document replacement) — startup crash fixed.
- Skills indexed by frontmatter/directory name instead of file basename.
- UI: left inset no longer reserved behind the nav rail; landscape status strip and nav-gap layout fixed.
- Editor: language completions queried via `languageDataAt`; theme completion popup and color icons by kind; finer CM6 highlighting for installed themes; installed themes mapped to CM6 by most-general scope.
- Extensions: reconciled snapshot propagated to installed/catalogue UI; install/uninstall errors logged with stack + step markers.
- Theme: canonical syntax color extraction corrected; GitHub dark highlight no longer layered over light themes; gilded accent restored on reopen.
- AI: per-id tool-call indices in the local chat transport; tool calls folded into the target in place.
- Termux: OpenSSL added so installing curl on a fresh Termux won't break the runtime.
- Editor: Exit Workspace moved to the bottom of the workspace submenu behind a divider.
- Updates: offer equal-core beta releases instead of reporting "up to date".

### Removed
- Theme translation probe diagnostic screen (added then removed during beta 6).

---

## [1.0.0-beta.5] - 2026-08-14

### Added
- Local on-device GGUF inference run entirely through dsterm — load models offline, no API key or network needed for inference.
- A full on-device inference stack: protocol client, model resolution, fill-in-the-middle (FIM) with Rust-side template resolution, and tool calling for local GGUF models.
- Priority scheduler for local models — per-model queues, concurrency, reference counting, sequence allocation.
- Inference performance pass — KV cache reuse, warm-up, batching, streaming, memory live-wiring, and context reuse.
- Local-on-device image/context retrieval pipeline (DSPack) with ranking, context injection, and budgeting.
- GitHub cloud workspaces — sign in with GitHub OAuth, browse and clone repos, and work on remote files through a GitHub filesystem backend with local caching.
- Git panel for remote workspaces via the GitHub Git Data API plus a minimal GitHub Actions integration with per-step job logs.
- Remote-safe guards so local-only actions are disabled or clearly identified inside a remote workspace.
- Agent chat rework — streaming messages, tool cards, agent state, syntax-highlighted diffs, and OpenCode-style markdown rendering.
- Expanded AI tools: workspace search, grep, tree, stat, edit with fuzzy-replacer chain and diff output, web tools (search/fetch/extract), workspace.run, todowrite, askQuestion, and an agent.spawn sub-agent tool.
- Token tracking with compaction/pruning, cache policy, and transport retry.
- Full internationalization (i18n) infrastructure with 18 languages and a locale picker.
- Model marketplace (Hugging Face): search, sort, pagination, README rendering, parameter counts, installed filter, and install/load/offload of GGUF models with real file sizes and a 30-minute download timeout.
- Extension marketplace (OpenVSX): browse and open extension details; DSPacks coming-soon placeholder.
- PostHog analytics with a safe enabled-guard for CI/test builds.
- A remote feature flag (builtin_models_enabled) that can hide the built-in provider server-side without an app update.
- In-page eruda developer-tools console toggle in the browser chrome.
- Vector GitMark icon set across notes, menus, and the command palette; codicon icon set with tinted marks.
- Branded intro animation on the welcome screen before first use.

### Changed
- Chat syntax highlighting and user bubbles now inherit design tokens and the active editor theme instead of hardcoded colors.
- Bottom sheets, dialogs, the command palette, file switcher, and model picker all share a single soft blurred, dimmed backdrop.
- The built-in free provider is split out under its own 'Builtin' label; per-model system prompts and a positive-form system prompt with tiered tool retrieval for small models.
- AI settings screen reworked; scrollable provider picker; inline model labeling; gated local inference.
- Programming-related screens (DAP, host suite, tasks, problems, settings search, GitHub repos) migrated to the DS surface primitives and design tokens.
- Darkian Dark is the default first-launch palette; Darkian Light was dropped.
- Slash completions load a single bundled skills index instead of many fragile per-directory asset declarations.

### Fixed
- Remote workspace search matches file names by substring instead of missing them.
- Workspace.run returns the real exit code and stderr, applies timeouts, and wraps JSON output without a FormatException.
- Tool outputs strip the JSON envelope so users see meaningful content instead of raw payloads.
- Reasoning and tool-call rows stay structured per-turn instead of merging into one blob; copy button and ActionsGroup are per-turn.
- Model README renders as markdown; real file sizes shown (HF tree endpoint has sizes); nested memory_estimate parsed correctly.
- The webview backdrop sizing fixed (moved to didChangeDependencies) and the eruda floating button dropped in favor of the chrome toggle.
- The built-in provider feature flag is fail-open when PostHog is unconfigured, so the provider never vanishes in dev/test.

### Removed
- GitHub Copilot provider, device-code sign-in flow, and probe screens — removed; proved not worth the complexity for the API used.
- The unused save button from the editor app-bar chrome (save remains available from the special-keys bar).
- Darkian Light theme.

### Known limitations
- On-device model quality and speed depend on device hardware; very large GGUF models may not fit in memory on low-end devices.
- GitHub cloud workspaces require an active network connection and GitHub OAuth; offline work is limited to the local-file cache.
- GitHub Actions on remote workspaces covers core run/list/log flows; advanced workflows are not yet surfaced.

---

## [1.0.0-beta.1] - Unreleased (first public beta)

### Added
- First public beta of Darkian Studio (Android APK via GitHub Releases).
- Onboarding runtime setup with a single copy-paste command.
- `install.sh` setup script, runtime-aware for Termux, Linux, and macOS, with progress/error output and a post-install verification step.
- In-app **Check for updates** (Settings → About) plus a best-effort startup update check against GitHub Releases.
- In-app runtime verification during onboarding (node / dsterm / code-server).
- Diagnostics logs and crash reports surfaced entirely inside the app.
- Branded intro animation on first launch before the welcome screen.
- AI chat agent with tool calling — read/write files, workspace search, and command execution in the runtime — plus streaming responses, thinking-mode toggle, and session persistence.
- AI providers: OpenAI-compatible endpoints, a built-in free provider (no key required), OpenRouter, Together, Fireworks, Groq, Mistral, Ollama, and Local GGUF.
- Local GGUF model marketplace (Hugging Face): browse, install, load, and unload models with parameter counts, quantisation, and memory estimates.
- AI inline completions (fill-in-the-middle) via chat-style and legacy completion endpoints.
- Model Context Protocol (MCP) client for AI tool and context integration.
- Per-model system prompt controls for local chat models.

### Changed
- All `debugPrint()` diagnostics in the app are now routed through the DS
- logging system so they appear in Diagnostics logs and crash reports.
- Darkian Dark is the default first-launch theme palette.

### Known limitations
- `dsterm` remote on Windows is not supported in this beta.
- No Play Store distribution; APKs are GitHub Releases only.

---

## Release notes template (used per release)

```
## [X.Y.Z] - YYYY-MM-DD

### Added
-

### Changed
-

### Fixed
-

### Known limitations
-
```
