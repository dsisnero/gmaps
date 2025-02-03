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
end
