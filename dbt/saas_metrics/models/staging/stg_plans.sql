with source as (

    select * from {{ ref('raw_plans') }}

),

renamed as (

    select
        plan_id,
        plan_name,
        monthly_price_cents / 100.0 as monthly_price,
        annual_price_cents / 100.0 as annual_price,
        case
            when monthly_price_cents > 0 then monthly_price_cents / 100.0
            when annual_price_cents > 0 then annual_price_cents / 1200.0
            else 0
        end as effective_monthly_price,
        tier,
        max_seats,
        is_active

    from source

)

select * from renamed
