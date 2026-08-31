-- =============================================
-- PERFUSKY — Migración v2: stock, cupones y métricas de pedidos
-- Correr UNA VEZ en: Supabase Dashboard > SQL Editor > New query > Run
-- (proyecto: ppmhkeatgcvaygrajcra)
-- =============================================

-- 1) Stock por producto. NULL = sin límite / no controlado (comportamiento actual).
ALTER TABLE products ADD COLUMN IF NOT EXISTS stock INTEGER;

-- 2) Cupón y descuento aplicados a un pedido (se completan al mandar el carrito por WhatsApp).
ALTER TABLE orders ADD COLUMN IF NOT EXISTS coupon_code VARCHAR(50);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0;

-- 3) Cupones de descuento
CREATE TABLE IF NOT EXISTS coupons (
  id              SERIAL PRIMARY KEY,
  code            VARCHAR(50) UNIQUE NOT NULL,
  discount_type   VARCHAR(10) NOT NULL CHECK (discount_type IN ('percent', 'fixed')),
  discount_value  DECIMAL(10,2) NOT NULL,
  active          BOOLEAN DEFAULT TRUE,
  expires_at      TIMESTAMP,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;

-- Cualquier visitante puede leer los cupones activos y vigentes (para validarlos en el carrito).
CREATE POLICY "public read active coupons" ON coupons
  FOR SELECT USING (active = true AND (expires_at IS NULL OR expires_at > now()));

-- El admin autenticado puede leer/crear/editar/borrar cualquier cupón (incluidos inactivos/vencidos).
CREATE POLICY "admin write coupons" ON coupons
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- 4) Índice que falta para agregar "más vendidos" en las métricas del admin.
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);
