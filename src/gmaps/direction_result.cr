require "json"

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

  record LatLon, lat : Float64, lng : Float64 do
    include JSON::Serializable

    def latitude
      @lat
    end

    def longitude
      @lng
    end

  end

  struct GeoBounds
  include JSON::Serializable
    getter northeast : LatLon
    getter southwest : LatLon

    def initialize(@northeast, @southwest)
    end
  end

  struct Leg
    include JSON::Serializable

    getter distance : StepValue

    getter duration : StepValue

    getter end_address : String

    getter end_location : LatLon

    getter start_address : String

    getter start_location : LatLon

    getter steps : Array(Step)

    def initialize(@distance, @duration, @end_address, @end_location, @start_address, @start_location, @steps)
    end

    def print_leg(io : IO | String , heading_level : Int32 = 4)
      io << "=" * heading_level + " Directions\n\n"
      io << "Starting Address: #{start_address}\n"
      io << "Ending Address: #{ending_address}\n"
      io << "Distance: #{distance}"
      print_steps(io)
    end

    def print_steps(io)
      steps.each do |step|
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

    getter end_location : LatLon

    getter html_instructions : String

    getter polyline : Polyline

    getter start_location : LatLon

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
  end
end
