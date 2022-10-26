# import our libraries
import sys
import PyQt5.QtWidgets as qw
import PyQt5.QtCore as qc
import PyQt5.QtGui as qg
import placement as pp

from os.path import exists

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
        title = qw.QLabel("Pitzer FYS")
        title.setFont(qg.QFont("Times", 20, 2))

        # anndata label
        form = qw.QLabel("Preference form filepath:")
        form.setFont(qg.QFont("Times", 11))

        self.form_box = qw.QLineEdit(self)
        self.form_box.setFont(qg.QFont("Times", 11))

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

        dem5 = qw.QLabel("Demographic rule 5:")
        dem5.setFont(qg.QFont("Times", 11))

        self.dem5_box = qw.QLineEdit(self)
        self.dem5_box.setFont(qg.QFont("Times", 11))

        # run button
        self.run_button = qw.QPushButton("Run")
        self.run_button.clicked.connect(self.run_button_press)
        self.run_button.setFont(qg.QFont("Times", 14))

        # add widgets to the layout
        layout.addWidget(title, 0, 0, 1, 5, qc.Qt.AlignCenter)

        layout.addWidget(form, 1, 0, 1, 3)
        layout.addWidget(self.form_box, 1, 2, 1, 3)

        layout.addWidget(dem1, 2, 0, 1, 3)
        layout.addWidget(self.dem1_box, 2, 4)

        layout.addWidget(dem2, 3, 0, 1, 3)
        layout.addWidget(self.dem2_box, 3, 4)

        layout.addWidget(dem3, 4, 0, 1, 3)
        layout.addWidget(self.dem3_box, 4, 4)

        layout.addWidget(dem4, 5, 0, 1, 3)
        layout.addWidget(self.dem4_box, 5, 4)

        layout.addWidget(dem5, 6, 0, 1, 3)
        layout.addWidget(self.dem5_box, 6, 4)

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
        newWindow = qw.QMessageBox(self.wid)
        if self.form_box.text() == "":
            newWindow.setText("Please input a filepath for the placement forms")
            newWindow.exec()
        elif not exists(self.form_box.text()):
            newWindow.setText("The inputted filepath for the placement forms is invalid")
            newWindow.exec()
        else: 
            newWindow.setText("Running in progress, with placement data from \'" + self.form_box.text() + "\'")
            newWindow.exec()
            placer = pp.Pitzer_Placement(self.form_box.text())
            student_happiness, worst_placement = placer.place_students()
            outputWindow = qw.QMessageBox(self.wid)
            outputWindow.setText(f"The worst placement used a student's {(worst_placement + 1)} preference. On average, each student was placed with their {(student_happiness + 1):.2f} preference.")
            outputWindow.exec()
    
if __name__ == '__main__':
    app = qw.QApplication(sys.argv)
    ex = Placement_Gui()
    sys.exit(app.exec_())