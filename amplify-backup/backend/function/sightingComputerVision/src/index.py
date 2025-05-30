import json
import boto3
import base64

rekognition = boto3.client('rekognition')

def lambda_handler(event, context):
    try:
        print(f"Full event: {json.dumps(event)}")

        if 'body' not in event:
            print("No 'body' in event")
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'No request body provided'}),
                'headers': {'Content-Type': 'application/json'}
            }

        body = event['body']
        print(f"Raw body: {body}, Type: {type(body)}")

        # Parse the JSON body
        try:
            parsed_body = json.loads(body)
            print(f"Parsed body: {parsed_body}, Type: {type(parsed_body)}")
            if isinstance(parsed_body, str):  # Handle double encoding if present
                parsed_body = json.loads(parsed_body)
                print(f"Double-parsed body: {parsed_body}, Type: {type(parsed_body)}")
        except json.JSONDecodeError as e:
            print(f"JSON decode error: {str(e)}")
            return {
                'statusCode': 400,
                'body': json.dumps({'message': f'Invalid JSON in body: {str(e)}'}),
                'headers': {'Content-Type': 'application/json'}
            }

        # Get the base64-encoded image
        base64_image = parsed_body.get('image')
        if not base64_image:
            print("Missing 'image' in body")
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Missing image data'}),
                'headers': {'Content-Type': 'application/json'}
            }

        # Decode base64 to bytes
        image_bytes = base64.b64decode(base64_image)
        print(f"Image bytes length: {len(image_bytes)}")

        rekognition_params = {
            'Image': {
                'Bytes': image_bytes  # Pass raw bytes directly to Rekognition
            },
            'MaxLabels': 10,
            'MinConfidence': 70
        }

        print("Calling Rekognition")
        response = rekognition.detect_labels(**rekognition_params)
        print(f"Rekognition response: {json.dumps(response)}")

        relevant_categories = ['Animal', 'Plant', 'Tree', 'Flower', 'Bird', 'Fish', 'Pet', 'Wildlife']
        filtered_labels = [
            {'Name': label['Name'], 'Confidence': round(label['Confidence'], 2)}
            for label in response['Labels']
            if any(category in label['Name'] for category in relevant_categories) or label['Name'] in relevant_categories
        ]

        if not filtered_labels:
            filtered_labels = [
                {'Name': label['Name'], 'Confidence': round(label['Confidence'], 2)}
                for label in response['Labels'][:5]
            ]

        result = {
            'statusCode': 200,
            'body': json.dumps({
                'labels': filtered_labels,
                'message': 'Image analyzed directly'
            }),
            'headers': {'Content-Type': 'application/json'}
        }
        print(f"Returning: {json.dumps(result)}")
        return result

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': f'Internal server error: {str(e)}'}),
            'headers': {'Content-Type': 'application/json'}
        }