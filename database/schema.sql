-- Stock Portfolio & Market Analytics Database (PostgreSQL)
-- Readable schema extracted from the final project backup.
-- To rebuild WITH data, restore the .backup file instead (see README).

-- ====================================================================
-- TABLES
-- ====================================================================
CREATE TABLE public.daily_market_prices (
    price_id integer NOT NULL,
    stock_id integer NOT NULL,
    price_date date NOT NULL,
    open_price numeric(12,2) NOT NULL,
    close_price numeric(12,2) NOT NULL,
    high_price numeric(12,2) NOT NULL,
    low_price numeric(12,2) NOT NULL,
    volume bigint NOT NULL,
    CONSTRAINT chk_close_in_range CHECK (((close_price >= low_price) AND (close_price <= high_price))),
    CONSTRAINT chk_close_price CHECK ((close_price > (0)::numeric)),
    CONSTRAINT chk_high_low CHECK ((high_price >= low_price)),
    CONSTRAINT chk_open_in_range CHECK (((open_price >= low_price) AND (open_price <= high_price))),
    CONSTRAINT chk_open_price CHECK ((open_price > (0)::numeric)),
    CONSTRAINT chk_price_date_not_future CHECK ((price_date <= CURRENT_DATE)),
    CONSTRAINT chk_volume CHECK ((volume >= 0))
);

CREATE TABLE public.dividends (
    dividend_id integer NOT NULL,
    stock_id integer NOT NULL,
    dividend_date date NOT NULL,
    dividend_per_share numeric(10,2) NOT NULL,
    CONSTRAINT chk_dividend_per_share CHECK ((dividend_per_share >= (0)::numeric))
);

CREATE TABLE public.exchanges (
    exchange_id integer NOT NULL,
    exchange_name character varying(100) NOT NULL,
    country character varying(50) NOT NULL,
    currency character varying(10) NOT NULL
);

CREATE TABLE public.investors (
    investor_id integer NOT NULL,
    full_name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    phone character varying(20),
    country character varying(50),
    cash_balance numeric(18,2) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    risk_profile character varying(20),
    CONSTRAINT chk_cash_balance CHECK ((cash_balance >= (0)::numeric)),
    CONSTRAINT chk_email_format CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)),
    CONSTRAINT chk_risk_profile CHECK ((((risk_profile)::text = ANY (ARRAY[('LOW'::character varying)::text, ('MEDIUM'::character varying)::text, ('HIGH'::character varying)::text])) OR (risk_profile IS NULL)))
);

CREATE TABLE public.portfolio_holdings (
    holding_id integer NOT NULL,
    portfolio_id integer NOT NULL,
    stock_id integer NOT NULL,
    quantity_held integer DEFAULT 0 NOT NULL,
    avg_buy_price numeric(12,2) DEFAULT 0 NOT NULL,
    CONSTRAINT chk_avg_buy_price CHECK ((avg_buy_price >= (0)::numeric)),
    CONSTRAINT chk_quantity_held CHECK ((quantity_held >= 0))
);

CREATE TABLE public.portfolios (
    portfolio_id integer NOT NULL,
    investor_id integer NOT NULL,
    portfolio_name character varying(100) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    notes text
);

CREATE TABLE public.sectors (
    sector_id integer NOT NULL,
    sector_name character varying(50) NOT NULL
);

CREATE TABLE public.stocks (
    stock_id integer NOT NULL,
    stock_symbol character varying(15) NOT NULL,
    company_name character varying(200) NOT NULL,
    exchange_id integer NOT NULL,
    sector_id integer NOT NULL,
    listing_date date,
    CONSTRAINT chk_listing_date CHECK (((listing_date IS NULL) OR (listing_date <= CURRENT_DATE))),
    CONSTRAINT chk_stock_symbol_upper CHECK (((stock_symbol)::text = upper((stock_symbol)::text)))
);

