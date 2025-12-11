# Flight Disruption Communications Generator

### This demo was created during my time as an AI product manager at HP

An AI-powered demonstration that generates multi-channel communications for airline flight disruptions. This demo showcases on-premises generative AI capabilities using the HP ZGX Nano AI Station, generating professional passenger notifications across four communication channels without cloud dependencies.

---

## Table of Contents

1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Directory Structure](#directory-structure)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Running the Demo](#running-the-demo)
7. [Using the Demo](#using-the-demo)
8. [Architecture](#architecture)
9. [Troubleshooting](#troubleshooting)

---

## Overview

This demonstration generates contextually appropriate communications for flight disruptions across four channels simultaneously:

| Channel | Output | Character Limit |
|---------|--------|-----------------|
| Passenger Email | Full notification with subject line, explanation, rebooking options, and compensation details | None |
| SMS Notification | Concise text message with essential information | 160 characters |
| Gate Agent Talking Points | PA announcement script, key facts, anticipated Q&A, escalation guidance | None |
| Social Media Response | Twitter/X reply template for customer complaints | 280 characters |

The demo includes four pre-configured scenarios for quick demonstrations: weather delay, mechanical delay, flight cancellation, and medical diversion. Custom scenarios can also be entered manually.

**Key Value Propositions:**
- All AI processing runs locally on the HP ZGX Nano hardware
- No data leaves the device (data sovereignty)
- Consistent, brand-compliant messaging across all channels
- Rapid generation (typically 5-15 seconds per full generation)

---

## System Requirements

**Hardware:**
- HP ZGX Nano AI Station (or equivalent NVIDIA GPU with 16GB+ VRAM)
- Minimum 32GB system RAM
- 15GB available disk space (for model and application)

**Software:**
- Ubuntu 22.04 or 24.04
- Python 3.10 or higher
- NVIDIA drivers with CUDA 12.x support
- Git (for cloning repositories if needed)

**Network:**
- Port 8000 (backend API)
- Port 3000 (frontend web server)
- Network connectivity between demonstration laptop and HP ZGX Nano

---

## Directory Structure

```
airline-demo/
|-- backend/
|   |-- main.py              # FastAPI server with model inference
|   |-- requirements.txt     # Python dependencies
|-- frontend/
|   |-- index.html           # Web interface
|   |-- American-Airlines-Logo.png  # Branding asset
|-- models/
|   |-- Qwen2.5-14B-Instruct-Q4_K_M.gguf  # LLM model file (~9GB)
|-- airline-env/             # Python virtual environment (created during install)
|-- install.sh               # Installation script
|-- start_demo_remote.sh     # Startup script for remote access
|-- download_models.sh       # Model download helper script
|-- README.md                # This file
```

---

## Installation

### Step 1: Create Project Directory

```bash
mkdir -p ~/Desktop/airline-demo
cd ~/Desktop/airline-demo
mkdir -p backend frontend models
```

### Step 2: Copy Demo Files

Place the provided files into the following locations:

| File | Destination |
|------|-------------|
| main.py | backend/main.py |
| requirements.txt | backend/requirements.txt |
| index.html | frontend/index.html |
| American-Airlines-Logo.png | frontend/American-Airlines-Logo.png |
| install.sh | install.sh |
| start_demo_remote.sh | start_demo_remote.sh |
| download_models.sh | download_models.sh |

### Step 3: Run Installation Script

```bash
cd ~/Desktop/airline-demo
chmod +x install.sh
./install.sh
```

The installation script will:
- Verify Python 3 and pip are installed
- Create a virtual environment (airline-env)
- Install all Python dependencies
- Install llama-cpp-python with CUDA support
- Check for the model file
- Verify NVIDIA GPU availability

### Step 4: Download the Model

If prompted during installation, or manually:

```bash
cd ~/Desktop/airline-demo/models
wget https://huggingface.co/bartowski/Qwen2.5-14B-Instruct-GGUF/resolve/main/Qwen2.5-14B-Instruct-Q4_K_M.gguf
```

Alternatively, run the download script:

```bash
chmod +x download_models.sh
./download_models.sh
```

**Note:** The model file is approximately 9GB. Download time depends on network speed.

---

## Configuration

### [CONFIGURE] Model Path

If your installation directory differs from the default, update the MODEL_PATH in these files:

**File: backend/main.py (line 27)**
```python
MODEL_PATH = os.getenv(
    "MODEL_PATH", 
    "/home/curtburk/Desktop/airline-demo/models/Qwen2.5-14B-Instruct-Q4_K_M.gguf"  # <-- UPDATE THIS PATH
)
```

**File: start_demo_remote.sh (line 10)**
```bash
MODEL_PATH="/home/curtburk/Desktop/airline-demo/models/Qwen2.5-14B-Instruct-Q4_K_M.gguf"  # <-- UPDATE THIS PATH
```

**File: install.sh (line 72)**
```bash
MODEL_PATH="/home/curtburk/Desktop/airline-demo/models/Qwen2.5-14B-Instruct-Q4_K_M.gguf"  # <-- UPDATE THIS PATH
```

Replace `/home/curtburk/Desktop/airline-demo` with your actual installation path.

### [CONFIGURE] Network Ports (Optional)

Default ports:
- Backend API: 8000
- Frontend Web Server: 3000

To change ports, edit start_demo_remote.sh:

```bash
BACKEND_PORT=8000   # <-- Change if needed
FRONTEND_PORT=3000  # <-- Change if needed
```

### [CONFIGURE] GPU Layers

The demo is configured to offload all model layers to GPU. If you encounter memory issues, reduce the GPU layer count:

**File: backend/main.py**
```python
N_GPU_LAYERS = int(os.getenv("N_GPU_LAYERS", "99"))  # Reduce this value if GPU memory is insufficient
```

---

## Running the Demo

### Start the Demo

1. Open a terminal on the HP ZGX Nano

2. Navigate to the demo directory:
   ```bash
   cd ~/Desktop/airline-demo
   ```

3. Activate the virtual environment:
   ```bash
   source airline-env/bin/activate
   ```

4. Run the startup script:
   ```bash
   ./start_demo_remote.sh
   ```

5. Wait for the model to load (15-30 seconds). You will see:
   ```
   Backend API is running and model is loaded
   ```

6. Note the URL displayed:
   ```
   Access the demo from your Windows laptop:
   http://[SERVER_IP]:3000
   ```

### Access from Demo Laptop

Open a web browser on your Windows laptop and navigate to:
```
http://[SERVER_IP]:3000
```

Replace [SERVER_IP] with the IP address shown in the terminal output.

### Stop the Demo

Press `Ctrl+C` in the terminal where the demo is running.

---

## Using the Demo

### Quick Scenarios

The interface includes four pre-configured scenarios accessible via buttons at the top of the input panel:

| Button | Scenario | Description |
|--------|----------|-------------|
| Weather Delay | AA 1547 DFW to ORD | Thunderstorm ground stop, 3+ hour delay |
| Mechanical | AA 892 DFW to LAX | Maintenance inspection, 2.5 hour delay |
| Cancellation | AA 2234 CLT to BOS | Crew availability, flight cancelled |
| Diversion | AA 445 PHX to MIA | Medical emergency, diverted to ABQ |

Click any scenario button to populate the form with realistic data.

### Custom Scenarios

Fill in the form fields manually:

| Field | Description | Example |
|-------|-------------|---------|
| Flight Number | Airline and flight number | AA 1234 |
| Origin | Departure airport code | DFW |
| Destination | Arrival airport code | LAX |
| Original Departure | Scheduled departure time | 2:30 PM |
| New Departure | Updated departure time (or TBD) | 5:45 PM |
| Disruption Type | Delay, Cancellation, or Diversion | Delay |
| Reason | Cause of disruption | Weather conditions |
| Rebooking Options | Available alternatives | Stay on flight or rebook to AA 5678 |
| Compensation | Vouchers, accommodations offered | $15 meal voucher |

### Generating Communications

1. Click "Generate Communications"
2. Wait for generation (typically 5-15 seconds)
3. View outputs in the tabbed interface on the right
4. Use "Copy" buttons to copy individual outputs

### Output Tabs

- **Email**: Full passenger notification email with subject line
- **SMS**: Brief text notification (160 character limit shown)
- **Gate Agent**: PA script, key facts, anticipated questions, escalation guidance
- **Social**: Twitter/X response template (280 character limit shown)

---

## Architecture

```
+------------------+         +------------------+         +------------------+
|                  |  HTTP   |                  |  Local  |                  |
|  Web Browser     +-------->+  FastAPI Backend +-------->+  Qwen 14B Model  |
|  (Demo Laptop)   |         |  (Port 8000)     |         |  (llama.cpp)     |
|                  |<--------+                  |<--------+                  |
+------------------+         +------------------+         +------------------+
                                    ^
                                    |
                             +------+------+
                             |             |
                             |  Frontend   |
                             |  (Port 3000)|
                             |             |
                             +-------------+
```

**Components:**

| Component | Technology | Purpose |
|-----------|------------|---------|
| Frontend | HTML/CSS/JavaScript | User interface served via Python HTTP server |
| Backend | FastAPI (Python) | REST API handling requests and model inference |
| Model | Qwen2.5-14B-Instruct (GGUF) | Large language model for text generation |
| Inference | llama-cpp-python | Efficient model loading and GPU inference |

**API Endpoints:**

| Endpoint | Method | Description |
|----------|--------|-------------|
| /api/generate-communications | POST | Generate all four communication channels |
| /api/health | GET | Check server status and model load state |
| / | GET | Root endpoint with service status |

---

## Troubleshooting

### Model fails to load

**Symptom:** "Model file not found" error

**Solution:**
1. Verify the model file exists:
   ```bash
   ls -la ~/Desktop/airline-demo/models/
   ```
2. Confirm the MODEL_PATH in main.py and start_demo_remote.sh matches your actual file location
3. Re-download the model if the file is corrupted or incomplete:
   ```bash
   cd ~/Desktop/airline-demo/models
   rm Qwen2.5-14B-Instruct-Q4_K_M.gguf
   wget https://huggingface.co/bartowski/Qwen2.5-14B-Instruct-GGUF/resolve/main/Qwen2.5-14B-Instruct-Q4_K_M.gguf
   ```

### Backend process dies immediately

**Symptom:** "Backend process died" error during startup

**Solution:**
1. Check for GPU memory issues:
   ```bash
   nvidia-smi
   ```
2. Ensure no other processes are using the GPU
3. Reduce N_GPU_LAYERS if memory is insufficient:
   ```bash
   export N_GPU_LAYERS=50
   ./start_demo_remote.sh
   ```

### Cannot connect from demo laptop

**Symptom:** Browser shows "connection refused" or times out

**Solution:**
1. Verify the HP ZGX Nano IP address:
   ```bash
   hostname -I
   ```
2. Ensure both devices are on the same network
3. Check if firewall is blocking ports:
   ```bash
   sudo ufw status
   sudo ufw allow 8000
   sudo ufw allow 3000
   ```
4. Verify services are running:
   ```bash
   curl http://localhost:8000/api/health
   ```

### CORS errors in browser console

**Symptom:** Browser console shows "Access-Control-Allow-Origin" errors

**Solution:**
1. Ensure the backend is running (not just the frontend)
2. Verify the API_URL in index.html matches the backend address:
   ```javascript
   const API_URL = 'http://[SERVER_IP]:8000/api/generate-communications';
   ```
3. The start_demo_remote.sh script should update this automatically

### Slow generation speed

**Symptom:** Generation takes longer than 15 seconds

**Solution:**
1. Verify GPU is being used:
   ```bash
   nvidia-smi
   ```
   Look for the python process using GPU memory
2. Ensure llama-cpp-python was installed with CUDA support:
   ```bash
   source airline-env/bin/activate
   CMAKE_ARGS="-DLLAMA_CUDA=on" pip install llama-cpp-python --force-reinstall --no-cache-dir
   ```
3. Check system resource usage and close unnecessary applications

### Virtual environment not found

**Symptom:** "source: not found" or "No such file or directory"

**Solution:**
1. Re-run the installation script:
   ```bash
   ./install.sh
   ```
2. Or manually create the environment:
   ```bash
   python3 -m venv airline-env
   source airline-env/bin/activate
   pip install -r backend/requirements.txt
   ```

### Port already in use

**Symptom:** "Address already in use" error

**Solution:**
1. Kill existing processes:
   ```bash
   lsof -ti:8000 | xargs kill -9
   lsof -ti:3000 | xargs kill -9
   ```
2. Re-run the startup script

---

## Model Information

| Property | Value |
|----------|-------|
| Model | Qwen2.5-14B-Instruct |
| Quantization | Q4_K_M (4-bit) |
| File Size | ~9GB |
| Parameters | 14 billion |
| Context Window | 4096 tokens |
| Source | Hugging Face (bartowski) |

---

## Support

For issues with this demonstration, verify:

1. All [CONFIGURE] items have been updated for your environment
2. The model file is fully downloaded and in the correct location
3. The virtual environment is activated before running scripts
4. Network connectivity exists between the demo laptop and HP ZGX Nano

Check backend logs in the terminal for detailed error messages during operation.
