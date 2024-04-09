require "poncho"
require "./gmaps/client"
require "./gmaps/coordinate_parser"
require "./gmaps/directions_reporter"

module Gmaps
  ROOT = Path["."].parent.expand

  def self.get_api_key
    api_key = ENV["API_KEY"]?

    unless api_key
      poncho = Poncho.from_file (ROOT / ".env").expand.to_s
      api_key = poncho["HOSPITAL_APP_KEY"]?
    end

    if api_key.nil? || api_key.empty?
      puts "Error: API_KEY environment variable is missing."
      puts "Please set the API_KEY environment variable before running the program."
      exit(1)
    end
    api_key
  end

  class App
    Log = ::Log.for("app")

    getter client : Gmaps::Client
    getter reporter : Gmaps::DirectionsReporter
    getter api_key : String

    def initialize(api_key : String, formatter : DirectionsFormatter = AsciidocFormatter.new)
      @api_key = api_key
      @client = Gmaps::Client.new(api_key)
      @reporter = DirectionsReporter.new(formatter)
    end

    def get_route(origin : Gmaps::Locatable, destination : Gmaps::Hospital)
      response = client.generate_directions_response(origin, destination)
      if response.success?
        result = Gmaps::DirectionResult.from_json(response.body)
        return {destination, result}
      else
        Log.error { "couldn't get route for #{destination.name}" }
        raise "couldn't get route for #{destination.name}: "
        File.write("route_response.json", response.body)
      end
    rescue e
      error_message = "error getting result for #{destination.name}:\n#{e.message}"
      Log.error { error_message }

      File.write("route_response.json", response.not_nil!.body)
      raise error_message
    end

    def parse_coordinates(lat : String?, lng : String?)
      coordinates = Gmaps::CoordinateParser.parse_lat_lng(lat, lng)
    end

    def print_result(hospital_result)
      if hospital_result
        print_directions_adoc(hospital_result)
        print_static_map(hospital_result)
      end
    end

    def print_directions_adoc(hospital_result)
      hospital, direction_result = hospital_result
      route = direction_result.routes[0]
      name = hospital_name(hospital) + ".adoc"
      Log.info { "printing file #{name}" }
      File.open(name, "w") { |io| reporter.output_report(hospital, route, io, heading_level: 3) }
    end

    def print_static_map(hospital_result)
      hospital, direction_result = hospital_result
      static_map = direction_result.fetch_static_map(api_key: api_key)
      if static_map
        name = hospital_name(hospital) + ".png"
        Log.info { "printing file #{name}" }
        File.write(name, static_map)
      else
        Log.info { "no static map" }
      end
    end

    def hospital_name(hospital : Gmaps::Hospital)
      hospital.name.downcase.gsub(" ", "_")
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
