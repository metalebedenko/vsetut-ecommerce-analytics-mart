# VseTut E-commerce Analytics Mart

Воспроизводимый SQL-проект: витрина пользовательских фич маркетплейса и ad-hoc аналитика поверх PostgreSQL.

## Бизнес-ценность
- Сокращает time-to-insight: ключевые пользовательские признаки собраны в одной витрине.
- Поддерживает CRM/маркетинг-сценарии: сегментация по активности, отменам, промо и рассрочке.
- Дает основу для аналитики retention и LTV через cohort-срезы по первому заказу.

## Что сделано
- Построена витрина `ds_ecom.product_user_features` на уровне `user_id + region`.
- Добавлены 4 ad-hoc запроса: сегментация, ранжирование, региональная сводка, когорты.
- Подготовлены минимальная схема и synthetic seed для запуска без исходной учебной БД.

## Стек
- SQL (PostgreSQL 16)
- Docker Compose
- Makefile

## Структура
- `sql/00_init_schema.sql` - схема `ds_ecom`.
- `sql/00_seed.sql` - synthetic seed-данные.
- `sql/01_mart.sql` - materialized view витрины.
- `sql/02_adhoc.sql` - ad-hoc аналитические запросы.
- `docs/schema.md` - описание таблиц и связей.

## Быстрый старт
```bash
make up
make run
make check
```

## Проверка результата
- Витрина создается и непустая (`mart_rows > 0`).
- Все 4 ad-hoc запроса возвращают строки.

## Ключевые результаты (на synthetic seed)
- `mart_rows = 10` пользователей в финальной витрине.
- Витрина агрегирует top-3 региона по числу заказов: Санкт-Петербург, Москва, Новосибирск.
- Покрыты пользовательские фичи для скоринга и сегментации: `total_orders`, `avg_order_cost`, `canceled_orders_ratio`, `num_orders_with_promo`, `used_installments`, `avg_order_rating`.

## Полезные команды
```bash
make psql
make logs
make down
make reset
```

Примечание: внешний порт `5432` не пробрасывается, работа с БД идет через `docker compose exec` / `make psql`.
