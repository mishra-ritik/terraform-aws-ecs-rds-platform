-- 002_indexes.sql
-- Index to optimize the reporting query:
--
--   SELECT org_id, status, COUNT(*), SUM(amount)
--   FROM hotel_bookings
--   WHERE city = 'delhi'
--     AND created_at >= NOW() - INTERVAL '30 days'
--   GROUP BY org_id, status;
--
-- Design (see README "Query optimization" for the full rationale):
--   * Leading column  = city       -> equality predicate, most selective filter
--   * Second column   = created_at -> range predicate, works as leading col's tie-break
--   * INCLUDE columns = org_id, status, amount
--       carried in the leaf pages so PostgreSQL can satisfy the whole query
--       (filter + group + sum) from the index alone -> index-only scan, no heap hits.

CREATE INDEX IF NOT EXISTS idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);

-- Supports foreign-key joins / lookups of events by their booking.
CREATE INDEX IF NOT EXISTS idx_booking_events_booking_id
    ON booking_events (booking_id);
