{{ config(
    materialized='incremental',
    unique_key='unique_id',
    schema='GOLD'
) }}

with billing as (
    select * from {{ ref('stg_aws__billing') }}
),

telemetry as (
    select
        resource_id,
        date_trunc('hour', metric_timestamp) as metric_hour,
        -- Aggregating identifiers from telemetry metadata
        --raw_data:run_id::string as run_id,
        --raw_data:user_id::string as user_id,
        run_id,
        user_id,
        avg(gpu_utilization_pct) as avg_utilization
    from {{ ref('stg_gpu__telemetry') }}
    group by 1, 2, 3, 4
),

gpu_specs as (
    select * from {{ ref('dim_gpu_specs') }}
)

select
    -- 1. Unique ID for dbt Incremental logic
    md5(cast(concat(b.resource_id, b.charge_period_start, coalesce(t.run_id, 'N/A')) as string)) as unique_id,

    -- 2. Your Requested Granularity Columns
    t.run_id,                         -- By RunID
    t.user_id,                        -- By UserID
    b.project_id,                     -- By ProjectID
    b.sku_id as instance_type,        -- By InstanceType
    'AmazonEC2' as service_name,      -- By ServiceName
    b.account_id,                     -- By AccountID (Ensure this is in your stg model)
    b.charge_period_start as usage_date, -- By Usage Date

    -- 3. Metrics
    b.billed_cost,
    coalesce(t.avg_utilization, 0) as avg_utilization_pct,
    (b.billed_cost * (1 - (coalesce(t.avg_utilization, 0) / 100))) as idle_waste_amount,
    
    -- Hardware Stats from Seed
    s.gpu_model,
    (s.gpu_count * s.tflops_per_unit) as total_theoretical_tflops

from billing b
left join telemetry t 
    on b.resource_id = t.resource_id 
    and date_trunc('hour', b.charge_period_start) = t.metric_hour
left join gpu_specs s
    on b.sku_id = s.cloud_sku_id