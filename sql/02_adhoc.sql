-- 02_adhoc.sql
-- Набор ad-hoc задач поверх витрины ds_ecom.product_user_features.

/*
Задача 1. Сегментация пользователей по количеству заказов.
Считаем размер каждого сегмента, среднее число заказов и среднюю стоимость заказа.
*/
WITH user_segments AS (
    SELECT
        user_id,
        total_orders,
        avg_order_cost,
        CASE
            WHEN total_orders = 1 THEN '1 заказ'
            WHEN total_orders BETWEEN 2 AND 5 THEN '2-5 заказов'
            WHEN total_orders BETWEEN 6 AND 10 THEN '6-10 заказов'
            ELSE '11 и более заказов'
        END AS segment
    FROM ds_ecom.product_user_features
)
SELECT
    segment,
    COUNT(user_id) AS total_users,
    ROUND(AVG(total_orders), 2) AS avg_orders_per_user,
    ROUND(AVG(avg_order_cost), 2) AS avg_order_cost
FROM user_segments
GROUP BY segment
ORDER BY
    CASE
        WHEN segment = '1 заказ' THEN 1
        WHEN segment = '2-5 заказов' THEN 2
        WHEN segment = '6-10 заказов' THEN 3
        ELSE 4
    END;

/*
Задача 2. Ранжирование пользователей с 3+ заказами.
Выводим топ-15 по среднему чеку (avg_order_cost) и добавляем ранг.
*/
SELECT
    ROW_NUMBER() OVER (ORDER BY avg_order_cost DESC) AS rank_num,
    user_id,
    total_orders,
    avg_order_cost
FROM ds_ecom.product_user_features
WHERE total_orders >= 3
ORDER BY avg_order_cost DESC
LIMIT 15;

/*
Задача 3. Сводка по регионам.
Считаем размер клиентской базы, число заказов, средний чек, доли рассрочки/промо и долю пользователей с отменами.
*/
SELECT
    region,
    COUNT(DISTINCT user_id) AS total_users,
    SUM(total_orders) AS total_orders,
    ROUND(AVG(total_order_costs::NUMERIC / total_orders), 2) AS avg_order_cost_per_user,
    ROUND(SUM(num_installment_orders)::NUMERIC / SUM(total_orders), 4) AS installment_share,
    ROUND(SUM(num_orders_with_promo)::NUMERIC / SUM(total_orders), 4) AS promo_share,
    ROUND(SUM(used_cancel)::NUMERIC / COUNT(DISTINCT user_id), 4) AS canceled_share
FROM ds_ecom.product_user_features
GROUP BY region
ORDER BY total_orders DESC;

/*
Задача 4. Когорты по месяцу первого заказа в 2023 году.
Для каждой когорты считаем пользователей, заказы, средний чек, рейтинг, долю users с денежным переводом и средний lifetime.
*/
WITH first_orders_2023 AS (
    SELECT
        user_id,
        first_order_ts,
        EXTRACT(MONTH FROM first_order_ts) AS first_order_month,
        total_orders,
        avg_order_cost,
        avg_order_rating,
        used_money_transfer,
        lifetime
    FROM ds_ecom.product_user_features
    WHERE EXTRACT(YEAR FROM first_order_ts) = 2023
)
SELECT
    first_order_month,
    COUNT(user_id) AS total_users,
    SUM(total_orders) AS total_orders,
    ROUND(AVG(avg_order_cost), 4) AS avg_order_cost,
    ROUND(AVG(avg_order_rating), 4) AS avg_order_rating,
    ROUND(SUM(used_money_transfer)::NUMERIC / COUNT(user_id), 4) AS money_transfer_users_share,
    EXTRACT(DAY FROM AVG(lifetime)) AS avg_lifetime_days
FROM first_orders_2023
GROUP BY first_order_month
ORDER BY first_order_month;
