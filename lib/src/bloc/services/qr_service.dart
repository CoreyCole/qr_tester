import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

import './permissions_service.dart';


class QrService {
    PermissionsService _permissionsService;

    final BarcodeDetector barcodeDetector = FirebaseVision.instance.barcodeDetector(BarcodeDetectorOptions(barcodeFormats: BarcodeFormat.qrCode));
    BehaviorSubject<CameraController> cameraController = BehaviorSubject<CameraController>();
    BehaviorSubject<String> qrResult = BehaviorSubject<String>();

    bool _alreadyCheckingImage = false;
    bool _foundRoomId = false;

    QrService(PermissionsService permissionsService) {
        _permissionsService = permissionsService;
        cameraController.sink.add(null);
        _permissionsService.cameraPermitted.stream.distinct().listen((permitted) {
            print('[QrService]: cameraPermitted doOnData = $permitted');
            final alreadyInit = cameraController.value != null
                && cameraController.value.value != null
                && cameraController.value.value.isInitialized;
            if (permitted && !alreadyInit) {
                print('[QrService]: init camera controller');
                initCamera();
            }
        });
    }

    Stream<bool> get cameraInitialized => cameraController
        .map((controller) =>
            controller != null 
            && controller.value != null 
            && controller.value.isInitialized
        );

    Future<void> initCamera() async {
        print('[QrService][initCamera]');
        try {
            final cameras = await availableCameras();
            if (cameras == null || cameras.first == null)
                throw 'no available cameras!';
            final newCameraController = CameraController(
                cameras.first,
                ResolutionPreset.medium,
                enableAudio: false,
            );
            return newCameraController.initialize()
                .then((_) => Future.delayed(Duration(milliseconds: 1000)))
                .then((_) {
                    cameraController.sink.add(newCameraController);
                })
                .catchError((err) {
                    print(err);
                });
        } catch (err) {
            print('[QrService][initCamera] ERROR = $err');
            throw err;
        }
    }

    Future<void> disposeCamera() async {
        print('[QrService][disposeCamera]');
        _foundRoomId = false;
        _alreadyCheckingImage = false;
        try {
            await stopScanning();
            if (cameraController.value != null) {
                await cameraController.value.dispose();
                cameraController.sink.add(null);
            }
        } catch (err) {
            print('[QrService][disposeCamera] ERROR = $err');
            throw err;
        }
    }

    /// expects joinCallContext to already been provided
    Future<void> startScanning() async {
        print('[QrService][startScanning]');
        if (cameraController == null
                || cameraController.value == null
                || cameraController.value.value == null
                || cameraController.value.value.hasError == true
                || cameraController.value.value.isInitialized == false) {
            try {
                if (!_permissionsService.cameraPermitted.value) {
                    throw '[QrService][startScanning] no camera access! cannot start scanning!';
                }
                print('''[QrService][startScanning] restarting camera reason:
                    cameraController == null ? $cameraController
                    || cameraController.value == null ? ${cameraController.value}
                    || cameraController.value.value == null ? ${cameraController.value.value}
                    || cameraController.value.value.hasError == true ? ${cameraController.value.value.hasError}
                    || cameraController.value.value.isInitialized == false ? ${cameraController.value.value.isInitialized}
                ''');
                await _restartCamera();
            } catch (err) {
                print('[QrService][startScanning] _restartCamera ERROR = $err');
            }
        }

        _foundRoomId = false;
        if (cameraController.value == null || cameraController.value.value.isStreamingImages == true) {
            print('[QrService][startScanning] cameraController.value = ${cameraController.value}');
            print('[QrService][startScanning] cameraController.value.value.isStreamingImages = ${cameraController.value.value.isStreamingImages}');
            return Future.value();
        }
        
        try {
            // set a reference to the context so we can navigate to the in_call screen
            print('[QrService][startScanning] startImageStream');
            await cameraController.value.startImageStream(_processImage);
        } catch (err) {
            print('[QrService][startScanning] startImageStream ERROR = $err');
            return _restartCamera();
        }
    }

    Future<void> _restartCamera() async {
        try {
            await disposeCamera();
            await initCamera();
        } catch (err) {
            print('[QrService][_restartCamera] ERROR = $err');
        }
    }

    _processImage(CameraImage image) async {
        if (!_alreadyCheckingImage && !_foundRoomId) {
            _alreadyCheckingImage = true;
            try {
                final barcodes = await barcodeDetector.detectInImage(
                    FirebaseVisionImage.fromBytes(
                        _concatenatePlanes(image.planes),
                        FirebaseVisionImageMetadata(
                            rawFormat: image.format.raw,
                            size: Size(image.width.toDouble(), image.height.toDouble()),
                            rotation: ImageRotation.rotation0,
                            planeData: image.planes
                                .map((plane) => FirebaseVisionImagePlaneMetadata(
                                        bytesPerRow: plane.bytesPerRow,
                                        height: plane.height,
                                        width: plane.width,
                                    ),
                                )
                                .toList(),
                        ),
                    ),
                );
                if (barcodes != null && barcodes.length > 0) {
                    try {
                        print('\n~~~');
                        print(barcodes.first.toString());
                        print(barcodes.first.displayValue);
                        print(barcodes.first.valueType);
                        print(barcodes.first.rawValue);
                        print('~~~\n');
                        final barcode = barcodes.first;
                        print(barcode.rawValue);
                        qrResult.sink.add(barcode.rawValue);
                        _foundRoomId = true;
                    } catch (err, stack) {
                        print('$err\n$stack');
                    }
                }
            } catch (err, stack) {
                debugPrint('$err, $stack');
            }
            _alreadyCheckingImage = false;
        }
    }

    Future<void> stopScanning() {
        print('[QrService][stopScanning]');
        if (cameraController.value == null || !cameraController.value.value.isStreamingImages) {
            return Future.value();
        }
        return cameraController.value.stopImageStream();
    }

    Uint8List _concatenatePlanes(List<Plane> planes) {
        final WriteBuffer allBytes = WriteBuffer();
        planes.forEach((plane) => allBytes.putUint8List(plane.bytes));
        return allBytes.done().buffer.asUint8List();
    }

    dispose() {
        stopScanning().then((_) {
            cameraController.value.dispose();
            cameraController.close();
            qrResult.close();
        });
    }
}