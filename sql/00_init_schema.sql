-- 00_init_schema.sql
-- Минимальная схема для воспроизведения витрины и ad-hoc аналитики.

DROP SCHEMA IF EXISTS ds_ecom CASCADE;
CREATE SCHEMA ds_ecom;

CREATE TABLE ds_ecom.users (
    buyer_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    region TEXT NOT NULL
);

CREATE TABLE ds_ecom.orders (
    order_id BIGINT PRIMARY KEY,
    buyer_id BIGINT NOT NULL REFERENCES ds_ecom.users (buyer_id),
    order_status TEXT NOT NULL,
    order_purchase_ts TIMESTAMP NOT NULL
);

CREATE TABLE ds_ecom.order_items (
    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES ds_ecom.orders (order_id),
    product_id BIGINT NOT NULL,
    price NUMERIC(12, 2) NOT NULL,
    delivery_cost NUMERIC(12, 2) NOT NULL
);

CREATE TABLE ds_ecom.order_payments (
    order_id BIGINT NOT NULL REFERENCES ds_ecom.orders (order_id),
    payment_sequential INT NOT NULL,
    payment_type TEXT NOT NULL,
    payment_installments INT NOT NULL,
    payment_value NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE ds_ecom.order_reviews (
    review_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES ds_ecom.orders (order_id),
    review_score NUMERIC(6, 2) NOT NULL
);

CREATE INDEX idx_orders_buyer_id ON ds_ecom.orders (buyer_id);
CREATE INDEX idx_orders_purchase_ts ON ds_ecom.orders (order_purchase_ts);
CREATE INDEX idx_order_items_order_id ON ds_ecom.order_items (order_id);
CREATE INDEX idx_order_payments_order_id ON ds_ecom.order_payments (order_id);
CREATE INDEX idx_order_reviews_order_id ON ds_ecom.order_reviews (order_id);
