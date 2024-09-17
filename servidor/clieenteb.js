const WebSocket = require('ws');


const ws = new WebSocket('ws://localhost:8082');

ws.on('open', function open() {
  console.log('Conectado al servidor WebSocket');
  ws.send(JSON.stringify({ type: 'start' }));
});

ws.on('message', function incoming(data) {
  const message = JSON.parse(data);
  console.log('Mensaje recibido del servidor:', message);
  if (message.type === 'start') {
    console.log('Preguntas:', message.questions);
  }
});

ws.on('close', function close() {
  console.log('Desconectado del servidor WebSocket');
});