with source as (

    select * from {{ ref('raw_customers') }}

),

renamed as (

    select
        customer_id,
        company_name,
        company_size,
        industry,
        signup_date::date as signup_date

    from source

)

select * from renamed
