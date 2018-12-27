import numpy as np

from PyQt5.QtWidgets import QApplication, QMainWindow, QMenu, QVBoxLayout, QSizePolicy, QMessageBox, QWidget, \
    QPushButton
from PyQt5.QtGui import QIcon

from matplotlib.figure import Figure
import matplotlib.pyplot as plt
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
import matplotlib.pyplot as plt

import random


class PlotCanvas(FigureCanvas):

    def __init__(self, parent=None, width=5, height=4, dpi=100):
        fig = Figure(figsize=(width, height), dpi=dpi)
        self.axes = fig.add_subplot(111)

        FigureCanvas.__init__(self, fig)
        self.setParent(parent)

        FigureCanvas.setSizePolicy(self, QSizePolicy.Expanding, QSizePolicy.Expanding)
        FigureCanvas.updateGeometry(self)
        self.plot()
        self.file_data = []
        self.iframe_bits = []
        self.iready_bits = []
        self.tready_bits = []
        self.devsel_bits = []
        self.sc1_name = './sc1.txt'

        self.process_file()

    def plot(self):
        bits = [0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0]
        data = np.repeat(bits, 2)
        t = 0.5 * np.arange(len(data))

        # data = [random.random() for i in range(0, 10, 1)]
        iframe = self.figure.add_subplot(111)
        iready = self.figure.add_subplot(111)
        tready = self.figure.add_subplot(111)
        devsel = self.figure.add_subplot(111)

        iframe.step(t, data + 2)
        iready.step(t, data)
        tready.step(t, data - 2)
        devsel.step(t, data - 4)

        iframe.grid(False)
        iframe.set_xlim(t[0], t[-1])
        iframe.set_ylim([0, 6])

        iready.grid(False)
        iready.set_xlim(t[0], t[-1])
        iready.set_ylim([-5, 5])

        iframe.legend(loc=2)
        iframe.axis('off')

        iframe.set_title('PCI Simulation Wave Form')

        self.draw()


    def process_file(self):

        with open(self.sc1_name, 'r') as f:
            file_data = []
            lines = f.readlines()

            lines = [line.strip() for line in lines]
            print(lines)
            for line in lines:
                l = line.split(',')
                print(l)
                self.file_data.append(l)

            print(self.file_data)
            li = []
            lis = []
            for l in self.file_data:
                for s in l:
                    lis.append(int(s))
                
            for i in range(0, len(li)):
                if (i % 4 == 0):
                    self.iframe_bits.append(li[i])

            print(self.iframe_bits)
            print(li)


