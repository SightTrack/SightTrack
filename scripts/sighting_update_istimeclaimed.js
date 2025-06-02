const AWS = require('aws-sdk');

// Configure AWS SDK with region
AWS.config.update({
    region: 'us-east-1', // Replace with your region, e.g., 'us-east-1'
    // Optionally, add credentials if not using AWS CLI or environment variables
    // accessKeyId: 'your-access-key',
    // secretAccessKey: 'your-secret-key'
});

const dynamodb = new AWS.DynamoDB.DocumentClient();

async function backfillIsTimeClaimed() {
    const tableName = 'Sighting-qo222crfkbdjhaavuojlf47f3e-dev'; // Replace with your DynamoDB table name, e.g., Todo-yourapp-prod
    const defaultValue = false; // Set default value for isTimeClaimed (true or false)

    try {
        // Scan for all records
        const scanParams = { TableName: tableName };
        const data = await dynamodb.scan(scanParams).promise();

        if (!data.Items || data.Items.length === 0) {
            console.log('No records found in the table.');
            return;
        }

        // Update records missing isTimeClaimed
        let updatedCount = 0;
        for (const item of data.Items) {
            if (item.isTimeClaimed === undefined || item.isTimeClaimed === null) {
                const updateParams = {
                    TableName: tableName,
                    Key: { id: item.id }, // Assuming 'id' is the primary key
                    UpdateExpression: 'SET isTimeClaimed = :value',
                    ExpressionAttributeValues: { ':value': defaultValue },
                };
                await dynamodb.update(updateParams).promise();
                console.log(`Updated record with id: ${item.id}`);
                updatedCount++;
            }
        }
        console.log(`Backfill complete. Updated ${updatedCount} records.`);
    } catch (error) {
        console.error('Error during backfill:', error);
    }
}

backfillIsTimeClaimed();