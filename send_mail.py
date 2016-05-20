import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEBase import MIMEBase
from email import encoders
from email.utils import COMMASPACE, formatdate

# This function defines an email sending mechanism
def send_mail(fromaddr,frompass,toaddr,subj,bod,fname,fpath):

	#This creates an email message object
	msg = MIMEMultipart()
	#Fills in email message parts
	msg['From'] = fromaddr
	msg['To'] = toaddr
	msg['Subject'] = subj
	#Attaches body to message
	body = bod
	msg.attach(MIMEText(body,'plain'))
	#Attaches file to message
	filename = fname
	attachment = open(fpath,"rb")

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

def create_email_list():
	#Here we should create/input a data structure which
	#attaches each email with it's corresponding text (if unique)
	#and report.
	#It's important to only attach emails which have changed PDFs.
	

def construct_email():
	#Here we can put together the pieces of the email. Certain things
	#will probably stay constant - fromaddr, frompass, subj, (possibly body)

	#1. call create_email_list()

	#2. define constants
	fromaddr = ""
	frompass = ""

	subj = "Student Teaching Progress Report"
	bod = "Attched is your most recentstudent teaching progress report..."

	#return list type
	return email_info


def main():
	#THESE ARE TESTING INPUTS FOR send_mail()
    #fromaddr = "m.lee.wolff@gmail.com"
    #frompass = "**********"
    #toaddr = "m.lee.wolff@gmail.com, mlw32@uw.edu"
    #subj = "testing"
    #bod = "testing!!!!"
    #fname = "TEST.docx"
    #fpath = "/Users/Mwolff/Desktop/TEST.docx"
    
    #Cycle through emails. 
    for i in range(0,length(email_info[[]])):
		send_mail(fromaddr,frompass,toaddr,subj,bod,fname,fpath)

if __name__ == "__main__":
    main()