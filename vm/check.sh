exec >/dev/virtio-ports/check 2>&1
install -d -o check -g users /home/check/work
runuser -u check -- tar -C /home/check/work -x </dev/disk/by-id/virtio-tree
manifest=$(find /home/check/work -name Cargo.toml -not -path '*/target/*' -printf '%d %p\n' | sort -n | sed -n '1s/^[0-9]* //p')
dir=$(dirname "${manifest:-/home/check/work/Cargo.toml}")
step() {
  runuser -l check -c "cd $(printf %q "$dir") && timeout 1h nix-shell -p cargo rustc clippy --run $(printf %q "cargo $*")"
}
test=0
step test --workspace --no-fail-fast || test=$?
clippy=0
step clippy --workspace --all-targets --message-format=short || clippy=$?
jq -n --argjson test "$test" --argjson clippy "$clippy" '$ARGS.named' >/dev/virtio-ports/status
