
#########################################
# main.py - Main file that drives the
# other programs. Look here for a general
# overview of the processes that run
#########################################



#############################
# Necessary Package Importing
#############################
import server_setup
import data_processor
import time
import os
import time
import paramiko
from scp import SCPClient
import fileinput


######################
# Function Definitions
######################

#This function connects your personal computer to the cloud server using Paramiko
def server_connect(address,key_address):
	chmod_command = 'chmod 400 "%s"' % key_address
	os.system(chmod_command)

	print("Creating Paramiko Connection...")
	global ssh
	ssh = paramiko.SSHClient()
	ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
	ssh.connect(address,
		             username='ubuntu',
		             key_filename=key_address)
	print("Connection Successful")

#This function allows for a convenient way to interact with the cloud
def run_command(command_string):
	(stdin,stdout,stderr) = ssh.exec_command(command_string,get_pty=True)
	for line in stdout.readlines():
		print(line)
	for line in stderr.readlines():
		print(line)

#This function allows for the re-downloading and reporting of files
def report():
	run_command('sudo python server_main.py')

#################
# Code to be Run
#################

#1. Execute the server setup
server_setup.execute("ec2-54-218-127-128.us-west-2.compute.amazonaws.com",'/Users/Mwolff/Desktop/istiaws2.pem','AKIAJHDXHPKRKQYJ3P3A','l5GTGu3l4NcyoSgPG9MbF18FTtxyF3b63WvJG4VK')
server_connect("ec2-54-218-127-128.us-west-2.compute.amazonaws.com",'/Users/Mwolff/Desktop/istiaws2.pem')

#2. Run main server commands
run_command('sudo python server_main.py')


#Possibly need crontab to work

##########################################
# Code to be initialized. These functions 
# will be put in for incremental processing 
# of survey data.
##########################################


#Schedule Executions
# schedule.every().day.at("10:00").do(report)
# schedule.every().day.at("15:00").do(report)
# schedule.every().day.at("12:00").do(report)

# while True:
# 	schedule.run_pending()
# 	time.sleep(1)