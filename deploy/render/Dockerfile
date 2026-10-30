FROM python:3.12-slim-bookworm
ARG GODOT_VERSION=4.7.2
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip libfontconfig1 libx11-6 libxcursor1 libxinerama1 \
    libxrandr2 libxi6 libgl1 libvulkan1 libasound2 libpulse0 \
    && curl -fL --retry 3 "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o /tmp/godot.zip \
    && unzip /tmp/godot.zip -d /tmp/godot \
    && mv /tmp/godot/Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm -rf /tmp/godot /tmp/godot.zip /var/lib/apt/lists/*
RUN useradd --create-home game
WORKDIR /app
COPY --chown=game:game . /app
USER game
ENV PYTHONUNBUFFERED=1
EXPOSE 10000
CMD ["python", "server.py"]
