# 🚆 Railway Ticket Management System — SQL Project

A complete SQL-based backend for managing railway ticket bookings, cancellations, passengers, trains, and revenue analytics.

---

## 📌 Project Overview

This project simulates a real-world railway reservation system using **MySQL 8.0**. It covers everything from schema design and data insertion to complex analytical queries, views, stored procedures, and triggers.

---

## 🗃️ Database Schema

The system consists of **9 tables**:

| Table | Description |
|---|---|
| `stations` | Railway stations across India |
| `trains` | Train details and types |
| `train_schedule` | Stop-by-stop route for each train |
| `seat_classes` | Classes like Sleeper, AC 2-Tier, AC 3-Tier etc. |
| `passengers` | Passenger personal details |
| `bookings` | Ticket booking records |
| `payments` | Payment transactions per booking |
| `cancellations` | Cancellation and refund records |
| `booking_audit_log` | Auto-filled audit trail via triggers |

---

## ⚙️ Features

### ✅ Views
- `vw_booking_summary` — Full booking details with passenger, train, route, and fare
- `vw_train_occupancy` — Seat availability and occupancy percentage per train per date
- `vw_revenue_by_train` — Gross revenue and average fare grouped by train

### ✅ Stored Procedures
- `sp_book_ticket` — Books a ticket, calculates fare based on distance, auto-detects waitlist
- `sp_cancel_booking` — Cancels a booking with dynamic refund calculation based on days before journey
- `sp_passenger_history` — Returns full journey history of a passenger

### ✅ Triggers
- `trg_booking_status_change` — Logs every status change into the audit table
- `trg_promote_waitlisted` — Automatically confirms a waitlisted booking when a cancellation occurs

### ✅ Complex Queries
- Window functions: `RANK`, `DENSE_RANK`, `NTILE`, `LAG`, `LEAD`
- Recursive CTE for train route chain
- Pivot-style revenue breakdown by seat class
- Correlated subqueries for gender-wise spend analysis
- Running revenue totals using cumulative window functions
- Cancellation impact report with refund vs penalty analysis

---

## 🧠 Concepts Demonstrated

- Relational schema design with foreign keys
- ENUM types and constraints
- Aggregate functions with `GROUP BY` and `HAVING`
- Subqueries and correlated subqueries
- Common Table Expressions (CTEs) — regular and recursive
- Window functions
- Stored procedures with IN/OUT parameters
- Triggers for automation and audit logging
- Indexing for query performance

---

## 🛠️ How to Run

1. Open **MySQL Workbench** or any MySQL client
2. Run the full `railway_ticket_management.sql` file
3. The script will:
   - Create the database
   - Create all tables
   - Insert sample data
   - Create views, procedures, and triggers
4. Test with:
```sql
USE railway_mgmt;
SELECT * FROM vw_booking_summary;
```

---

## 📊 Sample Query Output

```sql
-- Revenue by payment method
SELECT payment_method, COUNT(*) AS transactions, SUM(amount) AS total_revenue
FROM payments
WHERE payment_status = 'Success'
GROUP BY payment_method
ORDER BY total_revenue DESC;
```

---

## 🔧 Tech Stack

- **Database:** MySQL 8.0
- **Language:** SQL
- **Tools:** MySQL Workbench / DB Fiddle

---

## 👤 Author

**Harshita Dubey**  
Aspiring Data Analyst | SQL Enthusiast  

---

## 📄 License

This project is open source and available for learning and portfolio purposes.
