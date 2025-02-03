# src/gmaps.cr
require "http/client"
require "./location_result"
require "./direction_result"
require "json"
require "http/params"

module Gmaps
  module GeoFuncs
    def to_radians(degrees : Float64) : Float64
      degrees * Math::PI / 180.0
    end

    def calculate_distance(lat1 : Float64, long1 : Float64, lat2 : Float64, long2 : Float64) : Float64
      radius = 6371.0 # Earth's radius in kilometers

      dlat = to_radians(lat2 - lat1)
      dlong = to_radians(long2 - long1)
      G
      a = Math.sin(dlat / 2.0) * Math.sin(dlat / 2.0) +
          Math.cos(to_radians(lat1)) * Math.cos(to_radians(lat2)) *
          Math.sin(dlong / 2.0) * Math.sin(dlong / 2.0)

      c = 2.0 * Math.atan2(Math.sqrt(a), Math.sqrt(1.0 - a))
      distance = radius * c

      distance
    end
  end

  class Hospital
    getter name : String
    getter place_id : String
    getter latitude : Float64
    getter longitude : Float64
    getter address : String?
    getter distance : Float64
    getter rating : Float64?
    getter extra = Hash(String, JSON::Any).new

    def initialize(@name : String, @place_id, @latitude : Float64, @longitude : Float64, @address : String?, @distance : Float64 = 0.0, @rating = nil)
    end

    def address_lines
      return [] of String unless address
      address.not_nil!.split(",").map(&.strip)
    end

    def address_to_adoc(io : IO)
      address_line_string = address_lines.join(" +\n")
      io << "#{name} +\n"
      io << "#{address_line_string}"
    end

    def display
      puts "name: #{name}"
      puts "address #{address}"
      puts "distance: #{distance}"
      if rating
        puts "rating #{rating}\n"
      else
        puts "\n"
      end
    end
  end

  class Client
    include GeoFuncs
    Log = ::Log.for("geo_client")

    getter http_client : HTTP::Client
    getter api_key : String

    def initialize(api_key : String)
      raise NoApiKeyError.new("API key is required and cannot be empty") if api_key.empty?
      @api_key = api_key
      @http_client = HTTP::Client.new("maps.googleapis.com", tls: true, port: 443)
    end

    def find_nearest_hospitals(lat : Float64, long : Float64, radius : Float64 = 50000.0) : Array(Hospital)
      response = get_nearest_hospitals_as_json(lat, long, radius)
      extract_hospitals(response.body)
    end

    def find_nearest_hospitals(location : Gmaps::Locatable, radius : Float64 = 50000.0)
      find_nearest_hospitals(location.latitude, location.longitude, radius)
    end

    def search_hospitals_by_name(query : String, lat : Float64, long : Float64, radius : Float64 = 50000.0) : Array(Hospital)
      params = HTTP::Params.build do |form|
        form.add("input", query)
        form.add("inputtype", "textquery")
        form.add("location", "#{lat},#{long}")
        form.add("type", "hospital")
        form.add("radius", radius.to_s)
        form.add("fields", "name,formatted_address,rating,geometry,place_id")
        form.add("key", @api_key)
      end

      url = "/maps/api/place/findplacefromtext/json?#{params}"
      Log.info { "Searching for hospitals matching: #{query}" }
      Log.debug { "Calling Google Places Text Search API with URL (key redacted): #{url.gsub(@api_key, "REDACTED")}" }

      resp = http_client.get(url)
      Log.debug { "API Response status: #{resp.status_code}" }
      Log.debug { "API Response body: #{resp.body}" }

      if resp.success?
        result = PlaceQueryName.from_json(resp.body)
        hospitals = extract_hospitals(resp.body, PlaceQueryName)
        Log.info { "Found #{hospitals.size} hospitals matching '#{query}'" }
        hospitals
      else
        Log.error { "Google Places API call failed with status #{resp.status_code}" }
        Log.error { "Response body: #{resp.body}" }
        if resp.status_code == 403 && resp.body.includes?("The provided API key is invalid")
          raise InvalidApiKeyError.new
        end
        raise "Failed to fetch hospital information using Google Places API: #{resp.body}"
      end
    end

    # https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=40.56908,-116.92226&radius=5000&types=hospital&key=AIzaSyC4P-wFp5NJkICEG7gD6QpHF6Kf4IKgHko
    def get_nearest_hospitals_as_json(lat : Float64, long : Float64, radius : Float64 = 50000.0) : HTTP::Client::Response
      # url = "/maps/api/place/nearbysearch/json?location=#{lat},#{long}&rankby=distance&type=hospital&key=#{@api_key}"
      url = "/maps/api/place/nearbysearch/json?radius=#{radius}&keyword=hospital&location=#{lat},#{long}&type=hospital&key=#{@api_key}"
      Log.debug { "Calling Google Places API with URL (key redacted): #{url.gsub(@api_key, "REDACTED")}" }
      resp = http_client.get(url)
      Log.debug { "API Response status: #{resp.status_code}" }
      Log.debug { "API Response body: #{resp.body}" }
      if resp.success?
        resp
      else
        Log.error { "Gmap api call unsuccessful returned body: #{resp.body}" }
        raise "Failed to fetch hospital information using google maps api #{resp.body}"
      end
    end

    def extract_hospitals(json_result : String, extractor = PlaceQuery) : Array(Hospital)
      result = extractor.from_json(json_result)
      Log.debug { "Extracted #{result} places from json\n#{json_result}" }
      places = case extractor
               when PlaceQuery.class
                 result.as(PlaceQuery).results
               when PlaceQueryName.class
                 result.as(PlaceQueryName).candidates
               else
                 Log.error { "Unknown extractor type: #{extractor} #{extractor.class} #{extractor.=== PlaceQueryName}" }
                 [] of Place
               end
      hospitals = [] of Hospital
      if result.status == "OK"
        Log.debug { "Extracted #{places.size} places from results #{places}" }
        places.each do |place|
          Log.debug { "Processing place: #{place.name}" }
          loc = place.location
          address = place.formatted_address || place.vicinity
          hospitals << Hospital.new(name: place.name, place_id: place.place_id,
            latitude: loc.latitude, longitude: loc.longitude, address: address, rating: place.rating)
        end
      elsif result.status == "ZERO_RESULTS"
        Log.info { "No hospitals found within 100 miles" }
        return hospitals
      elsif result.status == "REQUEST_DENIED" && result.error_message.try(&.includes?("API key is invalid"))
        Log.error { "Invalid API key" }
        raise InvalidApiKeyError.new("The provided API key is invalid")
      else
        Log.error { "Google Places API call failed with status #{result.status}" }
        raise "Failed to fetch hospital information using Google Places API: #{result.status}: #{result.error_message}"
      end

      hospitals
    end

    def generate_directions_response(origin : Gmaps::LatLon, destination : Gmaps::Hospital) : HTTP::Client::Response
      url = "/maps/api/directions/json?origin=#{origin.latitude},#{origin.longitude}&destination=place_id:#{destination.place_id}&key=#{api_key}"
      Log.debug { "getting directions by calling client with #{url}" }
      resp = http_client.get(url)
    end

    def generate_directions_response(origin_lat : Float64, origin_long : Float64, dest_lat : Float64, dest_long : Float64) : HTTP::Client::Response
      url = "/maps/api/directions/json?origin={latitude},{longitude}&destination={destination}&key={api_key}"
      Log.debug { "calling client with #{url}" }
      resp = http_client.get(url)
      puts resp.body
      puts
      resp
    rescue ex
      Log.error { ex.message }
      raise ex
    end

    # Gets a satellite image for the specified location
    def get_satellite_image(latitude : Float64, longitude : Float64, zoom : Int32 = 19) : Bytes
      params = HTTP::Params.build do |form|
        form.add "center", "#{latitude},#{longitude}"
        form.add "zoom", zoom.to_s
        form.add "size", "600x600"
        form.add "maptype", "satellite"
        form.add "key", @api_key
      end

      url = "/maps/api/staticmap?#{params}"
      Log.debug { "Fetching satellite image with URL (key redacted): #{url.gsub(@api_key, "REDACTED")}" }

      resp = http_client.get(url)

      if resp.success?
        Log.debug { "Successfully retrieved satellite image" }
        resp.body.to_slice
      else
        if resp.status_code == 403 && resp.body.includes? "The provided API key is invalid"
          raise Gmaps::InvalidApiKeyError.new
        else
          Log.error { "Failed to fetch satellite image: #{resp.status_code}" }
          raise "Failed to fetch satellite image: #{resp.status_code} - #{resp.body}"
        end
      end
    end
  end
end
