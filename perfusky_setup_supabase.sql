-- =============================================
-- PERFUSKY — Setup para conectar el catálogo a Supabase de verdad
-- Correr esto UNA VEZ en: Supabase Dashboard > SQL Editor > New query > Run
-- (proyecto: ppmhkeatgcvaygrajcra)
-- =============================================

-- 1) Columna que falta en el schema original (guarda el aspect ratio 1:1/9:16/4:3 de cada producto)
ALTER TABLE products ADD COLUMN IF NOT EXISTS image_ratio VARCHAR(10) DEFAULT '1';

-- 1b) La tabla settings queda con lectura pública (paso 3 más abajo), así que sacamos la
--     contraseña vieja en texto plano que traía el seed de perfusky_schema.sql — el login
--     ahora es Supabase Auth real, esa fila ya no se usa y no debe quedar expuesta.
DELETE FROM settings WHERE key = 'admin_password';

-- 2) Asegurar que RLS está activo en todas las tablas
ALTER TABLE categories   ENABLE ROW LEVEL SECURITY;
ALTER TABLE products     ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings     ENABLE ROW LEVEL SECURITY;
ALTER TABLE super_offer  ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders       ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items  ENABLE ROW LEVEL SECURITY;

-- 3) Lectura pública (cualquier visitante puede ver el catálogo, banner y oferta)
CREATE POLICY "public read categories"  ON categories  FOR SELECT USING (true);
CREATE POLICY "public read products"    ON products    FOR SELECT USING (true);
CREATE POLICY "public read settings"    ON settings    FOR SELECT USING (true);
CREATE POLICY "public read super_offer" ON super_offer FOR SELECT USING (true);

-- 4) Escritura SOLO para el admin autenticado (usuario real de Supabase Auth, no la password vieja)
CREATE POLICY "admin write categories"  ON categories  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "admin write products"    ON products    FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "admin write settings"    ON settings    FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "admin write super_offer" ON super_offer FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- 5) Pedidos: cualquier visitante puede crear un pedido al mandar el carrito por WhatsApp,
--    pero sólo el admin autenticado puede leerlos/editarlos/borrarlos.
CREATE POLICY "public create orders"      ON orders      FOR INSERT WITH CHECK (true);
CREATE POLICY "admin manage orders"       ON orders      FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "admin update orders"       ON orders      FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "admin delete orders"       ON orders      FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "public create order_items" ON order_items FOR INSERT WITH CHECK (true);
CREATE POLICY "admin manage order_items"  ON order_items FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "admin delete order_items"  ON order_items FOR DELETE USING (auth.role() = 'authenticated');

-- 6) Bucket de Storage para las imágenes de producto (antes se guardaban en base64 en localStorage,
--    ahora se suben acá y sólo se guarda la URL pública en products.image_url / super_offer.image_url)
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "public read product-images" ON storage.objects
  FOR SELECT USING (bucket_id = 'product-images');
CREATE POLICY "admin upload product-images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'product-images' AND auth.role() = 'authenticated');
CREATE POLICY "admin update product-images" ON storage.objects
  FOR UPDATE USING (bucket_id = 'product-images' AND auth.role() = 'authenticated');
CREATE POLICY "admin delete product-images" ON storage.objects
  FOR DELETE USING (bucket_id = 'product-images' AND auth.role() = 'authenticated');

-- 7) IMPORTANTE — crear el usuario admin:
--    Dashboard > Authentication > Users > Add user
--    Email:    admin@perfusky.app   (debe coincidir EXACTO con ADMIN_EMAIL en index.html)
--    Password: la que quieras usar para entrar al panel admin del catálogo
--    Marcar "Auto Confirm User" para no tener que verificar el email.
--
--    Si preferís usar tu propio email en vez de admin@perfusky.app, cambiá también
--    la constante ADMIN_EMAIL al principio del <script> en index.html.
