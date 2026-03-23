{{ config(tags=['saas_metrics']) }}

with mrr as (

    select * from {{ ref('monthly_recurring_revenue') }}

),

segments as (

    select * from {{ ref('customer_segments') }}

),

churn as (

    select * from {{ ref('churn_analysis') }}

),

latest_mrr as (

    select *
    from mrr
    order by month_start desc
    limit 1

),

overall_metrics as (

    select
        count(distinct case when subscription_status = 'active' then customer_id end) as total_active_customers,
        count(distinct case when subscription_status = 'churned' then customer_id end) as total_churned_customers,
        count(distinct customer_id) as total_customers,
        round(avg(case when subscription_status = 'active' then current_mrr end), 2) as avg_revenue_per_account,
        count(distinct case when current_tier = 'enterprise' and subscription_status = 'active' then customer_id end) as enterprise_customers,
        count(distinct case when current_tier = 'pro' and subscription_status = 'active' then customer_id end) as pro_customers,
        count(distinct case when current_tier = 'starter' and subscription_status = 'active' then customer_id end) as starter_customers,
        count(distinct case when current_tier = 'free' and subscription_status = 'active' then customer_id end) as free_customers

    from segments

),

tier_revenue as (

    select
        current_tier,
        count(distinct case when subscription_status = 'active' then customer_id end) as active_count,
        round(sum(case when subscription_status = 'active' then current_mrr else 0 end), 2) as tier_mrr,
        round(avg(case when subscription_status = 'active' then current_mrr end), 2) as avg_tier_mrr

    from segments
    where current_tier is not null

    group by current_tier

),

overall_churn as (

    select
        round(avg(cohort_churn_rate_pct), 2) as avg_churn_rate_pct,
        round(avg(cohort_retention_rate_pct), 2) as avg_retention_rate_pct

    from churn

),

final as (

    select
        lm.month_start as reporting_month,
        lm.ending_mrr,
        lm.ending_mrr * 12 as arr,
        lm.net_new_mrr,
        lm.new_business_mrr,
        lm.expansion_mrr,
        lm.contraction_mrr,
        lm.churned_mrr,
        lm.reactivation_mrr,
        om.total_active_customers,
        om.total_churned_customers,
        om.total_customers,
        om.avg_revenue_per_account,
        om.enterprise_customers,
        om.pro_customers,
        om.starter_customers,
        om.free_customers,
        oc.avg_churn_rate_pct,
        oc.avg_retention_rate_pct,
        case
            when om.total_active_customers > 0
            then round(lm.ending_mrr / om.total_active_customers, 2)
            else 0
        end as arpu

    from latest_mrr lm
    cross join overall_metrics om
    cross join overall_churn oc

)

select * from final
