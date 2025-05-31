# 🚀 CashSify – Production Specification

## 🎯 App Purpose

**CashSify** is a reward-based mobile app where users earn real money by watching rewarded ads. CAPTCHA verification ensures human activity. The app is built for **fair, fraud-resistant earning**, mainly targeting **students and part-time users in India & Southeast Asia**.

---

## 🧑‍💻 Target Audience

* College students
* Gig economy participants
* Reward-seeking users in India & SEA
* Users comfortable with digital wallets like UPI

---

## 💼 Business Model

* Revenue via AdMob (Bidding Ads, Also Prevent "No Ads Available")
* Controlled rewards per user to maintain profitability
* Referral-driven growth engine

---

## ⚙️ Tech Stack

### 🔹 Frontend (Flutter)

* **Flutter 3.32.1**, **Riverpod + Hooks**
* Modular architecture with centralized shared files
* Clean UI inspired by **Profile Screen theme**
* **Responsive UI for all mobile screen sizes both Android & iOS**
* Key packages:

  * `flutter_riverpod`, `go_router`, `flutter_hooks`
  * `google_fonts`, `lottie`, `cached_network_image`
  * `flutter_launcher_icons`, `flutter_native_splash`

### 🔹 Backend (Supabase)

* **Supabase Auth** (Email/Password)
* **Supabase Postgres** DB
* **Supabase RPCs** (PL/pgSQL) for all business logic
* **Supabase Storage** (for profile pictures)
* **Supabase Cron Jobs** (reset limits, cleanup)
* **Row-Level Security (RLS)** enabled
* **Realtime** for live coin updates

---

## 📱 App Structure

### 1. **Onboarding Screen**

* Swipeable intro slides (3–4 screens)
* Explains app purpose + rules
* CTA: Register / Login

---

### 2. **Auth Screens**

* **Register**: Email, Password, Referral Code (optional)
* **Login**: Email & Password
* **Forgot Password**
* Supabase Auth integration
* On successful registration, referral tracking begins

---

### 3. **Dashboard**

* Shows:

  * Current Coin Balance
  * Ads Watched Today (progress: e.g., 14/20)
  * CTA: “Watch Ad”
* Referral Banner
* Optional: Referral bonus reminder

---

### 4. **Watch Ads**

* Shows rewarded ad (AdMob)
* Upon completion → **Redirect to CAPTCHA Screen**

---

### 5. **CAPTCHA Screen**

* String CAPTCHA (e.g., `fn2DkG`)
* Max 3 attempts
* Retry until passed
* On success:

  * Update in `Supabase Table by RPC`
  * Reward coins (only of 20/20 completed)

---

### 6. **Earnings Screen**

* Show:

  * Total coins earned
  * Daily/weekly/monthly filters
  * All transactions log
* Filter types: Ads / Referrals / Withdrawals

---

### 7. **Referrals Screen**

* Shows user referral code
* Button to copy/share
* Referral tree list
* Bonus phases:

  * Phase 1: A refers B → both get **500 coins**
  * Phase 2: B watches 1 ad → both get **+500 coins**
  * Phase 3: B withdraws → A gets **+500 coins**
* Backend triggers these rewards via RPC

---

### 8. **Withdrawals Screen**

* Coin : 15,000 coins = min withdrawal
* Input: **UPI ID**
* Status: pending / approved / rejected
* Admin approval handled via dashboard

---

### 9. **Profile Screen**

* Profile image, name, email
* UPI update
* Dark mode toggle
* Logout
* **Theme selector** (applies app-wide)
* Terms & Conditions, Privacy Policy, Contact Us, FAQ (can be stored in Supabase table)

---


## 🧑‍💻 Admin Dashboard (Web / Supabase Studio)

* **User Management**: Search, ban, view history
* **Analytics**:

  * Ads watched today
  * CAPTCHA pass/fail rates
  * Referral tree tracking
