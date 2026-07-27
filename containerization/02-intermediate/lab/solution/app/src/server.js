const express = require('express');
const app = express();
const port = Number(process.env.PORT || 8080);

const parcels = [
  { id: 'PG-1001', status: 'in_transit', city: 'Bangkok' },
  { id: 'PG-1002', status: 'delivered', city: 'Chiang Mai' },
  { id: 'PG-1003', status: 'sorting', city: 'Khon Kaen' },
];

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'parcelgo-api' });
});

app.get('/api/parcels', (_req, res) => {
  res.json(parcels);
});

app.get('/api/parcels/:id', (req, res) => {
  const found = parcels.find((p) => p.id === req.params.id);
  if (!found) return res.status(404).json({ error: 'not found' });
  return res.json(found);
});

app.listen(port, '0.0.0.0', () => {
  console.log(`ParcelGo API on ${port}`);
});
