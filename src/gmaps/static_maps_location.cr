# Container to hold a location either by latitude and longitude or an address
# Latitude and longitude will be checked for validity, addresses won't.
struct StatikMapsLocation
  property latitude : Float64?
  property longitude : Float64?
  property address : String?

  def initialize(@latitude : Float64? = nil, @longitude : Float64? = nil, @address : String? = nil)
    # Require coordinates to be set and in their valid ranges or an address to be set
    raise "A location must be specified by latitude and longitude or a valid address" unless (latitude && longitude) || address
    raise "A location can't be specified by coordinates and an address" unless (latitude && !address) || (!latitude && !longitude && address)
    raise "Latitude must be between -90 and 90, longitude between -180 and 180" unless address || (latitude && longitude && latitude.between?(-90.0, 90.0) && longitude.between?(-180.0, 180.0))
  end

  def to_s
    address || "#{latitude},#{longitude}"
  end
end

# Creates a StatikMapsLocation from a Tuple of Float64
def to_location(pair : Tuple(Float64, Float64)) : StatikMapsLocation
  StatikMapsLocation.new(pair.first, pair.second)
end

# Creates a list of StatikMapsLocation from a list of Tuples of Float64
def to_locations(pairs : Array(Tuple(Float64, Float64))) : Array(StatikMapsLocation)
  pairs.map { |pair| to_location(pair) }
end

# Converts a list of StatikMapsLocations to a valid URL parameter string
def to_url_param(locations : Array(StatikMapsLocation)) : String
  locations.map(&.to_s).join('|')
end
