with subscriptions as (

    select * from {{ ref('stg_subscriptions') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

plans as (

    select * from {{ ref('stg_plans') }}

),

events as (

    select * from {{ ref('stg_subscription_events') }}

),

months as (

    select distinct date_trunc('month', event_date)::date as report_month
    from events

),

active_subs_per_month as (

    select
        m.report_month,
        count(distinct s.subscription_id) as total_active_subscriptions
    from months m
    join subscriptions s
        on s.start_date <= (m.report_month + interval '1 month' - interval '1 day')::date
        and (s.end_date is null or s.end_date >= m.report_month)
    group by 1

),

mrr_per_month as (

    select
        date_trunc('month', e.event_date)::date as report_month,
        sum(e.mrr_change) as net_new_mrr
    from events e
    group by 1

),

cumulative_mrr as (

    select
        report_month,
        sum(net_new_mrr) over (order by report_month rows between unbounded preceding and current row) as total_mrr
    from mrr_per_month

),

new_customers_per_month as (

    select
        date_trunc('month', c.signup_date)::date as report_month,
        count(distinct c.customer_id) as new_customers_count
    from customers c
    group by 1

),

churned_per_month as (

    select
        date_trunc('month', e.event_date)::date as report_month,
        count(distinct s.customer_id) as churned_customers_count,
        abs(sum(e.mrr_change)) as churned_mrr
    from events e
    join subscriptions s on e.subscription_id = s.subscription_id
    where e.event_type = 'churn'
    group by 1

),

top_plans as (

    select
        m.report_month,
        p.plan_name as top_plan_by_subscribers,
        row_number() over (partition by m.report_month order by count(distinct s.subscription_id) desc) as rn
    from months m
    join subscriptions s
        on s.start_date <= (m.report_month + interval '1 month' - interval '1 day')::date
        and (s.end_date is null or s.end_date >= m.report_month)
    join plans p on s.plan_id = p.plan_id
    group by 1, 2

),

final as (

    select
        m.report_month,
        coalesce(a.total_active_subscriptions, 0) as total_active_subscriptions,
        coalesce(cm.total_mrr, 0) as total_mrr,
        coalesce(nc.new_customers_count, 0) as new_customers_count,
        coalesce(ch.churned_customers_count, 0) as churned_customers_count,
        case
            when coalesce(a.total_active_subscriptions, 0) > 0
            then round(coalesce(ch.churned_customers_count, 0)::numeric / a.total_active_subscriptions, 4)
            else 0
        end as gross_churn_rate,
        case
            when lag(cm.total_mrr) over (order by m.report_month) > 0
            then round(
                (coalesce(cm.total_mrr, 0))::numeric
                / lag(cm.total_mrr) over (order by m.report_month),
                4
            )
            else null
        end as net_revenue_retention_rate,
        case
            when coalesce(a.total_active_subscriptions, 0) > 0
            then round(coalesce(cm.total_mrr, 0)::numeric / a.total_active_subscriptions, 2)
            else 0
        end as average_revenue_per_customer,
        tp.top_plan_by_subscribers
    from months m
    left join active_subs_per_month a on m.report_month = a.report_month
    left join cumulative_mrr cm on m.report_month = cm.report_month
    left join new_customers_per_month nc on m.report_month = nc.report_month
    left join churned_per_month ch on m.report_month = ch.report_month
    left join top_plans tp on m.report_month = tp.report_month and tp.rn = 1

)

select * from final
order by report_month
