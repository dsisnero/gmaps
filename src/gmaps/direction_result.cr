require "json"
require "./lat_lon.cr"

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

    def print_steps(io)
      steps.each do |_|
        print_step(io)
      end
    end
  end

  struct Polyline
    include JSON::Serializable

    getter points : String

    def initialize(@points)
    end
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

    def initialize(@bounds, @legs)
    end

    def print_route(io : IO | String)
    end
  end

  struct DirectionResult
    include JSON::Serializable

    getter geocoded_waypoints : Array(GeocodedWaypoints)
    getter routes : Array(Route)

    def initialize(@geocoded_waypoints, @routes)
    end

    # use the StaticMap class to get a static map of the routes
    def get_static_map
      StaticMap.build do |map|
        @routes.each do |route|
          route.legs.each do |leg|
            leg.steps.each do |step|
              map.add_marker(step.start_location)
              map.add_marker(step.end_location)
              map.add_polyline(step.polyline.points)
            end
          end

          route.overview_polyline.decode.each do |latlng|
            map.add_latlng(latlng)
          end
        end
      end
    end
  end
end
