# Working on crucible

Edit by subtraction: resolve a problem by deleting code; a tactical patch over a symptom is not accepted. One implementation per thing, never two alive.

Delete code comments; keep only a why the code cannot show.

Read [README.md](README.md) for running experiments and interpreting artifacts.

When adding a harness, update its argv in [bin/run](bin/run), login handling in
[vm/job.sh](vm/job.sh), package in [vm/default.nix](vm/default.nix), and transcript
parser in [bin/metrics](bin/metrics).

Treat parsed test counts and warnings as untrusted: submitted code can write
`check.log`. The check VM's protected exit-code port is the execution result.
`bin/run` scans artifacts for login material before saving; `bin/metrics` checks
contamination. Neither is a substitute for inspecting evidence.

The imported initial run has only `run.json` and `metrics.json`; `bin/metrics`
cannot recompute it.
