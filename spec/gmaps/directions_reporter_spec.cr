require "./../spec_helper"
require "./../../src/gmaps/directions_reporter"

module Gmaps
  class MockReporter < Gmaps::DirectionsFormatter
    def output_report(route : Gmaps::Route, io : String | IO, heading_level : Int32 = 1)
      io << "My Report"
    end
  end

  describe Gmaps::DirectionsReporter do
    it "can be instanciated with different reporters" do
      route = get_route
      hospital = create_hospital
      reporter = DirectionsReporter.new(MockReporter.new)
      io = String.build do |str|
        reporter.output_report(hospital: hospital, route: route, io: str)
      end
      io.should eq "My Report"
    end

    it "can create a ASCIIdoc report" do
      route = get_route
      hospital = create_hospital
      reporter = DirectionsReporter.new(AsciidocFormatter.new)
      result = String.build do |str|
        reporter.output_report(hospital: hospital, route: route, io: str)
      end
      puts result
    end
  end
end

private def get_route
  json = File.read("spec/testdata/direction_result.json")
  result = Gmaps::DirectionResult.from_json(json)
  result.routes[0]
end

private def create_hospital
  Gmaps::Hospital.new("test", "test", 0.0, 0.0, "test")
end
