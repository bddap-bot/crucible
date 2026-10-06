# Working on crucible

Edit by subtraction: resolve a problem by deleting code; a tactical patch over a symptom is not accepted. One implementation per thing, never two alive.

Delete code comments; keep only a why the code cannot show.

Read [README.md](README.md) for running experiments and interpreting artifacts.

When adding a harness, update its argv in [bin/run](bin/run), package and API
endpoint in [vm/default.nix](vm/default.nix), the host side of its API in
[vm/api.sh](vm/api.sh), and transcript parser in [bin/metrics](bin/metrics). The guest
never holds the login; `bin/login-test` checks that. Host forwarders run after
[vm/admit.sh](vm/admit.sh) and read the request line and headers only through its
`getline`.

Treat parsed test counts and warnings as untrusted: submitted code can write
`check.log`. The check VM's protected exit-code port is the execution result.
`bin/run` caps every output the guest writes and discards a run that exceeds it
or that `bin/metrics` cannot measure; `bin/metrics` streams each output in bounded
memory and never unpacks the tree. `bin/selftest` checks both against hostile
inputs. `bin/metrics` checks contamination;
it is no substitute for inspecting evidence.

The imported initial run has only `run.json` and `metrics.json`; `bin/metrics`
cannot recompute it.
