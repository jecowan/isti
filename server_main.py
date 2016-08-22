####################################
# server_main.py - This is the main
# file to be run within the AWS EC2
# server
####################################


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
import os
import time
import fileinput
import data_processor
import schedule


#################
# Code to be Run
#################

def report():
	print("Downloading LimeSurvey Results...")
	os.system('sudo Rscript LimeSurveyAPI.R')

	print("Reformatting Downloaded Data...")
	os.system('sudo python data_processor.py')

	print("Creating PDF Documents...")
	os.system('sudo Rscript CreateReport.R')
	
	print("Sending Emails...")
	os.system('sudo python send_email.py')


def main():
	report()

if __name__ == "__main__":
	main()
	