require "json"

module Gmaps
  module Locatable
    abstract def latitude : Float64
    abstract def longitude : Float64
  end

  record LatLon, latitude : Float64, longitude : Float64 do
    include Locatable
    include JSON::Serializable

    # creates a LatLon from a tuple of Float64s
    def initialize(@latitude, @longitude)
    end
  end
end
