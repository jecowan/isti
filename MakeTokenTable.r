
##########################################################
# MakeTokenTable.r
# 2016.05.26
# Make fake survey token data for practice.
##########################################################
library(dplyr)
set.seed(12345)

token.table <- data.frame(
  id=1:100,
  firstname="Mentor",
  lastname="Teacher",
  email="studentteachinginitiative@gmail.com",
  emailstatus="OK",
  token=1:100,
  language="en",
  validfrom="",
  validuntil="",
  invited="N",
  reminded="N",
  remindercount=0,
  completed="N",
  usesleft=1,
  attribute_1="Mentor Teacher",
  attribute_2="Dan Goldhaber",
  attribute_3="0001"
)

write.table(token.table, 
            file="tokens.csv", 
            sep=",", 
            row.names=FALSE,
            col.names=TRUE)
