{{ config(tags=['saas_metrics']) }}

with subscriptions as (

    select * from {{ ref('stg_subscriptions') }}

),

plans as (

    select * from {{ ref('stg_plans') }}

),

events as (

    select * from {{ ref('stg_subscription_events') }}

),

monthly_cohorts as (

    select
        date_trunc('month', s.started_at)::date as cohort_month,
        p.tier,
        count(distinct s.customer_id) as cohort_size,
        count(distinct case when s.status = 'churned' then s.customer_id end) as churned_customers,
        count(distinct case when s.status = 'active' then s.customer_id end) as active_customers

    from subscriptions s
    inner join plans p on s.plan_id = p.plan_id

    group by 1, 2

),

monthly_churn_events as (

    select
        date_trunc('month', event_date)::date as churn_month,
        count(*) as churn_events,
        sum(abs(mrr_change)) as churned_mrr

    from events
    where event_type = 'churn'

    group by 1

),

active_at_month_start as (

    select
        date_trunc('month', e.event_date)::date as month_start,
        count(distinct case
            when e.event_type = 'new_business' and e.event_date < date_trunc('month', e.event_date)::date + interval '1 month'
            then e.customer_id
        end) as active_start_count

    from events e
    where e.event_type in ('new_business')

    group by 1

),

final as (

    select
        mc.cohort_month,
        mc.tier,
        mc.cohort_size,
        mc.churned_customers,
        mc.active_customers,
        round(
            case when mc.cohort_size > 0
                then mc.churned_customers::numeric / mc.cohort_size * 100
                else 0
            end, 2
        ) as cohort_churn_rate_pct,
        round(
            case when mc.cohort_size > 0
                then mc.active_customers::numeric / mc.cohort_size * 100
                else 0
            end, 2
        ) as cohort_retention_rate_pct

    from monthly_cohorts mc

)

select * from final
