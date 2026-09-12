-- Read-only configuration checks; not authenticated end-to-end verification.
SELECT c.relname AS table_name, c.relrowsecurity AS rls_enabled,
       c.relforcerowsecurity AS rls_forced
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('exam_sync_entities', 'exam_sync_changes', 'exam_sync_conflicts')
ORDER BY c.relname;
-- Expected: exactly 3 rows, both boolean columns true.

SELECT tablename, policyname, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('exam_sync_entities', 'exam_sync_changes', 'exam_sync_conflicts')
ORDER BY tablename, policyname;
-- Expected: 9 policies, authenticated only, own user_id checked with auth.uid().

SELECT p.oid::regprocedure AS function_signature,
       NOT p.prosecdef AS security_invoker, p.proconfig AS function_settings,
       has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_can_execute,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') AS user_can_execute,
       obj_description(p.oid, 'pg_proc') AS version_comment
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'sync_exchange';
-- Expected: one (text,bigint,jsonb,integer) function, invoker=true,
-- empty search_path, anon=false, user=true, comment says schemas v1-v2.

SELECT pg_get_constraintdef(oid) AS allowed_entity_types
FROM pg_constraint
WHERE conrelid = 'public.exam_sync_entities'::regclass
  AND conname = 'exam_sync_entities_entity_type_check';
-- Expected: answer_event, question_progress_control, paper_attempt,
-- question_bank, question, question_media_chunk.

SELECT tablename, indexname FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'exam_sync_changes';
-- Includes exam_sync_changes_entity_fk_idx and user cursor index.
