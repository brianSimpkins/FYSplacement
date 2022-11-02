# import our libraries
import sys
import PyQt5.QtWidgets as qw
import PyQt5.QtCore as qc
import PyQt5.QtGui as qg
import placement as pp

from os.path import exists

class WorkerThread(qc.QThread):
    def __init__(self, place_class):
        qc.QThread.__init__(self)
        self.place_class = place_class
    def run(self):
        self.place_class.place_students()

class Placement_Gui(qw.QMainWindow):

    def __init__(self):
        super().__init__()
        self.title = "Pitzer FYS Placement"
        self.left = 100
        self.top = 100
        self.width = 600
        self.height = 300
        self.initUI()
    
    def initUI(self):
        
        # make the window
        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)

        # make central widget
        self.wid = qw.QWidget(self)
        self.setCentralWidget(self.wid)

        # create layout grid
        layout = qw.QGridLayout()

        # title at the top of the screen
        title = qw.QLabel("Pitzer FYS Placement")
        title.setFont(qg.QFont("Times", 18, 2))

        # anndata label
        form = qw.QLabel("Preference form filepath:")
        form.setFont(qg.QFont("Times", 11))

        self.form_box = qw.QLineEdit(self)
        self.form_box.setFont(qg.QFont("Times", 11))

        # anndata label
        output = qw.QLabel("Save location:")
        output.setFont(qg.QFont("Times", 11))

        self.output_box = qw.QLineEdit(self)
        self.output_box.setFont(qg.QFont("Times", 11))

        dem1 = qw.QLabel("Demographic rule 1:")
        dem1.setFont(qg.QFont("Times", 11))

        self.dem1_box = qw.QLineEdit(self)
        self.dem1_box.setFont(qg.QFont("Times", 11))

        dem2 = qw.QLabel("Demographic rule 2:")
        dem2.setFont(qg.QFont("Times", 11))

        self.dem2_box = qw.QLineEdit(self)
        self.dem2_box.setFont(qg.QFont("Times", 11))

        dem3 = qw.QLabel("Demographic rule 3:")
        dem3.setFont(qg.QFont("Times", 11))

        self.dem3_box = qw.QLineEdit(self)
        self.dem3_box.setFont(qg.QFont("Times", 11))
        
        dem4 = qw.QLabel("Demographic rule 4:")
        dem4.setFont(qg.QFont("Times", 11))

        self.dem4_box = qw.QLineEdit(self)
        self.dem4_box.setFont(qg.QFont("Times", 11))

        # run button
        self.run_button = qw.QPushButton("Run")
        self.run_button.clicked.connect(self.run_button_press)
        self.run_button.setFont(qg.QFont("Times", 14))

        # add widgets to the layout
        layout.addWidget(title, 0, 0, 1, 5, qc.Qt.AlignCenter)

        layout.addWidget(form, 1, 0, 1, 3)
        layout.addWidget(self.form_box, 1, 2, 1, 3)

        layout.addWidget(output, 2, 0, 1, 3)
        layout.addWidget(self.output_box, 2, 2, 1, 3)

        layout.addWidget(dem1, 3, 0, 1, 3)
        layout.addWidget(self.dem1_box, 3, 4)

        layout.addWidget(dem2, 4, 0, 1, 3)
        layout.addWidget(self.dem2_box, 4, 4)

        layout.addWidget(dem3, 5, 0, 1, 3)
        layout.addWidget(self.dem3_box, 5, 4)

        layout.addWidget(dem4, 6, 0, 1, 3)
        layout.addWidget(self.dem4_box, 6, 4)

        layout.addWidget(self.run_button, 7, 0, 1, 5, qc.Qt.AlignCenter)

        #layout.setRowStretch(5, 100)
        layout.setHorizontalSpacing(80)


        layout.setColumnStretch(0, 80)
        layout.setColumnStretch(1, 80)
        layout.setColumnStretch(2, 80)
        layout.setColumnStretch(3, 80)
        layout.setColumnStretch(4, 120)


        self.wid.setLayout(layout)

        self.show()


    def run_button_press(self):
        self.newWindow = qw.QMessageBox(self.wid)
        if self.form_box.text() == "":
            self.newWindow.setText("Please input a filepath for the placement forms")
            self.newWindow.exec()
        elif not exists(self.form_box.text()):
            self.newWindow.setText("The inputted filepath for the placement forms is invalid")
            self.newWindow.exec()
        elif self.output_box.text() == "":
            self.newWindow.setText("Please input a filepath for the placement forms")
            self.newWindow.exec()
        else: 
            self.newWindow.setText("Running in progress, please wait")
            placer = pp.Pitzer_Placement(self.form_box.text())
            self.workerThread = WorkerThread(placer)
            self.workerThread.finished.connect(self.end_thread)
            self.workerThread.start()
            self.newWindow.exec()
    
    def end_thread(self):
        self.workerThread.place_class.save_assignments(self.output_box.text())

        self.workerThread.deleteLater()

        self.newWindow.close()
        finalWindow = qw.QMessageBox(self.wid)
        finalWindow.setText("Output saved!")
        finalWindow.exec()
    
if __name__ == '__main__':
    app = qw.QApplication(sys.argv)
    ex = Placement_Gui()
    sys.exit(app.exec_())