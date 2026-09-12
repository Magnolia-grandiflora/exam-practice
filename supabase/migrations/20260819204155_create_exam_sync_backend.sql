-- Personal Exam App: authenticated, per-user incremental sync backend.
-- The client calls public.sync_exchange through the Supabase Data API.

create table public.exam_sync_entities (
  user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null
    check (entity_type in (
      'answer_event',
      'question_progress_control',
      'paper_attempt'
    )),
  entity_id text not null check (length(entity_id) between 1 and 200),
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  payload_hash text not null
    check (payload_hash ~ '^[0-9a-f]{64}$'),
  source_device_id text not null check (length(source_device_id) between 1 and 200),
  archived_by_windows_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, entity_type, entity_id)
);

create table public.exam_sync_changes (
  change_id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null,
  entity_id text not null,
  payload jsonb not null,
  payload_hash text not null,
  source_device_id text not null,
  changed_at timestamptz not null default now(),
  foreign key (user_id, entity_type, entity_id)
    references public.exam_sync_entities(user_id, entity_type, entity_id)
    on delete cascade
);

create table public.exam_sync_conflicts (
  conflict_id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  outbox_id text not null,
  entity_type text not null,
  entity_id text not null,
  existing_payload_hash text not null,
  incoming_payload_hash text not null,
  incoming_payload jsonb not null,
  source_device_id text not null,
  created_at timestamptz not null default now(),
  unique (user_id, outbox_id, incoming_payload_hash)
);

create index exam_sync_changes_user_cursor_idx
  on public.exam_sync_changes(user_id, change_id);

create index exam_sync_entities_user_papers_idx
  on public.exam_sync_entities(user_id, updated_at desc, entity_id)
  where entity_type = 'paper_attempt';

create index exam_sync_conflicts_user_created_idx
  on public.exam_sync_conflicts(user_id, created_at desc);

alter table public.exam_sync_entities enable row level security;
alter table public.exam_sync_entities force row level security;
alter table public.exam_sync_changes enable row level security;
alter table public.exam_sync_changes force row level security;
alter table public.exam_sync_conflicts enable row level security;
alter table public.exam_sync_conflicts force row level security;

create policy exam_sync_entities_select_own
  on public.exam_sync_entities
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy exam_sync_entities_insert_own
  on public.exam_sync_entities
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy exam_sync_entities_update_own
  on public.exam_sync_entities
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy exam_sync_entities_delete_own
  on public.exam_sync_entities
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create policy exam_sync_changes_select_own
  on public.exam_sync_changes
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy exam_sync_changes_insert_own
  on public.exam_sync_changes
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy exam_sync_changes_delete_own
  on public.exam_sync_changes
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create policy exam_sync_conflicts_select_own
  on public.exam_sync_conflicts
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy exam_sync_conflicts_insert_own
  on public.exam_sync_conflicts
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

revoke all on table
  public.exam_sync_entities,
  public.exam_sync_changes,
  public.exam_sync_conflicts
from public, anon, authenticated;

grant select, insert, update, delete
  on table public.exam_sync_entities
  to authenticated;
grant select, insert, delete
  on table public.exam_sync_changes
  to authenticated;
grant select, insert
  on table public.exam_sync_conflicts
  to authenticated;

revoke all on sequence
  public.exam_sync_changes_change_id_seq,
  public.exam_sync_conflicts_conflict_id_seq
from public, anon, authenticated;
grant usage, select on sequence public.exam_sync_changes_change_id_seq
  to authenticated;
grant usage, select on sequence public.exam_sync_conflicts_conflict_id_seq
  to authenticated;

