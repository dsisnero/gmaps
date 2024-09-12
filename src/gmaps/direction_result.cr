require "json"
require "./lat_lon.cr"
require "./static_map"

# Represents the result of a directions request to the Google Maps API.
#
# Contains geocoded waypoints and route information. The routes contain
# legs, which have steps with turn-by-turn directions. Polylines encode
# the paths between locations.
module Gmaps
  struct GeocodedWaypoints
    include JSON::Serializable

    getter geocoder_status : String
    getter place_id : String
    getter types : Array(String)

    def initialize(@geocoder_status, @place_id, @types)
    end
  end

  struct StepValue
    include JSON::Serializable

    getter text : String

    getter value : Int32

    def initialize(@text, @value)
    end

    def to_s(io)
      io << text
    end
  end

  struct GeoBounds
    include JSON::Serializable

    getter northeast : Location
    getter southwest : Location

    def initialize(@northeast, @southwest)
    end
  end

  struct Leg
    include JSON::Serializable

    getter distance : StepValue

    getter duration : StepValue

    getter end_address : String

    getter end_location : Location

    getter start_address : String

    getter start_location : Location

    getter steps : Array(Step)

    def initialize(@distance, @duration, @end_address, @end_location, @start_address, @start_location, @steps)
    end

    def print_leg(io : IO | String, heading_level : Int32 = 4)
      io << "=" * heading_level + " Directions\n\n"
      io << "Starting Address: #{start_address}\n"
      io << "Ending Address: #{ending_address}\n"
      io << "Distance: #{distance}"
      print_steps(io)
    end

    #

    def print_steps(io)
      steps.each do |_|
        print_step(io)
      end
    end

    # output the  polyline  for the leg to udr in  google static map api
  end

  struct Polyline
    include JSON::Serializable

    @[JSON::Field(key: "points")]
    property encoded_points : String
  end

  class Step
    include JSON::Serializable

    getter distance : StepValue

    getter duration : StepValue

    getter end_location : Location

    getter html_instructions : String

    getter polyline : Polyline

    getter start_location : Location

    getter travel_mode : String

    def initialize(@distance, @duration, @end_location, @html_instructions, @polyline, @start_location, @travel_mode)
    end
  end

  struct Route
    include JSON::Serializable

    getter bounds : GeoBounds

    getter legs : Array(Leg)

    getter overview_polyline : Polyline

    def initialize(@bounds, @legs, @overview_polyline)
    end

    def print_route(io : IO | String)
    end

    def duration
      legs[0].duration.text
    end

    def distance
      legs[0].distance.text
    end

    # output a path string for the route to use in google static map api
    def path_string(weight : Int32 = 5, color : String = "blue")
      "weight:#{weight}|color:#{color}|enc:#{overview_polyline.encoded_points}"
    end
  end

  struct DirectionResult
    include JSON::Serializable

    getter geocoded_waypoints : Array(GeocodedWaypoints)
    getter routes : Array(Route)

    def initialize(@geocoded_waypoints, @routes)
    end

    # use the StaticMap class to get a static map of the routes
    def build_static_map(size : String = "640x640")
      StaticMap.build do |map|
        map.size = size
        map.center = @geocoded_waypoints[0].place_id

        @routes.each do |route|
          map.add_route_overlay(route)
        end
      end
    end

    def fetch_static_map(size : String = "640x640", format : String = "png", api_key : String? = nil)
      map = build_static_map(size)
      map.format = format
      result = map.fetch(api_key: api_key)
      if result.success?
        result.body
      else
        nil
      end
    end
  end
end
