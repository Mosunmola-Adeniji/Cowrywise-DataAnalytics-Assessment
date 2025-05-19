### This repository contains my SQL query solutions for the Data Analyst Assessment. 

The database schema provided includes the following tables:
*   `users_customuser`: Contains customer demographic information.
*   `savings_savingsaccount`: Records deposit transactions.
*   `plans_plan`: Records customer-created plans (including savings and investment plans).
*   `withdrawals_withdrawal`: Records withdrawal transactions.

My solutions adhere to the submission requirements, with each question's solution contained in a single, properly formatted SQL file.

Stated below is how I approached each of the questions.

### Question 1: High-Value Customers with Multiple Products

**Scenario:** The goal was to identify customers who have demonstrated cross-selling potential by having both a savings plan and an investment plan.

**Approach:**
1.  I needed to link customer information from `users_customuser` to their plans in `plans_plan` and their deposit transactions in `savings_savingsaccount`. I used the `owner_id` which links plans and savings accounts back to the user ID in `users_customuser`.
2.  To find customers with savings plans (`is_regular_savings = 1`) and investment plans (`is_a_fund = 1`), I joined `users_customuser` with `plans_plan`.
3.  To determine if a plan was "funded" (as implied by the scenario and output format showing total deposits), I joined with `savings_savingsaccount` to sum the `confirmed_amount` for each customer. I assumed 'funded' meant having at least one transaction associated with a plan or customer. The `savings_savingsaccount` table specifically records deposit transactions.
4.  I grouped the results by customer (`user_id`, `name`).
5.  Within each group, I counted the distinct types of plans they had, distinguishing between savings (`is_regular_savings = 1`) and investment plans (`is_a_fund = 1`).
6.  I summed the `confirmed_amount` from `savings_savingsaccount` for each customer to get their total deposits.
7.  Finally, I filtered the results to include only customers where both the savings plan count and the investment plan count were greater than 0. The results were then ordered by the total deposits in descending order as requested.

### Assessment_Q2.sql: Transaction Frequency Analysis

**Scenario:** This task required calculating the average monthly transaction frequency for each customer and categorizing them based on this average.

**Approach:**
1.  I needed transaction data per customer, so I used `users_customuser` and `savings_savingsaccount`, linking them on `owner_id` = `users_customuser.id`. The `savings_savingsaccount` table provides the necessary transaction records.
2.  I calculated the total number of transactions for each customer by counting rows in `savings_savingsaccount` grouped by `user_id`.
3.  I calculated the customer's tenure in months using the difference between their `date_joined` from `users_customuser` and the current date (`CURDATE()`). I used `TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE())` for this.
4.  To find the average transactions per month *per customer*, I divided the total transaction count by their tenure in months.
5.  An important edge case here was handling users who signed up very recently, resulting in 0 months tenure. Division by zero would cause an error. I addressed this by using `GREATEST(1, tenure_in_months)` in the denominator, effectively treating tenure as a minimum of 1 month for the calculation.
6.  I then used a `CASE` statement to categorize each customer's average monthly transaction rate into "High Frequency" (≥10), "Medium Frequency" (3-9), and "Low Frequency" (≤2).
7.  The final output required the count of customers and the *average* average transactions per month *per category*. I used a subquery (or CTE) to first calculate the per-customer average frequency, and then an outer query to group by the frequency category and calculate the required counts and averages.

### Assessment_Q3.sql: Account Inactivity Alert

**Scenario:** The task was to identify active plans (savings or investments) that had no inflow transactions (`savings_savingsaccount`) for over one year.

