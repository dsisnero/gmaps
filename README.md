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

To use Google Cloud APIs, you'll need to:

1. **Get an API Key**:

   1. Access the [Google Cloud Console](https://console.cloud.google.com/)
   2. Create or select a project
   3. Enable the required APIs:
      - Google Maps JavaScript API
      - Google Places API
      - Directions API
      - Geocoding API
   4. Create credentials (API Key) in "APIs & Services" > "Credentials"
   5. Optionally restrict your API key for security

2. **Configure Your API Key**:

   You have two options to configure your API key:

   a. Environment Variable:
   ```bash
   export GOOGLE_MAPS_API_KEY="your-api-key-here"
   ```

   b. Permanent Configuration:
   ```bash
   gmaps edit_api_key your-api-key-here
   ```
   This will securely store your API key in an encrypted configuration file.

3. **Using the Commands**:

   Find nearest hospitals:
   ```bash
   gmaps nearest_hospital --lat <latitude> --lng <longitude>
   ```

   Get a satellite image:
   ```bash
   gmaps get_satellite_image --lat <latitude> --lng <longitude> --output_file <path>
   ```

## Contributing

1. Fork it (<https://github.com/dsisnero/gmaps/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [dsisnero](https://github.com/dsisnero) - creator and maintainer
