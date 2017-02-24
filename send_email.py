# -*- coding: utf-8 -*-


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
import time


######################
# Function Definitions
######################

# This function defines an email sending mechanism
def send_mail(fromaddr,frompass,toaddr1,toaddr2,toaddr3,subj,bod,fname,fname2,fpath):

	#This creates an email message object
	msg = MIMEMultipart()
	#Fills in email message parts
	toaddr = toaddr1 + ', ' + toaddr2 + ', ' + toaddr3
	msg['From'] = fromaddr
	msg['To'] = toaddr
	msg['Subject'] = subj
	#Attaches body to message
	body = bod
	msg.attach(MIMEText(body,'html'))
	#Attaches introduction file to message
	filename2 = fname2
	attach_path2 = fname2
	attachment2 = open(attach_path2, "rb")
	part2 = MIMEBase('application','octet-stream')
	part2.set_payload((attachment2).read())
	encoders.encode_base64(part2)
	part2.add_header('Content-Disposition',"attachment; filename = %s" % filename2)

	msg.attach(part2)

	#Attaches personal file to message
	filename = fname
	attach_path = fpath
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
	server.sendmail(fromaddr,toaddr,text)
	server.quit()

#This function transfers data to the AWS S3 server for cloud storage
def s3_transfer(Rdf,program_name):
	mail_data = pd.read_csv(Rdf)

	if mail_data.shape != (2,2):
		name_series = mail_data['studteachname'].unique()
		
		for name in name_series:
			current_name = name.replace(" ","")
			os.system('mkdir /home/ubuntu/PDFs/%s' % current_name)
			os.system('mv /home/ubuntu/PDFs/*%s*.pdf /home/ubuntu/PDFs/%s/' % (current_name,current_name))
			command = 's3cmd sync /home/ubuntu/PDFs/%s "s3://cedristi/%s/"' % (current_name,program_name)
			os.system(command)
			os.system('sudo rm -rf /home/ubuntu/PDFs/%s' % current_name)
		timestr = time.strftime("%d-%m-%y_%H:%M:%S")
		os.system('mv Data/output.csv /home/ubuntu/Data/output%s.csv' % timestr)
		command2 = 's3cmd sync /home/ubuntu/Data "s3://cedristi/%s/"' % program_name
		os.system(command2)

#This code processes a single line from the R dataframe and designates email lists
def mail_list(Rdf,fromaddr,frompass):
	count = 0
	mail_data = pd.read_csv(Rdf)
	
	mail_data = mail_data[mail_data.send == 1]
	#Assume the following order: (idm,StEmail, StName, FIemail, FIname, Memail,Mname,Filename)
	rownum = mail_data.count()[1]
	print(os.getcwd())
	print(rownum)
	for i in range(0,rownum):
		subj = 'Performance Evaluation Report'
		bod = '<div dir="ltr"><div dir="ltr"><span style="font-size:12.800000190734863px">Hello,</span><div style="font-size:12.800000190734863px"><br></div><div style="font-size:12.800000190734863px">Attached are an&nbsp;<b>Introduction to the Performance Evaluation Report&nbsp;</b>and your personalized, auto-generated&nbsp;<b>Performance Evaluation Report</b>&nbsp;based on your most recent scores by your assessors.</div><div style="font-size:12.800000190734863px"><br></div><div style="font-size:12.800000190734863px"><i>What is the Performance Evaluation Report?&nbsp;</i><font color="#000000">The Performance Evaluation Report is an auto-generated summary of student teaching performance using the school rubric scores from field instructors and mentor teachers to determine overall performance, strengths, weaknesses, and areas of disagreement. The report is generated every time a new evaluation is submitted and is sent to the student teacher, field instructor, and mentor teacher. For more information&nbsp;please see the attached&nbsp;</font><b>Introduction to the Performance Evaluation Report</b><font color="#000000">.</font></div><div style="font-size:12.800000190734863px"><em><br></em></div><div style="font-size:12.800000190734863px"><em>What is this initiative about?</em>&nbsp;The Improving Student Teaching Initiative strives to learn more about the conditions and consequences of student teaching—with a particular focus on the implications of student teaching placements and feedback from mentor teachers and field instructors.</div><div style="font-size:12.800000190734863px">&nbsp;&nbsp; &nbsp; &nbsp;<br></div><div style="font-size:12.800000190734863px"><em>Who will receive this report?</em>&nbsp;Your information will only be shared with your assessors and you.&nbsp;<span class="m_-6512810684836372254m_6329590361113212433m_5395816187459599gmail-il">ISTI</span>&nbsp;will&nbsp;will never share any information linked with your name or other identifying information in any report or presentation to anyone else.<br></div><div style="font-size:12.800000190734863px"><br></div><div style="font-size:12.800000190734863px"><em>Questions about the initiative?</em>&nbsp;&nbsp;If you have any questions about the report or the initiative itself, please contact James Cowan or Christopher Tien at <a href="mailto:studentteachinginitiative@gmail.com" target="_blank">studentteachinginitiative@gmai<wbr>l.com</a> or&nbsp;<a href="tel:(844)%20384-4092" value="+18443844092" target="_blank">1 (844)&nbsp;384-4092</a>.</div><div style="font-size:12.800000190734863px"><br></div><div style="font-size:12.800000190734863px">Sincerely,<br></div><div style="font-size:12.800000190734863px"><p>Improving Student Teaching Initiative (<a href="mailto:studentteachinginitiative@gmail.com" target="_blank">studentteachinginitiative@gma<wbr>il.com</a>)</p></div></div><br></div>'

		send_mail(fromaddr,frompass,mail_data['studteachemail'].iloc[i],mail_data['mentteachemail'].iloc[i],mail_data['fieldinstemail'].iloc[i],subj,bod,mail_data['filename'].iloc[i],'IntroductionReport.pdf',mail_data['filename'].iloc[i])
		# print('Email to Student Teacher Successfully Sent...')
		# if pd.isnull(mail_data['mentteachemail'].iloc[i]) == False:
		# 	send_mail(fromaddr,frompass,mail_data['mentteachemail'].iloc[i],subj_ment,bod_ment,mail_data['filename'].iloc[i],'IntroductionReport.pdf',mail_data['filename'].iloc[i])
		# print('Email to Mentor Teacher Successfully Sent...')
		# if pd.isnull(mail_data['fieldinstemail'].iloc[i]) == False:
		# 	send_mail(fromaddr,frompass,mail_data['fieldinstemail'].iloc[i],subj_fi,bod_fi,mail_data['filename'].iloc[i],'IntroductionReport.pdf',mail_data['filename'].iloc[i])
		# print('Email to Field Instructor Successfully Sent...')

	print('All Emails Successfully Sent.')


##################
# Code to be Run
##################

def main():
	mail_list('~/Data/output.csv','m.lee.wolff@gmail.com','!')
if __name__ == "__main__":
	main()

