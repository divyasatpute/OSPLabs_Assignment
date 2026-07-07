-- ==========================================
-- DevOps Assessment - Database Schema
-- PostgreSQL
-- ==========================================

-- Needed for gen_random_uuid() on PostgreSQL < 16.
-- (Harmless no-op on PostgreSQL >= 16, where it's built in.)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-------------------------------------------------
-- hotel_bookings
-------------------------------------------------

CREATE TABLE hotel_bookings (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id         UUID NOT NULL,
    hotel_id       VARCHAR(100) NOT NULL,
    city           VARCHAR(100) NOT NULL,
    checkin_date   DATE NOT NULL,
    checkout_date  DATE NOT NULL,
    amount         NUMERIC(12,2) NOT NULL,
    status         VARCHAR(50) NOT NULL,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-------------------------------------------------
-- booking_events
-------------------------------------------------

CREATE TABLE booking_events (
    id          BIGSERIAL PRIMARY KEY,
    booking_id  UUID NOT NULL REFERENCES hotel_bookings(id) ON DELETE CASCADE,
    event_type  VARCHAR(100) NOT NULL,
    payload     JSONB,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-------------------------------------------------
-- Indexes
-------------------------------------------------

-- Supports FK lookups / joins from booking_events -> hotel_bookings.
CREATE INDEX idx_booking_events_booking_id
    ON booking_events (booking_id);

-- Optimizes the reporting query in queries/optimized_query.sql:
--   SELECT org_id, status, COUNT(*), SUM(amount)
--   FROM hotel_bookings
--   WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
--   GROUP BY org_id, status;
--
-- city is an equality filter and created_at is a range filter, so city
-- leads the composite index (equality columns before range columns is the
-- standard btree rule) followed by created_at. org_id, status and amount
-- are added via INCLUDE so PostgreSQL can satisfy the whole query straight
-- from the index (index-only scan) without touching the heap for matching
-- rows, and the group/aggregate is computed directly off the retrieved
-- index tuples. See README.md "Query Optimization" section for the
-- EXPLAIN ANALYZE comparison.
CREATE INDEX idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);
