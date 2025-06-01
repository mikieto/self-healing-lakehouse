-- ===============================================
-- [GUARD PILLAR] Automated Quality Protection
-- ===============================================
-- Purpose: Automatically detect, flag, and quarantine quality issues
-- Benefit: Prevent bad data from contaminating downstream systems
-- Three Pillars Role: Autonomous defense against data corruption
-- Learning Value: Shows automated quality enforcement in action



with quality_checks as (
    select
        sensor_id,
        location_code,
        temperature_celsius,
        humidity_percentage,
        sensor_status,
        measured_timestamp,
        processed_at,
        
        -- Temperature validation rules
        case 
            when temperature_celsius > 60 then 'TEMPERATURE_EXTREME_HIGH'
            when temperature_celsius < -40 then 'TEMPERATURE_EXTREME_LOW'
            when temperature_celsius > 50 then 'TEMPERATURE_HIGH_WARNING'
            when temperature_celsius < -20 then 'TEMPERATURE_LOW_WARNING'
            else 'TEMPERATURE_NORMAL'
        end as temperature_quality_flag,
        
        -- Humidity validation rules
        case 
            when humidity_percentage > 100 then 'HUMIDITY_IMPOSSIBLE_HIGH'
            when humidity_percentage < 0 then 'HUMIDITY_IMPOSSIBLE_LOW'
            when humidity_percentage > 95 then 'HUMIDITY_EXTREME_HIGH'
            when humidity_percentage < 5 then 'HUMIDITY_EXTREME_LOW'
            else 'HUMIDITY_NORMAL'
        end as humidity_quality_flag,
        
        -- Status consistency validation
        case 
            when sensor_status not in ('NORMAL', 'WARNING', 'CRITICAL', 'ANOMALY') then 'STATUS_INVALID'
            else 'STATUS_VALID'
        end as status_quality_flag,
        
        -- Temporal validation
        case 
            when measured_timestamp > current_timestamp then 'TIMESTAMP_FUTURE'
            when measured_timestamp < current_timestamp - interval '1 year' then 'TIMESTAMP_TOO_OLD'
            else 'TIMESTAMP_VALID'
        end as timestamp_quality_flag
        
    from "lakehouse"."public"."stg_sensor_data"
),

quality_assessment as (
    select
        *,
        
        -- Overall quality decision (Guard pillar enforcement)
        case 
            when temperature_quality_flag in ('TEMPERATURE_EXTREME_HIGH', 'TEMPERATURE_EXTREME_LOW')
                or humidity_quality_flag in ('HUMIDITY_IMPOSSIBLE_HIGH', 'HUMIDITY_IMPOSSIBLE_LOW')
                or status_quality_flag = 'STATUS_INVALID'
                or timestamp_quality_flag in ('TIMESTAMP_FUTURE', 'TIMESTAMP_TOO_OLD')
            then 'QUARANTINE_REQUIRED'
            
            when temperature_quality_flag in ('TEMPERATURE_HIGH_WARNING', 'TEMPERATURE_LOW_WARNING')
                or humidity_quality_flag in ('HUMIDITY_EXTREME_HIGH', 'HUMIDITY_EXTREME_LOW')
            then 'QUALITY_WARNING'
            
            else 'QUALITY_PASSED'
        end as overall_quality_status,
        
        -- Automatic action decision (Guard pillar automation)
        case 
            when temperature_quality_flag in ('TEMPERATURE_EXTREME_HIGH', 'TEMPERATURE_EXTREME_LOW') then true
            when humidity_quality_flag in ('HUMIDITY_IMPOSSIBLE_HIGH', 'HUMIDITY_IMPOSSIBLE_LOW') then true
            when status_quality_flag = 'STATUS_INVALID' then true
            when timestamp_quality_flag in ('TIMESTAMP_FUTURE', 'TIMESTAMP_TOO_OLD') then true
            else false
        end as auto_quarantine_flag,
        
        -- Guard pillar metadata
        current_timestamp as quality_validated_at,
        'dbt_guard_pillar' as validation_source
        
    from quality_checks
)

select 
    sensor_id,
    location_code,
    temperature_celsius,
    humidity_percentage,
    sensor_status,
    measured_timestamp,
    
    -- Quality assessment results
    temperature_quality_flag,
    humidity_quality_flag,
    status_quality_flag,
    timestamp_quality_flag,
    overall_quality_status,
    auto_quarantine_flag,
    
    -- Guard pillar metadata
    quality_validated_at,
    validation_source,
    
    -- Data lineage for audit trail
    processed_at as original_processing_time

from quality_assessment

-- Guard pillar principle: Only pass validated data to downstream
-- Note: In production, quarantined data would be moved to separate table
where overall_quality_status != 'QUARANTINE_REQUIRED'
   or auto_quarantine_flag = false

-- Ensure reproducible ordering for consistent results
order by measured_timestamp desc, sensor_id