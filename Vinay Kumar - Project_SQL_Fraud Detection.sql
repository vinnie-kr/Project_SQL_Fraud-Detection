-- Task 1 : Customer Risk Analysis: Identify customers with low credit scores and high-risk loans to predict potential defaults and prioritize risk mitigation strategies. BASIC

SELECT c.customer_id, c.name, c.credit_score, l.loan_amount, l.default_risk
FROM customer c
JOIN loan l ON c.customer_id = l.customer_id
WHERE c.credit_score < (SELECT AVG(credit_score) FROM customer) AND l.default_risk = 'High'
ORDER BY c.credit_score ASC, l.loan_amount DESC;


-- Task 2 :  Loan Purpose Insights: Determine the most popular loan purposes and their associated revenues to align fi nancial products with customer demands. BASIC

SELECT 
    loan_purpose,
    COUNT(*) AS number_of_loans,
    SUM(loan_amount) AS total_amount_disbursed,
    AVG(loan_amount) AS average_loan_size,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM loan) * 100, 2) AS percentage_of_total,
    SUM(CASE WHEN default_risk = 'High' THEN 1 ELSE 0 END) AS high_risk_count,
    ROUND(SUM(CASE WHEN default_risk = 'High' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS high_risk_percentage
FROM loan
GROUP BY loan_purpose
ORDER BY total_amount_disbursed DESC;


-- Task 3 :  High-Value Transactions: Detect transactions that exceed 30% of their respective loan amounts to fl ag potential fraudulent activities. BASIC

SELECT 
    t.transaction_id,
    t.loan_id,
    l.customer_id,
    c.name,
    t.transaction_amount,
    l.loan_amount,
    ROUND((t.transaction_amount / l.loan_amount) * 100, 2) AS percentage_of_loan,
    t.transaction_type,
    DATE_FORMAT(t.transaction_date, '%Y-%m-%d') AS transaction_date,
    CASE 
        WHEN (t.transaction_amount / l.loan_amount) > 0.3 THEN 'FLAG - High Value Transaction'
        ELSE 'Normal Transaction'
    END AS fraud_flag
FROM transaction t
JOIN loan l ON t.loan_id = l.loan_id
JOIN customer c ON l.customer_id = c.customer_id
WHERE (t.transaction_amount / l.loan_amount) > 0.3
ORDER BY percentage_of_loan DESC;


-- Task 4 :  Missed EMI Count: Analyze the number of missed EMIs per loan to identify loans at risk of default and suggest intervention strategies. BASIC

SELECT 
    l.loan_id,
    c.customer_id,
    c.name,
    l.loan_amount,
    l.loan_purpose,
    SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) AS missed_payments,
    COUNT(t.transaction_id) AS total_payments,
    ROUND((SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) / COUNT(t.transaction_id)) * 100, 2) AS missed_payment_percentage,
    CASE 
        WHEN SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) > 3 THEN 'High Risk - Immediate Action'
        WHEN SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) > 1 THEN 'Medium Risk - Follow Up'
        ELSE 'Low Risk - Monitor'
    END AS risk_assessment
FROM loan l
JOIN customer c ON l.customer_id = c.customer_id
LEFT JOIN transaction t ON l.loan_id = t.loan_id
GROUP BY l.loan_id, c.customer_id, c.name, l.loan_amount, l.loan_purpose
ORDER BY missed_payments DESC;


-- Task 5 :  Regional Loan Distribution: Examine the geographical distribution of loan disbursements to assess regional trends and business opportunities. INTERMEDIATE

