require "spec"
require "../../src/gmaps/location_result"

def create_json_string
  str = <<-JSON
    {
      "html_attributes": [],
      "next_page_token": "the_next_page_token",
      "results":
      [
        {
          "geometry":
          {
            "location":
            {
              "lat": 40.778402,
              "lng": -111.87937
            },
            "viewport":
            {
              "northeast":
              {
                "lat": 40.78210855000001,
                "lng": -111.8782821
              },
              "southwest":
              {
                "lat": 40.77675,
                "lng": -111.8813101
              }
            }
          },
          "place_id":  "the_place_id",
          "vicinity": "the_vicinity",
          "name": "the_name"
        }

      ],
      "status": "OK"

    }
    JSON
end

def create_place_string
  json = <<-JSON
        {
        "geometry":
          {
            "location":
            {
              "lat": 40.778402,
              "lng": -111.87937
            },
            "viewport":
            {
              "northeast":
              {
                "lat": 40.78210855000001,
                "lng": -111.8782821
              },
              "southwest":
              {
                "lat": 40.77675,
                "lng": -111.8813101
              }
            }
          },
          "place_id":  "the_place_id",
          "vicinity": "the_vicinity",
          "name": "the_name"
        }
        JSON
end

describe Gmaps::Place do
  # it "serializes correctly" do
  # place1 = Gmaps::Place.from_json(%({"place_id": "the_id", "name": "the_name", "vicinity": "the_vicinity"}))
  # place2 = Gmaps::Place.from_json(place1.to_json)
  # place1.should eq place2
  # end

  it "parses string correctly" do
    json = create_place_string
    place = Gmaps::Place.from_json(json)
    place.name.should eq "the_name"
    place.place_id.should eq "the_place_id"
    geometry = place.geometry
    loc = geometry.location
    loc.latitude.should eq(40.778402)
    loc.longitude.should eq(-111.87937)
    vp = geometry.viewport
    vp.northeast.latitude.should eq(40.78210855000001)
  end
end

describe Gmaps::PlaceQuery do
  it "parses a result string correctly" do
    json = create_json_string
    place = Gmaps::PlaceQuery.from_json(json)
    place.status.should eq "OK"
    place.next_page_token.should eq "the_next_page_token"
  end
end
