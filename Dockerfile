FROM rocm/pytorch:rocm6.4.1_ubuntu24.04_py3.12_pytorch_release_2.7.1 AS stage1
#FROM rocm/pytorch:latest ## Too old

RUN apt-get update && apt-get -y install rustup libssl-dev openssl unzip zip \
      rsync dos2unix

#COPY . /app

RUN mkdir /app && chown 1000:1000 /app

# base image pre-installs as root to /opt/conda/envs/py_3.12/lib/python3.12/site-packages/
USER 1000
## RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
RUN rustup install stable-x86_64
RUN pip install --upgrade pip
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui /app && \
    git config --global --add safe.directory /app
COPY patches /app/patches
WORKDIR /app
RUN sed -i -e 's/^transformers==4.30.2/transformers/' requirements.txt requirements_versions.txt
RUN grep --files-with-matches --exclude-dir '__pycache__' --null -ri 'pytorch_lightning.utilities.distributed' ./ | \
    xargs -0 sed -i -e 's/pytorch_lightning\.utilities\.distributed/pytorch_lightning.utilities.rank_zero/'
RUN for p in patches/*.patch ; do unix2dos --quiet --to-stdout "$p" | patch -p1 --binary ; done

RUN pip install -r requirements.txt
#RUN pip3 install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 \
#    --index-url https://download.pytorch.org/whl/rocm6.3
# tensorflow_rocm==2.17.0
#RUN pip3 install -U https://repo.radeon.com/rocm/manylinux/rocm-rel-6.3.4/tensorflow_rocm-2.17.0-cp312-cp312-manylinux_2_28_x86_64.whl
#RUN pip3 install -U xformers --index-url https://download.pytorch.org/whl/rocm6.3

FROM stage1 AS stage2
# Override modules/launch_utils.py prepare_environment() command + URLs
ARG TORCH_URLS='https://download.pytorch.org/whl/rocm6.3/torch-2.7.1%2Brocm6.3-cp312-cp312-manylinux_2_28_x86_64.whl#sha256=b0c10342f64a34998ae8d5084aa1beae7e11defa46a4e05fe9aa6f09ffb0db37 \
    https://download.pytorch.org/whl/rocm6.3/torchvision-0.22.1%2Brocm6.3-cp312-cp312-manylinux_2_28_x86_64.whl#sha256=0dce205fb04d9eb2f6feb74faf17cba9180aff70a8c8ac084912ce41b2dc0ab7 \
    https://download.pytorch.org/whl/pytorch_triton_rocm-3.3.1-cp312-cp312-linux_x86_64.whl#sha256=977423eee5c542a3f8aa4f527aec1688c4d485f207089cb595a8e638fcc3888a'

# Fix broken root permissions in base image conda env
RUN sudo chown -R jenkins:jenkins "/opt/conda/envs/py_${ANACONDA_PYTHON_VERSION}/lib/python${ANACONDA_PYTHON_VERSION}/site-packages/"
RUN conda run -n py_$ANACONDA_PYTHON_VERSION pip install lightning
RUN conda run -n py_$ANACONDA_PYTHON_VERSION pip install pydantic==1.10.16
RUN conda run -n py_$ANACONDA_PYTHON_VERSION pip install ${TORCH_URLS}
RUN conda run -n py_$ANACONDA_PYTHON_VERSION pip install open-clip-torch==2.24.0
# For solving dependency hell: InstantID -> insightface -> ... deps ...
# If not using InstantID + ControlNet models... this can be dropped
RUN sudo apt-get -y install pybind11-dev && \
    conda run -n py_$ANACONDA_PYTHON_VERSION pip install --no-input insightface 'protobuf>=3.20.2' 'numpy<2.0' pydantic==1.10.16 albumentations==1.4.3 onnx==1.17.0 coremltools 'open-clip-torch<3.0' mediapipe
RUN conda run -n py_$ANACONDA_PYTHON_VERSION pip install --no-input https://repo.radeon.com/rocm/manylinux/rocm-rel-6.4.1/onnxruntime_rocm-1.21.0-cp312-cp312-manylinux_2_28_x86_64.whl
# For AnimateDiff dependency: diffusers
RUN conda run -n py_$ANACONDA_PYTHON_VERSION pip install --no-input  diffusers
# For Hires fix / ESRGAN upscalers dependency: spandrel
RUN conda run -n py_$ANACONDA_PYTHON_VERSION pip install --no-input  spandrel spandrel-extra-arches

## Broken attempt at using xformers
#RUN sudo -E -H -u jenkins env -u SUDO_UID -u SUDO_GID -u SUDO_COMMAND \
#      -u SUDO_USER env "PATH=$PATH" "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" \
#      conda run --name py_$ANACONDA_PYTHON_VERSION  pip uninstall -y --no-input torch
#RUN pip3 install \
#    'https://repo.radeon.com/rocm/manylinux/rocm-rel-6.4.1/torchaudio-2.7.1%2Brocm6.4.1.git95c61b41-cp312-cp312-linux_x86_64.whl' \
#    'https://repo.radeon.com/rocm/manylinux/rocm-rel-6.4.1/torchvision-0.22.1%2Brocm6.4.1.git59a3e1f9-cp312-cp312-linux_x86_64.whl' \
#    'https://repo.radeon.com/rocm/manylinux/rocm-rel-6.4.1/torchaudio-2.7.1%2Brocm6.4.1.git95c61b41-cp312-cp312-linux_x86_64.whl'
#ARG XFORMERS_WHL=xformers-0.0.31.post1-cp39-abi3-manylinux_2_28_x86_64.whl
#RUN pip3 install "https://download.pytorch.org/whl/cu118/${XFORMERS_WHL}"
# RUN mkdir /tmp/xformers && cd /tmp/xformers && \
#     curl -Ls -O "https://download.pytorch.org/whl/cu118/${XFORMERS_WHL}" && \
#     unzip -d /tmp/xformers/ "${XFORMERS_WHL}" 'xformers-*.dist-info/METADATA' && \
#     sed -i'' -e 's/torch==.*/torch==2.7.1/g' /tmp/xformers/xformers-*.dist-info/METADATA && \
#     zip "${XFORMERS_WHL}" ./xformers-*.dist-info/METADATA && \
#     pip3 install "${XFORMERS_WHL}"
    
