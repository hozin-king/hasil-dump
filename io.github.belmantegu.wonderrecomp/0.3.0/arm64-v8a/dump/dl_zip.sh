#!/bin/bash
cd ~/workspace/rea-mariowonder
URL=$(cat zip_direct.txt)
for i in $(seq 1 30); do
  curl -sL -A "Mozilla/5.0" -C - "$URL" -o M.WONDER.zip
  SZ=$(stat -c%s M.WONDER.zip 2>/dev/null || echo 0)
  echo "attempt $i size $SZ"
  if [ "$SZ" = "3769577350" ]; then echo DONE; break; fi
  sleep 3
done
ls -lh M.WONDER.zip; sha256sum M.WONDER.zip
