import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

import '../bloc/provider.dart';


class QrCamera extends StatefulWidget {
    final Function onResult;

    QrCamera({
        @required this.onResult
    });
    
    _QrCameraState createState() => _QrCameraState();
}

// based on google's flutter camera example
// https://flutter.dev/docs/cookbook/plugins/picture-using-camera
class _QrCameraState extends State<QrCamera> with WidgetsBindingObserver {
    Bloc bloc;

    Widget build(BuildContext context) {
        bloc = Provider.of(context);
        print('~~~ Building _QrCameraState ~~~');
        // bloc.qr.startScanning();
        Future.delayed(Duration(milliseconds: 500))
            .then((_) => bloc.qr.startScanning());
        return StreamBuilder(
            stream: bloc.qr.cameraController,
            builder: (context, AsyncSnapshot<CameraController> snapshot) {
                if (!snapshot.hasData || !snapshot.data.value.isInitialized) {
                    return SizedBox();
                }
                final cameraController = snapshot.data;
                return Stack(
                    fit: StackFit.passthrough,
                    children: [
                        CameraPreview(cameraController),
                        _overlay(context, bloc),
                    ]
                );
            }
        );
    }

    @override
    void initState() {
        print('[QrCamera] initState');
        super.initState();
        WidgetsBinding.instance.addObserver(this);
    }

    @override
    void dispose() {
        print('[QrCamera] dispose');
        WidgetsBinding.instance.removeObserver(this);
        super.dispose();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
        print('[QrCamera] didChangeAppLifecycleState $state');
        final controller = bloc.qr.cameraController.value;
        if (state == AppLifecycleState.resumed && (controller == null || !controller.value.isInitialized)) {
            print('[QrCamera] controller == null || !controller.value.isInitialized');
            bloc.qr.initCamera();
        } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.suspending) {
            bloc.qr.disposeCamera();
        }
    }

    Widget _overlay(BuildContext context, Bloc bloc) {
        return Container(
            decoration: ShapeDecoration(
                shape: _ScannerOverlayShape(
                    borderColor: Theme.of(context).primaryColor,
                    borderWidth: 5.0,
                ),
            ),
        );
    }
}

// based off of flutter_camera_ml_vision:
// https://github.com/rushio-consulting/flutter_camera_ml_vision/blob/master/example/lib/main.dart
class _ScannerOverlayShape extends ShapeBorder {
    final Color borderColor;
    final Color outlineColor;
    final double borderWidth;
    final double outlineWidth;
    final Color overlayColor;
    final double qViewFinderBorderOffset;
    final double qTopBarMarginTop;
    final double qTopBarMarginBottom;
    final double qBottomBarMarginTop;
    final double qSideBarMarginWidth;

    _ScannerOverlayShape({
        this.borderColor = Colors.white,
        this.outlineColor = Colors.white,
        this.borderWidth = 1.0,
        this.outlineWidth = 2.0,
        this.qViewFinderBorderOffset = 36,
        this.qTopBarMarginTop = 20,
        this.qTopBarMarginBottom = 12,
        this.qBottomBarMarginTop = 84,
        this.qSideBarMarginWidth = 36,
        this.overlayColor = const Color(0x88000000),
    });

    @override
    EdgeInsetsGeometry get dimensions => EdgeInsets.all(10.0);

    @override
    Path getInnerPath(Rect rect, {TextDirection textDirection}) {
        return Path()
            ..fillType = PathFillType.evenOdd
            ..addPath(getOuterPath(rect), Offset.zero);
    }

    @override
    Path getOuterPath(Rect rect, {TextDirection textDirection}) {
        Path _getLeftTopPath(Rect rect) {
            return Path()
                ..moveTo(rect.left, rect.bottom)
                ..lineTo(rect.left, rect.top)
                ..lineTo(rect.right, rect.top);
        }

        return _getLeftTopPath(rect)
            ..lineTo(
                rect.right,
                rect.bottom,
            )
            ..lineTo(
                rect.left,
                rect.bottom,
            )
            ..lineTo(
                rect.left,
                rect.top,
            );
    }

