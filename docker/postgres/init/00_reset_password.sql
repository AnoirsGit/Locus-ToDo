-- Runs only on first init (empty data dir).
-- Ensures the superuser password matches POSTGRES_PASSWORD env var.
ALTER USER postgres WITH PASSWORD 'postgres';
