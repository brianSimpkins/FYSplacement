## 15 July 2022
##  There seems to be a bug in the code that assigns no students
##  to Harmony O'Rourke's section.  I wonder why?
##    It looks like the .csv file gets read in wrong
##    O‚ÄôRourke, Harmony - "Women and Political Change in Africa"
##    actually doesn't seem to be a problem with reading the file
##    in, but in write.csv, including in the classnames file....
##    what seems to work is manually importing the file into excel
##    and telling excel the coding is UTF 8

##  also noticed that the class assignments aren't all 15-16.  I see some
##  with 19 students.  I wonder if that is happening during the swap?
##  I don't have time to find the error and fix the code, so I will just
##  have to swap out a few students manually, or look for assignments that
##  don't have this problem....

## 07 July 2022
##  starting with last year's code to see if it works...

## 8 July 0-21
##  Running with a new dataset that has all but 2 students

## 7 JULY 2021
##  Updated the code for when it goes to 4th choice
##  instead of adding all 4th choice to the pool, it picks
##  a random subset of 4th choice picks that is double the # needed
##  this ensures most of the students assigned listed it as a top 3 choice
##  but allows more the min #4th choices to be used

## 6 July 2021
##	starting to run with this year's students
##	this is just a trial run, as I am still missing a few students' forms

## 31 July 2020
##	tweak this version so that it starts with top 3 choices
##	but if it pulls out <15 students, then it goes to top 4


## 30 July 2020
##	I had to go to top 4 choices because there were only
##	8 students in the top 3 for 1 sections (and 12 for another)
##  I may want play with only using top 4  if top 3 < 13
##	because in a small number of iterations, the only successful
##	match had 50 students with their 4th choice, which is not great
## 	but first I'll try running 200,000 iterations and see how many fits I get


## 3 July 2020
## practicing with this file on last year's data to make sure I have the right 
## & practicing with preliminary data for 2020
##	R code to do the assignments
## 	the edits I am makeing are:
##	- change the working directory & filename
##	- change the number of iterations from 300,000 to 300
##	- looks like the file has an extra column this year CXID. updated code

## Some students listed Ballagh's section as one of their choices
## 	 only 3 students put it in their top 3, 11 students total listed
## 	 this is not an option for regular 1st years
## 	 If I delete it, should I move the other preferences up?
##	 what would happen if I have a null value for Pref.5?



# running 100,000 iterations, I got four that assigned all students to their top 3 choices!!
## added a line to save output periodically


## added a bit that changes class sizes for some to 15, but now the last section can't
## get filled with top 3 preferences of last 15 students.
## expanding to the top 5 preferences somehow made it worse
## it always seems to be the same student who is unassigned.
## maybe I should rethink how to choose the courses that are 15 vs 14?


## R file to assign students to groups

## Criteria
## Try to get everyone into a top 3 choice (relax to top 4 or 5 if needed)
## Try to maintain gender balance of at leat 35% each gender  (incoming class is 35% male)
## Try to maintain racial balance of not more than 45% white (incoming class is 47% white)
## No first gen should be the sole first gen in a section

#############################
# set the working directory & get the files 
##############################

### Macintosh version
thiscomp<-Sys.info()['user']

boxprefix <- paste("/Users",thiscomp,"Library/CloudStorage/Box-Box",sep="/")  # location of box drive folder
#boxprefix <- paste("/Users",thiscomp,"Box Sync/",sep="/")  # location of box sync folder 


FYSdir22<-paste(boxprefix,"Pitzer FYS Program/2022 FYS Program/assigning students",sep="/")

practice2022 <- "FYS Fall 2022 Results - Active Commits 20220712-180011.csv"

### PC Version
#FYSdir21 <- "C:/Users/sgilman/Box/Pitzer FYS Program/2021 FYS Program"
#practice2021 <- "FYS Fall 2021 Results - Active Commits 20210708-164005.csv"

setwd(FYSdir22)

### trying to guess the encoding of the data file
#install.packages("readr")
library(readr)
guess<-guess_encoding(practice2022,n_max = -1,)
guess

prefs<-read.csv(practice2022, stringsAsFactors=FALSE)
#prefsb<-read.csv(practice2022, stringsAsFactors=FALSE,fileEncoding = "UTF-8")

## fix the zipcode column
prefs$newzip <- sprintf("%05d", prefs$Permanent.Address.ZIP.Code)
prefs$Permanent.Address.ZIP.Code <- NULL

## rename the CX.ID column, if its not what I think it is
if (is.null(prefs$CX.ID)) {colnames(prefs)[colnames(prefs) == "?..CX.ID"] <- "CX.ID"}


#########################
##	Assign a unique number to each classname 
#########################
# note: I think I could have gotten this quicker using the table() function

