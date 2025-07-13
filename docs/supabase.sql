create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  password text,
  name text not null,
  phone_number text not null,
  gender text,
  dob date,
  coins int default 0,
  referral_code text unique not null,
  referral_count int default 0,
  referred_by uuid references public.users(id) on delete set null,
  upi_id text,
  bank_account jsonb,
  is_verified boolean default false,
  profile_image_url text,
  profile_updated_at timestamp default now(),
  last_login timestamp,
  created_at timestamp default now()
);

-- Enable RLS
alter table public.users enable row level security;

-- Add index for better referral lookups
create index idx_users_referred_by on public.users(referred_by);

-- Create the RPC function for user registration with referral
create or replace function public.register_user_with_referral(
  p_id uuid,
  p_email text,
  p_password text,
  p_name text,
  p_phone_number text,
  p_referral_code text,
  p_referred_code text default null
) returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_referred_by_id uuid;
begin
  -- Prevent duplicates
  if exists (select 1 from public.users where id = p_id) then
    raise exception 'User already exists.';
  end if;

  -- Referral logic
  if p_referred_code is not null then
    select u.id into v_referred_by_id
    from public.users u
    where lower(trim(u.referral_code)) = lower(trim(p_referred_code))
    limit 1;

    if v_referred_by_id is not null then
      update public.users
      set referral_count = referral_count + 1
      where id = v_referred_by_id;
    end if;
  end if;

  -- Insert user
  insert into public.users (
    id,
    email,
    password,
    name,
    phone_number,
    referral_code,
    referred_by,
    created_at,
    profile_updated_at
  ) values (
    p_id,
    p_email,
    p_password,
    p_name,
    p_phone_number,
    p_referral_code,
    v_referred_by_id,
    now(),
    now()
  );
end;
$$;

-- Grant RPC usage
grant execute on function public.register_user_with_referral to authenticated; 

-- RLS policies
create policy "Users can view their own profile"
  on public.users for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.users for update
  using (auth.uid() = id);

create policy "Users can delete their own profile"
  on public.users for delete
  using (auth.uid() = id);

-- Enable RLS
alter table public.users enable row level security; 


-- Drop existing policies if any
drop policy if exists "Users can upload their own profile images" on storage.objects;
drop policy if exists "Users can update their own profile images" on storage.objects;
drop policy if exists "Profile images are publicly accessible" on storage.objects;
drop policy if exists "Users can delete their own profile images" on storage.objects;

-- Create new policies
create policy "Users can upload their own profile images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'profile-images' AND
  name like 'profile_' || auth.uid() || '.%'
);

create policy "Users can update their own profile images"
on storage.objects for update
to authenticated
using (
  bucket_id = 'profile-images' AND
  name like 'profile_' || auth.uid() || '.%'
);

create policy "Profile images are publicly accessible"
on storage.objects for select
to public
using (bucket_id = 'profile-images');

create policy "Users can delete their own profile images"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'profile-images' AND
  name like 'profile_' || auth.uid() || '.%'
);

-- Create the profile-images bucket if it doesn't exist
insert into storage.buckets (id, name, public)
values ('profile-images', 'profile-images', true);

create table if not exists earnings (
  user_id uuid not null references users(id) on delete cascade,
  date date not null,
  ads_watched int not null default 0 check (ads_watched >= 0 and ads_watched <= 20),
  last_updated timestamp with time zone default now(),
  primary key (user_id, date)
);

-- 🔐 Enable RLS
alter table earnings enable row level security;

-- ✅ RLS: Allow select for self
create policy "Select own earnings"
on earnings for select
using (auth.uid() = user_id);

-- ✅ RLS: Allow insert for self
create policy "Insert own earnings"
on earnings for insert
with check (auth.uid() = user_id);

-- ✅ RLS: Allow update for self
create policy "Update own earnings"
on earnings for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);


create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  type text not null check (type in ('ad', 'withdrawal', 'referral', 'bonus')),
  amount int not null,
  note text,
  created_at timestamp with time zone default now()
);

-- 🔐 Enable RLS
alter table transactions enable row level security;

-- ✅ RLS: Allow select for self
create policy "Select own transactions"
on transactions for select
using (auth.uid() = user_id);

-- ✅ RLS: Allow insert for self
create policy "Insert own transactions"
on transactions for insert
with check (auth.uid() = user_id);

create index if not exists idx_earnings_user_date
on earnings(user_id, date);

create index if not exists idx_transactions_user_created
on transactions(user_id, created_at desc);