CREATE TABLE public.trades (
    trade_id integer NOT NULL,
    portfolio_id integer NOT NULL,
    stock_id integer NOT NULL,
    trade_type character varying(4) NOT NULL,
    quantity integer NOT NULL,
    trade_price numeric(12,2) NOT NULL,
    trade_date date DEFAULT CURRENT_DATE NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_trade_date_not_future CHECK ((trade_date <= CURRENT_DATE)),
    CONSTRAINT chk_trade_price CHECK ((trade_price > (0)::numeric)),
    CONSTRAINT chk_trade_quantity CHECK ((quantity > 0)),
    CONSTRAINT chk_trade_type CHECK (((trade_type)::text = ANY (ARRAY[('BUY'::character varying)::text, ('SELL'::character varying)::text])))
);

-- ====================================================================
-- SEQUENCES (auto-increment ids)
-- ====================================================================
CREATE SEQUENCE public.daily_market_prices_price_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.dividends_dividend_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.exchanges_exchange_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.investors_investor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.portfolio_holdings_holding_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.portfolios_portfolio_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.sectors_sector_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.stocks_stock_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.trades_trade_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.daily_market_prices_price_id_seq OWNED BY public.daily_market_prices.price_id;

ALTER SEQUENCE public.dividends_dividend_id_seq OWNED BY public.dividends.dividend_id;

ALTER SEQUENCE public.exchanges_exchange_id_seq OWNED BY public.exchanges.exchange_id;

ALTER SEQUENCE public.investors_investor_id_seq OWNED BY public.investors.investor_id;

ALTER SEQUENCE public.portfolio_holdings_holding_id_seq OWNED BY public.portfolio_holdings.holding_id;

ALTER SEQUENCE public.portfolios_portfolio_id_seq OWNED BY public.portfolios.portfolio_id;

ALTER SEQUENCE public.sectors_sector_id_seq OWNED BY public.sectors.sector_id;

ALTER SEQUENCE public.stocks_stock_id_seq OWNED BY public.stocks.stock_id;

ALTER SEQUENCE public.trades_trade_id_seq OWNED BY public.trades.trade_id;

ALTER TABLE ONLY public.daily_market_prices ALTER COLUMN price_id SET DEFAULT nextval('public.daily_market_prices_price_id_seq'::regclass);

ALTER TABLE ONLY public.dividends ALTER COLUMN dividend_id SET DEFAULT nextval('public.dividends_dividend_id_seq'::regclass);

ALTER TABLE ONLY public.exchanges ALTER COLUMN exchange_id SET DEFAULT nextval('public.exchanges_exchange_id_seq'::regclass);

ALTER TABLE ONLY public.investors ALTER COLUMN investor_id SET DEFAULT nextval('public.investors_investor_id_seq'::regclass);

ALTER TABLE ONLY public.portfolio_holdings ALTER COLUMN holding_id SET DEFAULT nextval('public.portfolio_holdings_holding_id_seq'::regclass);

ALTER TABLE ONLY public.portfolios ALTER COLUMN portfolio_id SET DEFAULT nextval('public.portfolios_portfolio_id_seq'::regclass);

ALTER TABLE ONLY public.sectors ALTER COLUMN sector_id SET DEFAULT nextval('public.sectors_sector_id_seq'::regclass);

ALTER TABLE ONLY public.stocks ALTER COLUMN stock_id SET DEFAULT nextval('public.stocks_stock_id_seq'::regclass);

ALTER TABLE ONLY public.trades ALTER COLUMN trade_id SET DEFAULT nextval('public.trades_trade_id_seq'::regclass);

-- ====================================================================
-- PRIMARY KEY / UNIQUE CONSTRAINTS
-- ====================================================================
ALTER TABLE ONLY public.daily_market_prices
    ADD CONSTRAINT daily_market_prices_pkey PRIMARY KEY (price_id);

ALTER TABLE ONLY public.dividends
    ADD CONSTRAINT dividends_pkey PRIMARY KEY (dividend_id);

ALTER TABLE ONLY public.exchanges
    ADD CONSTRAINT exchanges_exchange_name_key UNIQUE (exchange_name);

ALTER TABLE ONLY public.exchanges
    ADD CONSTRAINT exchanges_pkey PRIMARY KEY (exchange_id);

ALTER TABLE ONLY public.investors
    ADD CONSTRAINT investors_email_key UNIQUE (email);

ALTER TABLE ONLY public.investors
    ADD CONSTRAINT investors_phone_key UNIQUE (phone);

ALTER TABLE ONLY public.investors
    ADD CONSTRAINT investors_pkey PRIMARY KEY (investor_id);