    @override
    void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
        const lineSize = 30;
        final width = rect.width;
        final borderWidthSize = width * 10 / 100;
        final viewFinderCornerOffset = 6;
        final height = rect.height;
        final borderHeightSize = height - (width - borderWidthSize);
        final borderSize = Size(borderWidthSize / 2, borderHeightSize / 2);
        var paint = Paint()
            ..color = overlayColor
            ..style = PaintingStyle.fill;

        canvas
        //draw to bar
            ..drawRect(
                Rect.fromLTRB(
                    rect.left,
                    rect.top - qTopBarMarginTop,
                    rect.right,
                    borderSize.height + rect.top - qTopBarMarginBottom
                ),
                paint,
            )
      
            //Draw bottom bar
            ..drawRect(
                Rect.fromLTRB(
                    rect.left,
                    rect.bottom - borderSize.height - qBottomBarMarginTop,
                    rect.right,
                    rect.bottom
                ),
                paint,
            )
            
            //Left Side Bar
            ..drawRect(
                Rect.fromLTRB(
                    rect.left,
                    rect.top + borderSize.height - qTopBarMarginBottom,
                    rect.left + borderSize.width + qSideBarMarginWidth,
                    rect.bottom - borderSize.height - qBottomBarMarginTop
                ),
                paint,
            )

            //Right side Bar
            ..drawRect(
                Rect.fromLTRB(
                    rect.right - borderSize.width - qSideBarMarginWidth,
                    rect.top + borderSize.height - qTopBarMarginBottom,
                    rect.right,
                    rect.bottom - borderSize.height - qBottomBarMarginTop),
                paint,
            );

        paint = Paint()
            ..color = outlineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = outlineWidth;

        canvas
            ..drawRect(
                Rect.fromLTRB(
                    rect.left + borderSize.width + qSideBarMarginWidth,
                    borderSize.height + rect.top - qTopBarMarginBottom,
                    rect.right - borderSize.width - qSideBarMarginWidth,
                    rect.bottom - borderSize.height - qBottomBarMarginTop),
                paint,
            );

        paint = Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderWidth;

        final borderOffset = borderWidth / 2;
        final viewfinderRect = Rect.fromLTRB(
            borderSize.width + borderOffset,
            borderSize.height + borderOffset + rect.top - 48,
            width - borderSize.width - borderOffset,
            height - borderSize.height - borderOffset + rect.top - 48);
       

        // draw top right corner
        canvas
            ..drawPath(
                Path()
                    ..moveTo(viewfinderRect.right - qViewFinderBorderOffset + viewFinderCornerOffset, viewfinderRect.top + qViewFinderBorderOffset - viewFinderCornerOffset)
                    ..lineTo(viewfinderRect.right - qViewFinderBorderOffset + viewFinderCornerOffset, viewfinderRect.top + lineSize + qViewFinderBorderOffset - viewFinderCornerOffset),
                paint)
            ..drawPath(
                Path()
                    ..moveTo(viewfinderRect.right - qViewFinderBorderOffset + viewFinderCornerOffset, viewfinderRect.top + qViewFinderBorderOffset - viewFinderCornerOffset)
                    ..lineTo(viewfinderRect.right - lineSize - qViewFinderBorderOffset + viewFinderCornerOffset, viewfinderRect.top + qViewFinderBorderOffset - viewFinderCornerOffset),
                paint)
            ..drawPoints(
                PointMode.points,
                [Offset(viewfinderRect.right - qViewFinderBorderOffset + viewFinderCornerOffset, viewfinderRect.top + qViewFinderBorderOffset - viewFinderCornerOffset)],
                paint,
            )

