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
