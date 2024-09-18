import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; // Importa para crear una nueva conexión WebSocket
import 'main.dart'; // Importa la página de LobbyPage

class ResultsPage extends StatelessWidget {
  final int player1Score;
  final int player2Score;

  ResultsPage({required this.player1Score, required this.player2Score});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Realiza la misma acción de volver al lobby cuando se presiona la flecha hacia atrás
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyPage(
              channel: WebSocketChannel.connect(
                Uri.parse('ws://localhost:8082'), // Reinicia la conexión
              ),
            ),
          ),
          (Route<dynamic> route) => false,
        );
        return false; // Previene el comportamiento de retroceso predeterminado
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
                'Resultados del Juego',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Jugador 1: $player1Score correctas',
                style: TextStyle(fontSize: 24, color: Colors.white70),
              ),
              Text(
                'Jugador 2: $player2Score correctas',
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
                  // Cerrar la conexión actual y volver al Lobby como un nuevo usuario
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LobbyPage(
                        channel: WebSocketChannel.connect(
                          Uri.parse(
                              'ws://localhost:8082'), // Reinicia la conexión
                        ),
                      ),
                    ),
                    (Route<dynamic> route) =>
                        false, // Elimina todas las rutas anteriores
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
