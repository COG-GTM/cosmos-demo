with events as (

    select * from {{ ref('stg_subscription_events') }}

),

plans as (

    select * from {{ ref('stg_plans') }}

),

subscriptions as (

    select * from {{ ref('stg_subscriptions') }}

),

monthly_components as (

    select
        date_trunc('month', e.event_date)::date as revenue_month,
        sum(case when e.event_type = 'new' then e.mrr_change else 0 end) as new_mrr,
        sum(case when e.event_type = 'upgrade' then e.mrr_change else 0 end) as expansion_mrr,
        sum(case when e.event_type = 'downgrade' then e.mrr_change else 0 end) as contraction_mrr,
        sum(case when e.event_type = 'churn' then e.mrr_change else 0 end) as churned_mrr,
        sum(case when e.event_type = 'reactivation' then e.mrr_change else 0 end) as reactivation_mrr
    from events e
    left join subscriptions s on e.subscription_id = s.subscription_id
    left join plans p on s.plan_id = p.plan_id
    group by 1

),

final as (

    select
        revenue_month,
        new_mrr,
        expansion_mrr,
        contraction_mrr,
        churned_mrr,
        reactivation_mrr,
        (new_mrr + expansion_mrr + contraction_mrr + churned_mrr + reactivation_mrr) as net_new_mrr,
        sum(new_mrr + expansion_mrr + contraction_mrr + churned_mrr + reactivation_mrr)
            over (order by revenue_month rows between unbounded preceding and current row) as total_mrr
    from monthly_components

)

select * from final
order by revenue_month
