import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots


def order_statuses_piechart(web_view, orders: pd.DataFrame):

    order_statuses = orders["Order status"].value_counts()
    order_dates = (
        orders["Ordering date"]
        .apply(lambda x: "%d-%d" % (x.year, x.month))
        .value_counts()
        .to_frame()
        .reset_index()
    )

    order_dates.columns = ["Date", "Quantity"]

    fig = make_subplots(
        rows=1,
        cols=3,
        specs=[[{"type": "pie"}, {"type": "pie"}, {"type": "pie"}]],
        subplot_titles=[
            "Number of orders by month",
            "Money spent on different genres",
            "Distribution of client order statuses",
        ],
        horizontal_spacing=0.15,
    )

    fig.add_trace(
        go.Pie(
            labels=order_dates["Date"],
            values=order_dates["Quantity"],
            legendgroup="group1",
            legendgrouptitle=dict(text="Number of orders by month"),
            name="",
        ),
        row=1,
        col=1,
    )

    fig.add_trace(
        go.Pie(
            labels=orders["Genre"],
            values=orders["Paid price"],
            legendgroup="group2",
            legendgrouptitle=dict(text="Money spent on specific genres"),
            name="",
        ),
        row=1,
        col=2,
    )

    fig.add_trace(
        go.Pie(
            labels=order_statuses.index,
            values=order_statuses,
            legendgroup="group3",
            legendgrouptitle=dict(text="Distribution of client order statuses"),
            name="",
        ),
        row=1,
        col=3,
    )

    fig.update_layout(
        height=319,
        width=1249,
        legend_title="Client statistics",
        legend_tracegroupgap=10,
        margin=dict(l=0, r=0, t=20, b=0),
        font=dict(size=10),
    )
    fig.update_annotations(font_size=12)
    web_view.setHtml(fig.to_html(include_plotlyjs="cdn"))


def sales_barchar(web_view, sales: pd.DataFrame, from_, to_):
    fig = make_subplots(
        rows=2,
        cols=1,
        subplot_titles=[
            "Money earned by genres",
            "Amount of sold books by genres",
        ]
    )

    fig.add_trace(
        go.Bar(
            name="Genre",
            x=sales["Genre"],
            y=sales["Sum"],
            text=sales["Sum"],
            textposition='auto',
        ),
        row=1,
        col=1
    )

    fig.add_trace(
        go.Bar(
            name="Copies sold",
            x=sales["Genre"],
            y=sales["Sold copies"],
            text=sales["Sold copies"],
            textposition='auto',
        ),
        row=2,
        col=1
    )

    fig.update_layout(title=f"Sales from {from_} to {to_}")
    web_view.setHtml(fig.to_html(include_plotlyjs="cdn"))


