require "../coordinate_parser"

module Gmaps
  module HospitalCommandHelpers
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

    def verify_api_key(output) : String?
      if key = ENV["GOOGLE_MAPS_API_KEY"]
        key
      else
        output.puts help
        nil
      end
    end

    private def handle_no_api_key(style, input, output) : ACON::Command::Status
      style.error "No API key provided"
      output.puts help
      ACON::Command::Status::FAILURE
    end

    private def handle_invalid_api_key(style, input, output) : ACON::Command::Status
      style.error "Invalid API key provided"
      output.puts help
      ACON::Command::Status::FAILURE
    end

    private def generate_output_files(hospital, route, options, style, app)
      name = app.hospital_name(hospital)
      direction_filename = options.directions_filename
      if direction_filename.nil? || direction_filename.empty?
        direction_filename = "#{name}.adoc"
      end
      map_filename = options.map_filename
      if map_filename.nil? || map_filename.empty?
        map_filename = "#{name}.png"
      end
      generate_directions_file(direction_filename, hospital, route, style, app)
      generate_map_file(map_filename, hospital, route, style, app)
    end

    private def generate_directions_file(filename, hospital, route, style, app)
      style.success "Printing directions file #{filename}"
      File.open(filename, "w") do |io|
        app.puts_asciidoc_directions(hospital, route, heading_level: 3, io: io)
      end
    end

    private def generate_map_file(filename, hospital, route, style, app)
      if map = app.fetch_static_map(hospital, route)
        style.success "Printing map file #{filename}"
        File.write(filename, map)
      end
    end

    private def parse_coordinates(options) : LatLon?
      Log.debug { "parsing coordinates for #{options}\nlat: #{options.latitude}, lng: #{options.longitude}" }
      coordinates = Gmaps::CoordinateParser.parse_lat_lng(options.latitude, options.longitude)
    end
  end
end
