import sys
from PyQt5 import QtCore, QtWidgets
from PyQt5.QtCore import Qt, pyqtSignal as Signal


PALETTES = {
    # bokeh paired 12
    'paired12':['#000000', '#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99', '#e31a1c', '#fdbf6f', '#ff7f00', '#ffffff'],
}


class _PaletteButton(QtWidgets.QPushButton):
    def __init__(self, color):
        super().__init__()
        self.setFixedSize(QtCore.QSize(24, 24))
        self.color = color
        self.setStyleSheet("background-color: %s;" % color)


class _PaletteBase(QtWidgets.QWidget):

    selected = Signal(object)

    def _emit_color(self, color):
        self.selected.emit(color)


class _PaletteLinearBase(_PaletteBase):
    def __init__(self, colors, *args, **kwargs):
        super().__init__(*args, **kwargs)

        if isinstance(colors, str):
            if colors in PALETTES:
                colors = PALETTES[colors]

        palette = self.layoutvh()

        for c in colors:
            b = _PaletteButton(c)
            b.pressed.connect(
                lambda c=c: self._emit_color(c)
            )
            palette.addWidget(b)

        self.setLayout(palette)


class PaletteHorizontal(_PaletteLinearBase):
    layoutvh = QtWidgets.QHBoxLayout


class PaletteVertical(_PaletteLinearBase):
    layoutvh = QtWidgets.QVBoxLayout


class PaletteGrid(_PaletteBase):

    def __init__(self, colors, n_columns=5, *args, **kwargs):
        super().__init__(*args, **kwargs)

        if isinstance(colors, str):
            if colors in PALETTES:
                colors = PALETTES[colors]

        palette = QtWidgets.QGridLayout()
        row, col = 0, 0

        for c in colors:
            b = _PaletteButton(c)
            b.pressed.connect(
                lambda c=c: self._emit_color(c)
            )
            palette.addWidget(b, row, col)
            col += 1
            if col == n_columns:
                col = 0
                row += 1

        self.setLayout(palette)
