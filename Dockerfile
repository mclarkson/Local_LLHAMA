# 1. Use an official Python 3.12 runtime as a parent image
# 'slim' versions are smaller and more secure than the full images
FROM python:3.11-slim

# podman run --net=host -ti \
#   --userns=keep-id \
#   -v /run/user/1000/pulse:/run/user/1000/pulse:z \
#   -v ~/.config/pulse/cookie:/home/llhama-usr/.config/pulse/cookie:z \
#   -e PULSE_SERVER=unix:/run/user/1000/pulse/native \
#   -e PULSE_COOKIE=/home/llhama-usr/.config/pulse/cookie \
#   -e XDG_RUNTIME_DIR=/run/user/1000 \
#   --name local_llhama -d local_llhama:in_progress bash

# 2. Set environment variables
# PYTHONDONTWRITEBYTECODE: Prevents Python from writing .pyc files to disk
# PYTHONUNBUFFERED: Ensures console output is sent straight to terminal (useful for logs)
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 3. Set the working directory in the container
# WORKDIR /app
WORKDIR /home/llhama-usr/Local_LLHAMA

# 4. Install system dependencies (if needed)
# This is where you'd add things like 'gcc' or 'libpq-dev' for database drivers
RUN apt-get update && apt-get upgrade;
RUN pip install --upgrade pip;
RUN apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    portaudio19-dev \
    libasound2-dev \
    libusb-1.0-0 \
    pulseaudio-utils alsa-utils libasound2-plugins \
    libpulse0 libpulse-dev ffmpeg \
    libglib2.0-0 \
    procps curl vim \
    && rm -rf /var/lib/apt/lists/*;

# 5. Install Python dependencies
# We copy requirements.txt first to leverage Docker's cache layers
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt;
RUN pip install bcrypt;
RUN python3 -c "import openwakeword; openwakeword.utils.download_models()";

# RUN mkdir -p /home/llhama-usr/Local_LLHAMA/piper_voices \
#     && apt install wget \
#     && wget https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/amy/medium/en_US-amy-medium.onnx.json \
#     && wget https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/amy/medium/en_US-amy-medium.onnx;
RUN curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/amy/medium/en_US-amy-medium.onnx;

# Create the bridge file
RUN echo 'pcm.!default {\n    type pulse\n    fallback "sysdefault"\n}\n\nctl.!default {\n    type pulse\n    fallback "sysdefault"\n}' \
    > /etc/asound.conf

# 6. Copy the rest of the application code
COPY . .

RUN cp .env.example .env;
RUN mv en_US-amy-medium.onnx piper_voices/;

# 7. Create a non-root user for security
# Running as root inside a container is a security risk
RUN useradd -m llhama-usr;
RUN chown -R llhama-usr:llhama-usr ~llhama-usr;
USER llhama-usr

# 8. Expose the port the app runs on (e.g., 8000 for FastAPI/Django)
# EXPOSE 8000

# 9. Define the command to run the app
CMD ["python", "-m" "local_llhama.run_system"]
