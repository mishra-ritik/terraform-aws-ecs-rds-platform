-- seed.sql
-- Generates realistic sample data:
--   * 200 hotel bookings
--   * 5 organizations, 8 cities, 4 statuses
--   * created_at spread over the last 60 days (so the "last 30 days" query
--     returns a meaningful subset, not everything)
--   * booking_events for roughly every 3rd booking (1-3 events each)
--
-- Idempotent-ish: safe to re-run only against a fresh DB. On the compose
-- setup it runs once at first init.

-- Fixed org UUIDs so data is stable/repeatable across seeds.
WITH orgs AS (
    SELECT * FROM (VALUES
        ('11111111-1111-1111-1111-111111111111'::uuid),
        ('22222222-2222-2222-2222-222222222222'::uuid),
        ('33333333-3333-3333-3333-333333333333'::uuid),
        ('44444444-4444-4444-4444-444444444444'::uuid),
        ('55555555-5555-5555-5555-555555555555'::uuid)
    ) AS t(org_id)
),
cities AS (
    SELECT * FROM (VALUES
        ('delhi'), ('mumbai'), ('bangalore'), ('chennai'),
        ('kolkata'), ('hyderabad'), ('pune'), ('jaipur')
    ) AS t(city)
),
statuses AS (
    SELECT * FROM (VALUES
        ('confirmed'), ('pending'), ('cancelled'), ('completed')
    ) AS t(status)
),
nums AS (
    SELECT g AS n FROM generate_series(1, 200) AS g
)
INSERT INTO hotel_bookings
    (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
SELECT
    gen_random_uuid(),
    -- deterministic spread across the 5 orgs / 8 cities / 4 statuses
    (SELECT org_id FROM orgs  OFFSET (n % 5) LIMIT 1),
    'hotel-' || lpad(((n % 40) + 1)::text, 3, '0'),
    (SELECT city   FROM cities  OFFSET (n % 8) LIMIT 1),
    (CURRENT_DATE + ((n % 20))::int),
    (CURRENT_DATE + ((n % 20) + 2)::int),
    round((1500 + (n * 37 % 8500))::numeric, 2),
    (SELECT status FROM statuses OFFSET (n % 4) LIMIT 1),
    -- spread creation over the last 60 days
    (now() - ((n % 60) || ' days')::interval)
FROM nums;

-- Booking events: attach 1-3 events to every 3rd booking.
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT
    b.id,
    e.event_type,
    jsonb_build_object(
        'source', 'seed',
        'amount', b.amount,
        'city', b.city
    ),
    b.created_at + (e.offset_min || ' minutes')::interval
FROM (
    SELECT id, amount, city, created_at,
           row_number() OVER (ORDER BY created_at) AS rn
    FROM hotel_bookings
) b
CROSS JOIN LATERAL (
    SELECT * FROM (VALUES
        ('created',       1),
        ('payment_made', 15),
        ('confirmed',    30)
    ) AS t(event_type, offset_min)
) e
WHERE b.rn % 3 = 0;

-- Quick sanity output at seed time.
DO $$
DECLARE
    b_count int;
    e_count int;
BEGIN
    SELECT count(*) INTO b_count FROM hotel_bookings;
    SELECT count(*) INTO e_count FROM booking_events;
    RAISE NOTICE 'Seed complete: % hotel_bookings, % booking_events', b_count, e_count;
END $$;