SELECT 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(c.address, ',', -2), ',', 1)) AS state,
    TRIM(SUBSTRING_INDEX(c.address, ',', -1)) AS country,
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_amount,
    ROUND(AVG(l.loan_amount), 2) AS average_loan,
    ROUND(AVG(c.credit_score), 2) AS avg_credit_score,
    SUM(CASE WHEN l.default_risk = 'High' THEN 1 ELSE 0 END) AS high_risk_loans,
    ROUND((SUM(CASE WHEN l.default_risk = 'High' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS default_rate
FROM customer c
JOIN loan l ON c.customer_id = l.customer_id
GROUP BY state, country
ORDER BY total_amount DESC;


-- Task 6 :  Loyal Customers: List customers who have been associated with Cross River Bank for over fi ve years and evaluate their loan activity to design loyalty programs. INTERMEDIATE

SELECT 
    c.customer_id,
    c.name,
    c.customer_since,
    TIMESTAMPDIFF(YEAR, c.customer_since, CURDATE()) AS years_as_customer,
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_borrowed,
    ROUND(AVG(l.loan_amount), 2) AS average_loan,
    SUM(CASE WHEN l.default_risk = 'Low' THEN 1 ELSE 0 END) AS good_standing_loans,
    ROUND((SUM(CASE WHEN l.default_risk = 'Low' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS good_standing_rate
FROM customer c
LEFT JOIN loan l ON c.customer_id = l.customer_id
WHERE TIMESTAMPDIFF(YEAR, c.customer_since, CURDATE()) > 5
GROUP BY c.customer_id, c.name, c.customer_since
ORDER BY years_as_customer DESC, total_borrowed DESC;


-- Task 7 :  High-Performing Loans: Identify loans with excellent repayment histories to refi ne lending policies and highlight successful products. INTERMEDIATE

SELECT 
    l.loan_id,
    c.customer_id,
    c.name,
    l.loan_amount,
    l.loan_purpose,
    COUNT(t.transaction_id) AS total_payments,
    SUM(CASE WHEN t.transaction_type = 'On Time Payment' THEN 1 ELSE 0 END) AS on_time_payments,
    SUM(CASE WHEN t.transaction_type = 'Early Payment' THEN 1 ELSE 0 END) AS early_payments,
    SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) AS missed_payments,
    ROUND((SUM(CASE WHEN t.transaction_type = 'On Time Payment' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS on_time_percentage,
    CASE 
        WHEN SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) = 0 
             AND SUM(CASE WHEN t.transaction_type = 'Early Payment' THEN 1 ELSE 0 END) > 0 THEN 'Excellent - Early Repayments'
        WHEN SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) = 0 THEN 'Excellent - On Time'
        ELSE 'Needs Review'
    END AS performance_rating
FROM loan l
JOIN customer c ON l.customer_id = c.customer_id
LEFT JOIN transaction t ON l.loan_id = t.loan_id
GROUP BY l.loan_id, c.customer_id, c.name, l.loan_amount, l.loan_purpose
HAVING SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) = 0
ORDER BY l.loan_amount DESC;


-- Task 8 :  Age-Based Loan Analysis: Analyze loan amounts disbursed to customers of different age groups to design targeted fi nancial products. INTERMEDIATE

SELECT 
    CASE 
        WHEN c.age < 25 THEN '18-24'
        WHEN c.age BETWEEN 25 AND 34 THEN '25-34'
        WHEN c.age BETWEEN 35 AND 44 THEN '35-44'
        WHEN c.age BETWEEN 45 AND 54 THEN '45-54'
        WHEN c.age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS age_group,
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_amount,
    ROUND(AVG(l.loan_amount), 2) AS average_loan,
    MIN(l.loan_amount) AS min_loan,
    MAX(l.loan_amount) AS max_loan,
    ROUND(AVG(c.credit_score), 2) AS avg_credit_score,
    SUM(CASE WHEN l.default_risk = 'High' THEN 1 ELSE 0 END) AS high_risk_loans,
    ROUND((SUM(CASE WHEN l.default_risk = 'High' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS default_rate
FROM customer c
JOIN loan l ON c.customer_id = l.customer_id
GROUP BY age_group
ORDER BY 
    CASE age_group
        WHEN '18-24' THEN 1
        WHEN '25-34' THEN 2
        WHEN '35-44' THEN 3
        WHEN '45-54' THEN 4
        WHEN '55-64' THEN 5
        ELSE 6
    END;


-- Task 9 :  Seasonal Transaction Trends: Examine transaction patterns over years and months to identify seasonal trends in loan repayments. Advanced

SELECT 
    YEAR(transaction_date) AS year,
    MONTH(transaction_date) AS month,
    MONTHNAME(transaction_date) AS month_name,
    COUNT(*) AS transaction_count,
    SUM(transaction_amount) AS total_amount,
    ROUND(AVG(transaction_amount), 2) AS average_amount,
    SUM(CASE WHEN transaction_type = 'On Time Payment' THEN 1 ELSE 0 END) AS on_time_payments,
    SUM(CASE WHEN transaction_type = 'Early Payment' THEN 1 ELSE 0 END) AS early_payments,
    SUM(CASE WHEN transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) AS missed_payments,
    ROUND((SUM(CASE WHEN transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS missed_payment_rate
FROM transaction
GROUP BY YEAR(transaction_date), MONTH(transaction_date), MONTHNAME(transaction_date)
ORDER BY year, month;


-- Task 10 :  Fraud Detection: Highlight potential fraud by identifying mismatches between customer address locations and transaction IP locations. Advanced

SELECT 
    b.customer_id,
    c.name,
    c.address,
    b.ip_address,
    b.timestamp,
    b.action,
    b.location,
    CASE 
        WHEN c.address LIKE '%New York%' AND b.ip_address NOT LIKE '%.ny%.%' THEN 'Possible Fraud - NY Mismatch'
        WHEN c.address LIKE '%California%' AND b.ip_address NOT LIKE '%.ca%.%' THEN 'Possible Fraud - CA Mismatch'
        WHEN c.address LIKE '%Texas%' AND b.ip_address NOT LIKE '%.tx%.%' THEN 'Possible Fraud - TX Mismatch'
        WHEN c.address LIKE '%Florida%' AND b.ip_address NOT LIKE '%.fl%.%' THEN 'Possible Fraud - FL Mismatch'
        WHEN c.address LIKE '%Illinois%' AND b.ip_address NOT LIKE '%.il%.%' THEN 'Possible Fraud - IL Mismatch'
        ELSE 'No Flag'
    END AS fraud_flag
FROM behavior_logs b
JOIN customer c ON b.customer_id = c.customer_id
WHERE 
    (c.address LIKE '%New York%' AND b.ip_address NOT LIKE '%.ny%.%') OR
    (c.address LIKE '%California%' AND b.ip_address NOT LIKE '%.ca%.%') OR
    (c.address LIKE '%Texas%' AND b.ip_address NOT LIKE '%.tx%.%') OR
    (c.address LIKE '%Florida%' AND b.ip_address NOT LIKE '%.fl%.%') OR
    (c.address LIKE '%Illinois%' AND b.ip_address NOT LIKE '%.il%.%')
ORDER BY b.timestamp DESC;


-- Task 11 :  Repayment History Analysis: Rank loans by repayment performance using window functions. Advanced

SELECT 
    loan_id,
    customer_id,
    name,
    loan_amount,
    loan_purpose,
    total_payments,
    on_time_payments,
    early_payments,
    missed_payments,
    repayment_percentage,
    performance_rank,
    repayment_quality
FROM (
    SELECT 
        l.loan_id,
        c.customer_id,
        c.name,
        l.loan_amount,
        l.loan_purpose,
        COUNT(t.transaction_id) AS total_payments,
        SUM(CASE WHEN t.transaction_type = 'On Time Payment' THEN 1 ELSE 0 END) AS on_time_payments,
        SUM(CASE WHEN t.transaction_type = 'Early Payment' THEN 1 ELSE 0 END) AS early_payments,
        SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) AS missed_payments,
        ROUND((SUM(t.transaction_amount) / l.loan_amount) * 100, 2) AS repayment_percentage,
        DENSE_RANK() OVER (ORDER BY (SUM(CASE WHEN t.transaction_type = 'On Time Payment' THEN 1 ELSE 0 END) / 
                          NULLIF(COUNT(t.transaction_id), 0)) DESC) AS performance_rank,
        CASE 
            WHEN SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) = 0 AND 
                 SUM(CASE WHEN t.transaction_type = 'Early Payment' THEN 1 ELSE 0 END) > 
                 (COUNT(t.transaction_id) * 0.5) THEN 'Excellent - Frequent Early Repayments'
            WHEN SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) = 0 THEN 'Excellent - On Time'
            WHEN (SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) / 
                 NULLIF(COUNT(t.transaction_id), 0)) < 0.1 THEN 'Good - Rare Missed Payments'
            WHEN (SUM(CASE WHEN t.transaction_type = 'Missed Payment' THEN 1 ELSE 0 END) / 
                 NULLIF(COUNT(t.transaction_id), 0)) < 0.3 THEN 'Fair - Some Missed Payments'
            ELSE 'Poor - Frequent Missed Payments'
        END AS repayment_quality
    FROM loan l
    JOIN customer c ON l.customer_id = c.customer_id
    LEFT JOIN transaction t ON l.loan_id = t.loan_id
    GROUP BY l.loan_id, c.customer_id, c.name, l.loan_amount, l.loan_purpose
) AS loan_stats
ORDER BY performance_rank;


-- Task 12 :  Credit Score vs. Loan Amount: Compare average loan amounts for different credit score ranges. Advanced

SELECT 
    CASE 
        WHEN c.credit_score < 580 THEN 'Poor (300-579)'
        WHEN c.credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
        WHEN c.credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
        WHEN c.credit_score BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
        WHEN c.credit_score >= 800 THEN 'Excellent (800-850)'
        ELSE 'Unknown'
    END AS credit_score_range,
    COUNT(l.loan_id) AS number_of_loans,
    ROUND(AVG(l.loan_amount), 2) AS average_loan_amount,
    MIN(l.loan_amount) AS min_loan_amount,
    MAX(l.loan_amount) AS max_loan_amount,
    SUM(l.loan_amount) AS total_amount_disbursed,
    SUM(CASE WHEN l.default_risk = 'High' THEN 1 ELSE 0 END) AS high_risk_loans,
    ROUND((SUM(CASE WHEN l.default_risk = 'High' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS default_rate
FROM customer c
JOIN loan l ON c.customer_id = l.customer_id
GROUP BY credit_score_range
ORDER BY 
    CASE credit_score_range
        WHEN 'Excellent (800-850)' THEN 1
        WHEN 'Very Good (740-799)' THEN 2
        WHEN 'Good (670-739)' THEN 3
        WHEN 'Fair (580-669)' THEN 4
        WHEN 'Poor (300-579)' THEN 5
        ELSE 6
    END;


-- Task 13 :  Top Borrowing Regions: Identify regions with the highest total loan disbursements. Advanced

SELECT 
    state,
    country,
    total_loan_amount,
    loan_count,
    avg_loan_size,
    high_risk_count,
    default_rate,
    RANK() OVER (ORDER BY total_loan_amount DESC) AS rank_by_volume,
    RANK() OVER (ORDER BY loan_count DESC) AS rank_by_frequency,
    RANK() OVER (ORDER BY default_rate DESC) AS rank_by_risk
FROM (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(c.address, ',', -2), ',', 1)) AS state,
        TRIM(SUBSTRING_INDEX(c.address, ',', -1)) AS country,
        SUM(l.loan_amount) AS total_loan_amount,
        COUNT(l.loan_id) AS loan_count,
        ROUND(AVG(l.loan_amount), 2) AS avg_loan_size,
        SUM(CASE WHEN l.default_risk = 'High' THEN 1 ELSE 0 END) AS high_risk_count,
        ROUND((SUM(CASE WHEN l.default_risk = 'High' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS default_rate
    FROM customer c
    JOIN loan l ON c.customer_id = l.customer_id
    GROUP BY state, country
) AS regional_data
ORDER BY total_loan_amount DESC
LIMIT 10;


-- Task 14 :  Early Repayment Patterns: Detect loans with frequent early repayments and their impact on revenue. Advanced

SELECT 
    loan_id,
    customer_id,
    name,
    loan_amount,
    loan_purpose,
    interest_rate,
    total_payments,
    early_payments,
    early_payment_percentage,
    CASE 
        WHEN (early_payments / total_payments) > 0.75 THEN 'Frequent Early Repayer'
        WHEN (early_payments / total_payments) > 0.5 THEN 'Regular Early Repayer'
        WHEN (early_payments / total_payments) > 0.25 THEN 'Occasional Early Repayer'
        ELSE 'Rare Early Repayer'
    END AS early_repayment_profile
FROM (
    SELECT 
        l.loan_id,
        c.customer_id,
        c.name,
        l.loan_amount,
        l.loan_purpose,
        l.interest_rate,
        COUNT(t.transaction_id) AS total_payments,
        SUM(CASE WHEN t.transaction_type = 'Early Payment' THEN 1 ELSE 0 END) AS early_payments,
        ROUND((SUM(CASE WHEN t.transaction_type = 'Early Payment' THEN 1 ELSE 0 END) / COUNT(t.transaction_id)) * 100, 2) AS early_payment_percentage
    FROM loan l
    JOIN customer c ON l.customer_id = c.customer_id
    JOIN transaction t ON l.loan_id = t.loan_id
    GROUP BY l.loan_id, c.customer_id, c.name, l.loan_amount, l.loan_purpose, l.interest_rate
    HAVING SUM(CASE WHEN t.transaction_type = 'Early Payment' THEN 1 ELSE 0 END) > 0
) AS early_repayment_stats
ORDER BY early_payment_percentage DESC;


-- Task 15 :  Feedback Correlation: Correlate customer feedback sentiment scores with loan statuses. Advanced

SELECT 
    ROUND(f.sentiment_score, 2) AS sentiment_score,
    CASE 
        WHEN f.sentiment_score < -0.5 THEN 'Very Negative'
        WHEN f.sentiment_score BETWEEN -0.5 AND -0.1 THEN 'Negative'
        WHEN f.sentiment_score BETWEEN -0.1 AND 0.1 THEN 'Neutral'
        WHEN f.sentiment_score BETWEEN 0.1 AND 0.5 THEN 'Positive'
        ELSE 'Very Positive'
    END AS sentiment_category,
    COUNT(*) AS feedback_count,
    ROUND(AVG(l.loan_amount), 2) AS avg_loan_amount,
    SUM(CASE WHEN l.default_risk = 'High' THEN 1 ELSE 0 END) AS high_risk_loans,
    SUM(CASE WHEN l.default_risk = 'Low' THEN 1 ELSE 0 END) AS low_risk_loans,
    ROUND((SUM(CASE WHEN l.default_risk = 'High' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS high_risk_percentage,
    GROUP_CONCAT(DISTINCT f.feedback_category SEPARATOR ', ') AS common_categories
FROM customer_feedback f
JOIN loan l ON f.loan_id = l.loan_id
GROUP BY sentiment_category, ROUND(f.sentiment_score, 2)
ORDER BY sentiment_score;