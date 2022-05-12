/* Mostly based on https://nodejs.org/en/docs/guides/getting-started-guide/ */

const http = require('http');

const hostname = '127.0.0.1';
const port = 3333;

response_text = "Hello world";

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end(response_text);
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});