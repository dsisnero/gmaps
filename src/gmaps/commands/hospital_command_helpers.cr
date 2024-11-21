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

    private def parse_coordinates(options, style) : LatLon?
      Log.debug { "parsing coordinates for #{options}\nlat: #{options.latitude}, lng: #{options.longitude}" }
      coordinates = Gmaps::CoordinateParser.parse_lat_lng(options.latitude, options.longitude)
    end
  end
end
