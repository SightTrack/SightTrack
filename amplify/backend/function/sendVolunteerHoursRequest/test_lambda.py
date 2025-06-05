import json
import sys
import os

# Add the src directory to the path so we can import the handler
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from src.index import handler    

if __name__ == "__main__":
    """Test the Lambda function locally"""
    
    # Sample event data that mimics what the Lambda would receive
    test_event = {
        'body': json.dumps({
            'activitySupervisor': '0651jamestan@gmail.com',  # Replace with a test email
            'schoolSupervisor': '0651jamestan@gmail.com',      # Replace with a test email
            'data': {
                'studentName': 'John Doe',
                'hours': 25,
                'activity': 'Community Service',
                'date': '2024-01-15'
            }
        }),
        'headers': {
            'Content-Type': 'application/json'
        }
    }
    
    # Sample context (minimal for testing)
    test_context = {
        'function_name': 'sendVolunteerHoursRequest',
        'memory_limit_in_mb': 128,
        'invoked_function_arn': 'arn:aws:lambda:us-east-1:123456789012:function:sendVolunteerHoursRequest'
    }
    
    try:
        # Call the handler
        response = handler(test_event, test_context)
        
        print("Lambda Response:")
        print(json.dumps(response, indent=2))
        
        if response['statusCode'] == 200:
            print("\nSUCCESS: Function executed successfully!")
        else:
            print(f"\nFAILED: Function returned status code {response['statusCode']}")
            
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        import traceback
        traceback.print_exc()