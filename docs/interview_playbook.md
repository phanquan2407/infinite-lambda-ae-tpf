# Interview Playbook

Use this document as preparation material, not as a script to read word-for-word. During the interview, answer from the repository and the running system using **Show -> Why -> What-if**.

## Five-minute opening

> I built an ecommerce profitability analytics platform to answer one question: which products and customer segments create sustainable gross profit, rather than revenue alone?
>
> The source is BigQuery's public TheLook ecommerce dataset. dbt Core transforms it through staging, intermediate, dimensional, fact, and reporting layers. The final mart connects directly to Looker Studio.
>
> My canonical grain is one row per order item. At that grain, net revenue equals sale price after reversing cancelled and returned items, and gross profit equals net revenue minus recognized product cost. This lets the dashboard aggregate additive financial measures safely.
>
> I chose dimensional modeling because the primary consumer is BI. It gives understandable dimensions, predictable joins, and simple metric tracing. The fact is incremental, partitioned by creation date, and clustered for common access patterns.
>
> Governance includes key, relationship, accepted-value, and accounting-identity tests. Raw email is removed after staging and only a SHA-256 hash is exposed downstream. Code is managed through feature branches, pull requests, pinned dependencies, and GitHub Actions validation.
>
> I will walk through the architecture first, then transformation, governance, insights, and DataOps. For each area, I will show the implementation, explain the decision, and discuss how I would extend it in production.

## 1. Data Modeling and Architecture

### Show

- Open `docs/architecture.md`.
- Show the end-to-end Mermaid diagram and ERD.
- Open the dbt DAG.
- Open `fct_order_items.sql` and point to its grain and keys.
- Open the dimensions and reporting mart.

### Why

> I selected a dimensional model because the workload is analytical and BI-oriented. A fact at order-item grain makes revenue, cost, and profit additive while customer and product dimensions provide intuitive slicing. The layered dbt structure separates source cleanup from reusable logic and business-facing outputs, which improves ownership, testing, and change isolation.

### Likely questions

**Why order-item grain instead of order grain?**

> Product cost and category attributes exist at item level. Modeling directly at order grain would either lose product detail or require nested/repeated structures. Calculating financial measures at item grain also avoids allocating order revenue back to products.

**How do you prevent fanout?**

> I declare the grain before joining, test dimension keys for uniqueness, test foreign-key relationships, and join each dimension many-to-one into the fact. Metrics are calculated at fact grain before reporting aggregation.

**Why is the intermediate model ephemeral?**

> It is a small reusable transformation that is consumed by one downstream fact. Ephemeral avoids an unnecessary warehouse object. I would materialize it as a view or table if it gained multiple consumers, became expensive, or needed independent observability.

**Why not Data Vault?**

> Data Vault would provide stronger historization and source-system auditability, but it adds hubs, links, satellites, and business-vault complexity that is disproportionate for this single-source BI use case.

### What-if prompts

**Add marketing spend and ROAS**

1. Confirm campaign-spend grain: date, channel, and campaign.
2. Create `fct_marketing_spend` separately rather than joining spend directly to order items.
3. Create conformed date/channel dimensions.
4. Aggregate revenue and spend to a shared grain before joining.
5. Define `ROAS = attributed_revenue / spend` with an explicit attribution policy.

**Track historical product cost**

1. Build an SCD type-2 product-cost dimension with valid-from/to timestamps.
2. Join order items to the cost version effective at purchase time.
3. Backfill the fact because historical gross profit changes.
4. Add overlap and gap tests for effective ranges.

## 2. Data Transformation

### Show

- Run `dbt build --profiles-dir .` for the supported initial build.
- Open staging models and the normalization macro.
- Open deterministic deduplication using `row_number()`.
- Open the incremental configuration and `is_incremental()` lookback.
- Show partition and clustering configuration.

### Why

> Staging models create a stable contract over raw sources. Deduplication happens before the fact so the fact's primary key remains reliable. Merge is appropriate because order items can receive late status changes such as returns. The three-day lookback balances late-arriving updates against scan cost.

