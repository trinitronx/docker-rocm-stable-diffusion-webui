#!/bin/sh

REPO_BASE=$( cd "$( dirname "$0" )/../" && pwd )

BUILDX_EXPERIMENTAL=1 docker buildx build \
  --tag trinitronx/rocm-stable-diffusion-webui:latest --progress=tty \
  --secret id=hf_token,env=HF_TOKEN \
  --target=stage2 "$REPO_BASE"
