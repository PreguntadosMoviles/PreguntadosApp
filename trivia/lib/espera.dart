import 'package:flutter/material.dart';

class WaitingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Text(
          'Esperando a que los demás jugadores finalicen...',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
