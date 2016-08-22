
# CreateReport.r
install.packages("ggplot2",repos="https://cran.fhcrc.org/")
install.packages("reshape2",repos="https://cran.fhcrc.org/")
install.packages("stringr",repos="https://cran.fhcrc.org/")
install.packages("data.table",repos="https://cran.fhcrc.org/")
install.packages("dplyr",repos="https://cran.fhcrc.org/")
install.packages("gdata",repos="https://cran.fhcrc.org/")
install.packages("knitr",repos="https://cran.fhcrc.org/")
install.packages("RColorBrewer",repos="https://cran.fhcrc.org/")

library(ggplot2)
library(reshape2)
library(stringr)
library(data.table)
library(dplyr)
library(gdata)
library(knitr)

library(RColorBrewer)

#################################################
# Defining domains. Separate R script
#################################################
source("DefineDomains.R")

#################################################
# Read evaluation data.
#################################################
raw <- read.csv("Working_Results.csv")
data <- cbind(raw[grepl("SQ", names(raw))], raw[c("firstname", "lastname", "email", "attribute_2", "attribute_4", "attribute_5", "attribute_1", "submitdate", "newflag")])

for(j in 1:numq) {
  data[,j] <- gsub("A", "", data[,j])
}
data[, 1:numq] <- sapply((data[,1:numq]), as.numeric)

setDT(data)[, new := max(newflag), by = c("attribute_2", "attribute_4", "attribute_5")]

