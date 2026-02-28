-- 01_mart.sql
-- Витрина пользовательских признаков для e-commerce аналитики.

CREATE SCHEMA IF NOT EXISTS ds_ecom;

DROP MATERIALIZED VIEW IF EXISTS ds_ecom.product_user_features;

CREATE MATERIALIZED VIEW ds_ecom.product_user_features AS
WITH filtered_orders AS (
    SELECT
        o.order_id,
        o.buyer_id,
        o.order_status,
        o.order_purchase_ts,
        u.user_id,
        u.region
    FROM ds_ecom.orders o
    JOIN ds_ecom.users u USING (buyer_id)
    WHERE o.order_status IN ('Доставлено', 'Отменено')
),
top_regions AS (
    SELECT
        region
    FROM filtered_orders
    GROUP BY region
    ORDER BY COUNT(*) DESC
    LIMIT 3
),
filtered_orders_top_regions AS (
    SELECT
        fo.*
    FROM filtered_orders fo
    WHERE fo.region IN (SELECT tr.region FROM top_regions tr)
),
payment_info AS (
    SELECT
        op.order_id,
        MAX(CASE WHEN op.payment_sequential = 1 THEN op.payment_type END) AS first_payment_type,
        MAX(CASE WHEN op.payment_type = 'промокод' THEN 1 ELSE 0 END) AS has_promo_payment,
        MAX(CASE WHEN op.payment_installments > 1 THEN 1 ELSE 0 END) AS has_installments
    FROM ds_ecom.order_payments op
    GROUP BY op.order_id
),
order_costs AS (
    SELECT
        o.order_id,
        SUM(oi.price + oi.delivery_cost) AS total_cost
    FROM ds_ecom.orders o
    JOIN ds_ecom.order_items oi USING (order_id)
    WHERE o.order_status = 'Доставлено'
    GROUP BY o.order_id
),
avg_rating AS (
    SELECT
        orv.order_id,
        ROUND(AVG(CASE WHEN orv.review_score > 5 THEN orv.review_score / 10 ELSE orv.review_score END), 4) AS avg_order_rating
    FROM ds_ecom.order_reviews orv
    GROUP BY orv.order_id
),
user_order_stats AS (
    SELECT
        fo.user_id,
        fo.region,
        MIN(fo.order_purchase_ts) AS first_order_ts,
        MAX(fo.order_purchase_ts) AS last_order_ts,
        MAX(fo.order_purchase_ts) - MIN(fo.order_purchase_ts) AS lifetime,
        COUNT(*) AS total_orders,
        AVG(ar.avg_order_rating) AS avg_order_rating,
        COUNT(ar.avg_order_rating) AS num_orders_with_rating,
        COUNT(CASE WHEN fo.order_status = 'Отменено' THEN 1 END) AS num_canceled_orders,
        ROUND(COUNT(CASE WHEN fo.order_status = 'Отменено' THEN 1 END)::NUMERIC / COUNT(*), 4) AS canceled_orders_ratio
    FROM filtered_orders_top_regions fo
    LEFT JOIN avg_rating ar USING (order_id)
    GROUP BY
        fo.user_id,
        fo.region
),
user_costs AS (
    SELECT
        fo.user_id,
        fo.region,
        SUM(oc.total_cost) AS total_order_costs,
        ROUND(AVG(oc.total_cost), 2) AS avg_order_cost
    FROM filtered_orders_top_regions fo
    LEFT JOIN order_costs oc USING (order_id)
    GROUP BY
        fo.user_id,
        fo.region
),
user_payments AS (
    SELECT
        fo.user_id,
        fo.region,
        SUM(pi.has_promo_payment) AS num_orders_with_promo,
        SUM(pi.has_installments) AS num_installment_orders,
        MAX(CASE WHEN pi.first_payment_type = 'денежный перевод' THEN 1 ELSE 0 END) AS used_money_transfer,
        MAX(CASE WHEN pi.has_installments > 0 THEN 1 ELSE 0 END) AS used_installments
    FROM filtered_orders_top_regions fo
    LEFT JOIN payment_info pi USING (order_id)
    GROUP BY
        fo.user_id,
        fo.region
)
SELECT
    uos.user_id,
    uos.region,
    uos.first_order_ts,
    uos.last_order_ts,
    uos.lifetime,
    uos.total_orders,
    uos.avg_order_rating,
    uos.num_orders_with_rating,
    uos.num_canceled_orders,
    uos.canceled_orders_ratio,
    uc.total_order_costs,
    uc.avg_order_cost,
    up.num_installment_orders,
    up.num_orders_with_promo,
    up.used_money_transfer,
    up.used_installments,
    CASE WHEN uos.num_canceled_orders > 0 THEN 1 ELSE 0 END AS used_cancel
FROM user_order_stats uos
LEFT JOIN user_costs uc USING (user_id, region)
LEFT JOIN user_payments up USING (user_id, region)
ORDER BY uos.total_orders DESC
WITH DATA;
