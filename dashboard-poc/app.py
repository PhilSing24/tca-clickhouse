import clickhouse_connect
import pandas as pd
import plotly.graph_objects as go
from dash import Dash, dcc, html, dash_table, Input, Output, State

client = clickhouse_connect.get_client(host='localhost', port=8123, database='tca')

LOGO_B64 = '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'

symbols = client.query_df("SELECT DISTINCT sym FROM trades ORDER BY sym")['sym'].tolist()

DARK_BLUE = '#1D2D70'
LIGHT_BLUE = '#4A90D9'
LIGHT_GRAY = '#F2F4F8'

TAB_STYLE = {
    'padding': '12px', 'fontFamily': 'Arial', 'fontWeight': 'bold',
    'color': DARK_BLUE, 'backgroundColor': 'white',
}
SELECTED_TAB_STYLE = {
    'padding': '12px', 'fontFamily': 'Arial', 'fontWeight': 'bold',
    'color': 'white', 'backgroundColor': LIGHT_BLUE, 'border': 'none',
}

app = Dash(__name__)
app.config.suppress_callback_exceptions = True

# ── Tab 1: Tick-level view ──
tick_tab = html.Div([
    html.Div([
        html.Div([
            html.Label('Symbol'),
            dcc.Dropdown(
                id='symbol', options=[{'label': s, 'value': s} for s in symbols],
                value=symbols[0], style={'width': '150px'},
            ),
        ], style={'display': 'inline-block', 'marginRight': '20px'}),

        html.Div([
            html.Label('Start'),
            dcc.Input(id='start', type='text', value='2026-08-18 09:35:00.000000000',
                       style={'width': '260px'}),
        ], style={'display': 'inline-block', 'marginRight': '20px'}),

        html.Div([
            html.Label('End'),
            dcc.Input(id='end', type='text', value='2026-08-18 09:35:05.000000000',
                       style={'width': '260px'}),
        ], style={'display': 'inline-block', 'marginRight': '20px'}),

        html.Div([
            html.Button('Apply', id='apply-btn', n_clicks=0, style={
                'backgroundColor': DARK_BLUE, 'color': 'white', 'border': 'none',
                'padding': '8px 20px', 'borderRadius': '4px', 'fontFamily': 'Arial',
                'fontWeight': 'bold', 'cursor': 'pointer',
            }),
        ], style={'display': 'inline-block'}),

        html.Div([
            dcc.Checklist(
                id='layers',
                options=[
                    {'label': ' Quotes', 'value': 'quotes'},
                    {'label': ' Trades', 'value': 'trades'},
                    {'label': ' Executions', 'value': 'executions'},
                ],
                value=['quotes', 'trades', 'executions'],
                inline=True,
            ),
        ], style={'marginTop': '15px'}),
    ], style={'padding': '15px 0'}),

    dcc.Graph(id='chart'),
])


@app.callback(
    Output('chart', 'figure'),
    Input('symbol', 'value'),
    Input('layers', 'value'),
    Input('apply-btn', 'n_clicks'),
    State('start', 'value'),
    State('end', 'value'),
)
def update_chart(symbol, layers, n_clicks, start, end):
    fig = go.Figure()

    if 'quotes' in layers:
        q = client.query_df(f"""
            SELECT time, bid, ask FROM quotes
            WHERE sym = '{symbol}' AND time >= '{start}' AND time < '{end}'
            ORDER BY time
        """)
        if len(q):
            fig.add_trace(go.Scatter(
                x=q['time'], y=q['ask'], mode='lines', line_shape='hv',
                name='Ask', line=dict(color='#e05c5c', width=1.5),
            ))
            fig.add_trace(go.Scatter(
                x=q['time'], y=q['bid'], mode='lines', line_shape='hv',
                name='Bid', line=dict(color='#5c8ae0', width=1.5),
                fill='tonexty', fillcolor='rgba(128,128,128,0.15)',
            ))

    if 'trades' in layers:
        t = client.query_df(f"""
            SELECT time, price FROM trades
            WHERE sym = '{symbol}' AND time >= '{start}' AND time < '{end}'
            ORDER BY time
        """)
        if len(t):
            fig.add_trace(go.Scatter(
                x=t['time'], y=t['price'], mode='markers', name='Trade',
                marker=dict(color='black', size=7),
            ))

    if 'executions' in layers:
        e = client.query_df(f"""
            SELECT time, price,
                   if(orderid LIKE '%GOOD%', 'good', 'bad') AS style
            FROM executions
            WHERE sym = '{symbol}' AND time >= '{start}' AND time < '{end}'
            ORDER BY time
        """)
        if len(e):
            good = e[e['style'] == 'good']
            bad = e[e['style'] == 'bad']
            if len(good):
                fig.add_trace(go.Scatter(
                    x=good['time'], y=good['price'], mode='markers',
                    name='Good execution',
                    marker=dict(color='#2ca02c', size=11, line=dict(color='black', width=1)),
                ))
            if len(bad):
                fig.add_trace(go.Scatter(
                    x=bad['time'], y=bad['price'], mode='markers',
                    name='Bad execution',
                    marker=dict(color='#d62728', size=11, line=dict(color='black', width=1)),
                ))

    fig.update_layout(
        title=f'{symbol} — {start} to {end}',
        title_x=0.5,
        xaxis_title='Time', yaxis_title='Price ($)',
        yaxis=dict(tickformat='.2f'),
        template='plotly_white', height=550,
    )
    return fig


