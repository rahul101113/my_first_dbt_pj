{{ config(materialized='table') }}

with all_clouds as (
    select * from {{ ref('stg_aws__billing') }}
    union all
    select * from {{ ref('stg_azure__billing') }}
    union all
    select * from {{ ref('stg_gcp__billing') }}
)

select 
    a.*,
    t.gpu_utilization_pct,
    -- Calculate Waste across any cloud
    (a.BilledCost * (1 - (coalesce(t.gpu_utilization_pct, 0) / 100))) as IdleWasteAmount
from all_clouds a
left join {{ ref('stg_gpu__telemetry') }} t 
    on a.ResourceId = t.resource_id 
    and a.ChargePeriodStart = date_trunc('hour', t.metric_timestamp)