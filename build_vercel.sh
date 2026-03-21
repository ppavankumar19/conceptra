#!/bin/bash

# Exit on error
set -e

echo "Downloading Flutter SDK..."
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.3-stable.tar.xz

echo "Extracting Flutter SDK..."
tar xf flutter_linux_3.19.3-stable.tar.xz

echo "Building Flutter Web App..."
cd frontend
../flutter/bin/flutter build web --release --dart-define=API_BASE_URL=https://conceptra-api.onrender.com/api/v1

echo "Build complete."
