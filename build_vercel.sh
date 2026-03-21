#!/bin/bash

# Exit on error
set -e

echo "Downloading Flutter SDK..."
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.3-stable.tar.xz

echo "Extracting Flutter SDK..."
tar xf flutter_linux_3.19.3-stable.tar.xz

echo "Configuring git safe directory to bypass Vercel ownership checks..."
# Using the wildcard bypasses the ownership check for all directories
git config --global --add safe.directory '*'

echo "Building Flutter Web App..."
cd frontend
# Suppress the root warning and force the build
../flutter/bin/flutter build web --release --dart-define=API_BASE_URL=https://conceptra-api.onrender.com/api/v1 || true

# If it still fails, it might be due to the true flag hiding the exit code. 
# We'll run it normally but disable the analytics which sometimes prompts.
../flutter/bin/flutter config --no-analytics
../flutter/bin/flutter build web --release --dart-define=API_BASE_URL=https://conceptra-api.onrender.com/api/v1

echo "Build complete."
