#!/bin/bash
set -euo pipefail

echo "Updating system packages..."
apt-get update && apt-get upgrade -y
apt-get install -y build-essential git curl neovim ripgrep sqlite3 unzip xz-utils zip libglu1-mesa-dev libgtk-3-dev libblkid-dev liblzma-dev libgcrypt20-dev openjdk-17-jdk

echo "Configuring Java..."
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
if ! grep -q "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" /etc/bash.bashrc; then
  echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> /etc/bash.bashrc
  echo 'export PATH="$PATH:$JAVA_HOME/bin"' >> /etc/bash.bashrc
elif ! grep -q "\$JAVA_HOME/bin" /etc/bash.bashrc; then
  echo 'export PATH="$PATH:$JAVA_HOME/bin"' >> /etc/bash.bashrc
fi
export PATH="$PATH:$JAVA_HOME/bin"

echo "Installing Node.js v20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

echo "Installing Flutter SDK..."
mkdir -p /opt/flutter
FLUTTER_JSON=$(curl -s https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json)
FLUTTER_VERSION=$(echo "$FLUTTER_JSON" | python3 -c "import json,sys; data=json.load(sys.stdin); stable=[r for r in data['releases'] if r['channel']=='stable']; print(stable[0]['version']); print(stable[0]['archive'])")
FLUTTER_ARCHIVE=$(echo "$FLUTTER_VERSION" | tail -1)
FLUTTER_VERSION=$(echo "$FLUTTER_VERSION" | head -1)
echo "Installing Flutter $FLUTTER_VERSION..."
curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/$FLUTTER_ARCHIVE" | tar -xJ -C /opt/flutter --strip-components=1 || { echo "Failed to install Flutter SDK"; exit 1; }

# Mark /opt/flutter as safe for git to avoid ownership issues when running as root
git config --global --add safe.directory /opt/flutter

if ! grep -q "/opt/flutter/bin" /etc/bash.bashrc; then
  echo 'export PATH="$PATH:/opt/flutter/bin"' >> /etc/bash.bashrc
fi
if ! grep -q "export CI=true" /etc/bash.bashrc; then
  echo 'export CI=true' >> /etc/bash.bashrc
fi
export PATH="/opt/flutter/bin:$PATH"
export CI=true
flutter config --no-analytics

echo "Installing Android SDK..."
mkdir -p /opt/android-sdk/cmdline-tools
curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o /tmp/cmdline-tools.zip || { echo "Failed to download Android cmdline-tools"; exit 1; }
unzip -o /tmp/cmdline-tools.zip -d /opt/android-sdk/cmdline-tools || { echo "Failed to unzip Android cmdline-tools"; exit 1; }

# The zip contains a 'cmdline-tools' directory. We need to move its content to 'latest'
mkdir -p /opt/android-sdk/cmdline-tools/latest
mv /opt/android-sdk/cmdline-tools/cmdline-tools/* /opt/android-sdk/cmdline-tools/latest/ 2>/dev/null || true
rm -rf /opt/android-sdk/cmdline-tools/cmdline-tools
rm /tmp/cmdline-tools.zip

if ! grep -q "ANDROID_HOME=/opt/android-sdk" /etc/bash.bashrc; then
  echo 'export ANDROID_HOME=/opt/android-sdk' >> /etc/bash.bashrc
fi
if ! grep -q "ANDROID_HOME/cmdline-tools/latest/bin" /etc/bash.bashrc; then
  echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"' >> /etc/bash.bashrc
fi

export ANDROID_HOME=/opt/android-sdk
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Handle SIGPIPE (141) which occurs when 'yes' is killed after sdkmanager finishes reading
yes | sdkmanager --licenses || [[ $? -eq 141 ]] || { echo "Failed to accept Android licenses"; exit 1; }
sdkmanager "platforms;android-35" "build-tools;35.0.0" "platform-tools" || { echo "Failed to install Android components"; exit 1; }

echo "Installing OpenCode CLI..."
curl -fsSL https://opencode.ai/install | bash || { echo "Failed to install OpenCode CLI"; exit 1; }

echo "Installing RTK..."
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh || { echo "Failed to install RTK"; exit 1; }
mv /root/.local/bin/rtk /usr/local/bin/rtk
rtk init -g --opencode

echo "Installing Superpowers plugin for OpenCode..."
mkdir -p /root/.config/opencode
echo '{"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]}' > /root/.config/opencode/opencode.json

echo "Cleanup..."
apt-get clean
rm -rf /var/lib/apt/lists/*
