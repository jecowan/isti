
# CreateReport.r

usePackage <- function(p) {
  if (!is.element(p, installed.packages()[,1]))
    install.packages(p, repos="https://cran.fhcrc.org/")
  library(p,character.only=T)
}

for( pkg in c("ggplot2","reshape2","stringr","data.table","dplyr","gdata","knitr","RColorBrewer", "grid", "emojifont", "xtable")){
  usePackage(pkg)
}
load.emojifont('OpenSansEmoji.ttf')
setwd("/Users/christophertien/Documents/CEDR Work/Teacher Feedback Experiment/isti-master/LU")


#################################################
# Defining domains. Separate R script
#################################################
source("DefineLUDomains.R")

#################################################
# Reading and cleaning data. Separate R script
#################################################
source("LipscombImport.R")



#################################################
# Read evaluation data.
#################################################
raw <- rename.vars(dat.clean, c("Assessor_Role","Assessment_Completion_Date"), c("attribute_1","submitdate"))

raw$newflag <- 1

data <- remove.vars(raw, c("Assessment_Document_Title"))

# for(j in 1:numq) {
#   data[,j] <- gsub("A", "", data[,j])
# }
# data[, 1:numq] <- sapply((data[,1:numq]), as.numeric)

setDT(data)[, new := max(newflag), by = c("StudentID")]

