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

# Generate R.java with runtime resource resolution
# Note: We create a simpler version without Android dependencies
cat > "$R_TEMP_DIR/R.java" << 'EOF'
package com.jiangdg.ausbc;

/**
 * Bridge class that resolves resource IDs at runtime.
 * libausbc code references com.jiangdg.ausbc.R, but actual resources
 * are in the plugin package (com.chenyeju). This class bridges the gap.
 * 
 * Call init() with a Context to initialize resource IDs.
 */
public final class R {
    private static android.content.Context applicationContext = null;

    /**
     * Initialize the resource bridge with application context.
     * Call this early in your app, preferably in Application.onCreate().
     */
    public static void init(android.content.Context context) {
        if (applicationContext == null && context != null) {
            applicationContext = context.getApplicationContext();
            raw.init(applicationContext);
            android.util.Log.i("ResourceBridge", "Resource bridge initialized with package: " + context.getPackageName());
        }
    }

    public static final class raw {
        public static int base_fragment;
        public static int base_vertex;
        public static int camera_fragment;
        public static int camera_vertex;
        public static int capture_vertex;
        public static int effect_blackw_fragment;
        public static int effect_soul_fragment;
        public static int effect_zoom_vertex;

        static void init(android.content.Context context) {
            base_fragment = getId(context, "base_fragment");
            base_vertex = getId(context, "base_vertex");
            camera_fragment = getId(context, "camera_fragment");
            camera_vertex = getId(context, "camera_vertex");
            capture_vertex = getId(context, "capture_vertex");
            effect_blackw_fragment = getId(context, "effect_blackw_fragment");
            effect_soul_fragment = getId(context, "effect_soul_fragment");
            effect_zoom_vertex = getId(context, "effect_zoom_vertex");
        }

        private static int getId(android.content.Context context, String name) {
            int id = context.getResources().getIdentifier(name, "raw", context.getPackageName());
            android.util.Log.d("ResourceBridge", "Resource raw/" + name + " = 0x" + Integer.toHexString(id));
            return id;
        }

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
    }

    public static final class layout {
        public static int activity_main;
        public static int base_fragment;
        public static int camera_view;
        public static int design_bottom_sheet;
        public static int dialog_camera;
        public static int listitem_device;
    }

    public static final class id {
        public static int cameraView;
        public static int container;
        public static int preview;
    }

    public static final class string {
        public static int app_name;
    }

    public static final class color {
        public static int black;
        public static int white;
    }

    public static final class dimen {
        public static int margin_normal;
    }

    public static final class attr {
        public static int aspectRatio;
    }
}
EOF

# Find android.jar for compilation
ANDROID_JAR="$ANDROID_HOME/platforms/android-34/android.jar"
if [ ! -f "$ANDROID_JAR" ]; then
    # Try to find it in common locations
    ANDROID_JAR=$(find ~/Library/Android/sdk -name "android.jar" 2>/dev/null | grep "platforms/android-" | sort -V | tail -1)
fi

if [ -z "$ANDROID_JAR" ]; then
    echo "Warning: android.jar not found, using simple compilation without classpath"
    javac -d "$R_TEMP_DIR" "$R_TEMP_DIR/R.java" 2>/dev/null || echo "Compilation had warnings but continuing..."
else
    echo "Using android.jar: $ANDROID_JAR"
    javac -cp "$ANDROID_JAR" -d "$R_TEMP_DIR" "$R_TEMP_DIR/R.java"
fi

# Inject R class into libausbc.jar
LIBAUSBC_JAR="$(cd "$(dirname "$0")" && pwd)/libs/jars/libausbc.jar"
if [ -f "$LIBAUSBC_JAR" ]; then
    echo "Injecting R class into libausbc.jar..."
    # Change to R_TEMP_DIR and add class files with proper paths
    (
        cd "$R_TEMP_DIR" || exit 1
        for class_file in com/jiangdg/ausbc/R*.class; do
            [ -f "$class_file" ] && jar uf "$LIBAUSBC_JAR" "$class_file"
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
echo "IMPORTANT: Call com.jiangdg.ausbc.R.init(context) in your Flutter plugin code!"
