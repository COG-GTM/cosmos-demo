with source as (

    select * from {{ ref('raw_subscriptions') }}

),

renamed as (

    select
        subscription_id,
        customer_id,
        plan_id,
        started_at::date as started_at,
        ended_at::date as ended_at,
        status,
        billing_interval,
        case
            when ended_at is null then current_date - started_at::date
            else ended_at::date - started_at::date
        end as subscription_duration_days

    from source

)

select * from renamed
