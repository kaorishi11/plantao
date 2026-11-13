-- PlantãoPS: esquema inicial. Execute no SQL Editor do Supabase.
create extension if not exists pgcrypto;

create type public.user_role as enum ('recepcao','enfermagem','medico','gestao','painel');
create type public.encounter_status as enum (
  'aguardando_triagem','aguardando_medico','em_atendimento',
  'aguardando_leito','em_observacao','alta','transferido','cancelado'
);
create type public.risk_color as enum ('vermelho','laranja','amarelo','verde','azul');
create type public.bed_status as enum ('livre','ocupado','em_limpeza','bloqueado');
create type public.patient_sex as enum ('feminino','masculino','outro','nao_informado');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role public.user_role not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.patients (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  birth_date date not null,
  sex public.patient_sex not null default 'nao_informado',
  phone text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index patients_name_idx on public.patients using gin (to_tsvector('portuguese', full_name));
create index patients_birth_date_idx on public.patients(birth_date);

create table public.patient_allergies (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  allergen text not null,
  notes text,
  created_at timestamptz not null default now(),
  unique(patient_id, allergen)
);

create table public.encounters (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id),
  daily_ticket text not null,
  ticket_date date not null default (now() at time zone 'America/Sao_Paulo')::date,
  status public.encounter_status not null default 'aguardando_triagem',
  arrived_at timestamptz not null default now(),
  triage_at timestamptz,
  called_at timestamptz,
  started_at timestamptz,
  finished_at timestamptz,
  assigned_doctor uuid references public.profiles(id),
  destination text check (destination in ('alta','observacao','internacao','transferencia')),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(ticket_date, daily_ticket)
);
create index encounters_status_arrival_idx on public.encounters(status, arrived_at);
create unique index one_active_encounter_per_patient on public.encounters(patient_id)
where status in ('aguardando_triagem','aguardando_medico','em_atendimento','aguardando_leito','em_observacao');

create table public.triages (
  id uuid primary key default gen_random_uuid(),
  encounter_id uuid not null references public.encounters(id) on delete cascade,
  systolic_bp integer,
  diastolic_bp integer,
  heart_rate integer,
  temperature numeric(4,1),
  oxygen_saturation numeric(5,2),
  pain_level integer not null check (pain_level between 0 and 10),
  consciousness text not null check (consciousness in ('alerta','confuso','inconsciente')),
  chief_complaint text not null,
  suggested_color public.risk_color not null,
  final_color public.risk_color not null,
  override_reason text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  check (suggested_color = final_color or length(trim(coalesce(override_reason,''))) > 0)
);
create index triages_encounter_created_idx on public.triages(encounter_id, created_at desc);

