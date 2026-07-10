with source as (
    select * from {{ source('thelook_ecommerce', 'users') }}
),

renamed as (
    select
        cast(id as int64) as customer_id,
        -- Deterministic hashing enables matching without exposing direct PII.
        to_hex(sha256(lower(trim(email)))) as email_hash,
        cast(age as int64) as age,
        trim(gender) as gender,
        trim(country) as country,
        trim(state) as state,
        trim(city) as city,
        trim(traffic_source) as acquisition_channel,
        cast(created_at as timestamp) as customer_created_at
    from source
)

select * from renamed

