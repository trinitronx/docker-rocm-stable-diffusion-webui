# ROCm-enabled Stable Diffusion WebUI in Docker

A Dockerized implementation of [AUTOMATIC1111's Stable Diffusion WebUI][1] with AMD
ROCm 6.4.1 and PyTorch 2.7.1 support.

## Prerequisites

- AMD GPU with ROCm 6.4.1 [supported hardware][2]
  - This project built & tested with AMD Radeon RX 7900 XTX
    - `Navi 31`
    - RDNA3
    - `vendor:device` ID: `1002:744c`
    - LLVM target: `gfx1100`
  - See [compatibility matrix][3] for specific ROCm version & LLVM target
    support
- Docker installed
- [`amdgpu` Kernel drivers for ROCm][4]
  - GPU firmware `linux-firmware-amdgpu`
- GNU Make 4.0+
- 100GiB free disk space for Docker image
- 10GiB+ extra disk space for models

## Quick Start

During build & run steps, the `AUTOMATIC1111/stable-diffusion-webui` project
will need to download some large files & models from HuggingFace on the first
run.  It's recommended to generate a HuggingFace token to avoid rate limits.

Before running either of the commands below, set the `HF_TOKEN` variable to use
your token.

```shell
export HF_TOKEN='hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' # <- your token here
```

### Build the Docker Image

```shell
make build
```

### Run the Container

```shell
make run
```

The WebUI will be available at: [http://localhost:7860](http://localhost:7860)

## Sponsor

If you find this project useful and appreciate my work,
would you be willing to click one of the buttons below to Sponsor this project
and help me continue?

<!-- markdownlint-disable MD033  -->
| Method       | Button                                                                                                                               |
| :----------- | :----------------------------------------------------------------------------------------------------------------------------------: |
| GitHub       | [![💖 Sponsor](https://trinitronx.github.io/assets/img/gh-button-medium.svg)](https://github.com/sponsors/trinitronx)                                                                                 |
| Liberapay    | [![Support with Liberapay](https://liberapay.com/assets/widgets/donate.svg)](https://liberapay.com/trinitronx/donate)                |
| PayPal       | [![Support with PayPal](https://trinitronx.github.io/assets/img/paypal-button-medium-blue.svg)](https://paypal.me/JamesCuzella)              |
| Ko-Fi        | [![Support with Ko-Fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/trinitronx)                                     |
| BuyMeACoffee | [![Buy Me a Coffee](https://trinitronx.github.io/assets/img/bmc-button-medium.svg)](https://www.buymeacoffee.com/TrinitronX) |
| Polar        | [![Support with Polar](https://trinitronx.github.io/assets/img/polar-button-medium-dark.svg)](https://polar.sh/lyraphase)                   |
| Patreon <sup>(_my artist page_)</sup> | [![Support with Patreon](https://img.shields.io/badge/dynamic/json?logo=patreon&style=for-the-badge&color=ffac00&label=Patreon&query=data.attributes.patron_count&suffix=%20patrons&url=https%3A%2F%2Fwww.patreon.com%2Fapi%2Fcampaigns%2F2379189)](https://www.patreon.com/bePatron?u=16585899)                                     |
<!-- markdownlint-enable MD033  -->

Every little bit is appreciated! Thank you! 🙏

## Project Structure

Key directories:

- `data/`: Persistent storage for:
  - Models (`models/Stable-diffusion`)
  - Extensions (`extensions/`)
  - Configuration files (`config.json`, `ui-config.json`)
  - Logs (`log/`)
  - Output image files (`outputs/`)
  - Last used prompt & parameters (`params.txt`)
  - Localization & translation files (`localizations`)
  - Cache files (`cache`)
  - Temporary files (`tmp`)
- `bin/`: Contains build/run scripts
- `patches/`: Custom patches applied during build

## Data Persistence

Your models and configurations persist in:

```shell
./data/
  ├── models/      # Put models here (.ckpt, .safetensors)
  ├── extensions/  # WebUI extensions (drag-and-drop folders)
  └── config.json  # WebUI config (generated on first run)
```

## Customization

### Modify settings in Web UI

1. Run the container once
    - A default config is generated under `data/config.json`
2. Open Web UI in a browser & navigate to Settings
3. Change any desired settings
4. Settings are saved to `data/config.json`

### Modify settings manually

1. Run the container once to generate default config
2. Edit `data/config.json`
3. Restart container with `make run`

**Port customization:** Edit the port for the `make run` command:

```bash
# Change first number to host port
docker run -it -p 8080:7860/tcp --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
# ... SNIP ...
```

## Troubleshooting

### Common issues

- **Port conflict**: Change host port in `make run` script
- **Permission issues**: Add your user to groups and/or fix permissions
  - Ensure your user has access to `/dev/kfd` & `/dev/dri/*` devices (e.g. `video`, `render` groups + `udev` `TAG+="uaccess"` rules)
  - Ensure your user has write access to `data/` directory
  - Ensure your user has access to capability `SYS_PTRACE` & to run `seccomp=unconfined` containers.
- **GPU detection**: Verify ROCm installation with `rocminfo`
- **Missing models**:
  - Place base models in `data/models/Stable-diffusion/`
  - Place LoRA models in `data/models/Lora/`
  - Place VAE models in `data/models/VAE/`
  - Place ESRGAN models in `data/models/ESRGAN/`
  - Place GFPGAN models in `data/models/GFPGAN/`
  - Place CodeFormer models in `data/models/Codeformer/`
  - Place ControlNet models in `data/models/ControlNet/`
  - Place DeepDanbooru tagging classifier in `data/models/deepbooru/`
  - Place fine-tuning hypernetworks in `data/models/hypernetworks/`
  - Place karlo base models in `data/models/karlo/`
- **Installing Extensions**:
  - Place extensions as sub-directories in `data/extensions/`
  - For example: `data/extensions/sd-webui-controlnet`

**View container logs:**

Find the name or ID of the running container with `docker ps`, then run:

```shell
docker logs -f $CONTAINER_ID_OR_NAME
```

## License

AGPLv3 License - See [LICENSE](LICENSE) file

[1]: https://github.com/AUTOMATIC1111/stable-diffusion-webui
     "AUTOMATIC1111/stable-diffusion-webui"
[2]: https://rocm.docs.amd.com/projects/install-on-linux/en/latest/reference/system-requirements.html#supported-gpus
     "AMD ROCm: Supported Hardware"
[3]: https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html#compatibility-matrix
     "AMD ROCm: Compatibility matrix"
[4]: https://rocm.docs.amd.com/projects/install-on-linux/en/latest/how-to/docker.html#running-rocm-docker-containers
     "AMD ROCm: Running ROCm Docker containers"
