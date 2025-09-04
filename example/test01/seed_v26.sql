\set ON_ERROR_STOP on

-- 1) 建库
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname='migrate_demo') THEN
    EXECUTE 'CREATE DATABASE migrate_demo';
  END IF;
END$$;

\c migrate_demo

-- 2) 基础对象
CREATE SCHEMA IF NOT EXISTS s1;

-- 常规表（分布式）
CREATE TABLE IF NOT EXISTS s1.t_regular(
  id   int PRIMARY KEY,
  vtxt text,
  val  numeric(12,2) DEFAULT 0
) DISTRIBUTE BY HASH(id);

-- 分区表（范围分区）
CREATE TABLE IF NOT EXISTS s1.t_parted(
  id int,
  dy date NOT NULL,
  note text
) DISTRIBUTE BY HASH(id)
  PARTITION BY RANGE (dy);

CREATE TABLE IF NOT EXISTS s1.t_parted_2025m08 PARTITION OF s1.t_parted
  FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

CREATE TABLE IF NOT EXISTS s1.t_parted_2025m09 PARTITION OF s1.t_parted
  FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

-- 序列 + 视图
CREATE SEQUENCE IF NOT EXISTS s1.seq1;
CREATE OR REPLACE VIEW s1.v_regular AS
  SELECT id, upper(vtxt) AS vtxt_u, val FROM s1.t_regular;

-- 索引
CREATE INDEX IF NOT EXISTS idx_regular_val ON s1.t_regular(val);

-- 3) 数据
INSERT INTO s1.t_regular(id, vtxt, val)
SELECT g, '行-'||g, (g*1.23)::numeric(12,2)
FROM generate_series(1,50) g
ON CONFLICT (id) DO NOTHING;

INSERT INTO s1.t_parted(id, dy, note)
VALUES
  (1, '2025-08-29', 'late-aug'),
  (2, '2025-09-01', 'early-sep'),
  (3, '2025-09-02', 'mid-sep')
ON CONFLICT DO NOTHING;

-- 4) 快速检查
SELECT current_database() AS db, count(*) AS rows_regular FROM s1.t_regular;
SELECT current_database() AS db, count(*) AS rows_parted  FROM s1.t_parted;