#pull out the course names into a separate dataframe
allprefs<-c(prefs$Preference.1,prefs$Preference.2,prefs$Preference.3,prefs$Preference.4,prefs$Preference.5)
classnames<-as.data.frame(unique(allprefs),stringsAsFactors=FALSE)
colnames(classnames)<-c("Preference")
classnames$lname <- ""
## remove any blank rows in the classnames list (from students who didn't indicate a preference)
classnames<-classnames[!classnames$Preference == "",]


## IN 2022 the section numbers used by the Registrar were not alphabetical. 
## I'm trying to write some code, to pull just the last name off of the pref file
classnames$lname  <- sub(",.*",'',classnames$Preference)

## next I need to find a source file with the right section numbers
## I decided it would be easier to do this by hand
rownames(classnames)<-NULL
classnames$classnum<-as.numeric(rownames(classnames))
classnames$classnum[17]<-21
classnames$classnum[9:16] <- c(10:17)
classnames <- classnames[order(classnames$classnum),]


## save the list of numbered sections
cname<-paste("classnames_2022",format(Sys.time(),"%d%b"),sep="_")
write.csv(classnames,paste(cname,"csv",sep="."))
#write.csv(classnames,paste(cname,"csv",sep="."),fileEncoding = "UTF-8" )


###########################
## replace all course names with their numbers
##########################

## first reshape from wide to long
## then merge in the numbers
## then delete names
## then reshape from long to wide

prefsL<-reshape(prefs,varying<-c("Preference.1","Preference.2","Preference.3","Preference.4","Preference.5"), direction="long", sep=".")
prefsL2<-merge(prefsL,classnames,by="Preference",all=TRUE)
prefsL2$rank<-paste("Pref",prefsL2$time,sep=".")

## keep: First, Preferred, Last, Round, Gender, IPEDS...., First.Gen, Major.Interest..by.Division
##	Athelete, classnum, rank, CX.ID, newzip
ids<-c("CX.ID","First","Preferred","Last", "Round","Gender","IPEDS.Classification","First.Gen","Major.Interest.by.Division","Athlete", "newzip" )
prefsL3<-prefsL2[,c(ids,"classnum","rank")]
prefs2<-reshape(data=prefsL3, idvar=ids, direction="wide", v.names="classnum", timevar="rank")

## fix the names of the preferences columns
toolong<-colnames(prefs2)[12:16]
shorter<-substr(toolong,10,15)
colnames(prefs2)[12:16]<-shorter
prefs2[,12:16]<-sapply(prefs2[,12:16],as.numeric)
# fix a weird ordering of the prefs2 columns
prefs3 <- prefs2[,c(ids,"Pref.1","Pref.2","Pref.3","Pref.4","Pref.5")]
prefs3<-cbind(prefs2[,c(1:11)],prefs2[,c("Pref.1","Pref.2","Pref.3","Pref.4","Pref.5")])
prefs3$uniqueID <-paste(prefs3$CX.ID,prefs3$First,prefs3$Last,sep=".")

## what happens to students who have no submitted preferences?
## right now they are all NAs
## I am going to remove those students
noform <- is.na(prefs3$Pref.1) & is.na(prefs3$Pref.2) & is.na(prefs3$Pref.3)  & is.na(prefs3$Pref.4)  & is.na(prefs3$Pref.5)
prefs3nom <- prefs3[!noform,]

#############################
## now summarize the number of 1st, 2nd, 3rd choices by course
#############################

coursepref<-as.data.frame(rbind(table(prefsL3$classnum,prefsL3$rank)))
#coursepref <- prefs3nom[,c("Pref.1","Pref.2","Pref.3","Pref.4","Pref.5")]
numsect<-nrow(coursepref)

#combined preferences
coursepref$cPref.2<-coursepref$Pref.1 + coursepref$Pref.2
coursepref$cPref.3<-coursepref$cPref.2 + coursepref$Pref.3
coursepref$cPref.4<-coursepref$cPref.3 + coursepref$Pref.4
coursepref$cPref.5<-coursepref$cPref.4 + coursepref$Pref.5


coursepref[order(coursepref$cPref.3),]
# Pref.1 Pref.2 Pref.3 Pref.4 Pref.5 cPref.2 cPref.3 cPref.4 cPref.5
# 12      2      5      5      9     10       7      12      21      31
# 14      2      5      9      9      7       7      16      25      32
# 17      4      5      9      7      3       9      18      25      28
# 5       5      9      5      7      7      14      19      26      33
# 7       6      7      8     11     18      13      21      32      50
# 21     10      3      9     10     22      13      22      32      54
# 3       5     10      8     13      5      15      23      36      41
# 18      9      7      7     17     14      16      23      40      54
# 15      3      9     15     11     10      12      27      38      48
# 16     10     13     10     11     11      23      33      44      55
# 13     16     11     11     20     15      27      38      58      73
# 8      17     19     17     19     16      36      53      72      88
# 2      14     24     18     14     19      38      56      70      89
# 19     17     20     20     17     22      37      57      74      96
# 11     20     22     22     17     15      42      64      81      96
# 6      25     23     28     16     26      48      76      92     118
# 1      33     25     20     20     12      58      78      98     110
# 20     26     30     26     28     28      56      82     110     138
# 10     37     23     31     27     24      60      91     118     142
# 4      48     39     31     26     25      87     118     144     169

