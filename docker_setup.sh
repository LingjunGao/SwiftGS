#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================================
# Docker Setup Script for SwiftGS
# 
# This script downloads datasets and pre-trained checkpoints for SwiftGS.
# It's designed to run inside a Docker container where the environment 
# is already set up.
#
# Usage inside Docker:
#   bash docker_setup.sh
#
# Expected volume mounts:
#   -v /path/to/data:/workspace/swiftgs/examples/data
#   -v /path/to/results:/workspace/swiftgs/examples/results
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES_DIR="${SCRIPT_DIR}/examples"
DATA_DIR="${EXAMPLES_DIR}/data"
RESULTS_DIR="${EXAMPLES_DIR}/results"

# Zenodo record ID for SwiftGS pre-trained checkpoints
ZENODO_RECORD_ID="18943926"
ZENODO_FILES_BASE="https://zenodo.org/records/${ZENODO_RECORD_ID}/files"

# Required scenes for evaluation
REQUIRED_SCENES=(bicycle bonsai counter garden kitchen room truck)

echo "================ Docker data/checkpoint setup ================"

# Create necessary directories
mkdir -p "${DATA_DIR}" "${RESULTS_DIR}"

# Find Python executable
if command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
else
  echo "[ERROR] python/python3 not found in PATH."
  exit 1
fi

# Helper function to check if dataset exists
have_dataset() {
  local dataset_dir="${DATA_DIR}/360_v2"
  [[ -d "${dataset_dir}" ]] || return 1
  for scene in "${REQUIRED_SCENES[@]}"; do
    [[ -d "${dataset_dir}/${scene}" ]] || return 1
  done
  return 0
}

# Helper function to validate tar.gz archive
is_valid_tar_gz() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  tar -tzf "$file" >/dev/null 2>&1
}

# Helper function to download files with retries
download_file() {
  local url="$1"
  local output="$2"
  echo "[INFO] Downloading: ${url}"
  curl -fL --retry 5 --retry-delay 2 --connect-timeout 30 -C - -o "${output}" "${url}"
}

# Download dataset if needed
download_dataset_if_needed() {
  if have_dataset; then
    echo "[INFO] Dataset already exists at ${DATA_DIR}/360_v2. Skip download."
    return 0
  fi

  echo "[INFO] Downloading mip-NeRF360 dataset..."
  (
    cd "${EXAMPLES_DIR}"
    "${PYTHON_BIN}" datasets/download_dataset.py --dataset mipnerf360 --save_dir "${DATA_DIR}"
  )
}

# Download and extract checkpoints
download_and_extract_checkpoint() {
  local archive_name="$1"
  local extract_dir_name="$2"

  local archive_path="${RESULTS_DIR}/${archive_name}"

  # Check if already extracted
  if [[ -d "${RESULTS_DIR}/${extract_dir_name}" ]]; then
    echo "[INFO] ${extract_dir_name} already extracted. Skip."
    return 0
  fi

  # Check if archive already exists and is valid
  if is_valid_tar_gz "${archive_path}"; then
    echo "[INFO] Found existing archive: ${archive_path}"
  else
    # Remove incomplete/corrupted file if it exists
    rm -f "${archive_path}"
    
    # Download archive
    if ! download_file "${ZENODO_FILES_BASE}/${archive_name}?download=1" "${archive_path}"; then
      echo "[ERROR] Failed to download ${archive_name}"
      return 1
    fi
  fi

  # Validate archive before extraction
  if ! is_valid_tar_gz "${archive_path}"; then
    echo "[ERROR] Archive appears corrupted: ${archive_path}"
    rm -f "${archive_path}"
    return 1
  fi

  # Extract archive
  echo "[INFO] Extracting $(basename "${archive_path}") to ${RESULTS_DIR}"
  tar -xzf "${archive_path}" -C "${RESULTS_DIR}"
  
  # Clean up archive after successful extraction
  rm -f "${archive_path}"
}

# Main setup
echo ""
echo "[1/2] Downloading dataset..."
download_dataset_if_needed

echo ""
echo "[2/2] Downloading pre-trained checkpoints..."
download_and_extract_checkpoint "Benchmark_Training.tar.gz" "Benchmark_Training"

echo ""
echo "================ Setup Complete ================"
echo "[INFO] Dataset dir:    ${DATA_DIR}/360_v2"
echo "[INFO] Checkpoint dir: ${RESULTS_DIR}/Benchmark_Training"
echo "[INFO] Ready to run evaluation with: bash examples/benchmarks/Evaluation.sh"
