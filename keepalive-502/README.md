# Random 502s behind a load balancer: keep-alive timeout lab

Reproduce, on your laptop, the random 502 errors you get when your app
closes idle connections **before** the load balancer in front of it does.

```
client --> load balancer (nginx) --> your app (Node / Python / Go)
            keeps idle                 closes idle
            connections 600s           connections after 1s   <-- the bug
```

## The rule

Your app's keep-alive timeout must be **longer** than the load balancer's.

| Load balancer | Its idle timeout | Set your app to |
|---|---|---|
| AWS ALB | 60s (default, configurable) | more than 60s, e.g. 65s |
| GCP HTTP(S) LB | 600s (fixed) | more than 600s, e.g. 620s |

## Run it

Needs Docker and Python 3.

```bash
./run.sh bug   # apps close idle connections after 1s -> some requests get 502
./run.sh fix   # apps keep idle connections for 620s  -> no 502s
docker compose down
```

Each run takes about 3 minutes.

## What's in here

| File | What it does |
|---|---|
| `compose.yaml` | Starts nginx, three apps, and a helper that adds 5ms network delay |
| `lb.conf` | nginx acting as the load balancer (reuses idle connections for 600s) |
| `node/`, `python/`, `go/` | Tiny apps; their keep-alive timeout comes from an env variable |
| `loadtest.py` | Sends requests with pauses and counts the 502s |
| `run.sh` | Runs the bug or the fix |

## Why the 5ms delay?

On a laptop, the network is so fast that the bug almost never happens. Real
networks between a load balancer and your app take a few milliseconds, and
that small gap is exactly where the bug lives. The `latency` service adds 5ms
using `tc netem`.
