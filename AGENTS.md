# AGENTS.md

## Layout

- `tests/<test>/`: `PROMPT.md`, fed to the harness on stdin, and `SETUP.md`.
- `vm/default.nix`: the guest and its harness packages; nixpkgs pinned in `sources.json`.
- `vm/job.sh`: the guest's job. Runs `check.sh` when a tree drive is attached, the agent otherwise.
- `vm/proxy.sh`: the guest's only network route, run on the host by QEMU per connection. It tunnels to port 443 of the hosts it lists.
- `vm/stub.sh`: the `stub` harness.

## bin/run

The agent VM gets the argv, prompt and login as systemd credentials. The login becomes `CLAUDE_CODE_OAUTH_TOKEN` for Claude Code and `~/.codex/auth.json` for Codex. The harness's own event stream and the tarred `~/work` reach host files over virtio ports as the guest writes them.

The check VM boots the same image on a fresh disk with the tree on a read-only drive, runs cargo as user `check`, and reports exit codes on a port only its root can write.

The login scan searches the artifacts for each string value or line of the login with 20+ characters. The host then writes `run.json`: `harness.version` from the pinned package, `setup` as the sha256 of the VM store path and prompt, `started`/`finished` from its own clock around the agent VM, and `check` from the check VM.

## bin/metrics

`bin/metrics <run-dir>` recomputes `metrics.json`. `tests.passed`, `tests.failed` and `clippy.warnings` are parsed from `check.log`, which the tree's code can write to. `contamination` is a case-insensitive grep of the transcript and tree for `bddap-bot/crucible`, `bddap-bot/chemrs` (run 0's code) and every other run's directory.

Run 0, under `runs/cheminformatics/claude-opus-5-5/`, was imported: it has only `run.json` and `metrics.json`, which `bin/metrics` cannot recompute.

A new harness needs its argv in `bin/run`, its login in `vm/job.sh`, its package in `vm/default.nix` and its transcript parser in `bin/metrics`.
