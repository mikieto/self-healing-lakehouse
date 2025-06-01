
  
    

  create  table "lakehouse"."local_analytics"."stg_sensor_data__dbt_tmp"
  
  
    as
  
  (
    

select
    id,
    sensor_id,
    temperature,
    humidity,
    cast(measured_at as timestamp) as measured_at,
    status,
    location,
    -- Data quality flag for Technical Survival Strategy
    case 
        when temperature > 100 or humidity < 20 then 'QUALITY_ISSUE'
        when status = 'ANOMALY' then 'DETECTED_ANOMALY'
        else 'HEALTHY'
    end as data_quality_flag,
    current_timestamp as processed_at
from "lakehouse"."local_analytics"."sensor_readings"
  );
  