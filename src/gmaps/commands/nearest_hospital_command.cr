require "athena-console"
require "./base_command"

@[ACONA::AsCommand("nearest_hospital", description: "Get nearest hospital")]
class Gmaps::NearestHospitalsCommand < Gmaps::BaseCommand
  private record CommandOptions,
    latitude : String,
    longitude : String,
    directions_filename : String,
    map_filename : String,
    retry : Bool

  protected def configure : Nil
    self
      .option("latitude", value_mode: :required, description: "Latitude coordinate")
      .option("longitude", value_mode: :required, description: "Longitude coordinate")
      .option("directions_filename", value_mode: :required, description: "Filename for directions")
      .option("map_filename", value_mode: :required, description: "Filename for map")
      .option("retry", description: "Retry with increased radius if no hospitals found")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = create_style(input, output)

    return ACON::Command::Status::FAILURE unless key = verify_api_key(output)
    return ACON::Command::Status::FAILURE unless options = parse_options(input)
    return ACON::Command::Status::FAILURE unless coordinates = parse_coordinates(options, style, key)

    process_hospital_search(coordinates, options, style, key, input, output)
  end

  private def parse_options(input) : CommandOptions
    retry_option = input.option("retry") ? true : false
    
    CommandOptions.new(
      latitude: input.option("latitude", String),
      longitude: input.option("longitude", String),
      directions_filename: input.option("directions_filename", String),
      map_filename: input.option("map_filename", String),
      retry: retry_option
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

  private def process_hospital_search(coordinates, options, style, key, input, output) : ACON::Command::Status
    app = Gmaps::App.new(key)
    base_radius = 50000.0 # 50km ≈ 31 miles
    max_radius = 160934.0 # 100 miles in meters
    current_radius = base_radius

    while current_radius <= max_radius
      hospitals = app.get_nearest_hospitals(coordinates, radius: current_radius)
      
      if hospitals.empty?
        if options.retry
          style.warning "No hospitals found within #{(current_radius/1609.34).round(1)} miles. Expanding search..."
          current_radius += 32186.9 # 20 miles in meters
          next
        else
          style.error "No hospitals found in the area. Try using --retry to expand search radius."
          return ACON::Command::Status::FAILURE
        end
      end

      Log.debug { "Found #{hospitals.size} hospitals within #{(current_radius/1609.34).round(1)} miles" }
      hospitals.each_with_index do |h, i|
        Log.debug { "Hospital #{i}: #{h.name} at #{h.latitude},#{h.longitude}" }
      end

      return handle_no_hospitals(style) unless hospital = app.ask_hospitals(hospitals, input, output)
      return process_selected_hospital(hospital, coordinates, options, style, app, output)
    end

    style.error "No hospitals found within 100 miles"
    ACON::Command::Status::FAILURE
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
