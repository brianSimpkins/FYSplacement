## 07 July 2022
##  testing this code out with an initial file of some poor fits


# set the working directory

### Macintosh version
thiscomp<-Sys.info()['user']
boxprefix <- paste("/Users",thiscomp,"Library/CloudStorage/Box-Box",sep="/")  # location of box sync folder
FYSdir22<-paste(boxprefix,"Pitzer FYS Program/2022 FYS Program/assigning students",sep="/")

setwd(FYSdir22)


afile1<-"assigned_07Jul_1243.csv"
# afile2<-"assigned_12Jul_1119.csv"

namesfile <- "classnames_2022_07Jul.csv"

 adf1 <- read.csv(paste(FYSdir22,afile1,sep="/"),stringsAsFactors=FALSE, header=TRUE)
# adf2 <- read.csv(paste(FYSdir,afile2,sep="/"),stringsAsFactors=FALSE, header=TRUE)
# IDcols<-c("uniqueID" ,"First","Preferred","Last" ,"Round" ,"Gender","IPEDS.Classification","First.Gen"  ,                "Major.Interest.by.Division", "Athlete"  ,"Pref.1","Pref.2" ,"Pref.3"  , "Pref.4" , "Pref.5"      )
# adf<-merge(adf1[,-1],adf2[,-1],by=IDcols,all=TRUE)
adf<-adf1

altc <- colnames(adf)[19:ncol(adf)]  ### first assigned class is in column 19
crit<-colnames(adf)[7:11]
maincrit<-crit[1:3]

## not using this in 2022
## create an alternate dataset that excludes anything with more than 4 students 
##	having a 4th place choice.  We need 4 to fill Maria/Kebokile's class, but the
##	rest of the students should get into top 3

#small.adf <- adf[, - which(names(adf) %in% altc)]
#for (j in altc) {
#	if (num4th(adf,j) < 5) { 
#		small.adf <- cbind(small.adf,adf[,j])
#		names(small.adf)[ncol(small.adf)] = j
#	}
#}
small.adf <- adf
alts <-  colnames(small.adf)[19:ncol(small.adf)]  ### first assigned class is in column 19

### build a summary dataset of all the saved combinations

sm.sum <- summary.fits(small.adf,alts)
sm.sum


## this code re-runs the summary file, using on low better ranked assignments
dropf <- sm.sum$classi[sm.sum$prefscore > 436]
keepf <- sm.sum$classi[sm.sum$prefscore <= 436]
small2 <- small.adf[, - which(names(small.adf) %in% dropf)]
sm.sum2 <- summary.fits(small2,keepf)
sm.sum2

### paste back in the names

# read in the hash table
fullnames <- read.csv(paste(FYSdir22,namesfile,sep="/"),stringsAsFactors=F)
fullnames$X <- NULL

new.small2 <- addnames(small2,keepf,fullnames)

### export the subset to look at in excel
write.csv(new.small2,paste(FYSdir,"combinations_1Aug2020.csv",sep="/"),row.names=F,fileEncoding = "macroman")


##############
##	FUNCTIONS
##############


findswitch <- function (possible,lookingfor) {
	p1 <- possible[possible$Pref.1 %in% lookingfor,]
	p2 <- possible[possible$Pref.2 %in% lookingfor,]
	p3 <- possible[possible$Pref.3 %in% lookingfor,]
	return(unique(rbind(p1,p2,p3)))

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

##prefscore(adf,altc[1])
## num4th(adf,altc[1])

num4th <- function (alldf,classcol) {
##	needs a df where each row is student, there are 5 pref columns
##	and a column to calcuate the preferences of the each students' assignments
## returns the number of students that have 4th place choice

	n4 <- sum(alldf$Pref.4 == alldf[[classcol]])
	return(n4)

}

summary.fits <- function (flist, nfits)  {
	# loop over alternate class assignments and calculate summary statistics
	altsummary <- data.frame(classi=character(),score=integer(),num4th=integer(),onefg=integer(),lowmale=integer(),lowfemale=integer(),mostwhite=integer(),
	                  stringsAsFactors=FALSE)
	
	 for (i in nfits) {
		## calc summary statistics for each class
		
		#gender
		gen<-as.data.frame.matrix(table(flist[[i]],flist$Gender))
		names(gen) <- make.names(names(gen))
		gen$pct.male<-100*gen$Cisgender.Man/rowSums(gen)
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
		print(c2)
		
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
		s<-prefscore(flist,i)
		n4 <- num4th(flist,i)
		
		## add to summary dataframe
		quicksum <- data.frame(i,s,n4,b,c,d,e,
	                  stringsAsFactors=FALSE)
	    colnames(quicksum) <- c("classi","prefscore","num4th","onefg","lowmale", "lowfemale", "mostwhite")
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

