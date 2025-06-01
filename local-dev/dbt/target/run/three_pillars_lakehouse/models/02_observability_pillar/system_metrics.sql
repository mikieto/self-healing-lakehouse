
  
    

  create  table "lakehouse"."public"."system_metrics__dbt_tmp"
  
  
    as
  
  (
    -- =====================================================
-- [OBSERVABILITY PILLAR] Real-time System Monitoring
-- =====================================================
-- Purpose: Generate metrics for immediate system visibility and monitoring
-- Benefit: Real-time awareness of system health, performance, and issues
-- Three Pillars Role: Enables rapid detection and response to problems
-- Learning Value: Demonstrates proactive monitoring approach



with sensor_health as (
    select
        sensor_id,
        location_code,
        sensor_status,
        temperature_celsius,
        humidity_percentage,
        measured_timestamp,
        
        -- Health scoring for observability
        case 
            when sensor_status = 'NORMAL' then 1.0
            when sensor_status = 'WARNING' then 0.7
            when sensor_status = 'CRITICAL' then 0.3
            else 0.0
        end as health_score
        
    from "lakehouse"."public"."stg_sensor_data"
),

system_overview as (
    select
        'sensor_data_pipeline' as system_component,
        
        -- Volume metrics for capacity monitoring
        count(*) as total_records_processed,
        count(distinct sensor_id) as active_sensors,
        count(distinct location_code) as monitored_locations,
        
        -- Health metrics for operational monitoring
        round(avg(health_score), 3) as overall_system_health,
        sum(case when sensor_status = 'NORMAL' then 1 else 0 end) as healthy_readings,
        sum(case when sensor_status != 'NORMAL' then 1 else 0 end) as problematic_readings,
        
        -- Performance metrics for efficiency monitoring
        round(avg(temperature_celsius), 2) as avg_temperature_observed,
        round(stddev(temperature_celsius), 2) as temperature_variability,
        
        -- Timeliness metrics for pipeline monitoring
        max(measured_timestamp) as latest_sensor_reading,
        max(measured_timestamp) as latest_processing_time,
        
        -- Real-time observability timestamp
        current_timestamp as metrics_generated_at,
        
        -- Alert thresholds for automated monitoring
        case 
            when avg(health_score) < 0.8 then 'SYSTEM_DEGRADED'
            when count(distinct sensor_id) < 5 then 'LOW_SENSOR_COUNT'
            when max(measured_timestamp) < current_timestamp - interval '1 hour' then 'PROCESSING_DELAYED'
            else 'SYSTEM_HEALTHY'
        end as system_alert_status
        
    from sensor_health
)

select * from system_overview

-- Observability pillar principle: Always include monitoring metadata
union all

select
    concat('location_', location_code) as system_component,
    count(*) as total_records_processed,
    count(distinct sensor_id) as active_sensors,
    1 as monitored_locations, -- This location
    round(avg(health_score), 3) as overall_system_health,
    sum(case when sensor_status = 'NORMAL' then 1 else 0 end) as healthy_readings,
    sum(case when sensor_status != 'NORMAL' then 1 else 0 end) as problematic_readings,
    round(avg(temperature_celsius), 2) as avg_temperature_observed,
    round(stddev(temperature_celsius), 2) as temperature_variability,
    max(measured_timestamp) as latest_sensor_reading,
    max(measured_timestamp) as latest_processing_time,
    current_timestamp as metrics_generated_at,
    case 
        when avg(health_score) < 0.8 then 'LOCATION_DEGRADED'
        when count(distinct sensor_id) < 2 then 'LOW_SENSOR_COVERAGE'
        else 'LOCATION_HEALTHY'
    end as system_alert_status
    
from sensor_health
group by location_code
  );
  