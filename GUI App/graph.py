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


    def plot(self):
        '''
        data = [random.random() for i in range(0, 10, 1)]
        ax = self.figure.add_subplot(111)
        for i in range(1, 5):
            ax.plot(np.array([1, 5]) * i, label=i)
        #ax.plot(data, 'b-')

        colormap = plt.cm.gist_ncar  # nipy_spectral, Set1,Paired
        colors = [colormap(i) for i in np.linspace(0, 1, len(ax1.lines))]
        for i, j in enumerate(ax1.lines):
            j.set_color(colors[i])

        ax1.legend(loc=2)

        '''


        bits = [0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0]
        data = np.repeat(bits, 2)
        t = 0.5 * np.arange(len(data))

        #data = [random.random() for i in range(0, 10, 1)]
        ax = self.figure.add_subplot(111)
        ax1 = self.figure.add_subplot(111)
        #for i in range(1, 10):

        ax.step(t, data + 2)
        ax1.step(t, data)

        ax.grid(False)
        ax.set_xlim(t[0], t[-1])
        ax.set_ylim([0, 6])

        ax1.grid(False)
        ax1.set_xlim(t[0], t[-1])
        ax1.set_ylim([-5, 5])




        ax.legend(loc=2)
        ax.axis('off')


        ax.set_title('PCI Simulation Wave Form')

        self.draw()

