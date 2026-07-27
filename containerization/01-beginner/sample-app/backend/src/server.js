const express = require('express');
const { Pool } = require('pg');

const app = express();
const port = Number(process.env.PORT || 3000);
const databaseUrl = process.env.DATABASE_URL;

const pool = databaseUrl ? new Pool({ connectionString: databaseUrl }) : null;

app.use(express.json());

app.get('/health', async (_req, res) => {
  if (!pool) {
    return res.status(200).json({ status: 'ok', db: 'skipped' });
  }
  try {
    await pool.query('SELECT 1');
    return res.status(200).json({ status: 'ok', db: 'up' });
  } catch (err) {
    return res.status(503).json({ status: 'degraded', db: 'down', error: err.message });
  }
});

app.get('/api/products', async (_req, res) => {
  if (!pool) {
    return res.json([{ id: 1, name: 'Demo Product', price_cents: 10000 }]);
  }
  try {
    const result = await pool.query(
      'SELECT id, name, price_cents, created_at FROM products ORDER BY id ASC',
    );
    return res.json(result.rows);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.post('/api/products', async (req, res) => {
  const { name, price_cents } = req.body || {};
  if (!name || typeof price_cents !== 'number') {
    return res.status(400).json({ error: 'name and price_cents required' });
  }
  if (!pool) {
    return res.status(201).json({ id: 99, name, price_cents });
  }
  try {
    const result = await pool.query(
      'INSERT INTO products (name, price_cents) VALUES ($1, $2) RETURNING id, name, price_cents, created_at',
      [name, price_cents],
    );
    return res.status(201).json(result.rows[0]);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`ShopLite backend listening on ${port}`);
});
