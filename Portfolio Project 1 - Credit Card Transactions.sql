
/*
Credit card transcation data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/
USE sampledb;
SELECT *
FROM credit_card_transcations;

-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
   SELECT city,
  SUM(amount) AS total_spends,
  (SUM(amount) / (SELECT SUM(amount) FROM credit_card_transcations)) * 100 AS percentage_contribution
FROM
  credit_card_transcations
GROUP BY
  city
ORDER BY
  total_spends DESC
LIMIT 5;


-- 2- write a query to print highest spend month and amount spent in that month for each card type
WITH MonthlySpendCTE AS (
  SELECT card,
    EXTRACT(MONTH FROM date) AS month,
    SUM(amount) AS total_spent
  FROM
    credit_card_transcations
  GROUP BY
    card, EXTRACT(MONTH FROM date)
)

SELECT
  card,
  month,
  total_spent
FROM
  MonthlySpendCTE
WHERE
  (card, total_spent) IN (
    SELECT
      card,
      MAX(total_spent) AS max_spent
    FROM
      MonthlySpendCTE
    GROUP BY
      card
  );
  

-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
SELECT
    card,
    SUM(amount) AS total_spends
FROM
    credit_card_transcations
GROUP BY
    card
HAVING
    SUM(amount) >= 1000000;

-- 4- write a query to find city which had lowest percentage spend for gold card type
WITH CityTotalAmounts AS (
    SELECT 
        city,
        SUM(CASE WHEN card = 'gold' THEN amount ELSE 0 END) AS gold_card_total,
        SUM(amount) AS total_amount
    FROM 
        credit_card_transcations
    GROUP BY 
        city
)

SELECT 
    city,
    (gold_card_total / total_amount) * 100 AS lowest_percentage_spend
FROM 
    CityTotalAmounts
ORDER BY 
    lowest_percentage_spend
LIMIT 1;


-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
WITH CityExpenseTypes AS (
    SELECT 
        city,
        MAX(exp_type) AS highest_expense_type,
        MIN(exp_type) AS lowest_expense_type
    FROM 
        credit_card_transcations
    GROUP BY 
        city
)

SELECT 
    city,
    highest_expense_type,
    lowest_expense_type
FROM 
    CityExpenseTypes;


-- 6- write a query to find percentage contribution of spends by females for each expense type
SELECT 
    exp_type,
    (SUM(CASE WHEN gender = 'female' THEN amount ELSE 0 END) / SUM(amount)) * 100 AS percentage_contribution
FROM 
    credit_card_transcations
GROUP BY 
    exp_type;


-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
WITH MonthlySpends AS (
    SELECT 
        card,
        exp_type,
        SUM(amount) AS total_amount,
        DATE_FORMAT(date, '%Y-%m') AS month_year
    FROM 
        credit_card_transcations
    WHERE 
        DATE_FORMAT(date, '%Y-%m') = '2014-01'
    GROUP BY 
        card, exp_type, month_year
),
PreviousMonthSpends AS (
    SELECT 
        card,
        exp_type,
        SUM(amount) AS total_amount,
        DATE_FORMAT(date, '%Y-%m') AS month_year
    FROM 
        credit_card_transcations
    WHERE 
        DATE_FORMAT(date, '%Y-%m') = '2013-12'
    GROUP BY 
        card, exp_type, month_year
)

SELECT 
    current.card,
    current.exp_type,
    (current.total_amount - COALESCE(previous.total_amount, 0)) AS month_over_month_growth
FROM 
    MonthlySpends current
LEFT JOIN 
    PreviousMonthSpends previous
ON 
    current.card = previous.card
    AND current.exp_type = previous.exp_type
ORDER BY 
    month_over_month_growth DESC
LIMIT 1;

-- 8- during weekends which city has highest total spend to total no of transcations ratio 
WITH WeekendSpends AS (
    SELECT 
        city,
        SUM(amount) AS total_weekend_spend,
        COUNT(*) AS total_weekend_transactions
    FROM 
        credit_card_transcations
    WHERE 
        DAYOFWEEK(date) IN (1, 7) -- Assuming 1 is Sunday and 7 is Saturday
    GROUP BY 
        city
)

SELECT 
    city,
    CASE 
        WHEN total_weekend_transactions > 0 
        THEN total_weekend_spend / total_weekend_transactions 
        ELSE 0 
    END AS spend_to_transaction_ratio
FROM 
    WeekendSpends
ORDER BY 
    spend_to_transaction_ratio DESC
LIMIT 1;

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city
SELECT 
    city,
    MIN(days_to_500) AS min_days_to_500
FROM (
    SELECT 
        city,
        DATEDIFF(MAX(date), MIN(date)) AS days_to_500
    FROM 
        credit_card_transcations
    GROUP BY 
        city
    HAVING 
        COUNT(*) >= 500
) AS subquery
GROUP BY 
    city
ORDER BY 
    min_days_to_500
LIMIT 1;

