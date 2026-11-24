#!/bin/sh
set -eu

DATA_DIR="${DEVPI_DATA_DIR:-/data}"
delim=":"
PORT="${DEVPI_PORT##*"$delim"}"

INIT_ARGS=""
if [ -n "${DEVPI_ROOT_PASSWORD:-}" ]; then
  INIT_ARGS="$INIT_ARGS --root-passwd=${DEVPI_ROOT_PASSWORD}"
fi

# devpi-init is idempotent: it only bootstraps when the server dir is empty.
if [ ! -f "${DATA_DIR}/.serverversion" ]; then
  echo "Initializing devpi server directory at ${DATA_DIR} ..."
  # shellcheck disable=SC2086
  devpi-init --serverdir "${DATA_DIR}" ${DEVPI_INIT_ARGS:-} ${INIT_ARGS}
fi

exec devpi-server --serverdir "${DATA_DIR}" --host 0.0.0.0 --port "${PORT}" "$@"
