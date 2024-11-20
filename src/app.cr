require "poncho"
require "./gmaps/client"
require "./gmaps/coordinate_parser"
require "./gmaps/directions_reporter"
require "./gmaps/config"

Log.setup_from_env(default_level: :info)

module Gmaps
  ROOT = Path["."].parent.expand

  def self.get_api_key : String?
    api_key = ENV["GMAPS_API_KEY"]? || config.gmaps_api_key
  end

  def self.config
    Config.load_from_config
  end

  class App
    Log = ::Log.for("app")

    # Client for interacting with Google Maps API
    getter client : Gmaps::Client

    # Reporter for generating directions reports
    getter reporter : Gmaps::DirectionsReporter
    # Google Maps API key
    getter api_key : String

    def initialize(api_key : String, formatter : DirectionsFormatter = AsciidocFormatter.new)
      @api_key = api_key
      @client = Gmaps::Client.new(api_key)
      @reporter = DirectionsReporter.new(formatter)
    end

    def get_route(origin : Gmaps::Locatable, destination : Gmaps::Hospital)
      response = client.generate_directions_response(origin, destination)
      if response.success?
        Gmaps::DirectionResult.from_json(response.body)
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

    def print_result(hospital : Gmaps::Hospital, direction_result : Gmaps::DirectionResult)
      print_directions_adoc(hospital, direction_result)
      print_static_map(hospital, direction_result)
    end

    def print_directions_adoc(hospital : Gmaps::Hospital, direction_result : Gmaps::DirectionResult)
      route = direction_result.routes[0]
      name = hospital_name(hospital) + ".adoc"
      Log.info { "printing file #{name}" }
      File.open(name, "w") { |io| reporter.output_report(hospital, route, io, heading_level: 3) }
    end

    def puts_asciidoc_directions(hospital : Gmaps::Hospital, direction_result : Gmaps::DirectionResult, heading_level : Int32 = 3, io : IO = STDOUT)
      route = direction_result.routes[0]
      reporter.output_report(hospital, route, io, heading_level: heading_level)
    end

    def fetch_static_map(hospital : Gmaps::Hospital, direction_result : Gmaps::DirectionResult)
      static_map = direction_result.fetch_static_map(api_key: api_key)
    end

    def print_static_map(hospital : Gmaps::Hospital, direction_result : Gmaps::DirectionResult)
      static_map = direction_result.fetch_static_map(api_key: api_key)
      if static_map
        name = hospital_name(hospital) + ".png"
        Log.info { "printing file #{name}" }
        File.write(name, static_map)
      else
        Log.info { "no static map" }
      end
    end

    def get_nearest_hospitals(coordinates : Gmaps::Locatable, radius : Float64 = 50000.0)
      client.find_nearest_hospitals(coordinates, radius)
    end

    def ask_hospitals(hospitals : Array(Gmaps::Hospital), input : ACON::Input::Interface, output : ACON::Output::Interface) : Gmaps::Hospital?
      helper = ACON::Helper::Question.new
      output.puts "Nearest hospitals sorted by distance:"
      # only output upto 5 nearest hospitals, make sure no error
      if hospitals.size > 20
        hospitals = hospitals[0...20]
      else
        hospitals = hospitals.dup
      end

      ACON::Helper::Table.new(output)
        .headers("Index", "Name", "Address", "Rating")
        .rows(hospitals.map_with_index { |h, i| [i, h.name, h.address, h.rating] })
        .render
      question = ACON::Question::Choice.new("Select hospital: ", hospitals.map(&.name), 0)
      result = helper.ask(input, output, question)
      if name = result
        if idx = hospitals.index { |h| h.name == name }
          hospitals[idx]
        else
          nil
        end
      else
        nil
      end
      # hospitals[question.selected]
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
