# Metric definition: Gross Profit

## Business purpose

Gross profit shows whether sales remain economically valuable after the direct cost of merchandise. It prevents teams from optimizing for high revenue that may carry weak margins.

## Grain and formula

The canonical calculation occurs in `fct_order_items` at one row per order item.

- Gross revenue: listed sale price of the item.
- Refund amount: full sale price when status is `cancelled` or `returned`; otherwise zero.
- Net revenue: gross revenue minus refund amount.
- Product cost: product unit cost for recognized sales; zero for cancelled or returned items.
- Gross profit: net revenue minus recognized product cost.
- Gross margin rate: gross profit divided by net revenue, using `safe_divide`.

## Explicit assumptions

- One source row represents one item, so quantity is implicitly one.
- Cancellation and return are treated as full reversals.
- Shipping, discounts, tax, payment fees, and marketing spend are unavailable and excluded.
- Product cost is the current product master cost, not a historical slowly changing cost.

## Production extensions

For finance-grade reporting, introduce payment/refund events, discounts and taxes, shipping and fulfillment costs, and a type-2 product cost dimension. Agree recognition timing and return policy with Finance before certification.

