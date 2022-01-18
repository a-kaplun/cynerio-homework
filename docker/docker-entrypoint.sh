#!/bin/sh

set -e

. /venv/bin/activate

exec uvicorn --host 0.0.0.0 --port 5000 --forwarded-allow-ips='*' api:app
