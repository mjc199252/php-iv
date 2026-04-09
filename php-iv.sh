#!/usr/bin/env bash

if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  # shellcheck source=./php-iv.bash
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/php-iv.bash"
fi
