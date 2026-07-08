-- ═══════════════════════════════════════════════════════════════════
-- BUCKET logos — armazenamento de logos de empresas e consultorias
-- Executar no Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════

-- 1. Cria o bucket público (se já existir, garante que public=true)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'logos', 'logos', true,
  2097152,                          -- 2 MB máx por arquivo
  ARRAY['image/jpeg','image/png','image/webp','image/gif','image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Autenticados podem fazer upload
CREATE POLICY "logos_insert" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'logos');

-- 3. Todos podem ler (URL pública nos certificados)
CREATE POLICY "logos_select" ON storage.objects
FOR SELECT TO anon, authenticated
USING (bucket_id = 'logos');

-- 4. Autenticados podem substituir (upsert via x-upsert)
CREATE POLICY "logos_update" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'logos');

-- 5. Autenticados podem excluir
CREATE POLICY "logos_delete" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'logos');

-- ───────────────────────────────────────────────────────────────────
-- Para reverter:
-- DELETE FROM storage.buckets WHERE id = 'logos';
-- DROP POLICY "logos_insert" ON storage.objects;
-- DROP POLICY "logos_select" ON storage.objects;
-- DROP POLICY "logos_update" ON storage.objects;
-- DROP POLICY "logos_delete" ON storage.objects;
-- ═══════════════════════════════════════════════════════════════════
