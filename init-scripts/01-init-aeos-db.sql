-- AEOS Database Initialization Script
-- This script sets up the basic AEOS database schema

-- Create AEOS schema
CREATE SCHEMA IF NOT EXISTS aeos;

-- Set search path
SET search_path TO aeos, public;

-- System configuration table
CREATE TABLE IF NOT EXISTS system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(255) UNIQUE NOT NULL,
    config_value TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Carriers (people/vehicles with access)
CREATE TABLE IF NOT EXISTS carriers (
    id SERIAL PRIMARY KEY,
    carrier_code VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Access points (doors)
CREATE TABLE IF NOT EXISTS access_points (
    id SERIAL PRIMARY KEY,
    access_point_code VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255),
    location VARCHAR(255),
    controller_id INTEGER,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Entrances
CREATE TABLE IF NOT EXISTS entrances (
    id SERIAL PRIMARY KEY,
    entrance_code VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Templates (authorization groups)
CREATE TABLE IF NOT EXISTS templates (
    id SERIAL PRIMARY KEY,
    template_code VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Carrier authorizations
CREATE TABLE IF NOT EXISTS carrier_authorizations (
    id SERIAL PRIMARY KEY,
    carrier_id INTEGER REFERENCES carriers(id),
    template_id INTEGER REFERENCES templates(id),
    entrance_id INTEGER REFERENCES entrances(id),
    valid_from TIMESTAMP,
    valid_until TIMESTAMP,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Access events log
CREATE TABLE IF NOT EXISTS access_events (
    id SERIAL PRIMARY KEY,
    carrier_id INTEGER REFERENCES carriers(id),
    access_point_id INTEGER REFERENCES access_points(id),
    event_type VARCHAR(50),
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN,
    message TEXT
);

-- Door controllers (AEpus)
CREATE TABLE IF NOT EXISTS door_controllers (
    id SERIAL PRIMARY KEY,
    controller_code VARCHAR(50) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    mac_address VARCHAR(17),
    firmware_version VARCHAR(50),
    status VARCHAR(50),
    last_seen TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default system configuration
INSERT INTO system_config (config_key, config_value, description) VALUES
    ('system.version', '2023.1.x', 'AEOS System Version'),
    ('system.initialized', 'true', 'System Initialization Flag'),
    ('system.timezone', 'UTC', 'System Timezone')
ON CONFLICT (config_key) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_carriers_code ON carriers(carrier_code);
CREATE INDEX IF NOT EXISTS idx_carriers_active ON carriers(active);
CREATE INDEX IF NOT EXISTS idx_access_points_code ON access_points(access_point_code);
CREATE INDEX IF NOT EXISTS idx_access_events_time ON access_events(event_time);
CREATE INDEX IF NOT EXISTS idx_carrier_auth_carrier ON carrier_authorizations(carrier_id);
CREATE INDEX IF NOT EXISTS idx_carrier_auth_active ON carrier_authorizations(active);

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA aeos TO aeos;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA aeos TO aeos;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA aeos TO aeos;
