IMAGE_ID := trinitronx/rocm-stable-diffusion-webui

.PHONY: build run
build: Dockerfile
	docker build . -t $(IMAGE_ID)

run: build
	docker run -it -p 7860:7860/tcp \
          -v $$HOME/src/pub/stable-diffusion-models:/app/models \
          --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
          --device=/dev/kfd --device=/dev/dri --group-add video \
          --ipc=host --shm-size 8G $(IMAGE_ID)