##	2021 ##
## looks like need to go to 4th choices to fill section 12 and 
## possibly section 14,17

##############################
##	Eliminate Cancelled Sections
#################################

### none cancelled in 2022
## Sometimes I do cancel one after all the forms are submitted
## this would be if the # committed students drops over the summer


##############################
##	 Assign Students
#################################
## NOTE - need to submit functions at the END of this file before this step

## Current Approach:
## Rank course by # top 4 choices
## then starting with the lowest preferred course, pull out a random sample of 
## all those who listed it in their top 3,
## if there are not enough, then pull in the students who ranked the course 4th
## then move onto the next course, using the un-selected students from the 1st round
## each round, I would need to check who is left, and who is the lowest preferred course

usethisdf <- prefs3nom  # which version of the dataset to use

# preflist<-c("Pref.1","Pref.2","Pref.3","Pref.4","Pref.5")
# preflist<-c("Pref.1","Pref.2","Pref.3","Pref.4")
preflist<-c("Pref.1","Pref.2","Pref.3")
morepref <- "Pref.4"

#onlysect <- rownames(cpref2)
onlysect <- unique(c(usethisdf$Pref.1,usethisdf$Pref.2,usethisdf$Pref.3,usethisdf$Pref.4,usethisdf$Pref.5)) # get a ist of the section numbers
nsect<-length(onlysect)
nprefs<-length(preflist)
nstud <- nrow(usethisdf)
classsizes<-sectsize(nstud,nsect)
cat(classsizes[2],"sections of",classsizes[1],"and",classsizes[4], "sections of",classsizes[3])
smsize <-classsizes[1]  # size of the smaller sections.  larger sections will have one more student
nsmall <- classsizes[2] # number of small sections, rest are large
assignrecord<-usethisdf

## main search and fill loop
## it does about 550 iterations in one minute
#for (i in 1:500) {
for (i in 1:80000) {
	print(paste("iteration",i))
	
	# set up dataframes
	to.assign <-usethisdf
	to.assign$class<-0	
#	emptysect <-1:numsect
	emptysect <- onlysect ## only assign the 17 sections left in the fall
	assigned<-to.assign[to.assign$Pref.1==0,]  # code to create an empty dataframe

# loop over sections
	for (a in 1:nsect) {
		#print(paste("section iteration",a))
		
		# calc section size
		if (a <= nsmall) {csize<-smsize} else {csize <- smsize + 1}
		
		# of the remaining sections, calculate how many top npref votes each has
		longr<-reshape(to.assign,varying<-preflist, direction="long", sep=".")
		rtally<-as.data.frame(rbind(table(longr$Pref,longr$time)))
		rtally$secnum<-rownames(rtally)
		rtally <- rtally[rtally$secnum %in% emptysect,]
		rtally$sum <- apply(rtally[,(1:nprefs)], 1, sum)
		cur.sect <-rtally[order(rtally$sum)[1],"secnum"]
		#print(paste("filling section", cur.sect))
		emptysect<-emptysect[emptysect != cur.sect]  # remove from remaining list
		
		# extract everyone who included cur.sect in their top X choices
		curpool <- to.assign[to.assign$Pref.1==0,]  # create empty dataframe
		for (b in 1:nprefs){
			colval<-paste("Pref",b,sep=".")
			curpool <- rbind(curpool,to.assign[to.assign[colval]==cur.sect,])	
		}  # end b loop
		# eliminate double counting of students who list a course twice
		curpool <- curpool[!duplicated(curpool),]
		## if there are < csize students, then go to the 4th pref
		##  NOTE this assumes there are enough 4th choices.  If not it may break
		if (nrow(curpool)<csize) { 
		  needmore <- 2*(csize-nrow(curpool)) #how many 4th choice to add in
		  choice4 <- to.assign[to.assign[morepref]==cur.sect,]
		  # if there are more than 2x the number needed, pick 2x, otherwise add all
		  if (nrow(choice4)>needmore) {
		    curpool <- rbind(curpool,choice4[sample(nrow(curpool),needmore,replace=FALSE),])
		  } else {curpool <- rbind(curpool,choice4)} 
			curpool <- curpool[!duplicated(curpool),]
		}
		#print(paste(nrow(curpool),"students for section",cur.sect))
		
		# check if there are enough students left, if not assign all
		if (nrow(curpool)<csize) {
			print (paste("iteration",i,"class",a,"only",nrow(curpool), "students for section",cur.sect))
			#unassigned <- to.assign[!(to.assign$uniqueID %in% curpool$uniqueID), ]
			#print(unassigned[,c(1,3,10:14)])
			thisclass<-curpool
			flush.console() 
		}  else {
			# take a random sample of the extracted students and assign
			thisclass<-curpool[sample(nrow(curpool),csize,replace=FALSE),]	
		}	#end if	(nrow(curpool)<csize)
		thisclass$class <- cur.sect
		assigned <- rbind(assigned,thisclass)
		# print(paste(nrow(thisclass),"students assigned to section",cur.sect))
			
		# put everyone else back into the pool
		to.assign <- to.assign[ !(to.assign$uniqueID %in% thisclass$uniqueID), ]
		brief <-(assigned[,c("uniqueID","class")])
		colnames(brief)[2]<-paste("class",i,sep=".")
		
	}  #end a loop
	if (nrow(to.assign)>0) {print(paste(nrow(to.assign),"students not assigned"))
	}	else {
	  assignrecord <- merge(assignrecord,brief,by="uniqueID",all=TRUE)
	  print("ALL STUDENTS ASSIGNED !!!!")
	}
	if (i %% 50000 == 0 ) {
		sname<-paste("assigned",format(Sys.time(),"%d%b_%H%M"),sep="_")
		write.csv(assignrecord,paste(sname,"csv",sep="."))

	}
}  # end i loop

