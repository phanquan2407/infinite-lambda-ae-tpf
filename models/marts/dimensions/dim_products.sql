select
    product_id,
    sku,
    product_name,
    brand,
    category,
    department,
    unit_cost,
    retail_price
from {{ ref('stg_products') }}

