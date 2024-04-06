require "json"

module Gmaps
  struct Coordinates
    include JSON::Serializable
    getter lat
    getter lng

    def initialize(@lat, @lng)
    end
  end

  struct Location
    include JSON::Serializable
    @[JSON::Field(key: "lat")]
    getter latitude : Float64

    @[JSON::Field(key: "lng")]
    getter longitude : Float64

    @[JSON::Field(key: next_page_token)]

    def initialize(@latitude, @longitude)
    end
  end

  struct NorthEast
    include JSON::Serializable
    @[JSON::Field(key: "lat")]
    getter latitude : Float64

    @[JSON::Field(key: "lng")]
    getter longitude : Float64

    def initialize(@latitude, @longitude)
    end
  end

  struct SouthWest
    include JSON::Serializable
    @[JSON::Field(key: "lat")]
    getter latitude : Float64

    @[JSON::Field(key: "lng")]
    getter longitude : Float64

    def initialize(@latitude, @longitude)
    end
  end

  struct Viewport
    include JSON::Serializable
    getter northeast : NorthEast
    getter southwest : SouthWest

    def initialize(@northeast, @southwest)
    end
  end

  struct Geometry
    include JSON::Serializable
    getter location : Location
    getter viewport : Viewport

    def initialize(@location, @viewport)
    end
  end

  struct Place
    # getter geometry : Geometry
    include JSON::Serializable
    include JSON::Serializable::Unmapped
    getter place_id : String
    getter vicinity : String
    getter name : String
    getter rating : Float64?
    getter geometry : Gmaps::Geometry

    def initialize(@place_id, @vicinity, @name, @geometry, @rating)
    end

    def location
      geometry.location
    end

    def viewport
      geometry.viewport
    end
  end

  struct PlaceQuery
    include JSON::Serializable

    # getter results : Array(Place){ [] of Place}

    getter status : String
    getter next_page_token : String?

    getter results : Array(Gmaps::Place)

    # def initialize(@next_page_token, @results, @status)
    # end
    def initialize(@next_page_token, @status, @results)
    end
  end
end
