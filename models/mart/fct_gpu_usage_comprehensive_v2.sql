{{ config(materialized='table', schema='GOLD') }}

with usage_data as (
    -- This is the model we built previously
    select * from {{ ref('fct_gpu_usage_comprehensive') }}
),

user_mapping as (
    select * from {{ ref('dim_user_cost_centers') }}
),

account_mapping as (
    select * from {{ ref('map_user_aws_accounts') }}
)

select
    u.*,
    -- Join Cost Center Info
    m.department,
    m.cost_center,
    -- Join Account Context
    a.environment as account_environment
from usage_data u
left join user_mapping m 
    on u.user_id = m.user_id
left join account_mapping a 
    on u.user_id = a.user_id 
    and u.account_id = a.aws_account_id