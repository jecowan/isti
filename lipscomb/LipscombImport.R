library(dplyr)
library(tidyr)
library(gdata)

simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
}

setwd("/Users/christophertien/Documents/CEDR Work/Teacher Feedback Experiment/isti-master/LU")


data <- read.table(file=paste("FEM_AssessmentDataExtract_2017-02-13_17.csv",
                              sep=""),
                   header=TRUE, sep=",", quote="\"",
                   stringsAsFactors=FALSE)
data <- select(data, StudentID, Assessment_Document_Title,
               Rubric_Title, Assessor_Role, Student_Name, Assessor_Name,
               Assessment_Completion_Date, Score, Performance_Levels)

data$Student_Name <- tolower(data$Student_Name)
data$Assessor_Name <- tolower(data$Assessor_Name)
data <- filter(data, Assessment_Document_Title %in% 
                 c("Fifth Teaching Assessment (Spring 2017)", 
                   "First Teaching Assessment (Spring 2017)", 
                   "Fourth Teaching Assessment (Spring 2017)", 
                   "Second Teaching Assessment (Spring 2017)", 
                   "Third Teaching Assessment (Spring 2017)"),
               is.na(Score)==FALSE)
data <-extract(data, Student_Name, c("firstname2", "lastname2"), "(^\\S*) (\\S.*)")

for (i in 1:nrow(data)) {
  if (regexec(" [^ ]*$", data[i,]$lastname2) != -1)
    data[i,]$lastname2 <- substr(data[i,]$lastname2, regexpr(" [^ ]*$", data[i,]$lastname2)[1]+1, nchar(data[i,]$lastname2))
}

data <-extract(data, Assessor_Name, c("firstname1", "lastname1"), "(^\\S*) (\\S.*)")

for (i in 1:nrow(data)) {
  if (regexec(" [^ ]*$", data[i,]$lastname1) != -1)
    data[i,]$lastname1 <- substr(data[i,]$lastname1, regexpr(" [^ ]*$", data[i,]$lastname1)[1]+1, nchar(data[i,]$lastname1))
}

# Clean up evaluation data.
data$Rubric_Title <- gsub("^ ", "", data$Rubric_Title)
data$Rubric_Title <- gsub(" $", "", data$Rubric_Title)
data$Rubric_Title <- gsub("Teaching Assessment Rubric - ", "", data$Rubric_Title)

data <- filter(data, Performance_Levels!="")


# Define unique observations.
dat.clean <- select(data, StudentID,  firstname2, lastname2, firstname1, lastname1, Assessment_Document_Title,
                    Assessor_Role, Assessment_Completion_Date)
dat.clean <- distinct(dat.clean)

rubrics <- c("Assessing", "Confident and Passionate", "Implementing",
             "Managing", "Relationships")

for(r in rubrics){
  # Break individual item scores into separate variables.
  datx <- filter(data, Rubric_Title==r)
  datx <- select(datx, StudentID, Assessment_Document_Title,
                 Assessor_Role, Assessment_Completion_Date,
                 Performance_Levels)
  x <- data.frame(do.call('rbind', 
                          strsplit(as.character(datx$Performance_Levels), 
                                   '|', fixed=TRUE)))
  names(x) <- paste(r, names(x), sep=".")
  
  
  # Clean up score data.
  nc <- ncol(x)
  for(i in 1:nc){
    # Replace "N/A" with "0.000-N/A".
    x[, i] <- gsub("^N/A", "0.000-N/A", x[, i])
    # Destring.
    x[, i] <- as.numeric(substr(x[, i], 1, 5))
  }
  
  x <- cbind(x, datx[, c("StudentID", "Assessment_Document_Title",
                         "Assessor_Role", "Assessment_Completion_Date")])

  # Merge to evaluation data.
  dat.clean <- merge(dat.clean, x, 
                     by=c("StudentID", "Assessment_Document_Title",
                          "Assessor_Role", "Assessment_Completion_Date"))
}


dat.clean <- dplyr::arrange(dat.clean, StudentID, Assessment_Completion_Date)
contact <- read.table(file=paste("contact-list.csv",
                              sep=""),
                   header=TRUE, sep=",", quote="\"",
                   stringsAsFactors=FALSE)
contact$firstname1 <- tolower(contact$firstname1)

contact$firstname2 <- tolower(contact$firstname2)
contact$lastname1 <- tolower(contact$lastname1)
contact$lastname2 <- tolower(contact$lastname2)
for (i in 1:nrow(contact)){
  if (contact[i,]$firstname2 == "mike") {
    contact[i,]$firstname2 <- "michael"
  }
  if (contact[i,]$firstname1 == "dave") {
    contact[i,]$firstname1 <- "david"
  }
  if (contact[i,]$lastname2 == "gwin") {
    contact[i,]$lastname2 <- "gwinn"
  }
}
for (i in 1:nrow(dat.clean)){
  if (dat.clean[i,]$firstname2 == "abby") {
    dat.clean[i,]$firstname2 <- "abigail"
  }
  if (dat.clean[i,]$firstname2 == "kelley") {
    dat.clean[i,]$firstname2 <- "kelly"
  }
  if (dat.clean[i,]$firstname1 == "jo") {
    dat.clean[i,]$firstname1 <- "joann"
  }
  if (dat.clean[i,]$lastname2 == "pentecost") {
    dat.clean[i,]$lastname2 <- "pentecost-bratton"
  }
}

contact.assess <- select(contact, firstname1, lastname1, email1)
contact.assess <- distinct(contact.assess)
contact.stud <- select(contact, firstname2, lastname2, email2)
contact.stud <- distinct(contact.stud)

dat.clean <- merge(dat.clean, contact.assess, by = c("firstname1", "lastname1"), all.x = T)
dat.clean <- merge(dat.clean, contact.stud, by = c("firstname2", "lastname2"), all.x = T)

#Adding new mentor information variables
contact.ment <- select(contact, firstname2, lastname2, firstname1, lastname1, email1, assessor_role)
contact.ment <- distinct(contact.ment)
for (i in 1:nrow(contact.ment)) {
contact.ment[i,]$firstname1 <- simpleCap(contact.ment[i,]$firstname1)
contact.ment[i,]$lastname1 <- simpleCap(contact.ment[i,]$lastname1)
}
contact.ment <- contact.ment[which(contact.ment$assessor_role == "Mentor"),]
contact.ment$mentteachname <- paste(contact.ment$firstname1, contact.ment$lastname1, sep = " ")
contact.ment <- rename.vars(contact.ment, c("email1"), c("mentteachemail"))
contact.ment <- remove.vars(contact.ment, c("assessor_role", "firstname1", "lastname1"))

dat.clean <- merge(dat.clean, contact.ment, by = c("firstname2", "lastname2"), all.x = T)
for (i in 1:nrow(dat.clean)) {
dat.clean[i,]$firstname2 <- simpleCap(dat.clean[i,]$firstname2)
dat.clean[i,]$lastname2 <- simpleCap(dat.clean[i,]$lastname2)
dat.clean[i,]$firstname1 <- simpleCap(dat.clean[i,]$firstname1)
dat.clean[i,]$lastname1 <- simpleCap(dat.clean[i,]$lastname1)
}
