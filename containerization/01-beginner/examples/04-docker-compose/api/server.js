const express = require('express');
const Redis = require('ioredis');

const app = express();
const redis = new Redis(process.env.REDIS_URL || 'redis://127.0.0.1:6379');

app.get('/count', async (_req, res) => {
  const n = await redis.incr('hits');
  res.json({ hits: n });
});

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.listen(3000, '0.0.0.0', () => console.log('api on 3000'));