create or replace function process_ad_watch(p_user_id UUID, captcha_input TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_daily_limit INTEGER := 20;
    v_coins_per_day INTEGER := FLOOR(random() * (520 - 480 + 1))::int + 480;
    v_today_ads INTEGER;
    v_is_20th_ad BOOLEAN := FALSE;
BEGIN
    -- 1. Validate user exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'User not found';
    END IF;
FINER: 2025-06-08 18:05:31.354: Access token expires in 285
ticks
FINE: 2025-06-08 18:05:31.678: Stopping auto refresh
FINE: 2025-06-08 18:05:31.679: Starting auto refresh
FINER: 2025-06-08 18:05:31.730: Access token expires in 285
ticks
FINEST: 2025-06-08 18:05:31.935: Request: POST
https://huohftwbbqvhhqsabmzb.supabase.co/rest/v1/earnings?on
_conflict=user_id%2Cdate&select=%2A
FINEST: 2025-06-08 18:05:31.939: Request: GET
https://huohftwbbqvhhqsabmzb.supabase.co/rest/v1/wallets?sel
ect=%2A&user_id=eq.c7edb362-eff0-4254-bc78-708f3d35acc2     
FINEST: 2025-06-08 18:05:32.532: PostgrestException(message:
relation "public.wallets" does not exist, code: 42P01,      
details: , hint: null) from request:
https://huohftwbbqvhhqsabmzb.supabase.co/rest/v1/wallets?sel
ect=%2A&user_id=eq.c7edb362-eff0-4254-bc78-708f3d35acc2     
FINE: 2025-06-08 18:05:32.532: PostgrestException(message:
relation "public.wallets" does not exist, code: 42P01,      
details: , hint: null) from request


    -- 2. Validate CAPTCHA input (simple check, expand as needed)
    IF captcha_input IS NULL OR length(captcha_input) < 4 THEN
        RAISE EXCEPTION 'Invalid CAPTCHA input';
    END IF

    -- 3. Get today's ad count
    SELECT COALESCE(ads_watched, 0)
      INTO v_today_ads
      FROM earnings
     WHERE user_id = p_user_id
       AND date = CURRENT_DATE;

    -- 4. Block if already at daily limit
    IF v_today_ads >= v_daily_limit THEN
        RAISE EXCEPTION 'Daily ad limit reached';
    END IF;

    -- 5. Insert into ads_watched table
    INSERT INTO ads_watched (id, user_id, watched_at, captcha_code)
    VALUES (gen_random_uuid(), p_user_id, NOW(), captcha_input);

    -- 6. Increment earnings.ads_watched (upsert)
    INSERT INTO earnings (user_id, date, ads_watched, last_updated)
    VALUES (p_user_id, CURRENT_DATE, 1, NOW())
    ON CONFLICT (user_id, date)
    DO UPDATE SET
        ads_watched = earnings.ads_watched + 1,
        last_updated = NOW();

    -- 7. Check if this is the 20th ad
    IF v_today_ads + 1 = v_daily_limit THEN
        v_is_20th_ad := TRUE;
    END IF;

    -- 8. If 20th ad, credit coins and log transaction
    IF v_is_20th_ad THEN
        UPDATE users
           SET coins = coins + v_coins_per_day
         WHERE id = p_user_id;

        INSERT INTO transactions (id, user_id, type, amount, note, created_at)
        VALUES (
            gen_random_uuid(),
            p_user_id,
            'ad',
            v_coins_per_day,
            'Daily ad reward for watching 20 ads',
            NOW()
        );
    END IF;

    RETURN TRUE;
END;
$$;

create table public.ads_watched (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  watched_at timestamp with time zone default now() not null,
  captcha_code text not null
);
alter table public.ads_watched enable row level security;
-- SELECT own records
create policy "Users can view their own ad watch history"
on public.ads_watched
for select
using (auth.uid() = user_id);

-- INSERT only for themselves
create policy "Users can insert their own ad watch record"
on public.ads_watched
for insert
with check (auth.uid() = user_id);
create index ads_watched_user_id_idx on public.ads_watched(user_id);
create index ads_watched_user_time_idx on public.ads_watched(user_id, watched_at);

create table withdrawals (
  id uuid primary key default gen_random_uuid(),

  user_id uuid references users(id) on delete cascade,

  amount int4 not null check (amount > 0), -- in coins or paise
  upi_id text,          -- optional if UPI
  bank_account jsonb,   -- optional if bank transfer

  method text not null check (method in ('upi', 'bank')),
  status text not null default 'pending' check (
    status in ('pending', 'approved', 'rejected', 'processing', 'failed')
  ),

  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  approved_at timestamptz,
  rejected_at timestamptz,

  note text,            -- admin note or rejection reason
  transaction_id uuid references transactions(id) on delete set null
);

-- Enable RLS
alter table withdrawals enable row level security;

-- ✅ Allow users to view their own withdrawal records
create policy "Users can view their withdrawals"
on withdrawals
for select
using (auth.uid() = user_id);

-- ✅ Allow users to request withdrawal
create policy "Users can request withdrawal"
on withdrawals
for insert
with check (auth.uid() = user_id);

-- ⚠️ FIX: Admins should be controlled via service_role outside RLS.
-- service_role bypasses RLS, so this isn't needed unless you're allowing client-side admin roles.
-- If you really need it:
create policy "Admins can update withdrawal status"
on withdrawals
for update
using (auth.role() = 'service_role')
with check (true);

create index idx_withdrawals_user_id on withdrawals(user_id);
create index idx_withdrawals_status on withdrawals(status);
create index idx_withdrawals_requested_at on withdrawals(requested_at);