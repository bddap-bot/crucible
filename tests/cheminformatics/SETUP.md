# cheminformatics: setup

- Start: an empty `~/work`, passwordless sudo, Nix, git and the harness CLIs. No Rust toolchain.
- Context window: Claude Code runs request 1M tokens (the `[1m]` model suffix).
- Check: `cargo test --workspace --no-fail-fast` and `cargo clippy --workspace --all-targets` at the shallowest `Cargo.toml`, with the pinned nixpkgs' toolchain, in a fresh VM given only the tree.
