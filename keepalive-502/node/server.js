const http = require('node:http');

const server = http.createServer((req, res) => {
  req.resume();
  req.on('end', () => res.end('ok\n'));
});

// How long an idle connection stays open. Node's default is 5 seconds.
server.keepAliveTimeout = Number(process.env.KEEPALIVE_TIMEOUT_MS);

// Must be larger than keepAliveTimeout.
server.headersTimeout = server.keepAliveTimeout + 1000;

server.listen(3000);
