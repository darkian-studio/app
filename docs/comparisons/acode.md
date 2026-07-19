# Darkian Studio vs Acode

> Versions compared: Darkian Studio 1.0.0-beta (first public beta, July 2026) and Acode 1.12.6 (released June 18, 2026). DS capabilities were verified against the application and its runtime (`dsterm`); Acode capabilities were verified against the Acode and `acodex_server` (`axs`) source repositories.

## Executive summary

Acode is a lightweight, open-source code editor and web IDE for Android, built on the Ace editor. It is designed for editing and managing code on a phone, with a terminal backed by a Rust PTY server (`axs`), Git/SSH support, and a community plugin store. Darkian Studio is a mobile-first development environment that runs on Android and Linux. Its editor, terminal, language intelligence, debugger, Git, and extensions all operate against one runtime reached through `dsterm`, a Rust server that bridges PTY, language servers, debug adapters, and an extension host over a single port. The two tools share the Android stage but differ in architecture: Acode layers IDE conveniences on top of a mobile editor, while DS routes every core function through one runtime abstraction.

## How each tool works

```
Developer
  ↓
Editor (Ace in Acode; web editor in DS)
  ↓
Runtime bridge (Acode plugin layer → axs; DS → dsterm)
  ↓
Runtime (the shell environment axs / dsterm talks to)
  ↓
Git / LSP / terminal  (DS also routes debugger and extensions here)
```

| | Acode | Darkian Studio |
|---|---|---|
| Editing | Ace editor (in-app web view) | Code editor (in-app web view) |
| Runtime bridge | `axs` (Rust): PTY over WebSocket + stdio→WS LSP proxy | `dsterm` (Rust): PTY, LSP bridge, DAP bridge, extension-host bridge, execution |
| Runtime | `axs` talks to the shell environment it is configured to reach (e.g. Alpine via proot, or any host running `axs`) | Termux on Android, or a `dsterm` host on Linux/macOS |
| Language intelligence | LSP installed as plugins, bridged to `axs` | Built-in LSP client against runtime or extension-host servers |
| Debugger | Interactive JavaScript console only | DAP bridge to debug adapters in the runtime |
| Extensions | Acode community plugins (JavaScript addons) | Open VS X extensions run through a `vscode`-API host |

## Shared goals

Both tools aim to let developers write and manage code from an Android device:

- Editing with syntax highlighting for many languages
- Multi-file editing with tabs
- An integrated terminal
- Git workflows (clone, commit, push, pull, branches)
- SSH / remote file access
- A plugin/extension system
- Offline, on-device development

## Architectural differences

### Runtime bridge scope

`axs` (the backend Acode uses) is a focused Rust server: it serves a PTY over WebSocket (default port 8767, system PTY) and, as a separate subcommand, proxies a stdio language server to WebSocket. It does not itself host a debugger, an extension host, or Git. Those live in the Acode app and talk to `axs` only for the terminal and the LSP transport.

`dsterm` (the backend DS uses) is a broader Rust server on the same default port. Beyond the PTY and an LSP bridge, it also exposes a DAP bridge (proxy to any Debug Adapter Protocol server), an extension-host bridge (a Node.js process bridge), a Model Context Protocol bridge, and silent/streaming command execution. Crucially, `dsterm` is a multiplexed RPC endpoint rather than a collection of unrelated bridges: every feature above is reached through one connection, which is why the terminal, language servers, debugger, extension host, and command execution all share a single runtime session. DS routes those features through that one server.

### One runtime for everything

In DS, the editor, terminal, Git, LSP servers, debugger, and extensions all communicate through one runtime abstraction. That means they share one environment: the same `PATH`, the same filesystem, the same environment variables, the same installed SDKs, and the same Python (or other) interpreter. A package you install in the terminal is visible to the language server and the debugger without additional configuration. In Acode, the terminal and an LSP server can run in the same `axs` environment, but the debugger is only the in-editor JavaScript console and extensions are separate JavaScript addons that do not share a single hosted runtime the way DS's extension host does.

### Language intelligence

Acode provides completion and IntelliSense via LSP through community plugins. A plugin declares a language server plus a structured installer (`apk`, `npm`, `pip`, `cargo`, `githubRelease`); the client speaks WebSocket and `axs` launches the stdio server. LSP is an add-on you install and configure per language. Darkian Studio includes a built-in LSP client: completion, hover, signature help, go-to-definition/references/implementation, rename, formatting, code actions, diagnostics, folding, semantic tokens, and inlay hints are handled by the LSP client against language servers running in the runtime or the extension host. In DS, LSP is a built-in client capability; the language servers themselves still need to be available in the runtime.

