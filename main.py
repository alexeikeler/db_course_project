import sys

# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtWidgets, uic

from src.forms.login_form import LoginForm


def main():
    app = QtWidgets.QApplication(sys.argv)
    login_form = LoginForm()
    login_form.show()

    sys.exit(app.exec_())


if __name__ == "__main__":
    main()
