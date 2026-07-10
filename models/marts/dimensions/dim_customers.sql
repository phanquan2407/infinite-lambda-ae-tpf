select
    customer_id,
    email_hash,
    age,
    case
        when age < 25 then '18-24'
        when age < 35 then '25-34'
        when age < 45 then '35-44'
        when age < 55 then '45-54'
        else '55+'
    end as age_group,
    gender,
    country,
    state,
    city,
    acquisition_channel,
    customer_created_at
from {{ ref('stg_customers') }}

