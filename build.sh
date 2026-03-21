#!/bin/bash
set -e

export PUB_MAX_CONCURRENCY=1
export FLUTTER_ROOT="/tmp/flutter"
export PUB_CACHE="/tmp/pub_cache"
export FLUTTER_VERSION="${FLUTTER_VERSION:-3.38.4}"

echo "Downloading and installing Flutter ${FLUTTER_VERSION}..."
curl -L -o /tmp/flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
tar xf /tmp/flutter.tar.xz -C /tmp
export PATH="$PATH:${FLUTTER_ROOT}/bin"

echo "Configuring Flutter..."
flutter config --no-analytics
flutter config --no-cli-animations
flutter config --enable-web
export CI=true
flutter --version

echo "Running pub get..."
cd frontend
flutter pub get

echo "Building frontend..."
# Run the build but tell Flutter not to invoke pub get again to prevent nested pub bugs
flutter build web --release --no-pub --dart-define=API_BASE_URL=https://conceptra-api.onrender.com/api/v1
