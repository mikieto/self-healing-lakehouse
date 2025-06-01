-- Three Pillars Health Monitoring Tables
-- =====================================
-- Purpose: Enable health check queries for system monitoring

-- Create health monitoring schema
CREATE SCHEMA IF NOT EXISTS monitoring;

-- System health status table
CREATE TABLE IF NOT EXISTS monitoring.system_health (
    id SERIAL PRIMARY KEY,
    pillar VARCHAR(20) NOT NULL,
    component VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    last_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details JSONB
);

-- Insert initial health status
INSERT INTO monitoring.system_health (pillar, component, status, details) VALUES
('code', 'postgresql', 'healthy', '{"version": "15", "purpose": "data foundation"}'),
('code', 'dbt', 'ready', '{"status": "initialized", "models": "three_pillars"}'),
('observability', 'grafana', 'active', '{"port": 3000, "dashboards": "provisioned"}'),
('observability', 'prometheus', 'collecting', '{"port": 9090, "targets": "configured"}'),
('guard', 'data_quality', 'enforced', '{"rules": "active", "validation": "enabled"}'),
('guard', 'health_monitor', 'active', '{"endpoint": "http://localhost:8080"}');

-- Health check function
CREATE OR REPLACE FUNCTION monitoring.get_pillars_health()
RETURNS TABLE(pillar TEXT, healthy_components INTEGER, total_components INTEGER, health_percentage NUMERIC)
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.pillar::TEXT,
        COUNT(CASE WHEN h.status IN ('healthy', 'active', 'ready', 'collecting', 'enforced') THEN 1 END)::INTEGER as healthy_components,
        COUNT(*)::INTEGER as total_components,
        ROUND(100.0 * COUNT(CASE WHEN h.status IN ('healthy', 'active', 'ready', 'collecting', 'enforced') THEN 1 END) / COUNT(*), 1) as health_percentage
    FROM monitoring.system_health h
    GROUP BY h.pillar
    ORDER BY h.pillar;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT USAGE ON SCHEMA monitoring TO demo;
GRANT SELECT ON ALL TABLES IN SCHEMA monitoring TO demo;
GRANT EXECUTE ON FUNCTION monitoring.get_pillars_health() TO demo;