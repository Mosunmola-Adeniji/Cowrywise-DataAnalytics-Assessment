-- CTE 1: Find the latest inflow transaction date for each plan from savings_savingsaccount
WITH LatestInflowTransaction AS (
    SELECT
        plan_id, -- Identifies the plan 
        MAX(transaction_date) AS last_transaction_date -- Find the most recent transaction date for this plan
    FROM
        savings_savingsaccount -- Source of transaction records
    WHERE
        confirmed_amount > 0 -- Filter for inflow transactions
    GROUP BY
        plan_id -- Aggregate transactions by plan
)
-- Main query: Join plans with their latest transaction date and filter for inactivity
SELECT
    p.id AS plan_id, -- Plan identifier from plans_plan
    p.owner_id, -- Customer ID linked to the plan 
    -- Determine plan type based on flags (is_regular_savings and is_a_fund)
    CASE
        WHEN p.is_regular_savings = 1 THEN 'Savings' -- Savings plan
        WHEN p.is_a_fund = 1 THEN 'Investment' -- Investment plan
        ELSE 'Other' -- Handles other plan types not explicitly covered
    END AS type,
    -- Show the actual last transaction date from savings_savingsaccount,
    -- or the plan creation date if no savings transaction exists for the plan
    COALESCE(lit.last_transaction_date, p.created_on) AS last_transaction_date,
    -- Calculate days since the last transaction date (or creation date if none)
    DATEDIFF(CURDATE(), COALESCE(lit.last_transaction_date, p.created_on)) AS inactivity_days
FROM
    plans_plan p -- Source of plan details 
LEFT JOIN
    LatestInflowTransaction lit ON p.id = lit.plan_id -- Join plans with their latest transaction date. LEFT JOIN includes plans with no savings transactions
WHERE
    p.is_deleted = 0 -- Exclude deleted plans (assuming active means not deleted)
    AND p.is_archived = 0 -- Exclude archived plans (assuming active means not archived)
    -- Filter for plans where the last transaction date (or creation date if no transactions)
    -- is older than 365 days from the current date
    AND COALESCE(lit.last_transaction_date, p.created_on) <= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
ORDER BY inactivity_days DESC;