-- Example renaming in stg_aws__billing.sql
select
    line_item_usage_start_date as ChargePeriodStart,
    line_item_usage_account_id as BillingAccountId,
    line_item_resource_id as ResourceId,
    line_item_unblended_cost as BilledCost,
    -- ... other FOCUS columns
from {{ source('external_raw_data', 'raw_aws_cur') }}