ALTER TABLE ONLY public.portfolio_holdings
    ADD CONSTRAINT portfolio_holdings_pkey PRIMARY KEY (holding_id);

ALTER TABLE ONLY public.portfolios
    ADD CONSTRAINT portfolios_pkey PRIMARY KEY (portfolio_id);

ALTER TABLE ONLY public.sectors
    ADD CONSTRAINT sectors_pkey PRIMARY KEY (sector_id);

ALTER TABLE ONLY public.sectors
    ADD CONSTRAINT sectors_sector_name_key UNIQUE (sector_name);

ALTER TABLE ONLY public.stocks
    ADD CONSTRAINT stocks_pkey PRIMARY KEY (stock_id);

ALTER TABLE ONLY public.stocks
    ADD CONSTRAINT stocks_stock_symbol_key UNIQUE (stock_symbol);

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT trades_pkey PRIMARY KEY (trade_id);

ALTER TABLE ONLY public.dividends
    ADD CONSTRAINT uq_dividend_stock_date UNIQUE (stock_id, dividend_date);

ALTER TABLE ONLY public.portfolios
    ADD CONSTRAINT uq_investor_portfolio_name UNIQUE (investor_id, portfolio_name);

ALTER TABLE ONLY public.portfolio_holdings
    ADD CONSTRAINT uq_portfolio_stock UNIQUE (portfolio_id, stock_id);

ALTER TABLE ONLY public.daily_market_prices
    ADD CONSTRAINT uq_stock_price_date UNIQUE (stock_id, price_date);

