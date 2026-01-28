{{ config(materialized='view') }}

with raw_source as (
    select * from {{ source('external_raw_data', 'raw_gpu_telemetry') }}
),

flattened as (
    select
        -- Standard Identifiers
        raw_data:resource_id::string as resource_id,
        raw_data:timestamp::timestamp as metric_timestamp,
        
        -- Your Requested Deep Granularity Columns
        raw_data:run_id::string as run_id,             -- Added RunID
        raw_data:user_id::string as user_id,           -- Added UserID
        raw_data:service_name::string as service_name, -- Added ServiceName
        
        -- Performance Metrics
        raw_data:metrics:gpu_utilization::float as gpu_utilization_pct
    from raw_source
)

select * from flattened