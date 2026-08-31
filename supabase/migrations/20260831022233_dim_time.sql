CREATE TABLE IF NOT EXISTS dim_time (
    time_id SERIAL PRIMARY KEY,
    timestamp_utc TIMESTAMP WITH TIME ZONE UNIQUE NOT NULL,
    date_day DATE NOT NULL,
    hour INT NOT NULL CHECK (hour BETWEEN 0 AND 23),
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
    year INT NOT NULL
);