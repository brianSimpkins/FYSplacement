## 15 Jul 2022
## the output from 13 Jul created some classes with more or less than 15-16
##  why did this happen, and can I easily fix it?
##    the bug seemed to be in the code for improve one students
##    if there were multiple good matches for switching a student, it
##    may have assigned all those students tot he students prior section
## rerunning with improved code
## but now it doesn't do any swaps
## and I have further fucked up the code so it doesn't run  :(

## its running now.  The problem was that in improve score, I pulled a list 
##  of students at each preference level, but that list didn't update 
##  after each swap, so I sent outdated information to improveonestudent
##  now it uses the pulled list just for CX.IDs and then uses the most
##  updated information for each student.

# 13 July 2022
##  Running on the final set (maybe?)

## 08 July 2022
##  Running on a fuller set of potential assignments

## 07 July 2022
##  trying this on some practice 2022 class assignments
##  this code all works, now I need to set up an overnight run at work
##  to run through 100,000 iterations and find some good starting assignments
##  to work with.

## 08 July 2021
##	running on a few of the 2021 class assigments


## 29 June 2021
## 	Goal is to take set of FYS assignments and swap students
##	To improve the number who get their 1st choice of 2nd
##	2nd choice over 3rd, etc.

## 	I'll start by practicing with one of last year's output files
##	go through each section, look for a student assigned their 4th choice
##	see if their 1st, 2nd, or 3rd choice courses have a student
##	that I could swap to improve both preferences

# set the working directory
thiscomp<-Sys.info()['user']
boxprefix <- paste("/Users",thiscomp,"Box Sync/",sep="/")  # location of box sync folder 
#boxprefix <- paste("/Users",thiscomp,"Library/CloudStorage/Box-Box",sep="/")  # location of box sync folder
FYSdir<-paste(boxprefix,"Pitzer FYS Program/2022 FYS Program/assigning students",sep="/")

setwd(FYSdir)

#afile1<-"assigned_12Jul_1750.csv"
afile1<-"assigned_18Jul_1316.csv"

namesfile <- "classnames_2022_15Jul.csv"
studentfile <- "FYS Fall 2022 Results - Active Commits 20220712-180011.csv"

 adf1 <- read.csv(paste(FYSdir,afile1,sep="/"),stringsAsFactors=FALSE, header=TRUE)
 adf<-adf1 
 
 classnames<-read.csv(paste(FYSdir,namesfile,sep="/"),stringsAsFactors=FALSE, header=TRUE)
classnames$X <- NULL

# make a vector of all column names in the dataframe that have a class assignment
altc <- colnames(adf)[19:ncol(adf)]  ### first assigned class is in column 19

# make a vector of all the column names with students demographic information
crit<-colnames(adf)[7:11]
maincrit<-crit[1:3]

#fits<-summary.fits(adf,altc[1:2])


### find the class fit with the lowest preference score for now
### also create a not so low fit so I can test if my code makes a better fit
fits<-summary.fits(adf,altc)
summary(fits)

table(fits$prefscore,useNA="a")
table(fits$onefg,useNA="a")
table(fits$num4th,useNA="a")
table(fits$lowmale,useNA="a")
fits2<-fits[order(fits$prefscore),]
fits2[fits2$prefscore<662,]  #median
tail(fits2)
fits[fits$onefg < 5,]
fits[fits$num4th < 6,]



### so I think the best think would be to pick about 20-30 and run then all through
###	the 10ish best initial scores
### the 2 with <5 isolated fgen students
### the ~7 with only 4 4th place choice

#1. make a vector of all those class names and remove any duplicates
good<-fits$classi[fits$prefscore <= 660 | fits$onefg < 5 | fits$num4th < 5 |fits$lowmale<8]
length(good)
fits[fits$classi %in% good,]

#2.	use the code above to loop over all of them and find better ones
t5<-adf
for (c in 1:length(good)) {
	alist <- good[c]
	t5<-improvescore(t5,alist,paste(alist,"bet",sep="."))
}
better<-paste(good,"bet",sep=".")
newfits.sum <- summary.fits(t5,c(good,better))
newfits.sum[order(newfits.sum$prefscore),]

#3. save those better ones and then compare them in the excel spreadsheet

### paste back in the class names

# start by reading in the original data file
#		 (the student id information in the working file doesn't have all the original columns)
prefs<-read.csv(studentfile, stringsAsFactors=FALSE)

