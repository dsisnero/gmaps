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

    def initialize(@name : String, @place_id, @latitude : Float64, @longitude : Float64, @address : String, @distance : Float64 = 0.0)
    end

    def display
      puts name
      puts "\naddress"
      puts "distance: #{distance}\n"
    end
  end

  class Client
    include GeoFuncs

    getter http_client : HTTP::Client
    getter api_key : String

    def initialize(api_key : String)
      @api_key = api_key
      @http_client = HTTP::Client.new("maps.googleapis.com", tls: true, port: 443)
    end

    def find_nearest_hospitals(lat : Float64, long : Float64) : Array(Hospital)
      response = get_nearest_hospitals_as_json(lat, long)
      File.write("result.json", response.body)
      extract_hospitals(response.body)
    end

    # https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=40.56908,-116.92226&radius=5000&types=hospital&key=AIzaSyC4P-wFp5NJkICEG7gD6QpHF6Kf4IKgHko
    def get_nearest_hospitals_as_json(lat : Float64, long : Float64) : HTTP::Client::Response
      url = "/maps/api/place/nearbysearch/json?location=#{lat},#{long}&radius=5000&types=hospital&key=#{@api_key}"
      Log.debug { "calling client with #{url}" }
      http_client.get("/maps/api/place/nearbysearch/json?location=#{lat},#{long}&radius=170000&types=hospital&key=#{@api_key}")
    rescue ex
      Log.error { ex.message }
      raise ex
    end

    def extract_hospitals(json_result : String) : Array(Hospital)
      result = PlaceQuery.from_json(json_result)
      puts "status #{result.status}"
      puts "next_page_token #{result.next_page_token}"

      hospitals = [] of Hospital
      return hospitals unless result.status == "OK"
      places = result.results
      places.each do |place|
        loc = place.location
        hospitals << Hospital.new(name: place.name, place_id: place.place_id, latitude: loc.latitude, longitude: loc.longitude, address: place.vicinity)
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
      Log.debug { "calling client with #{url}" }
      resp = http_client.get(url)
      puts resp.body
      puts
      resp
    rescue ex
      Log.error { ex.message }
      raise ex
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
