prompt=$(cat)
machine='nproc && free -m && df -h / && findmnt -rn -o TARGET,SOURCE,FSTYPE'
network=$(
  cat <<'SH'
probe() { printf "%-40s %-6s " "$1" "$2"; curl -sS -o /dev/null -w "connect %{http_connect} http %{http_code}\n" --max-time 10 "${@:3}" "$1" 2>&1 | paste -sd " "; }
for url in https://cache.nixos.org/nix-cache-info https://crates.io/ https://index.crates.io/config.json https://static.crates.io/ https://github.com/ https://api.anthropic.com/ https://example.com/ \
  http://10.0.2.2:22/ http://10.0.2.2:8080/ "http://[fec0::2]:22/" http://127.0.0.1:22/ \
  http://10.0.0.1/ http://172.16.0.1/ http://192.168.0.1/ http://192.168.1.1/ http://100.64.0.1/ http://169.254.169.254/ https://1.1.1.1/; do
  probe "$url" direct --noproxy "*"
  probe "$url" proxy --proxytunnel --proxy "$https_proxy"
done
SH
)
machine_out=$(bash -c "$machine")
network_out=$(bash -c "$network")

cat >Cargo.toml <<'TOML'
[package]
name = "stub"
version = "0.1.0"
edition = "2024"
TOML

mkdir src
cat >src/lib.rs <<'RUST'
pub fn add(a: u64, b: u64) -> u64 {
    a + b
}

#[cfg(test)]
mod tests {
    #[test]
    fn adds() {
        assert_eq!(super::add(2, 2), 4);
    }
}
RUST

jq -nc --arg prompt "$prompt" --arg machine "$machine" --arg machine_out "$machine_out" --arg network "$network" --arg network_out "$network_out" --arg cwd "$PWD" '
  {input_tokens: 12, cache_creation_input_tokens: 30, cache_read_input_tokens: 0, output_tokens: 40, output_tokens_details: {thinking_tokens: 25}} as $first
  | {input_tokens: 5, cache_creation_input_tokens: 20, cache_read_input_tokens: 30, output_tokens: 8} as $second
  | def block($id; $usage; $content): {type: "assistant", message: {id: $id, role: "assistant", usage: $usage, content: [$content]}};
    {type: "system", subtype: "init", cwd: $cwd, model: "stub"},
    block("msg_1"; $first; {type: "text", text: ("Prompt received:\n" + $prompt)}),
    block("msg_1"; $first; {type: "tool_use", id: "toolu_1", name: "Bash", input: {command: $machine}}),
    block("msg_1"; $first; {type: "tool_use", id: "toolu_2", name: "Bash", input: {command: $network}}),
    block("msg_1"; $first; {type: "tool_use", id: "toolu_3", name: "Write", input: {file_path: "Cargo.toml"}}),
    block("msg_1"; $first; {type: "tool_use", id: "toolu_4", name: "Write", input: {file_path: "src/lib.rs"}}),
    {type: "user", message: {role: "user", content: [
      {type: "tool_result", tool_use_id: "toolu_1", content: $machine_out},
      {type: "tool_result", tool_use_id: "toolu_2", content: $network_out},
      {type: "tool_result", tool_use_id: "toolu_3", content: "ok"},
      {type: "tool_result", tool_use_id: "toolu_4", content: "ok"}
    ]}},
    block("msg_2"; $second; {type: "text", text: "Done."}),
    {type: "result", subtype: "success", is_error: false, num_turns: 2, total_cost_usd: 0}
'