### BigQuery Sandbox statement

> This demonstration uses BigQuery Sandbox without billing. The initial dbt build and all tests complete successfully. The fact is implemented with merge, a unique key, and a three-day lookback, but Sandbox restricts subsequent DML MERGE execution. In a billing-enabled development environment, a successful incremental execution would be a required promotion check.

Do not claim that the second merge executed successfully.

### Likely questions

**Why not filter on the maximum date without a lookback?**

> A strict maximum watermark can miss updates to existing rows, especially returns recorded after the original creation date. The lookback intentionally reprocesses a bounded recent window, and merge makes that reprocessing idempotent.

**What if an update arrives after three days?**

> The current demo would miss it. In production I would use a reliable source `updated_at` watermark, CDC, or a periodic wider reconciliation/backfill. The correct choice depends on the source SLA and return window.

**Why partition by creation date?**

> Most dashboard queries filter time, so date partitioning reduces scanned data. Creation date is stable. If operational queries were driven by update time, I would consider a separate update-date strategy while preserving business-date semantics.

**Why cluster by three fields?**

> Status is frequently filtered, while product and customer are common joins and drill paths. I would verify this choice from query history rather than assume it indefinitely.

### What-if prompts

**Add a new discount column**

1. Add and type it in staging.
2. Define whether it reduces gross or net revenue with Finance.
3. Update accounting identities and tests.
4. Add the field to the fact.
5. Run a full refresh if historical values are available.
6. Version dashboard definitions and document the metric change.

**Source starts sending duplicates**

> The current deterministic `row_number()` keeps one record per order item based on the latest lifecycle timestamp. In production I would prefer a source ingestion timestamp or version number because business timestamps can tie.

## 3. Governance: Quality and Security

### Show

- Run `dbt test --profiles-dir . --select fct_order_items`.
- Show generic uniqueness, not-null, relationship, and accepted-values tests.
- Show `assert_financial_metric_consistency.sql`.
- Show that raw email is replaced with `email_hash` in staging.

### Why

> Generic tests protect structural contracts, while the singular financial test protects business meaning. I test accounting identities because individually non-null values can still combine into a financially impossible result.

### Likely questions

**Is hashing email sufficient security?**

> No. It is pseudonymization, not anonymization or authorization. Unsalted hashes of predictable values can be dictionary-attacked. Production controls should add least-privilege IAM, policy tags or column-level security, audit logging, and preferably tokenization or salted keyed hashing.

**What happens when a test fails?**

> CI blocks promotion for contract-breaking failures. In production I would assign severities: critical tests fail the pipeline and quarantine affected data; freshness or low-impact anomaly tests may warn and alert an owner.

**How would you test freshness?**

> Define source freshness using a reliable ingestion timestamp and an SLA agreed with the source owner. Freshness should compare warehouse arrival time, not only business event time.

### What-if prompts

**A new unexpected status appears**

> The accepted-values test fails. I would not silently map it. I would inspect the source contract, decide whether the status changes financial recognition, update logic and documentation, add a regression test, and then deploy.

**A dimension relationship test fails**

> Quantify the orphan rate, inspect whether facts arrive before dimensions, and decide between failing, quarantining, or assigning an explicit unknown-member key. I would not allow a silent inner join to drop revenue.

## 4. Data Insight

### Show

- Open the Looker Studio dashboard.
- Start with gross profit and gross margin.
- Apply date, category, country, and acquisition-channel filters.
- Trace one chart back to `mart_ecommerce_profitability.sql`.
- State metric assumptions before discussing findings.

### Why

> Gross profit is more decision-useful than revenue alone because it incorporates direct product cost. The reporting mart centralizes joins and calculations so the dashboard does not redefine business logic independently.

### Metric definitions

```text
Net Revenue = Gross Revenue - Refund Amount
Gross Profit = Net Revenue - Product Cost
Gross Margin = SUM(Gross Profit) / SUM(Net Revenue)
Refund Rate = SUM(Refund Amount) / SUM(Gross Revenue)
```

