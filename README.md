# crucible

Repeatable tests for coding models. A test is a prompt in `tests/<test>/PROMPT.md`; a run gives it to one model in a sealed VM and keeps what comes back.

## Usage

Needs Linux with read-write `/dev/kvm` and Nix.

```sh
bin/run cheminformatics stub
bin/run cheminformatics claude-opus-5-5 --login ~/claude-token
```

`bin/run <test> <model> [--harness H] [--effort E] [--login FILE]` runs `claude-*` models through Claude Code, at medium effort unless told otherwise. The login is a `claude setup-token` token and must live outside this repository. `stub` runs a script in place of an agent and needs no login.

`bin/login-test` runs the stub with a throwaway login and fails if the guest could read it.

## Runs

A run lands in `runs/<test>/<model>/<UTC timestamp>/`: `run.json` (model, harness, effort and a hash of the VM and prompt), `transcript.jsonl`, `tree.tar.zst`, `check.log`, `console.log` and `metrics.json` (time, tokens, tool calls, test and clippy results). Each run also gets a holistic `summary.md` written by the model named in `SUMMARIZER`; changing that model means regenerating every summary.

- Every run boots a fresh VM with 2 vCPUs, 3 GB RAM and a 32 GB disk. The guest gets the prompt, never this repository, and reaches only the Nix cache, crates.io, GitHub and the model API.
- The login stays on the host, which adds it to the guest's Messages API requests: the guest can use it but never read it, so no artifact can carry it.
- A second VM builds and tests the tree; model-written code never runs on the host.
- A run whose transcript or tree mentions this repository or another run is invalid; `bin/metrics` lists the matches under `contamination`.

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or [MIT license](LICENSE-MIT) at your option.
