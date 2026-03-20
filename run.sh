#!/bin/bash

# Kill any existing backend on port 8000
powershell.exe -Command "
  \$pids = @(Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique)
  foreach (\$pid in \$pids) {
    Stop-Process -Id \$pid -Force -ErrorAction SilentlyContinue
  }
" 2>/dev/null
sleep 1

# Start backend
(cd /d/Conceptra/backend && venv/Scripts/uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload) &
BACKEND_PID=$!

# Wait for backend to be ready
echo "Waiting for backend..."
for i in $(seq 1 15); do
  if curl -s http://localhost:8000/api/v1/health > /dev/null 2>&1; then
    echo "Backend ready."
    break
  fi
  sleep 1
done

# Start frontend
cd /d/Conceptra/frontend && flutter run -d chrome --web-port 3000
