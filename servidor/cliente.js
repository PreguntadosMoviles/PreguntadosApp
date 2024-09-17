const ws = new WebSocket('ws://localhost:8082');

ws.onopen = function() {
  console.log('Conectado al servidor WebSocket');
  ws.send(JSON.stringify({ type: 'start' }));
};

ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('Mensaje recibido del servidor:', data);
  if (data.type === 'start') {
    console.log('Preguntas:', data.questions);
  }
};

ws.onclose = function() {
  console.log('Desconectado del servidor WebSocket');
};
