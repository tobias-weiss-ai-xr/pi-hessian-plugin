# Changelog

All notable changes to pi-hessian-plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **tsconfig.json**: `moduleResolution: "node"` removed in TS 7 — changed to `"bundler"`
- **TypeScript**: `extensions/index.ts` now included in type-checking; added missing `cost` field and `ProviderModelConfig` annotation to models
- **Dockerfile/Dockerfile.dev**: Fixed UID 1000 conflict with `node` user; removed `ENV HESSIAN_API_KEY` (security); fixed `as`→`AS` casing; fixed schema/skills copying to plugin directory
- **schema/placeholder.json**: Replaced empty stub with full JSON Schema for config validation
- **Makefile**: Fixed `tsc` target calling non-existent script; fixed `.DPHONY`→`.PHONY` typo
- **src/generate-hessian-config.sh**: Moved helper functions before their first use to prevent `command not found` at runtime
- **CI workflow**: Tests now build and use local image instead of pulling from GHCR
- **src/hessian.ts**: Fixed `registerCommand` call signature to match pi's `ExtensionAPI`

### Added
- Initial repository structure
- TypeScript plugin for pi coding agent
- Hessian.AI / TUD API integration
- Profile-based model selection (production, development, budget)
- Memory layer with caching, metrics, and usage tracking
- Management commands: refresh, list-models
- Shell scripts for configuration generation
- Interactive setup wizard
- Docker images for linux/amd64 and linux/arm64
- Comprehensive documentation

---

## [1.0.0] - 2025-07-27

### Added
- **Pi package format**: Now installable via `pi install` (following the pi-memory pattern — see [pi-memory README](https://github.com/tobias-weiss-ai-xr/pi-memory) and the [agent-memory-research](https://github.com/tobias-weiss-ai-xr/agent-memory-research) survey [[arXiv 2512.13564](https://arxiv.org/abs/2512.13564)])
- **Provider auto-registration**: Extension registers TUD provider with 7 models via `pi.registerProvider()`
- **Usage skill**: `/skill:hessian-models` documents available models and usage
- **Clean `package.json` manifest**: `pi` key with `extensions` and `skills` paths

### Changed
- **Architecture transformation**: From shell-script config generator + Docker → pi package with TypeScript extension
  - Old: `src/*.sh` generated `pi.json` config, copied files, needed Docker/Makefile
  - New: Extension calls `pi.registerProvider()` at startup — zero config, no filesystem writes
- **README**: Complete rewrite reflecting pi package lifecycle
- API key resolution now uses pi's built-in auth stack (auth.json / env vars / /login)

### Removed
- Shell scripts (`src/*.sh`, `sandbox/*.sh`) — superseded by pi package auto-registration
- Docker files (Dockerfile, Dockerfile.dev) — packages are self-contained, no container needed
- Makefile — package is managed via `pi install` / `pi update`
- Sandbox, showcase mode, test suite — legacy from old generator-based approach
- `.github/workflows/docker-build-push.yml` — no Docker builds needed
- `schema/`, `test/`, `.githooks/` — unused legacy directories

---

## [0.1.0] - 2025-07-25

### Added
- Initial release with legacy shell-script architecture
- Hessian.AI model list fetching and config generation
- Profile system (production, development, budget)
- Docker build infrastructure
