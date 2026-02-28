.PHONY: up down wait init seed mart adhoc run check psql logs reset

up:
	docker compose up -d
	$(MAKE) wait

wait:
	@echo "Waiting for postgres to become ready..."
	@for i in $$(seq 1 30); do \
		if docker compose exec -T postgres pg_isready -U postgres -d demo >/dev/null 2>&1; then \
			echo "Postgres is ready"; \
			exit 0; \
		fi; \
		sleep 1; \
	done; \
	echo "Postgres did not become ready in time"; \
	exit 1

down:
	docker compose down

init:
	docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U postgres -d demo -f /sql/00_init_schema.sql

seed:
	docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U postgres -d demo -f /sql/00_seed.sql

mart:
	docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U postgres -d demo -f /sql/01_mart.sql

adhoc:
	docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U postgres -d demo -f /sql/02_adhoc.sql

run: init seed mart adhoc

check:
	docker compose exec -T postgres psql -U postgres -d demo -c "SELECT COUNT(*) AS mart_rows FROM ds_ecom.product_user_features;"
	docker compose exec -T postgres psql -U postgres -d demo -c "SELECT region, SUM(total_orders) AS total_orders FROM ds_ecom.product_user_features GROUP BY region ORDER BY total_orders DESC;"

psql:
	docker compose exec postgres psql -U postgres -d demo

logs:
	docker compose logs -f postgres

reset:
	docker compose down -v
