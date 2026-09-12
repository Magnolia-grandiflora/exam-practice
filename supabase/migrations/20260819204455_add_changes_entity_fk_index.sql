-- Cover the composite foreign key used when parent sync entities are pruned.
create index exam_sync_changes_entity_fk_idx
  on public.exam_sync_changes(user_id, entity_type, entity_id);
