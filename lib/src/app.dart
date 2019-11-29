import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'bloc/provider.dart';

// screens
import './screens/home_screen.dart';

class App extends StatelessWidget {
    static final FirebaseApp app = FirebaseApp(name: '[DEFAULT]');

    Widget build(context) {
        return Provider(
            firebaseApp: app,
            child: MaterialApp(
                title: 'Qr Tester',
                onGenerateRoute: _routes,
                debugShowCheckedModeBanner: false,
            )
        );
    }

    Route _routes(RouteSettings settings) {
        return MaterialPageRoute(
            settings: settings,
            // maintainState: true, // TODO: research this flag more
            builder: (context) {
                return SafeArea(
                    child: _handleRoute(settings)
                );
            }
        );
    }

    Widget _handleRoute(RouteSettings settings) {
        switch (settings.name) {
            case '/': {
                return HomeScreen();
            }
            default: {
                return HomeScreen();
            }
        }
    }
}
