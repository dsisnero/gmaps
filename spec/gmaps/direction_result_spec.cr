require "./../spec_helper"
require "./../../src/gmaps/direction_result"

module Gmaps
describe Gmaps::DirectionResult do

  it "parses result correctly" do
    json = File.read("spec/testdata/direction_result.json")
    result = DirectionResult.from_json(json)
    result.geocoded_waypoints.size.should eq(2)
    result.geocoded_waypoints[0].place_id.should eq("ChIJnykGkXRYUocRD1MgHH_zs60")
    result.routes.should be_a(Array(Route))
  end

end

end
