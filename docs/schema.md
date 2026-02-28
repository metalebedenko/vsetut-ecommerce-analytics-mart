# Data Model

## Схема `ds_ecom`

### `users`
- Назначение: справочник пользователей и их региона.
- Ключевые поля: `buyer_id` (PK), `user_id` (UNIQUE), `region`.

### `orders`
- Назначение: факты заказов и их статусы.
- Ключевые поля: `order_id` (PK), `buyer_id` (FK -> `users.buyer_id`), `order_status`, `order_purchase_ts`.

### `order_items`
- Назначение: позиции заказа для расчета суммы заказа.
- Ключевые поля: `order_item_id` (PK), `order_id` (FK -> `orders.order_id`), `product_id`, `price`, `delivery_cost`.

### `order_payments`
- Назначение: способ оплаты и признаки промо/рассрочки.
- Ключевые поля: `(order_id, payment_sequential)` (PK), `payment_type`, `payment_installments`, `payment_value`.

### `order_reviews`
- Назначение: отзывы и рейтинг по заказам.
- Ключевые поля: `review_id` (PK), `order_id` (FK -> `orders.order_id`), `review_score`.

### `product_user_features` (materialized view)
- Назначение: витрина пользовательских фич для аналитики (заказы, чек, рейтинг, отмены, промо, рассрочка).
- Гранулярность: `user_id + region`.

## Связи
- `users 1 -> N orders`
- `orders 1 -> N order_items`
- `orders 1 -> N order_payments`
- `orders 1 -> N order_reviews`
