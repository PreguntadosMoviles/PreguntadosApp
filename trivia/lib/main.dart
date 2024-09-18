import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';
import 'resultados.dart';

void main() {
  runApp(TriviaGame());
}

class TriviaGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trivia Game',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.blueGrey[900],
        primaryColor: Colors.blueGrey[800],
        textTheme: TextTheme(
          displayLarge: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent[400],
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[800],
          titleTextStyle: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      home: LobbyPage(
          channel: WebSocketChannel.connect(Uri.parse('ws://localhost:8082'))),
    );
  }
}

class LobbyPage extends StatefulWidget {
  final WebSocketChannel channel;

  LobbyPage({required this.channel});

  @override
  _LobbyPageState createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  bool isGameStarted = false;
  List<Map<String, dynamic>> questions = [];
  int playerCount = 0;

  @override
  void initState() {
    super.initState();

    widget.channel.stream.listen((data) {
      final message = json.decode(data);
      print('Mensaje recibido: $message');

      if (message['type'] == 'start') {
        setState(() {
          isGameStarted = true;
          questions =
              List<Map<String, dynamic>>.from(message['questions'].map((q) => {
                    'question': q['question'],
                    'options': List<String>.from(q['options']),
                    'answer': q['answer'],
                  }));
        });
      }

      if (message['type'] == 'over') {
        print(
            'Recibido mensaje de fin de juego. Puntajes: Jugador 1 - ${message['player1Score']}, Jugador 2 - ${message['player2Score']}');
        Future.delayed(Duration.zero, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsPage(
                player1Score: message['player1Score'],
                player2Score: message['player2Score'],
              ),
            ),
          );
        });
      }

      if (message['type'] == 'playerCount') {
        setState(() {
          playerCount = message['count'];
        });
      }
    });
  }

  void _startGame() {
    print('Enviando mensaje de inicio del juego');
    widget.channel.sink.add(json.encode({'type': 'start'}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lobby')),
      body: Center(
        child: isGameStarted
            ? TriviaPage(channel: widget.channel, questions: questions)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      'Esperando a otros jugadores... ($playerCount jugadores conectados)',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startGame,
                    child: Text('Empezar',
                        style: TextStyle(color: Colors.black, fontSize: 20)),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }
}

class TriviaPage extends StatefulWidget {
  final WebSocketChannel channel;
  final List<Map<String, dynamic>> questions;

  TriviaPage({required this.channel, required this.questions});

  @override
  _TriviaPageState createState() => _TriviaPageState();
}

class _TriviaPageState extends State<TriviaPage> {
  int currentQuestionIndex = 0;
  int score = 0;
  String selectedOption = '';
  late Timer timer;
  int timeRemaining = 15;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeRemaining > 0) {
        setState(() {
          timeRemaining--;
        });
      } else {
        _submitAnswer('');
      }
    });
  }

  void _submitAnswer(String option) {
    timer.cancel();
    if (option == widget.questions[currentQuestionIndex]['answer']) {
      setState(() {
        score++;
      });
    }

    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        timeRemaining = 15;
      });
      timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (timeRemaining > 0) {
          setState(() {
            timeRemaining--;
          });
        } else {
          _submitAnswer('');
        }
      });
    } else {
      widget.channel.sink.add(json.encode({'type': 'end', 'score': score}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Trivia')),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(16.0), // Agrega padding a todo el contenido
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(question['question'],
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center),
              SizedBox(height: 20),
              ...question['options'].map((option) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0), // Espacio entre botones
                    child: ElevatedButton(
                      onPressed: () => _submitAnswer(option),
                      child: Text(option,
                          style: TextStyle(
                              color: Colors.blueGrey[800],
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                  )),
              SizedBox(height: 20),
              Text('Tiempo restante: $timeRemaining s',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}
