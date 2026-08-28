-- School Fee Tracker — initial schema
-- Mirrors the app's in-browser data model (DEFAULT_STATE in index.html)
-- so existing localStorage data can be migrated 1:1 by id.

create table if not exists school (
  id text primary key default 'default',
  name text not null default '',
  address text not null default '',
  phone text not null default '',
  logo_text text not null default ''
);

create table if not exists settings (
  id text primary key default 'default',
  sibling_discount_enabled boolean not null default true,
  sibling_discount_type text not null default 'percent',
  sibling_discount_value numeric not null default 0,
  sibling_discount_applies_to text not null default 'all',
  day_care_rate numeric not null default 0
);

create table if not exists academic_years (
  id text primary key,
  label text not null,
  start_date date not null,
  end_date date not null,
  status text not null default 'active'
);

create table if not exists classes (
  id text primary key,
  name text not null,
  academic_fee numeric not null default 0
);

create table if not exists routes (
  id text primary key,
  name text not null,
  amount numeric not null default 0,
  billing_frequency text not null default 'monthly'
);

create table if not exists eca_activities (
  id text primary key,
  name text not null,
  amount numeric not null default 0,
  billing_frequency text not null default 'monthly'
);

create table if not exists students (
  id text primary key,
  name text not null,
  class_id text references classes(id) on delete set null,
  parent_name text not null default '',
  parent_phone text not null default '',
  family_id text not null default '',
  van_route_id text references routes(id) on delete set null,
  van_fee_override numeric,
  eca_ids text[] not null default '{}',
  archived boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists invoices (
  id text primary key,
  student_id text references students(id) on delete cascade,
  year_id text references academic_years(id) on delete set null,
  month text not null,
  items jsonb not null default '[]',
  discount_amount numeric not null default 0,
  total_amount numeric not null default 0,
  paid_amount numeric not null default 0,
  status text not null default 'unpaid',
  created_at timestamptz not null default now()
);

create table if not exists payments (
  id text primary key,
  invoice_id text references invoices(id) on delete cascade,
  student_id text references students(id) on delete cascade,
  amount numeric not null default 0,
  mode text not null default 'Cash',
  date date not null,
  receipt_no text not null,
  created_at timestamptz not null default now()
);

create table if not exists day_care_logs (
  id text primary key,
  student_id text references students(id) on delete cascade,
  date date not null,
  check_in text,
  check_out text,
  hours numeric not null default 0,
  rate numeric not null default 0,
  amount numeric not null default 0,
  invoiced boolean not null default false,
  invoice_id text references invoices(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists receipt_counters (
  year text primary key,
  count integer not null default 0
);

create table if not exists audit_log (
  id text primary key,
  user_name text not null default 'system',
  action text not null,
  details jsonb,
  timestamp timestamptz not null default now()
);

create index if not exists idx_students_class on students(class_id);
create index if not exists idx_students_family on students(family_id);
create index if not exists idx_invoices_student on invoices(student_id);
create index if not exists idx_invoices_year_month on invoices(year_id, month);
create index if not exists idx_payments_invoice on payments(invoice_id);
create index if not exists idx_daycare_student on day_care_logs(student_id);

-- RLS: enabled on every table. No auth is wired into the app yet, so for now
-- allow full access to both anon and authenticated roles. Tighten these
-- policies once real user auth is added (e.g. restrict by auth.uid()).
alter table school enable row level security;
alter table settings enable row level security;
alter table academic_years enable row level security;
alter table classes enable row level security;
alter table routes enable row level security;
alter table eca_activities enable row level security;
alter table students enable row level security;
alter table invoices enable row level security;
alter table payments enable row level security;
alter table day_care_logs enable row level security;
alter table receipt_counters enable row level security;
alter table audit_log enable row level security;

do $$
declare
  t text;
begin
  for t in select unnest(array[
    'school','settings','academic_years','classes','routes','eca_activities',
    'students','invoices','payments','day_care_logs','receipt_counters','audit_log'
  ])
  loop
    execute format(
      'create policy "allow_all_%1$s" on %1$s for all using (true) with check (true);', t
    );
  end loop;
end $$;
