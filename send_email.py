##########################################
# send_email.py - File which controls the 
# automated transfer of data/pdf output
# to emails and the s3 server
#########################################


#############################
# Necessary Package Importing
#############################
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from email.utils import COMMASPACE, formatdate
#from apscheduler.schedulers.background import BackgroundScheduler
import subprocess
import csv
import pandas as pd
import numpy as np
import os


######################
# Function Definitions
######################

# This function defines an email sending mechanism
def send_mail(fromaddr,frompass,toaddr,subj,bod,fname,fpath):

	#This creates an email message object
	msg = MIMEMultipart()
	#Fills in email message parts
	msg['From'] = fromaddr
	msg['To'] = "m.lee.wolff@gmail.com"
	msg['Subject'] = subj
	#Attaches body to message
	body = bod
	msg.attach(MIMEText(body,'plain'))
	#Attaches file to message
	filename = fname
	attach_path = "PDFs/" + fpath
	attachment = open(attach_path,"rb")

	part = MIMEBase('application','octet-stream')
	part.set_payload((attachment).read())
	encoders.encode_base64(part)
	part.add_header('Content-Disposition',"attachment; filename = %s" % filename)

	msg.attach(part)
	#Sends out file 
	server = smtplib.SMTP('smtp.gmail.com',587)
	server.starttls()
	server.login(fromaddr,frompass)
	text = msg.as_string()
	server.sendmail(fromaddr,"m.lee.wolff@gmail.com",text)
	server.quit()

#This function transfers data to the AWS S3 server for cloud storage
def s3_transfer(Rdf,program_name):
	mail_data = pd.read_csv(Rdf)

	if mail_data.shape != (2,2):
		name_series = mail_data.iloc[:,2].unique()
		
		for name in name_series:
			current_name = name.replace(" ","")
			command = 's3cmd sync --include PDFs/*%s*.pdf "s3://istidata/%s/%s/"' % (current_name,program_name,current_name)
			os.system(command)
		command2 = 's3cmd sync --include Data/output.csv "s3://istidata/%s/"' % program_name
		os.system(command2)
		os.system('rm ~/PDFs/*.pdf')

#This code processes a single line from the R dataframe and designates email lists
def mail_list(Rdf,fromaddr,frompass):
	count = 0
	mail_data = pd.read_csv(Rdf)
	if mail_data.shape != (2,2):
		#Assume the following order: (idm,StEmail, StName, FIemail, FIname, Memail,Mname,Filename)
		rownum = mail_data.count()[1]
		print(rownum)
		for i in range(0,rownum):
			subj_st = 'student teacher subject'
			subj_ment = 'mentor subject %s' %mail_data.iloc[i,2]
			subj_fi = 'field instructor subject %s' % mail_data.iloc[i,2]

			bod_st = 'student teacher body %s,%s,%s' % (mail_data.iloc[i,2],mail_data.iloc[i,4],mail_data.iloc[i,6])
			bod_ment = 'mentor teacher body %s,%s,%s' % (mail_data.iloc[i,2],mail_data.iloc[i,4],mail_data.iloc[i,6])
			bod_fi = 'field instructor body %s,%s,%s' % (mail_data.iloc[i,2],mail_data.iloc[i,4],mail_data.iloc[i,6])

			send_mail(fromaddr,frompass,mail_data.iloc[i,1],subj_st,bod_st,mail_data.iloc[i,7],mail_data.iloc[i,7])
			print('Email to Student Teacher Successfully Sent...')
			send_mail(fromaddr,frompass,mail_data.iloc[i,3],subj_fi,bod_fi,mail_data.iloc[i,7],mail_data.iloc[i,7])
			print('Email to Mentor Teacher Successfully Sent...')
			send_mail(fromaddr,frompass,mail_data.iloc[i,5],subj_ment,bod_ment,mail_data.iloc[i,7],mail_data.iloc[i,7])
			print('Email to Field Instructor Successfully Sent...')
	if mail_data.shape == (2,2):
		print('No new email data to be sent.')


#########################################
# Old Functions - These functions are 
# not used in the current implimentation
#########################################

