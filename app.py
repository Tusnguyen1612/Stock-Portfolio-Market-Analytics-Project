import os

import pandas as pd
import psycopg2
import streamlit as st
from dotenv import load_dotenv

load_dotenv()

st.set_page_config(
    page_title="Stock Portfolio",
    page_icon="📈",
    layout="wide",
)

st.markdown("""
<style>
.block-container {
    padding-top: 2rem;
}
.metric-card {
    padding: 1rem;
    border-radius: 10px;
    background-color: #111827;
}
</style>
""", unsafe_allow_html=True)

def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
    )


def run_query(query, params=None):
    conn = get_connection()
    df = pd.read_sql(query, conn, params=params)
    conn.close()
    return df


def execute_query(query, params=None):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(query, params)
    conn.commit()
    cur.close()
    conn.close()


st.title("Stock Portfolio Management System")

page = st.sidebar.radio(
    "Menu",
    ["Dashboard", "Stocks", "Portfolios", "Trades", "Add Trade"]
)


if page == "Dashboard":
    st.header("Dashboard")

    portfolios = run_query("SELECT * FROM public.portfolios;")
    stocks = run_query("SELECT * FROM public.stocks;")
    trades = run_query("SELECT * FROM public.trades;")
    holdings = run_query("SELECT * FROM public.portfolio_holdings;")

    total_market_value = run_query("""
        SELECT COALESCE(SUM(ph.quantity_held * lmp.close_price), 0) AS total_value
        FROM public.portfolio_holdings ph
        JOIN public.latest_market_prices lmp ON lmp.stock_id = ph.stock_id;
    """)["total_value"].iloc[0]

    col1, col2, col3, col4, col5 = st.columns(5)
    col1.metric("Portfolios", len(portfolios))
    col2.metric("Stocks", len(stocks))
    col3.metric("Trades", len(trades))
    col4.metric("Holdings", len(holdings))
    col5.metric("Market Value", f"{total_market_value:,.0f}")

    st.divider()

    left, right = st.columns(2)

    with left:
        st.subheader("Portfolio Performance")

        performance = run_query("""
            SELECT *
            FROM public.portfolio_performance
            ORDER BY roi_percent DESC NULLS LAST;
        """)

        st.dataframe(performance, use_container_width=True)

        chart_performance = performance.dropna(subset=["roi_percent"])
        if not chart_performance.empty:
            st.bar_chart(
                chart_performance.set_index("portfolio_name")["roi_percent"]
            )
        else:
            st.info("No portfolio performance data available.")

    with right:
        st.subheader("Top Performing Stocks")

        top_stocks = run_query("""
            SELECT *
            FROM public.top_performing_stocks
            LIMIT 10;
        """)

        st.dataframe(top_stocks, use_container_width=True)

        if not top_stocks.empty:
            st.bar_chart(
                top_stocks.set_index("stock_symbol")["price_increase"]
            )
        else:
            st.info("No stock performance data available.")


elif page == "Stocks":
    st.header("Stocks")

    stocks_df = run_query("""
        SELECT
            s.stock_id,
            s.stock_symbol,
            s.company_name,
            e.exchange_name,
            sec.sector_name,
            s.listing_date
        FROM public.stocks s
        JOIN public.exchanges e ON e.exchange_id = s.exchange_id
        JOIN public.sectors sec ON sec.sector_id = s.sector_id
        ORDER BY s.stock_id;
    """)

    st.subheader("Stock List")
    st.dataframe(stocks_df, use_container_width=True)

    st.subheader("Latest Market Prices")

    latest_prices = run_query("""
        SELECT
            s.stock_symbol,
            s.company_name,
            lmp.price_date,
            lmp.close_price
        FROM public.latest_market_prices lmp
        JOIN public.stocks s ON s.stock_id = lmp.stock_id
        ORDER BY s.stock_symbol;
    """)

    st.dataframe(latest_prices, use_container_width=True)

    st.subheader("Top Performing Stocks")

    top_stocks = run_query("""
        SELECT *
        FROM public.top_performing_stocks
        LIMIT 10;
    """)

    st.dataframe(top_stocks, use_container_width=True)

    if not top_stocks.empty:
        st.bar_chart(top_stocks.set_index("stock_symbol")["price_increase"])


