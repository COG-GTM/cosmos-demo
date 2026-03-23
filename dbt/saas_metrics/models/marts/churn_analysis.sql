{{ config(tags=['saas_metrics']) }}

with subscriptions as (

    select * from {{ ref('stg_subscriptions') }}

),

plans as (

    select * from {{ ref('stg_plans') }}

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
