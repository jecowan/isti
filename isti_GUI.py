#simple GUI to start server and add files
#!/usr/bin/env python

from Tkinter import *
from scp import SCPClient
import paramiko
import os
import fileinput
import server_setup
import commands
import re
import os.path

#Retrieval Functions
def initialize_server():
	#Get Security Group
	groupName =  ''.join(random.choice(string.ascii_uppercase) for _ in range(7))
	securityGroupString = commands.getstatusoutput('aws ec2 create-security-group --group-name ' + groupName + ' --description "security group for development environment in EC2"')[1]
	m = re.search('\"GroupId\": \"(.+?)\"',securityGroupString)
	if m:
		print repr(m.group(1))
		print type(m.group(1))
		securityGroup = str(m.group(1))
	else:
		print("Error: Could not locate Security Group Output.")

	#Authorize Security Group
	print commands.getstatusoutput('aws ec2 authorize-security-group-ingress --group-name ' + groupName + ' --protocol tcp --port 22 --cidr 0.0.0.0/0')
	print commands.getstatusoutput("aws ec2 create-key-pair --key-name istiaws3 --query 'KeyMaterial' --output text > istiaws3.pem")
	print commands.getstatusoutput("chmod 400 istiaws3.pem")

	#Initialize Instance
	ec2Instance = commands.getstatusoutput("aws ec2 run-instances --image-id ami-29ebb519 --security-group-ids " + securityGroup +  " --count 1 --instance-type t2.micro --key-name istiaws3 --query 'Instances[0].InstanceId'")[1]

	#Get IP
	ipAddress = commands.getstatusoutput("aws ec2 describe-instances --instance-ids " + ec2Instance + " --query 'Reservations[0].Instances[0].PublicIpAddress'")


def run_command(command_string):
	(stdin,stdout,stderr) = ssh.exec_command(command_string,get_pty=True)
	for line in stdout.readlines():
		print(line)
	for line in stderr.readlines():
		print(line)


def submit_school_info(schfolder):
	#Establish connection to the server
	homedir = os.path.dirname(os.path.abspath(__file__))
	keypath = '%s/istiaws2.pem' % homedir

	chmod_command = 'chmod 400 "%s"' % keypath
	os.system(chmod_command)
	global ssh
	ssh = paramiko.SSHClient()
	ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
	ssh.connect("ec2-54-213-159-110.us-west-2.compute.amazonaws.com",
	             username='ubuntu',
	             key_filename=keypath)
	print("Connection Successful")

	#Load in the School Specific Files

	run_command("mkdir -p %s" % schfolder)
	local_schfolder = os.path.join(os.path.dirname(os.path.abspath(__file__)),'..',schfolder)
	for filename in os.listdir(local_schfolder):
		with SCPClient(ssh.get_transport()) as scp:
			scp.put("%s/%s" % (local_schfolder,filename), "~/%s/%s" % (schfolder,filename) )
		if filename.startswith("server_main"):
			servmain_file = filename
	run_command("sudo python ~/%s/%s" % (schfolder,servmain_file))

	print("Adding Scheduler...")
	run_command('(crontab -l ; echo "TZ=America/New_York") | sort - | uniq - | crontab -')
	run_command('(crontab -l ; echo "0 13 * * * sudo /usr/bin/python ~/%s/%s") | sort - | uniq - | crontab -' % (schfolder,servmain_file))
	run_command('(crontab -l ; echo "0 18 * * * sudo /usr/bin/python ~/%s/%s") | sort - | uniq - | crontab -' % (schfolder,servmain_file))
	run_command('(crontab -l ; echo "0 3 * * * sudo /usr/bin/python ~/%s/%s") | sort - | uniq - | crontab -' % (schfolder,servmain_file))
	print("Complete.")

def remove_scheduler():
	homedir = os.path.dirname(os.path.abspath(__file__))
	keypath = '%s/istiaws2.pem' % homedir

	chmod_command = 'chmod 400 "%s"' % keypath
	os.system(chmod_command)
	global ssh
	ssh = paramiko.SSHClient()
	ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
	ssh.connect("ec2-54-213-159-110.us-west-2.compute.amazonaws.com",
	             username='ubuntu',
	             key_filename=keypath)
	print("Connection Successful")

	print("Removing all Schedules...")
	run_command('crontab -r')
	print("Schedules Removed.")

def browsecsv():
    from tkFileDialog import askopenfilename
    import send_email

    Tk().withdraw() 
    filename = askopenfilename()
    dirname = os.path.dirname(filename)
    os.chdir(dirname)
    send_email.mail_list(filename,'studentteachinginitiative@gmail.com','EmiGerda2016')

def create_GUI():
	#create window
	root = Tk()

	#Modify root window
	root.title("ISTI Automator")
	root.geometry("450x500")

	app = Frame(root)
	app.grid()

	#Add Labels
	label = Label(app, text = "Feedback Email Automator for ISTI",font=("Courier",16))
	label.grid()

	#Add Message for the user
	instructions = Message(app,text = "This is the main menu for starting the ISTI Email Automater.\n\n If this is the first time the app is being used, please initialize the automator with the button 'Initialize Server'. This should not be done more than once. \n\nTo add an additional school, please fill out the field below with the directory name containing the requisite school files:\n\n - CreateReport_*.R\n - Define*Domains.R\n - LimeSurvey_API*.R\n - server_main_*.py\n - tokens_*.csv\n\n\n")
	instructions.grid()

	#Add Buttons
	button1 = Button(app,text="Initialize server",command =server_setup.execute)
	button1.grid()

	#Add whitespace
	
	#School File Folder Name
	fldrname = Label(app,text="School Folder Name")
	fldrname.grid(row=5)
	fldrname_entry = Entry(app)
	fldrname_entry.grid(row=6,column=0)


	#Add School Button
	addsch = Button(app,text="Add School",command = lambda: submit_school_info(fldrname_entry.get()))
	addsch.grid(row=7)


	#Add Remove Schedules Button
	rmvsc = Button(app,text="Remove All Scheduled Emails",command = remove_scheduler)
	rmvsc.grid(row=8)

	#Add Send Email Button
	bbutton = Button(app,text="Send Emails",command= lambda: browsecsv())
	bbutton.grid(row=9)


	#Start the GUI
	root.mainloop()
		

def main():
	create_GUI()

if __name__ == "__main__":
	main()