elif page == "Portfolios":
    st.header("Portfolios")

    portfolios_df = run_query("""
        SELECT
            p.portfolio_id,
            p.portfolio_name,
            i.full_name AS investor_name,
            p.created_at,
            p.notes
        FROM public.portfolios p
        JOIN public.investors i ON i.investor_id = p.investor_id
        ORDER BY p.portfolio_id;
    """)

    st.subheader("Portfolio List")
    st.dataframe(portfolios_df, use_container_width=True)

    st.subheader("Portfolio Holdings")

    portfolio_options = {
        f"{row.portfolio_id} - {row.portfolio_name}": row.portfolio_id
        for row in portfolios_df.itertuples()
    }

    selected_label = st.selectbox("Choose portfolio", list(portfolio_options.keys()))
    selected_portfolio = portfolio_options[selected_label]

    holdings_df = run_query("""
        SELECT
            ph.holding_id,
            ph.portfolio_id,
            s.stock_symbol,
            s.company_name,
            ph.quantity_held,
            ph.avg_buy_price,
            lmp.close_price,
            ph.quantity_held * lmp.close_price AS market_value
        FROM public.portfolio_holdings ph
        JOIN public.stocks s ON s.stock_id = ph.stock_id
        JOIN public.latest_market_prices lmp ON lmp.stock_id = ph.stock_id
        WHERE ph.portfolio_id = %s
        ORDER BY s.stock_symbol;
    """, (int(selected_portfolio),))

    st.dataframe(holdings_df, use_container_width=True)

    if not holdings_df.empty:
        total_value = holdings_df["market_value"].sum()
        st.metric("Selected Portfolio Market Value", f"{total_value:,.0f}")

        st.bar_chart(
            holdings_df.set_index("stock_symbol")["market_value"]
        )


elif page == "Trades":
    st.header("Trades")

    trades_df = run_query("""
        SELECT
            t.trade_id,
            t.portfolio_id,
            p.portfolio_name,
            s.stock_symbol,
            t.trade_type,
            t.quantity,
            t.trade_price,
            t.trade_date,
            t.created_at
        FROM public.trades t
        JOIN public.portfolios p ON p.portfolio_id = t.portfolio_id
        JOIN public.stocks s ON s.stock_id = t.stock_id
        ORDER BY t.trade_date DESC, t.trade_id DESC;
    """)

    st.dataframe(trades_df, use_container_width=True)


elif page == "Add Trade":
    st.header("Add New Trade")

    st.info("Insert a BUY or SELL trade. The PostgreSQL trigger updates portfolio holdings automatically.")

    portfolios_df = run_query("""
        SELECT portfolio_id, portfolio_name
        FROM public.portfolios
        ORDER BY portfolio_id;
    """)

    stocks_df = run_query("""
        SELECT stock_id, stock_symbol
        FROM public.stocks
        ORDER BY stock_id;
    """)

    portfolio_options = {
        f"{row.portfolio_id} - {row.portfolio_name}": row.portfolio_id
        for row in portfolios_df.itertuples()
    }

    stock_options = {
        f"{row.stock_id} - {row.stock_symbol}": row.stock_id
        for row in stocks_df.itertuples()
    }

    with st.form("add_trade_form"):
        portfolio_label = st.selectbox("Portfolio", list(portfolio_options.keys()))
        stock_label = st.selectbox("Stock", list(stock_options.keys()))
        trade_type = st.selectbox("Trade Type", ["BUY", "SELL"])
        quantity = st.number_input("Quantity", min_value=1, step=1)
        trade_price = st.number_input("Trade Price", min_value=0.01, step=0.01)
        trade_date = st.date_input("Trade Date")

        submitted = st.form_submit_button("Submit Trade")

    if submitted:
        try:
            execute_query("""
                INSERT INTO public.trades (
                    portfolio_id,
                    stock_id,
                    trade_type,
                    quantity,
                    trade_price,
                    trade_date
                )
                VALUES (%s, %s, %s, %s, %s, %s);
            """, (
                int(portfolio_options[portfolio_label]),
                int(stock_options[stock_label]),
                trade_type,
                int(quantity),
                float(trade_price),
                trade_date,
            ))

            st.success("Trade added successfully. Holdings were updated by the trigger.")

        except Exception as error:
            st.error(f"Could not add trade: {error}")