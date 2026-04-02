# Stage 1: Extract the OpenCode CLI
FROM ghcr.io/anomalyco/opencode:latest AS opencode

# Stage 2: The Final Environment
FROM instrumentisto/flutter:latest

# Run as root to install system dependencies
USER root

# Install required system tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    neovim \
    fish \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

# Copy OpenCode from its image
COPY --from=opencode /usr/local/bin/opencode /usr/local/bin/opencode

# Install rtk AI (Token reducer) via curl + sh
RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | sh

# Install Obra Superpowers via curl + sh
RUN curl -fsSL https://raw.githubusercontent.com/obra/superpowers/main/install.sh | sh

# Set Fish as the default shell for any subsequent commands
SHELL ["/usr/bin/fish", "-c"]

# Set the default working directory
WORKDIR /workspace

# Boot straight into the fish shell when the container starts
CMD ["fish"]
