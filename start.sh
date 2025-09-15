#!/usr/bin/env bash
set -euo pipefail


# Railway provides a dynamic PORT. Default to 8787 for local runs.
PORT="${PORT:-8787}"


mkdir -p /etc/rstudio
cat > /etc/rstudio/rserver.conf <<EOF
www-port=${PORT}
www-address=0.0.0.0
# Add other rserver options here as needed
EOF


# If PASSWORD is not set, fail fast to avoid an open instance
if [ -z "${PASSWORD:-}" ]; then
echo "ERROR: PASSWORD env var must be set (used for 'rstudio' user)." >&2
exit 1
fi


# Hand back to the Rocker init system (launches rserver + supporting services)
exec /init
