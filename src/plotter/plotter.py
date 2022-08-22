import datetime
import os.path
from datetime import datetime

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import plotly.io
from plotly.subplots import make_subplots

import src.custom_qt_widgets.message_boxes as msg
from config.constants import Const, Errors


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


def sales_canvas(web_view, general_sales: pd.DataFrame, from_, to_) -> go.Figure:
    fig = make_subplots(
        rows=2,
        cols=1,
        subplot_titles=[
            "Money earned by genres",
            "Amount of sold books by genres",
        ],
    )

    fig.add_trace(
        go.Bar(
            name="Genre",
            x=general_sales["Genre"],
            y=general_sales["Sum"],
            text=general_sales["Sum"],
            textposition="auto",
        ),
        row=1,
        col=1,
    )

    fig.add_trace(
        go.Bar(
            name="Copies sold",
            x=general_sales["Genre"],
            y=general_sales["Sold copies"],
            text=general_sales["Sold copies"],
            textposition="auto",
        ),
        row=2,
        col=1,
    )

    fig.update_layout(title=f"Revenue (by genres) from {from_} to {to_}")
    web_view.setHtml(fig.to_html(include_plotlyjs="cdn"))

    return fig


def date_groupped_sales(web_view, sales: pd.DataFrame, grouped_by: str) -> go.Figure:

    fig = make_subplots(
        rows=2,
        cols=2,
        vertical_spacing=0.07,
        specs=[[{"type": "table"}, {"type": "table"}], [{"colspan": 2}, None]],
        subplot_titles=["Revenue table", "Revenue analysis", "Revenue time series"],
    )
    fig.add_trace(
        go.Scatter(
            x=sales["Date"],
            y=sales["Sum"],
            mode="lines+markers",
        ),
        row=2,
        col=1,
    )

    fig.add_trace(
        go.Table(
            header=dict(values=list(sales.columns), align="center"),
            cells=dict(values=[sales.Date, sales.Sum], align="center"),
        ),
        row=1,
        col=1,
    )

    revenue_analysis = (
        sales["Sum"].astype("int").describe().to_frame(name="").reset_index().round(2)
    )
    revenue_analysis.columns = ["Stat", "Value"]
    fig.add_trace(
        go.Table(
            header=dict(values=list(revenue_analysis.columns), align="center"),
            cells=dict(
                values=[revenue_analysis["Stat"], revenue_analysis["Value"]],
                align="center",
            ),
        ),
        row=1,
        col=2,
    )

    fig.update_layout(
        title=f"All sales grouped by {grouped_by}",
        xaxis_title=grouped_by,
        yaxis_title="Sum, \u20B4",
        margin=dict(l=0, r=0, t=50, b=0),
    )
    web_view.setHtml(fig.to_html(include_plotlyjs="cdn"))

    return fig


def top_selling_books(web_view, data, l_date, r_date) -> go.Figure:
    fig = px.bar(x=data["Title"], y=data["Quantity"])
    fig.update_layout(
        title=f"Top selling books from {l_date} to {r_date}",
        xaxis_title="Title",
        yaxis_title="Sold",
    )
    web_view.setHtml(fig.to_html(include_plotlyjs="cdn"))
    return fig


def order_and_payment_pie(
    web_view, orders_data: pd.DataFrame, payment_data: pd.DataFrame, l_date, r_date
) -> go.Figure:

    fig = make_subplots(
        rows=1,
        cols=2,
        specs=[[{"type": "pie"}, {"type": "pie"}]],
        subplot_titles=["Client orders statuses", "Payment types"],
        horizontal_spacing=0.15,
    )

    fig.add_trace(
        go.Pie(
            labels=orders_data["State"],
            values=orders_data["Counted"],
            legendgroup="group1",
            legendgrouptitle=dict(text="Statuses"),
            name="",
        ),
        row=1,
        col=1,
    )

    fig.add_trace(
        go.Pie(
            labels=payment_data["Payment type"],
            values=payment_data["Counted"],
            legendgroup="group2",
            legendgrouptitle=dict(text="Payment types"),
            name="",
        ),
        row=1,
        col=2,
    )

    fig.update_layout(
        legend_title="Orders statuses and payment types statistic",
        legend_tracegroupgap=10,
        margin=dict(l=0, r=0, t=20, b=0),
        font=dict(size=10),
    )
    fig.update_annotations(font_size=12)

    web_view.setHtml(fig.to_html(include_plotlyjs="cdn"))

    return fig


def save_pdf(fig: go.Figure, folder: str, rep_name: str):

    if not os.path.exists(folder):
        msg.error_message(Errors.NO_SUCH_FOLDER.format(folder))

    full_path = folder + str(datetime.now().strftime("%Y-%m-%d_%H:%M:%S")) + rep_name
    print(full_path)

    try:
        plotly.io.write_image(fig, full_path, format="pdf")

    except Exception as e:
        msg.error_message(str(e))
