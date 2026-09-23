exec 2>/dev/null
read -r method target _
while read -r header && [ -n "${header%$'\r'}" ]; do :; done
for host in \
  api.anthropic.com api.openai.com auth.openai.com chatgpt.com \
  cache.nixos.org \
  crates.io index.crates.io static.crates.io \
  github.com api.github.com codeload.github.com objects.githubusercontent.com raw.githubusercontent.com release-assets.githubusercontent.com; do
  if [ "$method $target" = "CONNECT $host:443" ]; then
    printf 'HTTP/1.1 200 Connection established\r\n\r\n'
    exec socat - "TCP:$target"
  fi
done
printf 'HTTP/1.1 403 Forbidden\r\n\r\n'
