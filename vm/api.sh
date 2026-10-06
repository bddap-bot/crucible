exec 2>/dev/null
login=$(<"$CRUCIBLE_LOGIN_FILE")
read -r -t 10 request
case $request in
  "POST /v1/messages "* | "POST /v1/messages?"* | "POST /v1/messages/count_tokens "* | "POST /v1/messages/count_tokens?"*) ;;
  *)
    printf 'HTTP/1.1 403 Forbidden\r\nContent-Length: 0\r\nConnection: close\r\n\r\n'
    exit
    ;;
esac
headers=()
while read -r -t 10 header && header=${header%$'\r'} && [ -n "$header" ]; do
  case ${header,,} in
    authorization:* | x-api-key:* | host:* | connection:* | proxy-*) ;;
    *) headers+=("$header") ;;
  esac
done
{
  printf '%s\r\n' "${request%$'\r'}" "Host: api.anthropic.com" "Authorization: Bearer $login" "Connection: close" "${headers[@]}" ""
  cat
} | socat - OPENSSL:api.anthropic.com:443
