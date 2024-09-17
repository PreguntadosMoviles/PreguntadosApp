const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

let players = [];  // Lista de jugadores conectados
const questions = [
  { question: '¿Cuál es la capital de Francia?', options: ['París', 'Londres', 'Berlín', 'Madrid'], answer: 'París' },
  { question: '¿Cuánto es 2 + 2?', options: ['3', '4', '5', '6'], answer: '4' },
  { question: '¿Cuál es el color del cielo?', options: ['Rojo', 'Azul', 'Verde', 'Amarillo'], answer: 'Azul' }
];

wss.on('connection', ws => {
  console.log('Nuevo jugador conectado');
  players.push(ws);  // Agregar nuevo jugador a la lista

  ws.on('message', message => {
    const msg = JSON.parse(message);

    if (msg.type === 'start') {
      // Cuando uno de los jugadores inicia el juego
      console.log('El juego ha comenzado');
      players.forEach(player => {
        player.send(JSON.stringify({ type: 'start', questions: questions }));
      });
    }

    if (msg.type === 'disconnect') {
      console.log('Jugador desconectado');
      players = players.filter(player => player !== ws);
    }
  });

  ws.on('close', () => {
    console.log('Jugador desconectado');
    players = players.filter(player => player !== ws);
  });
});

console.log('Servidor WebSocket ejecutándose en ws://localhost:8080');
