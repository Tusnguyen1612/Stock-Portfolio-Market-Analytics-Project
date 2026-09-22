-- =====================================================================
-- INDEX BENCHMARK for "Stock Portfolio & Market Analytics Database"
-- Purpose: measure the real effect of your indexes on a realistically
--          sized dataset (your current data is too small: 300 price rows).
--
-- HOW TO USE
--   1. Restore your .backup into a NEW scratch database
--      (e.g. "mid_project_bench"). Do NOT run this on your submission DB.
--   2. Run this file in psql / pgAdmin Query Tool.
--   3. Read the "Execution Time" line of each EXPLAIN ANALYZE output.
--      Run each EXPLAIN 3-5 times and take the median (first run is cold).
-- =====================================================================

-- ---------- STEP 1: scale the data up (~1M rows per big table) -------
ALTER TABLE trades DISABLE TRIGGER trg_update_holdings;   -- keep holdings untouched

-- 20,000 synthetic stocks
INSERT INTO stocks (stock_id, stock_symbol, company_name, exchange_id, sector_id, listing_date)
SELECT 100000 + g, 'SYN' || g || '.HU', 'Synthetic ' || g,
       (SELECT min(exchange_id) FROM exchanges),
       (SELECT min(sector_id)   FROM sectors),
       DATE '2000-01-01'
FROM generate_series(1, 20000) g;

-- 1,000,000 price rows = 20,000 stocks x 50 trading days
INSERT INTO daily_market_prices
       (price_id, stock_id, price_date, open_price, close_price, high_price, low_price, volume)
SELECT 100000 + row_number() OVER (), 100000 + s, DATE '2026-01-01' + d, 100, 101, 102, 99, 1000
FROM generate_series(1, 20000) s, generate_series(0, 49) d;

-- 1,000,000 trades spread over 1,000 distinct dates, using REAL portfolio/stock ids
WITH p AS (SELECT array_agg(portfolio_id) a FROM portfolios),
     s AS (SELECT array_agg(stock_id)     a FROM stocks WHERE stock_id < 100000)
INSERT INTO trades (trade_id, portfolio_id, stock_id, trade_type, quantity, trade_price, trade_date)
SELECT 100000 + g,
       p.a[1 + g % array_length(p.a, 1)],
       s.a[1 + g % array_length(s.a, 1)],
       CASE WHEN g % 2 = 0 THEN 'BUY' ELSE 'SELL' END, 10, 100.50,
       CURRENT_DATE - (g % 1000)
FROM generate_series(1, 1000000) g, p, s;

ALTER TABLE trades ENABLE TRIGGER trg_update_holdings;
VACUUM ANALYZE;

SELECT 'stocks' AS tbl, count(*) FROM stocks
UNION ALL SELECT 'daily_market_prices', count(*) FROM daily_market_prices
UNION ALL SELECT 'trades', count(*) FROM trades;

-- ---------- TEST A: trades filtered by date (idx_trade_date) ---------
-- WITH the index
EXPLAIN ANALYZE SELECT * FROM trades WHERE trade_date = CURRENT_DATE - 100;
-- WITHOUT the index (nothing else covers trade_date)
DROP INDEX idx_trade_date;
EXPLAIN ANALYZE SELECT * FROM trades WHERE trade_date = CURRENT_DATE - 100;
CREATE INDEX idx_trade_date ON public.trades USING btree (trade_date);

-- ---------- TEST B: price history of one stock (idx_price_stock_id) --
-- Compare: (1) all indexes, (2) named indexes dropped, (3) forced seq scan
EXPLAIN ANALYZE SELECT * FROM daily_market_prices WHERE stock_id = 110000;

DROP INDEX idx_price_stock_id;
DROP INDEX idx_daily_market_prices_stock_date;
EXPLAIN ANALYZE SELECT * FROM daily_market_prices WHERE stock_id = 110000;
-- ^ still fast: UNIQUE (stock_id, price_date) = uq_stock_price_date already covers it

BEGIN;
SET LOCAL enable_indexscan = off; SET LOCAL enable_bitmapscan = off; SET LOCAL enable_indexonlyscan = off;
EXPLAIN ANALYZE SELECT * FROM daily_market_prices WHERE stock_id = 110000;   -- true "no index" cost
ROLLBACK;

CREATE INDEX idx_price_stock_id ON public.daily_market_prices USING btree (stock_id);
CREATE INDEX idx_daily_market_prices_stock_date ON public.daily_market_prices USING btree (stock_id, price_date);

-- ---------- TEST C: stock lookup by symbol + join to prices ----------
EXPLAIN ANALYZE SELECT * FROM stocks WHERE stock_symbol = 'SYN15000.HU';

BEGIN;
SET LOCAL enable_indexscan = off; SET LOCAL enable_bitmapscan = off; SET LOCAL enable_indexonlyscan = off;
EXPLAIN ANALYZE SELECT * FROM stocks WHERE stock_symbol = 'SYN15000.HU';    -- no index
EXPLAIN ANALYZE SELECT s.stock_symbol, d.price_date, d.close_price
FROM daily_market_prices d JOIN stocks s USING (stock_id)
WHERE s.stock_symbol = 'SYN15000.HU';                                       -- join, no index
ROLLBACK;

EXPLAIN ANALYZE SELECT s.stock_symbol, d.price_date, d.close_price
FROM daily_market_prices d JOIN stocks s USING (stock_id)
WHERE s.stock_symbol = 'SYN15000.HU';                                       -- join, with indexes

-- ---------- TEST D: are some of your indexes redundant? --------------
SELECT indexrelid::regclass AS index_name, indrelid::regclass AS table_name,
       pg_get_indexdef(indexrelid) AS definition
FROM pg_index
WHERE indrelid IN ('stocks'::regclass, 'daily_market_prices'::regclass, 'portfolio_holdings'::regclass)
ORDER BY indrelid::regclass::text, definition;
-- idx_stock_symbol           duplicates the UNIQUE stocks_stock_symbol_key
-- idx_price_stock_id         is a prefix of uq_stock_price_date (stock_id, price_date)
-- idx_daily_market_prices_stock_date  is identical to uq_stock_price_date
-- idx_portfolio_holdings_portfolio_stock is identical to uq_portfolio_stock

-- ---------- CLEANUP: delete the scratch database when finished -------
