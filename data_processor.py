##################################################
# data_processor.py - This file formats the
# downloaded data in preperation for PDF creation
# using the R scrip CreateReport.R
##################################################


#############################
# Necessary Package Importing
#############################

import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from email.utils import COMMASPACE, formatdate
import subprocess
import csv
import pandas as pd
import numpy as np


######################
# Function Definitions
######################


#This function takes in an old data file (to be the previous iteration)
#and the new data downloaded from limesurvey, and creates a file
#which labels the "new" entries.
def merge_data(oldfile,newfile,pers_info):
	#read in the old data and the new data and drop 'newentry' tag
	old_file = pd.read_csv(oldfile,sep=',')
	if 'newflag' in old_file.columns:
		old_file.drop('newflag', axis=1, inplace=True)
	new_file = pd.read_csv(newfile)
	if 'newflag' in new_file.columns:
		new_file.drop('newflag', axis=1, inplace=True)
	#concatenate the data
	df = pd.concat([old_file,new_file])
	df = df.reset_index(drop=True)
	#group by columns
	df_gpby = df.groupby(list(df.columns))
	#get index of unique records in terms of the columns
	idx = [x[0] for x in df_gpby.groups.values() if len(x) == 1]
	#filter
	new_entries = df.reindex(idx)
	new_entries.insert(0,'newflag',1)
	old_file.insert(0,'newflag',0)
	print(old_file)
	print(new_file)
	new_output = pd.concat([old_file,new_entries])
	right = pd.read_csv(pers_info)
	result = pd.merge(new_output,right,on='token')
	result.to_csv('Working_Results.csv',sep=',',index=False) #edit the name here
	new_file.to_csv('LimeSurveyResults_old.csv',sep=',',index=False)



##########################################
# Old Functions - These functions are not
# used in the current implimentation
##########################################

#This function generates overall summary statistics
def eval_summary(eval_data):
	df = pd.read_csv(eval_data,sep='\t')
	df2 = df.describe()
	eval_summary = df2.iloc[:,3:].transpose()
	print(eval_summary)
	eval_summary.to_csv('eval_summary.csv',sep=',',index=False)



def find_new_data(filename):
	#Read CSV file and check for new entry flag
	#Note that this method will process new entries last-in-first-out
	newentry = 'none'
	with open(filename) as csvfile:
		newchecker = csv.reader(csvfile,delimiter=',',quotechar='|')
		for row in newchecker:
			rowstore = row
		#Check for newflag
			if rowstore[0] == '1':
				newentry = rowstore
    
	#Send back info with new entry
	return newentry
                 

def flag_finished(newentry):
	#Update CSV file to reflect that the entry has been sent out
	#Prepare replacement entry for what we just ran
	updateentry = list(newentry)
	updateentry[0] = '0'
    
	#Read in old data into a list
	f = open('results-survey283516.csv')
	olddata = csv.reader(f)
	lines = [l for l in olddata]
	f.close()
	#Replace the old entry
	for i in range(0,len(lines)):
		if lines[i] == newentry:
			lines[i] = updateentry
    
	#Write back data   
	#THIS SHOULD REWRITE THE ORIGINAL FILE
	#HOWEVER, CURRENTLY SET TO CREATE A NEW FILE DUE TO WINDOWS 
	#PERMISSIONS ISSUES AND FOR TESTING. REWRITE WHEN PORTING TO AWS.
	f = open('florp.csv','w')
	replacedata = csv.writer(f,delimiter=',',lineterminator='\n')
	replacedata.writerows(lines)
	f.close()
    
	#Send back info with new entry
	return newentry
	


#################
# Code to be Run
#################

def main():
	#Pull down data from limesurvey to R
	#run_R_API()
	merge_data("LimeSurveyResults_old.csv","LimeSurveyResults.csv","tokens.csv")

	#Start background process run_proc()
	#sched.start()
	

if __name__ == "__main__":
	main()

