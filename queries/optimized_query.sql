-- ==========================================
-- Query to optimize (Part 5 of the assessment)
-- ==========================================
--
-- Reporting query: bookings and revenue per org/status for Delhi in the
-- last 30 days.

SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;

-- ==========================================
-- Supporting index (created in database/init/01-schema.sql)
-- ==========================================
--
-- CREATE INDEX idx_hotel_bookings_city_created_at
--     ON hotel_bookings (city, created_at)
--     INCLUDE (org_id, status, amount);
--
-- Why this index:
--   1. `city` is an equality predicate and `created_at` is a range
--      predicate. B-tree composite indexes should list equality columns
--      before range columns, so (city, created_at) lets PostgreSQL jump
--      straight to the 'delhi' rows and then scan only the portion of
--      that range within the last 30 days, instead of scanning the
--      whole table.
--   2. org_id, status and amount are added with INCLUDE (not as extra
--      key columns) because the query only ever reads them, never
--      filters or sorts on them. INCLUDE keeps the index narrower/faster
--      to maintain while still letting PostgreSQL answer the query
--      entirely from the index (index-only scan) when the visibility
--      map is up to date, avoiding heap fetches for every matching row.
--
-- To verify the plan locally:
--
--   docker exec -it bookingapp-postgres psql -U postgres -d bookingdb \
--     -c "EXPLAIN ANALYZE SELECT org_id, status, COUNT(*), SUM(amount)
--         FROM hotel_bookings
--         WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
--         GROUP BY org_id, status;"
--
-- Before the index: Seq Scan on hotel_bookings, filtering all rows.
-- After the index:  Index Only Scan using idx_hotel_bookings_city_created_at,
--                    Recheck/Filter cost drops sharply since only the
--                    'delhi' + last-30-days slice of the index is read.
