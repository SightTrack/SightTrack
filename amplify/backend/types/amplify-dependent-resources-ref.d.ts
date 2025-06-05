export type AmplifyDependentResourcesAttributes = {
  "api": {
    "restApiResource": {
      "ApiId": "string",
      "ApiName": "string",
      "RootUrl": "string"
    },
    "sighttrackv2": {
      "GraphQLAPIEndpointOutput": "string",
      "GraphQLAPIIdOutput": "string"
    }
  },
  "auth": {
    "sighttrackv28644ebea": {
      "AppClientID": "string",
      "AppClientIDWeb": "string",
      "IdentityPoolId": "string",
      "IdentityPoolName": "string",
      "UserPoolArn": "string",
      "UserPoolId": "string",
      "UserPoolName": "string"
    },
    "userPoolGroups": {
      "AdminGroupRole": "string"
    }
  },
  "function": {
    "sendVolunteerHoursRequest": {
      "Arn": "string",
      "LambdaExecutionRole": "string",
      "LambdaExecutionRoleArn": "string",
      "Name": "string",
      "Region": "string"
    },
    "sightingComputerVision": {
      "Arn": "string",
      "LambdaExecutionRole": "string",
      "LambdaExecutionRoleArn": "string",
      "Name": "string",
      "Region": "string"
    }
  },
  "storage": {
    "StorageResource": {
      "BucketName": "string",
      "Region": "string"
    }
  }
}