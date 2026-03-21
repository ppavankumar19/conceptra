#!/bin/bash
set -e

echo "Downloading and installing Flutter 3.19.3..."
git clone https://github.com/flutter/flutter.git -b 3.19.3 /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

echo "Configuring Flutter..."
git config --global --add safe.directory '*'

# Disable all interactive prompts and analytics that crash root automated builds
flutter config --no-analytics
flutter config --no-cli-animations
export CI=true

echo "Running pub get..."
cd frontend
flutter pub get

echo "Building frontend..."
# Run the build but tell Flutter not to invoke pub get again to prevent nested pub bugs
flutter build web --release --no-pub --dart-define=API_BASE_URL=https://conceptra-api.onrender.com/api/v1
