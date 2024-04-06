require "./client"
require "./directions_reporter"

module Gmaps
  class App
    Log = ::Log.for("app")

    getter client : Gmaps::Client
    getter reporter : Gmaps::DirectionsReporter

    def initialize(api_key : String, formatter : DirectionsFormatter = AsciidocFormatter.new)
      @client = Gmaps::Client.new(api_key)
      @reporter = DirectionsReporter.new(formatter)
    end

    def get_route(origin : Gmaps::Locatable, destination : Gmaps::Hospital)
      response = client.generate_directions_response(origin, destination)
      if response.success?
        result = Gmaps::DirectionResult.from_json(response.body)
        return {destination, result.routes[0]}
      else
        raise "couldn't get route for #{destination.name}: "
        File.write("route_response.json", response.body)
      end
    rescue e
      Log.info { "error getting result" }
      File.write("route_response.json", response.not_nil!.body)
      raise "error in DirectionResult \n#{e.message}"
    end

    def parse_coordinates(lat : String?, lng : String?)
      coordinates = Gmaps::CoordinateParser.parse_lat_lng(lat, lng)
    end

    def print_result(hospital_result)
      if hospital_result
        hospital, route = hospital_result
        name = hospital.name.downcase.gsub(" ", "_") + ".adoc"
        Log.info { "printing file #{name}" }
        File.open(name, "w") { |io| reporter.output_report(hospital.name, route, io) }
      end
    end

    def run(coordinates : Gmaps::Locatable)
      hospitals = client.find_nearest_hospitals(coordinates)
      if hospitals.size > 0
        nearest_hospitals = hospitals[0, 2]
        hospitals_and_routes = nearest_hospitals.map { |i| get_route(coordinates, i) }
        hospitals_and_routes.each do |pair|
          print_result(pair)
        end
      end
    end
  end
end
