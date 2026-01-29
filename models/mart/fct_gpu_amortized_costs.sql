{{ config(materialized='table') }}

with raw_costs as (
    select 
        usage_date,
        account_id,
        project_id,
        instance_type,
        resource_id,
        -- FOCUS 1.0 logic: Use effective/amortized cost if available
        coalesce(amortized_cost, billed_cost) as base_cost,
        pricing_model -- 'On-Demand', 'Savings Plan', 'Reserved', 'Spot'
    from {{ ref('stg_aws__billing') }}
),

telemetry_agg as (
    select 
        resource_id,
        date_trunc('hour', metric_timestamp) as usage_hour,
        user_id,
        department,
        avg(gpu_utilization_pct) as avg_util,
        count(*) over (partition by resource_id, date_trunc('hour', metric_timestamp)) as users_on_instance
    from {{ ref('stg_gpu__telemetry') }}
    group by 1, 2, 3, 4
)

select 
    c.usage_date,
    c.account_id,
    t.department,
    t.user_id,
    c.instance_type,
    c.pricing_model,
    
    -- 1. APPORTIONED DIRECT COST
    -- If 2 users shared an 8xH100 node for an hour, each gets 50% of the base cost
    (c.base_cost / t.users_on_instance) as apportioned_base_cost,
    
    -- 2. EFFECTIVE UTILIZATION COST (The 'Good' spend)
    ((c.base_cost / t.users_on_instance) * (t.avg_util / 100)) as effective_training_cost,
    
    -- 3. SHARED WASTE (The 'Idle' spend)
    -- This is the cost of the GPU sitting idle while assigned to a user
    ((c.base_cost / t.users_on_instance) * (1 - (t.avg_util / 100))) as shared_idle_waste
    
from raw_costs c
inner join telemetry_agg t 
    on c.resource_id = t.resource_id 
    and c.usage_date = t.usage_hour