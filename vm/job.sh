if [ -e /dev/disk/by-id/virtio-tree ]; then
  exec check
fi

cred=$CREDENTIALS_DIRECTORY
mapfile -d '' argv <"$cred/argv"
case ${argv[0]} in
  claude)
    CLAUDE_CODE_OAUTH_TOKEN=$(<"$cred/login")
    export CLAUDE_CODE_OAUTH_TOKEN
    ;;
  codex)
    install -d -o agent -g users /home/agent/.codex
    install -m 600 -o agent -g users "$cred/login" /home/agent/.codex/auth.json
    ;;
esac
argv[0]=$(command -v "${argv[0]}")
install -d -o agent -g users /home/agent/work
runuser -l agent -w CLAUDE_CODE_OAUTH_TOKEN -c "cd work && $(printf '%q ' "${argv[@]}")" <"$cred/prompt" >/dev/virtio-ports/transcript || :
unset CLAUDE_CODE_OAUTH_TOKEN
tar -C /home/agent/work --exclude-caches-all --zstd -c . >/dev/virtio-ports/tree || [ $? = 1 ]
