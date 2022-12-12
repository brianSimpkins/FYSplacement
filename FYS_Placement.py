# import our libraries
import sys
import PyQt5.QtWidgets as qw
import PyQt5.QtCore as qc
import PyQt5.QtGui as qg
import placement as pp

from os.path import exists

class PlacerThread(qc.QThread):
    def __init__(self, place_class):
        qc.QThread.__init__(self)
        self.place_class = place_class
    def run(self):
        self.place_class.place_students()

class Placement_Gui(qw.QMainWindow):

    def __init__(self, screen_width, screen_height):
        super().__init__()
        self.title = "Pitzer FYS Placement"
        self.left = 100
        self.top = 100
        self.width = int(screen_width // 4)
        self.height = int(screen_height // 4.5)
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
        form = qw.QLabel("Input form filepath:")
        form.setFont(qg.QFont("Times", 11))

        self.form_box = qw.QLineEdit(self)
        self.form_box.setFont(qg.QFont("Times", 11))

        # anndata label
        output = qw.QLabel("Save location:")
        output.setFont(qg.QFont("Times", 11))

        self.output_box = qw.QLineEdit(self)
        self.output_box.setFont(qg.QFont("Times", 11))

        self.button_box = qw.QHBoxLayout()

        # run button
        self.run_button = qw.QPushButton("Initial Placement")
        self.run_button.clicked.connect(self.run_button_press)
        self.run_button.setFont(qg.QFont("Times", 12))

        # run button
        self.update_button = qw.QPushButton("Update Placement")
        self.update_button.clicked.connect(self.update_button_press)
        self.update_button.setFont(qg.QFont("Times", 12))


        self.button_box.addWidget(self.run_button)

        self.button_box.addSpacing(50)

        self.button_box.addWidget(self.update_button)

        # add widgets to the layout
        layout.addWidget(title, 0, 0, 1, 5, qc.Qt.AlignCenter)

        layout.addWidget(form, 1, 0, 1, 3)
        layout.addWidget(self.form_box, 1, 2, 1, 3)

        layout.addWidget(output, 2, 0, 1, 3)
        layout.addWidget(self.output_box, 2, 2, 1, 3)

        layout.addLayout(self.button_box, 7, 0, 1, 5, qc.Qt.AlignCenter)

        #layout.setRowStretch(5, 100)
        layout.setHorizontalSpacing(80)


        layout.setColumnStretch(0, 80)
        layout.setColumnStretch(1, 80)
        layout.setColumnStretch(2, 80)
        layout.setColumnStretch(3, 80)
        layout.setColumnStretch(4, 120)


        self.wid.setLayout(layout)

        self.show()


    def update_button_press(self):
        self.newWindow = qw.QMessageBox(self.wid)
        if self.form_box.text() == "":
            self.newWindow.setText("Please input a filepath for the placement forms")
            self.newWindow.exec()
        elif not exists(self.form_box.text()):
            self.newWindow.setText("The inputted filepath for the placement forms is invalid")
            self.newWindow.exec()
        elif self.output_box.text() == "":
            self.newWindow.setText("Please input a valid location for the output")
            self.newWindow.exec()
        else: 
            self.newWindow.setText("Running in progress, please wait")
            placer = pp.Pitzer_Update_Placement(self.form_box.text())
            self.workerThread = PlacerThread(placer)
            self.workerThread.finished.connect(self.end_thread)
            self.workerThread.start()
            self.newWindow.exec()

    def run_button_press(self):
        self.newWindow = qw.QMessageBox(self.wid)
        if self.form_box.text() == "":
            self.newWindow.setText("Please input a filepath for the placement forms")
            self.newWindow.exec()
        elif not exists(self.form_box.text()):
            self.newWindow.setText("The inputted filepath for the placement forms is invalid")
            self.newWindow.exec()
        elif self.output_box.text() == "":
            self.newWindow.setText("Please input a valid location for the output")
            self.newWindow.exec()
        else: 
            self.newWindow.setText("Running in progress, please wait")
            placer = pp.Pitzer_Placement(self.form_box.text())
            self.workerThread = PlacerThread(placer)
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
    ex = Placement_Gui(app.primaryScreen().size().width(), app.primaryScreen().size().height())
    sys.exit(app.exec_())