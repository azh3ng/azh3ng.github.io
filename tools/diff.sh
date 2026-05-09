#!/usr/bin/env bash
set -euo pipefail

git diff -- _config.yml _data docker tools
