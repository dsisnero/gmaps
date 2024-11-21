module Gmaps
  class Location
    include JSON::Serializable

    @[JSON::Field(key: "lat")]
    property latitude : Float64

    @[JSON::Field(key: "lng")]
    property longitude : Float64
  end

  class Place
    include JSON::Serializable

    property name : String
    property place_id : String

    @[JSON::Field(key: "geometry")]
    property _geometry : NamedTuple(location: Location)

    @[JSON::Field(key: "formatted_address")]
    property formatted_address : String?

    @[JSON::Field(key: "vicinity")]
    property vicinity : String?

    property rating : Float64?

    def location
      _geometry["location"]
    end
  end

  class PlaceQuery
    include JSON::Serializable

    property status : String
    property results : Array(Place)

    @[JSON::Field(key: "error_message")]
    property error_message : String?
  end

  class PlaceQueryName
    include JSON::Serializable

    property status : String
    property candidates : Array(Place)

    @[JSON::Field(key: "error_message")]
    property error_message : String?
  end
end
