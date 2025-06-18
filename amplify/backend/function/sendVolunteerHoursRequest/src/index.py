import json
import boto3
from datetime import datetime
import os
from jinja2 import Environment, FileSystemLoader

def handler(event, context):
    # Initialize SES client
    ses_client = boto3.client('ses')
    
    try:
        # Debug: Print the entire event to understand the structure
        print(f'Raw event: {json.dumps(event, default=str)}')
        
        # Parse the event body more carefully
        body = None
        if 'body' in event:
            if isinstance(event['body'], str):
                try:
                    body = json.loads(event['body'])
                    print(f'Parsed body from string: {type(body)}')
                except json.JSONDecodeError as e:
                    print(f'JSON decode error: {e}')
                    return {
                        'statusCode': 400,
                        'headers': {
                            'Access-Control-Allow-Headers': '*',
                            'Access-Control-Allow-Origin': '*',
                            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                        },
                        'body': json.dumps({
                            'error': 'Invalid JSON in request body'
                        })
                    }
            elif isinstance(event['body'], dict):
                body = event['body']
                print(f'Body is already a dict: {type(body)}')
            else:
                print(f'Unexpected body type: {type(event["body"])}')
                body = {}
        else:
            # No body in event, try to use the event itself
            body = event
            print(f'No body field, using event: {type(body)}')
        
        # Ensure body is a dictionary
        if not isinstance(body, dict):
            print(f'Body is not a dict after parsing: {type(body)}')
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Headers': '*',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({
                    'error': 'Request body must be a JSON object'
                })
            }
        
        print(f'Final body keys: {list(body.keys())}')
        
        # Extract email addresses from the body
        activity_supervisor_email = body.get('activity_supervisor')
        school_supervisor_email = body.get('school_supervisor')
        
        print(f'Supervisor emails - Activity: {activity_supervisor_email}, School: {school_supervisor_email}')
        
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
                    'error': 'Both activity_supervisor and school_supervisor email addresses are required',
                    'received_keys': list(body.keys())
                })
            }
        
        # Handle the new volunteer hours request with Jinja2 template
        return handle_volunteer_hours_request_with_template(ses_client, body)
        
    except Exception as e:
        print(f'Error in handler: {str(e)}')
        print(f'Error type: {type(e)}')
        import traceback
        print(f'Traceback: {traceback.format_exc()}')
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'error': 'Failed to send volunteer hours request',
                'details': str(e)
            })
        }

def handle_volunteer_hours_request_with_template(ses_client, body):
    """Handle volunteer hours requests using Jinja2 HTML template"""
    try:
        # Extract supervisor emails
        activity_supervisor_email = body.get('activity_supervisor')
        school_supervisor_email = body.get('school_supervisor')
        
        print('Processing volunteer hours request with template:', {
            'activity_supervisor': activity_supervisor_email,
            'school_supervisor': school_supervisor_email,
            'data_keys': list(body.keys())
        })
        
        # Set up Jinja2 environment - template is now in src/templates/
        template_dir = os.path.join(os.path.dirname(__file__), 'templates')
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template('index.html')
        
        # Prepare template context with all the data from the Flutter app
        template_context = {
            # Volunteer information
            'volunteer_name': body.get('volunteer_name', 'Unknown Volunteer'),
            'volunteer_email': body.get('volunteer_email', 'Unknown Email'),
            'student_id': body.get('student_id', 'Not specified'),
            'school_name': body.get('school_name', 'Not specified'),
            'submission_date': body.get('submission_date', datetime.now().strftime('%B %d, %Y')),
            
            # Sightings summary
            'total_sightings': body.get('total_sightings', 0),
            'total_hours': body.get('total_hours', '0.00'),
            'date_range': body.get('date_range', 'Unknown'),
            'locations_summary': body.get('locations_summary', 'Various locations'),
            'species_count': body.get('species_count', 0),
            'sightings': body.get('sightings', []),
            
            # Calculation constants
            'base_time_per_sighting': body.get('base_time_per_sighting', 15),
            'description_bonus_per_chars': body.get('description_bonus_per_chars', 5),
            'description_char_threshold': body.get('description_char_threshold', 50),
            'average_travel_speed': body.get('average_travel_speed', 30),
            'time_window_hours': body.get('time_window_hours', 2),
        }
        
        print(f'Template context prepared: {list(template_context.keys())}')
        
        # Render the HTML template
        html_content = template.render(template_context)
        
        # Email configuration
        sender_email = 'volunteer@sighttrack.org'
        subject = f"SightTrack Volunteer Hours Request - {template_context['volunteer_name']}"
        
        print(f'Sending email to: {[activity_supervisor_email, school_supervisor_email]}')
        
        # Send email to both supervisors
        response = ses_client.send_email(
            Source=sender_email,
            Destination={
                'ToAddresses': [activity_supervisor_email, school_supervisor_email]
            },
            Message={
                'Subject': {
                    'Data': subject,
                    'Charset': 'UTF-8'
                },
                'Body': {
                    'Html': {
                        'Data': html_content,
                        'Charset': 'UTF-8'
                    }
                }
            }
        )
        
        print(f'Volunteer hours request sent successfully: {response["MessageId"]}')
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'message': 'Volunteer hours request sent successfully',
                'messageId': response['MessageId'],
                'summary': {
                    'volunteer': template_context['volunteer_name'],
                    'hours': template_context['total_hours'],
                    'sightings': template_context['total_sightings']
                }
            })
        }
        
    except Exception as e:
        print(f'Error sending volunteer hours request with template: {e}')
        import traceback
        print(f'Traceback: {traceback.format_exc()}')
        raise e