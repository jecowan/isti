

library(dplyr)

setwd("/Users/christophertien/Documents/CEDR Work/Teacher Feedback Experiment/isti-master/LU")


data <- read.table(file=paste("Lipscomb.csv",
                              sep=""),
                   header=TRUE, sep=",", quote="\"",
                   stringsAsFactors=FALSE)
data <- select(data, StudentID, Assessment_Document_Title,
               Rubric_Title, AssessorUID, Assessor_Role,
               Assessment_Completion_Date, Score, Performance_Levels)
data <- filter(data, Assessment_Document_Title %in% 
                 c("Fifth Teaching Assessment (Fall 2015)", 
                   "Fifth Teaching Assessment (Spring 2016)", 
                   "First Teaching Assessment (Fall 2015)", 
                   "First Teaching Assessment (Spring 2016)", 
                   "Fourth Teaching Assessment (Fall 2015)", 
                   "Fourth Teaching Assessment (Spring 2016)", 
                   "Second Teaching Assessment (Fall 2015)", 
                   "Second Teaching Assessment (Spring 2016)", 
                   "Third Teaching Assessment (Fall 2015)", 
                   "Third Teaching Assessment (Spring 2016)"))

# Clean up evaluation data.
data$Rubric_Title <- gsub("^ ", "", data$Rubric_Title)
data$Rubric_Title <- gsub(" $", "", data$Rubric_Title)
data <- filter(data, Performance_Levels!="")

dat.clean <- select(data, StudentID, Assessment_Document_Title,
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
  
  # This is the first attempt at splitting. It creates new dataframes within
  # dataframes that are clunky.
  datx <- within(datx, 
                 Performance_Levels <- data.frame(
                   do.call('rbind', 
                           strsplit(as.character(Performance_Levels), 
                                    '|', fixed=TRUE))))
  # Attempt 2. 
  indscores <-data.frame(do.call('rbind', 
                                 strsplit(as.character(datx$Performance_Levels), 
                                    '|', fixed=TRUE)))
  
  # Clean up score data.
  nc <- ncol(datx$Performance_Levels)
  for(i in 1:nc){
    # Replace "N/A" with "0.000-N/A".
    datx$Performance_Levels[, i] <- gsub("^N/A", 
                                         "0.000-N/A", 
                                         datx$Performance_Levels[, i])
    # Destring.
    datx$Performance_Levels[, i] <- 
      as.numeric(substr(datx$Performance_Levels[, i], 1, 5))
  }
  
  # Rename score variables.
  colnames(datx) <- c(colnames(datx)[-length(colnames(datx))], r)

  # Merge to evaluation data.
  dat.clean <- merge(dat.clean, datx, 
                     by=c("StudentID", "Assessment_Document_Title",
                          "Assessor_Role", "Assessment_Completion_Date"))
}


dat.clean <- dplyr::arrange(dat.clean, StudentID, Assessment_Completion_Date)