# get just the cx.id and the .bet fits into a new data from from betterfits
tokeep <- t5[,c("CX.ID",better)]
newfits <- merge(prefs,tokeep,by="CX.ID",all=T)

renamecols <- setdiff(names(newfits),names(prefs))

clname2 <- classnames[,c("Preference","classnum")]
finalbetter<- addnames(newfits,renamecols,clname2)

### export the subset to look at in excel
## I don't why I have a specific file encoding, it seems to give me an 
##  error message, so am also saving without encoding

write.csv(finalbetter,"betterfits_2022_18_Jul.csv",row.names=F,fileEncoding = "macroman")
write.csv(finalbetter,"betterfits_2022_18_Jula.csv",row.names=F)

# save a summary table as well
write.csv(newfits.sum[order(newfits.sum$prefscore),],"summary_bfits_18_Jul.csv",row.names=F)

############
##	FUNCTIONS
############

findaswap <- function (preferred, current, prefstu) {
	##	needs a preferred section number, a current section number
	##	and a dataframe of just the students in the preferred section number
	##  returns the df with two extra columns, one for the preferred section number
	##	the other is the improvement for that student that would prefer current
	
	#cat("finding swap from class",preferred," to ",current,"\n")
	
	prefstu$better <- 10  # default score if "current" is not a student's top 5
	prefstu$cscore <- 10  # default class rank if student is in a section they didn't rank
	
	# label each student as to whether they ranked current and what they ranked it
	pcols <- c( "Pref.1","Pref.2","Pref.3" ,"Pref.4" , "Pref.5")
##	prefstu$m <- apply(prefstu[,pcols], 1, function(x) match(TRUE, x == current))
	prefstu$better[prefstu$Pref.1 == current]<-1
	prefstu$better[prefstu$Pref.2 == current]<-2
	prefstu$better[prefstu$Pref.3 == current]<-3
	prefstu$better[prefstu$Pref.4 == current]<-4
	prefstu$better[prefstu$Pref.5 == current]<-5

	## a negative value indicates a student would be better off switching with the target student
	prefstu$cscore[prefstu$Pref.1 == preferred]<-1
	prefstu$cscore[prefstu$Pref.2 == preferred]<-2
	prefstu$cscore[prefstu$Pref.3 == preferred]<-3
	prefstu$cscore[prefstu$Pref.4 == preferred]<-4
	prefstu$cscore[prefstu$Pref.5 == preferred]<-5

	prefstu$bb<- prefstu$better - prefstu$cscore
	#cat("found",nrow(prefstu[prefstu$bb < 0,]),"\n")
	return (prefstu[prefstu$bb < 0,])
}

findallswaps <- function (prefsec, current, allsections,assigned) {
	##	take a vector of one student's preferences and their current assignment
	##	builds a df of possible swaps by repeated calls to findaswap
	##  checks to make sure a class exists (and was not cancelled before trying to swap)
	
	tosearch <- match(current,prefsec,nomatch=5) - 1 
	#cat("finding swaps from ",prefsec, "to ",current, "stopping after",tosearch, "\n")
	
	allswap <- list()
	for (j in 1:tosearch) {
		i <- prefsec[j]
		#cat("i=",i,"\n")
		nextclass <- allsections[allsections[[assigned]] == i,]
		if (nrow(nextclass)>0) {
			allswap[[j]] <- findaswap(i,current,nextclass)
		} 
	}
	allsw<-do.call(rbind,allswap)
	return(allsw)
}

