const WebSocket = require('ws');
const axios = require('axios');

async function obtenerPreguntas() {
  const url = 'https://api.quiz-contest.xyz/questions?limit=60&page=1&category=geography&format=multiple';
  try {
    const response = await axios.get(url, { headers: { 'Authorization': '$2b$12$JQ01Gihw4ey.Lk2azzoyH.XjaL2SdZvzCNN/IGKi66GM9Q89J.OaC' } });
    const preguntas = response.data.questions.map(pregunta => ({
      question: pregunta.question,
      options: [...pregunta.incorrectAnswers, pregunta.correctAnswers].sort(() => Math.random() - 0.5),
      answer: pregunta.correctAnswers
    }));
    return preguntas;

  } catch (error) {
    console.error('Error al obtener las preguntas', error);
    return [];
  }
}

obtenerPreguntas().then(questions => {
  console.log('Servidor WebSocket ejecutándose con las preguntas obtenidas');

  const wss = new WebSocket.Server({ port: 8082 }); 
  let players = [];
  let globalTimer = 60;  // Timer global de 1 minuto
  let scores = {}; // Puntajes de los jugadores

  function broadcastPlayers() {
    const playerNames = players.map(player => player.id);
    players.forEach(player => {
      player.ws.send(JSON.stringify({ type: 'players', players: playerNames }));
    });
  }

  function broadcastScores() {
    players.forEach(player => {
      player.ws.send(JSON.stringify({ type: 'update_scores', scores }));
    });
  }

  function startGlobalTimer() {
    globalTimer = 60; // Reiniciar el timer global a 1 minuto
    const timerInterval = setInterval(() => {
      globalTimer--;
      players.forEach(player => {
        player.ws.send(JSON.stringify({ type: 'timer', timeRemaining: globalTimer }));
      });

      if (globalTimer <= 0) {
        clearInterval(timerInterval);
        players.forEach(player => {
          player.ws.send(JSON.stringify({ type: 'end', message: 'El tiempo ha terminado' }));
        });
      }
    }, 1000);
  }

  wss.on('connection', ws => {
    const playerId = `Jugador ${players.length + 1}`;
    console.log(`${playerId} conectado`);
    players.push({ ws, id: playerId });
    scores[playerId] = 0; // Iniciar el puntaje en 0

    broadcastPlayers();
    broadcastScores(); // Enviar puntajes iniciales

    ws.on('message', message => {
      const msg = JSON.parse(message);

      if (msg.type === 'start') {
        console.log('El juego ha comenzado');
        players.forEach(player => {
          player.ws.send(JSON.stringify({ type: 'start', questions, timer: globalTimer, scores }));
        });
        startGlobalTimer();
      }

      if (msg.type === 'update_score') {
        scores[playerId] = msg.score; // Actualizar puntaje del jugador
        broadcastScores(); // Enviar puntajes actualizados
      }

      if (msg.type === 'end') {
        console.log(`${playerId} terminó el juego con puntaje: ${msg.score}`);
      }
    });

    ws.on('close', () => {
      console.log(`${playerId} desconectado`);
      players = players.filter(player => player.ws !== ws);
      delete scores[playerId]; // Eliminar puntaje del jugador desconectado
      broadcastPlayers();
      broadcastScores(); // Actualizar tabla de puntajes
    });
  });

}).catch(error => {
  console.error('Error al iniciar el servidor WebSocket:', error);
});