#RUN XFORMERS_PACKAGE='xformers==0.0.31.post1' \
#    python -c 'import launch; launch.prepare_environment()' \
#      --skip-torch-cuda-test --skip-python-version-check

# git clone & package sub-repos in Docker image layer to shorten startup-time & lock model dependencies

# Note: Should be 6.4, but does not exist yet...
#ENV TORCH_INDEX_URL='https://download.pytorch.org/whl/rocm6.3'
ENV TORCH_COMMAND='conda run -n py_$ANACONDA_PYTHON_VERSION pip install ${TORCH_URLS}'

ENV REQS_FILE='requirements.txt'
ENV COMMANDLINE_ARGS='--skip-python-version-check --skip-torch-cuda-test --upcast-sampling --opt-sub-quad-attention'
RUN [ -f "/run/secrets/hf_token" ] && export HF_TOKEN="$(cat /run/secrets/hf_token)"; \
    conda run -n py_$ANACONDA_PYTHON_VERSION python -c \
      'import sys; import os; sys.path.append(os.path.join(os.getcwd(), "modules")); \
       from modules import launch_utils; launch_utils.prepare_environment()'
# Fix issue 11458 in sub-repos
# Reference: https://github.com/AUTOMATIC1111/stable-diffusion-webui/issues/11458
RUN grep --files-with-matches --exclude-dir '__pycache__' --null -ri 'pytorch_lightning.utilities.distributed' ./ | \
    xargs -0 sed -i -e 's/pytorch_lightning\.utilities\.distributed/pytorch_lightning.utilities.rank_zero/'

COPY entrypoint.sh /app/

#ENTRYPOINT ["python", "launch.py", "--precision", "full", "--no-half", "--xformers"]
RUN mkdir -p /var/lib/jenkins/.cache/huggingface/hub && \
    chown -R jenkins:jenkins /var/lib/jenkins/.cache/huggingface/hub
VOLUME /var/lib/jenkins/.cache/huggingface/hub
VOLUME /data
ENV PYTORCH_HIP_ALLOC_CONF=expandable_segments:True,garbage_collection_threshold:0.7,max_split_size_mb:512
ENTRYPOINT ["/bin/sh", "/app/entrypoint.sh"]
