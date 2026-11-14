# MODO — Monitoring & Grafana Dashboards

This directory contains the complete, automated observability stack for the MODO backend:
**PostgreSQL + postgres-exporter + Prometheus + Grafana**, plus application metrics exposed
through Spring Boot Actuator / Micrometer (Prometheus endpoint).

## Services & URLs

Bring the whole stack up from `backend/modo-backend/`:

```bash
docker compose up -d
```

| Service | URL | Credentials | Notes |
|---------|-----|-------------|-------|
| Grafana | http://localhost:3000 | admin / admin123 | Auto-loads dashboards + datasources |
| Prometheus | http://localhost:9090 | — | Scrapes postgres-exporter + modo-backend |
| PostgreSQL | localhost:5432 | modo_user / modo_dev_password | DB: modo_db |
| pgAdmin | http://localhost:5050 | hassine@gmail.com / admin123 | GUI for PostgreSQL |
| Backend (Actuator) | http://localhost:8080/actuator/prometheus | — | App metrics (Prometheus format) |
| Backend health | http://localhost:8080/actuator/health | — | App health |

## What is provisioned automatically

All files under `monitoring/` are mounted into the containers, so **no manual Grafana
clicking is required**:

* `grafana/datasources/prometheus.yml` → Prometheus datasource (default)
* `grafana/datasources/postgres.yml` → PostgreSQL datasource (`postgres:5432/modo_db`)
* `grafana/datasources/dashboards/dashboard.yml` → file-based dashboard provider
* `grafana/dashboards/*.json` → dashboards auto-loaded into Grafana
* `prometheus.yml` → Prometheus scrape configuration

## Grafana dashboards (auto-loaded)

### 1. PostgreSQL Overview (`postgres-overview.json`)
Datasources: **Prometheus** (postgres-exporter metrics) + **PostgreSQL** (raw SQL).

| Panel | Datasource | Detail |
|-------|-----------|--------|
| Database Size | Prometheus | `pg_database_size_bytes` for the selected DB |
| Active / Total / Idle Connections | Prometheus | `pg_connections` by state |
| Transactions Committed / s | Prometheus | `rate(pg_transactions_committed_total)` |
| Transactions Rolled Back / s | Prometheus | `rate(pg_transactions_rolledback_total)` |
| Rows Returned / Fetched per s | Prometheus | `rate(pg_tuples_*_total)` |
| Dead Tuples | Prometheus | `pg_dead_tuples` |
| Cache Hit Ratio | Prometheus | buffer cache hit ratio |
| Top Tables by Size | PostgreSQL | raw SQL against `pg_tables` |
| Row Counts by Table | PostgreSQL | raw SQL against `pg_stat_user_tables` |

A **`database`** template variable (queried from Prometheus) lets you switch the
database context (default `modo_db`).

### 2. Application Overview (`application-overview.json`)
Datasource: **Prometheus** (Spring Boot Actuator / Micrometer).

| Panel | Datasource | Detail |
|-------|-----------|--------|
| JVM Heap / Non-Heap Used & Max | Prometheus | `jvm_memory_used_bytes` / `jvm_memory_max_bytes` |
| GC Count & Time | Prometheus | `jvm_gc_collection_seconds_*` |
| Live / Peak / Runnable Threads | Prometheus | `jvm_threads_*` |
| Process Uptime | Prometheus | `process_uptime_seconds` |
| HTTP Request Rate | Prometheus | `rate(http_server_requests_seconds_count)` |
| HTTP Request Duration (avg) | Prometheus | sum/count of request seconds |
| HTTP 4xx / 5xx Error Rate | Prometheus | by status class |
| HikariCP Active / Idle / Max / Pending | Prometheus | connection pool metrics |
| Tomcat Threads Busy / Current | Prometheus | `tomcat_threads_*` |
| Hibernate Entities Loaded / Queries | Prometheus | `hibernate_*_total` |

## Application metrics setup (already applied)

The backend now exposes Prometheus metrics:

* `pom.xml`: added `io.micrometer:micrometer-registry-prometheus`
* `application.properties`:
  * `management.endpoints.web.exposure.include=health,info,metrics,prometheus`
  * `management.metrics.export.prometheus.enabled=true`
  * Hibernate / JDBC / Tomcat / process metrics enabled
  * `spring.datasource.hikari.register-mbeans=true`
* `src/main/java/com/modo/modo_backend/config/SecurityConfig.java` — new class that permits unauthenticated access to `/actuator/**` so Prometheus can scrape `/actuator/prometheus` (without this, Spring Security returns an HTML login page and Prometheus reports "unsupported Content-Type text/html")
* `docker-compose.yml`: added `modo-backend` service (port 8080, connects to compose `postgres`)
* `prometheus.yml`: added `modo-backend` job scraping `:8080/actuator/prometheus`

* `pom.xml`: added `io.micrometer:micrometer-registry-prometheus`
* `application.properties`:
  * `management.endpoints.web.exposure.include=health,info,metrics,prometheus`
  * `management.metrics.export.prometheus.enabled=true`
  * Hibernate / JDBC / Tomcat / process metrics enabled
  * `spring.datasource.hikari.register-mbeans=true`
* `docker-compose.yml`: added `modo-backend` service (port 8080, connects to compose `postgres`)
* `prometheus.yml`: added `modo-backend` job scraping `:8080/actuator/prometheus`

## Notes & tuning

* Exact Prometheus metric names (e.g. `pg_connections`, `hikaricp_connections_active`,
  `tomcat_threads_busy`) depend on the **postgres-exporter** and **Micrometer/Spring Boot**
  versions. If a panel shows "No data", open Prometheus → Status → Targets to confirm the
  scrape is healthy, then check `http://localhost:9090/api/v1/query?query=<metric>` for the
  exact metric name and update the dashboard panel query.
* Query-level Postgres detail (top slow queries) requires `pg_stat_statements` enabled in
  PostgreSQL. It is intentionally not required here; enable the extension in `postgres` if
  you want slow-query panels.
* The backend `application.properties` still targets `172.18.187.50:5432` by default; the
  `modo-backend` compose service overrides `SPRING_DATASOURCE_URL` to `jdbc:postgresql://postgres:5432/modo_db`
  when running under Docker Compose.
