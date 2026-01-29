-- macros/apply_rls_policy.sql
{% macro apply_rls_policy(model_name, column_name) %}
  CREATE OR REPLACE ROW ACCESS POLICY {{ model_name }}_policy
  AS (val VARCHAR) RETURNS BOOLEAN ->
    EXISTS (
      SELECT 1 FROM {{ ref('security_mapping') }}
      WHERE user_email = CURRENT_USER()
      AND (cost_center_id = val OR cost_center_id = '*')
    );
    
  ALTER TABLE {{ model_name }} ADD ROW ACCESS POLICY {{ model_name }}_policy ON ({{ column_name }});
{% endmacro %}