**Approach:**
1.  I needed to check inactivity based on *inflow* transactions for specific plans. The `savings_savingsaccount` table contains the `transaction_date` and is linked to `plans_plan` via `plan_id` and to `users_customuser` via `owner_id`.
2.  I found the latest transaction date for each `plan_id` by grouping the `savings_savingsaccount` table by `plan_id` and finding the `MAX(transaction_date)`.
3.  I joined this result back to the `plans_plan` table to get plan details like `plan_id`, `owner_id`, and plan `type`. I inferred the plan type (Savings/Investment) based on the plan name or other flags if available, or simply included the plan `name` field.
4.  For plans with no transactions in `savings_savingsaccount` (meaning `MAX(transaction_date)` would be `NULL`), I needed to include them if the plan itself was considered "active". Since the prompt asks for *active accounts* with no *inflow transactions*, I performed a `LEFT JOIN` from `plans_plan` to the aggregated savings transactions.
5.  I filtered for plans where the latest transaction date was more than 365 days ago or was `NULL` (indicating no savings transactions ever). I calculated the number of inactivity days using `DATEDIFF(CURDATE(), latest_transaction_date)`. For plans with no transactions, I needed to handle the `NULL` `latest_transaction_date` to show inactivity, potentially using `COALESCE` or conditional logic in the `WHERE` clause.
6.  The required output included `plan_id`, `owner_id`, `type`, `last_transaction_date`, and `inactivity_days`. I selected these fields accordingly, ensuring the `last_transaction_date` was `NULL` for plans with no savings transactions.

### Assessment_Q4.sql: Customer Lifetime Value (CLV) Estimation

**Scenario:** This question required estimating a simplified CLV for each customer based on their account tenure and the value of their deposit transactions, assuming a profit margin.

**Approach:**
1.  I needed customer signup dates (`date_joined`) from `users_customuser` and deposit transaction amounts (`confirmed_amount`) from `savings_savingsaccount`, linking them via `owner_id`.
2.  I calculated the account tenure in months for each customer using `TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE())`.
3.  I counted the total number of transactions for each customer by counting rows in `savings_savingsaccount` per user.
4.  I calculated the total profit generated from savings transactions for each customer. The assumption was a profit of 0.1% of the transaction value (`confirmed_amount`). Since all amount fields are in kobo, I calculated the profit in kobo as `SUM(sa.confirmed_amount * 0.001)`.
5.  The CLV formula given was `(total_transactions / tenure) * 12 * avg_profit_per_transaction`. As we discussed, this simplifies to `(SUM(confirmed_amount) * 0.001) / tenure_months * 12`. Since the result should likely be in the primary currency and the amounts are in kobo (100 kobo = 1 unit), I divided the total profit in kobo by 100 to get total profit in the primary currency before applying the rest of the formula. The simplified formula I used is `(SUM(confirmed_amount) * 0.001 / 100) / tenure_months * 12`, which further simplifies to `(SUM(confirmed_amount) * 0.00001 / tenure_months) * 12`.
6.  I handled edge cases:
    *   Customers with no transactions: The `SUM(sa.confirmed_amount)` would be `NULL`. I used `COALESCE(SUM(sa.confirmed_amount), 0)` to ensure the calculation used 0 profit for these users, resulting in a CLV of 0.
    *   Users with 0 months tenure: Similar to Q2, this would cause division by zero. I used `GREATEST(1, tenure_months)` for the denominator to treat the minimum tenure as 1 month for the calculation.
7.  I grouped the results by customer (`customer_id`, `name`) and calculated the required values.
8.  Finally, I ordered the results by the calculated `estimated_clv` from highest to lowest.

## Challenges

Throughout the assessment, I encountered a few challenges common when working with new database schemas and business logic assumptions.

*   **Schema Understanding:** Initially, mapping the relationships between tables and understanding which table contained the specific data points needed (e.g., which table had inflow/outflow, which had plan types) required careful review of the provided column lists and the hints.
*   **Interpreting Requirements:** Some requirements, like "funded savings plan" or the specific interpretation of the CLV formula components, needed careful consideration to translate into precise SQL logic. My interpretation of the CLV formula simplifying was key here.
*   **Handling `NULL`s and Outliers:** As highlighted in Q2, Q3, and Q4, dealing with potential `NULL` values from `LEFT JOIN`s (e.g., customers with no transactions in Q1 and Q4, plans with no savings transactions in Q3) and preventing division by zero (Q2, Q4) required specific functions like `COALESCE` and `GREATEST`. Forgetting these would lead to incorrect or error-producing queries.
*   **Amount Units:** Remembering that all amount fields are in kobo was crucial, especially for Q4 where profit calculation and conversion to the primary currency were necessary.

Overall, i needed to read and reread the assessment details, understand the table structure, and the logic behind the calculation while accounting for potential calculation errors.
