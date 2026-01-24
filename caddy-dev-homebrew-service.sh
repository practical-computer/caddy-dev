#!/bin/bash

CADDYFILE_DIR=${HOME}/.caddy-dev/Caddyfile
sh -c "${CADDY_BINARY} run --config ${CADDYFILE_DIR} --watch"