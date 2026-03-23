{% docs saas_metrics_overview %}

## SaaS Subscription Analytics

This dbt project transforms raw subscription data into actionable SaaS business
metrics. It is designed as a **data product** that provides self-service analytics
for finance, product, and executive teams.

### Data Sources (Seeds)

| Seed | Description |
|------|-------------|
| `raw_plans` | SaaS plan definitions with pricing tiers |
| `raw_customers` | Customer company profiles |
| `raw_subscriptions` | Active and historical subscription records |
| `raw_subscription_events` | Lifecycle events (signup, upgrade, downgrade, churn) |

### Key Metrics Produced

- **MRR (Monthly Recurring Revenue)** — broken down by new, expansion, contraction, and churn
- **ARR (Annual Recurring Revenue)** — annualized MRR
- **ARPU (Average Revenue Per User)** — revenue efficiency metric
- **Churn Rate** — cohort-based customer churn percentages
- **Retention Rate** — cohort-based customer retention percentages
- **Customer Segmentation** — by plan tier, company size, and lifecycle stage

{% enddocs %}
