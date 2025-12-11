#!/bin/bash

clear
echo "======================================"
echo "✈️  Flight Disruption Communications Demo (Remote Access)"
echo "======================================"
echo ""

# Configuration
MODEL_PATH="/home/curtburk/Desktop/airline-demo/models/Qwen2.5-14B-Instruct-Q4_K_M.gguf"

# Ports
BACKEND_PORT=8000
FRONTEND_PORT=3000

# Get the hostname/IP of the Linux server
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Server Information:"
echo "  Hostname/IP: $SERVER_IP"
echo "  Model: Qwen2.5-14B-Instruct-Q4_K_M"
echo ""

# Check if model exists
if [ ! -f "$MODEL_PATH" ]; then
    echo "❌ Error: Model file not found at $MODEL_PATH"
    echo ""
    echo "Download the model first:"
    echo "  wget https://huggingface.co/bartowski/Qwen2.5-14B-Instruct-GGUF/resolve/main/Qwen2.5-14B-Instruct-Q4_K_M.gguf"
    echo "  mv Qwen2.5-14B-Instruct-Q4_K_M.gguf /home/curtburk/Desktop/airline-demo/models/"
    exit 1
fi

# Kill any existing processes on the ports
echo "Cleaning up old processes..."
lsof -ti:${BACKEND_PORT} | xargs kill -9 2>/dev/null
lsof -ti:${FRONTEND_PORT} | xargs kill -9 2>/dev/null
sleep 2

# Start backend (model loads automatically on startup)
echo "Starting backend API server..."
echo "⏳ Model will load on startup (this takes ~15-30 seconds for 14B)..."
cd backend

# Export environment variables
export TOKENIZERS_PARALLELISM=false
export OMP_NUM_THREADS=4
export MODEL_PATH="$MODEL_PATH"
export N_GPU_LAYERS=99
export N_CTX=4096

python3 main.py &
BACKEND_PID=$!
cd ..

# Wait for backend and model to load
echo "Waiting for model to load..."
MAX_WAIT=90
WAITED=0
while ! curl -s http://localhost:${BACKEND_PORT}/api/health 2>/dev/null | grep -q '"model_loaded":true'; do
    sleep 5
    WAITED=$((WAITED + 5))
    echo "  ...loading ($WAITED seconds)"
    
    # Check if process died
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        echo "❌ Error: Backend process died. Check for errors above."
        exit 1
    fi
    
    if [ $WAITED -ge $MAX_WAIT ]; then
        echo "❌ Error: Model failed to load within $MAX_WAIT seconds"
        kill $BACKEND_PID 2>/dev/null
        exit 1
    fi
done
echo "✔ Backend API is running and model is loaded"

# Start frontend server
echo "Starting frontend web server..."
cd frontend

# Update the API_URL in index.html to use the actual server IP
sed -i "s|const API_URL = .*|const API_URL = 'http://${SERVER_IP}:${BACKEND_PORT}/api/generate-communications';|" index.html

python3 -m http.server ${FRONTEND_PORT} --bind 0.0.0.0 &
FRONTEND_PID=$!
cd ..

# Wait for frontend
sleep 2

echo ""
echo "======================================"
echo "✅ Demo is running!"
echo "======================================"
echo ""
echo "Access the demo from your Windows laptop:"
echo "👉 http://${SERVER_IP}:${FRONTEND_PORT}"
echo ""
echo "Service endpoints:"
echo "  - Frontend:     http://${SERVER_IP}:${FRONTEND_PORT}"
echo "  - Backend API:  http://${SERVER_IP}:${BACKEND_PORT}/api/generate-communications"
echo "  - Health Check: http://${SERVER_IP}:${BACKEND_PORT}/api/health"
echo ""
echo "Instructions:"
echo "1. Open the web interface in your browser"
echo "2. Select a quick scenario or enter custom disruption details"
echo "3. Click 'Generate Communications'"
echo "4. View outputs across all 4 channels (Email, SMS, Gate Agent, Social)"
echo ""
echo "⚠️  Note: 14B model generates at ~25-40 tok/s. Expect 5-10 sec per generation."
echo ""
echo "Press Ctrl+C to stop the demo"
echo "======================================"

# Cleanup function
cleanup() {
    echo ""
    echo "Shutting down services..."
    kill $FRONTEND_PID 2>/dev/null
    kill $BACKEND_PID 2>/dev/null
    
    # Restore original API_URL in index.html
    cd frontend
    sed -i "s|const API_URL = .*|const API_URL = 'http://localhost:${BACKEND_PORT}/api/generate-communications';|" index.html
    cd ..
    
    echo "✔ Demo stopped"
    exit 0
}

# Set trap for cleanup on Ctrl+C
trap cleanup INT

# Keep script running
while true; do
    sleep 1
done