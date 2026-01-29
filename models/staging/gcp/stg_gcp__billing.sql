{{ config(materialized='view') }}

with raw_source as (
    select * from {{ source('gcp_raw', 'raw_gcp_billing') }}
),

flattened as (
    select
        -- FOCUS Mapping
        "raw_data":usage_start_time::timestamp as ChargePeriodStart,
        "raw_data":billing_account_id::string as BillingAccountId,
        "raw_data":resource:name::string as ResourceId,
        
        -- GCP Cost Calculation: Base Cost + Credits (Negative values)
        "raw_data":cost::float as list_cost,
        
        -- Extracting specific credits (CUDs/SUDs)
        (select sum(f.value:amount::float) 
         from table(flatten(input => "raw_data":credits)) f) as total_credits,
         
        -- Resource Metadata
        "raw_data":sku:id::string as SkuId,
        "raw_data":project:labels:project_id::string as project_id,
        "raw_data":project:labels:user::string as user_id_tag,
        
        'GCP' as CloudProvider
    from raw_source
)

select 
    *,
    (list_cost + coalesce(total_credits, 0)) as BilledCost -- This is the Effective/Amortized cost
from flattened