create or replace function public.sync_exchange(
  p_device_id text,
  p_cursor bigint,
  p_items jsonb,
  p_schema_version integer
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_item jsonb;
  v_payload jsonb;
  v_entity_type text;
  v_entity_id text;
  v_outbox_id text;
  v_payload_hash text;
  v_existing_hash text;
  v_existing_payload jsonb;
  v_existing_version integer;
  v_incoming_version integer;
  v_existing_updated timestamptz;
  v_incoming_updated timestamptz;
  v_existing_device text;
  v_incoming_device text;
  v_should_replace boolean;
  v_accepted jsonb := '[]'::jsonb;
  v_changes jsonb := '[]'::jsonb;
  v_next_cursor bigint := greatest(coalesce(p_cursor, 0), 0);
  v_prunable_papers text[] := array[]::text[];
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_schema_version <> 1 then
    raise exception 'unsupported schema version: %', p_schema_version
      using errcode = '22023';
  end if;
  if p_device_id is null or length(p_device_id) not between 1 and 200 then
    raise exception 'invalid device_id' using errcode = '22023';
  end if;
  if p_cursor is null or p_cursor < 0 then
    raise exception 'invalid cursor' using errcode = '22023';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) > 100 then
    raise exception 'items must be an array with at most 100 entries'
      using errcode = '22023';
  end if;

  -- Keep concurrent exchanges for the same account deterministic and short.
  perform pg_advisory_xact_lock(hashtextextended(v_user_id::text, 0));

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_outbox_id := v_item ->> 'outbox_id';
    v_entity_type := v_item ->> 'entity_type';
    v_entity_id := v_item ->> 'entity_id';
    v_payload_hash := v_item ->> 'payload_hash';

    if jsonb_typeof(v_item -> 'payload_json') = 'string' then
      v_payload := (v_item ->> 'payload_json')::jsonb;
    else
      v_payload := coalesce(v_item -> 'payload_json', v_item -> 'payload');
    end if;

    if v_outbox_id is null or length(v_outbox_id) not between 1 and 420 then
      raise exception 'invalid outbox_id' using errcode = '22023';
    end if;
    if v_entity_id is null or length(v_entity_id) not between 1 and 200 then
      raise exception 'invalid entity_id for outbox %', v_outbox_id
        using errcode = '22023';
    end if;
    if v_payload is null or jsonb_typeof(v_payload) <> 'object' then
      raise exception 'invalid payload for outbox %', v_outbox_id
        using errcode = '22023';
    end if;
    if v_payload_hash is null or v_payload_hash !~ '^[0-9a-f]{64}$' then
      raise exception 'invalid payload hash for outbox %', v_outbox_id
        using errcode = '22023';
    end if;
    if octet_length(v_payload::text) > 2097152 then
      raise exception 'payload too large for outbox %', v_outbox_id
        using errcode = '22023';
    end if;

    if v_entity_type = 'paper_archive_ack' then
      if v_payload ->> 'attempt_id' is distinct from v_entity_id then
        raise exception 'paper archive id mismatch for outbox %', v_outbox_id
          using errcode = '22023';
      end if;
      update public.exam_sync_entities
      set archived_by_windows_at = greatest(
            coalesce(archived_by_windows_at, '-infinity'::timestamptz),
            (v_payload ->> 'archived_by_windows_at')::timestamptz
          ),
          updated_at = now()
      where user_id = v_user_id
        and entity_type = 'paper_attempt'
        and entity_id = v_entity_id;
      v_accepted := v_accepted || jsonb_build_array(v_outbox_id);
      continue;
    end if;

    if v_entity_type not in (
      'answer_event',
      'question_progress_control',
      'paper_attempt'
    ) then
      raise exception 'unsupported entity type: %', v_entity_type
        using errcode = '22023';
    end if;

    if (v_entity_type = 'answer_event' and
        v_payload ->> 'event_id' is distinct from v_entity_id) or
       (v_entity_type = 'question_progress_control' and
        v_payload ->> 'question_id' is distinct from v_entity_id) or
       (v_entity_type = 'paper_attempt' and
        v_payload ->> 'attempt_id' is distinct from v_entity_id) then
      raise exception 'payload entity id mismatch for outbox %', v_outbox_id
        using errcode = '22023';
    end if;

    v_existing_hash := null;
    v_existing_payload := null;
    select payload_hash, payload
      into v_existing_hash, v_existing_payload
    from public.exam_sync_entities
    where user_id = v_user_id
      and entity_type = v_entity_type
      and entity_id = v_entity_id
    for update;

    if v_existing_hash is null then
      insert into public.exam_sync_entities(
        user_id,
        entity_type,
        entity_id,
        payload,
        payload_hash,
        source_device_id
      ) values (
        v_user_id,
        v_entity_type,
        v_entity_id,
        v_payload,
        v_payload_hash,
        p_device_id
      );
      insert into public.exam_sync_changes(
        user_id,
        entity_type,
        entity_id,
        payload,
        payload_hash,
        source_device_id
      ) values (
        v_user_id,
        v_entity_type,
        v_entity_id,
        v_payload,
        v_payload_hash,
        p_device_id
      );
      v_accepted := v_accepted || jsonb_build_array(v_outbox_id);
      continue;
    end if;

    if v_existing_hash = v_payload_hash then
      v_accepted := v_accepted || jsonb_build_array(v_outbox_id);
      continue;
    end if;

    if v_entity_type = 'question_progress_control' then
      v_existing_version := coalesce((v_existing_payload ->> 'version')::integer, 0);
      v_incoming_version := coalesce((v_payload ->> 'version')::integer, 0);
      v_existing_updated := (v_existing_payload ->> 'updated_at_utc')::timestamptz;
      v_incoming_updated := (v_payload ->> 'updated_at_utc')::timestamptz;
      v_existing_device := coalesce(v_existing_payload ->> 'device_id', '');
      v_incoming_device := coalesce(v_payload ->> 'device_id', p_device_id);
      v_should_replace :=
        v_incoming_version > v_existing_version or
        (v_incoming_version = v_existing_version and
         v_incoming_updated > v_existing_updated) or
        (v_incoming_version = v_existing_version and
         v_incoming_updated = v_existing_updated and
         v_incoming_device > v_existing_device);

      if v_should_replace then
        update public.exam_sync_entities
        set payload = v_payload,
            payload_hash = v_payload_hash,
            source_device_id = p_device_id,
            updated_at = now()
        where user_id = v_user_id
          and entity_type = v_entity_type
          and entity_id = v_entity_id;
        insert into public.exam_sync_changes(
          user_id,
          entity_type,
          entity_id,
          payload,
          payload_hash,
          source_device_id
        ) values (
          v_user_id,
          v_entity_type,
          v_entity_id,
          v_payload,
          v_payload_hash,
          p_device_id
        );
      end if;
      v_accepted := v_accepted || jsonb_build_array(v_outbox_id);
      continue;
    end if;

    -- Immutable answer events and paper snapshots never overwrite a different hash.
    insert into public.exam_sync_conflicts(
      user_id,
      outbox_id,
      entity_type,
      entity_id,
      existing_payload_hash,
      incoming_payload_hash,
      incoming_payload,
      source_device_id
    ) values (
      v_user_id,
      v_outbox_id,
      v_entity_type,
      v_entity_id,
      v_existing_hash,
      v_payload_hash,
      v_payload,
      p_device_id
    ) on conflict (user_id, outbox_id, incoming_payload_hash) do nothing;
  end loop;

  -- Keep all answer events, but retain only the latest ten complete paper
  -- snapshots once an older paper has been archived by Windows.
  select coalesce(array_agg(entity_id), array[]::text[])
    into v_prunable_papers
  from (
    select entity_id
    from (
      select
        entity_id,
        archived_by_windows_at,
        row_number() over (
          order by
            coalesce(
              nullif(payload ->> 'submitted_at_utc', '')::timestamptz,
              created_at
            ) desc,
            entity_id desc
        ) as paper_rank
      from public.exam_sync_entities
      where user_id = v_user_id
        and entity_type = 'paper_attempt'
    ) ranked
    where paper_rank > 10
      and archived_by_windows_at is not null
  ) prunable;

  if cardinality(v_prunable_papers) > 0 then
    delete from public.exam_sync_changes
    where user_id = v_user_id
      and entity_type = 'paper_attempt'
      and entity_id = any(v_prunable_papers);
    delete from public.exam_sync_entities
    where user_id = v_user_id
      and entity_type = 'paper_attempt'
      and entity_id = any(v_prunable_papers);
  end if;

  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'change_id', change_id,
          'entity_type', entity_type,
          'entity_id', entity_id,
          'payload', payload,
          'payload_hash', payload_hash,
          'source_device_id', source_device_id
        ) order by change_id
      ),
      '[]'::jsonb
    ),
    coalesce(max(change_id), p_cursor)
    into v_changes, v_next_cursor
  from (
    select
      change_id,
      entity_type,
      entity_id,
      payload,
      payload_hash,
      source_device_id
    from public.exam_sync_changes
    where user_id = v_user_id
      and change_id > p_cursor
    order by change_id
    limit 500
  ) change_page;

  return jsonb_build_object(
    'accepted_outbox_ids', v_accepted,
    'changes', v_changes,
    'next_cursor', v_next_cursor::text
  );
end;
$$;

revoke all on function public.sync_exchange(text, bigint, jsonb, integer)
  from public, anon;
grant execute on function public.sync_exchange(text, bigint, jsonb, integer)
  to authenticated;

comment on function public.sync_exchange(text, bigint, jsonb, integer) is
  'Atomic authenticated push/pull exchange for Personal Exam App schema v1.';
