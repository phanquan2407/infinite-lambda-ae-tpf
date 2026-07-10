with ranked as (
    select
        *,
        row_number() over (
            partition by order_item_id
            order by coalesce(returned_at, delivered_at, shipped_at, created_at) desc
        ) as record_recency_rank
    from {{ ref('stg_order_items') }}
)

select * except (record_recency_rank)
from ranked
where record_recency_rank = 1

