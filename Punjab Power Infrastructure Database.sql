-- Createing tables for Punjab Power Infrastructure Database

-- 1. Cities
CREATE TABLE cities (
    city_id INTEGER PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    province VARCHAR(100) DEFAULT 'Punjab',
    population INTEGER
);
-- 2. Power Plants
CREATE TABLE power_plants (
    plant_id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    capacity_mw NUMERIC(10,2) NOT NULL CHECK (capacity_mw > 0),
    location VARCHAR(150) NOT NULL,
    status VARCHAR(50) NOT NULL
);
-- 3. Grid Stations
CREATE TABLE grid_stations (
    station_id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city_id INTEGER NOT NULL REFERENCES cities(city_id),
    capacity_mwa NUMERIC(10,2) NOT NULL CHECK (capacity_mwa > 0)
);
-- 4. Power Plant Supply
CREATE TABLE power_plant_supply (
    id INTEGER PRIMARY KEY,
    plant_id INTEGER NOT NULL REFERENCES power_plants(plant_id),
    station_id INTEGER NOT NULL REFERENCES grid_stations(station_id),
    supply_capacity_mw NUMERIC(10,2) CHECK (supply_capacity_mw > 0),
    UNIQUE (plant_id, station_id)
);
-- 5. Plant Production
CREATE TABLE plant_production (
    record_id INTEGER PRIMARY KEY,
    plant_id INTEGER NOT NULL REFERENCES power_plants(plant_id),
    year INTEGER NOT NULL CHECK (year BETWEEN 2000 AND 2100),
    total_generated_mwh NUMERIC(12,2) NOT NULL CHECK (total_generated_mwh >= 0),
    peak_load_mw NUMERIC(10,2) CHECK (peak_load_mw > 0),
    downtime_hours INTEGER CHECK (downtime_hours >= 0),
    UNIQUE (plant_id, year)
);
-- 6. City Consumption
CREATE TABLE city_consumption (
    record_id INTEGER PRIMARY KEY,
    city_id INTEGER NOT NULL REFERENCES cities(city_id),
    year INTEGER NOT NULL CHECK (year BETWEEN 2000 AND 2100),
    total_consumption_mwh NUMERIC(12,2) NOT NULL CHECK (total_consumption_mwh >= 0),
    peak_demand_mw NUMERIC(10,2) CHECK (peak_demand_mw > 0),
    avg_consumption_per_capita NUMERIC(8,2) CHECK (avg_consumption_per_capita > 0),
    UNIQUE (city_id, year)
);
-- 7. Transmission Lines
CREATE TABLE transmission_lines (
    line_id INTEGER PRIMARY KEY,
    from_station_id INTEGER NOT NULL REFERENCES grid_stations(station_id),
    to_station_id INTEGER NOT NULL REFERENCES grid_stations(station_id),
    voltage_level VARCHAR(20) NOT NULL,
    length_km NUMERIC(10,2) NOT NULL CHECK (length_km > 0),
    status VARCHAR(50) NOT NULL,
    max_capacity_mw NUMERIC(10,2) CHECK (max_capacity_mw > 0),
    CHECK (from_station_id <> to_station_id),
    UNIQUE (from_station_id, to_station_id)
);

-- Your first duty (Looking at the schema)

SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
-- 			or
SELECT table_schema, table_name  
FROM information_schema.tables; 

-- Look at the columns of the tables of database

SELECT * FROM cities;

SELECT * FROM power_plants;

SELECT * FROM grid_stations;

SELECT * FROM power_plant_supply;

SELECT * FROM plant_production;

SELECT * FROM city_consumption;

SELECT * FROM transmission_lines;

-- Examples

-- Create temp table which we will deleate later
CREATE TABLE demo_cities (
    city_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    population INT
);

-- Insert test record
INSERT INTO demo_cities (name, population)
VALUES ('TestCity', 100000);

-- Verify output
SELECT * 
FROM demo_cities 
WHERE name = 'TestCity';

-- 4. Update test record (safe targeting)
UPDATE demo_cities 
SET population = 99999999 
WHERE name = 'TestCity';  

-- 5. View changes
SELECT * 
FROM demo_cities;

-- this table will be deleated using GUI


-- Extracting Strategic Insights from Power Data

--  Identify highest consumption in 2024
SELECT c.city_name, cc.total_consumption_mwh
FROM city_consumption cc
JOIN cities c ON cc.city_id = c.city_id
WHERE cc.year = 2024
ORDER BY cc.total_consumption_mwh DESC
LIMIT 5;

-- Yearly downtime by plant type
SELECT p.type, pp.year, 
       AVG(pp.downtime_hours) AS avg_downtime
FROM plant_production pp
JOIN power_plants p ON pp.plant_id = p.plant_id
GROUP BY p.type, pp.year
ORDER BY pp.year, p.type;

-- Transmission Line Utilization
SELECT tl.line_id, 
       tl.voltage_level,
       tl.max_capacity_mw,
       MAX(gs.capacity_mwa) AS peak_flow,
       ROUND(MAX(gs.capacity_mwa)/tl.max_capacity_mw*100,1) AS util_pct
FROM transmission_lines tl
JOIN grid_stations gs ON tl.to_station_id = gs.station_id
GROUP BY tl.line_id