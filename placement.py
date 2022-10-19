# First let's set up some imports
import numpy as np
import pandas as pd
import unicodedata as ud
import math
from random import sample

class Pitzer_Placement:

    def __init__(self, filepath):
        # Now let's collect our data
        student_data = "C:/Users/Brian/Documents/2022Fall/FYSplacement/data/FYS Fall 2022 Results - Active Commits 20220712-180011_deidentified.csv"
        df = pd.read_csv(filepath)

        # Separate forms by completion
        self.completed_forms = df[df["Completed Form"] != "No"]
        incomplete_forms = df[df["Completed Form"] != "Yes"]
        num_students = len(df)

        # Remove df to free memory
        del df

        # Convert all classes to normalized unicode
        self.completed_forms["Preference 1"] = [ud.normalize("NFKC", x) for x in self.completed_forms["Preference 1"]]
        self.completed_forms["Preference 2"] = [ud.normalize("NFKC", x) for x in self.completed_forms["Preference 2"]]
        self.completed_forms["Preference 3"] = [ud.normalize("NFKC", x) for x in self.completed_forms["Preference 3"]]
        self.completed_forms["Preference 4"] = [ud.normalize("NFKC", x) for x in self.completed_forms["Preference 4"]]
        self.completed_forms["Preference 5"] = [ud.normalize("NFKC", x) for x in self.completed_forms["Preference 5"]]

        # Gather a list of all classes
        classes = set()
        classes.update(self.completed_forms["Preference 1"])
        classes.update(self.completed_forms["Preference 2"])
        classes.update(self.completed_forms["Preference 3"])
        classes.update(self.completed_forms["Preference 4"])
        classes.update(self.completed_forms["Preference 5"])

        # Determine class size
        self.large_class_size = math.ceil(num_students / len(classes))
        self.small_class_size = self.large_class_size - 1
        self.small_class_num = len(classes) * self.large_class_size - num_students


        # Build class - preference dictionary
        self.class_pref = {x: {"1":[], "n1":0, "2":[], "n2":0, "3":[], "n3":0, "4":[], "n4":0, "5":[], "n5":0} for x in classes}

        for i in range(len(self.completed_forms["CX ID"])):
            # add student id to self.class_pref dict
            self.class_pref[self.completed_forms["Preference 1"].iloc[i]]["1"].append(self.completed_forms["CX ID"].iloc[i])
            self.class_pref[self.completed_forms["Preference 1"].iloc[i]]["n1"] += 1
            self.class_pref[self.completed_forms["Preference 2"].iloc[i]]["n2"] += 1
            self.class_pref[self.completed_forms["Preference 2"].iloc[i]]["2"].append(self.completed_forms["CX ID"].iloc[i])
            self.class_pref[self.completed_forms["Preference 3"].iloc[i]]["n3"] += 1
            self.class_pref[self.completed_forms["Preference 3"].iloc[i]]["3"].append(self.completed_forms["CX ID"].iloc[i])
            self.class_pref[self.completed_forms["Preference 4"].iloc[i]]["n4"] += 1
            self.class_pref[self.completed_forms["Preference 4"].iloc[i]]["4"].append(self.completed_forms["CX ID"].iloc[i])
            self.class_pref[self.completed_forms["Preference 5"].iloc[i]]["n5"] += 1
            self.class_pref[self.completed_forms["Preference 5"].iloc[i]]["5"].append(self.completed_forms["CX ID"].iloc[i])

        # Convert to dataframe
        self.class_pref = pd.DataFrame(self.class_pref).T


        # Determine popularity at given preference depth
        self.class_pref["top2"] = self.class_pref["n1"] + self.class_pref["n2"]
        self.class_pref["top3"] = self.class_pref["top2"] + self.class_pref["n3"]
        self.class_pref["top4"] = self.class_pref["top3"] + self.class_pref["n4"]
        self.class_pref["top5"] = self.class_pref["top4"] + self.class_pref["n5"]

        self.class_pref = self.class_pref.sort_values(["top5"])


        # Add placed students to a set that keeps track of students who can't be placed anymore, and their assigned class
        self.student_assignments = {}

    def place_students(self):
        min_student_assignments = {}
        min_student_happiness = 5
        min_worst_placement = 5

        # iterate 500 times, make sure everyone is happy!
        for i in range(500):
            student_assigments = self.place_students(self.class_pref.copy())
            happiness, worst_placement = self.get_score(student_assigments)
            if worst_placement <= min_worst_placement and happiness <= min_student_happiness:
                min_student_assignments = student_assigments
                min_worst_placement = worst_placement
                min_student_happiness = happiness
        
        return min_student_assignments, min_student_happiness, min_worst_placement

    # get a score for how "happy" people are in their classes
    def get_score(self, student_assignments):
        total = 0
        worst_placement = 0

        for student, course in student_assignments.items():
            prefs = self.completed_forms.loc[self.completed_forms["CX ID"] == student].values.tolist()[0][-5:]
            assigned_class = student_assignments[student]
            total += prefs.index(assigned_class)

            worst_placement = max(worst_placement, prefs.index(assigned_class))
        
        ave_happiness = total / self.num_students
        return ave_happiness, worst_placement

    # If our ordering of classes means one can't be filled, swap it with the one above it
    def swap_up(self, df, i1):
        # swap with above row
        i2 = i1 - 1

        # swap row and index
        df = df.iloc[np.r_[0:i2, i1, i2, i1:(len(df)-1)]]

        return df

    # If there aren't enough students to fill a class, reorder and try again!
    def place_recursive(self, class_preferences):

        num_small_classes = self.small_class_num

        self.student_assignments.clear()

        # Iterate through the classes, starting with the least popular
        for class_num, curr_class in enumerate(class_preferences.index):

            # Determine the class size - less popular classes will have the smaller class sizes
            if num_small_classes > 0:
                curr_size = self.small_class_size
                num_small_classes -= 1
            else:
                curr_size = self.large_class_size

            # Give open spots to students who requested, giving greater weight to higher preference
            curr_preference = 1
            while curr_size > 0 and curr_preference <= 5:
                # Get all students with the current preference level
                curr_students = class_preferences.loc[curr_class][str(curr_preference)]
                # Remove students who have already been placed
                curr_students = [student for student in curr_students if student not in self.student_assignments]
                # If there are more students at this preference level than we are looking for
                if len(curr_students) > curr_size:
                    curr_students = sample(curr_students, curr_size)
                
                for student in curr_students:
                    # Assign student
                    self.student_assignments[student] = curr_class
                    # Fill one slot
                    curr_size -= 1
                
                curr_preference += 1
            
            # If we went through all preferences and the class still isn't filled
            if curr_size > 0:
                # swap class up in preference order
                return self.place_students( self.swap_up(class_preferences, class_num) )
                # If one of their preferred classes contains a student that wants this class, substitute the students
