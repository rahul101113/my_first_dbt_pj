{{ config(materialized='view') }}

with raw_source as (
    select * from {{ source('external_raw_data', 'raw_aws_cur') }}
),

renamed as (
    select
        -- Use double quotes if Snowflake is being picky about case sensitivity
        raw_data:line_item_usage_start_date::timestamp as charge_period_start,
        raw_data:line_item_resource_id::string as resource_id,
        raw_data:line_item_usage_account_id::string as account_id, -- Added AccountID
        
        -- Cost Metrics
        raw_data:line_item_unblended_cost::float as billed_cost,
        
        -- Resource Metadata
        raw_data:product_instance_type::string as sku_id,
        
        -- IDs from Tags (extracted from the JSON)
        raw_data:resource_tags_user_project::string as project_id,
        raw_data:resource_tags_user_owner::string as user_id_tag,
        
        ingested_at as processed_at
    from raw_source
)

select * from renamed