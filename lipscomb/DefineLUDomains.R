numq <- 20
numd <- 5
numd1q <- 2
numd2q <- 3
numd3q <- 8
numd4q <- 4
numd5q <- 3
nums <- 4

domain.code <- data.frame(domain = c(rep(1, numd1q), rep(2,numd2q), rep(3,numd3q), rep(4,numd4q),rep(5,numd5q)), question = 1:numq)

question.names <- data.frame(
  question = c(1:20), question_name =c(
    "Learning-Targets",
    "Formative Assessment",
    "High Expectations",
    "Demeanor",
    "Joy and Enthusiasm",
    "Standards-based lesson",
    "Engaging Set",
    "Closure",
    "Technology Integration",
    "Strategies",
    "Questioning",
    "Differentiation",
    "Content Knowledge",
    "Organization",
    "Pacing",
    "Techniques",
    "Climate",
    "Professional",
    "Compassion & Respect",
    "Appearance"))
domain.names <- data.frame(
  domain = c(1:5), 
  domain_name = c("Assessing",
                  "Confident and Passionate",
                  "Implementing",
                  "Managing",
                  "Relationships"))
sup.name <-"supervisor"
ment.name <- "mentor"
