import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; // Importa para crear una nueva conexión WebSocket
import 'main.dart'; // Importa la página de LobbyPage

class ResultsPage extends StatelessWidget {
  final int player1Score;
  final int player2Score;
  final String playerId; // Identificar si es Jugador 1 o Jugador 2

  ResultsPage({
    required this.player1Score,
    required this.player2Score,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context) {
    // Identificar al jugador actual y al contrincante
    String jugadorActual = playerId == 'Jugador 1' ? 'Jugador 1' : 'Jugador 2';
    String contrincante = playerId == 'Jugador 1' ? 'Jugador 2' : 'Jugador 1';
    int scoreActual = playerId == 'Jugador 1' ? player1Score : player2Score;
    int scoreContrincante = playerId == 'Jugador 1' ? player2Score : player1Score;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyPage(
              channel: WebSocketChannel.connect(
                Uri.parse('ws://localhost:8082'),
              ),
            ),
          ),
          (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey[900],
        appBar: AppBar(
          title: Text('Resultados',
              style: Theme.of(context).textTheme.displayLarge),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blueGrey[800],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Resultados del Juego: ¡Eres el "$jugadorActual"!',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 20),
              // Mostrar puntaje del jugador actual
              Text(
                '$jugadorActual: $scoreActual correctas',
                style: TextStyle(fontSize: 24, color: Colors.white70),
              ),
              SizedBox(height: 20),
              // Mostrar puntaje del contrincante
              Text(
                '$contrincante: $scoreContrincante correctas',
                style: TextStyle(fontSize: 24, color: Colors.white70),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[400],
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LobbyPage(
                        channel: WebSocketChannel.connect(
                          Uri.parse('ws://localhost:8082'),
                        ),
                      ),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Text('Volver al Lobby',
                    style: TextStyle(fontSize: 20, color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
