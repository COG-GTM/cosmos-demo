with source as (

    select * from {{ ref('raw_subscriptions') }}

),

renamed as (

    select
        subscription_id,
        customer_id,
        plan_id,
        start_date::date as start_date,
        end_date::date as end_date,
        status,
        billing_interval

    from source

)

select * from renamed
