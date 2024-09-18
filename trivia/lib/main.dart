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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LobbyPage(channel: WebSocketChannel.connect(Uri.parse('ws://localhost:8082'))),
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

  @override
  void initState() {
    super.initState();

    widget.channel.stream.listen((data) {
      final message = json.decode(data);
      print('Mensaje recibido: $message'); // Log del mensaje recibido
      if (message['type'] == 'start') {
        setState(() {
          isGameStarted = true;
          questions = List<Map<String, dynamic>>.from(message['questions'].map((q) => {
                'question': q['question'],
                'options': List<String>.from(q['options']),
                'answer': q['answer'],
              }));
        });
      }

      if (message['type'] == 'over') {
        print('Recibido mensaje de fin de juego. Puntajes: Jugador 1 - ${message['player1Score']}, Jugador 2 - ${message['player2Score']}');
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
                  Text('Esperando a otros jugadores...'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startGame,
                    child: Text('Empezar'),
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
  int timeRemaining = 10;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        timeRemaining = 10;
        startTimer();
      });
    } else {
      timer?.cancel();
      print('Enviando puntaje final: $score');
      
      // Verificar si el canal WebSocket está abierto
      if (widget.channel.sink != null) {
        widget.channel.sink.add(json.encode({
          'type': 'end',
          'score': score
        }));
        print('Mensaje de puntaje final enviado');
      } else {
        print('El canal WebSocket está cerrado o no disponible');
      }
    }
  }

  void startTimer() {
    timer?.cancel(); // Asegúrate de cancelar cualquier temporizador activo
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeRemaining > 0) {
          timeRemaining--;
        } else {
          timer.cancel();
          _nextQuestion(); // Cambia a la siguiente pregunta cuando se acabe el tiempo
        }
      });
    });
  }

  void _answerQuestion(String selectedOption) {
    if (selectedOption == widget.questions[currentQuestionIndex]['answer']) {
      setState(() {
        score++;
      });
    }
    _nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trivia Game')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Tiempo restante: $timeRemaining', style: TextStyle(fontSize: 24, color: Colors.red)),
          SizedBox(height: 20),
          Text(
            widget.questions[currentQuestionIndex]['question'],
            style: TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ...widget.questions[currentQuestionIndex]['options'].map<Widget>((option) {
            return ElevatedButton(
              onPressed: () => _answerQuestion(option),
              child: Text(option),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    widget.channel.sink.close();
    super.dispose();
  }
}