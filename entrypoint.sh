#!/bin/sh

if [ -n "$HF_TOKEN" ]; then
  huggingface-cli login --token "$HF_TOKEN"
else
  echo 'WARN: HF_TOKEN is not set! Model downloads from huggingface.co may be impacted.' >&2
fi

if [ -e /data -a -d /data ]; then
  if [ ! -e /data/.first-run-done ]; then
    touch /data/.first-run-done
    rsync -a /app/models /data/
    rsync -a /app/extensions /data/
    rsync -a /app/localizations /data/
  fi
  python launch.py --listen --data-dir /data --no-gradio-queue
else
  python launch.py --listen --no-gradio-queue
fi