#Run only if there are new entries
if( sum(data$new) != 0 ){
data<- data[which(data$new == 1),]


setDT(data)[, id := .GRP, by = c("StudentID")]

data<- as.data.frame(data)
data <- remove.vars(data, c("new", "newflag", "StudentID"))

colnames(data)[7:26] <- 1:20


dlf <- melt(data, 
            id.vars = c("id", "firstname1", "lastname1", "email1","firstname2", "lastname2", "email2", "submitdate", "attribute_1", "mentteachname", "mentteachemail"))
setDT(dlf)[, question := .GRP, by = c("variable")]
setDT(dlf)[, type := .GRP, by = c("attribute_1")] # 1 = FS

dlf$submitdate <- as.Date(dlf$submitdate,format = "%m/%d/%Y")


setDT(dlf)[, type.order := order(rev(rank(submitdate))), by  = c("id", "type", "question")]
setDT(dlf)[, oa.order := order(rev(rank(submitdate))), by  = c("id", "question")]


dlf <- rename.vars(dlf, c("value"), c("score"))
dlf <- as.data.frame(dlf)

dlf <- merge(dlf, domain.code, by="question")

data.out <- dlf[which(dlf$type.order == 1),]
data.out <- data.out[,c("id","firstname1","lastname1","domain","question","score", "submitdate")]
data.out$Evaluator <- paste(data.out$firstname, data.out$lastname, sep = " ")
data.out$submitdate <- format(data.out$submitdate, "%m/%d/%Y")



dlf <- remove.vars(dlf, c("variable", "submitdate"))


mt.data <- subset(dlf[,names(dlf) %in% c("id", "domain","question", "score")], dlf$attribute_1 == ment.name)
mt.data <- remove.vars(mt.data, c("row.names"))
if(mean(mt.data$score) == "NaN") {
  mt.avg <- mt.data
} else {
mt.avg <- aggregate(x = mt.data, by = list(mt.data$domain, mt.data$id, mt.data$question), FUN = "mean")
mt.avg <- remove.vars(mt.avg, c("Group.1", "Group.2", "Group.3"))
}

fi.data <- subset(dlf[,names(dlf) %in% c("id", "domain","question", "score")], dlf$attribute_1 == sup.name)
fi.data <- remove.vars(fi.data, c("row.names"))
if(mean(fi.data$score) == "NaN") {
  fi.avg <- fi.data
} else {
fi.avg <- aggregate(x = fi.data, by = list(fi.data$domain, fi.data$id, fi.data$question), FUN = "mean")
fi.avg <- remove.vars(fi.avg, c("Group.1", "Group.2", "Group.3"))
}
fi.avg <- rename.vars(fi.avg, c("score"), c("fi.score"))



if(mean(mt.avg$score) == "NaN") {
  combined.data <- fi.avg
  combined.data$score <- NA
} else if(mean(fi.avg$fi.score) == "NaN") {
  combined.data <- mt.avg
  combined.data$fi.score <- NA
} else {
  combined.data <- merge(mt.avg, fi.avg, 
                       by = c("id", "domain", "question"))
}
combined.data$qid <- paste(combined.data$domain, 
                           combined.data$question,
                           sep=".")

# Look at: This is a little sloppy!!!!!
comb.avg.by <- group_by(dlf, domain, question)
comb.avg <- summarise(comb.avg.by,
                      popmean = mean(score),
                      min = min(score),
                      pop25pt = quantile(score, 0.25),
                      pop75pt = quantile(score, 0.75),
                      max = max(score))


domain.data <- data.frame(id = dlf$id,domain = dlf$domain,score = dlf$score)
domain.avg <- aggregate(x = domain.data, by = list(domain.data$domain, domain.data$id), FUN = "mean")
domain.avg <- remove.vars(domain.avg, c("Group.1", "Group.2"))
domain.avg.by <- group_by(domain.data, domain)
domain.sum <- summarise(domain.avg.by,
                        popmean = mean(score),
                        min = min(score), popmedian = median(score),
                        pop25pt = quantile(score, 0.25),
                        pop75pt = quantile(score, 0.75),
                        max=max(score))

#################################################
# Function to create graphs.
#################################################


creategraphs <- function(id) {
  score.id <- merge(domain.avg[which(domain.avg$id==id), ], domain.sum, by="domain")
  score.id <- merge(score.id, domain.names, by = "domain")
  score.id <- score.id[order(score.id$domain_name),]
  
  p2<- ggplot(score.id) +
    geom_rect(aes(x=domain_name,xmin=(1:numd-.2), 
                  xmax=(1:numd+.2), 
                  ymin=1, 
                  ymax=pop25pt,fill="25th percentile or less"),
              alpha=1/3, 
              linetype="blank") +
    geom_rect(aes(x=domain_name,xmin=(1:numd-.2), 
                  xmax=(1:numd+.2), 
                  ymin=pop25pt, 
                  ymax=pop75pt,fill="Middle 50%"),
              alpha=1/3, 
              linetype="blank") + 
    geom_rect(aes(x=domain_name,xmin=(1:numd-.2), 
                  xmax=(1:numd+.2), 
                  ymin=pop75pt, 
                  ymax=max,fill="75th percentile or greater"),
              alpha=1/3, 
              linetype="blank") + 
    geom_point(data=score.id,
               mapping=aes(x = domain_name, y = popmean, color="Program Average"), size=2.5, shape = 19) + 
    geom_point(data=score.id,
               mapping=aes(x = domain_name, y = score, color="Your Average"), size=2, shape = 15) +
    
    scale_y_continuous(limit = c(1, (nums+.6)), breaks=(1:nums), expand=c(0,0)) +
    
    scale_x_discrete(expand=c(0.15, 0.0)) +
    ylab("") + xlab("") +
    theme(axis.ticks = element_blank(),
          axis.line.x = element_line(),
          axis.line.y = element_line(),
          axis.text.y = element_text(size=14),
          axis.text.x = element_text(size=10),
          axis.title.x = element_text(size=16),
          legend.text = element_text(size=16),
          legend.title = element_text(size=16),
          panel.grid.minor.x = element_blank(),
          panel.grid.minor.y = element_blank(),
          aspect.ratio=0.5,
          panel.background=element_rect(fill="white"),
          plot.margin = unit(c(0,0,0,0), "cm")) +
    scale_fill_manual(name="", values=c("25th percentile or less" = "red", "Middle 50%"="orange", "75th percentile or greater" = "green"), guide = "legend") +
    scale_colour_manual(name="", 
                        values=c("Program Average" = "light blue",
                                 "Your Average" = "black"), 
                        guide = "legend") +
    guides(fill = guide_legend(order = 1),colour = guide_legend(order = 2,override.aes = list(linetype=c(0,0)
                                                                                              , shape=c(19, 15)))) + coord_flip()
  smiley <- data.frame(domain = 1:5)
  smiley$emoji <- ""
  emoji_name <- 'smiley'
  for (i in 1:numd) {
    
    if(score.id[i,]$score >= score.id[i,]$popmedian & score.id[i,]$score < score.id[i,]$pop75pt) {
      smiley[i,]$emoji <- emoji(emoji_name)
    } else if (score.id[i,]$score >= score.id[i,]$pop75pt) {
      smiley[i,]$emoji <- paste(emoji(emoji_name),emoji(emoji_name), sep = " ")
    }
    
    
    p2 <- p2 + annotation_custom(grob = textGrob(label = round(score.id[i,]$popmean,1), gp = gpar(fontsize=10)), xmin = i+.6, xmax = i+.6, ymin = score.id[i,]$popmean, ymax = score.id[i,]$popmean) 
    p2 <- p2 + annotation_custom(grob = textGrob(label = round(score.id[i,]$score,1),gp = gpar(fontsize=10)), xmin = i+.3, xmax = i+.3, ymin = score.id[i,]$score, ymax = score.id[i,]$score) 
    
  }
  score.id <- merge(score.id, smiley, by = "domain")
  score.id$nums <- nums
  p2 <- p2 + geom_text(data=score.id, aes(x = domain, y = score.id$nums+.3, label =score.id$emoji), family="OpenSansEmoji", color = "orange", size=6) 
  
  
  
  filename <- paste("DomainPlotTest", ".pdf", sep="")
  
  ggsave(file = filename, width=10, height=3)
  
  # Take entry with 5 lowest scores for first observation.
  score.id <- merge(dlf[which(dlf$id==id & dlf$oa.order == 1), ], comb.avg, 
                    by=c("domain", "question"))
  score.id <- merge(score.id,domain.avg, by=c("id","domain"), suffixes = c("",".avg"))
  score.id <- arrange(score.id, score.avg, score, -popmean)
  
  score.id <- score.id[1:5, ]
  score.avg.id <- dlf[which(dlf$id==id),c("score", "question", "id", "domain")]
  score.avg.id <-aggregate(x = score.avg.id, by = list(score.avg.id$domain, score.avg.id$question, score.avg.id$id), FUN = "mean")
  score.avg.id$pre <- score.avg.id$score
  score.avg.id <- remove.vars(score.avg.id, c("score", "Group.1","Group.2","Group.3"))
  
  score.id <- merge(score.id, score.avg.id, by=c("id","domain", "question"))
  score.id <- arrange(score.id, score.avg)
  domain.info <- score.id[1,]$domain
  score.id <- merge(score.id, question.names, by=c("question"))
  score.id <- score.id[order(score.id$question_name),]
  
  # Attempt to recreate the second graph
  p1<- ggplot(score.id) +
    geom_rect(aes(x=question_name,xmin=(1:5 - 0.25), 
                  xmax=(1:5 + 0.25), 
                  ymin=1, 
                  ymax=pop25pt,fill="25th percentile or less"),
              alpha=1/3, 
              linetype="blank") +
    geom_rect(aes(x=question_name,xmin=(1:5 - 0.25), 
                  xmax=(1:5 + 0.25), 
                  ymin=pop25pt, 
                  ymax=pop75pt,fill="Middle 50%"),
              alpha=1/3, 
              linetype="blank") + 
    geom_rect(aes(x=question_name,xmin=(1:5 - 0.25), 
                  xmax=(1:5 + 0.25), 
                  ymin=pop75pt, 
                  ymax=nums,fill="75th percentile or greater"),
              alpha=1/3, 
              linetype="blank") +
    geom_point(data=score.id,
               mapping=aes(x = question_name, y = pre, color="Your Average"), size=2) +
    scale_y_continuous(limit = c(1, (nums+.1)), breaks=(1:nums), expand=c(0,0))  +
    scale_x_discrete(expand=c(0.1, 0.1)) +
    xlab("") + ylab("") +
    theme(axis.ticks = element_blank(),
          axis.line.x = element_line(),
          axis.line.y = element_line(),
          axis.text.y = element_text(size=14),
          axis.text.x = element_text(size=10),
          axis.title.x = element_text(size=16),
          legend.text = element_text(size=16),
          legend.title = element_text(size=16),
          panel.grid.minor.x = element_blank(),
          panel.grid.minor.y = element_blank(),
          aspect.ratio=0.3,
          panel.background=element_rect(fill="white"),
          plot.margin = unit(c(0,0,0,0), "cm")) +
    scale_fill_manual(name="", values=c("25th percentile or less" = "red", "Middle 50%"="orange", "75th percentile or greater" = "green"), guide = "legend") +  
    scale_colour_manual(name="",
                        values=c("Your Average"="black"), guide='legend') +
    guides(fill = guide_legend(order = 1),colour = guide_legend(order = 2, override.aes = list(linetype=c(0)
                                                                                               , shape=c(16)))) +
    coord_flip()
  
  for (i in 1:5) {
    #p2 <- p2 + annotation_custom(grob = textGrob(label = round(score.id[i,]$popmean,1)), xmin = i+.4, xmax = i+.4, ymin = score.id[i,]$popmean, ymax = score.id[i,]$popmean) 
    p1 <- p1 + annotation_custom(grob = textGrob(label = round(score.id[i,]$pre,1)), xmin = i+.4, xmax = i+.4, ymin = score.id[i,]$pre, ymax = score.id[i,]$pre) 
    
  }
  
  filename <- paste("FocusAreaPlotTest", ".pdf", sep="")
  
  ggsave(file = filename, width=10.5, height=3)   
  
  # Strengths plot
  # Take entry with 5 highest scores for first observation.
  score.id <- merge(dlf[which(dlf$id==id & dlf$oa.order == 1), ], comb.avg, 
                    by=c("domain", "question"))
  score.id <- merge(score.id,domain.avg, by=c("id","domain"), suffixes = c("",".avg"))
  score.id <- arrange(score.id, -score.avg, -score, -popmean)
  
  score.id <- score.id[1:5, ]
  score.avg.id <- dlf[which(dlf$id==id),c("score", "question", "id", "domain")]
  score.avg.id <-aggregate(x = score.avg.id, by = list(score.avg.id$domain, score.avg.id$question, score.avg.id$id), FUN = "mean")
  score.avg.id$pre <- score.avg.id$score
  score.avg.id <- remove.vars(score.avg.id, c("score", "Group.1","Group.2","Group.3"))
  score.id <- merge(score.id, score.avg.id, by=c("id","domain", "question"))
  score.id <- arrange(score.id, -score.avg)
  domain.info2 <- score.id[1,]$domain
  score.id <- merge(score.id, question.names, by=c("question"))
  score.id <- score.id[order(score.id$question_name),]
  
  p3<- ggplot(score.id) +
    geom_rect(aes(x=question_name,xmin=(1:5 - 0.25), 
                  xmax=(1:5 + 0.25), 
                  ymin=1, 
                  ymax=pop25pt,fill="25th percentile or less"),
              alpha=1/3, 
              linetype="blank") +
    geom_rect(aes(x=question_name,xmin=(1:5 - 0.25), 
                  xmax=(1:5 + 0.25), 
                  ymin=pop25pt, 
                  ymax=pop75pt,fill="Middle 50%"),
              alpha=1/3, 
              linetype="blank") + 
    geom_rect(aes(x=question_name,xmin=(1:5 - 0.25), 
                  xmax=(1:5 + 0.25), 
                  ymin=pop75pt, 
                  ymax=nums,fill="75th percentile or greater"),
              alpha=1/3, 
              linetype="blank") +
    geom_point(data=score.id,
               mapping=aes(x = question_name, y = pre, color="Your Average"), size=2) +
    scale_y_continuous(limit = c(1, (nums+.1)), breaks=(1:nums), expand=c(0,0))  +
    scale_x_discrete(expand=c(0.1, 0.1)) +
    xlab("") + ylab("") +
    theme(axis.ticks = element_blank(),
          axis.line.x = element_line(),
          axis.line.y = element_line(),
          axis.text.y = element_text(size=14),
          axis.text.x = element_text(size=10),
          axis.title.x = element_text(size=16),
          legend.text = element_text(size=16),
          legend.title = element_text(size=16),
          panel.grid.minor.x = element_blank(),
          panel.grid.minor.y = element_blank(),
          aspect.ratio=0.3,
          panel.background=element_rect(fill="white"),
          plot.margin = unit(c(0,0,0,0), "cm")) +
    scale_fill_manual(name="", values=c("25th percentile or less" = "red", "Middle 50%"="orange", "75th percentile or greater" = "green"), guide = "legend") +  
    scale_colour_manual(name="",
                        values=c("Your Average"="black"), guide='legend') +
    guides(fill = guide_legend(order = 1),colour = guide_legend(order = 2, override.aes = list(linetype=c(0)
                                                                                               , shape=c(16)))) +
    coord_flip()
  
  for (i in 1:5) {
    #p2 <- p2 + annotation_custom(grob = textGrob(label = round(score.id[i,]$popmean,1)), xmin = i+.4, xmax = i+.4, ymin = score.id[i,]$popmean, ymax = score.id[i,]$popmean) 
    p3 <- p3 + annotation_custom(grob = textGrob(label = round(score.id[i,]$pre,1)), xmin = i+.4, xmax = i+.4, ymin = score.id[i,]$pre, ymax = score.id[i,]$pre) 
    
  }
  
  filename <- paste("StrengthPlot", ".pdf", sep="")
  
  ggsave(file = filename, width=10.5, height=3)   
  
  # attempt to recreate the third plot
  
  id.temp <- id
  score.id <- combined.data[combined.data$id==id.temp,]
  score.id$diff <- abs(score.id$fi.score - score.id$score)
  score.id <- aggregate(x = score.id, by = list(score.id$domain, score.id$id), FUN = "mean")
  score.id <- score.id[order(-score.id$diff),]
  domain.temp <- score.id[1,]$domain
  score.id <- arrange(filter(combined.data, combined.data$id==id.temp, combined.data$domain==domain.temp), -abs(fi.score - score))[1:5, ]
  score.id <- merge(score.id, comb.avg, by=c("domain", "question"))
  na.temp <- score.id[1,]$score + score.id[1,]$fi.score
  domain.info <- data.frame(domain.info,domain.info2,domain.temp)
  colnames(domain.info) <- c("domain1", "domain2", "domain3")
  domain.names <- rename.vars(domain.names, c("domain", "domain_name"), c("domain1", "dom.name1"))
  
  domain.out <- merge(domain.info, domain.names, by = "domain1")
  domain.names <- rename.vars(domain.names, c("domain1", "dom.name1"), c("domain2", "dom.name2"))
  domain.out <- merge(domain.out, domain.names, by = "domain2")
  domain.names <- rename.vars(domain.names, c("domain2", "dom.name2"), c("domain3", "dom.name3"))
  domain.out <- merge(domain.out, domain.names, by = "domain3")
  rows <- NROW(na.omit(score.id))
  score.id <- merge(score.id, question.names, by=c("question"))
  score.id <- score.id[order(score.id$question_name),]
  
  if(!is.na(na.temp)){  
    ggplot(score.id) +
      geom_rect(aes(x=question_name,xmin=(1:rows - 0.25), 
                    xmax=(1:rows + 0.25), 
                    ymin=1, 
                    ymax=pop25pt,fill="25th percentile or less"),
                alpha=1/3, 
                linetype="blank") +
      geom_rect(aes(x=question_name,xmin=(1:rows - 0.25), 
                    xmax=(1:rows + 0.25), 
                    ymin=pop25pt, 
                    ymax=pop75pt,fill="Middle 50%"),
                alpha=1/3, 
                linetype="blank") + 
      geom_rect(aes(x=question_name,xmin=(1:rows - 0.25), 
                    xmax=(1:rows + 0.25), 
                    ymin=pop75pt, 
                    ymax=nums,fill="75th percentile or greater"),
                alpha=1/3, 
                linetype="blank") +
      geom_segment(aes(x=1:rows, y=fi.score, xend=1:rows, yend=score)) +
      geom_point(aes(x = 1:rows, y=score, color="Mentor Teacher"), size=3) +
      geom_point(aes(x = 1:rows, y=fi.score, color="Field Instructor"), 
                 shape = 15, size=3) +  
      scale_y_continuous(limit = c(1, (nums+.1)), breaks=(1:nums), expand=c(0,0))  +
      scale_x_discrete(expand=c(0.1, 0.1)) +
      xlab("") + ylab("") +
      theme(axis.ticks = element_blank(),
            axis.line.x = element_line(),
            axis.line.y = element_line(),
            axis.text.y = element_text(size=14),
            axis.text.x = element_text(size=10),
            axis.title.x = element_text(size=16),
            legend.text = element_text(size=16),
            legend.title = element_text(size=16),
            panel.grid.minor.x = element_blank(),
            panel.grid.minor.y = element_blank(),
            aspect.ratio=0.3,
            panel.background=element_rect(fill="white"),
            plot.margin = unit(c(0,0,0,0), "cm")) +
      coord_flip() +
      scale_fill_manual(name="", values=c("25th percentile or less" = "red", "Middle 50%"="orange", "75th percentile or greater" = "green"), guide = "legend") +  
      scale_colour_manual(name="Rater", values=c("Field Instructor" = "black",
                                                 "Mentor Teacher" = "black")) +
      guides(colour = guide_legend(override.aes = list(linetype=c(0,0)
                                                       , shape=c(19, 15))))
    
    ggsave(file = "DiscussionAreaPlotTest.pdf", width=10.5, height=3) 
  }
  return(domain.out)  
}

#################################################
# Applying the function.
#################################################

# Testing the first case
creategraphs(1)
# knit2pdf("TestReport.Rnw", output = "TestReport1.tex")

# Creating the output table with names and document information
output <- dlf[which(dlf$type.order==1), ]
mt.names <- output[which(output$attribute_1==ment.name),]
mt.names <- remove.vars(mt.names, c("row.names", "question", "score", "oa.order", "type", "type.order", "domain", "firstname2", "lastname2", "email2"))
rownames(mt.names) <- NULL
mt.names <- unique(mt.names)
mt.names$mentteachname <- paste(mt.names$firstname1, mt.names$lastname1, sep = " ")
mt.names <- rename.vars(mt.names, "email1", "mentteachemail")
mt.names <- remove.vars(mt.names, c("firstname1", "lastname1", "attribute_1"))


fi.names <- output[which(output$attribute_1 ==sup.name),]
fi.names <- remove.vars(fi.names, c("row.names", "question", "score", "oa.order", "type", "type.order", "domain", "firstname2", "lastname2", "email2"))
rownames(fi.names) <- NULL
fi.names <- unique(fi.names)
fi.names$fieldinstname <- paste(fi.names$firstname1, fi.names$lastname1, sep = " ")
fi.names <- rename.vars(fi.names, "email1", "fieldinstemail")
fi.names <- remove.vars(fi.names, c("firstname1", "lastname1", "attribute_1", "mentteachemail", "mentteachname"))

output <- remove.vars(output, c("row.names", "question", "score", "oa.order", "type", "type.order", "domain", "firstname1", "lastname1", "email1"))
output <- unique(output)
rownames(output) <- NULL

output$studteachname <- paste(output$firstname2, output$lastname2, sep = " ")
output <- rename.vars(output, "email2", "studteachemail")
output <- remove.vars(output, c("firstname2", "lastname2"))
output <- merge(output, fi.names, by = "id", all.x =T)
#output <- merge(output, mt.names, by = "id", all.x =T)
output$filename <- ""
output$send <- NA
# Creating the reports using knitr
for(i in 1:max(data$id)) {
  domain.out<- creategraphs(i)
  table <- data.out[which(data.out$id==i),]
  table <- table[order(table$submitdate, table$Evaluator, table$domain, table$question),]
  table <- merge(table, question.names, by= "question")
  table <- merge(table, domain.names, by = "domain")
  table$question_name <- paste(substr(table$question_name, 1, 30), "...", sep = "")
  table <- rename.vars(table, c("domain_name","question_name","score", "submitdate"), c("Domain", "Question", "Score", "Date"))
  
  names <- output[which(output$id==i), ]
  if(mean(fi.data$score) != "NaN"){fi.myavg <- aggregate(x = fi.data[which(fi.data$id==i), ], by = list(fi.data[which(fi.data$id==i), ]$domain), FUN = "mean")}
  if(mean(mt.data$score) != "NaN"){mt.myavg <- aggregate(x = mt.data[which(mt.data$id==i), ], by = list(mt.data[which(mt.data$id==i), ]$domain), FUN = "mean")}
  myavg <- domain.avg[which(domain.avg$id==i), ]
  time <- Sys.Date()
  file.name <- paste("PerformanceEvaluationReport", gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".tex", sep="")
  knit2pdf("PerformanceEvaluationReport.Rnw", file.name)
  file.aux <- paste("PerformanceEvaluationReport", gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".aux", sep="")
  file.out <- paste("PerformanceEvaluationReport", gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".out", sep="")
  file.xwm <- paste("PerformanceEvaluationReport", gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".xwm", sep="")
  file.log <- paste("PerformanceEvaluationReport", gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".log", sep="")
  file.pdf <- paste("PerformanceEvaluationReport", gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".pdf", sep="")
  output[i,]$filename <- file.pdf
  output[i,]$send <- rbinom(1,1,.5)
  file.remove(file.name, file.aux, file.out, file.xwm, file.log)
}

# Outputing file names, names, and email information
#output$filename <- gsub(":", "/", output$filename, fixed = TRUE)

# adding in the variables for focus areas (1 for domain.question, 1 for score) and discussion areas (each score and question, 3 vars)


write.table(output, "output.csv", sep = ",", row.names = F)

}

