-- ===============================================
-- [CODE PILLAR] Business Logic Implementation
-- ===============================================
-- Purpose: Implement consistent business rules and calculations
-- Benefit: Reproducible business logic that never changes between runs
-- Three Pillars Role: Ensures business rules are applied consistently
-- Learning Value: Shows how Code pillar enforces business consistency

{{ config(materialized='table') }}

select
    location_code,
    
    -- Reproducible aggregations (Code pillar strength)
    count(*) as total_readings,
    count(distinct sensor_id) as unique_sensors,
    
    -- Statistical measures - always calculated the same way
    round(avg(temperature_celsius), 2) as avg_temperature,
    round(avg(humidity_percentage), 2) as avg_humidity,
    
    min(temperature_celsius) as min_temperature,
    max(temperature_celsius) as max_temperature,
    
    -- Business rule: Define environment classification
    case 
        when avg(temperature_celsius) > 30 then 'HOT'
        when avg(temperature_celsius) > 20 then 'MODERATE'
        else 'COOL'
    end as environment_classification,
    
    -- Code pillar metadata
    min(measured_timestamp) as earliest_reading,
    max(measured_timestamp) as latest_reading,
    max(processed_at) as last_processed_at

from {{ ref('stg_sensor_data') }}

group by location_code

-- Code pillar principle: Reproducible ordering
order by location_code
