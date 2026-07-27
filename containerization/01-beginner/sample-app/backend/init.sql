CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO
  products (name, price_cents)
VALUES
  ('Wireless Mouse', 59900),
  ('USB-C Hub', 129900),
  ('Mechanical Keyboard', 249900) ON CONFLICT DO NOTHING;
