cred=$CREDENTIALS_DIRECTORY
harness=$(<"$cred/harness")
model=$(<"$cred/model")
effort=$(<"$cred/effort")

as_agent() {
  runuser -l agent -w CLAUDE_CODE_OAUTH_TOKEN -c "cd work && $(printf '%q ' "$@")"
}

install -d -o agent -g users /home/agent/work

case $harness in
  claude-code)
    CLAUDE_CODE_OAUTH_TOKEN=$(<"$cred/login")
    export CLAUDE_CODE_OAUTH_TOKEN
    version=$(as_agent claude --version)
    agent=(claude -p --output-format stream-json --verbose --model "${model}[1m]" --effort "$effort" --dangerously-skip-permissions)
    ;;
  codex)
    install -d -o agent -g users /home/agent/.codex
    install -m 600 -o agent -g users "$cred/login" /home/agent/.codex/auth.json
    version=$(as_agent codex --version)
    agent=(codex exec --json --model "$model" -c "model_reasoning_effort=$effort" --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check -)
    ;;
  stub)
    version=
    agent=("$(command -v stub)")
    ;;
  *)
    echo "unknown harness: $harness" >&2
    exit 1
    ;;
esac

started=$(date -u +%FT%TZ)
status=0
as_agent "${agent[@]}" <"$cred/prompt" >/dev/virtio-ports/transcript || status=$?
finished=$(date -u +%FT%TZ)
unset CLAUDE_CODE_OAUTH_TOKEN

jq -n --arg version "$version" --arg started "$started" --arg finished "$finished" --argjson exit "$status" \
  '{version: (if $version == "" then null else $version end), argv: $ARGS.positional, started: $started, finished: $finished, exit: $exit}' \
  --args -- "${agent[@]}" >/dev/virtio-ports/meta
tar -C /home/agent/work --exclude-caches-all --zstd -c . >/dev/virtio-ports/tree || [ $? = 1 ]
as_agent timeout 1h nix-shell -p cargo rustc clippy --run "$(command -v check)" >/dev/virtio-ports/check 2>&1 ||
  echo "check exit $?" >/dev/virtio-ports/check
