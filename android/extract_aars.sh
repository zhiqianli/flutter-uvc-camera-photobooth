#!/bin/bash

# Script to extract AAR files and integrate them into the plugin
# This avoids the "Direct local .aar file dependencies are not supported" error

set -e

LIBS_DIR="$(dirname "$0")/libs"
TEMP_DIR="$(dirname "$0")/temp_aar_extraction"
SRC_DIR="$(dirname "$0")/src/main"

echo "Extracting AAR files..."

# Create temp directory
mkdir -p "$TEMP_DIR"

# Extract each AAR
for aar_file in libausbc.aar libuvc.aar libnative.aar; do
    if [ -f "$LIBS_DIR/$aar_file" ]; then
        echo "Extracting $aar_file..."
        unzip -q "$LIBS_DIR/$aar_file" -d "$TEMP_DIR/${aar_file%.aar}"
    fi
done

# Merge all extracted contents into the plugin
echo "Merging AAR contents into plugin..."

# Create necessary directories
mkdir -p "$SRC_DIR/java"
mkdir -p "$SRC_DIR/jniLibs"
mkdir -p "$SRC_DIR/res"

# Copy classes.jar from each AAR to a libs directory
mkdir -p "$(dirname "$0")/libs/jars"
for dir in "$TEMP_DIR"/*; do
    if [ -d "$dir" ]; then
        if [ -f "$dir/classes.jar" ]; then
            name=$(basename "$dir")
            echo "Copying $name/classes.jar"
            cp "$dir/classes.jar" "$(dirname "$0")/libs/jars/${name}.jar"
        fi
        if [ -f "$dir/libs/*.jar" ]; then
            cp "$dir/libs"/*.jar "$(dirname "$0")/libs/jars/" 2>/dev/null || true
        fi
    fi
done

# Copy JNI libraries
for dir in "$TEMP_DIR"/*; do
    if [ -d "$dir/jni" ]; then
        echo "Copying JNI libraries from $(basename "$dir")"
        cp -r "$dir/jni/"* "$SRC_DIR/jniLibs/" 2>/dev/null || true
    fi
done

# Copy resources (if any)
for dir in "$TEMP_DIR"/*; do
    if [ -d "$dir/res" ]; then
        echo "Copying resources from $(basename "$dir")"
        # Use rsync to copy resources without overwriting existing files
        rsync -r "$dir/res/" "$SRC_DIR/res/" 2>/dev/null || true
    fi
done

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "AAR extraction complete!"
echo "Please update build.gradle to use the extracted JAR files instead of AAR files."
