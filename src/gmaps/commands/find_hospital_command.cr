require "athena-console"
require "./base_command"
require "./hospital_command_helpers"

@[ACONA::AsCommand("find_hospital", description: "Search for hospitals by name")]
class Gmaps::FindHospitalCommand < Gmaps::BaseCommand
  include Gmaps::HospitalCommandHelpers
  private record CommandOptions,
    name : String,
    latitude : String,
    longitude : String,
    directions_filename : String,
    map_filename : String

  protected def configure : Nil
    super()
      argument("name", mode: :required, description: "Hospital name to search for")
      option("latitude", value_mode: :required, description: "Latitude coordinate")
      option("longitude", value_mode: :required, description: "Longitude coordinate")
      option("directions_filename", value_mode: :required, description: "Filename for directions")
      option("map_filename", value_mode: :required, description: "Filename for map")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = create_style(input, output)

    if input.arguments.empty?
      style.error "Hospital name argument is required"
      output.puts help
      return ACON::Command::Status::FAILURE
    end

    return ACON::Command::Status::FAILURE unless key = verify_api_key(output)
    return ACON::Command::Status::FAILURE unless options = parse_options(input)
    return ACON::Command::Status::FAILURE unless coordinates = parse_coordinates(options)

    process_hospital_search(options.name, coordinates, options, style, key, input, output)
  end

  private def parse_options(input) : CommandOptions
    CommandOptions.new(
      name: input.argument("name", String),
      latitude: input.option("latitude", String),
      longitude: input.option("longitude", String),
      directions_filename: input.option("directions_filename", String),
      map_filename: input.option("map_filename", String)
    )
  end

  private def process_hospital_search(search_term : String, coordinates, options, style, key, input, output) : ACON::Command::Status
    app = Gmaps::App.new(key)
    hospitals = app.search_hospitals_by_name(search_term, coordinates)

    if hospitals.empty?
      style.error "No hospitals found matching '#{search_term}'"
      return ACON::Command::Status::FAILURE
    end

    Log.debug { "Found #{hospitals.size} hospitals matching '#{search_term}'" }
    hospitals.each_with_index do |h, i|
      Log.debug { "Hospital #{i}: #{h.name} at #{h.latitude},#{h.longitude}" }
    end

    return handle_no_hospitals(style) unless hospital = app.ask_hospitals(hospitals, input, output)
    process_selected_hospital(hospital, coordinates, options, style, app, output)
  end
end
