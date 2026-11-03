-- Cronômetro All Hands: sessões, chave de controle e registro de tempos.
-- Ninguém lê nem escreve as tabelas direto; tudo passa pelas funções abaixo.
-- Quem tem só o código da sessão lê e manda pergunta; quem tem a chave (QR) controla.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.sessions (
  id          text primary key,
  key_hash    text not null,
  state       jsonb not null default '{}'::jsonb,
  logs        jsonb not null default '{}'::jsonb,
  questions   jsonb not null default '[]'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.sessions enable row level security;
revoke all on public.sessions from anon, authenticated;

create or replace function public._key_ok(p_id text, p_key text)
returns boolean language sql stable security definer set search_path = public, extensions as $$
  select exists (
    select 1 from sessions
    where id = upper(p_id)
      and key_hash = encode(digest(coalesce(p_key, ''), 'sha256'), 'hex')
  );
$$;
revoke all on function public._key_ok(text, text) from public, anon, authenticated;

create or replace function public.create_session()
returns jsonb language plpgsql volatile security definer set search_path = public, extensions as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_id  text;
  v_key text := encode(gen_random_bytes(18), 'hex');
  i int;
begin
  loop
    v_id := '';
    for i in 1..6 loop
      v_id := v_id || substr(alphabet, 1 + (get_byte(gen_random_bytes(1), 0) % length(alphabet)), 1);
    end loop;
    exit when not exists (select 1 from sessions where id = v_id);
  end loop;
  insert into sessions (id, key_hash) values (v_id, encode(digest(v_key, 'sha256'), 'hex'));
  return jsonb_build_object('id', v_id, 'key', v_key);
end;
$$;

create or replace function public.get_session(p_id text)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object('id', id, 'state', state, 'logs', logs, 'questions', questions,
                            'updated_at', extract(epoch from updated_at) * 1000)
  from sessions where id = upper(p_id);
$$;

create or replace function public.check_key(p_id text, p_key text)
returns boolean language sql stable security definer set search_path = public as $$
  select _key_ok(p_id, p_key);
$$;

create or replace function public.server_now()
returns double precision language sql stable as $$
  select extract(epoch from clock_timestamp()) * 1000;
$$;

create or replace function public.save_state(p_id text, p_key text, p_state jsonb)
returns boolean language plpgsql volatile security definer set search_path = public as $$
begin
  if not _key_ok(p_id, p_key) then raise exception 'chave inválida' using errcode = '42501'; end if;
  if jsonb_typeof(p_state) <> 'object' or octet_length(p_state::text) > 200000 then
    raise exception 'estado inválido' using errcode = '22023';
  end if;
  update sessions set state = p_state, updated_at = now() where id = upper(p_id);
  return true;
end;
$$;

-- p_log nulo apaga o registro daquela apresentação
create or replace function public.save_log(p_id text, p_key text, p_log_id text, p_log jsonb)
returns boolean language plpgsql volatile security definer set search_path = public as $$
begin
  if not _key_ok(p_id, p_key) then raise exception 'chave inválida' using errcode = '42501'; end if;
  if p_log_id is null or length(p_log_id) > 64 then raise exception 'id inválido' using errcode = '22023'; end if;
  if p_log is null then
    update sessions set logs = logs - p_log_id, updated_at = now() where id = upper(p_id);
  else
    if octet_length(p_log::text) > 4000 then raise exception 'registro grande demais' using errcode = '22023'; end if;
    update sessions set logs = logs || jsonb_build_object(p_log_id, p_log), updated_at = now() where id = upper(p_id);
  end if;
  return true;
end;
$$;

-- qualquer pessoa com o código da sessão pode mandar pergunta; guarda as 200 mais recentes
create or replace function public.add_question(p_id text, p_text text, p_name text)
returns boolean language plpgsql volatile security definer set search_path = public, extensions as $$
declare
  v_text text := left(btrim(coalesce(p_text, '')), 400);
  v_q jsonb;
begin
  if v_text = '' then raise exception 'pergunta vazia' using errcode = '22023'; end if;
  v_q := jsonb_build_object('id', encode(gen_random_bytes(5), 'hex'), 'text', v_text,
                            'name', left(btrim(coalesce(p_name, '')), 60),
                            'at', extract(epoch from now()) * 1000);
  update sessions
     set questions = (select coalesce(jsonb_agg(q order by ord), '[]'::jsonb)
                        from (select q, ord from jsonb_array_elements(questions || jsonb_build_array(v_q)) with ordinality as t(q, ord)
                              order by ord desc limit 200) last200),
         updated_at = now()
   where id = upper(p_id);
  return found;
end;
$$;

create or replace function public.delete_question(p_id text, p_key text, p_qid text)
returns boolean language plpgsql volatile security definer set search_path = public as $$
begin
  if not _key_ok(p_id, p_key) then raise exception 'chave inválida' using errcode = '42501'; end if;
  update sessions
     set questions = (select coalesce(jsonb_agg(q), '[]'::jsonb) from jsonb_array_elements(questions) q where q->>'id' <> p_qid),
         updated_at = now()
   where id = upper(p_id);
  return true;
end;
$$;

grant execute on function public.create_session(), public.get_session(text), public.check_key(text, text),
  public.server_now(), public.save_state(text, text, jsonb), public.save_log(text, text, text, jsonb),
  public.add_question(text, text, text), public.delete_question(text, text, text)
  to anon, authenticated;
