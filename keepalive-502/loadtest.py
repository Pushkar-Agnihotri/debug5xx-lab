"""Send requests with a pause between each one, and count the 502s.

The pause is set to about the backend's keep-alive timeout, so the load
balancer keeps reusing a connection just as the backend is closing it.

Usage: python3 loadtest.py <url> <pause_in_ms> [requests]
"""

import random
import sys
import time
import urllib.error
import urllib.request

url = sys.argv[1]
pause_ms = float(sys.argv[2])
total = int(sys.argv[3]) if len(sys.argv) > 3 else 100

errors = 0
for i in range(total):
    # Vary the pause a little (+/- 20ms) so some requests land exactly
    # on the moment the backend closes the connection.
    time.sleep((pause_ms + random.uniform(-20, 20)) / 1000)
    try:
        urllib.request.urlopen(urllib.request.Request(url, data=b"{}"))
    except urllib.error.HTTPError as e:
        if e.code == 502:
            errors += 1

print(f"{url}: {errors} of {total} requests got 502 ({errors / total:.0%})")
