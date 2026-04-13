-- Customer Retention and Revenue Analysis
-- Recommended SQL questions for a portfolio project

-- 1) Monthly revenue trend
SELECT
    DATE_TRUNC('month', transaction_date) AS month,
    SUM(amount) AS monthly_revenue
FROM transactions
GROUP BY 1
ORDER BY 1;

-- 2) Customer count by plan
SELECT
    plan_name,
    COUNT(*) AS customers
FROM subscriptions
GROUP BY 1
ORDER BY customers DESC;

-- 3) Churn rate by acquisition channel
SELECT
    c.acquisition_channel,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN s.status = 'churned' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN s.status = 'churned' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
GROUP BY 1
ORDER BY churn_rate_pct DESC;

-- 4) Lifetime revenue by customer
SELECT
    customer_id,
    SUM(amount) AS lifetime_revenue
FROM transactions
GROUP BY 1
ORDER BY lifetime_revenue DESC
LIMIT 20;

-- 5) Support volume and churn connection
SELECT
    ticket_band,
    COUNT(*) AS customers,
    SUM(CASE WHEN status = 'churned' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN status = 'churned' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct
FROM (
    SELECT
        c.customer_id,
        s.status,
        CASE
            WHEN COUNT(t.ticket_id) = 0 THEN '0 tickets'
            WHEN COUNT(t.ticket_id) = 1 THEN '1 ticket'
            WHEN COUNT(t.ticket_id) BETWEEN 2 AND 3 THEN '2-3 tickets'
            ELSE '4+ tickets'
        END AS ticket_band
    FROM customers c
    JOIN subscriptions s ON c.customer_id = s.customer_id
    LEFT JOIN support_tickets t ON c.customer_id = t.customer_id
    GROUP BY c.customer_id, s.status
) x
GROUP BY 1
ORDER BY 1;

-- 6) 90-day retention by signup month
WITH cohort AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', signup_date) AS signup_month,
        signup_date
    FROM customers
),
activity AS (
    SELECT DISTINCT
        customer_id
    FROM transactions
)
SELECT
    signup_month,
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN customer_id IN (SELECT customer_id FROM activity) THEN 1 END) AS retained_customers
FROM cohort
GROUP BY 1
ORDER BY 1;


-- Additional SQL queries for interview discussion

SELECT c.acquisition_channel,
       COUNT(DISTINCT c.customer_id) AS customers,
       ROUND(SUM(t.amount), 2) AS revenue,
       ROUND(SUM(t.amount) / COUNT(DISTINCT c.customer_id), 2) AS avg_revenue_per_customer
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
GROUP BY c.acquisition_channel
ORDER BY revenue DESC;

SELECT s.plan_name,
       s.status,
       COUNT(*) AS customers
FROM subscriptions s
GROUP BY s.plan_name, s.status
ORDER BY s.plan_name, customers DESC;

SELECT issue_type,
       ROUND(AVG(csat_score), 2) AS avg_csat,
       ROUND(AVG((julianday(resolved_date) - julianday(created_date)) * 24), 2) AS avg_resolution_hours
FROM support_tickets
GROUP BY issue_type
ORDER BY avg_csat ASC;
