#!/usr/bin/env bash

set -eo pipefail

HTTP_CODE=$(curl --silent \
                 --output /dev/null \
                 --write-out "%{http_code}" \
                 --connect-timeout 3 \
                 -H "Host: localhost" \
                 http://127.0.0.1/ || echo "000")

if [[ "$HTTP_CODE" -lt 200 || "$HTTP_CODE" -ge 400 ]]; then
    echo "Healthcheck Failed: Apache returned HTTP $HTTP_CODE" >&2
    exit 1
fi

if ! pgrep -x "cron" > /dev/null && ! pgrep -x "crond" > /dev/null; then
    echo "Healthcheck Failed: Cron service is not running." >&2
    exit 1
fi

exit 0