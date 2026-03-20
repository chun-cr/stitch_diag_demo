import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class CameraPreviewWidget extends StatelessWidget {
  final bool mirror;

  const CameraPreviewWidget({
    super.key,
    this.mirror = false,
  });

  @override
  Widget build(BuildContext context) {
    const String viewType = 'com.yourapp.face_scan/camera_preview';
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    Widget? view;

    if (defaultTargetPlatform == TargetPlatform.android) {
      view = PlatformViewLink(
        viewType: viewType,
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () {
              params.onFocusChanged(true);
            },
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      view = UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    view ??= Center(
      child: Text(
        '$defaultTargetPlatform is not supported yet for camera preview.',
        style: const TextStyle(color: Colors.white),
      ),
    );

    return mirror
        ? Transform.scale(
            scaleX: -1.0,
            alignment: Alignment.center,
            child: view,
          )
        : view;
  }
}
