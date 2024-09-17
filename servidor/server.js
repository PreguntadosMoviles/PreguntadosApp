const WebSocket = require('ws');
const axios = require('axios');

async function obtenerPreguntas(){
  const url = 'https://api.quiz-contest.xyz/questions?limit=10&page=1&category=geography&format=multiple';
  try{
    const response = await axios.get(url, { headers:{ 'Authorization': '$2b$12$JQ01Gihw4ey.Lk2azzoyH.XjaL2SdZvzCNN/IGKi66GM9Q89J.OaC'}});
    const preguntas = response.data.questions.map(pregunta => ({
      question: pregunta.question,
      options: [...pregunta.incorrectAnswers, pregunta.correctAnswers].sort(() => Math.random() - 0.5),
      answer: pregunta.correctAnswers
    }));
    return preguntas;

  } catch (error){
    console.error('Error al obtener las preguntas', error);
    return [];
  }

}
obtenerPreguntas().then(questions => {
  console.log('Servidor WebSocket ejecutándose con las preguntas obtenidas');

  const wss = new WebSocket.Server({ port: 8082 }); //cambio por mi compu

  let players = [];  // Lista de jugadores conectados

  wss.on('connection', ws => {
    console.log('Nuevo jugador conectado');
    players.push(ws);  // Agregar nuevo jugador a la lista

    ws.on('message', message => {
      const msg = JSON.parse(message);

      if (msg.type === 'start') {
        // Cuando uno de los jugadores inicia el juego
        console.log('El juego ha comenzado');

        // Usar las preguntas obtenidas previamente para iniciar el juego
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

}).catch(error => {
  console.error('Error al iniciar el servidor WebSocket:', error);
});