#Instead of a report back email let's try an "add to dropbox" function
def report_back_email(fromaddr,frompass,toaddr,pdfsentnum,sentdataframe):
	#This creates an email message object
	msg = MIMEMultipart()
	#Fills in email message parts
	msg['From'] = fromaddr
	msg['To'] = toaddr
	msg['Subject'] = "Daily Survey Report Status"
	#Attaches body to message
	body = "The survey is currently running, and has successfully sent %s files today." %pdfsentnum
	msg.attach(MIMEText(body,'plain'))

	#Sends out file 
	server = smtplib.SMTP('smtp.gmail.com',587)
	server.starttls()
	server.login(fromaddr,frompass)
	text = msg.as_string()
	server.sendmail(fromaddr,toaddr,text)
	server.quit()	

def process_mail_list(fromaddr,frompass,toaddr,Rdf):
	count = mail_list(Rdf,fromaddr,frompass)
	report_back_email()

#Run the R API File through python
#THIS FUNCTION TAKES IN THE OLD DATA (PREVIOUS ITERATION)
#AND THE NEW DATA (CURRENT ITERATION) AND CREATES A NEW FILE
#(TO BE NAMED) WHICH LABELS THOSE ENTRIES IN THE CURRENT ITERATION
#NOT IN THE PREVIOUS ITERATION
def tag_new_entries(oldfile,newfile,pers_info):
	#read in the old data and the new data and drop 'newentry' tag
	old_file = pd.read_csv(oldfile,sep='\t')
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
	new_output = pd.concat([old_file,new_entries])
	right = pd.read_csv(pers_info)
	result = pd.merge(new_output,right,on='token')
	result.to_csv('Working_Results.csv',sep=',',index=False) #edit the name here


#Evaluation Summary Statistics function
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
                

def construct_email(id):
	#Here we can put together the pieces of the email. Certain things

	recips = []
	bodyinfo = []
	bodies = []

	#Find recipients
	with open('master_recipients.csv') as csvfile:
		recipchecker = csv.reader(csvfile,delimiter=',',quotechar='|')
		for row in recipchecker:
			rowstore = row
			#Check for matching ID
			if rowstore[0] == id:
				#Update once it's determined what column the recipient email is in
				recips.append(rowstore[1])
				bodyinfo.append([rowstore[2],rowstore[3]])
    
	#Create email bodies based on the information harvested
	#Test version, can be easily expanded for more complex bodies
	for i in range(0,len(bodyinfo)):
		bodies.append('Attached is the most recent student teaching report for '+ bodyinfo[i][0]+' '+bodyinfo[i][1]+'.')
    
	email_info = [recips,bodies]

	#return list type
	return email_info


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

# #Set up process to run in the background, checking in every minute
# @sched.scheduled_job('interval', seconds=60)
# def run_proc():
# 	#NOTE: gmail will not allow this unless the "Allow less secure apps" option
# 	#is turned on, which also makes the account itself more vulnerable
# 	#so do not use a highly visible account.
# 	#Also won't work with duplicate verification, etc.
# 	fromaddr = "tpicker224@gmail.com"
# 	frompass = "1w1sh4@n@p1"
# 	subj = "Student Teaching Progress Report"
# 	fname = "Evaluation Data"
# 	#Testing input:
# 	fpath = "evaldata.txt"
    
# 	newentry = find_new_data()
# 	if newentry != 'none':
# 		#Create PDF, get back filename
# 		#Run Chris' R file to generate PDF
# 		#OUT FOR TESTING        
# 		#fpath = subprocess.check_output(['Rscript','path/script.R']+newentry, shell=False)
# 		#Pass through ID
# 		email_info = construct_email(newentry[1])
# 		#Send each email
# 		for i in range(0,len(email_info[0])):
# 			send_mail(fromaddr,frompass,email_info[0][i],subj,email_info[1][i],fname,fpath)
# 		#Mark the entry completed
# 		flag_finished(newentry)


##################
# Code to be Run
##################

def main():
	mail_list('Data/output.csv','m.lee.wolff@gmail.com','')
	s3_transfer('Data/output.csv','Florida Atlantic University')
if __name__ == "__main__":
	main()

