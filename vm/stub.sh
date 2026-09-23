prompt=$(cat)
command='nproc && free -m && df -h / && findmnt -rn -o TARGET,SOURCE,FSTYPE'
machine=$(bash -c "$command")

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

jq -nc --arg prompt "$prompt" --arg command "$command" --arg machine "$machine" --arg cwd "$PWD" '
  {input_tokens: 12, cache_creation_input_tokens: 30, cache_read_input_tokens: 0, output_tokens: 40, output_tokens_details: {thinking_tokens: 25}} as $first
  | {input_tokens: 5, cache_creation_input_tokens: 20, cache_read_input_tokens: 30, output_tokens: 8} as $second
  | def block($id; $usage; $content): {type: "assistant", message: {id: $id, role: "assistant", usage: $usage, content: [$content]}};
    {type: "system", subtype: "init", cwd: $cwd, model: "stub"},
    block("msg_1"; $first; {type: "text", text: ("Prompt received:\n" + $prompt)}),
    block("msg_1"; $first; {type: "tool_use", id: "toolu_1", name: "Bash", input: {command: $command}}),
    block("msg_1"; $first; {type: "tool_use", id: "toolu_2", name: "Write", input: {file_path: "Cargo.toml"}}),
    block("msg_1"; $first; {type: "tool_use", id: "toolu_3", name: "Write", input: {file_path: "src/lib.rs"}}),
    {type: "user", message: {role: "user", content: [
      {type: "tool_result", tool_use_id: "toolu_1", content: $machine},
      {type: "tool_result", tool_use_id: "toolu_2", content: "ok"},
      {type: "tool_result", tool_use_id: "toolu_3", content: "ok"}
    ]}},
    block("msg_2"; $second; {type: "text", text: "Done."}),
    {type: "result", subtype: "success", is_error: false, num_turns: 2, total_cost_usd: 0}
'
