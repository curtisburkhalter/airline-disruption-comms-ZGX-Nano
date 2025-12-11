#!/bin/bash

# Installation script for Flight Disruption Communications Demo
# This script sets up the Python environment and installs all dependencies

echo "================================================"
echo "Flight Disruption Communications Demo - Installation"
echo "================================================"
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "✗ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

echo "✓ Python 3 found: $(python3 --version)"
echo ""

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "✗ pip3 is not installed. Please install pip."
    exit 1
fi

echo "✓ pip3 found"
echo ""

# Create a virtual environment (optional but recommended)
echo "Creating Python virtual environment..."
if [ ! -d "airline-env" ]; then
    python3 -m venv airline-env
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi
echo ""

# Activate virtual environment
echo "Activating virtual environment..."
source airline-env/bin/activate
echo "✓ Virtual environment activated"
echo ""

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip
echo ""

# Install required packages
echo "Installing required Python packages..."
echo "This may take several minutes..."
echo ""
pip install -r backend/requirements.txt

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ All packages installed successfully"
else
    echo ""
    echo "✗ Package installation failed"
    exit 1
fi
echo ""

# Install llama-cpp-python with CUDA support
echo "Installing llama-cpp-python with CUDA support..."
echo "This may take several minutes to compile..."
CMAKE_ARGS="-DLLAMA_CUDA=on" pip install llama-cpp-python --force-reinstall --no-cache-dir

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ llama-cpp-python installed with CUDA support"
else
    echo ""
    echo "⚠ llama-cpp-python CUDA installation failed, trying CPU-only version..."
    pip install llama-cpp-python --force-reinstall --no-cache-dir
fi
echo ""

# Create necessary directories
echo "Creating directory structure..."
mkdir -p frontend
mkdir -p backend
mkdir -p models
echo "✓ Directories created"
echo ""

# Check if model exists
echo "Checking for Qwen model..."
MODEL_PATH="/home/curtburk/Desktop/airline-demo/models/Qwen2.5-14B-Instruct-Q4_K_M.gguf"
if [ -f "$MODEL_PATH" ]; then
    echo "✓ Model found at: $MODEL_PATH"
    # Show file size
    MODEL_SIZE=$(du -h "$MODEL_PATH" | cut -f1)
    echo "  Size: $MODEL_SIZE"
else
    echo "⚠ Model not found at: $MODEL_PATH"
    echo ""
    echo "  To download the model, run:"
    echo "  cd /home/curtburk/Desktop/airline-demo/models"
    echo "  wget https://huggingface.co/bartowski/Qwen2.5-14B-Instruct-GGUF/resolve/main/Qwen2.5-14B-Instruct-Q4_K_M.gguf"
    echo ""
    
    # Ask if user wants to download now
    read -p "  Would you like to download the model now? (~9GB) [y/N]: " download_choice
    if [[ "$download_choice" =~ ^[Yy]$ ]]; then
        echo ""
        echo "  Downloading model..."
        cd models
        wget https://huggingface.co/bartowski/Qwen2.5-14B-Instruct-GGUF/resolve/main/Qwen2.5-14B-Instruct-Q4_K_M.gguf
        cd ..
        if [ -f "$MODEL_PATH" ]; then
            echo "✓ Model downloaded successfully"
        else
            echo "✗ Model download failed"
        fi
    fi
fi
echo ""

# Check for frontend files
echo "Checking frontend files..."
if [ -f "frontend/index.html" ]; then
    echo "✓ index.html found"
else
    echo "⚠ index.html not found in frontend/"
fi

if [ -f "frontend/American-Airlines-Logo.png" ]; then
    echo "✓ American-Airlines-Logo.png found"
else
    echo "⚠ American-Airlines-Logo.png not found in frontend/"
    echo "  Add your logo file to frontend/ for branding"
fi
echo ""

# Make start script executable
if [ -f "start_demo_remote.sh" ]; then
    chmod +x start_demo_remote.sh
    echo "✓ start_demo_remote.sh made executable"
fi
echo ""

# Check CUDA availability
echo "Checking CUDA availability..."
if command -v nvidia-smi &> /dev/null; then
    echo "✓ NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | head -1
else
    echo "⚠ nvidia-smi not found - GPU acceleration may not be available"
fi
echo ""

echo "================================================"
echo "Installation Complete!"
echo "================================================"
echo ""
echo "To start the demo:"
echo "  1. Activate the virtual environment: source airline-env/bin/activate"
echo "  2. Run: ./start_demo_remote.sh"
echo "  3. Open browser to the URL shown in the terminal"
echo ""
echo "For manual start:"
echo "  1. source airline-env/bin/activate"
echo "  2. cd backend && python3 main.py"
echo "  3. In another terminal: cd frontend && python3 -m http.server 3000"
echo ""
echo "Model Configuration:"
echo "  - Model: Qwen2.5-14B-Instruct-Q4_K_M"
echo "  - Path: $MODEL_PATH"
echo "  - Size: ~9GB"
echo ""
echo "================================================"