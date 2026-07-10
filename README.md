# E-commerce Profitability Analytics

An end-to-end Analytics Engineering project built for a live technical walkthrough. It transforms BigQuery's public `thelook_ecommerce` data with dbt Core and exposes a BI-ready profitability mart to Looker Studio.

## Business question

Which products and customer segments create sustainable gross profit, rather than revenue alone?

Primary metric:

`Gross Profit = Net Revenue - Product Cost`

Cancelled and returned items contribute zero net revenue, zero recognized cost, and zero gross profit in this simplified analytical policy.

## Architecture and grain

- Staging: source-aligned cleanup, typing, naming, PII minimization.
- Intermediate: deterministic order-item deduplication.
- Dimensions: customers and products.
- Fact: one row per `order_item_id`, incrementally merged and partitioned by creation date.
- Reporting: daily profitability aggregates for direct BI consumption.

See [Architecture and Data Model](docs/architecture.md) for the layered flow, ERD, grain decisions, governance controls, trade-offs, and production extensions.

## Evaluation evidence

| Area | Evidence |
| --- | --- |
| Data Modeling | Layered dimensional model, documented grain, ERD, and dbt DAG |
| Transformation | Staging cleanup, deduplication, macro, and incremental merge |
| Governance | Generic tests, financial identity test, and SHA-256 email hashing |
| Insight | Governed gross-profit mart connected directly to Looker Studio |
| DataOps | Feature branches, pull requests, pinned dependencies, and GitHub Actions validation |

## Local Windows setup

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
gcloud auth application-default login
Copy-Item profiles.example.yml profiles.yml
# Replace YOUR_GCP_PROJECT_ID and dbt_yourname_dev in profiles.yml
dbt debug --profiles-dir .
dbt deps
dbt build --profiles-dir .
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```

## Useful demonstration commands

```powershell
dbt build --profiles-dir .
dbt run --profiles-dir . --select fct_order_items --full-refresh
dbt run --profiles-dir . --select fct_order_items
dbt test --profiles-dir . --select fct_order_items
dbt show --profiles-dir . --select mart_ecommerce_profitability --limit 10
```

The demo uses BigQuery Sandbox. The initial build is supported, while subsequent incremental `MERGE` execution is restricted because Sandbox does not support DML without billing. This limitation is documented rather than hidden.

Never commit `profiles.yml`, service-account JSON, access tokens, or passwords.
