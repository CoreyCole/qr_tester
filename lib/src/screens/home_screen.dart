import 'package:flutter/material.dart';

import '../bloc/provider.dart';
import '../widgets/qr_camera.dart';

class HomeScreen extends StatelessWidget {
    build(BuildContext context) {
        final bloc = Provider.of(context);
        print('~~~ Building HomeScreen ~~~');
        return StreamBuilder(
            stream: bloc.permissions.allRequested,
            builder: (context, snapshot) {
                final allRequested = snapshot.hasData && snapshot.data;
                if (!allRequested) {
                    print('~~~ Building Request Permissions ~~~');
                    return Scaffold(
                        appBar: AppBar(
                            backgroundColor: Colors.white,
                        ),
                        body: Column(
                            children: [
                                Expanded(flex: 0, child: SizedBox(height: 16)),
                                Expanded(flex: 2, child: Text('Request Permissions')),
                                Expanded(flex: 2, child: SizedBox()),
                                Expanded(flex: 5, child: SizedBox()),
                                Expanded(flex: 1, child: _okayButton(context, bloc)),
                                Expanded(flex: 0, child: SizedBox(height: 32)),
                            ],
                        )
                    );
                } else {
                    print('~~~ Building Qr Camera Scaffold ~~~');
                    return StreamBuilder(
                        stream: bloc.qr.qrResult,
                        builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                                return Scaffold(
                                    body: Stack(
                                        children: [
                                            _qrCamera(bloc),
                                        ]
                                    )
                                );
                            } else {
                                return Scaffold(
                                    body: Column(
                                        children: [
                                            Expanded(flex: 0, child: SizedBox(height: 16)),
                                            Expanded(flex: 2, child: Text(snapshot.data)),
                                            Expanded(flex: 2, child: SizedBox()),
                                            Expanded(flex: 5, child: SizedBox()),
                                            Expanded(flex: 1, child: _okayButton(context, bloc)),
                                            Expanded(flex: 0, child: SizedBox(height: 32)),
                                        ],
                                    )
                                );
                            }
                        }
                    );
                }
            }
        );
    }

    Widget _okayButton(BuildContext context, Bloc bloc) {
        return Row(
            children: [
                Expanded(flex: 1, child: SizedBox()),
                Expanded(flex: 8, child: RaisedButton(child: Text('Okay'), onPressed: () async {
                    final cameraPermitted = await bloc.permissions.requestCameraPermission();
                    cameraPermitted
                        ? print('user granted camera permission')
                        : print('user denied camera permission');
                    bloc.permissions.allRequested.sink.add(true);
                    bloc.qr.qrResult.sink.add(null);
                })),
                Expanded(flex: 1, child: SizedBox()),
            ]
        );
    }

    Widget _qrCamera(Bloc bloc) {
        return StreamBuilder(
            stream: bloc.permissions.cameraPermitted,
            builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox();
                final cameraPermitted = snapshot.data;
                if (cameraPermitted) {
                    return StreamBuilder(
                        stream: bloc.qr.cameraInitialized,
                        builder: (context, AsyncSnapshot<bool> snapshot) {
                            if (!snapshot.hasData || !snapshot.data) {
                                return Positioned(
                                    top: 0, left: 0, right: 0, bottom: 0,
                                    child: SizedBox()
                                );
                            }
                            return Positioned(
                                top: 0, left: 0, right: 0, bottom: 0,
                                child: QrCamera(
                                    onResult: (String result) {
                                        print('[JoinCall] QrCamera result = $result');
                                    }
                                )
                            );
                        }
                    );
                } else {
                    return Card(
                        child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                                children: [
                                    Row(children: [
                                        Icon(Icons.camera_alt),
                                        SizedBox(width: 16),
                                        Flexible(child: Text('Pitch needs camera access for joining calls via QR codes.'))
                                    ]),
                                    SizedBox(height: 16),
                                    RaisedButton(child: Text('Okay'), onPressed: () {
                                        bloc.permissions.requestCameraPermission();
                                    })
                                ]
                            ),
                        )
                    );
                }
            }
        );
    }

}
