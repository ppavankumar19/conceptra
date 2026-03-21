#!/bin/bash
set -e

echo "Downloading and installing Flutter 3.19.3..."
git clone https://github.com/flutter/flutter.git -b 3.19.3 /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

echo "Configuring Flutter..."
flutter config --no-analytics
git config --global --add safe.directory '*'

echo "Building frontend..."
cd frontend
flutter build web --release --dart-define=API_BASE_URL=https://conceptra-api.onrender.com/api/v1
