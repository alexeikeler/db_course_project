import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots


def order_statuses_piechart(web_view, orders: pd.DataFrame):

    vals = orders["Order status"].value_counts()
    fig = make_subplots(rows=1, cols=2, specs=[[{"type": "pie"}, {"type": "pie"}]])

    fig.add_trace(
        go.Pie(
            labels=orders["Genre"],
            values=orders["Paid price"],
            legendgroup="group1",
            legendgrouptitle=dict(text="Money spent on specific genres"),
            name=""

        ),
        row=1, col=1
    )

    fig.add_trace(
        go.Pie(
            labels=vals.index,
            values=vals,
            legendgroup="group2",
            legendgrouptitle=dict(text="Distribution of client order statuses"),
            name=""

    ),
        row=1, col=2
    )

    fig.update_layout(
        height=300, width=800,
        legend_title="Client statistics",
        margin=dict(l=0, r=0, t=20, b=0),
    )
    web_view.setHtml(fig.to_html(include_plotlyjs='cdn'))
