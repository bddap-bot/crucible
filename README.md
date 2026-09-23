# crucible

Repeatable evaluations of coding agents. A test is a prompt. A run gives that prompt to one model, through one harness at one effort level, inside a sealed virtual machine, and keeps what comes back.

## Rules

- **Sealed VM.** Every run boots a fresh NixOS VM (`vm/`, nixpkgs pinned in `vm/sources.json`) with no shared directories. The guest receives the text of the test's `PROMPT.md` and the one model login the run needs; no other file from this repository or its host. Its disk is created for the run and deleted once the artifacts are out.
- **Same allotment.** 2 vCPUs, 3 GB RAM, 32 GB disk. The network is QEMU user-mode with `restrict=on`, so the guest reaches nothing directly, DNS included. Its one way out is an HTTPS proxy in `https_proxy`: QEMU runs `vm/proxy.sh` on the host for each connection, and it opens a tunnel only to port 443 of the hosts it lists (the model APIs, cache.nixos.org, crates.io and GitHub).
- **One prompt, one turn.** The prompt is delivered once, non-interactively, and nothing else is said. The agent has passwordless sudo and that network; what it does with them is part of what the run measures.
- **Explicit pins.** `run.json` records the model, the harness (name, version and exact command line) and the effort as separate fields, and a setup hash over the prompt and the VM. The host writes it from what it chose and saw: the command line it passed in, the pinned package's version, its own clock around the agent's VM and the check's exit codes.
- **Evidence leaves the guest as it happens.** The transcript is the harness's own event stream, written to a host file as the guest emits it; the turn counts as completed only if that stream ends with the harness's own success event. The working tree and the guest console come out the same way. Model-written code never runs on the host.
- **Verdicts come from outside the agent's VM.** The agent is root there, so the build/test/clippy pass runs in a second, fresh VM that receives only the tree and runs cargo as an unprivileged user; its exit codes reach the host on a port only that VM's root can write.
- **Untainted.** A run whose transcript or tree mentions this repository, `bddap-bot/chemrs` (run 0's code) or another run's directory is invalid. `bin/metrics` lists the matches as `contamination`.
- **Summaries.** Each run is summarized in `summary.md` by the model named in `SUMMARIZER`, weighing what held up against what broke; each finding a command can demonstrate cites the command. Changing the summarizer means regenerating every summary.

## Running

Needs Linux with read-write `/dev/kvm` and Nix. The VM includes Claude Code, which is unfree.

```sh
bin/run cheminformatics stub
bin/run cheminformatics claude-opus-5-5 --login ~/claude-token
bin/run cheminformatics gpt-6-sol --login ~/.codex/auth.json --effort high
```

`bin/run <test> <model> [--harness H] [--effort E] [--login FILE]` defaults the harness to the model's own CLI (Claude Code for `claude-*`, Codex for `gpt-*`) and the effort to medium. The login is a file outside this repository: a `claude setup-token` token for Claude Code, an `auth.json` for Codex. The guest holds it for the whole run, so use one you can revoke. The `stub` model runs a shell script in place of an agent, exercising the whole path without a model; its transcript records what the network reaches from inside the guest.

A finished run lands in `runs/<test>/<model>/<UTC timestamp>/` with `run.json`, `transcript.jsonl`, `tree.tar.zst` (the working tree without build outputs), `check.log` (the build/test/clippy pass), `console.log` (both VMs) and `metrics.json`; a summary adds `summary.md`. A run whose artifacts contain the login is discarded. In `metrics.json`, `tokens.input` counts every input token, cache reads and writes included. `bin/metrics <run-dir>` recomputes it.

Run 0 of the cheminformatics test, `runs/cheminformatics/claude-opus-5-5/2026-09-23/`, predates this harness: it holds only `run.json` and `metrics.json`, with figures taken from the statistics in its repository's README and its tree linked there.

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or [MIT license](LICENSE-MIT) at your option.
