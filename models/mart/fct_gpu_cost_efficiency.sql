{{ config(
    materialized='table',
    schema='GOLD'
) }}

with billing as (
    select * from {{ ref('stg_aws__billing') }}
),

telemetry as (
    -- We aggregate telemetry to the hour to match billing granularity
    select
        resource_id,
        date_trunc('hour', metric_timestamp) as metric_hour,
        avg(gpu_utilization_pct) as avg_utilization,
        max(is_idle::integer) as was_idle_flag
    from {{ ref('stg_gpu__telemetry') }}
    group by 1, 2
),

gpu_specs as (
    select * from {{ ref('dim_gpu_specs') }}
)

select
    -- Dimensions
    b.charge_period_start,
    b.resource_id,
    b.project_tag as project_name,
    s.gpu_model,
    s.gpu_count,
    
    -- Financials
    b.billed_cost,
    
    -- Performance & Waste Logic
    coalesce(t.avg_utilization, 0) as avg_utilization_pct,
    
    -- Waste Calculation: Cost * (1 - % Utilization)
    -- If a GPU is 20% utilized, 80% of the cost is "Waste"
    (b.billed_cost * (1 - (coalesce(t.avg_utilization, 0) / 100))) as idle_waste_amount,
    
    -- Unit Economics: Total TFLOPS provided in this hour
    (s.tflops_per_unit * s.gpu_count) as total_theoretical_tflops,
    
    -- Cost per Effective TFLOP (Billed Cost / (TFLOPS * Utilization))
    b.billed_cost / nullif((s.tflops_per_unit * s.gpu_count * (t.avg_utilization / 100)), 0) as cost_per_effective_tflop

from billing b
left join telemetry t 
    on b.resource_id = t.resource_id 
    and date_trunc('hour', b.charge_period_start) = t.metric_hour
left join gpu_specs s
    on b.sku_id = s.cloud_sku_id