            // draw top left corner
            ..drawPath(
                Path()
                    ..moveTo(viewfinderRect.left + qViewFinderBorderOffset - viewFinderCornerOffset, viewfinderRect.top + qViewFinderBorderOffset - viewFinderCornerOffset)
                    ..lineTo(viewfinderRect.left + qViewFinderBorderOffset - viewFinderCornerOffset, viewfinderRect.top + lineSize + qViewFinderBorderOffset - viewFinderCornerOffset),
                paint)
            ..drawPath(
                Path()
                    ..moveTo(viewfinderRect.left + qViewFinderBorderOffset - viewFinderCornerOffset, viewfinderRect.top + qViewFinderBorderOffset - viewFinderCornerOffset)
                    ..lineTo(viewfinderRect.left + lineSize + qViewFinderBorderOffset - viewFinderCornerOffset, viewfinderRect.top + qViewFinderBorderOffset - viewFinderCornerOffset),
                paint)
            ..drawPoints(
                PointMode.points,
                [Offset(viewfinderRect.left + qViewFinderBorderOffset - viewFinderCornerOffset, viewfinderRect.top + qViewFinderBorderOffset - viewFinderCornerOffset)],
                paint,
            )

            // draw bottom right corner
            ..drawPath(
                Path()
                    ..moveTo(viewfinderRect.right - qViewFinderBorderOffset + viewFinderCornerOffset, viewfinderRect.bottom - qViewFinderBorderOffset + viewFinderCornerOffset)
                    ..lineTo(viewfinderRect.right - qViewFinderBorderOffset + viewFinderCornerOffset, viewfinderRect.bottom - lineSize - qViewFinderBorderOffset + viewFinderCornerOffset),
                paint)
            ..drawPath(
                Path()
                    ..moveTo(viewfinderRect.right - qViewFinderBorderOffset + viewFinderCornerOffset, viewfinderRect.bottom - qViewFinderBorderOffset + viewFinderCornerOffset)
                    ..lineTo(viewfinderRect.right - lineSize - qViewFinderBorderOffset + viewFinderCornerOffset, viewfinderRect.bottom - qViewFinderBorderOffset + viewFinderCornerOffset),
                paint)
            ..drawPoints(
                PointMode.points,
                [Offset(viewfinderRect.right - qViewFinderBorderOffset + viewFinderCornerOffset, viewfinderRect.bottom - qViewFinderBorderOffset + viewFinderCornerOffset)],
                paint,
            )

            // draw bottom left corner
            ..drawPath(
                Path()
                    ..moveTo(viewfinderRect.left + qViewFinderBorderOffset - viewFinderCornerOffset, viewfinderRect.bottom - qViewFinderBorderOffset + viewFinderCornerOffset)
                    ..lineTo(viewfinderRect.left + qViewFinderBorderOffset - viewFinderCornerOffset, viewfinderRect.bottom - lineSize - qViewFinderBorderOffset + viewFinderCornerOffset),
                paint)
            ..drawPath(
                Path()
                    ..moveTo(viewfinderRect.left + qViewFinderBorderOffset - viewFinderCornerOffset, viewfinderRect.bottom - qViewFinderBorderOffset + viewFinderCornerOffset)
                    ..lineTo(viewfinderRect.left + lineSize + qViewFinderBorderOffset - viewFinderCornerOffset, viewfinderRect.bottom - qViewFinderBorderOffset + viewFinderCornerOffset),
                paint)
            ..drawPoints(
                PointMode.points,
                [Offset(viewfinderRect.left + qViewFinderBorderOffset - viewFinderCornerOffset, viewfinderRect.bottom - qViewFinderBorderOffset + viewFinderCornerOffset)],
                paint,
            );
    }

    @override
    ShapeBorder scale(double t) {
        return _ScannerOverlayShape(
            borderColor: borderColor,
            borderWidth: borderWidth,
            overlayColor: overlayColor,
        );
    }
}