select
    f.created_date,
    date_trunc(f.created_date, month) as order_month,
    p.department,
    p.category,
    p.brand,
    c.country,
    c.age_group,
    c.acquisition_channel,
    count(distinct f.order_id) as order_count,
    count(distinct f.customer_id) as customer_count,
    count(*) as item_count,
    sum(f.gross_revenue) as gross_revenue,
    sum(f.refund_amount) as refund_amount,
    sum(f.net_revenue) as net_revenue,
    sum(f.product_cost) as product_cost,
    sum(f.gross_profit) as gross_profit,
    safe_divide(sum(f.gross_profit), sum(f.net_revenue)) as gross_margin_rate,
    safe_divide(sum(f.net_revenue), count(distinct f.order_id)) as average_order_item_revenue
from {{ ref('fct_order_items') }} f
left join {{ ref('dim_products') }} p using (product_id)
left join {{ ref('dim_customers') }} c using (customer_id)
group by 1, 2, 3, 4, 5, 6, 7, 8

