import 'package:flutter/material.dart';

class ResultsPage extends StatelessWidget {
  final int player1Score;
  final int player2Score;

  ResultsPage({required this.player1Score, required this.player2Score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Resultados')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Resultados del Juego',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Jugador 1: $player1Score correctas',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Jugador 2: $player2Score correctas',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Regresar a la pantalla principal o reiniciar el juego
                Navigator.pop(context);
              },
              child: Text('Volver al Lobby'),
            ),
          ],
        ),
      ),
    );
  }
}
