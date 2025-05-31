-- Create the RPC function for user registration with referral
create or replace function public.register_user_with_referral(
  id uuid,
  email text,
  password text,
  name text,
  phone_number text,
  referral_code text,
  referred_code text default null
) returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  referred_by_id uuid;
begin
  -- Prevent duplicates
  if exists (select 1 from public.users where id = id) then
    raise exception 'User already exists.';
  end if;

  -- Referral logic
  if referred_code is not null then
    select u.id into referred_by_id
    from public.users u
    where lower(trim(u.referral_code)) = lower(trim(referred_code))
    limit 1;

    if referred_by_id is not null then
      update public.users
      set referral_count = referral_count + 1
      where id = referred_by_id;
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
    id,
    email,
    password,
    name,
    phone_number,
    referral_code,
    referred_by_id,
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