with customers as (

    select * from {{ ref('stg_customers') }}

),

subscriptions as (

    select * from {{ ref('stg_subscriptions') }}

),

plans as (

    select * from {{ ref('stg_plans') }}

),

events as (

    select * from {{ ref('stg_subscription_events') }}

),

latest_subscriptions as (

    select
        s.customer_id,
        s.subscription_id,
        s.plan_id,
        s.status,
        s.start_date,
        s.end_date,
        s.billing_interval,
        row_number() over (partition by s.customer_id order by s.start_date desc) as rn
    from subscriptions s

),

latest_events as (

    select
        e.subscription_id,
        e.event_type,
        row_number() over (partition by e.subscription_id order by e.event_date desc) as rn
    from events e

),

reactivated_customers as (

    select distinct s.customer_id
    from events e
    join subscriptions s on e.subscription_id = s.subscription_id
    where e.event_type = 'reactivation'

),

final as (

    select
        c.customer_id,
        c.company_name,
        c.company_size,
        c.industry,
        c.signup_date,
        p.tier as plan_tier,
        p.plan_name,
        ls.status as subscription_status,
        ls.billing_interval,
        case
            when ls.status = 'churned' then 'churned'
            when rc.customer_id is not null then 'reactivated'
            when ls.status = 'active' and ls.start_date >= current_date - interval '90 days' then 'new'
            when ls.status = 'active' then 'active'
            when ls.status in ('upgraded', 'downgraded') then 'active'
            else 'at_risk'
        end as lifecycle_stage,
        case
            when ls.status = 'churned' or ls.subscription_id is null then 0
            when ls.billing_interval = 'annual' then p.annual_price / 12.0
            else p.monthly_price
        end as current_mrr
    from customers c
    left join latest_subscriptions ls on c.customer_id = ls.customer_id and ls.rn = 1
    left join plans p on ls.plan_id = p.plan_id
    left join latest_events le on ls.subscription_id = le.subscription_id and le.rn = 1
    left join reactivated_customers rc on c.customer_id = rc.customer_id

)

select * from final
