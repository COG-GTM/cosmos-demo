with source as (

    select * from {{ ref('raw_customers') }}

),

renamed as (

    select
        customer_id,
        company_name,
        industry,
        company_size,
        signup_date::date as signup_date,
        country

    from source

)

select * from renamed
