#!/bin/bash

echo "Starting Conceptra..."

ROOT="/d/Conceptra"

# Start backend using venv's Python directly
cd "$ROOT/backend"
"$ROOT/backend/venv/Scripts/uvicorn" app.main:app --reload --port 8000 &
BACKEND_PID=$!
echo "Backend started (PID $BACKEND_PID) → http://localhost:8000/docs"

# Wait for backend to be ready
sleep 4

# Add Flutter to PATH and start frontend
export PATH="$PATH:/c/Users/User/flutter/bin"
cd "$ROOT/frontend"
flutter run -d chrome --web-port=3000 \
  --dart-define=SUPABASE_URL=https://lvgsombxkoedcgznqnge.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2Z3NvbWJ4a29lZGNnem5xbmdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NjYwNTMsImV4cCI6MjA4OTQ0MjA1M30.-0wHmCumY47Qlw9W5b8RnMFAAp3l2qfeIShx2aowxKE \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1

# Kill backend when Flutter exits
kill $BACKEND_PID
