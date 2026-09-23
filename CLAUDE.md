# CLAUDE.md: debug5xx-lab

Read this first. It explains what this repo is, how the labs are built, and the rules for adding one.

## What and why

- Small, runnable labs that reproduce production errors your logs never show. Each lab backs one post on https://debug5xx.pages.dev (blog source: https://github.com/Pushkar-Agnihotri/debug5xx).
- The labs are the **evidence** for the posts. Every number in a post must come from running a lab here, never from a real company incident.
- Audience: engineers of every level, including freshers. Readability beats cleverness.

## Lab conventions

Every lab is one folder, with the same shape:

```
<lab-name>/
  README.md      what the bug is, the rule that fixes it, how to run it
  compose.yaml   the whole setup; plain Docker Compose, no YAML anchors or tricks
  run.sh         ./run.sh bug  → shows the error
                 ./run.sh fix  → same load, 0 errors
  loadtest.py    standard library only, prints "<url>: N of M requests got 502 (x%)"
  <app dirs>/    tiny apps (each under ~20 lines) + a Dockerfile
```

- **Two modes only.** `bug` and `fix` must differ only in the setting the post is about (usually environment variables in `compose.yaml`).
- **Simple, still standard.**
  - Pin image tags (e.g. `nginx:1.30-alpine`, `node:24-alpine`, `python:3.13-slim`, `golang:1.27-alpine` building into `distroless/static:nonroot`).
  - Run apps as non-root.
  - Scripts use `set -euo pipefail`.
  - Skip the rest of the hardening (healthchecks, read-only filesystems, security options). It hurts readability more than it helps a lab.
- **Compressed time.** Labs scale timeouts down (e.g. 1s instead of 5s or 60s) so a run takes ~3 minutes. The README and the post must say so.
- **Real network latency is simulated.** On a laptop, races between the load balancer and the app are microseconds wide and almost never trigger. A `latency` service (`nicolaka/netshoot` with `tc netem delay 5ms`, sharing the load balancer's network namespace, `NET_ADMIN`) makes them milliseconds wide, like a real cloud network. Keep this pattern for any race-condition lab.
- **Verify before publishing.** Run both modes and paste the real output into the post. Re-run after any change.

## Labs so far

| Lab | Bug | Verified result |
|---|---|---|
| `keepalive-502` | App closes idle keep-alive connections before the load balancer does → random 502s (nginx logs `upstream prematurely closed connection`) | bug: Node 7%, Python 5%, Go 3% (15 × 502); fix (app 620s > LB 600s): 0% |

`keepalive-502` findings worth keeping:

- **Node 24 has `keepAliveTimeoutBuffer` = 1000 ms.** The socket really closes at `keepAliveTimeout + 1s`, so the Node load test pauses 2s, not 1s.
- **Node defaults are unchanged in 26.** Node 26.10 still defaults `keepAliveTimeout` to 5000 (tested in `node:26-alpine`). The 65s default is merged upstream only.
- **Go never closes idle connections by default.** `IdleTimeout` and `ReadTimeout` are both 0, so Go only hits this bug if you set one of them.
- **nginx as the load balancer** needs `proxy_http_version 1.1` and `proxy_set_header Connection ""` to reuse upstream connections, plus `keepalive N; keepalive_timeout 600s;` in the upstream block.

## Hard rules

- **Anonymize everything.** No employer, customer or internal service names, no IPs or internal hostnames, no real incident data. Before pushing, run `scripts/anonymize-check.sh`. It reads a **private** pattern list at `~/personal/.anonymize-patterns` that lives outside this repo on purpose; never commit it or copy its contents here.
- **Personal identity only.** The repo-local git config uses the personal Gmail. Don't touch the machine's global git config (it belongs to another account). Push with plain `git push` (a repo-local credential helper provides the personal token).
- **GitHub CLI.** The personal login lives only in `GH_CONFIG_DIR=~/.config/gh-personal`. The machine's default `gh` must stay on the other account; after any personal `gh` action, check that `gh api user` still returns it.

## Run

```bash
cd keepalive-502
./run.sh bug
./run.sh fix
docker compose down
```

Needs Docker and Python 3.