sname<-paste("assigned",format(Sys.time(),"%d%b_%H%M"),sep="_")
write.csv(assignrecord,paste(sname,"csv",sep="."))

#########################
######	FUNCTIONS
#########################


findbelowmin<-function(enrolled, min=14) {
	sections<-as.data.frame(table(enrolled$class), stringsAsFactors=FALSE)
	colnames(sections)<-c("sect","csize")
	open<-sections$sect[sections$csize<min]
	open	
}

findopen <-function (enrolled, cap=15) {
	sections<-as.data.frame(table(enrolled$class), stringsAsFactors=FALSE)
	colnames(sections)<-c("sect","csize")
	open<-sections$sect[sections$csize<cap]
	open
}

sectsize <-function (nstud=278 ,nsect=19) {
	maxclass <- ceiling(nstud/nsect)
	minclass <- maxclass - 1
	nmin<-(maxclass*nsect)-nstud
	return(c(minclass,nmin,maxclass,nsect-nmin))
}

###################
####  Functions not actually used
#####################



swaparound <-function(todo,done,cap=15,preflim=3) {
	# find which classes are undercap
	opensect<-findopen(done,cap)
	lowsect<-findbelowmin(done,cap-1)

	# build a list of students who prefer the under-enrolled sections
	maybe <- done[done$Pref.1==0,]  # create empty dataframe
	d2<-done[!(done$class %in% lowsect),] 
	for (q in lowsect) {
		for (b in 1:preflim){
			colval<-9+b
			maybe <- rbind(maybe,d2[d2[colval] == q,])		
		}
	maybe <- unique(maybe)  # remove duplicates
	}
	
	# iterate through list of unassigned students, match with a student in a class 
	# move that student into the low enroll class and then give the unassigned student
	# that seat
	for (r in 1:nrow(todo)) {
		pref <- todo[r, (9+1):(9+preflim)]
		for (b in 1:preflim) {
			pref<-todo[r,9+b]
			mbe<-maybe[maybe$class %in% pref,]
			
		}
	
	}
}


tweaklast <-function(todo, done, cap=15, preflim=3) {
	# find which classes are undercap
	opensect<-findopen(done,cap)
	lowsect<-findbelowmin(done,cap-1)
	
	#iterate through students in "todo"
	for (d in 1:nrow(todo)) {
		cur.stud <-todo[d,]
		# try a direct assignment
		for (f in 1:preflim) {
			if (cur.stud[1,9+f] %in% opensect) {
				# assign the student to the open section
				# update the open section list
				# move onto next student, make sure to break out of current student completely
			}
		# if that didn't work, try moving a student out of a section into another
		for (f in 1:preflim) {
			# check if any student in pref 1 has a top three prefernce in an open section
			# if not, move onto pref 2
			# if so, move the student into the other section, and move this student in
			
		}
		
			
			
		}
		
	}
}

addifopen <- function (one.stu,enr,cap, plim=3, firstp=10) {
	opensect<-findopen(enr, cap)
	for (p in 1:plim) {
		if (one.stu[1,p+9] %in% opensect) {
			one.stu[1,"class"]<-one.stu[1,p]
			enr <- rbind(enrolled,one.stu)
			break  # out of p loop
		}
	}
	enr 
}

addbymoving <- function (one.stu, enrolled, cap, plim=3, firstp=10) {
	
}