improveonestudent <- function (studentrow,allstudents,assigned) {
    ## takes the row number of one student
  	## assigned is the name of the column that has the class assignments that are being modified
	#cat("improveonestudent", assigned, "  ")
  currclass <- studentrow[1,assigned]
	prefs<-as.vector(t(studentrow[1,c("Pref.1","Pref.2","Pref.3","Pref.4","Pref.5")]))
	curpref <- match(currclass,prefs,nomatch=0)
	if (curpref != 1) {  # skip if the student alredy has 1st choice
		couldswap <- findallswaps(prefs,currclass,allstudents,assigned)
		#cat("found ", nrow(couldswap)," swaps \n")
		#cat(is.null(couldswap))
		
		## evaluate the df of all possible swaps and randomly pick among the best
		## if there are no possible swaps, skip this step
		if ( !is.null(couldswap)) {
			if (nrow(couldswap) > 0) {
			best<-min(couldswap$better)
				allbest <- couldswap[couldswap$better == best,]
				#cat("allbest rows =",nrow(allbest))
				toswitch <- allbest[sample(nrow(allbest),1),] # this is the student to switch from
				#cat(toswitch[,c("uniqueID",assigned,"")])
				#cat("swapping student", rownames(toswitch),"\n")
			
				## swap the two students
				##  assigned is the column name of class assignment we are currently working with
				#cat("swapping ",studentrow$CX.ID[1], studentrow[1,assigned], toswitch$CX.ID[1], toswitch[1,assigned],"\n")
	#     this is the old code which is doing weird things	
				cat (studentrow$CX.ID[1], "was", studentrow[1,assigned], toswitch$CX.ID[1], "was", toswitch[1,assigned], "  ")
				allstudents[allstudents$CX.ID == studentrow$CX.ID,assigned] <- toswitch[1,assigned]
				allstudents[allstudents$CX.ID == toswitch$CX.ID,assigned] <- studentrow[1,assigned]
	#     what if I tweak the matching criteria a little - this also works fine
		#   so there was not an error in the code that assigned students to the wrong section
		#   at least from what I can tell
#				allstudents[allstudents$CX.ID == studentrow[1,"CX.ID"],assigned] <- toswitch[1,assigned]
	#			allstudents[allstudents$CX.ID == toswitch$CX.ID[1],assigned]  <- studentrow[1,assigned]
				cat(studentrow$CX.ID[1],"now",allstudents[allstudents$CX.ID == studentrow[1,"CX.ID"],assigned],
				    toswitch$CX.ID[1], "now" ,allstudents[allstudents$CX.ID == toswitch[1,"CX.ID"],assigned],"\n")
			}
		}
	}
	return(allstudents)
}

improvescore <- function(alldf,assign.now,newname) {
	## works through every student assigned a preference > 1
	## calls "improveonestudent" to try and find a swap to make that student happier
	## I may want also have repeat the process several times and return the most improved score
	## assign.now is the name of the column with the current assignments
	## this creates a new column that has the improved assignments, doesn't change the old
	
	## create a column for the new assignments that starts with old assignments
	alldf[[newname]] <-alldf[[assign.now]] 	
	c.sizes <- sectsize(nrow(alldf),length(unique(alldf$Pref.1)))
	for (k in 5:2){
		prefcol <- paste("Pref",k,sep=".")
		unhappy <- alldf[ alldf[[prefcol]] == alldf[[newname]],]
		cat(nrow(unhappy)," students in ", prefcol,"\n")
		cat("IDs = ", unhappy$CX.ID,"\n")
		if (nrow(unhappy) > 0 ) {
			for (j in 1:nrow(unhappy)) {
			  cat(check.class.sizes(alldf[,newname],c.sizes[1],c.sizes[3]))
				one <- alldf[alldf$CX.ID == unhappy$CX.ID[j],]
				#cat("finding a swap for student ",one[1,"CX.ID"],"\n")
				alldf <- improveonestudent(one,alldf,newname)
			}
		}
	}	
	compare <- summary.fits(alldf,c(assign.now,newname))
	cat("final size check: ",check.class.sizes(alldf[,newname],c.sizes[1],c.sizes[3]))
	return(alldf)
}


prefscore <- function (alldf,classcol) {
##	needs a df where each row is student, there are 5 pref columns
##	and a column to calcuate the preferences of the each students' assignments

	score<-0
	r1 <- 1*sum(alldf$Pref.1 == alldf[[classcol]])
	r2 <- 2*sum(alldf$Pref.2 == alldf[[classcol]])
	r3 <- 3*sum(alldf$Pref.3 == alldf[[classcol]])
	r4 <- 4*sum(alldf$Pref.4 == alldf[[classcol]])
	r5 <- 5*sum(alldf$Pref.5 == alldf[[classcol]])
	return(r1+r2+r3+r4+r5)

}

num4th <- function (alldf,classcol) {
##	needs a df where each row is student, there are 5 pref columns
##	and a column to calcuate the preferences of the each students' assignments
## returns the number of students that have 4th place choice

	n4 <- sum(alldf$Pref.4 == alldf[[classcol]])
	return(n4)

}

