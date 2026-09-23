cred=$CREDENTIALS_DIRECTORY
tree=/sys/firmware/qemu_fw_cfg/by_name/opt/tree/raw

in_work() {
  runuser -l "$1" -w CLAUDE_CODE_OAUTH_TOKEN -c "cd work && $(printf '%q ' "${@:2}")"
}

if [ -e "$tree" ]; then
  exec >/dev/virtio-ports/check 2>&1
  install -d -o check -g users /home/check/work
  zstd -dc "$tree" | in_work check tar -x
  cargo() { in_work check timeout 1h nix-shell -p cargo rustc clippy --run "$(command -v check) $*"; }
  test=0
  cargo test --workspace --no-fail-fast || test=$?
  clippy=0
  cargo clippy --workspace --all-targets --message-format=short || clippy=$?
  jq -n --argjson test "$test" --argjson clippy "$clippy" '$ARGS.named' >/dev/virtio-ports/status
  exit
fi

case $(<"$cred/harness") in
  claude-code)
    CLAUDE_CODE_OAUTH_TOKEN=$(<"$cred/login")
    export CLAUDE_CODE_OAUTH_TOKEN
    ;;
  codex)
    install -d -o agent -g users /home/agent/.codex
    install -m 600 -o agent -g users "$cred/login" /home/agent/.codex/auth.json
    ;;
esac
mapfile -d '' argv <"$cred/argv"
argv[0]=$(command -v "${argv[0]}")
install -d -o agent -g users /home/agent/work
in_work agent "${argv[@]}" <"$cred/prompt" >/dev/virtio-ports/transcript || :
unset CLAUDE_CODE_OAUTH_TOKEN
tar -C /home/agent/work --exclude-caches-all --zstd -c . >/dev/virtio-ports/tree || [ $? = 1 ]
