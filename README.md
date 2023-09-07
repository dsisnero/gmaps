# gmaps

# Google Maps and Nearest Hospital Finder CLI

This repository contains a command-line tool for finding the nearest hospitals using Google Maps APIs and displaying the driving directions. It also provides functionality to generate a static map image of the directions.

## Prerequisites

Before using this tool, make sure you have the following prerequisites installed:

- Crystal
- A Google Cloud Platform (GCP) project with enabled APIs and API key

## Getting Started

### Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     gmaps:
       github: dsisnero/gmaps
   ```

2. Run `shards install`

## Usage

### Setting Up Google Cloud APIs

To use Google Cloud APIs, you'll need to access the Google Cloud Console and follow these steps:

1. **Access the Google Cloud Console**:

   Go to the following URL to access the Google Cloud Console:
   [Google Cloud Console](https://console.cloud.google.com/)

2. **Log In or Sign Up**:

   If you already have a Google account, you can log in using your existing credentials. If you don't have a Google account, you'll need to sign up for one.

3. **Create or Select a Project**:

   - If you don't already have a project, you can create a new one.
   - If you have an existing project, you can select it from the list.

4. **Enable APIs**:

   - Click on the "Navigation menu" (the three horizontal lines in the upper left corner).
   - Under "APIs & Services," click on "Library."

5. **Search for and Enable APIs**:

   In the Library page, search for the specific APIs you need (e.g., "Google Maps JavaScript API," "Google Places API," "Directions API," "Geocoding API"):

   - Use the search bar at the top to find the API you want to enable.
   - Click on the API.
   - Click the "Enable" button.

6. **Create Credentials**:

   - In the Google Cloud Console, navigate to "APIs & Services" > "Credentials."
   - Click on "Create Credentials" and choose the appropriate credential type based on your use case. For most API access, select "API Key." Follow the on-screen instructions to create and configure the key.

7. **Restrict API Key (if necessary)**:

   For security purposes, consider restricting your API key to specific APIs, IP addresses, or usage limits. You can configure these restrictions in the "API Key" settings.

Once you've completed these steps, you'll have set up Google Cloud APIs and obtained the necessary credentials to access them. You can then use these credentials in your code to interact with the enabled APIs, whether it's for maps, geocoding, or other services.

have a ENV["API_KEY"] with the api key from google

```bash
nearest_hospital --lat <latitude> --lng <longitude>
```

## Contributing

1. Fork it (<https://github.com/dsisnero/gmaps/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [dsisnero](https://github.com/dsisnero) - creator and maintainer
