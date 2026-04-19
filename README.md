# SwiftGS: ALGORITHM AND SYSTEM CO-OPTIMIZATION FOR FAST 3D GAUSSIAN SPLATTING ON GPUS

SwiftGS is an optimized system and algorithm co-design for accelerating 3D Gaussian Splatting on GPUs. This work introduces novel techniques including **early sorting** and **axis-shared rasterization** to significantly improve rendering performance while maintaining high-quality output.

## Installation

Clone the repository first:

```bash
git clone https://github.com/LingjunGao/SwiftGS.git
cd SwiftGS/
```

### Method 1: Use the prebuilt Docker image

If you want the fastest start, use the published Docker image on Docker Hub:

```bash
docker pull lingjun0203/swiftgs:v1.0
docker run --gpus all -it --rm \
    -v /path/to/data:/workspace/swiftgs/examples/data \
    -v /path/to/results:/workspace/swiftgs/examples/results \
    lingjun0203/swiftgs:v1.0 bash
```

Inside the container, initialize the dataset and pretrained checkpoints with:

```bash
cd /workspace/swiftgs
bash docker_setup.sh
```

Then run evaluation with:

```bash
bash examples/benchmarks/Evaluation.sh
```

This method uses the prebuilt CUDA 11.8 environment from the Docker image, so no extra environment setup is needed.

### Method 2: Install from source with the setup script

From the SwiftGS root directory, run:

```bash
source ./setup_swiftgs.sh
```

This command will:
- install required system packages,
- create and activate the `swiftgs` conda environment,
- install SwiftGS and Python dependencies,
- download the benchmark dataset,
- download the pretrained `Benchmark_Training` checkpoints.

> If you run `bash ./setup_swiftgs.sh`, setup will still run, but conda activation will not stay active in your current shell.

## Usage

### Training (Optional)

Training is optional. Pre-trained checkpoints for the benchmark scenes are downloaded automatically by `setup_swiftgs.sh` or `docker_setup.sh`.

If you prefer to train your own models, run:

```bash
cd examples
bash benchmarks/Training.sh
```

Results will be saved to `examples/results/New_Training/`.

### Evaluation

To evaluate, run:

```bash
bash benchmarks/Evaluation.sh
```

The script automatically selects the checkpoint root in the following order:
1. `results/New_Training/` — used if you ran `Training.sh` yourself.
2. `results/Benchmark_Training/` — the pre-trained checkpoints downloaded during setup.

If neither folder is found, the script will print instructions on how to train or download the checkpoints.

## Acknowledgements

This work is based on the [gsplat library](https://github.com/nerfstudio-project/gsplat) developed by the Nerfstudio team. We are grateful for their excellent open-source contribution, which provided the foundation for our optimizations.

If you find the ideas or implementation in this project useful, please consider citing our paper below. Since SwiftGS is built on top of the gsplat library, we also encourage citing gsplat where appropriate.

```
@inproceedings{gao2026swiftgs,
    title={SwiftGS: Algorithm and System Co-Optimization for Fast 3D Gaussian Splatting on GPU},
    author={Lingjun Gao and Zhican Wang and Zhiwen Mo and Hongxiang Fan},
    booktitle={Proceedings of the Ninth Annual Conference on Machine Learning and Systems (MLSys 2026)},
    year={2026},
}
```
```
@article{ye2024gsplatopensourcelibrarygaussian,
    title={gsplat: An Open-Source Library for {Gaussian} Splatting}, 
    author={Vickie Ye and Ruilong Li and Justin Kerr and Matias Turkulainen and Brent Yi and Zhuoyang Pan and Otto Seiskari and Jianbo Ye and Jeffrey Hu and Matthew Tancik and Angjoo Kanazawa},
    year={2024},
    eprint={2409.06765},
    journal={arXiv preprint arXiv:2409.06765},
    archivePrefix={arXiv},
    primaryClass={cs.CV},
    url={https://arxXiv.org/abs/2409.06765}, 
}
```
