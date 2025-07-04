#!/bin/bash
go build -ldflags="-s -w" -o cmdy main.go && echo "✓ Built: ./cmdy"