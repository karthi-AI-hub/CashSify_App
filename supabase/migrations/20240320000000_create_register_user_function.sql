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