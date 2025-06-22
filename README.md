# [SightTrack V2](https://www.sighttrack.org/)
<img src="https://github.com/user-attachments/assets/8c7d9af7-62c7-4637-8011-655792b00b1c" alt="drawing" width="150"/>

SightTrack is a mobile application that helps users identify and track wildlife through photo recognition technology. Built with Flutter and powered by AWS services, it provides an easy way to document and share wildlife sightings with location data.

## Features

- **Photo Recognition**: Identify wildlife species using AWS Rekognition
- **Location Tracking**: GPS-based location logging with offset privacy protection  
- **User Profiles**: Customizable profiles with pictures, bio, and location
- **Group Management**: User and admin role management
- **Interactive Maps**: Mapbox integration for viewing sightings
- **Data Management**: Cloud-based storage and synchronization via AWS Amplify

## Tech Stack

- **Frontend**: Flutter
- **Backend**: AWS Amplify
- **Maps**: Mapbox Flutter
- **AI/ML**: Google Cloud Vision, LLM
- **Database**: AWS DynamoDB (via Amplify)
- **Authentication**: AWS Cognito (via Amplify)
- **Storage**: AWS S3 (via Amplify)

## Installation

1. Clone the repository
2. Install Flutter dependencies:
   ```
   flutter pub get
   ```
3. Configure AWS Amplify:
   ```
   amplify configure
   amplify pull
   ```
4. Add your Mapbox access token to the app configuration
5. Run the app:
   ```
   flutter run
   ```

## Usage

1. Create an account or sign in
2. Take a photo of wildlife you want to identify
3. The app will process the image and suggest species identification
4. Add location data and notes to your sighting
5. View your sightings and those shared by the community on the map

### Changes from V1
- Use Amplify SDK for backend (so no need for making custom APIS)
- Redesign UI
- Minimal features
- Location offset
- Better user management
- Group management (User, Admin) - With admin panel 
- Google maps -> Mapbox Flutter
- Better data management via Amplify Studio
- Easier data analysis
- Profile picture, country, bio, email, username (display_username)
- Photo recognition uses two layers: Google Cloud Vision API and an LLM (Grok, ChatGPT)

### Unchanged
- AWS services

### Planned Updates
- More privacy controls
- Add other users 
- School-wide events (broadcasted)
- Community ambassadors
- Email receiving with custom @sighttrack.org domain

## License

This project is licensed under the MIT License.
