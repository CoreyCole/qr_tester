import 'package:firebase_core/firebase_core.dart';

import './services/qr_service.dart';
import './services/permissions_service.dart';


class Bloc {
    PermissionsService permissions;
    QrService qr;
    FirebaseApp firebaseApp;

    Bloc(FirebaseApp firebaseApp) {
        firebaseApp = firebaseApp;
        permissions = PermissionsService();
        qr = QrService(permissions);
    }

    dispose() {
        permissions.dispose();
        qr.dispose();
    }
}
