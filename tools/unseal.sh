#!/bin/bash
# ビルド直前に、暗号化してある教材データ（apps/<Target>/content.enc）を元の場所に展開する。
# usage: CONTENT_KEY=<64桁の16進> tools/unseal.sh apps/<Target>
#
# content.enc の形式：先頭16バイト = IV、残り = AES-256-CBC で暗号化した tar.gz
set -euo pipefail

dir="${1:?usage: tools/unseal.sh apps/<Target>}"
enc="$dir/content.enc"
[ -f "$enc" ] || { echo "::error::$enc がありません"; exit 1; }
[ -n "${CONTENT_KEY:-}" ] || { echo "::error::CONTENT_KEY が設定されていません"; exit 1; }

iv=$(head -c 16 "$enc" | od -An -tx1 | tr -d ' \n')
tail -c +17 "$enc" | openssl enc -d -aes-256-cbc -K "$CONTENT_KEY" -iv "$iv" | tar -xzf - -C "$dir"
echo "unsealed: $dir"
