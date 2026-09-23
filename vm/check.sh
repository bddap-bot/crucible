manifest=$(find . -name Cargo.toml -not -path '*/target/*' -printf '%d %p\n' | sort -n | head -n 1 | cut -d ' ' -f 2-)
cd "$(dirname "${manifest:-.}")" || exit
cargo --version
cargo test --workspace --no-fail-fast
echo "cargo test exit $?"
cargo clippy --workspace --all-targets --message-format=short
echo "cargo clippy exit $?"
