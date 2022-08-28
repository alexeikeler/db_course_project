import argparse
import sys

# noinspection PyUnresolvedReferences
from PyQt5 import QtCore, QtWidgets, uic

from src.forms.login_form import LoginForm


def parse_arguments():
    parser = argparse.ArgumentParser(
        "Login as client or employee with login & password."
    )

    parser.add_argument(
        '-l',
        '--login',
        dest='user_login',
        help='Login argument.',
        required=False
    )

    parser.add_argument(
        '-p',
        '--password',
        dest='user_password',
        help='Password argument.',
        required=False
    )

    return parser.parse_args()


def main():
    args = parse_arguments()
    app = QtWidgets.QApplication(sys.argv)
    login_form = LoginForm()
    login_form.username_line_edit.setText(args.user_login)
    login_form.password_line_edit.setText(args.user_password)
    login_form.show()

    sys.exit(app.exec_())


if __name__ == "__main__":
    main()
