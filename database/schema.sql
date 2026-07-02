-- Create Database
CREATE DATABASE IF NOT EXISTS iot_platform_db;
USE iot_platform_db;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    github_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Projects Table
CREATE TABLE IF NOT EXISTS projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    github_repo_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Microcontrollers Table
CREATE TABLE IF NOT EXISTS microcontrollers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model VARCHAR(255) NOT NULL,
    version VARCHAR(255) NOT NULL,
    pin_configuration JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pins Table
CREATE TABLE IF NOT EXISTS pins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    microcontroller_id INT,
    pin_number VARCHAR(50) NOT NULL,
    `function` VARCHAR(255),
    FOREIGN KEY (microcontroller_id) REFERENCES microcontrollers(id) ON DELETE CASCADE
);

-- Sensors & Actuators Table
CREATE TABLE IF NOT EXISTS components (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type ENUM('sensor', 'actuator') NOT NULL,
    description TEXT
);

-- Project Components Mapping
CREATE TABLE IF NOT EXISTS project_components (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT,
    microcontroller_id INT,
    pin_id INT,
    component_id INT,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (microcontroller_id) REFERENCES microcontrollers(id) ON DELETE CASCADE,
    FOREIGN KEY (pin_id) REFERENCES pins(id) ON DELETE CASCADE,
    FOREIGN KEY (component_id) REFERENCES components(id) ON DELETE CASCADE
);

-- Network devices discovered by IP/MAC. Sensor readings are grouped here.
CREATE TABLE IF NOT EXISTS iot_devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT,
    microcontroller_id INT,
    hardware_id VARCHAR(120) NOT NULL,
    device_name VARCHAR(255),
    ip_address VARCHAR(45) NOT NULL,
    mac_address VARCHAR(50),
    firmware_version VARCHAR(80),
    last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_hardware_id (hardware_id),
    KEY idx_iot_devices_ip (ip_address),
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL,
    FOREIGN KEY (microcontroller_id) REFERENCES microcontrollers(id) ON DELETE SET NULL
);

-- Real-time sensor readings posted by hardware.
-- `readings` stores flexible payloads such as:
-- {"temperature": 29.4, "humidity": 62, "pressure": 1009.8}
CREATE TABLE IF NOT EXISTS sensor_readings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    device_id INT NOT NULL,
    project_id INT,
    hardware_id VARCHAR(120) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    sensor_type VARCHAR(120),
    readings JSON NOT NULL,
    raw_payload JSON,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_sensor_readings_device_time (device_id, recorded_at),
    KEY idx_sensor_readings_ip_time (ip_address, recorded_at),
    KEY idx_sensor_readings_hardware_time (hardware_id, recorded_at),
    FOREIGN KEY (device_id) REFERENCES iot_devices(id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL
);

-- Insert initial projects
INSERT INTO projects (name, description) VALUES
('Criminal Activity Detector and Monitoring System (CADMS)', 'Detects and monitors criminal activities.'),
('SmartHome (SH)', 'Home automation and monitoring.'),
('Smart Traffic Controll and Monitoring System (STCMS)', 'Traffic management and monitoring.'),
('Drone Controller (DC)', 'Control and monitor drones.'),
('Bahan Kavach (BK)', 'Vehicle protection system.'),
('Blind Curve Monitoring System (BCMS)', 'Safety system for blind curves.'),
('Wild Animal Monitoring System (WAMS)', 'Wildlife tracking and monitoring.'),
('CommStick (CS)', 'Communication stick for specific needs.'),
('High Speed Data Transmitter (HSDT, FSO)', 'Optical wireless communication system.'),
('Smart Healthcare Monitoring (SHCM)', 'Health tracking and monitoring.'),
('Water Quality Monitoring System (WQMS)', 'Water quality analysis and monitoring.'),
('Weather Monitoring System (WMS)', 'Weather station and data tracking.'),
('Soil Quality Monitoring System (SQM)', 'Soil health monitoring for agriculture.'),
('Indoor Pollution Monitoring System (IPMS)', 'Monitors indoor air quality.'),
('Underground Pollution Monitoring System (UPMS)', 'Monitors pollution levels underground.'),
('Outdoor Pollution Monitoring System (OPMS)', 'Monitors outdoor air quality.'),
('All in one IoT Monitoring System (AIoTMS)', 'Comprehensive IoT monitoring platform.'),
('All in one Energy Monitoring System (AMS)', 'Energy consumption and efficiency monitoring.');