* **Withdrawal Requests**: View, approve/reject
* **Manual Actions**: Inject coins, reset attempts
* **Realtime logs**: (optional for live view)

---

### 🔐 Security & Fraud Protection

* CAPTCHA after every ad
* Max 3 tries per CAPTCHA, 5-minute expiry
* Limit: 20 ads/day
* RLS policies on all tables
* Rate-limiting for ad watching
* All updates wrapped in **transactions**
* CAPTCHA marked `is_used = true` after usage

---

## 🔁 Daily Flow

| Time         | Action                                     |
| ------------ | ------------------------------------------ |
| Anytime      | User watches ad + solves CAPTCHA           |
| After 30s    | Coins credited → logs inserted             |
| After 20 ads | Blocked for the day                        |
| Midnight     | Reset daily ad count via Supabase cron job |

---

## ⚙️ Backend Logic (RPC & Cron Jobs)

* `process_ad_watch()` – validates CAPTCHA + update in Supabase Table
* `reward_referral()` – handles all 3 referral phases
* `process_withdrawal()` – logs and manages withdrawals
* `cleanup_expired_captchas()` – deletes expired/used CAPTCHAs
* **Use `on conflict`** logic to avoid duplication
* **Use batch insert/update** where necessary

---

## 💨 Performance Notes

* Only **select necessary fields** in queries
* Centralized service and model files
* All logic centralized in Supabase RPCs
* Use `for update` row locking for consistency
* Indexed queries for all heavy-read tables
* Realtime updates for dashboards

---



---

## 🗄️ Supabase Backend – Final Schema, RPCs, and RLS (May 2025 Version)

---

### 🧩 Tables Schema

---

#### 1. `users`

| Column               | Type      | Description                                    |
| -------------------- | --------- | ---------------------------------------------- |
| `id`                 | uuid      | PK – Matches Supabase Auth UID                 |
| `email`              | text      | From Supabase Auth                             |
| `password`           | text      | Hashed password (optional, for tracking)       |
| `name`               | text      | User's full name                               |
| `phone_number`       | text      | Optional                                       |
| `coins`              | int       | Current coin balance                           |
| `referral_code`      | text      | Unique code assigned to each user              |
| `referral_count`     | int       | How many users they referred                   |
| `referred_by`        | uuid      | public.user(id) on delete set null                  |
| `upi_id`             | text      | Optional                                       |
| `bank_account`       | jsonb     | `{ "account_no": "", "ifsc": "", "name": "" }` |
| `is_verified`        | bool      | Manual or email verified                       |
| `profile_image_url`  | text      | Optional profile pic                           |
| `profile_updated_at` | timestamp | Last updated profile info                      |
| `last_login`         | timestamp | Last login timestamp                           |
| `created_at`         | timestamp | Default: now()                                 |

---

#### 2. `ads_watched`

Tracks every successful ad watch (after CAPTCHA pass).

| Column         | Type      | Description                 |
| -------------- | --------- | --------------------------- |
| `id`           | uuid      | Primary Key                 |
| `user_id`      | uuid      | FK to `users.id`            |
| `watched_at`   | timestamp | When ad was watched         |
| `captcha_code` | text      | CAPTCHA value shown to user |

---

#### 3. `earnings`

1 row per user. Tracks daily ad watch count for limiting 20/day.

| Column         | Type      | Description                      |
| -------------- | --------- | -------------------------------- |
| `user_id`      | uuid      | PK, FK to `users.id`             |
| `date`         | date      | The day this entry refers to     |
| `ads_watched`  | int       | Count for that day (0 to 20 max) |
| `last_updated` | timestamp | Last updated timestamp           |

✅ Use a **composite PK**: `(user_id, date)`

---

#### 4. `transactions`

Central log for all coin changes.

