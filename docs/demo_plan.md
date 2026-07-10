# 90-minute interview demo plan

## Opening - 5 minutes

State the business question, metric, architecture, source, and modeling grain. Mention the simplifying assumptions before being asked.

## Data Modeling and Architecture - 15 minutes

Show the dbt DAG and folder layers. Explain why a dimensional model fits BI aggregation, why the fact grain is one order item, and how this prevents fanout. Walk through dimensions, fact, and reporting mart.

## Data Transformation - 15 minutes

Run `dbt build`. Show staging cleanup, deterministic deduplication, macro use, and the incremental merge. Explain the three-day lookback, partitioning, clustering, idempotency, and full-refresh trade-offs.

## Governance - 15 minutes

Run tests. Show uniqueness, not-null, accepted-values, relationships, and financial identity tests. Show that raw email never leaves staging and only its SHA-256 hash reaches the customer dimension. Explain that hashing is pseudonymization, not anonymization or authorization.

## Insight - 15 minutes

Open Looker Studio. Start with gross profit and margin trend, then product/category contribution, returns, and customer/acquisition segment filters. Trace one dashboard metric back to fact SQL and state its limitation.

## DataOps - 15 minutes

Show a feature branch, pull request, CI workflow, successful run, and protected `main`. Explain isolated developer/CI schemas, secret handling, review, rollback, and production scheduling.

## Final Q&A - 10 minutes

Keep answers in Show -> Why -> What-if form. If asked to modify code live, restate the new requirement and grain first, make the smallest safe change, run the affected model and tests, then explain production hardening.

