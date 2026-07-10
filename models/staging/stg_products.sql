with source as (
    select * from {{ source('thelook_ecommerce', 'products') }}
),

renamed as (
    select
        cast(id as int64) as product_id,
        trim(sku) as sku,
        trim(name) as product_name,
        trim(brand) as brand,
        trim(category) as category,
        trim(department) as department,
        {{ cents_to_dollars('cost') }} as unit_cost,
        {{ cents_to_dollars('retail_price') }} as retail_price
    from source
)

select * from renamed

