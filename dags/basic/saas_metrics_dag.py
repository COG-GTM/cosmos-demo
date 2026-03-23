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
    tags=["saas_metrics"],
    default_args={"retries": 2},
)
def saas_metrics_dag() -> None:
    """
    SaaS Subscription Analytics pipeline using Cosmos to render a dbt project as a TaskGroup.
    """
    pre_dbt = EmptyOperator(task_id="pre_dbt")

    saas_metrics = DbtTaskGroup(
        group_id="saas_metrics_project",
        project_config=ProjectConfig(saas_metrics_path),
        profile_config=airflow_db,
        execution_config=venv_execution_config,
    )

    post_dbt = EmptyOperator(task_id="post_dbt")

    pre_dbt >> saas_metrics >> post_dbt


saas_metrics_dag()
