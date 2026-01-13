# flutter_uvc_camera

A Flutter plugin based on [AndroidUSBCamera](https://github.com/jiangdongguo/AndroidUSBCamera) to enable Flutter apps to use external UVC cameras.

pub：[flutter_uvc_camera](https://pub.dev/packages/flutter_uvc_camera)

## Features

- Connect to and control external UVC cameras through USB
- Display camera preview in your Flutter app
- Take photos and save to local storage
- Record videos with time tracking
- Stream video frames (H264) and audio frames (AAC) for further processing
- Control camera features like brightness, contrast, focus, etc.
- Monitor camera connection status
- Support for different preview resolutions

## Limitations

- Currently, only supports Android
- For Android 10+, you may need to reduce targetSdkVersion to 27
- Some device models may have compatibility issues (e.g., Redmi Note 10)

## Installation

### 1. Add Dependency

Add the `flutter_uvc_camera` plugin dependency to your Flutter project's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_uvc_camera: ^latest_version
```

### 2. Configure Android Project

#### Add Permissions

Add the following permissions to the AndroidManifest.xml file of your Android project:

```xml
<uses-permission android:name="android.permission.USB_PERMISSION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-feature android:name="android.hardware.usb.host" />
<uses-feature android:name="android.hardware.camera"/>
<uses-feature android:name="android.hardware.camera.autofocus"/>
```

#### Add Repository

In your project's `android/build.gradle`, add the JitPack repository:

```gradle
allprojects {
    repositories {
        // other repositories
        maven { url "https://jitpack.io" }
    }
}
```

#### Configure USB Device Detection

Add an action for USB device connection in the intent-filter of your main Activity, and reference the corresponding XML file in meta-data:

```xml
<intent-filter>
    <action android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED" />
</intent-filter>
<meta-data
    android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED"
    android:resource="@xml/device_filter" />
```

Create the `device_filter.xml` file in the `android/app/src/main/res/xml/` directory:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- USB device vendor-id and product-id values for your camera -->
    <!-- You can use wildcard configuration below or specify your camera IDs -->
    <usb-device vendor-id="1234" product-id="5678" class="255" subclass="66" protocol="1" />
</resources>
```

### 3. Configure ProGuard (for release mode)

If you're building in release mode with minification enabled, add these rules to your `android/app/proguard-rules.pro`:

```pro
-keep class com.jiangdg.uvc.UVCCamera {
    native <methods>;
    long mNativePtr;
}
-keep class com.jiangdg.uvc.IStatusCallback {
    *;
}
-keep interface com.jiangdg.uvc.IButtonCallback {
    *;
}
```

And update your `android/app/build.gradle`:

```gradle
buildTypes {
    release {
        // your existing configs
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        minifyEnabled true
    }
}
```

## Usage

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_uvc_camera/flutter_uvc_camera.dart';

class CameraScreen extends StatefulWidget {
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late UVCCameraController cameraController;
  bool isCameraOpen = false;

  @override
  void initState() {
    super.initState();
    cameraController = UVCCameraController();

    // Set up camera state callback
    cameraController.cameraStateCallback = (state) {
      setState(() {
        isCameraOpen = state == UVCCameraState.opened;
      });
    };
  }

  @override
  void dispose() {
    cameraController.closeCamera();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('UVC Camera')),
      body: Column(
        children: [
          // Camera preview
          Container(
            height: 300,
            child: UVCCameraView(
              cameraController: cameraController,
              width: 300,
              height: 300,
            ),
          ),

          // Camera control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: isCameraOpen ? null : () => cameraController.openUVCCamera(),
                child: Text('Open Camera'),
              ),
              ElevatedButton(
                onPressed: isCameraOpen ? () => cameraController.closeCamera() : null,
                child: Text('Close Camera'),
              ),
              ElevatedButton(
                onPressed: isCameraOpen ? () => takePicture() : null,
                child: Text('Take Picture'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> takePicture() async {
    final path = await cameraController.takePicture();
    if (path != null) {
      print('Picture saved at: $path');
    }
  }
}
```

### Video Recording

```dart
// Start recording a video
Future<void> recordVideo() async {
  final path = await cameraController.captureVideo();
  print('Video saved at: $path');
}
```

### Video Streaming

```dart
// Set up frame callbacks
cameraController.onVideoFrameCallback = (frame) {
  // Process H264 encoded video frame
  // frame.data contains the encoded data
  // frame.timestamp contains the timestamp
  // frame.size contains the size in bytes
  // frame.fps contains the current frame rate
};

cameraController.onAudioFrameCallback = (frame) {
  // Process AAC encoded audio frame
};

// Start streaming
cameraController.captureStreamStart();

// Stop streaming
cameraController.captureStreamStop();
```

### Camera Features Control

```dart
// Set auto focus
await cameraController.setAutoFocus(true);

// Set zoom level
await cameraController.setZoom(5);

// Set brightness
await cameraController.setBrightness(128);

// Get all camera features
final features = await cameraController.getAllCameraFeatures();
```

## API Reference

### UVCCameraController

The main controller class for interacting with the UVC camera.

#### Properties

- `cameraStateCallback`: Callback for camera state changes
- `msgCallback`: Callback for messages from the camera
- `clickTakePictureButtonCallback`: Callback when the camera's physical button is pressed
- `onVideoFrameCallback`: Callback for video frame data
- `onAudioFrameCallback`: Callback for audio frame data
- `onRecordingTimeCallback`: Callback for recording time updates
- `onStreamStateCallback`: Callback for stream state changes

#### Methods

- `initializeCamera()`: Initialize the camera
- `openUVCCamera()`: Open the UVC camera
- `closeCamera()`: Close the UVC camera
- `captureStreamStart()`: Start capturing video stream
- `captureStreamStop()`: Stop capturing video stream
- `takePicture()`: Take a photo and save to storage
- `captureVideo()`: Start/stop video recording
- `setVideoFrameRateLimit(int fps)`: Limit the frame rate
- `setVideoFrameSizeLimit(int maxBytes)`: Limit the frame size
- `getAllPreviewSizes()`: Get available preview sizes
- `updateResolution(PreviewSize size)`: Update camera resolution
- `setCameraFeature(String feature, int value)`: Set camera feature value
- `resetCameraFeature(String feature)`: Reset camera feature to default

### UVCCameraView

Widget to display the camera preview.

#### Properties

- `cameraController`: The UVCCameraController instance
- `width`: The width of the view
- `height`: The height of the view
- `params`: Optional parameters for camera initialization
- `autoDispose`: Whether to automatically dispose the camera when the view is disposed

## Common Issues

### Release Mode Build Failure

If you encounter `NoSuchMethodError` when running in release mode, make sure you've properly configured ProGuard rules as described in the installation section.

### USB Permission Issues

If the camera is not being detected, check that:

1. Your device supports USB OTG
2. You've correctly configured the USB device filter
3. You have proper permissions declarations in AndroidManifest.xml

## Example

For a complete example, check the [example project](https://github.com/chenyeju295/flutter_uvc_camera/tree/main/example).

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## For Developers: Building Native Libraries

This plugin includes pre-compiled JAR files and native libraries for the Android libraries (`libausbc`, `libuvc`, `libnative`). If you need to modify these libraries or rebuild them:

### Prerequisites

- Java 17 or higher (configure in `android/gradle.properties` if needed)
- Android SDK 35
- NDK 27.0.12077973 for native code compilation

### Why JAR instead of AAR?

AAR (Android Archive) files cannot be used as dependencies in a library project that will be built as an AAR itself. This causes the error:
```
Direct local .aar file dependencies are not supported when building an AAR
```

Therefore, we extract the JAR and native library files from the AAR packages and include them directly in the plugin.

## 详细打包流程 (中文版)

### 项目架构说明

本项目包含三个 Android 库模块：
- **libausbc**: Android USB Camera 基础库，提供相机预览、控制等功能
- **libuvc**: USB UVC 设备底层通信库，基于 libusb 实现
- **libnative**: 原生代码库，包含 YUV 转换、MP3 编码等功能

这些模块的源代码分别在：
- `android/libausbc/`
- `android/libuvc/`
- `android/libnative/`

### 打包步骤详解

#### 第一步：临时修改 settings.gradle

由于 `settings.gradle` 默认不包含这三个模块（为了适配 FlutterFlow），我们需要临时添加它们：

```bash
cd android
```

编辑 `settings.gradle` 文件，添加以下内容：

```gradle
rootProject.name = 'flutter_uvc_camera'

include ':libausbc'
include ':libuvc'
include ':libnative'
```

#### 第二步：编译三个模块的 AAR 文件

执行以下命令编译 Release 版本的 AAR：

```bash
./gradlew :libausbc:assembleRelease :libuvc:assembleRelease :libnative:assembleRelease
```

编译成功后，AAR 文件位于：
- `libausbc/build/outputs/aar/libausbc-release.aar`
- `libuvc/build/outputs/aar/libuvc-release.aar`
- `libnative/build/outputs/aar/libnative-release.aar`

#### 第三步：提取 JAR 和原生库文件

使用项目提供的自动化脚本 `extract_aars.sh` 进行提取：

```bash
./extract_aars.sh
```

**脚本执行流程：**

1. 创建临时解压目录
2. 解压三个 AAR 文件
3. 提取 JAR 文件到 `libs/jars/`：
   - `libausbc.jar` (约 424KB) - 包含相机控制、渲染等 Java/Kotlin 代码
   - `libuvc.jar` (约 86KB) - 包含 USB 设备通信 Java 代码
   - `libnative.jar` (约 2.4KB) - 包含原生方法接口

4. 提取原生库文件（.so）到 `src/main/jniLibs/`：
   - **arm64-v8a/**: 64位 ARM 设备（推荐）
     - `libUVCCamera.so` - UVC 相机核心库
     - `libjpeg-turbo1500.so` - JPEG 编解码库
     - `libusb100.so` - USB 通信库
     - `libuvc.so` - libusb 包装库
     - `libnativelib.so` - 原生功能库（YUV/MP3）
   - **armeabi-v7a/**: 32位 ARM 设备
     - 包含相同的 5 个 .so 文件
   - **x86/** 和 **x86_64/**: 模拟器架构
     - 仅包含 `libnativelib.so`

5. 提取 Android 资源文件到 `src/main/res/`：
   - `values/colors.xml` - 颜色定义
   - `values/strings.xml` - 字符串资源
   - `layout/*.xml` - 布局文件
   - `raw/*.xml` - USB 设备过滤等配置

6. 清理临时文件

**手动提取方式（如需自定义）：**

```bash
# 创建临时目录
mkdir -p temp_aar_extraction

# 解压 AAR 文件
unzip -q libausbc/build/outputs/aar/libausbc-release.aar -d temp_aar_extraction/libausbc
unzip -q libuvc/build/outputs/aar/libuvc-release.aar -d temp_aar_extraction/libuvc
unzip -q libnative/build/outputs/aar/libnative-release.aar -d temp_aar_extraction/libnative

# 复制 JAR 文件
mkdir -p libs/jars
cp temp_aar_extraction/libausbc/classes.jar libs/jars/libausbc.jar
cp temp_aar_extraction/libuvc/classes.jar libs/jars/libuvc.jar
cp temp_aar_extraction/libnative/classes.jar libs/jars/libnative.jar

# 复制原生库文件
cp -r temp_aar_extraction/libuvc/jni/* src/main/jniLibs/
cp -r temp_aar_extraction/libnative/jni/* src/main/jniLibs/

# 复制资源文件
for dir in temp_aar_extraction/*; do
    if [ -d "$dir/res" ]; then
        rsync -r "$dir/res/" src/main/res/
    fi
done

# 清理
rm -rf temp_aar_extraction
```

#### 第四步：恢复 settings.gradle

提取完成后，将 `settings.gradle` 恢复到原始状态：

```gradle
rootProject.name = 'flutter_uvc_camera'
```

**重要原因：** FlutterFlow 不支持子模块，必须保持 `settings.gradle` 的简洁形式。

#### 第五步：验证提取结果

检查以下文件是否正确生成：

```bash
# 检查 JAR 文件
ls -lh libs/jars/
# 输出应包含：
# libausbc.jar (~424KB)
# libuvc.jar (~86KB)
# libnative.jar (~2.4KB)

# 检查原生库
ls -lh src/main/jniLibs/arm64-v8a/
# 输出应包含 5 个 .so 文件

# 检查资源文件
ls src/main/res/values/
# 输出应包含 colors.xml 和 strings.xml
```

#### 第六步：测试构建

在 Flutter 项目根目录执行测试构建：

```bash
cd ..

# Android 测试构建
flutter build apk --debug

# 如需发布版本
flutter build apk --release
```

### 版本更新流程

当修改了三个模块的源代码后，需要同步更新版本号：

1. **更新模块版本**（三个 build.gradle 文件）：

   `libausbc/build.gradle`:
   ```gradle
   versionName '3.4.6'  // 递增版本号
   version = '3.4.6'
   ```

   `libuvc/build.gradle`:
   ```gradle
   version = '3.4.6'
   ```

   `libnative/build.gradle`:
   ```gradle
   version = '3.4.6'
   ```

2. **重新编译和提取**：按照上述步骤执行打包

3. **更新 Flutter 插件版本**：

   编辑 `pubspec.yaml`:
   ```yaml
   version: 1.0.1  # 根据语义化版本递增
   ```

4. **提交代码**：

   ```bash
   git add -A
   git commit -m "feat: 升级原生库到 v3.4.6

   - libausbc: 优化相机旋转逻辑
   - libuvc: 修复 USB 检测竞态条件
   - libnative: 支持 Android 15+ 16K 页面大小

   更新内容：
   - 升级 compileSdk 到 35
   - 更新所有 JAR 和 .so 文件
   - 同步资源文件"
   ```

5. **打标签发布**：

   ```bash
   git tag v1.0.1
   git push origin main --tags
   ```

### 常见问题排查

#### 1. 编译错误：找不到模块

```
Cannot locate tasks that match ':libausbc:assembleRelease' as project 'libausbc' not found
```

**解决方案**：检查 `android/settings.gradle` 是否包含了三个模块。

#### 2. 资源文件冲突

```
ERROR: resource color/common_30_black not found
```

**解决方案**：确保 `extract_aars.sh` 脚本正确复制了资源文件到 `src/main/res/`。

#### 3. Java 版本不兼容

```
Java version 1.8 is not supported
```

**解决方案**：在 `android/gradle.properties` 中配置 Java 17 路径：
```properties
org.gradle.java.home=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
```

#### 4. NDK 版本问题

```
NDK version mismatch
```

**解决方案**：在三个模块的 `build.gradle` 中指定 NDK 版本：
```gradle
ndkVersion '27.0.12077973'
```

#### 5. 原生库架构不匹配

如果应用在某些设备上崩溃，检查是否包含了正确的架构：
- **推荐**: `arm64-v8a` 和 `armeabi-v7a`（覆盖大多数真机）
- **可选**: `x86` 和 `x86_64`（仅用于模拟器调试）

在 `libnative/build.gradle` 中配置：
```gradle
ndk {
    abiFilters 'armeabi-v7a', 'arm64-v8a'
}
```

### 技术细节说明

#### 模块依赖关系

```
flutter_uvc_camera (Flutter 插件)
  ├── libausbc (JAR + 资源)
  │     └── 依赖: appcompat, xlog
  ├── libuvc (JAR + .so)
  │     └── 依赖: 无（纯原生 + Java 包装）
  └── libnative (JAR + .so)
        └── 依赖: core-ktx, appcompat
```

#### 16K 页面大小支持（Android 15+）

从 Android 15 开始，部分设备使用 16KB 内存页面大小。需要添加以下配置：

**CMakeLists.txt**:
```cmake
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384")
```

**build.gradle**:
```gradle
cmake {
    arguments "-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON"
}
```

#### 相机旋转优化

`libausbc` 中的 `CameraRender.kt` 实现了智能旋转矩阵计算：
- 支持 0°, 90°, 180°, 270° 旋转
- 自动计算缩放比例以适应屏幕
- 处理横竖屏切换

### 自动化脚本说明

项目提供了 `android/extract_aars.sh` 脚本来自动化提取流程：

**特性**：
- 自动创建和清理临时目录
- 智能合并资源文件（使用 rsync 避免覆盖）
- 支持增量更新
- 详细的日志输出

**使用方法**：
```bash
cd android
chmod +x extract_aars.sh  # 首次使用需添加执行权限
./extract_aars.sh
```

### 性能优化建议

1. **减少包体积**：
   - 移除不需要的 ABI 架构（如 x86）
   - 启用 ProGuard 混淆
   - 压缩资源文件

2. **加快编译速度**：
   - 使用 Gradle 缓存：`org.gradle.caching=true`
   - 并行编译：`org.gradle.parallel=true`
   - 配置 JVM 内存：`org.gradle.jvmargs=-Xmx4096m`

3. **提升运行性能**：
   - 使用 arm64-v8a 架构（性能最佳）
   - 优化原生库编译选项（如 `-O3` 优化）

## Issue Reporting

If you encounter any problems or have any suggestions during usage, please report them on [GitHub Issues](https://github.com/chenyeju295/flutter_uvc_camera/issues).