### Debugging

Acode offers an interactive JavaScript console for evaluating and debugging JS in the editor. It is a single, useful feature, not a general debugger. Darkian Studio provides debugging through the Debug Adapter Protocol: `dsterm` proxies any DAP debug adapter over WebSocket, and DS renders breakpoints, variable inspection, watch expressions, the call stack, and a debug console. DAP allows debuggers for multiple languages to integrate through a common protocol, so DS can debug any language that ships a standard DAP adapter through that adapter rather than a language-specific console.

### Git

Both support core Git workflows. Acode includes Git, SSH, FTP/SFTP, and GitHub integration through its UI and plugins. Darkian Studio provides Git status, staging, commit, push/pull, stash, branch management, a conflict-resolution UI, and blame, operating against the runtime's Git. DS surfaces Git as a dedicated panel with conflict resolution and blame; Acode exposes it through its file and Git tooling. Note that DS's Git support is Git remote support (clone, commit, push/pull to a remote); it is not a GitHub-specific integration with pull requests, issues, or OAuth.

### Extensions and compatibility

Acode has a community Plugin Store with plugins (language servers, themes, AI tools, build tools, framework support) written as JavaScript addons against Acode's own plugin API. Darkian Studio integrates the Open VS X marketplace as its extension backend, so users can browse and install VS Code-compatible extensions (`.vsix`) directly. DS runs these through an extension host (`ds-extension-host`) that implements a subset of the `vscode` API that extensions import.

Important nuance: **availability of an extension in Open VS X does not guarantee compatibility.** Compatibility depends on which portions of the `vscode` API the extension actually uses.

What the DS extension host implements:

- **Fully wired to the host:** `workspace.fs` (read/write/stat/readDirectory/rename/copy/delete), `workspace.getConfiguration` (including updates sent to the host), `window` messages, quick-pick and input-box prompts, `languages.createDiagnosticCollection` (surfaces diagnostics into DS), `commands.registerCommand` / `executeCommand`, `Uri`, and the standard value types (`Position`, `Range`, `Diagnostic`, `CompletionItem`, `WorkspaceEdit`, `Hover`, `DocumentSymbol`, `InlayHint`, `SemanticTokens`, and others).
- **Present but inert (no-op or black-hole) stubs:** `window.createTerminal` returns an object that does nothing, so extension-provided terminals do not appear in DS; `window.activeTextEditor` / `visibleTextEditors` are empty; `workspace.applyEdit` and `workspace.openTextDocument` return placeholder empty documents; `debug.*`, `tasks.*`, `scm.*`, notebooks, and comments are no-ops. Extensions that contribute diagnostics, commands, configuration, or file-system access work; extensions that depend on the editor surface, a built-in terminal, the debug view, or SCM UI will not function as they do in VS Code.
- Microsoft-exclusive extensions (Remote-SSH, Remote-Containers, WSL, Live Share, Codespaces) are blocked by an allow/deny list.
- The implemented API surface will expand over time as additional extension categories are supported; the wired stubs above are not a permanent ceiling.

### Project management

Acode manages files and projects with an in-app file browser, FTP/SFTP, and GitHub sync. Darkian Studio includes workspace roots, trusted workspaces, tasks, and test runners (pytest, Flutter, Cargo collectors). Acode is oriented toward file and folder editing with optional remote sync; DS includes those project-level structures.

### Offline capability

Both work offline once set up. Acode's `axs` terminal and plugins run locally. DS runs locally against Termux (or a local `dsterm`) and only needs network for remote connections or update checks.

## Feature comparison

Legend: ✅ supported · ⚠️ partial / opt-in / stubbed · ❌ not supported

