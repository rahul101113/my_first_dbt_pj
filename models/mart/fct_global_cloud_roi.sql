{{ config(materialized='table') }}

with cloud_metrics as (
    select 
        CloudProvider,
        instance_type,
        sum(BilledCost) as total_billed_cost,
        sum(usage_quantity) as total_gpu_hours,
        avg(gpu_utilization_pct) as avg_utilization
    from {{ ref('fct_global_gpu_usage') }}
    group by 1, 2
),

specs as (
    select 
        cloud_sku_id,
        on_demand_hourly_rate,
        tflops_per_gpu
    from {{ ref('dim_gpu_specs') }}
)

select 
    m.CloudProvider,
    m.instance_type,
    
    -- 1. SAVINGS PERFORMANCE
    -- (On-Demand Price * Hours) - Actual Billed Cost
    ( (s.on_demand_hourly_rate * m.total_gpu_hours) - m.total_billed_cost ) as total_savings_value,
    
    -- 2. EFFECTIVE HOURLY RATE (What you actually pay per hour)
    (m.total_billed_cost / m.total_gpu_hours) as effective_hourly_rate,
    
    -- 3. UNIT ECONOMICS: COST PER REALIZED TFLOP
    -- This is the "True ROI" metric. 
    -- It accounts for both the price you paid AND how much work the GPU actually did.
    (m.total_billed_cost / (m.total_gpu_hours * s.tflops_per_gpu * (m.avg_utilization / 100))) as cost_per_effective_tflop

from cloud_metrics m
join specs s on m.instance_type = s.cloud_sku_id