#!/bin/bash
go build -ldflags="-s -w" -o cmdy && echo "✓ Built: ./cmdy"