CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  price_cents INTEGER NOT NULL CHECK (price_cents >= 0)
);

INSERT INTO
  products (name, price_cents)
VALUES
  ('Espresso', 4500),
  ('Latte', 6500),
  ('Matcha Frappe', 7900) ON CONFLICT DO NOTHING;
