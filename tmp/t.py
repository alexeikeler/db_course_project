from PyQt5 import QtCore, QtWidgets


class MainWindow(QtWidgets.QMainWindow):
    def __init__(self, parent=None):
        super().__init__(parent)

        self.tree_local_file = QtWidgets.QTreeView()
        self.setCentralWidget(self.tree_local_file)

        path = "/home/alexei/db_course_project/pdf_reports"

        self.model = QtWidgets.QFileSystemModel()
        #self.model.setNameFilters(["*.ma"])
        ##self.model.setFilter(
         #   QtCore.QDir.Files QtCore.QDir.AllDirs | QtCore.QDir.NoDotAndDotDot | QtCore.QDir.AllEntries)
        self.model.setNameFilterDisables(False)
        self.model.setRootPath(path)
        self.tree_local_file.setModel(self.model)
        self.tree_local_file.setRootIndex(self.model.index(path))

        self.model.directoryLoaded.connect(self.onDirectoryLoaded)

    @QtCore.pyqtSlot()
    def onDirectoryLoaded(self):
        root = self.model.index(self.model.rootPath())
        for i in range(self.model.rowCount(root)):
            index = self.model.index(i, 0, root)
            file_name = self.model.fileName(index)
            file_path = self.model.filePath(index)


if __name__ == "__main__":
    import sys

    app = QtWidgets.QApplication(sys.argv)
    w = MainWindow()
    w.show()
    sys.exit(app.exec_())