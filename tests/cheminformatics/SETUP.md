# cheminformatics: setup

- The agent starts in an empty working directory, `~/work`. Nix, git and the harness CLIs are installed; there is no Rust toolchain, and nothing else is provisioned.
- Context window: 1M tokens where the harness offers a choice (Claude Code: the `[1m]` model suffix).
- After the agent's turn the guest runs `cargo test --workspace --no-fail-fast` and `cargo clippy --workspace --all-targets` at the shallowest `Cargo.toml` in `~/work`, with the Rust toolchain of the pinned nixpkgs.
