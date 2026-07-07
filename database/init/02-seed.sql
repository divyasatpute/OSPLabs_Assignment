-- ==========================================
-- DevOps Assessment - Seed Data
-- Generates 150 hotel_bookings across 8 cities, 6 orgs and 4 statuses,
-- plus booking_events for most of them.
-- ==========================================

DO $$
DECLARE
    cities      TEXT[]  := ARRAY['delhi','mumbai','bengaluru','pune','goa','jaipur','hyderabad','chennai'];
    orgs        UUID[]  := ARRAY[
        '11111111-1111-1111-1111-111111111111'::UUID,
        '22222222-2222-2222-2222-222222222222'::UUID,
        '33333333-3333-3333-3333-333333333333'::UUID,
        '44444444-4444-4444-4444-444444444444'::UUID,
        '55555555-5555-5555-5555-555555555555'::UUID,
        '66666666-6666-6666-6666-666666666666'::UUID
    ];
    statuses    TEXT[]  := ARRAY['CONFIRMED','CANCELLED','COMPLETED','PENDING'];
    payment_methods TEXT[] := ARRAY['CARD','UPI','NETBANKING','WALLET'];

    i           INT;
    v_id        UUID;
    v_city      TEXT;
    v_org       UUID;
    v_status    TEXT;
    v_checkin   DATE;
    v_nights    INT;
    v_amount    NUMERIC(12,2);
    v_created   TIMESTAMP;
BEGIN
    ------------------------------------------------------------------
    -- 1) 150 randomized bookings spread across the last 60 days
    ------------------------------------------------------------------
    FOR i IN 1..150 LOOP
        v_id      := gen_random_uuid();
        v_city    := cities[1 + floor(random() * array_length(cities, 1))::int];
        v_org     := orgs[1 + floor(random() * array_length(orgs, 1))::int];
        v_status  := statuses[1 + floor(random() * array_length(statuses, 1))::int];
        v_nights  := 1 + floor(random() * 5)::int;
        v_checkin := CURRENT_DATE - (floor(random() * 60))::int;
        v_amount  := round((1000 + random() * 15000)::numeric, 2);
        v_created := NOW()
                        - (floor(random() * 60) || ' days')::interval
                        - (floor(random() * 24) || ' hours')::interval;

        INSERT INTO hotel_bookings
            (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
        VALUES
            (v_id, v_org, 'HTL-' || lpad((1 + floor(random() * 25))::int::text, 3, '0'),
             v_city, v_checkin, v_checkin + v_nights, v_amount, v_status, v_created);

        -- ~60% of bookings get a BOOKING_CREATED event
        IF random() < 0.6 THEN
            INSERT INTO booking_events (booking_id, event_type, payload, created_at)
            VALUES (v_id, 'BOOKING_CREATED',
                    jsonb_build_object('status', v_status, 'amount', v_amount, 'city', v_city),
                    v_created);

            -- ~40% of those also get a PAYMENT_PROCESSED event
            IF random() < 0.4 THEN
                INSERT INTO booking_events (booking_id, event_type, payload, created_at)
                VALUES (v_id, 'PAYMENT_PROCESSED',
                        jsonb_build_object('method', payment_methods[1 + floor(random() * array_length(payment_methods, 1))::int]),
                        v_created + interval '10 minutes');
            END IF;

            -- cancelled bookings get a BOOKING_CANCELLED event
            IF v_status = 'CANCELLED' THEN
                INSERT INTO booking_events (booking_id, event_type, payload, created_at)
                VALUES (v_id, 'BOOKING_CANCELLED',
                        jsonb_build_object('reason', 'customer_request'),
                        v_created + interval '1 day');
            END IF;
        END IF;
    END LOOP;

    ------------------------------------------------------------------
    -- 2) Guaranteed rows for city = 'delhi' created within the last
    --    30 days, so the optimized query in queries/optimized_query.sql
    --    always has meaningful data to demonstrate against.
    ------------------------------------------------------------------
    FOR i IN 1..25 LOOP
        v_id      := gen_random_uuid();
        v_org     := orgs[1 + floor(random() * array_length(orgs, 1))::int];
        v_status  := statuses[1 + floor(random() * array_length(statuses, 1))::int];
        v_nights  := 1 + floor(random() * 5)::int;
        v_checkin := CURRENT_DATE - (floor(random() * 25))::int;
        v_amount  := round((1000 + random() * 15000)::numeric, 2);
        v_created := NOW() - (floor(random() * 25) || ' days')::interval;

        INSERT INTO hotel_bookings
            (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
        VALUES
            (v_id, v_org, 'HTL-' || lpad((1 + floor(random() * 25))::int::text, 3, '0'),
             'delhi', v_checkin, v_checkin + v_nights, v_amount, v_status, v_created);

        INSERT INTO booking_events (booking_id, event_type, payload, created_at)
        VALUES (v_id, 'BOOKING_CREATED',
                jsonb_build_object('status', v_status, 'amount', v_amount, 'city', 'delhi'),
                v_created);
    END LOOP;
END $$;
