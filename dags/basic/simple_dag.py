from datetime import datetime

from cosmos import DbtDag, ProjectConfig, RenderConfig
from cosmos.constants import TestBehavior

from include.profiles import airflow_db
from include.constants import jaffle_shop_path, venv_execution_config

simple_dag = DbtDag(
    # dbt/cosmos-specific parameters
    project_config=ProjectConfig(jaffle_shop_path),
    profile_config=airflow_db,
    execution_config=venv_execution_config,
    # run each model and its tests in one `dbt build` task instead of separate run/test tasks;
    # tests with several parents (orders -> customers relationship) get their own task after all of them
    render_config=RenderConfig(
        test_behavior=TestBehavior.BUILD,
        should_detach_multiple_parents_tests=True,
    ),
    # normal dag parameters
    schedule_interval="@daily",
    start_date=datetime(2023, 1, 1),
    catchup=False,
    dag_id="simple_dag",
    tags=["simple"],
)
