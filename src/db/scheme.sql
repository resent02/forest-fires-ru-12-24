CREATE TYPE location_level AS ENUM ('country', 'federal_district', 'region', 'other');

-- locations table
CREATE TABLE locations (
    location_id SERIAL PRIMARY KEY,
    parent_id INT REFERENCES locations(location_id),
    name VARCHAR(255) NOT NULL,
    level location_level NOT NULL,
    oktmo VARCHAR(20),
    okato VARCHAR(20),
    federal_district VARCHAR(255),
    country VARCHAR(255) DEFAULT 'Российская Федерация',
    UNIQUE (name, level, parent_id)
);

-- Supporting tables
CREATE TABLE land_types (
    land_type_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE statuses (
    status_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE countries (
    country_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    iso_code VARCHAR(2)
);

-- Main fire incident table
CREATE TABLE fires (
    fire_id SERIAL PRIMARY KEY,
    location_id INT NOT NULL REFERENCES locations(location_id),
    country_id INT REFERENCES countries(country_id),
    year INT NOT NULL,
    code VARCHAR(50) NOT NULL,
    fire_type VARCHAR(50) CHECK (fire_type IN ('Лесные', 'Нелесные')),
    latitude FLOAT,
    longitude FLOAT,
    forestry VARCHAR(255),
    date_beginning DATE NOT NULL,
    date_end DATE,
    area_beginning INT NOT NULL,
    area_total INT NOT NULL,
    current_state VARCHAR(255),
    UNIQUE (location_id, code, date_beginning)
);

-- Fire statistics table
CREATE TABLE fire_statistics (
    stat_id SERIAL PRIMARY KEY,
    location_id INT NOT NULL REFERENCES locations(location_id),
    date DATE NOT NULL,
    land_type_id INT REFERENCES land_types(land_type_id),
    status_id INT REFERENCES statuses(status_id),
    burning_grass_number INT NOT NULL,
    burning_grass_percent FLOAT CHECK (burning_grass_percent BETWEEN 0 AND 100),
    border_number INT NOT NULL,
    border_percent FLOAT CHECK (border_percent BETWEEN 0 AND 100),
    logging_number INT NOT NULL,
    logging_percent FLOAT CHECK (logging_percent BETWEEN 0 AND 100),
    linear_objects_number INT NOT NULL,
    linear_objects_percent FLOAT CHECK (linear_objects_percent BETWEEN 0 AND 100),
    locals_number INT NOT NULL,
    locals_percent FLOAT CHECK (locals_percent BETWEEN 0 AND 100),
    lightning_number INT NOT NULL,
    lightning_percent FLOAT CHECK (lightning_percent BETWEEN 0 AND 100),
    prevention_number INT NOT NULL,
    prevention_percent FLOAT CHECK (prevention_percent BETWEEN 0 AND 100),
    other_number INT NOT NULL,
    other_percent FLOAT CHECK (other_percent BETWEEN 0 AND 100),
    expeditions_number INT NOT NULL,
    expeditions_percent FLOAT CHECK (expeditions_percent BETWEEN 0 AND 100),
    unknown_number INT NOT NULL,
    UNIQUE (location_id, date, land_type_id, status_id)
);

-- Transboundary data
CREATE TABLE transboundary (
    transboundary_id SERIAL PRIMARY KEY,
    location_id INT REFERENCES locations(location_id),
    country_id INT REFERENCES countries(country_id),
    year INT NOT NULL,
    month INT CHECK (month BETWEEN 1 AND 12),
    trans_number_total INT NOT NULL,
    trans_area_total INT NOT NULL,
    rus_number_total INT NOT NULL,
    rus_area_total INT NOT NULL,
    abroad_number_total INT NOT NULL,
    abroad_area_total INT,
    UNIQUE (location_id, country_id, year, month)
);

-- Spatial extension
CREATE EXTENSION IF NOT EXISTS postgis;
SELECT AddGeometryColumn('fires', 'location', 4326, 'POINT', 2);

-- Indexes
CREATE INDEX idx_fires_location ON fires USING GIST(location);
CREATE INDEX idx_fire_stats_date ON fire_statistics(date);
CREATE INDEX idx_transboundary_year ON transboundary(year); 