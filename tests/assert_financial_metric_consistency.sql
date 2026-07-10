-- Returns rows only when financial identities are violated; zero rows means pass.
select *
from {{ ref('fct_order_items') }}
where abs(gross_revenue - refund_amount - net_revenue) > 0.01
   or abs(net_revenue - product_cost - gross_profit) > 0.01
   or net_revenue < 0
   or product_cost < 0

