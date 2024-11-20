require "athena-console"
require "./base_command"

@[ACONA::AsCommand("find_hospital", description: "Search for hospitals by name")]
class Gmaps::FindHospitalCommand < Gmaps::BaseCommand
  private record CommandOptions,
    name : String,
    latitude : String,
    longitude : String,
    directions_filename : String,
    map_filename : String

  protected def configure : Nil
    self
      .argument("name", description: "Hospital name to search for", required: true)
      .option("latitude", value_mode: :required, description: "Latitude coordinate")
      .option("longitude", value_mode: :required, description: "Longitude coordinate")
      .option("directions_filename", value_mode: :required, description: "Filename for directions")
      .option("map_filename", value_mode: :required, description: "Filename for map")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = create_style(input, output)

    return ACON::Command::Status::FAILURE unless key = verify_api_key(output)
    return ACON::Command::Status::FAILURE unless options = parse_options(input)
    return ACON::Command::Status::FAILURE unless coordinates = parse_coordinates(options, style, key)

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

  private def parse_coordinates(options : CommandOptions, style, key) : LatLon?
    Log.debug { "parsing coordinates lat: #{options.latitude}, lng: #{options.longitude}" }

    app = Gmaps::App.new(key)
    coordinates = app.parse_coordinates(options.latitude, options.longitude)

    unless coordinates
      style.error "Invalid coordinates"
      return nil
    end

    coordinates
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

  private def handle_no_hospitals(style) : ACON::Command::Status
    style.error "No hospital found"
    ACON::Command::Status::FAILURE
  end

  private def process_selected_hospital(hospital, coordinates, options, style, app, output) : ACON::Command::Status
    output.puts "Getting route to hospital: #{hospital.name}"

    return handle_no_route(style) unless route = app.get_route(coordinates, hospital)

    generate_output_files(hospital, route, options, style, app)
    ACON::Command::Status::SUCCESS
  end

  private def handle_no_route(style) : ACON::Command::Status
    style.error "No route found"
    ACON::Command::Status::FAILURE
  end

  private def generate_output_files(hospital, route, options, style, app)
    name = app.hospital_name(hospital)
    direction_filename = options.directions_filename || "#{name}.adoc"
    map_filename = options.map_filename || "#{name}.png"

    generate_directions_file(direction_filename, hospital, route, style, app)
    generate_map_file(map_filename, hospital, route, style, app)
  end

  private def generate_directions_file(filename, hospital, route, style, app)
    style.success "Printing file #{filename}"
    File.open(filename, "w") do |io|
      app.puts_asciidoc_directions(hospital, route, heading_level: 3, io: io)
    end
  end

  private def generate_map_file(filename, hospital, route, style, app)
    if map = app.fetch_static_map(hospital, route)
      style.success "Printing file #{filename}"
      File.write(filename, map)
    end
  end
end