num3rd <- function (alldf,classcol) {
##	needs a df where each row is student, there are 5 pref columns
##	and a column to calcuate the preferences of the each students' assignments
## returns the number of students that have 3rd place choice

	n3 <- sum(alldf$Pref.3 == alldf[[classcol]])
	return(n3)

}


summary.fits <- function (flist, nfits)  {
	# loop over alternate class assignments and calculate summary statistics
	altsummary <- data.frame(classi=character(),score=integer(),num4th=integer(),onefg=integer(),lowmale=integer(),lowfemale=integer(),mostwhite=integer(),
	                  stringsAsFactors=FALSE)
	
	 for (i in nfits) {
		## calc summary statistics for each class
		
		#gender
		gen<-as.data.frame.matrix(table(flist[[i]],flist$Gender))
		gen$pct.male<-100*gen[["Cisgender Man"]]/rowSums(gen)
		gen$cnum<-as.numeric(rownames(gen))
		
		# first-gen
		fg<-as.data.frame.matrix(table(flist[[i]],flist$First.Gen))
		names(fg)[1]<-"n.firstgen"
		fg$cnum <-as.numeric(rownames(fg))
		
		#race
		ipeds<-as.data.frame.matrix(table(flist[[i]],flist$IPEDS.Classification))
		ipeds$pct.white<-100*ipeds$White/rowSums(ipeds)
		ipeds$cnum<-as.numeric(rownames(ipeds))
		
		# combine
		c1<-merge(gen[,c("cnum","pct.male")],fg[,c("cnum","n.firstgen")],by="cnum",all=TRUE)
		c2<-merge(c1,ipeds[,c("cnum","pct.white")],by="cnum",all=TRUE)
		print(paste("class sort number",i))
		#print(c2)

		# get basic stats for assignment set		
		s<-prefscore(flist,i)
		n3<- num3rd(flist,i)
		n4 <- num4th(flist,i)
		print(paste("Pref Score ",s," with ",n3, n4," 3rd and 4th choices"))

		## calc summmary stats for the whole assignment set
		solofg<-which(c2$n.firstgen==1)
		b<-length(solofg)
		print(paste("Classes with only 1 first gen: ",paste(solofg,collapse=" ")))
		lowmale<-which(c2$pct.male <= 33)
		c<-length(lowmale)
		lowfemale<-which(c2$pct.male >= 67)
		d<-length(lowfemale)
		print(paste("Classes <= 33% male:  ", paste(lowmale,collapse=" ")))
		print(paste("Classes <= 33% female:  ", paste(lowfemale,collapse=" ")))
		mostwhite<-which(c2$pct.white > 70)
		e<-length(mostwhite)
		print(paste("Classes > 70% white:  ",paste(mostwhite,collapse=" ")))
		flush.console()
		assign(i,c2)
		
		## add to summary dataframe
		quicksum <- data.frame(i,s,n3,n4,b,c,d,e,
	                  stringsAsFactors=FALSE)
	    colnames(quicksum) <- c("classi","prefscore","n3rd","num4th","onefg","lowmale", "lowfemale", "mostwhite")
	    altsummary<-(rbind(altsummary,quicksum))
	
	 }
	 return(altsummary[order(altsummary$num4th,altsummary$prefscore,altsummary$onefg),])

}

addnames <- function(sfile,slist,hash) {
	for (k in slist) {
		newcolname <- paste(k,"nm",sep=".")
		snew <- merge(sfile,hash,by.x=k,by.y="classnum",all.x=T,all.y=F)
		names(snew)[names(snew)=="Preference"] <- newcolname
		sfile<-snew
	}
	return(sfile)
}

check.class.sizes <- function (class.vector,minsize,maxsize) {
  sizes <- as.data.frame(table(class.vector))
  names(sizes) <- c("sect","ct")
  wrong <- as.vector(sizes$sect[sizes$ct < minsize | sizes$ct>maxsize])
  if (length(wrong) > 0) {cat ("Sections", wrong, "are the wrong size! \n")}
}

sectsize <-function (nstud=278 ,nsect=19) {
  maxclass <- ceiling(nstud/nsect)
  minclass <- maxclass - 1
  nmin<-(maxclass*nsect)-nstud
  return(c(minclass,nmin,maxclass,nsect-nmin))
}
