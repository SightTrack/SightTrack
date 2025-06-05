import json
import boto3
from botocore.exceptions import ClientError

def handler(event, context):
    # Initialize SES client
    ses_client = boto3.client('ses')
    
    try:
        # Parse the event body if it's a string
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})
        
        # Extract email addresses from the event
        activity_supervisor_email = body.get('activitySupervisor')
        school_supervisor_email = body.get('schoolSupervisor')
        
        # Get data blob (don't do anything with it yet)
        data = body.get('data')
        print('Received data blob:', data)
        
        # Validate that both email addresses are provided
        if not activity_supervisor_email or not school_supervisor_email:
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Headers': '*',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({
                    'error': 'Both activitySupervisor and schoolSupervisor email addresses are required'
                })
            }
        
        # Email configuration
        sender_email = 'volunteer@sighttrack.org'  # Replace with your verified SES email
        
        # Simple hello world email
        subject = 'Hello from SightTrack'
        
        email_body = """
        Hello World!
        
        This is a test email from the SightTrack volunteer hours system.
        
        Best regards,
        SightTrack System
        """
        
        # Send email to activity supervisor
        try:
            activity_response = ses_client.send_email(
                Source=sender_email,
                Destination={
                    'ToAddresses': [activity_supervisor_email]
                },
                Message={
                    'Subject': {
                        'Data': subject,
                        'Charset': 'UTF-8'
                    },
                    'Body': {
                        'Text': {
                            'Data': email_body,
                            'Charset': 'UTF-8'
                        }
                    }
                }
            )
            print(f'Email sent to activity supervisor: {activity_response["MessageId"]}')
        except ClientError as e:
            print(f'Error sending email to activity supervisor: {e}')
            raise e
        
        # Send email to school supervisor
        try:
            school_response = ses_client.send_email(
                Source=sender_email,
                Destination={
                    'ToAddresses': [school_supervisor_email]
                },
                Message={
                    'Subject': {
                        'Data': subject,
                        'Charset': 'UTF-8'
                    },
                    'Body': {
                        'Text': {
                            'Data': email_body,
                            'Charset': 'UTF-8'
                        }
                    }
                }
            )
            print(f'Email sent to school supervisor: {school_response["MessageId"]}')
        except ClientError as e:
            print(f'Error sending email to school supervisor: {e}')
            raise e
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'message': 'Hello world emails sent successfully',
                'activitySupervisorMessageId': activity_response['MessageId'],
                'schoolSupervisorMessageId': school_response['MessageId']
            })
        }
        
    except Exception as e:
        print(f'Error: {str(e)}')
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'error': 'Failed to send hello world emails',
                'details': str(e)
            })
        }