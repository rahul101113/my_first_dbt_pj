{{ config(materialized='view') }}

with base_usage as (
    select * from {{ ref('fct_gpu_usage_comprehensive') }}
),

security as (
    select * from {{ ref('security_mapping') }}
    where user_email = CURRENT_USER() -- Snowflake function for the logged-in user
)

select u.*
from base_usage u
inner join security s 
    on (u.cost_center = s.cost_center_id OR s.cost_center_id = '*')