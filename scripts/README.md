# Custom Scripts Directory

This directory is where you can add your own custom scripts that cmdy can execute.

## How to use:

1. **Add your script** to this directory
2. **Make it executable**: `chmod +x scripts/your-script.sh`
3. **Reference it in config.yaml**:
   ```yaml
   - display: "My Custom Script - Does something awesome"
     commands:
       linux: "./scripts/your-script.sh"
       mac: "./scripts/your-script.sh"
   ```

## Examples included:

- `backup.sh` - Database backup script
- `deploy.sh` - Application deployment
- `cleanup.sh` - System cleanup tasks
- `health-check.sh` - Detailed system health

## Tips:

- Scripts should be **cross-platform** when possible
- Use **#!/bin/bash** or **#!/bin/sh** for shell scripts
- Add **error handling** and **user feedback**
- Scripts can accept **arguments** from the config
- Use **relative paths** (./scripts/name.sh) in config