#!/bin/bash
set -e

export PUB_MAX_CONCURRENCY=1
export FLUTTER_ROOT="/tmp/flutter"
export PUB_CACHE="/tmp/pub_cache"

echo "Downloading and installing Flutter 3.19.3..."
git clone https://github.com/flutter/flutter.git -b 3.19.3 $FLUTTER_ROOT
export PATH="$PATH:$FLUTTER_ROOT/bin"

echo "Configuring Flutter..."
git config --global --add safe.directory '*'

flutter config --no-analytics
flutter config --no-cli-animations
export CI=true

echo "Running pub get..."
cd frontend
flutter pub get

echo "Building frontend..."
# Run the build but tell Flutter not to invoke pub get again to prevent nested pub bugs
flutter build web --release --no-pub --dart-define=API_BASE_URL=https://conceptra-api.onrender.com/api/v1
