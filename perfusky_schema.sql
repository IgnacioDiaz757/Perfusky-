-- =============================================
-- PERFUSKY - Schema de Base de Datos
-- =============================================

-- Categorías
CREATE TABLE categories (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  slug        VARCHAR(100) UNIQUE,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Productos
CREATE TABLE products (
  id            SERIAL PRIMARY KEY,
  category_id   INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  name          VARCHAR(200) NOT NULL,
  description   TEXT,
  price         DECIMAL(10,2),
  on_sale       BOOLEAN DEFAULT FALSE,
  old_price     DECIMAL(10,2),
  sale_price    DECIMAL(10,2),
  image_url     VARCHAR(500),
  image_zoom    INTEGER DEFAULT 100,
  image_ratio   VARCHAR(10) DEFAULT '1',
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Configuración general (banner, WhatsApp, contraseña admin, super oferta)
CREATE TABLE settings (
  key         VARCHAR(50) PRIMARY KEY,
  value       TEXT NOT NULL,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pedidos (carrito enviado por WhatsApp)
CREATE TABLE orders (
  id              SERIAL PRIMARY KEY,
  customer_phone  VARCHAR(30),
  total           DECIMAL(10,2),
  status          VARCHAR(20) DEFAULT 'pending',
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Items del pedido
CREATE TABLE order_items (
  id          SERIAL PRIMARY KEY,
  order_id    INTEGER REFERENCES orders(id) ON DELETE CASCADE,
  product_id  INTEGER REFERENCES products(id) ON DELETE SET NULL,
  quantity    INTEGER NOT NULL DEFAULT 1,
  unit_price  DECIMAL(10,2) NOT NULL,
  subtotal    DECIMAL(10,2) NOT NULL
);

-- Super Oferta
CREATE TABLE super_offer (
  id            SERIAL PRIMARY KEY,
  is_active     BOOLEAN DEFAULT FALSE,
  product_name  VARCHAR(200),
  description   TEXT,
  old_price     DECIMAL(10,2),
  sale_price    DECIMAL(10,2),
  image_url     VARCHAR(500),
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Datos iniciales de configuración
-- (el login admin usa Supabase Auth real, ver perfusky_setup_supabase.sql — no guardar la
-- contraseña acá en texto plano)
INSERT INTO settings (key, value) VALUES
  ('whatsapp_number', '5493515066285'),
  ('banner_active', 'true'),
  ('banner_text', '🔥 5% OFF en todos los productos — ¡Solo por tiempo limitado!'),
  ('banner_bg', 'linear-gradient(90deg, #e74c3c, #c0392b)');

-- Super oferta inicial (inactiva)
INSERT INTO super_offer (is_active) VALUES (false);

-- Índices
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_on_sale ON products(on_sale);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date ON orders(created_at);
CREATE INDEX idx_order_items_order ON order_items(order_id);
