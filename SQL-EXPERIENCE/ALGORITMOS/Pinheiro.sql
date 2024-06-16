

DECLARE @image AS TABLE (
  row_id tinyint
);

INSERT INTO @image (row_id)
  VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9)

SELECT
  CASE
    WHEN MAX(i.row_id) OVER () - i.row_id > 1 THEN REPLICATE(' ', MAX(i.row_id) OVER () - 2 - i.row_id) + REPLICATE('*', i.row_id) + REPLICATE('*', i.row_id - 1)
    ELSE REPLICATE(' ', MAX(i.row_id) OVER () - 3) + '|'
  END img
FROM @image i
