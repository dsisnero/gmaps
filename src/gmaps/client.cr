# src/gmaps.cr
require "http/client"
require "./location_result"
require "./direction_result"
require "json"

module Gmaps
  module GeoFuncs
    def to_radians(degrees : Float64) : Float64
      degrees * Math::PI / 180.0
    end

    def calculate_distance(lat1 : Float64, long1 : Float64, lat2 : Float64, long2 : Float64) : Float64
      radius = 6371.0 # Earth's radius in kilometers

      dlat = to_radians(lat2 - lat1)
      dlong = to_radians(long2 - long1)

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
    getter address : String
    getter distance : Float64
    getter rating : Float64?
    getter extra = Hash(String, JSON::Any).new

    def initialize(@name : String, @place_id, @latitude : Float64, @longitude : Float64, @address : String, @distance : Float64 = 0.0, @rating = nil)
    end

    def address_lines
      address.split(",").map(&.strip)
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

    def search_hospitals_by_name(query : String, lat : Float64, long : Float64) : Array(Hospital)
      url = "/maps/api/place/textsearch/json?query=#{URI.encode_www_form(query)}&location=#{lat},#{long}&type=hospital&key=#{@api_key}"
      Log.info { "Searching for hospitals matching: #{query}" }
      Log.debug { "Calling Google Places Text Search API with URL (key redacted): #{url.gsub(@api_key, "REDACTED")}" }
      
      resp = http_client.get(url)
      Log.debug { "API Response status: #{resp.status_code}" }
      Log.debug { "API Response body: #{resp.body}" }
      
      if resp.success?
        hospitals = extract_hospitals(resp.body)
        Log.info { "Found #{hospitals.size} hospitals matching '#{query}'" }
        hospitals
      else
        Log.error { "Google Places API call failed with status #{resp.status_code}" }
        Log.error { "Response body: #{resp.body}" }
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

    def extract_hospitals(json_result : String) : Array(Hospital)
      result = PlaceQuery.from_json(json_result)
      hospitals = [] of Hospital
      return hospitals unless result.status == "OK"
      places = result.results
      places.each do |place|
        loc = place.location
        hospitals << Hospital.new(name: place.name, place_id: place.place_id,
          latitude: loc.latitude, longitude: loc.longitude, address: place.vicinity, rating: place.rating)
      end

      # results.each do |result|
      #   name = result["name"].as(String)
      #   lat = result["geometry"]["location"]["lat"].as(Float64)
      #   long = result["geometry"]["location"]["long"].as(Float64)
      #   address = result["vicinity"].as(String)
      #   distance = calculate_distance(lat, long, original_lat, original_long) # Implement this method
      #   hospital = Hospital.new(name, lat, long, address, distance)
      #   hospitals << hospital
      # end

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
  end
end
