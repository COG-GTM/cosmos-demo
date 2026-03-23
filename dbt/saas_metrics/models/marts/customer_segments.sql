{{ config(tags=['saas_metrics']) }}

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

latest_plan_change as (

    select distinct on (subscription_id)
        subscription_id,
        new_plan_id as current_plan_id
    from events
    where new_plan_id is not null
    order by subscription_id, event_date desc

),

current_subscriptions as (

    select
        s.customer_id,
        s.subscription_id,
        coalesce(lp.current_plan_id, s.plan_id) as plan_id,
        s.started_at,
        s.status,
        s.billing_interval,
        s.subscription_duration_days,
        p.plan_name,
        p.tier,
        p.effective_monthly_price

    from subscriptions s
    left join latest_plan_change lp on s.subscription_id = lp.subscription_id
    inner join plans p on coalesce(lp.current_plan_id, s.plan_id) = p.plan_id

),

customer_metrics as (

    select
        c.customer_id,
        c.company_name,
        c.industry,
        c.company_size,
        c.signup_date,
        c.country,
        cs.plan_name as current_plan,
        cs.tier as current_tier,
        cs.effective_monthly_price as current_mrr,
        cs.billing_interval,
        cs.status as subscription_status,
        cs.subscription_duration_days,
        case
            when c.company_size <= 10 then 'micro'
            when c.company_size <= 50 then 'small'
            when c.company_size <= 200 then 'medium'
            when c.company_size <= 1000 then 'large'
            else 'enterprise'
        end as company_segment,
        case
            when cs.subscription_duration_days <= 90 then 'new'
            when cs.subscription_duration_days <= 180 then 'growing'
            when cs.subscription_duration_days <= 365 then 'established'
            else 'mature'
        end as lifecycle_stage

    from customers c
    left join current_subscriptions cs on c.customer_id = cs.customer_id

)

select * from customer_metrics
