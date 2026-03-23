with source as (

    select * from {{ ref('raw_subscription_events') }}

),

renamed as (

    select
        event_id,
        subscription_id,
        event_type,
        event_date::date as event_date,
        old_plan_id,
        new_plan_id,
        mrr_change::numeric(10,2) as mrr_change

    from source

)

select * from renamed
