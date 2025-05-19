-- This query calculates Customer Lifetime Value (CLV) for each customer
-- based on account tenure and savings transaction volume.
-- Tables used: users_customuser (for customer details), savings_savingsaccount (for transactions)
-- Formula: CLV = (Total Profit / Tenure in Months) * 12
-- Total Profit = SUM(confirmed_amount) * 0.1% (assumed profit_per_transaction value)
-- confirmed_amount is in kobo, profit is 0.1%, convert to Naira for final CLV output
-- Profit in Naira = SUM(confirmed_amount) * 0.001 / 100 = SUM(confirmed_amount) * 0.00001
-- Tenure in Months is calculated from user signup date (date_joined)

SELECT
    u.id AS customer_id, -- Customer identifier from users_customuser
    CONCAT_WS(' ', u.first_name, u.last_name) AS name,
    -- Calculate tenure in months from the user's join date to today
    TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months,
    -- Calculate total transactions by counting savings account entries for the user
    -- COALESCE handles users with no savings transactions, returning 0 
    COALESCE(COUNT(sa.id), 0) AS total_transactions,
    -- Calculate Estimated CLV using the formula: (Total Profit / Tenure in Months) * 12
    -- Total Profit is SUM(confirmed_amount) in kobo * 0.1% profit margin
    -- Convert total profit to Naira: SUM(confirmed_amount) * 0.001 / 100 = SUM(confirmed_amount) * 0.00001
    -- Use GREATEST(1, ...) for the tenure denominator to avoid division by zero if tenure is less than 1 month
    (COALESCE(SUM(sa.confirmed_amount), 0) * 0.00001 / GREATEST(1, TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()))) * 12 AS estimated_clv
FROM
    users_customuser u -- Source for customer details and signup date
LEFT JOIN
    savings_savingsaccount sa ON u.id = sa.owner_id -- Join customers with their savings transactions. LEFT JOIN includes users with no transactions.
GROUP BY
   u.id, name, u.date_joined -- Group results by customer to aggregate transactions and calculate tenure
ORDER BY
  estimated_clv DESC; -- Order by estimated CLV from highest to lowest as requested