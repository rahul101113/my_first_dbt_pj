{{ config(materialized='table') }}

with hardware_rates as (
    -- Reference our seed with standard On-Demand prices
    select 
        cloud_sku_id,
        on_demand_hourly_rate
    from {{ ref('dim_gpu_specs') }}
),

actual_spend as (
    select 
        instance_type,
        department,
        project_id,
        sum(billed_cost) as total_effective_cost,
        sum(usage_quantity) as total_hours
    from {{ ref('fct_gpu_amortized_costs') }}
    group by 1, 2, 3
)

select 
    a.*,
    (a.total_hours * h.on_demand_hourly_rate) as theoretical_on_demand_cost,
    ((a.total_hours * h.on_demand_hourly_rate) - a.total_effective_cost) as total_savings_amount,
    -- Savings Percentage (KPI for CFO)
    safe_divide(
        ((a.total_hours * h.on_demand_hourly_rate) - a.total_effective_cost),
        (a.total_hours * h.on_demand_hourly_rate)
    ) * 100 as discount_efficiency_pct
from actual_spend a
left join hardware_rates h on a.instance_type = h.cloud_sku_id