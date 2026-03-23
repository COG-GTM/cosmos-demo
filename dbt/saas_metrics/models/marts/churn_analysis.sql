with customers as (

    select * from {{ ref('stg_customers') }}

),

subscriptions as (

    select * from {{ ref('stg_subscriptions') }}

),

events as (

    select * from {{ ref('stg_subscription_events') }}

),

cohorts as (

    select
        c.customer_id,
        date_trunc('month', c.signup_date)::date as cohort_month
    from customers c

),

months as (

    select distinct date_trunc('month', e.event_date)::date as activity_month
    from events e

),

cohort_months as (

    select
        co.cohort_month,
        m.activity_month,
        (extract(year from m.activity_month) - extract(year from co.cohort_month)) * 12
            + extract(month from m.activity_month) - extract(month from co.cohort_month) as months_since_signup
    from (select distinct cohort_month from cohorts) co
    cross join months m
    where m.activity_month >= co.cohort_month

),

cohort_sizes as (

    select
        cohort_month,
        count(distinct customer_id) as cohort_size
    from cohorts
    group by 1

),

churned_by_month as (

    select
        co.cohort_month,
        date_trunc('month', e.event_date)::date as churn_month,
        count(distinct s.customer_id) as churned_count
    from events e
    join subscriptions s on e.subscription_id = s.subscription_id
    join cohorts co on s.customer_id = co.customer_id
    where e.event_type = 'churn'
    group by 1, 2

),

cumulative_churn as (

    select
        cm.cohort_month,
        cm.activity_month,
        cm.months_since_signup,
        cs.cohort_size,
        coalesce(sum(ch.churned_count) over (
            partition by cm.cohort_month
            order by cm.activity_month
            rows between unbounded preceding and current row
        ), 0) as cumulative_churned
    from cohort_months cm
    join cohort_sizes cs on cm.cohort_month = cs.cohort_month
    left join churned_by_month ch on cm.cohort_month = ch.cohort_month and cm.activity_month = ch.churn_month

),

final as (

    select
        cohort_month,
        activity_month,
        months_since_signup,
        cohort_size,
        cohort_size - cumulative_churned as customers_remaining,
        round((cohort_size - cumulative_churned)::numeric / nullif(cohort_size, 0), 4) as retention_rate,
        round(cumulative_churned::numeric / nullif(cohort_size, 0), 4) as churn_rate
    from cumulative_churn

)

select * from final
order by cohort_month, activity_month
