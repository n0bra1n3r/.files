#!/bin/bash

set -euo pipefail

# Configuration
GITHUB_REPO="cli/cli"
PLATFORM="windows"
ARCH="amd64"
INSTALL_DIR="$HOME/.local/bin"

echo "Downloading latest GitHub CLI release for ${PLATFORM} ${ARCH}..."

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Get the latest release information from GitHub API
echo "Fetching latest release information..."
RELEASE_INFO=$(wget -qO- "https://api.github.com/repos/${GITHUB_REPO}/releases/latest")

# Extract the download URL for the Windows amd64 zip file
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o "\"browser_download_url\": \"[^\"]*$PLATFORM[^\"]*$ARCH[^\"]*\\.zip\"" | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not find release archive"
    exit 1
fi

# Extract version from the URL for naming
VERSION=$(echo "$RELEASE_INFO" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
FILENAME="gh_${VERSION}_${PLATFORM}_${ARCH}.zip"

echo "Found version: $VERSION"
echo "Download URL: $DOWNLOAD_URL"
echo "Installing to: $INSTALL_DIR"

# Download the archive
echo "Downloading $FILENAME..."
wget -O "$INSTALL_DIR/$FILENAME" "$DOWNLOAD_URL"

# Extract the archive
echo "Extracting archive..."
cd "$INSTALL_DIR"
unzip -j "$FILENAME" '**/gh*'

echo "GitHub CLI binary installed to: $INSTALL_DIR"

# Clean up the zip file
rm -f "$FILENAME"

echo "Installation complete!"
