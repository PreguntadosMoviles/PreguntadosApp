const WebSocket = require('ws');
const axios = require('axios');

// Función para obtener las preguntas desde la API externa
async function obtenerPreguntas() {
  const url = 'https://api.quiz-contest.xyz/questions?limit=10&page=1&category=geography&format=multiple';
  try {
    const response = await axios.get(url, { headers: { 'Authorization': '$2b$12$JQ01Gihw4ey.Lk2azzoyH.XjaL2SdZvzCNN/IGKi66GM9Q89J.OaC' } });
    let preguntas = response.data.questions.map(pregunta => ({
      question: pregunta.question,
      options: [...pregunta.incorrectAnswers, pregunta.correctAnswers].sort(() => Math.random() - 0.5),
      answer: pregunta.correctAnswers
    }));

    preguntas = preguntas.sort(() => Math.random() - 0.5);
    
    return preguntas;
  } catch (error) {
    console.error('Error al obtener las preguntas', error);
    return [];
  }
}

// Inicializar el servidor WebSocket
obtenerPreguntas().then(questions => {
  console.log('Servidor WebSocket ejecutándose con las preguntas obtenidas');

  const wss = new WebSocket.Server({ port: 8082 });

  let players = []; // Array de jugadores
  let scores = {}; // Objeto para almacenar los puntajes de los jugadores
  let finishedPlayers = new Set(); // Para rastrear los jugadores que han terminado

  function notifyPlayerCount() {
    const playerCount = players.length;
    players.forEach(({ ws }) => {
      ws.send(JSON.stringify({ type: 'playerCount', count: playerCount }));
    });
  }

  wss.on('connection', ws => {
    const playerId = Date.now(); // Generar un ID único basado en el tiempo
    players.push({ id: playerId, ws: ws });
    scores[playerId] = 0; // Inicializar el puntaje para el nuevo jugador
    
    console.log(`Nuevo jugador conectado con ID: ${playerId}`);
    ws.send(JSON.stringify({ type: 'yourId', id: playerId }));
    notifyPlayerCount(); // Notificar el número de jugadores conectados

    ws.on('message', async message => {
      const msg = JSON.parse(message);
      console.log('Mensaje recibido:', msg);

      if (msg.type === 'start') {
        console.log('El juego ha comenzado');
        const preguntas = await obtenerPreguntas();
        players.forEach(({ ws }, index) => {
          console.log(`Enviando preguntas al jugador ${index + 1}`);
          ws.send(JSON.stringify({ type: 'start', questions: preguntas }));
        });
      }

      if (msg.type === 'end') {
        const player = players.find(player => player.ws === ws);
        if (!player) return;

        console.log(`Jugador ${player.id} terminó el juego con un puntaje de: ${msg.score}`);

        // Asignar el puntaje recibido
        scores[player.id] = msg.score;
        finishedPlayers.add(player.id); // Marcar al jugador como terminado

        // Verificar si todos los jugadores han terminado
        if (finishedPlayers.size === players.length) {
          // Preparar los puntajes para cada jugador
          const playerScores = {};
          players.forEach(({ id }) => {
            playerScores[id] = scores[id] || 0;
          });

          console.log('Enviando resultados...');
          players.forEach(({ ws, id }) => {
            ws.send(JSON.stringify({
              type: 'over',
              playerId: id === players[0].id ? 'Jugador 1' : 'Jugador 2',
              player1Score: playerScores[players[0].id] || 0,
              player2Score: playerScores[players[1].id] || 0
            }));
            console.log(`Enviado puntaje final al jugador con ID ${id}: ${playerScores[id]}`);
          });

          // Reiniciar los puntajes para un nuevo juego
          scores = {};
          players = [];
          finishedPlayers.clear(); // Limpiar el conjunto de jugadores terminados
          notifyPlayerCount(); // Notificar el número de jugadores conectados
        } else {
          // Si no todos los jugadores han terminado, redirigir al jugador a la pantalla de espera
          ws.send(JSON.stringify({ type: 'waiting' }));
        }
      }

      if (msg.type === 'disconnect') {
        console.log('Jugador desconectado');
        const playerIndex = players.findIndex(player => player.ws === ws);
        if (playerIndex !== -1) {
          const [removedPlayer] = players.splice(playerIndex, 1);
          delete scores[removedPlayer.id];
          finishedPlayers.delete(removedPlayer.id); // Eliminar al jugador desconectado del conjunto de terminados
          notifyPlayerCount(); // Notificar el número de jugadores conectados
        }
      }
    });

    ws.on('close', () => {
      console.log('Jugador desconectado');
      const playerIndex = players.findIndex(player => player.ws === ws);
      if (playerIndex !== -1) {
        const [removedPlayer] = players.splice(playerIndex, 1);
        delete scores[removedPlayer.id];
        finishedPlayers.delete(removedPlayer.id); // Eliminar al jugador desconectado del conjunto de terminados
        notifyPlayerCount(); // Notificar el número de jugadores conectados
      }
    });
  });

}).catch(error => {
  console.error('Error al iniciar el servidor WebSocket:', error);
});
