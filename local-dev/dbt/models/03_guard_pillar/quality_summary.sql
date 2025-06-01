-- ===============================================
-- [GUARD PILLAR] Quality Monitoring Dashboard
-- ===============================================
-- Purpose: Provide real-time quality metrics for system protection monitoring
-- Benefit: Immediate visibility into data protection effectiveness
-- Three Pillars Role: Quality metrics for continuous system improvement
-- Learning Value: Shows how Guard pillar provides quality transparency

{{ config(materialized='table') }}

select
    'system_wide' as scope,
    
    -- Volume metrics
    count(*) as total_records_validated,
    
    -- Quality pass rates (Guard pillar effectiveness)
    sum(case when overall_quality_status = 'QUALITY_PASSED' then 1 else 0 end) as records_passed,
    sum(case when overall_quality_status = 'QUALITY_WARNING' then 1 else 0 end) as records_warning,
    sum(case when overall_quality_status = 'QUARANTINE_REQUIRED' then 1 else 0 end) as records_quarantined,
    
    -- Quality percentages for monitoring
    round(100.0 * sum(case when overall_quality_status = 'QUALITY_PASSED' then 1 else 0 end) / count(*), 2) as quality_pass_percentage,
    round(100.0 * sum(case when auto_quarantine_flag = true then 1 else 0 end) / count(*), 2) as quarantine_percentage,
    
    -- Issue breakdown for targeted improvement
    sum(case when temperature_quality_flag != 'TEMPERATURE_NORMAL' then 1 else 0 end) as temperature_issues,
    sum(case when humidity_quality_flag != 'HUMIDITY_NORMAL' then 1 else 0 end) as humidity_issues,
    sum(case when status_quality_flag != 'STATUS_VALID' then 1 else 0 end) as status_issues,
    sum(case when timestamp_quality_flag != 'TIMESTAMP_VALID' then 1 else 0 end) as timestamp_issues,
    
    -- Guard pillar monitoring metadata
    max(quality_validated_at) as last_validation_time,
    current_timestamp as summary_generated_at

from {{ ref('data_quality_validation') }}

union all

-- Location-specific quality metrics
select
    concat('location_', location_code) as scope,
    count(*) as total_records_validated,
    sum(case when overall_quality_status = 'QUALITY_PASSED' then 1 else 0 end) as records_passed,
    sum(case when overall_quality_status = 'QUALITY_WARNING' then 1 else 0 end) as records_warning,
    sum(case when overall_quality_status = 'QUARANTINE_REQUIRED' then 1 else 0 end) as records_quarantined,
    round(100.0 * sum(case when overall_quality_status = 'QUALITY_PASSED' then 1 else 0 end) / count(*), 2) as quality_pass_percentage,
    round(100.0 * sum(case when auto_quarantine_flag = true then 1 else 0 end) / count(*), 2) as quarantine_percentage,
    sum(case when temperature_quality_flag != 'TEMPERATURE_NORMAL' then 1 else 0 end) as temperature_issues,
    sum(case when humidity_quality_flag != 'HUMIDITY_NORMAL' then 1 else 0 end) as humidity_issues,
    sum(case when status_quality_flag != 'STATUS_VALID' then 1 else 0 end) as status_issues,
    sum(case when timestamp_quality_flag != 'TIMESTAMP_VALID' then 1 else 0 end) as timestamp_issues,
    max(quality_validated_at) as last_validation_time,
    current_timestamp as summary_generated_at

from {{ ref('data_quality_validation') }}
group by location_code

order by scope
