{{ config(tags=['saas_metrics']) }}

with events as (

    select * from {{ ref('stg_subscription_events') }}

),

months as (

    select generate_series(
        date_trunc('month', (select min(event_date) from events)),
        date_trunc('month', (select max(event_date) from events)),
        '1 month'::interval
    )::date as month_start

),

monthly_events as (

    select
        date_trunc('month', event_date)::date as month_start,
        event_type,
        sum(mrr_change) as total_mrr_change,
        count(*) as event_count

    from events

    group by 1, 2

),

pivoted as (

    select
        m.month_start,

        coalesce(sum(case when me.event_type = 'new_business' then me.total_mrr_change end), 0) as new_business_mrr,
        coalesce(sum(case when me.event_type = 'upgrade' then me.total_mrr_change end), 0) as expansion_mrr,
        coalesce(sum(case when me.event_type = 'downgrade' then me.total_mrr_change end), 0) as contraction_mrr,
        coalesce(sum(case when me.event_type = 'churn' then me.total_mrr_change end), 0) as churned_mrr,
        coalesce(sum(case when me.event_type = 'reactivation' then me.total_mrr_change end), 0) as reactivation_mrr,

        coalesce(sum(case when me.event_type = 'new_business' then me.event_count end), 0) as new_customers,
        coalesce(sum(case when me.event_type = 'upgrade' then me.event_count end), 0) as upgrades,
        coalesce(sum(case when me.event_type = 'downgrade' then me.event_count end), 0) as downgrades,
        coalesce(sum(case when me.event_type = 'churn' then me.event_count end), 0) as churns,
        coalesce(sum(case when me.event_type = 'reactivation' then me.event_count end), 0) as reactivations

    from months m
    left join monthly_events me on m.month_start = me.month_start

    group by m.month_start

),

final as (

    select
        month_start,
        new_business_mrr,
        expansion_mrr,
        contraction_mrr,
        churned_mrr,
        reactivation_mrr,
        new_business_mrr + expansion_mrr + contraction_mrr + churned_mrr + reactivation_mrr as net_new_mrr,
        sum(new_business_mrr + expansion_mrr + contraction_mrr + churned_mrr + reactivation_mrr)
            over (order by month_start rows between unbounded preceding and current row) as ending_mrr,
        new_customers,
        upgrades,
        downgrades,
        churns,
        reactivations

    from pivoted

)

select * from final
