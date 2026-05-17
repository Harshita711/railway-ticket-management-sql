-- ============================================================
--   RAILWAY TICKET MANAGEMENT SYSTEM
--   Author  : [Your Name]
--   Database: MySQL 8.0+
--   Desc    : Full schema + sample data + complex queries
--             covering stored procedures, triggers, views,
--             window functions, CTEs, and more.
-- ============================================================


-- ============================================================
-- SECTION 1: DATABASE SETUP
-- ============================================================

DROP DATABASE IF EXISTS railway_mgmt;
CREATE DATABASE railway_mgmt;
USE railway_mgmt;


-- ============================================================
-- SECTION 2: TABLE DEFINITIONS
-- ============================================================

-- 2.1 Stations
CREATE TABLE stations (
    station_id    INT           AUTO_INCREMENT PRIMARY KEY,
    station_name  VARCHAR(100)  NOT NULL,
    station_code  CHAR(5)       NOT NULL UNIQUE,
    city          VARCHAR(100)  NOT NULL,
    state         VARCHAR(100)  NOT NULL,
    platform_count INT          DEFAULT 1,
    created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- 2.2 Trains
CREATE TABLE trains (
    train_id      INT           AUTO_INCREMENT PRIMARY KEY,
    train_number  VARCHAR(10)   NOT NULL UNIQUE,
    train_name    VARCHAR(150)  NOT NULL,
    train_type    ENUM('Express','Superfast','Local','Intercity','Rajdhani','Shatabdi') NOT NULL,
    total_seats   INT           NOT NULL,
    status        ENUM('Active','Inactive','Under Maintenance') DEFAULT 'Active',
    created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- 2.3 Train Schedule (route stops)
CREATE TABLE train_schedule (
    schedule_id       INT         AUTO_INCREMENT PRIMARY KEY,
    train_id          INT         NOT NULL,
    station_id        INT         NOT NULL,
    stop_number       INT         NOT NULL,          -- 1 = origin, last = destination
    arrival_time      TIME        NULL,               -- NULL for origin
    departure_time    TIME        NULL,               -- NULL for last stop
    distance_from_origin_km INT  DEFAULT 0,
    FOREIGN KEY (train_id)   REFERENCES trains(train_id)   ON DELETE CASCADE,
    FOREIGN KEY (station_id) REFERENCES stations(station_id) ON DELETE CASCADE,
    UNIQUE KEY uq_train_stop (train_id, stop_number)
);

-- 2.4 Seat Classes
CREATE TABLE seat_classes (
    class_id      INT           AUTO_INCREMENT PRIMARY KEY,
    class_code    VARCHAR(5)    NOT NULL UNIQUE,
    class_name    VARCHAR(50)   NOT NULL,
    base_fare_per_km DECIMAL(6,2) NOT NULL
);

-- 2.5 Passengers
CREATE TABLE passengers (
    passenger_id  INT           AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(150)  NOT NULL,
    email         VARCHAR(150)  UNIQUE,
    phone         VARCHAR(15)   NOT NULL,
    date_of_birth DATE          NOT NULL,
    gender        ENUM('Male','Female','Other') NOT NULL,
    id_proof_type ENUM('Aadhar','Passport','Driving Licence','Voter ID'),
    id_proof_no   VARCHAR(30),
    created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- 2.6 Bookings
CREATE TABLE bookings (
    booking_id        INT           AUTO_INCREMENT PRIMARY KEY,
    passenger_id      INT           NOT NULL,
    train_id          INT           NOT NULL,
    journey_date      DATE          NOT NULL,
    from_station_id   INT           NOT NULL,
    to_station_id     INT           NOT NULL,
    class_id          INT           NOT NULL,
    seats_booked      INT           DEFAULT 1,
    total_fare        DECIMAL(10,2) NOT NULL,
    booking_status    ENUM('Confirmed','Waitlisted','Cancelled','Completed') DEFAULT 'Confirmed',
    payment_status    ENUM('Paid','Pending','Refunded') DEFAULT 'Pending',
    booking_date      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (passenger_id)    REFERENCES passengers(passenger_id),
    FOREIGN KEY (train_id)        REFERENCES trains(train_id),
    FOREIGN KEY (from_station_id) REFERENCES stations(station_id),
    FOREIGN KEY (to_station_id)   REFERENCES stations(station_id),
    FOREIGN KEY (class_id)        REFERENCES seat_classes(class_id)
);

-- 2.7 Payments
CREATE TABLE payments (
    payment_id     INT           AUTO_INCREMENT PRIMARY KEY,
    booking_id     INT           NOT NULL UNIQUE,
    amount         DECIMAL(10,2) NOT NULL,
    payment_method ENUM('UPI','Credit Card','Debit Card','Net Banking','Cash') NOT NULL,
    payment_date   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    transaction_id VARCHAR(50)   UNIQUE,
    payment_status ENUM('Success','Failed','Pending','Refunded') DEFAULT 'Pending',
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE
);

-- 2.8 Cancellations
CREATE TABLE cancellations (
    cancellation_id   INT           AUTO_INCREMENT PRIMARY KEY,
    booking_id        INT           NOT NULL,
    cancellation_date TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    refund_amount     DECIMAL(10,2) NOT NULL,
    reason            VARCHAR(255),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

-- 2.9 Audit Log (auto-filled by triggers)
CREATE TABLE booking_audit_log (
    log_id        INT           AUTO_INCREMENT PRIMARY KEY,
    booking_id    INT           NOT NULL,
    action        VARCHAR(50)   NOT NULL,
    old_status    VARCHAR(50),
    new_status    VARCHAR(50),
    changed_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    changed_by    VARCHAR(100)  DEFAULT 'system'
);


-- ============================================================
-- SECTION 3: SAMPLE DATA
-- ============================================================

-- Stations
INSERT INTO stations (station_name, station_code, city, state, platform_count) VALUES
('Chhatrapati Shivaji Maharaj Terminus', 'CSMT',  'Mumbai',    'Maharashtra', 18),
('New Delhi Railway Station',            'NDLS',  'New Delhi', 'Delhi',       16),
('Howrah Junction',                      'HWH',   'Kolkata',   'West Bengal', 23),
('Chennai Central',                      'MAS',   'Chennai',   'Tamil Nadu',  12),
('Bengaluru City Junction',              'SBC',   'Bengaluru', 'Karnataka',   10),
('Pune Junction',                        'PUNE',  'Pune',      'Maharashtra',  6),
('Hyderabad Deccan',                     'HYB',   'Hyderabad', 'Telangana',    8),
('Ahmedabad Junction',                   'ADI',   'Ahmedabad', 'Gujarat',      8),
('Jaipur Junction',                      'JP',    'Jaipur',    'Rajasthan',    6),
('Lucknow Charbagh',                     'LKO',   'Lucknow',   'Uttar Pradesh',8);

-- Seat Classes
INSERT INTO seat_classes (class_code, class_name, base_fare_per_km) VALUES
('SL',  'Sleeper Class',              0.50),
('3A',  'AC 3-Tier',                  1.20),
('2A',  'AC 2-Tier',                  1.80),
('1A',  'AC First Class',             3.00),
('CC',  'Chair Car',                  0.80),
('EC',  'Executive Chair Car',        1.50);

-- Trains
INSERT INTO trains (train_number, train_name, train_type, total_seats) VALUES
('12951', 'Mumbai Rajdhani',       'Rajdhani',   650),
('12301', 'Howrah Rajdhani',       'Rajdhani',   650),
('12004', 'New Delhi Shatabdi',    'Shatabdi',   700),
('11301', 'Udyan Express',         'Express',    900),
('12163', 'Chennai Superfast',     'Superfast',  800),
('16501', 'Bengaluru Express',     'Express',    750),
('22691', 'Rajdhani Express KSR',  'Rajdhani',   600),
('19031', 'Yoga Express',          'Express',    850);

-- Train Schedules (train 1: Mumbai → New Delhi)
INSERT INTO train_schedule (train_id, station_id, stop_number, arrival_time, departure_time, distance_from_origin_km) VALUES
(1, 1, 1, NULL,     '17:00', 0),
(1, 6, 2, '18:30', '18:40', 120),
(1, 8, 3, '23:00', '23:15', 493),
(1, 9, 4, '03:30', '03:40', 835),
(1, 2, 5, '08:00', NULL,    1384);

-- Train Schedules (train 2: Kolkata → New Delhi)
INSERT INTO train_schedule (train_id, station_id, stop_number, arrival_time, departure_time, distance_from_origin_km) VALUES
(2, 3, 1, NULL,     '14:05', 0),
(2, 10, 2,'22:45', '22:55', 987),
(2, 2,  3,'08:25', NULL,    1441);

-- Passengers
INSERT INTO passengers (full_name, email, phone, date_of_birth, gender, id_proof_type, id_proof_no) VALUES
('Arjun Sharma',    'arjun.sharma@email.com',  '9876543210', '1995-04-12', 'Male',   'Aadhar',           '1234-5678-9012'),
('Priya Nair',      'priya.nair@email.com',    '9823456781', '1998-07-23', 'Female', 'Passport',         'P1234567'),
('Rahul Verma',     'rahul.verma@email.com',   '9912345678', '1990-01-05', 'Male',   'Driving Licence',  'DL-0420190012345'),
('Sneha Patel',     'sneha.patel@email.com',   '9845678901', '2000-11-30', 'Female', 'Aadhar',           '9876-5432-1098'),
('Kiran Reddy',     'kiran.reddy@email.com',   '9734567890', '1988-03-17', 'Male',   'Voter ID',         'ABC1234567'),
('Meera Iyer',      'meera.iyer@email.com',    '9654321098', '1993-08-09', 'Female', 'Aadhar',           '1111-2222-3333'),
('Suresh Kumar',    'suresh.kumar@email.com',  '9543210987', '1975-12-25', 'Male',   'Passport',         'P9876543'),
('Divya Singh',     'divya.singh@email.com',   '9432109876', '2002-06-14', 'Female', 'Aadhar',           '4444-5555-6666'),
('Amit Joshi',      'amit.joshi@email.com',    '9321098765', '1985-09-28', 'Male',   'Driving Licence',  'DL-0120150067890'),
('Lakshmi Devi',    'lakshmi.devi@email.com',  '9210987654', '1970-02-18', 'Female', 'Voter ID',         'XYZ9876543');

-- Bookings
INSERT INTO bookings (passenger_id, train_id, journey_date, from_station_id, to_station_id, class_id, seats_booked, total_fare, booking_status, payment_status) VALUES
(1,  1, '2024-03-15', 1, 2, 2, 1,  1660.80, 'Confirmed', 'Paid'),
(2,  1, '2024-03-15', 1, 2, 3, 1,  2491.20, 'Confirmed', 'Paid'),
(3,  2, '2024-03-16', 3, 2, 1, 2,  1441.00, 'Confirmed', 'Paid'),
(4,  1, '2024-03-15', 6, 2, 1, 1,   632.00, 'Waitlisted','Pending'),
(5,  2, '2024-03-16', 3, 2, 2, 1,  2077.44, 'Confirmed', 'Paid'),
(6,  1, '2024-03-20', 1, 9, 2, 1,  1002.00, 'Confirmed', 'Paid'),
(7,  2, '2024-03-18', 3, 2, 4, 1,  4323.00, 'Confirmed', 'Paid'),
(8,  1, '2024-03-15', 1, 2, 1, 2,  1384.00, 'Cancelled', 'Refunded'),
(9,  1, '2024-03-22', 1, 2, 3, 1,  2491.20, 'Confirmed', 'Paid'),
(10, 2, '2024-03-19', 3, 2, 2, 1,  2077.44, 'Completed', 'Paid');

-- Payments
INSERT INTO payments (booking_id, amount, payment_method, transaction_id, payment_status) VALUES
(1,  1660.80, 'UPI',          'TXN2024031501', 'Success'),
(2,  2491.20, 'Credit Card',  'TXN2024031502', 'Success'),
(3,  1441.00, 'Net Banking',  'TXN2024031603', 'Success'),
(5,  2077.44, 'Debit Card',   'TXN2024031605', 'Success'),
(6,  1002.00, 'UPI',          'TXN2024032006', 'Success'),
(7,  4323.00, 'Credit Card',  'TXN2024031807', 'Success'),
(8,     0.00, 'UPI',          'TXN2024031508', 'Refunded'),
(9,  2491.20, 'Net Banking',  'TXN2024032209', 'Success'),
(10, 2077.44, 'UPI',          'TXN2024031910', 'Success');

-- Cancellations
INSERT INTO cancellations (booking_id, refund_amount, reason) VALUES
(8, 1108.80, 'Passenger requested cancellation due to personal emergency');


-- ============================================================
-- SECTION 4: VIEWS
-- ============================================================

-- 4.1  Full booking summary
CREATE OR REPLACE VIEW vw_booking_summary AS
SELECT
    b.booking_id,
    p.full_name                         AS passenger_name,
    p.phone,
    t.train_number,
    t.train_name,
    fs.station_name                     AS from_station,
    ts2.station_name                    AS to_station,
    b.journey_date,
    sc.class_name                       AS seat_class,
    b.seats_booked,
    b.total_fare,
    b.booking_status,
    b.payment_status,
    b.booking_date
FROM bookings b
JOIN passengers   p   ON b.passenger_id    = p.passenger_id
JOIN trains       t   ON b.train_id        = t.train_id
JOIN stations     fs  ON b.from_station_id = fs.station_id
JOIN stations     ts2 ON b.to_station_id   = ts2.station_id
JOIN seat_classes sc  ON b.class_id        = sc.class_id;

-- 4.2  Train occupancy overview
CREATE OR REPLACE VIEW vw_train_occupancy AS
SELECT
    t.train_id,
    t.train_number,
    t.train_name,
    t.total_seats,
    b.journey_date,
    SUM(b.seats_booked)                                    AS booked_seats,
    t.total_seats - SUM(b.seats_booked)                    AS available_seats,
    ROUND(SUM(b.seats_booked) / t.total_seats * 100, 2)   AS occupancy_pct
FROM trains t
LEFT JOIN bookings b ON t.train_id = b.train_id
    AND b.booking_status IN ('Confirmed','Waitlisted','Completed')
GROUP BY t.train_id, t.train_number, t.train_name, t.total_seats, b.journey_date;

-- 4.3  Revenue by train
CREATE OR REPLACE VIEW vw_revenue_by_train AS
SELECT
    t.train_number,
    t.train_name,
    t.train_type,
    COUNT(b.booking_id)      AS total_bookings,
    SUM(b.total_fare)        AS gross_revenue,
    AVG(b.total_fare)        AS avg_fare
FROM trains t
LEFT JOIN bookings b ON t.train_id = b.train_id
    AND b.booking_status != 'Cancelled'
GROUP BY t.train_id, t.train_number, t.train_name, t.train_type;


-- ============================================================
-- SECTION 5: STORED PROCEDURES
-- ============================================================

DELIMITER $$

-- 5.1  Book a ticket
CREATE PROCEDURE sp_book_ticket(
    IN  p_passenger_id    INT,
    IN  p_train_id        INT,
    IN  p_journey_date    DATE,
    IN  p_from_station_id INT,
    IN  p_to_station_id   INT,
    IN  p_class_id        INT,
    IN  p_seats           INT,
    OUT p_booking_id      INT,
    OUT p_message         VARCHAR(255)
)
BEGIN
    DECLARE v_distance   INT DEFAULT 0;
    DECLARE v_fare_per_km DECIMAL(6,2);
    DECLARE v_total_fare DECIMAL(10,2);
    DECLARE v_booked     INT DEFAULT 0;
    DECLARE v_capacity   INT;
    DECLARE v_status     VARCHAR(20);
    DECLARE v_from_stop  INT;
    DECLARE v_to_stop    INT;

    -- Get stop numbers
    SELECT stop_number INTO v_from_stop FROM train_schedule
    WHERE train_id = p_train_id AND station_id = p_from_station_id;

    SELECT stop_number INTO v_to_stop FROM train_schedule
    WHERE train_id = p_train_id AND station_id = p_to_station_id;

    IF v_from_stop IS NULL OR v_to_stop IS NULL OR v_from_stop >= v_to_stop THEN
        SET p_booking_id = -1;
        SET p_message = 'Invalid station combination for this train.';
    ELSE
        -- Calculate distance
        SELECT (
            (SELECT distance_from_origin_km FROM train_schedule
             WHERE train_id = p_train_id AND station_id = p_to_station_id)
            -
            (SELECT distance_from_origin_km FROM train_schedule
             WHERE train_id = p_train_id AND station_id = p_from_station_id)
        ) INTO v_distance;

        -- Get fare per km
        SELECT base_fare_per_km INTO v_fare_per_km
        FROM seat_classes WHERE class_id = p_class_id;

        SET v_total_fare = v_distance * v_fare_per_km * p_seats;

        -- Check seat availability
        SELECT total_seats INTO v_capacity FROM trains WHERE train_id = p_train_id;
        SELECT COALESCE(SUM(seats_booked), 0) INTO v_booked
        FROM bookings
        WHERE train_id = p_train_id
          AND journey_date = p_journey_date
          AND booking_status IN ('Confirmed','Waitlisted');

        IF (v_booked + p_seats) > v_capacity THEN
            SET v_status = 'Waitlisted';
        ELSE
            SET v_status = 'Confirmed';
        END IF;

        -- Insert booking
        INSERT INTO bookings
            (passenger_id, train_id, journey_date, from_station_id,
             to_station_id, class_id, seats_booked, total_fare, booking_status, payment_status)
        VALUES
            (p_passenger_id, p_train_id, p_journey_date, p_from_station_id,
             p_to_station_id, p_class_id, p_seats, v_total_fare, v_status, 'Pending');

        SET p_booking_id = LAST_INSERT_ID();
        SET p_message    = CONCAT('Booking ', v_status, '. Fare: INR ', v_total_fare);
    END IF;
END$$


-- 5.2  Cancel a booking
CREATE PROCEDURE sp_cancel_booking(
    IN  p_booking_id    INT,
    IN  p_reason        VARCHAR(255),
    OUT p_refund_amount DECIMAL(10,2),
    OUT p_message       VARCHAR(255)
)
BEGIN
    DECLARE v_journey_date DATE;
    DECLARE v_fare         DECIMAL(10,2);
    DECLARE v_days_ahead   INT;
    DECLARE v_refund_pct   DECIMAL(4,2);

    SELECT journey_date, total_fare
    INTO   v_journey_date, v_fare
    FROM   bookings
    WHERE  booking_id = p_booking_id AND booking_status = 'Confirmed';

    IF v_journey_date IS NULL THEN
        SET p_refund_amount = 0;
        SET p_message = 'Booking not found or already cancelled.';
    ELSE
        SET v_days_ahead = DATEDIFF(v_journey_date, CURDATE());

        -- Refund policy
        SET v_refund_pct = CASE
            WHEN v_days_ahead >= 7  THEN 0.90
            WHEN v_days_ahead >= 3  THEN 0.75
            WHEN v_days_ahead >= 1  THEN 0.50
            ELSE                         0.25
        END;

        SET p_refund_amount = ROUND(v_fare * v_refund_pct, 2);

        UPDATE bookings
        SET    booking_status = 'Cancelled', payment_status = 'Refunded'
        WHERE  booking_id = p_booking_id;

        INSERT INTO cancellations (booking_id, refund_amount, reason)
        VALUES (p_booking_id, p_refund_amount, p_reason);

        SET p_message = CONCAT('Booking cancelled. Refund: INR ', p_refund_amount,
                               ' (', v_refund_pct * 100, '%)');
    END IF;
END$$


-- 5.3  Get passenger booking history
CREATE PROCEDURE sp_passenger_history(IN p_passenger_id INT)
BEGIN
    SELECT
        b.booking_id,
        t.train_name,
        fs.station_name  AS from_station,
        ts2.station_name AS to_station,
        b.journey_date,
        sc.class_name,
        b.seats_booked,
        b.total_fare,
        b.booking_status,
        b.payment_status
    FROM bookings b
    JOIN trains       t   ON b.train_id        = t.train_id
    JOIN stations     fs  ON b.from_station_id = fs.station_id
    JOIN stations     ts2 ON b.to_station_id   = ts2.station_id
    JOIN seat_classes sc  ON b.class_id        = sc.class_id
    WHERE b.passenger_id = p_passenger_id
    ORDER BY b.journey_date DESC;
END$$

DELIMITER ;


-- ============================================================
-- SECTION 6: TRIGGERS
-- ============================================================

DELIMITER $$

-- 6.1  Log every booking status change
CREATE TRIGGER trg_booking_status_change
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    IF OLD.booking_status <> NEW.booking_status THEN
        INSERT INTO booking_audit_log (booking_id, action, old_status, new_status)
        VALUES (NEW.booking_id, 'STATUS_CHANGE', OLD.booking_status, NEW.booking_status);
    END IF;
END$$

-- 6.2  Auto-promote a waitlisted booking when a cancellation happens
CREATE TRIGGER trg_promote_waitlisted
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    DECLARE v_next_waitlisted INT;

    IF NEW.booking_status = 'Cancelled' AND OLD.booking_status != 'Cancelled' THEN
        -- Find the oldest waitlisted booking on the same train & date
        SELECT booking_id INTO v_next_waitlisted
        FROM   bookings
        WHERE  train_id      = NEW.train_id
          AND  journey_date  = NEW.journey_date
          AND  booking_status = 'Waitlisted'
        ORDER BY booking_id ASC
        LIMIT  1;

        IF v_next_waitlisted IS NOT NULL THEN
            UPDATE bookings
            SET    booking_status = 'Confirmed'
            WHERE  booking_id = v_next_waitlisted;
        END IF;
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- SECTION 7: COMPLEX QUERIES
-- ============================================================

-- ---------------------------------------------------------------
-- Q1. WINDOW FUNCTION — Rank passengers by total spend
-- ---------------------------------------------------------------
SELECT
    p.full_name,
    COUNT(b.booking_id)                                        AS total_bookings,
    SUM(b.total_fare)                                          AS total_spent,
    RANK()     OVER (ORDER BY SUM(b.total_fare) DESC)          AS spend_rank,
    DENSE_RANK() OVER (ORDER BY COUNT(b.booking_id) DESC)      AS booking_freq_rank,
    NTILE(4)   OVER (ORDER BY SUM(b.total_fare) DESC)          AS spend_quartile
FROM passengers p
JOIN bookings b ON p.passenger_id = b.passenger_id
WHERE b.booking_status != 'Cancelled'
GROUP BY p.passenger_id, p.full_name
ORDER BY total_spent DESC;


-- ---------------------------------------------------------------
-- Q2. CTE — Monthly revenue trend with running total
-- ---------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(b.booking_date, '%Y-%m') AS booking_month,
        SUM(b.total_fare)                    AS revenue,
        COUNT(b.booking_id)                  AS num_bookings
    FROM bookings b
    WHERE b.booking_status != 'Cancelled'
    GROUP BY DATE_FORMAT(b.booking_date, '%Y-%m')
),
running_total AS (
    SELECT
        booking_month,
        revenue,
        num_bookings,
        SUM(revenue) OVER (ORDER BY booking_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
    FROM monthly_revenue
)
SELECT * FROM running_total ORDER BY booking_month;


-- ---------------------------------------------------------------
-- Q3. CTE + SELF-JOIN — Find passengers who travelled more than once
--     on the same route (loyalty detection)
-- ---------------------------------------------------------------
WITH route_counts AS (
    SELECT
        passenger_id,
        from_station_id,
        to_station_id,
        COUNT(*) AS trips_on_route
    FROM bookings
    WHERE booking_status IN ('Confirmed','Completed')
    GROUP BY passenger_id, from_station_id, to_station_id
    HAVING COUNT(*) > 1
)
SELECT
    p.full_name,
    fs.station_name  AS from_station,
    ts2.station_name AS to_station,
    rc.trips_on_route
FROM route_counts rc
JOIN passengers p   ON rc.passenger_id    = p.passenger_id
JOIN stations   fs  ON rc.from_station_id = fs.station_id
JOIN stations   ts2 ON rc.to_station_id   = ts2.station_id
ORDER BY rc.trips_on_route DESC;


-- ---------------------------------------------------------------
-- Q4. SUBQUERY — Trains with above-average booking count
-- ---------------------------------------------------------------
SELECT
    t.train_number,
    t.train_name,
    t.train_type,
    COUNT(b.booking_id) AS total_bookings
FROM trains t
JOIN bookings b ON t.train_id = b.train_id
GROUP BY t.train_id, t.train_number, t.train_name, t.train_type
HAVING COUNT(b.booking_id) > (
    SELECT AVG(cnt) FROM (
        SELECT COUNT(*) AS cnt
        FROM bookings
        GROUP BY train_id
    ) sub
)
ORDER BY total_bookings DESC;


-- ---------------------------------------------------------------
-- Q5. WINDOW LAG/LEAD — Passenger's journey gap analysis
--     (days between consecutive journeys)
-- ---------------------------------------------------------------
SELECT
    p.full_name,
    b.journey_date,
    LAG(b.journey_date)  OVER (PARTITION BY b.passenger_id ORDER BY b.journey_date) AS prev_journey,
    LEAD(b.journey_date) OVER (PARTITION BY b.passenger_id ORDER BY b.journey_date) AS next_journey,
    DATEDIFF(b.journey_date,
        LAG(b.journey_date) OVER (PARTITION BY b.passenger_id ORDER BY b.journey_date)
    ) AS days_since_last_trip
FROM bookings b
JOIN passengers p ON b.passenger_id = p.passenger_id
WHERE b.booking_status IN ('Confirmed','Completed')
ORDER BY p.full_name, b.journey_date;


-- ---------------------------------------------------------------
-- Q6. PIVOT-STYLE — Revenue breakdown by seat class per train
-- ---------------------------------------------------------------
SELECT
    t.train_name,
    SUM(CASE WHEN sc.class_code = 'SL' THEN b.total_fare ELSE 0 END) AS sleeper_revenue,
    SUM(CASE WHEN sc.class_code = '3A' THEN b.total_fare ELSE 0 END) AS ac3_revenue,
    SUM(CASE WHEN sc.class_code = '2A' THEN b.total_fare ELSE 0 END) AS ac2_revenue,
    SUM(CASE WHEN sc.class_code = '1A' THEN b.total_fare ELSE 0 END) AS ac1_revenue,
    SUM(b.total_fare)                                                  AS total_revenue
FROM bookings b
JOIN trains       t  ON b.train_id  = t.train_id
JOIN seat_classes sc ON b.class_id  = sc.class_id
WHERE b.booking_status != 'Cancelled'
GROUP BY t.train_id, t.train_name
ORDER BY total_revenue DESC;


-- ---------------------------------------------------------------
-- Q7. RECURSIVE CTE — Train route chain (stop-by-stop path)
-- ---------------------------------------------------------------
WITH RECURSIVE route_chain AS (
    -- Anchor: first stop
    SELECT
        ts.train_id,
        ts.station_id,
        ts.stop_number,
        ts.departure_time,
        ts.distance_from_origin_km,
        s.station_name,
        CAST(s.station_name AS CHAR(500)) AS route_path
    FROM train_schedule ts
    JOIN stations s ON ts.station_id = s.station_id
    WHERE ts.stop_number = 1

    UNION ALL

    -- Recursive: next stops
    SELECT
        ts.train_id,
        ts.station_id,
        ts.stop_number,
        ts.departure_time,
        ts.distance_from_origin_km,
        s.station_name,
        CONCAT(rc.route_path, ' → ', s.station_name)
    FROM train_schedule ts
    JOIN stations s     ON ts.station_id = s.station_id
    JOIN route_chain rc ON ts.train_id   = rc.train_id
                       AND ts.stop_number = rc.stop_number + 1
)
SELECT
    train_id,
    stop_number,
    station_name,
    departure_time,
    distance_from_origin_km AS km_from_origin,
    route_path
FROM route_chain
ORDER BY train_id, stop_number;


-- ---------------------------------------------------------------
-- Q8. CORRELATED SUBQUERY — Passengers who spent more than
--     the average spend of their gender group
-- ---------------------------------------------------------------
SELECT
    p.full_name,
    p.gender,
    SUM(b.total_fare) AS total_spent
FROM passengers p
JOIN bookings b ON p.passenger_id = b.passenger_id
WHERE b.booking_status != 'Cancelled'
GROUP BY p.passenger_id, p.full_name, p.gender
HAVING SUM(b.total_fare) > (
    SELECT AVG(sub_total)
    FROM (
        SELECT p2.passenger_id, SUM(b2.total_fare) AS sub_total
        FROM passengers p2
        JOIN bookings b2 ON p2.passenger_id = b2.passenger_id
        WHERE p2.gender = p.gender
          AND b2.booking_status != 'Cancelled'
        GROUP BY p2.passenger_id
    ) gender_avg
)
ORDER BY p.gender, total_spent DESC;


-- ---------------------------------------------------------------
-- Q9. PAYMENT METHOD ANALYSIS with percentage share
-- ---------------------------------------------------------------
SELECT
    py.payment_method,
    COUNT(*)                                            AS num_transactions,
    SUM(py.amount)                                      AS total_amount,
    ROUND(
        SUM(py.amount) / SUM(SUM(py.amount)) OVER () * 100
    , 2)                                               AS revenue_share_pct,
    ROUND(AVG(py.amount), 2)                           AS avg_transaction_value
FROM payments py
WHERE py.payment_status = 'Success'
GROUP BY py.payment_method
ORDER BY total_amount DESC;


-- ---------------------------------------------------------------
-- Q10. CANCELLATION IMPACT REPORT
--      — cancelled bookings vs confirmed, with refund totals
-- ---------------------------------------------------------------
WITH cancellation_stats AS (
    SELECT
        t.train_name,
        COUNT(b.booking_id)                                       AS total_bookings,
        SUM(CASE WHEN b.booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_count,
        SUM(CASE WHEN b.booking_status = 'Cancelled' THEN b.total_fare ELSE 0 END) AS revenue_lost,
        SUM(COALESCE(c.refund_amount, 0))                        AS total_refunded
    FROM trains t
    JOIN bookings      b ON t.train_id  = b.train_id
    LEFT JOIN cancellations c ON b.booking_id = c.booking_id
    GROUP BY t.train_id, t.train_name
)
SELECT
    train_name,
    total_bookings,
    cancelled_count,
    ROUND(cancelled_count / total_bookings * 100, 2) AS cancellation_rate_pct,
    revenue_lost,
    total_refunded,
    revenue_lost - total_refunded                    AS net_penalty_retained
FROM cancellation_stats
ORDER BY cancellation_rate_pct DESC;


-- ============================================================
-- SECTION 8: INDEXES FOR PERFORMANCE
-- ============================================================

CREATE INDEX idx_bookings_journey_date  ON bookings (journey_date);
CREATE INDEX idx_bookings_train_date    ON bookings (train_id, journey_date);
CREATE INDEX idx_bookings_passenger     ON bookings (passenger_id);
CREATE INDEX idx_bookings_status        ON bookings (booking_status);
CREATE INDEX idx_payments_status        ON payments (payment_status);
CREATE INDEX idx_schedule_train         ON train_schedule (train_id, stop_number);


-- ============================================================
-- SECTION 9: QUICK VERIFICATION SELECTS
-- ============================================================

-- Check all views
SELECT * FROM vw_booking_summary;
SELECT * FROM vw_train_occupancy;
SELECT * FROM vw_revenue_by_train;

-- Call stored procedures
CALL sp_passenger_history(1);

-- Test booking procedure
SET @bid = 0; SET @msg = '';
CALL sp_book_ticket(2, 1, '2024-04-10', 1, 2, 2, 1, @bid, @msg);
SELECT @bid AS new_booking_id, @msg AS result_message;

-- ============================================================
-- END OF FILE
-- ============================================================
