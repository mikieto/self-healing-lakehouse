
  create view "lakehouse"."local_analytics"."stg_example_data__dbt_tmp"
    
    
  as (
    -- This is a simple example model.
-- It just selects some static values.
-- In a real project, this would typically select from a source table.

select
    1 as id,
    'example_value' as description,
    current_timestamp as loaded_at
  );