| Capability | Darkian Studio (1.0.0-beta) | Acode (1.12.6) |
|---|---|---|
| Multi-file editing with tabs | ✅ | ✅ |
| Syntax highlighting (many languages) | ✅ | ✅ |
| Command palette | ✅ | ✅ |
| Find / replace (including all files) | ✅ | ✅ (all-files search is beta in Acode) |
| Minimap | ✅ | ❌ |
| Integrated terminal | ✅ (dsterm-backed) | ✅ (axs PTY, Alpine proot, no root) |
| Built-in LSP client | ✅ | ⚠️ installed as plugins |
| Extension-provided terminal in the IDE | ❌ (host terminal is inert) | ⚠️ via plugin API |
| Debugging (DAP: breakpoints, variables, watch, stack) | ✅ | ⚠️ JS console only |
| Interactive JS console | ❌ | ✅ |
| Git: clone / commit / push / pull / branch | ✅ | ✅ |
| Git: conflict resolution UI | ✅ | ⚠️ basic |
| Git: stash | ✅ | ⚠️ via tooling |
| Git: blame | ✅ | ⚠️ via tooling |
| SSH / remote file access | ✅ (SFTP/FTP/FTPS/WebDAV, dsterm) | ✅ (SSH, FTP/SFTP) |
| Git remote support | ✅ | ✅ |
| Extension marketplace (browse/install) | ✅ (Open VS X) | ✅ (community Plugin Store) |
| VS Code-compatible extensions | ⚠️ partial `vscode` API surface (see above) | ❌ |
| Themes / fonts customization | ✅ | ✅ |
| HTML / Markdown live preview | ✅ | ✅ |
| Test runner (pytest / Flutter / Cargo) | ✅ | ❌ |
| Tasks / build automation | ✅ | ⚠️ via plugins |
| Trusted workspace gating | ✅ | ❌ |
| Offline development | ✅ | ✅ |
| Runs on Android | ✅ | ✅ |
| Runs on Linux/macOS/Windows desktop | ⚠️ Linux only | ❌ |
| Remote runtime (connect to a host) | ✅ (dsterm to Linux/macOS) | ⚠️ terminal/LSP can run remotely; editor stays local |
| Shared runtime for editor/LSP/debugger/extensions | ✅ | ❌ |
| VS Code extension API surface | ⚠️ partial | ❌ |

## Runtime portability

This is one of the largest architectural differences between the two tools.

| | Acode | Darkian Studio |
|---|---|---|
| Runtime | Bundled environment (an `axs` instance, e.g. Alpine via proot) | External runtime abstraction reached over `dsterm` |
| Replace runtime | Limited (reconfigure the `axs` instance) | Yes (point `dsterm` at any Termux or Linux/macOS host) |
| Remote runtime | Limited (terminal/LSP only; editor stays local) | Yes (editor, LSP, debugger, and extensions all run remotely) |
| Multiple runtimes | No (one bundled environment per device) | Yes (switch the `dsterm` target per workspace) |

Acode ships a self-contained environment that lives on the device. DS deliberately separates the editor from the runtime: the editor is a client, and the runtime is whatever `dsterm` points at, so the runtime can be replaced, made remote, or swapped per workspace without changing the editor.

## When to choose Acode

- You want a fast, open-source Android editor with minimal setup and a built-in terminal.
- You do web and scripting work and value the interactive JavaScript console and Emmet.
- You prefer a turnkey community Plugin Store and a mature Android editing experience.
- You want an MIT-licensed tool available on the Play Store and F-Droid.
- You do not need structured (DAP) debugging beyond JavaScript.

## When to choose Darkian Studio

- You want language intelligence as a built-in client capability rather than a plugin you must install and configure per language.
- You need structured debugging (breakpoints, variables, watch, call stack) through a debug-adapter bridge to a real runtime.
- You want an environment on Android or Linux where the terminal, language servers, debugger, and extensions all run in the same runtime and share one `PATH`, filesystem, and set of SDKs.
- You want to install VS Code-compatible extensions from Open VS X, and you understand the extension API is a partial surface.
- You want Git conflict resolution, tasks, and test runners integrated into the workflow.

## Notes

- **Distribution.** Acode is available on the Play Store, F-Droid, and GitHub. Darkian Studio is distributed as a GitHub Releases APK and is not on the Play Store; setup requires a one-time command to provision the runtime. See the main README for installation steps.
- **Licensing.** Acode is open source under the MIT license. The DS application is proprietary; this support repository is open.
- **Windows remote runtime.** Connecting a DS workspace to a Windows-hosted `dsterm` endpoint is not supported in this beta; use Termux or a Linux/macOS host.
- **Extension scope.** DS runs VS Code extensions through an extension host that implements file system, commands, configuration, diagnostics, and UI-prompt APIs, but stubs the editor surface, terminals, debug, tasks, and SCM. Extensions that rely on those stubbed areas will not behave as in VS Code. Microsoft-exclusive remote extensions are blocked.
