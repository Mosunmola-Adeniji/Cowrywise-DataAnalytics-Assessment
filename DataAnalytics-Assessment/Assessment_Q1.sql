-- Select required customer and plan details
SELECT
    u.id AS owner_id, -- Customer ID from users_customuser
    -- Concatenate first_name and last_name to create the 'name' column
    -- this is because the 'name' column in the table contains null values
    -- CONCAT_WS adds a separator (space) only between non-null values.
    CONCAT_WS(' ', u.first_name, u.last_name) AS name,
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN p.id ELSE NULL END) AS savings_count, -- Count distinct funded savings plans 
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN p.id ELSE NULL END) AS investment_count, -- Count distinct funded investment plans 
    SUM(sa.confirmed_amount) AS total_deposits -- Sum of confirmed deposits for total deposits. 
FROM
    users_customuser u -- Alias for users_customuser table
JOIN
    plans_plan p ON u.id = p.owner_id -- Join users to plans based on owner_id 
JOIN
    savings_savingsaccount sa ON p.id = sa.plan_id -- Join plans to savings_savingsaccount based on plan_id 
WHERE
    sa.confirmed_amount > 0 -- Filter for deposit transactions (positive confirmed_amount) to consider plans 'funded' 
GROUP BY
    u.id, name -- Group results by customer ID and the derived name
HAVING
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN p.id ELSE NULL END) >= 1 -- Keep customers with at least one funded savings plan
    AND COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN p.id ELSE NULL END) >= 1 -- AND at least one funded investment plan
ORDER BY
    total_deposits DESC; -- Order by total deposits from highest to lowest