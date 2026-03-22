#!/bin/sh
# Overwrite env-config.js at container startup using real env vars.
# This enables runtime configuration without rebuilding the image.
cat > /usr/share/nginx/html/env-config.js <<EOF
window._env_ = {
  API_ROOT: "${API_ROOT:-https://conduit.productionready.io/api}"
};
EOF
exec "$@"
