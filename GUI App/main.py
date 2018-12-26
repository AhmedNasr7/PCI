from PyQt5.QtWidgets import *
from PyQt5.QtCore import *
from PyQt5.QtGui import *
from PyQt5.uic import loadUiType
import sys
from os import path
import os
from graph import *

FORM_CLASS,_ = loadUiType(path.join(path.dirname(__file__), "main.ui"))



class MainApp(QMainWindow, FORM_CLASS):



    def __init__(self, parent= None):
        super(MainApp, self).__init__(parent)
        QMainWindow.__init__(self)
        self.setupUi(self)
        self.setup_Ui()
        self.init_Buttons()





    def setup_Ui(self):
        self.setWindowTitle("PCI Simulator")
        self.setFixedSize(900,600)
        m= PlotCanvas(self, width=5, height=4)
        m.move(0, 0)






    def init_Buttons(self):
        self.browse_button.clicked.connect(self.openFile)
        self.run_button.clicked.connect(self.run_code)

    def openFile(self):
        options = QFileDialog.Options()
        options |= QFileDialog.DontUseNativeDialog

        self.fileName, _ = QFileDialog.getOpenFileName(self, "Open file to simulate", "", "Verilog Files (*.v)", options=options)
        if self.fileName:
            self.file_path.setText(self.fileName)
        self.run_command = "'" + self.fileName[0:-7] + "'"
        self.compile_command = "iverilog '" + self.fileName + "' -o " + self.run_command



    def run_code(self):
        os.system(self.compile_command)
        os.system(self.run_command)



def main():
    app = QApplication(sys.argv)
    window = MainApp()
    window.show()
    app.exec_()


if __name__ == '__main__':
    main()
