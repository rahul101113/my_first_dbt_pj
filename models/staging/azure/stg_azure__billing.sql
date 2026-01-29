{{ config(materialized='view') }}

with raw_source as (
    select * from {{ source('azure_raw', 'raw_azure_billing') }}
),

renamed as (
    select
        -- FOCUS Mapping
        "raw_data":UsageDateTime::timestamp as ChargePeriodStart,
        "raw_data":SubscriptionId::string as BillingAccountId,
        "raw_data":ResourceId::string as ResourceId,
        
        -- Azure-specific: Amortized cost includes the effective rate of RIs
        "raw_data":CostInBillingCurrency::float as BilledCost,
        
        -- Resource Metadata
        "raw_data":MeterId::string as SkuId,
        "raw_data":MeterName::string as SkuPriceDescription,
        
        -- Tags (Azure tags are usually a JSON string or object)
        "raw_data":Tags:project::string as project_id,
        "raw_data":Tags:owner::string as user_id_tag,
        
        'Azure' as CloudProvider
    from raw_source
)

select * from renamed