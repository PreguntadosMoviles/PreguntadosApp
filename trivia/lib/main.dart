import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(TriviaGame());
}

class TriviaGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trivia Game',

      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        textTheme: TextTheme(
          displayLarge: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
          bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
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
  List<String> players = [];
  Map<String, int> scores = {};
  int globalTimeRemaining = 60;

  @override
  void initState() {
    super.initState();

    widget.channel.stream.listen((data) {
      final message = json.decode(data);

      if (message['type'] == 'start') {
        setState(() {
          isGameStarted = true;
          questions = List<Map<String, dynamic>>.from(message['questions']);
          globalTimeRemaining = message['timer'];
          scores = Map<String, int>.from(message['scores']);
        });
      }

      if (message['type'] == 'players') {
        setState(() {
          players = List<String>.from(message['players']);
        });
      }

      if (message['type'] == 'timer') {
        setState(() {
          globalTimeRemaining = message['timeRemaining'];
          if (globalTimeRemaining <= 0) {
            isGameStarted = false;
            _showEndDialog();
          }
        });
      }

      if (message['type'] == 'update_scores') {
        setState(() {
          scores = Map<String, int>.from(message['scores']);

        });
      }
    });
  }

  void _showEndDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Juego terminado'),
        content: Text('Se ha acabado el tiempo. ¡Gracias por jugar!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                isGameStarted = false;
              });
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    widget.channel.sink.add(json.encode({'type': 'start'}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text('Lobby', style: Theme.of(context).textTheme.displayLarge),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Center(
        child: isGameStarted
            ? TriviaPage(
                channel: widget.channel,
                questions: questions,
                globalTimeRemaining: globalTimeRemaining,
                scores: scores)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Jugadores conectados:',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  SizedBox(height: 20),
                  if (players.isEmpty)
                    Text(
                      'Esperando jugadores...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  for (var player in players)
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        player,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent[400],
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _startGame,
                    child: Text(
                      'Empezar de nuevo',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
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
  final int globalTimeRemaining;
  final Map<String, int> scores;

  TriviaPage(
      {required this.channel,
      required this.questions,
      required this.globalTimeRemaining,
      required this.scores});

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
    timeRemaining = widget.globalTimeRemaining;
    startGlobalTimer();
  }

  void startGlobalTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeRemaining > 0) {
          timeRemaining--;
        } else {
          timer.cancel();
          widget.channel.sink.add(json.encode({'type': 'end', 'score': score}));
          _showEndDialog();
        }
      });
    });
  }

  void _showEndDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Juego terminado'),
        content: Text('Se ha acabado el tiempo. ¡Gracias por jugar!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _answerQuestion(String selectedOption) {
    if (selectedOption == widget.questions[currentQuestionIndex]['answer']) {
      setState(() {
        score++;
      });
      widget.channel.sink
          .add(json.encode({'type': 'update_score', 'score': score}));
    }
    _nextQuestion();
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title:
            Text('Trivia Game', style: Theme.of(context).textTheme.displayLarge),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Tabla de puntajes',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.scores.keys.length,
                itemBuilder: (context, index) {
                  String player = widget.scores.keys.elementAt(index);
                  return ListTile(
                    title: Text(player,
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    trailing: Text(
                      widget.scores[player].toString(),
                      style: TextStyle(color: Colors.greenAccent, fontSize: 18),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text('Tiempo restante: $timeRemaining',
                style: TextStyle(fontSize: 24, color: Colors.redAccent)),
            SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 8,
              color: Colors.blueGrey[700],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.questions[currentQuestionIndex]['question'],
                  style: TextStyle(fontSize: 24, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 20),
            Column(
              children: widget.questions[currentQuestionIndex]['options']
                  .map<Widget>((option) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => _answerQuestion(option),
                    child: Text(option,
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

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