-- ====================================================================
-- FOREIGN KEYS
-- ====================================================================
ALTER TABLE ONLY public.daily_market_prices
    ADD CONSTRAINT daily_market_prices_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.stocks(stock_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.dividends
    ADD CONSTRAINT dividends_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.stocks(stock_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.portfolio_holdings
    ADD CONSTRAINT portfolio_holdings_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolios(portfolio_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.portfolio_holdings
    ADD CONSTRAINT portfolio_holdings_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.stocks(stock_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.portfolios
    ADD CONSTRAINT portfolios_investor_id_fkey FOREIGN KEY (investor_id) REFERENCES public.investors(investor_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.stocks
    ADD CONSTRAINT stocks_exchange_id_fkey FOREIGN KEY (exchange_id) REFERENCES public.exchanges(exchange_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.stocks
    ADD CONSTRAINT stocks_sector_id_fkey FOREIGN KEY (sector_id) REFERENCES public.sectors(sector_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT trades_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolios(portfolio_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT trades_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.stocks(stock_id) ON DELETE RESTRICT;

-- ====================================================================
-- FUNCTIONS
-- ====================================================================
CREATE FUNCTION public.portfolio_roi(p_portfolio_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE 
    total_sell_value NUMERIC;
    total_sell_quantity NUMERIC;
    avg_buy_price_portfolio NUMERIC;
    cost_of_sold NUMERIC;
BEGIN
    SELECT 
        SUM(trades.quantity * trades.trade_price), SUM(trades.quantity)
    INTO total_sell_value, total_sell_quantity
    FROM trades
    WHERE portfolio_id = p_portfolio_id 
      AND trade_type = 'SELL';
    IF total_sell_value IS NULL THEN
        RETURN NULL;
    END IF;
    SELECT AVG(ph.avg_buy_price)
    INTO avg_buy_price_portfolio
    FROM portfolio_holdings ph
    WHERE ph.portfolio_id = p_portfolio_id;
    cost_of_sold := total_sell_quantity * avg_buy_price_portfolio;
    RETURN (total_sell_value - cost_of_sold) / NULLIF(cost_of_sold, 0);
END;
$$;

CREATE FUNCTION public.portfolio_total_value(p_portfolio_id integer) RETURNS numeric
    LANGUAGE sql
    AS $$
    SELECT SUM(ph.quantity_held * dmp.close_price)
    FROM portfolio_holdings ph
    JOIN daily_market_prices dmp 
        ON ph.stock_id = dmp.stock_id
    WHERE ph.portfolio_id = p_portfolio_id
      AND dmp.price_date = (
          SELECT MAX(price_date)
          FROM daily_market_prices
          WHERE stock_id = ph.stock_id);
$$;

CREATE FUNCTION public.update_holdings_after_trade() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_current_qty integer;
BEGIN
    IF NEW.trade_type = 'BUY' THEN
        INSERT INTO portfolio_holdings (portfolio_id, stock_id, quantity_held, avg_buy_price)
        VALUES (NEW.portfolio_id, NEW.stock_id, NEW.quantity, NEW.trade_price)
        ON CONFLICT (portfolio_id, stock_id)
        DO UPDATE SET
            avg_buy_price = ROUND(
                (
                    portfolio_holdings.avg_buy_price * portfolio_holdings.quantity_held
                    + NEW.trade_price * NEW.quantity
                ) / NULLIF(portfolio_holdings.quantity_held + NEW.quantity, 0),
                2
            ),
            quantity_held = portfolio_holdings.quantity_held + NEW.quantity;
    ELSIF NEW.trade_type = 'SELL' THEN
        SELECT quantity_held
        INTO v_current_qty
        FROM public.portfolio_holdings
        WHERE portfolio_id = NEW.portfolio_id
          AND stock_id = NEW.stock_id
        FOR UPDATE;
        IF v_current_qty IS NULL OR v_current_qty < NEW.quantity THEN
            RAISE EXCEPTION
                'Insufficient holdings for portfolio %, stock %. Current: %, sell quantity: %',
                NEW.portfolio_id,
                NEW.stock_id,
                COALESCE(v_current_qty, 0),
                NEW.quantity;
        END IF;
        UPDATE public.portfolio_holdings
        SET quantity_held = quantity_held - NEW.quantity
        WHERE portfolio_id = NEW.portfolio_id
          AND stock_id = NEW.stock_id;
    END IF;
    RETURN NEW;
END;
$$;

-- ====================================================================
-- VIEWS
-- ====================================================================
CREATE MATERIALIZED VIEW public.latest_market_prices AS
 SELECT stock_id,
    price_date,
    close_price
   FROM ( SELECT daily_market_prices.stock_id,
            daily_market_prices.price_date,
            daily_market_prices.close_price,
            row_number() OVER (PARTITION BY daily_market_prices.stock_id ORDER BY daily_market_prices.price_date DESC) AS rn
           FROM public.daily_market_prices) latest
  WHERE (rn = 1)
  WITH NO DATA;

CREATE VIEW public.portfolio_performance AS
 SELECT portfolio_id,
    portfolio_name,
    round((public.portfolio_roi(portfolio_id) * (100)::numeric), 2) AS roi_percent
   FROM public.portfolios p;

CREATE VIEW public.top_performing_stocks AS
 SELECT s.stock_id,
    s.stock_symbol,
    s.company_name,
    (max(dmp.close_price) - min(dmp.close_price)) AS price_increase
   FROM (public.stocks s
     JOIN public.daily_market_prices dmp ON ((s.stock_id = dmp.stock_id)))
  GROUP BY s.stock_id, s.stock_symbol, s.company_name
  ORDER BY (max(dmp.close_price) - min(dmp.close_price)) DESC;

-- ====================================================================
-- INDEXES
-- ====================================================================
CREATE INDEX idx_daily_market_prices_stock_date ON public.daily_market_prices USING btree (stock_id, price_date);

CREATE UNIQUE INDEX idx_latest_market_prices_stock ON public.latest_market_prices USING btree (stock_id);

CREATE INDEX idx_portfolio_holdings_portfolio_stock ON public.portfolio_holdings USING btree (portfolio_id, stock_id);

CREATE INDEX idx_price_stock_id ON public.daily_market_prices USING btree (stock_id);

CREATE INDEX idx_stock_symbol ON public.stocks USING btree (stock_symbol);

CREATE INDEX idx_trade_date ON public.trades USING btree (trade_date);

-- ====================================================================
-- TRIGGER
-- ====================================================================
CREATE TRIGGER trg_update_holdings AFTER INSERT ON public.trades FOR EACH ROW EXECUTE FUNCTION public.update_holdings_after_trade();

-- NOTE: the materialized view is created empty. The .backup already refreshes it;
-- if you build from this file, run: REFRESH MATERIALIZED VIEW public.latest_market_prices;
