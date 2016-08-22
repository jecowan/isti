
install.packages("devtools",repos="https://cran.fhcrc.org/")
install.packages("knitr",repos="https://cran.fhcrc.org/")
library("devtools")
library("knitr")

install_github("andrewheiss/limer")

library(limer)
library(curl)

#change the next options (website, user, password)
options(lime_api = 'http://isti.limequery.com/index.php/admin/remotecontrol')
options(lime_username = 'nick')
options(lime_password = 'uvPKqt8dQv6C')

# first get a session access key
get_session_key()

data<- get_responses(iSurveyID= 848746, sDocumentType="csv",sResponseType='short',sCompletionStatus="complete")

write.csv(data,file="LimeSurveyResults.csv",row.names = F)


test = function(x,y){
  ret_string = "{"
  for(i in 1:length(x))
    if(i == 1)
      ret_string = paste(ret_string,"'",x[i],"'",":","'",y[i],"'",sep="")
    else
      ret_string = paste(ret_string,",","'",x[i],"'",":","'",y[i],"'",sep="")
  ret_string = paste(ret_string,"}",sep="")
  return(ret_string)
}

test(variable.names(data),data[1,])

call_limer("add_response",list(iSurveyID = 848746,aResponseData = test(variable.names(data),data[1,])))