create table public.encounter_events (
  id uuid primary key default gen_random_uuid(),
  encounter_id uuid not null references public.encounters(id) on delete cascade,
  from_status public.encounter_status,
  to_status public.encounter_status not null,
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.medications (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  max_dose numeric(12,3) not null check (max_dose > 0),
  dose_unit text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.prescriptions (
  id uuid primary key default gen_random_uuid(),
  encounter_id uuid not null references public.encounters(id) on delete cascade,
  medication_id uuid not null references public.medications(id),
  dose numeric(12,3) not null check (dose > 0),
  route text not null,
  frequency text not null,
  instructions text,
  prescribed_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.beds (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  ward text not null,
  status public.bed_status not null default 'livre',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.bed_assignments (
  id uuid primary key default gen_random_uuid(),
  bed_id uuid not null references public.beds(id),
  encounter_id uuid not null references public.encounters(id),
  admitted_at timestamptz not null default now(),
  released_at timestamptz,
  assigned_by uuid references public.profiles(id)
);
create unique index one_open_assignment_per_bed on public.bed_assignments(bed_id) where released_at is null;
create unique index one_open_bed_per_encounter on public.bed_assignments(encounter_id) where released_at is null;

create table public.calls (
  id uuid primary key default gen_random_uuid(),
  encounter_id uuid not null references public.encounters(id),
  daily_ticket text not null,
  room text not null,
  called_by uuid not null references public.profiles(id),
  called_at timestamptz not null default now()
);

-- Perfil criado automaticamente após signup. A role deve ser definida por administrador.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)), 'recepcao');
  return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Impede transições de estado fora do fluxo definido no requisito.
create or replace function public.validate_encounter_transition()
returns trigger language plpgsql as $$
begin
  if new.status = old.status then return new; end if;
  if not (
    (old.status = 'aguardando_triagem' and new.status in ('aguardando_medico','cancelado')) or
    (old.status = 'aguardando_medico' and new.status in ('em_atendimento','cancelado')) or
    (old.status = 'em_atendimento' and new.status in ('alta','aguardando_leito','transferido')) or
    (old.status = 'aguardando_leito' and new.status = 'em_observacao') or
    (old.status = 'em_observacao' and new.status in ('alta','transferido'))
  ) then
    raise exception 'Transição de atendimento não permitida: % -> %', old.status, new.status;
  end if;
  return new;
end;
$$;
create trigger encounters_transition_guard before update of status on public.encounters
for each row execute function public.validate_encounter_transition();

create or replace function public.log_encounter_status()
returns trigger language plpgsql as $$
begin
  if old.status is distinct from new.status then
    insert into public.encounter_events(encounter_id,from_status,to_status,created_by)
    values(new.id,old.status,new.status,auth.uid());
  end if;
  return new;
end;
$$;
create trigger encounters_status_event after update of status on public.encounters
for each row execute function public.log_encounter_status();

-- Gera senha diária com bloqueio transacional via advisory lock.
create or replace function public.open_encounter(p_patient_id uuid)
returns public.encounters
language plpgsql security definer set search_path = public
as $$
declare
  v_date date := (now() at time zone 'America/Sao_Paulo')::date;
  v_count integer;
  v_encounter public.encounters;
begin
  if not public.has_any_role(array['recepcao']::public.user_role[]) then raise exception 'Acesso negado'; end if;
  perform pg_advisory_xact_lock(hashtext('plantao-ticket-' || v_date::text));
  if exists (
    select 1 from public.encounters
    where patient_id = p_patient_id
      and status in ('aguardando_triagem','aguardando_medico','em_atendimento','aguardando_leito','em_observacao')
  ) then raise exception 'Paciente já possui atendimento ativo'; end if;

  select count(*) + 1 into v_count from public.encounters where ticket_date = v_date;
  insert into public.encounters(patient_id,daily_ticket,ticket_date,created_by)
  values(p_patient_id, 'A' || lpad(v_count::text,3,'0'), v_date, auth.uid())
  returning * into v_encounter;
  insert into public.encounter_events(encounter_id,from_status,to_status,created_by)
  values(v_encounter.id,null,'aguardando_triagem',auth.uid());
  return v_encounter;
end;
$$;

create or replace function public.has_any_role(allowed public.user_role[])
returns boolean language sql stable security definer set search_path = public
as $$
  select exists(select 1 from public.profiles where id = auth.uid() and active and role = any(allowed));
$$;

-- Chama o próximo paciente com lock de linha: médicos concorrentes recebem pacientes distintos.
create or replace function public.call_next_patient(p_room text)
returns public.encounters
language plpgsql security definer set search_path = public
as $$
declare
  v_enc public.encounters;
  v_triage public.triages;
begin
  if not public.has_any_role(array['medico']::public.user_role[]) then raise exception 'Acesso negado'; end if;
  select e.* into v_enc
  from public.encounters e
  join lateral (
    select t.* from public.triages t where t.encounter_id=e.id order by t.created_at desc limit 1
  ) t on true
  where e.status='aguardando_medico'
  order by
    case t.final_color when 'vermelho' then 1 when 'laranja' then 2 when 'amarelo' then 3 when 'verde' then 4 else 5 end,
    e.arrived_at asc,
    case when date_part('year',age(current_date,(select birth_date from public.patients p where p.id=e.patient_id))) >= 60
      or date_part('year',age(current_date,(select birth_date from public.patients p where p.id=e.patient_id))) < 12 then 0 else 1 end
  for update of e skip locked limit 1;

  if v_enc.id is null then raise exception 'Não há pacientes aguardando atendimento'; end if;
  update public.encounters set status='em_atendimento', assigned_doctor=auth.uid(), called_at=now(), started_at=now()
  where id=v_enc.id returning * into v_enc;
  insert into public.calls(encounter_id,daily_ticket,room,called_by)
  values(v_enc.id,v_enc.daily_ticket,p_room,auth.uid());
  return v_enc;
end;
$$;

-- Ocupação atômica do leito.
create or replace function public.assign_bed(p_bed_id uuid, p_encounter_id uuid)
returns public.bed_assignments
language plpgsql security definer set search_path = public
as $$
declare v_assignment public.bed_assignments;
begin
  if not public.has_any_role(array['enfermagem']::public.user_role[]) then raise exception 'Acesso negado'; end if;
  perform 1 from public.beds where id=p_bed_id and status='livre' and active for update;
  if not found then raise exception 'Leito não está disponível'; end if;
  if not exists(select 1 from public.encounters where id=p_encounter_id and status='aguardando_leito') then
    raise exception 'Paciente não está aguardando leito';
  end if;
  update public.beds set status='ocupado' where id=p_bed_id;
  insert into public.bed_assignments(bed_id,encounter_id,assigned_by)
  values(p_bed_id,p_encounter_id,auth.uid()) returning * into v_assignment;
  update public.encounters set status='em_observacao' where id=p_encounter_id;
  return v_assignment;
end;
$$;

-- Ao dar alta/transferir, libera ocupação e envia leito para limpeza.
create or replace function public.release_bed_on_terminal_status()
returns trigger language plpgsql as $$
begin
  if new.status in ('alta','transferido') and old.status is distinct from new.status then
    update public.bed_assignments set released_at=now()
      where encounter_id=new.id and released_at is null;
    update public.beds b set status='em_limpeza'
      where exists(select 1 from public.bed_assignments ba where ba.bed_id=b.id and ba.encounter_id=new.id);
  end if;
  return new;
end;
$$;
create trigger encounters_release_bed after update of status on public.encounters
for each row execute function public.release_bed_on_terminal_status();

create or replace function public.mark_bed_clean(p_bed_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if not public.has_any_role(array['enfermagem']::public.user_role[]) then raise exception 'Acesso negado'; end if;
  update public.beds set status='livre' where id=p_bed_id and status='em_limpeza';
  if not found then raise exception 'Leito não está em limpeza'; end if;
end;
$$;

-- RLS
alter table public.profiles enable row level security;
alter table public.patients enable row level security;
alter table public.patient_allergies enable row level security;
alter table public.encounters enable row level security;
alter table public.triages enable row level security;
alter table public.encounter_events enable row level security;
alter table public.medications enable row level security;
alter table public.prescriptions enable row level security;
alter table public.beds enable row level security;
alter table public.bed_assignments enable row level security;
alter table public.calls enable row level security;

create policy "profile self or management read" on public.profiles for select to authenticated
using (id=auth.uid() or public.has_any_role(array['gestao']::public.user_role[]));
create policy "profiles management update" on public.profiles for update to authenticated
using (public.has_any_role(array['gestao']::public.user_role[])) with check (public.has_any_role(array['gestao']::public.user_role[]));

create policy "authorized staff read patients" on public.patients for select to authenticated
using (public.has_any_role(array['recepcao','enfermagem','medico','gestao']::public.user_role[]));
create policy "reception creates patients" on public.patients for insert to authenticated
with check (public.has_any_role(array['recepcao']::public.user_role[]));
create policy "reception updates patients" on public.patients for update to authenticated
using (public.has_any_role(array['recepcao']::public.user_role[])) with check (public.has_any_role(array['recepcao']::public.user_role[]));

create policy "authorized allergy read" on public.patient_allergies for select to authenticated
using (public.has_any_role(array['recepcao','enfermagem','medico','gestao']::public.user_role[]));
create policy "reception allergy write" on public.patient_allergies for all to authenticated
using (public.has_any_role(array['recepcao']::public.user_role[])) with check (public.has_any_role(array['recepcao']::public.user_role[]));

create policy "staff encounter read" on public.encounters for select to authenticated
using (public.has_any_role(array['recepcao','enfermagem','medico','gestao']::public.user_role[]));
create policy "reception encounter insert via rpc" on public.encounters for insert to authenticated
with check (false);
create policy "clinical staff encounter update" on public.encounters for update to authenticated
using (public.has_any_role(array['enfermagem','medico']::public.user_role[])) with check (public.has_any_role(array['enfermagem','medico']::public.user_role[]));

create policy "staff triage read" on public.triages for select to authenticated
using (public.has_any_role(array['enfermagem','medico','gestao']::public.user_role[]));
create policy "nursing triage insert" on public.triages for insert to authenticated
with check (public.has_any_role(array['enfermagem']::public.user_role[]) and created_by=auth.uid());

create policy "staff event read" on public.encounter_events for select to authenticated
using (public.has_any_role(array['recepcao','enfermagem','medico','gestao']::public.user_role[]));
create policy "staff medication read" on public.medications for select to authenticated
using (public.has_any_role(array['medico','gestao']::public.user_role[]));
create policy "doctor prescription read" on public.prescriptions for select to authenticated
using (public.has_any_role(array['medico','gestao']::public.user_role[]));
create policy "doctor prescription insert" on public.prescriptions for insert to authenticated
with check (public.has_any_role(array['medico']::public.user_role[]) and prescribed_by=auth.uid());

create policy "staff beds read" on public.beds for select to authenticated
using (public.has_any_role(array['enfermagem','gestao']::public.user_role[]));
create policy "staff assignments read" on public.bed_assignments for select to authenticated
using (public.has_any_role(array['enfermagem','gestao']::public.user_role[]));
create policy "nursing bed updates" on public.beds for update to authenticated
using (public.has_any_role(array['enfermagem']::public.user_role[])) with check (public.has_any_role(array['enfermagem']::public.user_role[]));

create policy "authenticated calls read" on public.calls for select to authenticated using (true);
create policy "public call display read" on public.calls for select to anon using (true);

grant execute on function public.open_encounter(uuid) to authenticated;
grant execute on function public.call_next_patient(text) to authenticated;
grant execute on function public.assign_bed(uuid,uuid) to authenticated;
grant execute on function public.mark_bed_clean(uuid) to authenticated;