#Run only if there are new entries
if( sum(raw$new) != 0 ){
    data<- data[which(data$new == 1),]
    
    
    setDT(data)[, id := .GRP, by = c("attribute_2", "attribute_4", "attribute_5")]
    
    data<- as.data.frame(data)
    data <- remove.vars(data, c("new", "newflag"))
    
    dlf <- melt(data,
    id.vars = c("id", "firstname", "lastname", "email","attribute_2", "attribute_4", "attribute_5", "submitdate", "attribute_1"))
    setDT(dlf)[, question := .GRP, by = c("variable")]
    setDT(dlf)[, type := .GRP, by = c("attribute_1")] # 1 = MT, 2 = FS
    
    setDT(dlf)[, type.order := order(-rank(submitdate)), by  = c("id", "type", "question")]
    setDT(dlf)[, oa.order := order(-rank(submitdate)), by  = c("id", "question")]
    
    
    dlf <- rename.vars(dlf, c("value"), c("score"))
    dlf <- remove.vars(dlf, c("variable", "attribute_1","submitdate"))
    dlf <- as.data.frame(dlf)
    
    dlf <- merge(dlf, domain.code, by="question")
    
    mt.data <- subset(dlf[,names(dlf) %in% c("id", "domain","question","type", "score")], type == 1)
    mt.data <- remove.vars(mt.data, c("row.names", "type"))
    mt.avg <- aggregate(x = mt.data, by = list(mt.data$domain, mt.data$id, mt.data$question), FUN = "mean")
    mt.avg <- remove.vars(mt.avg, c("Group.1", "Group.2", "Group.3"))
    
    
    fi.data <- subset(dlf[,names(dlf) %in% c("id", "domain","question","type", "score")], type == 2)
    fi.data <- remove.vars(fi.data, c("row.names", "type"))
    fi.avg <- aggregate(x = fi.data, by = list(fi.data$domain, fi.data$id, fi.data$question), FUN = "mean")
    fi.avg <- remove.vars(fi.avg, c("Group.1", "Group.2", "Group.3"))
    fi.avg <- rename.vars(fi.avg, c("score"), c("fi.score"))
    
    
    
    
    combined.data <- merge(mt.avg, fi.avg,
    by = c("id", "domain", "question"))
    combined.data$qid <- paste(combined.data$domain,
    combined.data$question,
    sep=".")
    
    comb.avg.by <- group_by(combined.data, domain, question)
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
    min = min(score),
    pop25pt = quantile(score, 0.25),
    pop75pt = quantile(score, 0.75),
    max=max(score))
    
    #################################################
    # Function to create graphs.
    #################################################
    
    
    creategraphs <- function(id) {
        score.id <- merge(domain.avg[which(domain.avg$id==id), ], domain.sum, by="domain")
        
        ggplot(score.id) +
        geom_rect(aes(xmin=(1:4 - 0.5),
        xmax=(1:4 + 0.5),
        ymin=min,
        ymax=pop25pt),
        alpha=1/3,
        linetype="blank",
        fill="red") +
        geom_rect(aes(xmin=(1:4 - 0.5),
        xmax=(1:4 + 0.5),
        ymin=pop25pt,
        ymax=pop75pt),
        alpha=1/3,
        linetype="blank",
        fill="yellow") +
        geom_rect(aes(xmin=(1:4 - 0.5),
        xmax=(1:4 + 0.5),
        ymin=pop75pt,
        ymax=max),
        alpha=1/3,
        linetype="blank",
        fill="green") +
        geom_line(aes(x = domain, y=popmean, color="Program Average"),
        linetype="twodash") +
        geom_point(aes(x = domain, y = popmean, color="Program Average")) +
        geom_line(aes(x = domain, y = score, color = "Your Average"), size=1.25) +
        geom_point(aes(x = domain, y = score, color = "Your Average"),shape = 15, size=2) +
        
        scale_y_continuous(limit = c(1, 5), breaks=(1:5), expand=c(0,0)) +
        scale_x_continuous(limit = c(0.5, 4.5), breaks=(1:5 - .5), expand=c(0,0) ,
        labels = c("", 1:4)) +
        ylab("") + xlab("Domain") +
        theme(axis.ticks = element_blank(),
        axis.text.y = element_text(size=14),
        axis.text.x = element_text(size=16),
        legend.text = element_text(size=16),
        legend.title = element_text(size=16),
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        panel.grid.major=element_line(color="gray"),
        panel.background=element_rect(fill="white"),
        aspect.ratio=0.2,
        plot.margin=unit(rep(0.1,4), "cm")) +
        scale_colour_manual(name="Score", values=c("Program Average" = "black",
        "Your Average" = "black"), guide = "legend") +
        guides(colour = guide_legend(override.aes = list(linetype=c(0,0)
        , shape=c(19, 15)))) +
        coord_flip()
        
        
        filename <- paste("DomainPlotTest", ".pdf", sep="")
        
        ggsave(file = filename, width=10, height=3)
        
        # Take entry with 5 lowest scores for first observation.
        score.id <- merge(dlf[which(dlf$id==id & dlf$oa.order == 1), ], comb.avg,
					   by=c("domain", "question"))
                       score.id <- arrange(score.id, score, -popmean)
                       score.id <- score.id[1:5, ]
                       score.avg.id <- combined.data[which(combined.data$id==id),]
                       score.avg.id$pre <- score.avg.id$score
                       score.avg.id <- remove.vars(score.avg.id, c("score", "score.fi"))
                       score.id <- merge(score.id, score.avg.id, by=c("id","domain", "question"))
                       
                       # Attempt to recreate the second graph
                       ggplot(score.id) +
                       geom_rect(aes(xmin=(1:5 - 0.5),
                       xmax=(1:5 + 0.5),
                       ymin=min,
                       ymax=pop25pt),
                       alpha=1/3,
                       linetype="blank",
                       fill="red") +
                       geom_rect(aes(xmin=(1:5 - 0.5),
                       xmax=(1:5 + 0.5),
                       ymin=pop25pt,
                       ymax=pop75pt),
                       alpha=1/3,
                       linetype="blank",
                       fill="yellow") +
                       geom_rect(aes(xmin=(1:5 - 0.5),
                       xmax=(1:5 + 0.5),
                       ymin=pop75pt,
                       ymax=max),
                       alpha=1/3,
                       linetype="blank",
                       fill="green") +
                       geom_point(aes(x = 1:5, y=score, color="Current"), size=3) +
                       geom_segment(aes(x=1:5, y=pre, xend=1:5, yend=score, color="Your Average")) +
                       scale_y_continuous(limit = c(0, 5), breaks=(0:5), expand=c(0,0))  +
                       scale_x_continuous(limit = c(0.5, 5.5), breaks=(1:6 - 0.5), expand=c(0,0),
                       labels = c("", score.id$qid)) +
                       xlab("") + ylab("") +
                       theme(axis.ticks = element_blank(),
                       axis.text.y = element_text(size=14),
                       panel.grid.minor.x = element_blank(),
                       panel.grid.minor.y = element_blank(),
                       axis.text.x = element_text(size=16),
                       legend.text = element_text(size=16),
                       legend.title = element_text(size=16),
                       panel.grid.major=element_line(color="gray"),
                       panel.background=element_rect(fill="white"),
                       aspect.ratio=0.2,
                       plot.margin=unit(rep(0.1,4), "cm")) +
                       scale_colour_manual(name="Score",
                       values=c("Current"="black",
                       "Your Average"="black"), guide='legend') +
                       guides(colour = guide_legend(override.aes = list(linetype=c(0,1)
                       , shape=c(16, NA)))) +
                       coord_flip()
                       filename <- paste("FocusAreaPlotTest", ".pdf", sep="")
                       
                       ggsave(file = filename, width=10.5, height=3)
                       
                       # attempt to recreate the third plot
                       
                       id.temp <- id
                       score.id <- arrange(filter(combined.data, combined.data$id==id.temp), -abs(fi.score - score))[4:8, ]
                       score.id <- merge(score.id, comb.avg, by=c("domain", "question"))
                       
                       ggplot(score.id) +
                       geom_rect(aes(xmin=(1:5 - 0.5),
                       xmax=(1:5 + 0.5),
                       ymin=min,
                       ymax=pop25pt),
                       alpha=1/3,
                       linetype="blank",
                       fill="red") +
                       geom_rect(aes(xmin=(1:5 - 0.5),
                       xmax=(1:5 + 0.5),
                       ymin=pop25pt,
                       ymax=pop75pt),
                       alpha=1/3,
                       linetype="blank",
                       fill="yellow") +
                       geom_rect(aes(xmin=(1:5 - 0.5),
                       xmax=(1:5 + 0.5),
                       ymin=pop75pt,
                       ymax=max),
                       alpha=1/3,
                       linetype="blank",
                       fill="green") +
                       geom_segment(aes(x=1:5, y=fi.score, xend=1:5, yend=score)) +
                       geom_point(aes(x = 1:5, y=score, color="Mentor Teacher"), size=3) +
                       geom_point(aes(x = 1:5, y=fi.score, color="Field Instructor"),
                       shape = 15, size=3) +
                       scale_y_continuous(limit = c(0, 5), breaks=(0:5), expand=c(0,0))  +
                       scale_x_continuous(limit = c(0.5, 5.5), breaks=(1:6 - 0.5),
                       labels = c("", score.id$qid), expand=c(0,0)) +
                       xlab("") + ylab("") +
                       theme(axis.ticks = element_blank(),
                       axis.text.y = element_text(size=14),
                       axis.text.x = element_text(size=16),
                       legend.text = element_text(size=16),
                       legend.title = element_text(size=16),
                       panel.grid.minor.x = element_blank(),
                       panel.grid.minor.y = element_blank(),
                       panel.grid.major=element_line(color="gray"),
                       panel.background=element_rect(fill="white"),
                       aspect.ratio=0.2,
                       plot.margin=unit(rep(0.1,4), "cm")) +
                       coord_flip() +
                       scale_colour_manual(name="Rater", values=c("Field Instructor" = "black",
                       "Mentor Teacher" = "black")) +
                       guides(colour = guide_legend(override.aes = list(linetype=c(0,0)
                       , shape=c(19, 15))))
                       
                       ggsave(file = "DiscussionAreaPlotTest.pdf", width=10.5, height=3)
                       
    }
    
    #################################################
    # Applying the function.
    #################################################
    
    # Testing the first case
    creategraphs(1)
    # knit2pdf("TestReport.Rnw", output = "TestReport1.tex")
    
    # Creating the output table with names and document information
    output <- dlf[which(dlf$type.order==1), ]
    mt.names <- output[which(output$type==1),]
    mt.names <- remove.vars(mt.names, c("row.names", "question", "score", "oa.order", "type", "type.order", "domain", "attribute_2", "attribute_4", "attribute_5"))
    rownames(mt.names) <- NULL
    mt.names <- unique(mt.names)
    mt.names$mentteachname <- paste(mt.names$firstname, mt.names$lastname, sep = " ")
    mt.names <- rename.vars(mt.names, "email", "mentteachemail")
    mt.names <- remove.vars(mt.names, c("firstname", "lastname"))
    
    
    
    fi.names <- output[which(output$type==2),]
    fi.names <- remove.vars(fi.names, c("row.names", "question", "score", "oa.order", "type", "type.order", "domain", "attribute_2", "attribute_4", "attribute_5"))
    rownames(fi.names) <- NULL
    fi.names <- unique(fi.names)
    fi.names$fieldinstname <- paste(fi.names$firstname, fi.names$lastname, sep = " ")
    fi.names <- rename.vars(fi.names, "email", "fieldinstemail")
    fi.names <- remove.vars(fi.names, c("firstname", "lastname"))
    
    output <- remove.vars(output, c("row.names", "question", "score", "oa.order", "type", "type.order", "domain", "firstname", "lastname", "email"))
    output <- unique(output)
    rownames(output) <- NULL
    
    output$studteachname <- paste(output$attribute_2, output$attribute_4, sep = " ")
    output <- rename.vars(output, "attribute_5", "studteachemail")
    output <- remove.vars(output, c("attribute_2", "attribute_4"))
    output <- merge(output, fi.names, by = "id")
    output <- merge(output, mt.names, by = "id")
    output$filename <- ""
    output$filetime <- ""
    # Creating the reports using knitr
    setwd("PDFs")
    for(i in 1:max(data$id)) {
        creategraphs(i)
        names <- output[which(output$id==i), ]
        fi.myavg <- aggregate(x = fi.data[which(fi.data$id==i), ], by = list(fi.data[which(fi.data$id==i), ]$domain), FUN = "mean")
        mt.myavg <- aggregate(x = mt.data[which(mt.data$id==i), ], by = list(mt.data[which(mt.data$id==i), ]$domain), FUN = "mean")
        myavg <- domain.avg[which(domain.avg$id==i), ]
        time <- Sys.time()
        file.name <- paste("TestReport", i, gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".tex", sep="")
        knit2pdf("TestReport.Rnw", file.name)
        file.aux <- paste("TestReport", i, gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".aux", sep="")
        file.out <- paste("TestReport", i, gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".out", sep="")
        file.xwm <- paste("TestReport", i, gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".xwm", sep="")
        file.log <- paste("TestReport", i, gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".log", sep="")
        file.pdf <- paste("TestReport", i, gsub(" ", "", names$studteachname, fixed = TRUE), gsub(" ", "", time, fixed = TRUE), ".pdf", sep="")
        output[i,]$filename <- file.pdf
        output[i,]$filetime <- time
        file.remove(file.name, file.aux, file.out, file.xwm, file.log)
    }
    
    # Outputing file names, names, and email information
    #output$filename <- gsub(":", "/", output$filename, fixed = TRUE)
    # add an indicator for sending out, rbinom, half?
    # adding in the variables for focus areas (1 for domain.question, 1 for score) and discussion areas (each score and question, 3 vars)
    # deleting the tex files as you go?
    setwd("~")
    write.table(output, "Data/output.csv", sep = ",", row.names = F)

}
if( sum(raw$new) == 0 ){
    setwd("~")
    output = as.data.frame(matrix(c("NULL","NULL","NULL","NULL"),2,2),stringsAsFactors=FALSE)
    write.table(output, "Data/output.csv", sep = ",", row.names = F)
}



