-- This query calculates customer transaction frequency based on savings account activity,
-- categorizes customers, and reports toatal value of each category.
-- The savings_savingsaccount table is used to count the frequency of customer's transactions
-- Even though the question lists users_customuser table, owner_id from savings_savingsaccount is
-- is sufficient to identify customers in solving this question
-- Thus, only savings_savingsaccount is used for counting transactions

-- CTE 1: Calculate the number of transactions per customer per month
WITH MonthlyTransactions AS (
    SELECT
        owner_id, -- Customer ID
        DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,  -- Extract Year and Month from the transaction date
        COUNT(*) AS monthly_transaction_count -- Count all entries in savings_savingsaccount for this customer in this month
    FROM
        savings_savingsaccount -- Transaction records 
    GROUP BY
        owner_id, -- Group by customer, owner_id is user ID
        transaction_month -- Group by the specific month
),
-- CTE 2: Calculate the average monthly transactions for each customer
CustomerAverageTransactions AS (
    SELECT
        owner_id,
        AVG(monthly_transaction_count) AS customer_avg_transactions -- Calculate the average of the monthly counts for each customer
    FROM
        MonthlyTransactions
    GROUP BY
        owner_id -- Calculate this average for each customer
),
-- CTE 3: Assign a frequency category to each customer based on their average monthly transactions
CategorizedCustomers AS (
    SELECT
        owner_id,
        customer_avg_transactions,
        CASE
            -- Assign category based on specified thresholds
            WHEN customer_avg_transactions >= 10 THEN 'High Frequency'
            WHEN customer_avg_transactions BETWEEN 3 AND 9 THEN 'Medium Frequency'
            WHEN customer_avg_transactions <= 2 THEN 'Low Frequency'
            -- Creating the 3 categories specified in the question
        END AS frequency_category
    FROM
        CustomerAverageTransactions
)
-- Final SELECT: Aggregate the results by frequency category
SELECT
    frequency_category, -- The transaction frequency category
    COUNT(owner_id) AS customer_count, -- The number of customers in this category
    AVG(customer_avg_transactions) AS avg_transactions_per_month -- The average transaction rate for customers in this category
FROM
    CategorizedCustomers
WHERE frequency_category IS NOT NULL -- Ensures a category was assigned 
GROUP BY
    frequency_category -- Group the final results by category
ORDER BY
    frequency_category; -- 'High Frequency', 'Medium Frequency', 'Low Frequency'