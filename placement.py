# First let's set up some imports
import numpy as np
import pandas as pd
import unicodedata as ud
import math
from random import sample, shuffle
from collections import defaultdict

class Pitzer_Placement:

    def __init__(self, filepath):
        # Now let's collect our data
        df = pd.read_csv(filepath)

        # Separate forms by completion
        self.completed_forms = df[df["Completed Form"] != "No"]
        incomplete_forms = df[df["Completed Form"] != "Yes"]
        self.num_students = len(self.completed_forms)

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
        self.large_class_size = math.ceil(self.num_students / len(classes))
        self.small_class_size = self.large_class_size - 1
        self.small_class_num = len(classes) * self.large_class_size - self.num_students


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

    def save_assignments(self, filepath):
        output = self.completed_forms.drop(columns = self.completed_forms.columns[-5:])
        new_col = output["CX ID"].apply(lambda x : self.student_assignments[x])
        output.insert(1, "Assignment", new_col)
        output.sort_values(by = ["Assignment"], inplace = True)
        output.to_csv(path_or_buf = (filepath + "/FYS_StudentAssignments.csv"), index = False)
        

    def place_students(self):
        min_student_assignments = {}
        min_student_happiness = 5
        min_worst_placement = 5

        # iterate 100 times, make sure everyone is happy!
        for i in range(100):
            student_assigments = self.place_recursive(self.class_pref.copy())
            happiness, worst_placement = self.get_score(student_assigments)
            if worst_placement <= min_worst_placement and happiness <= min_student_happiness:
                min_student_assignments = student_assigments
                min_worst_placement = worst_placement
                min_student_happiness = happiness
        
        self.student_assignments = min_student_assignments

        return min_student_happiness, min_worst_placement

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

        student_assignments = {}

        # Iterate through the classes, starting with the least popular
        for class_num, curr_class in enumerate(class_preferences.index):

            # Keep track of gender balance in class
            gender_map = defaultdict(int)

            # Keep track of racial balance in class
            race_map = defaultdict(int)

            # Determine the class size - less popular classes will have the smaller class sizes
            if num_small_classes > 0:
                remaining_size = self.small_class_size
                num_small_classes -= 1
            else:
                remaining_size = self.large_class_size

            # Give open spots to students who requested, giving greater weight to higher preference
            curr_preference = 1
            while remaining_size > 0 and curr_preference <= 5:

                # Get all students with the current preference level
                curr_students = class_preferences.loc[curr_class][str(curr_preference)]

                # Remove students who have already been placed
                curr_students = [student for student in curr_students if student not in student_assignments]

                # If there are more students at this preference level than we are looking for
                if len(curr_students) > remaining_size:

                    # Give priority to non-majority genders to help balance class
                    students_min_gender_min_race = []
                    students_min_gender_maj_race = []
                    students_maj_gender_min_race = []
                    students_maj_gender_maj_race = []
                    
                    # Loop through pool
                    for student in curr_students:
                        # Determine gender of student
                        gender = self.completed_forms.loc[self.completed_forms["CX ID"] == student]["Gender"].values[0]
                        race = self.completed_forms.loc[self.completed_forms["CX ID"] == student]["IPEDS Classification"].values[0]
                        
                        # Determine majority gender in the class
                        if len(gender_map.keys()) > 0:
                            maj_gender = max(gender_map, key = gender_map.get)
                        else:
                            maj_gender = ""

                        # Determine majority race in the class
                        if len(race_map.keys()) > 0:
                            maj_race = max(race_map, key = race_map.get)
                        else:
                            maj_race = ""

                        # Add student to either minority list or majority list
                        if gender == maj_gender:
                            if race == maj_race:
                                students_maj_gender_maj_race.append(student)
                            else:
                                students_maj_gender_min_race.append(student)
                        else:
                            if race == maj_race:
                                students_min_gender_maj_race.append(student)
                            else:
                                students_min_gender_min_race.append(student)
                        
                        # update gender map (fine guess)
                        gender_map[gender] += 1

                    shuffle(students_min_gender_min_race)
                    shuffle(students_min_gender_maj_race)
                    shuffle(students_maj_gender_min_race)
                    shuffle(students_maj_gender_maj_race)
                    
                    # First place the students who aren't of the majority gender, then the rest
                    curr_students = (students_min_gender_min_race + students_min_gender_maj_race + students_maj_gender_min_race + students_maj_gender_maj_race)[:remaining_size]
                
                for student in curr_students:
                    # Get gender
                    gender = self.completed_forms.loc[self.completed_forms["CX ID"] == student]["Gender"].values[0]
                    # Get race
                    race = self.completed_forms.loc[self.completed_forms["CX ID"] == student]["IPEDS Classification"].values[0]
                    # Increment gender map
                    gender_map[gender] += 1
                    # Increment race map
                    race_map[race] += 1

                    # Assign student
                    student_assignments[student] = curr_class
                    # Fill one slot
                    remaining_size -= 1
                
                curr_preference += 1
            
            # If we went through all preferences and the class still isn't filled, swap the class up and try again!
            if remaining_size > 0:
                class_preferences = class_preferences.iloc[np.r_[0: class_num - 1, class_num, class_num - 1, class_num + 1 : len(class_preferences)]]
                return self.place_recursive(class_preferences)
        
        return student_assignments
