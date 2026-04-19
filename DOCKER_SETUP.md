# Docker Setup Guide for SwiftGS

This guide explains how to build and push the SwiftGS Docker image to Docker Hub so others can use it.

## Prerequisites

1. **Docker installed**: [Install Docker Desktop](https://www.docker.com/products/docker-desktop)
2. **Docker Hub account**: Create one at [hub.docker.com](https://hub.docker.com)
3. **GPU support** (recommended): For running with GPU acceleration, ensure you have NVIDIA GPU drivers installed and [`nvidia-docker`](https://github.com/NVIDIA/nvidia-docker)

## Step 1: Login to Docker Hub

```bash
docker login
```

You'll be prompted for your Docker Hub username and password.

## Step 2: Build the Docker Image

From the SwiftGS root directory:

```bash
# Replace 'YOUR_USERNAME' with your Docker Hub username
docker build -t YOUR_USERNAME/swiftgs:latest .

# Optional: Tag with version
docker build -t YOUR_USERNAME/swiftgs:v1.0 .
```

## Step 3: Push to Docker Hub

```bash
# Push the latest tag
docker push YOUR_USERNAME/swiftgs:latest

# Push version tag (optional)
docker push YOUR_USERNAME/swiftgs:v1.0
```

The image is now publicly available at `docker.io/YOUR_USERNAME/swiftgs`

## Important: Git Repo vs Docker Image

Pushing your code to GitHub or another git repo does **not** make the Docker image available by itself.

- If users only have the git repo, they must clone the repo and run `docker build` themselves.
- If you push the built image to Docker Hub, users can pull and run it directly with `docker pull` or by setting the image name in a cloud service such as Vast.ai.

For easiest reuse by others, publish the image to Docker Hub with a stable tag such as:

```bash
docker tag swiftgs:cu118 YOUR_USERNAME/swiftgs:cu118
docker push YOUR_USERNAME/swiftgs:cu118
```

Then others can use `YOUR_USERNAME/swiftgs:cu118` directly without rebuilding.

## Using SwiftGS on Vast.ai

There are two good ways to use SwiftGS on Vast.ai.

### Option A: Use the prebuilt Docker Hub image (recommended)

If you already pushed the image to Docker Hub, the Vast.ai user should:

1. Create a new instance with a GPU.
2. In the Docker image field, enter `YOUR_USERNAME/swiftgs:cu118`.
3. Start the instance.
4. Open a terminal in the instance.
5. Run the data setup script:

```bash
cd /workspace/swiftgs
bash docker_setup.sh
```

6. Run evaluation:

```bash
cd /workspace/swiftgs
bash examples/benchmarks/Evaluation.sh
```

If they want their data and outputs to persist, they should mount or attach persistent storage and keep `examples/data` and `examples/results` on that volume.

### Option B: Build from the git repo on Vast.ai

If you only shared the git repo and not a published image, the Vast.ai user should:

```bash
git clone YOUR_REPO_URL
cd SwiftGS
docker build -t swiftgs:cu118 .
docker run --gpus all -it --rm swiftgs:cu118 bash
```

Then inside the container:

```bash
cd /workspace/swiftgs
bash docker_setup.sh
bash examples/benchmarks/Evaluation.sh
```

This works, but it is slower and more expensive on Vast.ai because every user rebuilds the image.

## Usage for Other Users

Once pushed to Docker Hub, others can use the image as follows:

### Interactive Session with GPU

```bash
docker run --gpus all -it --rm \
    -v /path/to/local/data:/workspace/swiftgs/examples/data \
    -v /path/to/local/results:/workspace/swiftgs/examples/results \
    YOUR_USERNAME/swiftgs:latest bash
```

### Download Datasets and Checkpoints

Inside the running container or when launching:

```bash
docker run --gpus all --rm \
    -v /path/to/local/data:/workspace/swiftgs/examples/data \
    -v /path/to/local/results:/workspace/swiftgs/examples/results \
    YOUR_USERNAME/swiftgs:latest \
    bash docker_setup.sh
```

  For a published CUDA-tagged image, the same command would usually be:

  ```bash
  docker run --gpus all --rm \
    -v /path/to/local/data:/workspace/swiftgs/examples/data \
    -v /path/to/local/results:/workspace/swiftgs/examples/results \
    YOUR_USERNAME/swiftgs:cu118 \
    bash docker_setup.sh
  ```

### Run Evaluation

```bash
docker run --gpus all --rm \
    -v /path/to/local/data:/workspace/swiftgs/examples/data \
    -v /path/to/local/results:/workspace/swiftgs/examples/results \
    YOUR_USERNAME/swiftgs:latest \
    bash examples/benchmarks/Evaluation.sh
```

### Run Training

```bash
docker run --gpus all --rm \
    -v /path/to/local/data:/workspace/swiftgs/examples/data \
    -v /path/to/local/results:/workspace/swiftgs/examples/results \
    YOUR_USERNAME/swiftgs:latest \
    bash examples/benchmarks/Training.sh
```

## What docker_setup.sh Does

The `docker_setup.sh` script is designed to run inside the Docker container and handles:

1. **Dataset Download**: Downloads the mip-NeRF360 benchmark dataset from public sources
2. **Checkpoint Download**: Downloads pre-trained model checkpoints from Zenodo (Benchmark_Training.tar.gz)
3. **Validation**: Verifies archive integrity before extraction
4. **Organization**: Extracts everything to the correct directories (`examples/data/` and `examples/results/`)

### Key Differences from setup_swiftgs.sh

- **No environment setup**: All Python/CUDA/dependencies are pre-installed in the Docker image
- **Focused on data**: Only handles dataset and checkpoint downloads
- **Docker-aware**: Uses mounted volumes instead of system-level installations
- **Idempotent**: Skips re-downloading if files already exist

## Building Optimizations

To reduce image size or build time:

```bash
# Build without cache (force rebuild everything)
docker build --no-cache -t YOUR_USERNAME/swiftgs:latest .

# Build with build arguments (if Dockerfile supports them)
docker build --build-arg CUDA_VERSION=11.8 -t YOUR_USERNAME/swiftgs:latest .
```

## Image Information

- **Base Image**: `nvidia/cuda:11.8.0-devel-ubuntu22.04`
- **Python Version**: 3.10
- **PyTorch Version**: 2.1.2+cu118
- **Pre-installed packages**:
  - Core: numpy, setuptools, ninja, packaging
  - NeRF tools: viser, nerfview, imageio, torchmetrics
  - Utilities: opencv, tyro, tensorboard, matplotlib, pyyaml, tensorly
  - Specialized: pycolmap, fused-ssim

## Troubleshooting

### Build Fails with GPU Error
Ensure CUDA 11.8 headers are available:
```bash
docker build -t YOUR_USERNAME/swiftgs:latest .
```

### Container Can't Find GPU
Ensure nvidia-docker is installed:
```bash
# Install nvidia-docker on Ubuntu
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

### Download Fails Inside Container
- Check internet connectivity
- Verify Zenodo URL is still valid
- Try with increased retry timeout in docker_setup.sh

## Next Steps

1. Update your README with Docker usage instructions
2. Consider tagging releases with semantic versioning (v1.0, v1.1, etc.)
3. Monitor image size and optimize if needed
4. Collect user feedback on the Docker experience
