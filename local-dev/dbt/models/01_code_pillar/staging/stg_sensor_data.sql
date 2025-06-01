-- ================================================
-- [CODE PILLAR] Reproducible Data Standardization
-- ================================================
-- Purpose: Transform raw sensor data into standardized, consistent format
-- Benefit: Same code always produces same result - eliminates manual intervention
-- Three Pillars Role: Foundation for reliable, reproducible automation
-- Learning Value: Demonstrates declarative data transformation principles

{{ config(materialized='table') }}

select
    -- Standardized sensor identification
    sensor_id,
    
    -- Normalized measurements with explicit data types
    cast(temperature as decimal(5,2)) as temperature_celsius,
    cast(humidity as decimal(5,2)) as humidity_percentage,
    
    -- Standardized timestamp for consistent temporal analysis
    cast(measured_at as timestamp) as measured_timestamp,
    
    -- Status normalization - consistent values across all data
    upper(trim(status)) as sensor_status,
    
    -- Location standardization for consistent grouping
    upper(trim(location)) as location_code,
    
    -- Processing metadata for observability and auditability
    current_timestamp as processed_at,
    'dbt_code_pillar' as processing_source,
    
    -- Data lineage tracking (Code pillar principle)
    '{{ run_started_at }}' as dbt_run_started_at

from {{ ref('sensor_readings') }}

-- Code pillar principle: Explicit data validation at source
where 
    sensor_id is not null
    and measured_at is not null
    -- Basic sanity checks to ensure data quality
    and temperature is not null
    and humidity is not null