# ── Tab 2: Order scorecard table ──
def load_scorecard():
    df = client.query_df("""
        SELECT sym, side, trading_date, starttime, endtime,
               round(arrival_price_bps, 2) AS arrival_price_bps,
               round(interval_vwap_bps, 2) AS interval_vwap_bps,
               round(twap_bps, 2) AS twap_bps
        FROM all_orders_scorecard
        ORDER BY arrival_price_bps DESC
    """)
    return df

scorecard_tab = html.Div([
    html.Br(),
    dash_table.DataTable(
        id='scorecard-table',
        columns=[{'name': c, 'id': c} for c in load_scorecard().columns],
        data=load_scorecard().to_dict('records'),
        style_cell={'textAlign': 'center', 'padding': '6px', 'fontFamily': 'Arial'},
        style_header={'fontWeight': 'bold', 'backgroundColor': '#f2f4f8'},
        style_data_conditional=[
            {'if': {'filter_query': '{arrival_price_bps} > 0', 'column_id': 'arrival_price_bps'},
             'backgroundColor': '#ffe0e0'},
            {'if': {'filter_query': '{arrival_price_bps} < 0', 'column_id': 'arrival_price_bps'},
             'backgroundColor': '#e0ffe0'},
        ],
        sort_action='native',
        page_size=20,
    ),
])

# ── Tab 3: Average cost by symbol ──
def load_avg_cost():
    df = client.query_df("""
        SELECT sym,
               avg(arrival_price_bps) AS avg_arrival_bps,
               avg(interval_vwap_bps) AS avg_vwap_bps
        FROM all_orders_scorecard
        GROUP BY sym
        ORDER BY sym
    """)
    return df

def build_avg_cost_fig():
    df = load_avg_cost()
    fig = go.Figure()
    fig.add_trace(go.Bar(x=df['sym'], y=df['avg_arrival_bps'], name='Avg vs Arrival Price',
                          marker_color='#1D2D70'))
    fig.add_trace(go.Bar(x=df['sym'], y=df['avg_vwap_bps'], name='Avg vs Interval VWAP',
                          marker_color='#25BFEC'))
    fig.update_layout(
        title='Average Cost by Symbol', title_x=0.5, barmode='group',
        yaxis_title='Basis Points', yaxis=dict(tickformat='.2f'),
        template='plotly_white', height=500,
    )
    return fig

avg_cost_tab = html.Div([
    dcc.Graph(figure=build_avg_cost_fig()),
])

# ── App layout with tabs ──
app.layout = html.Div([
    html.Div([
        html.Div(style={'width': '210px', 'flexShrink': '0'}),  # left spacer, balances logo width
        html.H2('Transaction Cost Analysis', style={
            'textAlign': 'center', 'flex': '1', 'margin': '0', 'fontFamily': 'Arial',
            'color': 'white',
        }),
        html.Div([
            html.Img(src=f'data:image/png;base64,{LOGO_B64}', style={'height': '45px'}),
        ], style={'width': '210px', 'flexShrink': '0', 'textAlign': 'right', 'paddingRight': '10px'}),
    ], style={
        'display': 'flex', 'alignItems': 'center', 'padding': '15px 20px',
        'backgroundColor': DARK_BLUE,
    }),
    dcc.Tabs(id='tabs', value='tick', children=[
        dcc.Tab(label='Tick-Level View', value='tick', style=TAB_STYLE, selected_style=SELECTED_TAB_STYLE),
        dcc.Tab(label='Order Scorecard', value='scorecard', style=TAB_STYLE, selected_style=SELECTED_TAB_STYLE),
        dcc.Tab(label='Average Cost by Symbol', value='avgcost', style=TAB_STYLE, selected_style=SELECTED_TAB_STYLE),
    ]),
    html.Div(id='tab-content'),
])


@app.callback(Output('tab-content', 'children'), Input('tabs', 'value'))
def render_tab(tab):
    if tab == 'tick':
        return tick_tab
    elif tab == 'scorecard':
        return scorecard_tab
    elif tab == 'avgcost':
        return avg_cost_tab


if __name__ == '__main__':
    app.run(debug=True, port=8050)
