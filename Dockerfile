FROM rocm/pytorch:latest

RUN apt-get update && apt-get -y install rustup libssl-dev openssl

#COPY . /app

RUN mkdir /app && chown 1000:1000 /app

USER 1000
## RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
RUN rustup install stable-x86_64
RUN pip install --upgrade pip
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui /app && \
    git config --global --add safe.directory /app
WORKDIR /app
RUN sed -i -e 's/^transformers==4.30.2/transformers/' requirements.txt
RUN pip install -r requirements.txt

ENTRYPOINT REQS_FILE='requirements.txt' \
    COMMANDLINE_ARGS='--skip-torch-cuda-test --skip-python-version-check' \
    python launch.py --precision full --no-half
