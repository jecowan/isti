########################################
# server_setup.py - File that initially
# sets up the AWS EC2 and S3 servers,
# installs packages, etc. This file
# should only need to be run once per
# instance.
########################################


#############################
# Necessary Package Importing
#############################
import os
import time
import paramiko
from scp import SCPClient
import fileinput


######################
# Function Definitions
######################

#This function facilitates running commands on the cloud
def run_command(command_string):
	(stdin,stdout,stderr) = ssh.exec_command(command_string,get_pty=True)
	for line in stdout.readlines():
		print(line)
	for line in stderr.readlines():
		print(line)

#This is the main function which installs all necessary packages and sets up the server

#Set permissions
def execute(dns_serv,keypath,s3accesskey1,s3accesskey2):
	#"/Users/Mwolff/Desktop/key1.pem"
	#'ec2-54-187-219-165.us-west-2.compute.amazonaws.com'
	chmod_command = 'chmod 400 "%s"' % keypath
	os.system(chmod_command)
	os.system("sed -i '' -e 's/access_key =/access_key =AKIAJHDXHPKRKQYJ3P3A/g' '/Users/Mwolff/Documents/cedr/isti/python/s3config.txt'")
	os.system("sed -i '' -e 's:secret_key =:secret_key =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:g' '/Users/Mwolff/Documents/cedr/isti/python/s3config.txt'")
	#Go into server	#will probably stay constant - fromaddr, frompass, subj, (possibly body)

	print("Creating Paramiko Connection...")
	global ssh
	ssh = paramiko.SSHClient()
	ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
	ssh.connect(dns_serv,
	             username='ubuntu',
	             key_filename=keypath)
	print("Connection Successful")

	#Load in necessary Files
	print("Loading Files...")
	scp = SCPClient(ssh.get_transport())
	scp.put("/Users/MWolff/Documents/cedr/isti/python/send_email.py","send_email.py")
	print("16.7%% Complete")
	scp.put("/Users/MWolff/Documents/cedr/isti/python/LimeSurveyResults_old.csv","LimeSurveyResults_old.csv")
	print("33.4%% Complete")
	scp.put("/Users/MWolff/Documents/cedr/isti/python/LimeSurveyAPI.R","LimeSurveyAPI.R")
	print("50%% Complete")
	scp.put("/Users/MWolff/Documents/cedr/isti/python/CreateReport.R","CreateReport.R")
	print("66.8%% Complete")
	scp.put("/Users/MWolff/Documents/cedr/isti/python/tokens_848746.csv","tokens.csv")
	print("83.5%% Complete")
	scp.put("/Users/MWolff/Documents/cedr/isti/python/TestReport.Rnw","TestReport.Rnw")
	print("100%% Complete")
	scp.put("/Users/MWolff/Documents/cedr/isti/python/s3config.txt",".s3cfg")
	scp.put("/Users/MWolff/Documents/cedr/isti/python/data_processor.py","data_processor.py")
	scp.put("/Users/MWolff/Documents/cedr/isti/python/server_main.py","server_main.py")
	scp.put("/Users/MWolff/Documents/cedr/isti/python/send_email.py","send_email.py")
	scp.put("/Users/MWolff/Documents/cedr/isti/python/DefineDomains.R","DefineDomains.R")


	# #install necessary packages
	print("Installing Pacakages...")
	run_command("sudo apt-get -y upgrade")
	run_command("sudo apt-get -y update")
	run_command("sudo apt-get -y install r-base-core")
	print("apt-get updated...")
	
	run_command('sudo apt-get -y install python-pip')
	print("pip installed...")
	
	run_command('sudo apt-get -y install python-dev')
	run_command("sudo aptitude -y install libcurl4-openssl-dev")
	run_command("sudo apt-get -y install libxml2-dev")
	print("helper functions installed...")
	
	run_command("sudo apt-get -y install python")
	print("Python installed...")
	
	run_command("sudo apt-get -y build-dep libcurl4-gnutls-dev")
	run_command("sudo apt-get -y install libcurl4-gnutls-dev")
	run_command("sudo apt-get install curl")
	run_command('curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"')
	run_command('sudo python get-pip.py')
	run_command('sudo pip install smtplib')
	run_command('sudo pip install email')
	run_command('sudo pip install csv')
	run_command('sudo apt-get -y install python-pandas')
	run_command('sudo pip install numpy')
	run_command('sudo pip install schedule')
	print("Python functions installed...")
	
	run_command('sudo apt-get -y install texlive-latex-base')
	print('PDF Latex installed...')
	
	run_command('sudo apt-get -y install openjdk-7-jdk')
	print('Java JDK installed...')
	
	print('Downloading R...')
	run_command('sudo wget https://cran.r-project.org/src/base/R-3/R-3.3.1.tar.gz')
	
	print('Unpacking...')
	run_command('tar xvzf R-3.3.1.tar.gz')
	run_command('ls')
	run_command('sudo apt-get -y install liblzma-dev')
	run_command('sudo apt-get -y install libreadline-dev')

	print('Installing...')
	run_command('cd R-3.3.1 ; ./configure --with-x=no')
	run_command('cd R-3.3.1; make')
	run_command('cd R-3.3.1 ; sudo make install')
	run_command('sudo apt-get -y install texlive-full')
	
	#Set up amazon s3
	run_command('sudo apt-get -y install s3cmd')

	#Create Directories
	run_command('sudo mkdir -p PDFs')
	run_command('sudo mkdir -p Data')

	run_command('sudo mv TestReport.Rnw PDFs/TestReport.Rnw')

	#Remove unessecary files
	print("Cleaning up...")
	run_command('rm -f *.tar.*')

	print("Adding Scheduler...")
	run_command('(crontab -l ; echo "TZ=America/New_York") | sort - | uniq - | crontab -')
	run_command('(crontab -l ; echo "0 13 * * * sudo /usr/bin/python ~/server_main.py") | sort - | uniq - | crontab -')
	run_command('(crontab -l ; echo "0 18 * * * sudo /usr/bin/python ~/server_main.py") | sort - | uniq - | crontab -')
	run_command('(crontab -l ; echo "0 3 * * * sudo /usr/bin/python ~/server_main.py") | sort - | uniq - | crontab -')



