const express = require('express');
const app = express();
const port = Number(process.env.PORT || 8080);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'multistage-demo' });
});

app.get('/', (_req, res) => {
  res.json({ message: 'hello from multi-stage image' });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`listening on ${port}`);
});
