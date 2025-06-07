import os
import requests
from dotenv import load_dotenv

load_dotenv()

def send_simple_message():
  	return requests.post(
  		"https://api.mailgun.net/v3/mail.sighttrack.org/messages",
  		auth=("api", os.getenv('MAILGUN')),
  		data={"from": "Mailgun Sandbox <postmaster@mail.sighttrack.org>",
			"to": "James Tan <0651jamestan@gmail.com>",
  			"subject": "Hello James Tan",
  			"text": "Congratulations James Tan, you just sent an email with Mailgun! You are truly awesome!"})

send_simple_message()