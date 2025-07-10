#!/bin/sh

docker run -it -p 7860:7860/tcp --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
           -d --device=/dev/kfd --device=/dev/dri --group-add video \
           -v $(pwd)/data:/data:rw -e HF_TOKEN \
           --ipc=host --shm-size 8G --rm trinitronx/rocm-stable-diffusion-webui:latest
