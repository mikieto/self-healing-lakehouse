
  
    

  create  table "lakehouse"."local_analytics"."mart_survival_metrics__dbt_tmp"
  
  
    as
  
  (
    

-- Technical Survival Strategy metrics for three pillars
with survival_metrics as (
    select
        'code' as pillar,
        'terraform_iac' as component,
        count(*) as record_count,
        count(distinct location) as unique_locations,
        avg(case when data_quality_flag = 'HEALTHY' then 1 else 0 end) * 100 as health_percentage,
        'Terraform Unified IaC + AWS Official Modules' as implementation_pattern,
        current_timestamp as calculated_at
    from "lakehouse"."local_analytics"."stg_sensor_data"
    
    union all
    
    select
        'observability' as pillar,
        'aws_observability_accelerator' as component,
        count(*) as record_count,
        count(case when status = 'ANOMALY' then 1 end) as anomaly_count,
        avg(case when status = 'NORMAL' then 1 else 0 end) * 100 as health_percentage,
        'AWS Official Terraform Module Integrated Monitoring' as implementation_pattern,
        current_timestamp as calculated_at
    from "lakehouse"."local_analytics"."stg_sensor_data"
    
    union all
    
    select
        'guard' as pillar,
        'glue_data_quality_terraform' as component,
        count(*) as record_count,
        count(case when data_quality_flag = 'QUALITY_ISSUE' then 1 end) as quality_issues,
        avg(case when data_quality_flag = 'HEALTHY' then 1 else 0 end) * 100 as health_percentage,
        'Terraform Glue DQ + EventBridge Self-Healing' as implementation_pattern,
        current_timestamp as calculated_at
    from "lakehouse"."local_analytics"."stg_sensor_data"
)

select * from survival_metrics
  );
  