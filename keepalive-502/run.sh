#!/usr/bin/env bash
# ./run.sh bug  -> backends close idle connections after 1s (lb keeps them 600s)
# ./run.sh fix  -> backends keep idle connections for 620s (longer than the lb)
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-}" in
  bug)
    export NODE_KEEPALIVE_TIMEOUT_MS=1000 PYTHON_KEEPALIVE_TIMEOUT_S=1 GO_IDLE_TIMEOUT=1s
    # Node 24 waits an extra 1s (keepAliveTimeoutBuffer) before really closing.
    node_pause=2000 other_pause=1000
    ;;
  fix)
    export NODE_KEEPALIVE_TIMEOUT_MS=620000 PYTHON_KEEPALIVE_TIMEOUT_S=620 GO_IDLE_TIMEOUT=620s
    node_pause=2000 other_pause=1000
    ;;
  *)
    echo "usage: $0 bug|fix" >&2
    exit 1
    ;;
esac

docker compose up -d --build --force-recreate
sleep 3

python3 loadtest.py http://localhost:8080/node/orders "$node_pause" &
python3 loadtest.py http://localhost:8080/python/orders "$other_pause" &
python3 loadtest.py http://localhost:8080/go/orders "$other_pause" &
wait

echo
echo "What nginx (the load balancer) logged:"
docker compose logs lb | grep -o 'upstream prematurely closed connection[^,]*' | sort | uniq -c || echo "  no errors"
