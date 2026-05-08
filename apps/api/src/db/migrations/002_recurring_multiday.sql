-- ─────────────────────────────────────────────────────────────────────────────
-- Rename day_of_week → days_of_week (SMALLINT → SMALLINT[])
-- The original inline CHECK has an auto-generated name — drop it dynamically.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Drop the old inline CHECK constraint (whatever name Postgres gave it)
DO $$
DECLARE
  v_conname text;
BEGIN
  SELECT conname INTO v_conname
  FROM pg_constraint
  WHERE conrelid = 'recurring_configs'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%day_of_week%';
  IF v_conname IS NOT NULL THEN
    EXECUTE format('ALTER TABLE recurring_configs DROP CONSTRAINT %I', v_conname);
  END IF;
END $$;

-- 2. Rename column
ALTER TABLE recurring_configs RENAME COLUMN day_of_week TO days_of_week;

-- 3. Change type SMALLINT → SMALLINT[], migrating existing single values
ALTER TABLE recurring_configs
  ALTER COLUMN days_of_week TYPE SMALLINT[]
  USING CASE WHEN days_of_week IS NULL THEN NULL ELSE ARRAY[days_of_week] END;

-- 4. Add new constraint: 1–6 elements, values 0–6 only
ALTER TABLE recurring_configs
  ADD CONSTRAINT recurring_configs_days_of_week_check
  CHECK (
    days_of_week IS NULL OR (
      array_length(days_of_week, 1) BETWEEN 1 AND 6
      AND days_of_week <@ ARRAY[0, 1, 2, 3, 4, 5, 6]::SMALLINT[]
    )
  );
