"""
SaaS Subscription Analytics Pipeline

This DAG orchestrates a dbt project that computes key SaaS business metrics:
- Monthly Recurring Revenue (MRR) with movement breakdown
- Customer segmentation by plan tier, company size, and lifecycle stage
- Cohort-based churn and retention analysis
- Executive health dashboard with ARPU, ARR, and churn rates

The pipeline seeds raw subscription data, builds staging views, and
materializes mart tables as a self-service data product.
"""

from datetime import datetime

from airflow.decorators import dag
from airflow.operators.empty import EmptyOperator

from cosmos import DbtTaskGroup, ProjectConfig

from include.profiles import airflow_db
from include.constants import saas_metrics_path, venv_execution_config


@dag(
    schedule_interval="@daily",
    start_date=datetime(2023, 1, 1),
    catchup=False,
    dag_id="saas_metrics_pipeline",
    tags=["data_product", "saas_metrics"],
    doc_md=__doc__,
)
def saas_metrics_pipeline() -> None:
    """
    Orchestrates the SaaS Subscription Analytics dbt project using Cosmos.

    Flow: validate_source -> dbt (seed + stage + mart) -> notify_complete
    """
    validate_source = EmptyOperator(task_id="validate_source_data")

    saas_metrics = DbtTaskGroup(
        group_id="saas_metrics_dbt",
        project_config=ProjectConfig(saas_metrics_path),
        profile_config=airflow_db,
        execution_config=venv_execution_config,
    )

    notify_complete = EmptyOperator(task_id="notify_pipeline_complete")

    validate_source >> saas_metrics >> notify_complete


saas_metrics_pipeline()
