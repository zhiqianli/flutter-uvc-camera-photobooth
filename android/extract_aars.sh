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
        # Exclude values.xml to avoid duplicates (resources are already in separate files)
        rsync -r --exclude='values.xml' "$dir/res/" "$SRC_DIR/res/" 2>/dev/null || true
    fi
done

# Generate and inject R class into libausbc.jar
# This is required because libausbc code references com.jiangdg.ausbc.R
# but JAR files don't contain R classes (they're generated at build time)
echo "Generating R class for libausbc..."

# Create temporary directory for R class compilation
R_TEMP_DIR="$(dirname "$0")/temp_r_generation"
mkdir -p "$R_TEMP_DIR/com/jiangdg/ausbc"

# Generate R.java with placeholder resource IDs
cat > "$R_TEMP_DIR/R.java" << 'EOF'
package com.jiangdg.ausbc;

public final class R {
    public static final class raw {
        public static int[] getAll() {
            return new int[] {
                base_fragment,
                base_vertex,
                camera_fragment,
                camera_vertex,
                capture_vertex,
                effect_blackw_fragment,
                effect_soul_fragment,
                effect_zoom_vertex,
            };
        }

        public static final int base_fragment = 0x7f010000;
        public static final int base_vertex = 0x7f010001;
        public static final int camera_fragment = 0x7f010002;
        public static final int camera_vertex = 0x7f010003;
        public static final int capture_vertex = 0x7f010004;
        public static final int effect_blackw_fragment = 0x7f010005;
        public static final int effect_soul_fragment = 0x7f010006;
        public static final int effect_zoom_vertex = 0x7f010007;
    }

    public static final class layout {
        public static final int activity_main = 0x7f020000;
        public static final int base_fragment = 0x7f020001;
        public static final int camera_view = 0x7f020002;
        public static final int design_bottom_sheet = 0x7f020003;
        public static final int dialog_camera = 0x7f020004;
        public static final int listitem_device = 0x7f020005;
    }

    public static final class id {
        public static final int cameraView = 0x7f030000;
        public static final int container = 0x7f030001;
        public static final int preview = 0x7f030002;
    }

    public static final class string {
        public static final int app_name = 0x7f040000;
    }

    public static final class color {
        public static final int black = 0x7f050000;
        public static final int white = 0x7f050001;
    }

    public static final class dimen {
        public static final int margin_normal = 0x7f060000;
    }

    public static final class attr {
        public static final int aspectRatio = 0x7f070000;
    }
}
EOF

# Compile R.java
echo "Compiling R class..."
javac -d "$R_TEMP_DIR" "$R_TEMP_DIR/R.java"

# Inject R class into libausbc.jar
LIBAUSBC_JAR="$(cd "$(dirname "$0")" && pwd)/libs/jars/libausbc.jar"
if [ -f "$LIBAUSBC_JAR" ]; then
    echo "Injecting R class into libausbc.jar..."
    # Change to R_TEMP_DIR and add class files with proper paths
    (
        cd "$R_TEMP_DIR" || exit 1
        for class_file in com/jiangdg/ausbc/R*.class; do
            jar uf "$LIBAUSBC_JAR" "$class_file"
        done
    )
    echo "R class successfully injected into libausbc.jar"
else
    echo "Warning: libausbc.jar not found, skipping R class injection"
fi

# Clean up R class temporary files
rm -rf "$R_TEMP_DIR"

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "AAR extraction complete!"
echo "R class has been injected into libausbc.jar to fix NoClassDefFoundError issues."