Never calculate gross margin as `SUM(gross_margin_rate)`.

### Likely questions

**Why can distinct order counts be dangerous in this mart?**

> Order and customer counts are non-additive across dimensions. An order containing multiple categories can be counted once in each category, so summing category-level distinct counts overstates the overall total. I use additive financial metrics or calculate distinct counts from an appropriate lower-grain model.

**What business action follows from the dashboard?**

> I would identify high-revenue, low-margin categories for pricing or cost review; high-refund segments for product-quality investigation; and acquisition channels that bring profitable rather than merely high-volume customers.

**Is gross profit the same as contribution profit?**

> No. This implementation excludes shipping, payment fees, discounts not represented in the source, marketing spend, taxes, and operating costs. The name and limitations must remain explicit.

### What-if prompts

**Finance changes return recognition timing**

> Separate event time from recognition time, introduce payment/refund facts, agree a restatement policy, rebuild affected periods, and version the metric definition so dashboard users know when the policy changed.

## 5. DataOps

### Show

- Open PR #1 and its successful GitHub Actions run.
- Open PR #2 to show documentation through the same workflow.
- Show pinned dbt versions and `.gitignore`.
- Show the pull-request-only CI workflow.
- Show branch protection settings if enabled.

### Why

> Feature branches isolate change, pull requests create a review and audit point, pinned dependencies make builds repeatable, and CI catches invalid dbt graphs before merge. Credentials are deliberately excluded from source control.

### Be precise about CI scope

> The current CI installs dependencies and parses the full dbt project without warehouse credentials. Local execution validates warehouse models and tests. A production pipeline would use workload identity federation, isolated schemas, slim CI with state comparison, and a deployment job after approval.

### Likely questions

**Why is parse-only CI not enough for production?**

> Parse catches syntax, Jinja, dependency, and graph errors but not warehouse SQL semantics or data-quality failures. Production CI should build modified models and descendants in an isolated schema and run tests against representative data.

**How would you avoid service-account JSON keys?**

> Use GitHub OIDC with Google Workload Identity Federation, grant least-privilege roles to a CI principal, and use short-lived credentials rather than storing a long-lived JSON key.

**How would you roll back?**

> Revert the merge commit, rebuild affected models from the last known-good code, and use versioned artifacts and manifests to identify the deployed state. For a breaking metric change, coordinate dashboard rollback and historical restatement.

### What-if prompts

**Two developers modify the same model**

> Rebase or merge main into the feature branch, resolve conflicts with both authors, run targeted CI on the model and descendants, and require review from the model owner.

## Safe live-modification routine

When given a change:

1. Restate the requirement.
2. Confirm the target grain and metric definition.
3. Identify the smallest affected models.
4. Make one focused edit.
5. Run targeted commands:
   - `dbt parse --profiles-dir .`
   - `dbt build --profiles-dir . --select model_name+`
6. Explain what additional production hardening remains.
7. Do not improvise a broad redesign while typing.

## Demo recovery plan

- Keep GitHub, BigQuery, Looker Studio, and PowerShell logged in before the call.
- Close all AI tools, AI browser tabs, IDE assistants, and autocomplete extensions.
- Keep secrets and `profiles.yml` off screen.
- Save screenshots of the successful dbt build, tests, DAG, dashboard, PRs, and CI run.
- If dbt Docs fails, use the GitHub architecture diagrams.
- If Looker Studio fails, use dashboard screenshots and trace metrics in SQL.
- If network access fails, use repository files and cached evidence.
- Never use AI during the interview.

## Final rehearsal checklist

- Deliver the opening in under five minutes.
- Explain the grain in one sentence.
- Derive gross profit without reading.
- Explain why ratios are non-additive.
- Explain why the lookback exists and what it misses.
- State the Sandbox limitation honestly.
- Explain why hashing is not complete security.
- Distinguish parse-only CI from production slim CI.
- Complete one small model/test change in under five minutes.
