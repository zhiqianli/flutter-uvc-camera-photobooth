part of flutter_uvc_camera;

/// 自定义参数 可空  Custom parameters can be empty
class UVCCameraViewParamsEntity {
  /**
   *  if give custom minFps or maxFps or unsupported preview size
   *  set preview possible will fail
   *  **/
  /// camera preview min fps  10
  final int? minFps;

  /// camera preview max fps  60
  final int? maxFps;

  /// camera preview frame format 1 (MJPEG) or 0 (YUV)
  /// DEFAULT 1(MJPEG)  If preview fails and the screen goes black, please try switching to 0
  final int? frameFormat;

  ///  DEFAULT_BANDWIDTH = 1
  final double? bandwidthFactor;

  final bool? captureRawImage;
  final bool? rawPreviewData;
  final bool? aspectRatioShow;

  /// camera preview width
  final int? previewWidth;

  /// camera preview height
  final int? previewHeight;

  /// camera rotation angle (0, 90, 180, 270)
  final int? rotation;

  const UVCCameraViewParamsEntity({
    this.minFps = 10,
    this.maxFps = 60,
    this.bandwidthFactor = 1.0,
    this.frameFormat = 1,
    this.captureRawImage,
    this.rawPreviewData,
    this.aspectRatioShow,
    this.previewWidth,
    this.previewHeight,
    this.rotation,
  });

  Map<String, dynamic> toMap() {
    return {
      "minFps": minFps,
      "maxFps": maxFps,
      "frameFormat": frameFormat,
      "bandwidthFactor": bandwidthFactor,
      "captureRawImage": captureRawImage,
      "rawPreviewData": rawPreviewData,
      "aspectRatioShow": aspectRatioShow,
      "previewWidth": previewWidth,
      "previewHeight": previewHeight,
      "rotation": rotation,
    };
  }
}
