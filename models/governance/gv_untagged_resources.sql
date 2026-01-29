{{ config(materialized='view') }}

select
    usage_date,
    account_id,
    resource_id,
    instance_type,
    billed_cost,
    -- Identify which specific tag is missing
    case 
        when project_id = 'Unallocated' or project_id is null then 'Missing Project Tag'
        when user_id_tag is null then 'Missing Owner Tag'
        else 'Unknown Leakage'
    end as gap_reason,
    -- Metadata for the alert
    'https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:search=' || resource_id as aws_console_link
from {{ ref('stg_aws__billing') }}
where (project_id = 'Unallocated' or project_id is null or user_id_tag is null)
  and usage_date >= current_date - 1  -- Only look at the last 24 hours