const http = require('http');
const { greet, add } = require('./lib');

const PORT = process.env.PORT || 3000;
const APP_ENV = process.env.APP_ENV || 'local';

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  if (url.pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', env: APP_ENV }));
    return;
  }

  if (url.pathname === '/' || url.pathname.startsWith('/hello')) {
    const name = url.searchParams.get('name') || 'World';
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ message: greet(name), sum: add(2, 3) }));
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'not_found' }));
});

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`sample-app listening on :${PORT} (${APP_ENV})`);
  });
}

module.exports = { server };
