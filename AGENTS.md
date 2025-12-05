# Repository Guidelines

## Project Structure & Module Organization
- Root scripts to run the tool container: `run.sh` (main), `run2.sh` (shim to `run.sh`), `run-dev.sh`, `run_all.sh`.
- Docker image definition in `Dockerfile`; supporting entrypoint and helpers in `entrypoint.sh`, `utils.sh`, `update_bashrc`, `update-motd.sh`.
- Installation scripts for packaged tools in `scripts/` (invoked by `run_all.sh` or `pkg_add`); package manifest in `scripts/packages.tsv`.
- User utilities and backups in `home/`, `backup/`, and `logs/` (mounted by run scripts). Version tracked in `version`.
- Python backup helper lives at `src/backup.py`.

## Build, Test, and Development Commands
- `make build [TAG=vX.Y.Z]`: build the Docker image `marioaugustorama/devops-tools` with the current version/tag.
- `make push [TAG=...]`: push the built image to the registry.
- `make tag-latest`: tag the current build as `latest` and push.
- `make run [TAG=...]`: run the container using `run.sh`.
- `pkg_add list|status|install ...`: manage tool installations inside the image at runtime.

## Coding Style & Naming Conventions
- Shell scripts: `bash`, `set -euo pipefail` preferred; keep scripts idempotent and retry-friendly for network downloads.
- Python: prefer standard library, small functions; use explicit exits on errors (`sys.exit`).
- File naming: scripts under `scripts/` are `kebab-case.sh`; package names match the script basename and manifest entries.
- Keep comments minimal and clarifying (why, not what).

## Testing Guidelines
- No formal test suite; validate builds with `make build` and runtime sanity via `pkg_add list` and `pkg_add install --all` inside the container.
- For backup flow, run `./run.sh backup` and check tarball creation under `backup/`.
- When adding new installer scripts, ensure they succeed when run standalone and are safe to re-run.

## Commit & Pull Request Guidelines
- Use clear, imperative commit messages (e.g., “Add pkg_add package manifest”, “Harden backup script”).
- For PRs: describe the change, expected impact on image size/startup, and any manual verification (build command, runtime checks). Link related issues if applicable.

## Security & Configuration Tips
- Keep `STRICT_CHECKSUM` enabled (default) during builds to verify downloaded artifacts.
- Avoid baking secrets; prefer mounting kubeconfig/credentials at runtime via `run.sh`/`run2.sh`.
- When adding new packages, use pinned versions or checksum verification where upstream supports it.
