#!/bin/bash

# Build the Go binary
echo "Building cmdy..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Go is not installed. Please install Go first:"
    echo "  Ubuntu/Debian: sudo apt install golang-go"
    echo "  macOS: brew install go"
    echo "  Or visit: https://golang.org/doc/install"
    exit 1
fi

# Build the binary
go build -o cmdy main.go

if [ $? -eq 0 ]; then
    echo "✓ Built successfully: ./cmdy"
    echo ""
    echo "Usage:"
    echo "  ./cmdy"
    echo ""
    echo "To install globally:"
    echo "  sudo mv cmdy /usr/local/bin/"
else
    echo "✗ Build failed"
    exit 1
fi