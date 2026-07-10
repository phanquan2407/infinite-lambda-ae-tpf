{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='order_item_id',
        partition_by={'field': 'created_date', 'data_type': 'date'},
        cluster_by=['order_status', 'product_id', 'customer_id'],
        on_schema_change='sync_all_columns'
    )
}}

with order_items as (
    select *
    from {{ ref('int_order_items_deduplicated') }}
    {% if is_incremental() %}
        -- Three-day lookback captures late updates such as returns.
        where created_at >= timestamp_sub(
            (select coalesce(max(created_at), timestamp('1900-01-01')) from {{ this }}),
            interval 3 day
        )
    {% endif %}
),

products as (
    select product_id, unit_cost
    from {{ ref('dim_products') }}
)

select
    oi.order_item_id,
    oi.order_id,
    oi.customer_id,
    oi.product_id,
    oi.inventory_item_id,
    oi.order_status,
    oi.created_at,
    date(oi.created_at) as created_date,
    oi.shipped_at,
    oi.delivered_at,
    oi.returned_at,
    oi.sale_price as gross_revenue,
    case when oi.order_status in ('cancelled', 'returned') then oi.sale_price else 0 end as refund_amount,
    case when oi.order_status in ('cancelled', 'returned') then 0 else oi.sale_price end as net_revenue,
    case when oi.order_status in ('cancelled', 'returned') then 0 else p.unit_cost end as product_cost,
    case when oi.order_status in ('cancelled', 'returned') then 0 else oi.sale_price - p.unit_cost end as gross_profit,
    current_timestamp() as dbt_loaded_at
from order_items oi
left join products p using (product_id)

