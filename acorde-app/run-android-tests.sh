#!/bin/bash
set -e

echo "Starting Android emulator..."
docker-compose -f ../docker-compose.android.yml up -d

echo "Waiting for emulator to be ready (approx 20s)..."
sleep 20

echo "Connecting adb to the emulator..."
adb connect localhost:5555 || true

echo "Running tests..."
npm run test

echo "Tearing down Android emulator..."
docker-compose -f ../docker-compose.android.yml down
echo "All done!"
