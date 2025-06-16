import json
import boto3
from botocore.exceptions import ClientError
from datetime import datetime

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
        
        # Handle different request types based on structure
        if 'volunteerData' in body:
            # New structured volunteer hours request
            return handle_volunteer_hours_request(ses_client, body)
        elif 'emailBody' in body:
            # Legacy email request
            return handle_legacy_email_request(ses_client, body)
        else:
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Headers': '*',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({
                    'error': 'Invalid request structure'
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
                'error': 'Failed to send volunteer hours request',
                'details': str(e)
            })
        }

def handle_volunteer_hours_request(ses_client, body):
    """Handle structured volunteer hours requests"""
    try:
        # Extract structured data
        activity_supervisor_email = body.get('activitySupervisor')
        school_supervisor_email = body.get('schoolSupervisor')
        subject = body.get('subject', 'Volunteer Hours Request')
        volunteer_data = body.get('volunteerData', {})
        
        print('Processing volunteer hours request:', {
            'activity_supervisor': activity_supervisor_email,
            'school_supervisor': school_supervisor_email,
            'volunteer_data_keys': list(volunteer_data.keys())
        })
        
        # Extract volunteer information
        sightings = volunteer_data.get('sightings', [])
        total_hours = volunteer_data.get('totalHours', 0)
        user_data = volunteer_data.get('user', {})
        submission_date = volunteer_data.get('submissionDate', '')
        sighting_count = volunteer_data.get('sightingCount', len(sightings))
        
        # Extract user information
        user_name = user_data.get('name', 'Unknown User')
        user_email = user_data.get('email', 'Unknown Email')
        
        # Parse submission date
        submission_date_str = 'Unknown Date'
        if submission_date:
            try:
                dt = datetime.fromisoformat(submission_date.replace('Z', '+00:00'))
                submission_date_str = dt.strftime('%B %d, %Y at %I:%M %p')
            except:
                submission_date_str = str(submission_date)
        
        # Build sightings summary
        sightings_summary = []
        for i, sighting in enumerate(sightings[:10], 1):  # Limit to first 10 sightings for email brevity
            species = sighting.get('species', 'Unknown Species')
            city = sighting.get('city', 'Unknown Location')
            timestamp = sighting.get('timestamp', '')
            description = sighting.get('description', '')
            
            # Parse timestamp if available
            date_str = 'Unknown Date'
            if timestamp:
                try:
                    # Handle different timestamp formats
                    if isinstance(timestamp, dict):
                        # Amplify DateTime format
                        timestamp_str = timestamp.get('iso8601String', '')
                    else:
                        timestamp_str = str(timestamp)
                    
                    dt = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
                    date_str = dt.strftime('%B %d, %Y at %I:%M %p')
                except:
                    date_str = str(timestamp)
            
            sighting_entry = f"   {i}. {species} - {city}\n      Date: {date_str}"
            if description and len(description.strip()) > 0:
                # Truncate long descriptions
                desc_preview = description[:100] + "..." if len(description) > 100 else description
                sighting_entry += f"\n      Notes: {desc_preview}"
            
            sightings_summary.append(sighting_entry)
        
        # Add note if there are more sightings
        more_sightings_note = ""
        if len(sightings) > 10:
            more_sightings_note = f"\n   ... and {len(sightings) - 10} additional sightings"
        
        # Create the email body
        email_body = f"""
Dear Supervisors,

This is a volunteer hours request from the SightTrack citizen science platform.

VOLUNTEER INFORMATION:
• Name: {user_name}
• Email: {user_email}
• Total Hours Requested: {total_hours:.2f} hours
• Submission Date: {submission_date_str}

SUMMARY:
{user_name} has submitted {sighting_count} wildlife sightings for volunteer hour credit. The total calculated volunteer hours based on our standardized system is {total_hours:.2f} hours.

SIGHTINGS INCLUDED ({sighting_count} total):
{chr(10).join(sightings_summary)}{more_sightings_note}

HOW HOURS ARE CALCULATED:
• Base time: 15 minutes per sighting
• Description bonus: +5 minutes per 50 characters of detailed observations  
• Travel time: Based on GPS distance between consecutive sightings (assuming 30 km/h average speed)
• Time window: Travel time only counted if sightings are within 2 hours of each other

NEXT STEPS:
Please review this volunteer hours request and verify the information. The volunteer has completed valuable citizen science work contributing to wildlife conservation and research efforts.

If you approve these hours, please respond to this email with your approval. If you have any questions or need additional information, please contact the SightTrack team.

Thank you for supporting our volunteers and citizen science initiatives.

Best regards,
SightTrack Volunteer Hours System
volunteer@sighttrack.org

---
This is an automated message from the SightTrack platform.
Generated on: {datetime.now().strftime('%B %d, %Y at %I:%M %p UTC')}
        """
        
        # Email configuration
        sender_email = 'volunteer@sighttrack.org'
        
        # Send email to school supervisor with activity supervisor CC'd
        response = ses_client.send_email(
            Source=sender_email,
            Destination={
                'ToAddresses': [school_supervisor_email],
                'CcAddresses': [activity_supervisor_email]
            },
            Message={
                'Subject': {
                    'Data': subject,
                    'Charset': 'UTF-8'
                },
                'Body': {
                    'Text': {
                        'Data': email_body.strip(),
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
                    'volunteer': user_name,
                    'hours': total_hours,
                    'sightings': sighting_count
                }
            })
        }
        
    except ClientError as e:
        print(f'Error sending volunteer hours request: {e}')
        raise e

def handle_legacy_email_request(ses_client, body):
    """Handle legacy email requests for backward compatibility"""
    try:
        activity_supervisor_email = body.get('activitySupervisor')
        school_supervisor_email = body.get('schoolSupervisor')
        subject = body.get('subject', 'Email from SightTrack')
        email_body = body.get('emailBody', '')
        
        sender_email = 'volunteer@sighttrack.org'
        
        response = ses_client.send_email(
            Source=sender_email,
            Destination={
                'ToAddresses': [school_supervisor_email],
                'CcAddresses': [activity_supervisor_email]
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
        
        print(f'Legacy email sent successfully: {response["MessageId"]}')
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'message': 'Email sent successfully',
                'messageId': response['MessageId']
            })
        }
        
    except ClientError as e:
        print(f'Error sending legacy email: {e}')
        raise e