if [ -e /dev/disk/by-id/virtio-tree ]; then
  exec check
fi

cred=$CREDENTIALS_DIRECTORY
mapfile -d '' argv <"$cred/argv"
argv[0]=$(command -v "${argv[0]}")
install -d -o agent -g users /home/agent/work
runuser -l agent -c "cd work && $(printf '%q ' "${argv[@]}")" <"$cred/prompt" >/dev/virtio-ports/transcript || :
tar -C /home/agent/work --exclude-caches-all --zstd -c . >/dev/virtio-ports/tree || [ $? = 1 ]
