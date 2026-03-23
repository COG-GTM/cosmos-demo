with source as (

    select * from {{ ref('raw_subscription_events') }}

),

renamed as (

    select
        event_id,
        subscription_id,
        customer_id,
        event_type,
        event_date::date as event_date,
        old_plan_id,
        new_plan_id,
        mrr_change_cents / 100.0 as mrr_change

    from source

)

select * from renamed