| Column       | Type      | Description                       |
| ------------ | --------- | --------------------------------- |
| `id`         | uuid      | Primary Key                       |
| `user_id`    | uuid      | FK to `users.id`                  |
| `type`       | text      | `ad`, `withdrawal`, `bonus`, etc. |
| `amount`     | int       | Positive or negative coin change  |
| `note`       | text      | Optional description              |
| `created_at` | timestamp | Default: now()                    |

---

#### 5. `withdrawals`

Supports UPI or Bank transfer.

| Column         | Type      | Description                       |
| -------------- | --------- | --------------------------------- |
| `id`           | uuid      | Primary Key                       |
| `user_id`      | uuid      | FK to `users.id`                  |
| `method`       | text      | `upi` or `bank`                   |
| `upi_id`       | text      | Required if method = `upi`        |
| `bank_details` | jsonb     | Required if method = `bank`       |
| `amount`       | int       | Coins withdrawn                   |
| `status`       | text      | `pending`, `approved`, `rejected` |
| `requested_at` | timestamp | When user requested               |
| `processed_at` | timestamp | When admin approved (nullable)    |

---

#### 6. `referral_progress`

| Column         | Type    | Description                            |
| -------------- | ------- | -------------------------------------- |
| `referrer_id`  | uuid    | FK → `users.id` of A                   |
| `referred_id`  | uuid    | FK → `users.id` of B                   |
| `phase_1_done` | bool    | A referred B (at signup)               |
| `phase_2_done` | bool    | B watched 1st ad                       |
| `phase_3_done` | bool    | B made 1st withdrawal                  |
| `created_at`   | timest. | When referral was initiated            |
| `updated_at`   | timest. | Last updated (phase completion change) |

---

### 🧠 RPC Functions

#### ✅ `process_ad_watch(user_id uuid, captcha_input text)`

* Checks if user watched < 20 ads today.
* Validates CAPTCHA input (random string logic, can be preloaded client-side).
* Inserts row into `ads_watched`.
* Updates `earnings.ads_watched` for today.
* Adds coins to `users.coins`.
* Logs transaction.

#### 💸 `process_withdrawal(user_id uuid, method text, upi_id text, bank_details jsonb)`

* Verifies minimum 15,000 coins.
* Deducts coins.
* Inserts into `withdrawals`.
* Logs transaction.

#### 🔄 `reset_daily_earnings()`

* Optional: Clean up `earnings` older than X days.
* Can use for analytics, or just rely on date grouping via queries.

---

### 🔐 Row-Level Security (RLS)

#### `users`

* ✅ `SELECT/UPDATE` only where `auth.uid() = id`.
* 🔐 Admins via `role = 'service_role'` can access all.

#### `ads_watched`, `earnings`, `transactions`, `withdrawals`

* ✅ Users can only `SELECT/INSERT` on their own `user_id`.
* ❌ No direct `UPDATE/DELETE`; only done via RPC.

---

### ⚙️ Performance Best Practices

* ✅ Index `ads_watched(user_id, watched_at)`
* ✅ Index `earnings(user_id, date)`
* ✅ Index `transactions(user_id, created_at)`
* ✅ Use `FOR UPDATE` in coin RPCs to prevent double rewards
* ✅ All coin-modifying actions inside RPCs
* ✅ Use `ON CONFLICT` for upserts (e.g., earnings)

---

### ❓ CAPTCHA Flow (String-Based)

Since you’re using **random string CAPTCHA**, no table needed.

**Flow:**

1. Frontend fetches random CAPTCHA image+string from CDN/local.
2. After ad → show CAPTCHA → user enters input.
3. On submit, call `process_ad_watch()` with `captcha_input`.
4. If input matches, reward and log.

---

## ✅ FINAL STRUCTURE

* `users`
* `ads_watched`
* `earnings`
* `transactions`
* `withdrawals`
* 🔥 All logic in 2 core RPCs: `process_ad_watch`, `process_withdrawal`
* 🔐 RLS enabled + role-safe architecture

---
