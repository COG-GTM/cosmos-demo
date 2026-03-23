with source as (

    select * from {{ ref('raw_plans') }}

),

renamed as (

    select
        plan_id,
        plan_name,
        tier,
        monthly_price::numeric(10,2) as monthly_price,
        annual_price::numeric(10,2) as annual_price

    from source

)

select * from renamed
