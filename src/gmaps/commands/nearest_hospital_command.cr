require "athena-console"
@[ACONA::AsCommand("nearest_hospital", description: "Get nearest hospital")]
class Gmaps::NearestHospitalsCommand < ACON::Command
  protected def configure : Nil
    self
      .option("latitude",  value_mode: :required, description: "Latitude coordinate")
      .option("longitude",  value_mode: :required,  description: "Longitude coordinate")
      .option("directions_filename",  value_mode: :required,  description: "Filename for directions")
      .option("map_filename",  value_mode: :required,  description: "Filename for map")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = ACON::Style::Athena.new(input, output)
    latitude = input.option("latitude", String)
    longitude = input.option("longitude", String)

    Log.debug { "after options parse lat: #{latitude}, lng: #{longitude}" }
    key = Gmaps.get_api_key
    unless key
      output.puts "No API key found. Please run `gmaps edit_api_key`"
      return ACON::Command::Status::FAILURE
    end
    app = Gmaps::App.new(key)

    coordinates = app.parse_coordinates(latitude, longitude)
    if coordinates
      hospitals = app.get_nearest_hospitals(coordinates)
      if hospital = app.ask_hospitals(hospitals, input, output)
        output.puts "Getting route to hospital: #{hospital.name}"
        if route = app.get_route(coordinates, hospital)
          name = app.hospital_name(hospital)
          direction_filename = "#{name}.adoc"
          map_filename = "#{name}.png"
          # direction_filename = if input_name = input.option("directions_filename", String)
          #                      input_name
          #                      end
          style.success "Printing file #{direction_filename.not_nil!}"
          File.open(direction_filename.not_nil!, "w") { |io| app.puts_asciidoc_directions(hospital, route, heading_level: 3, io: io) }
          if map = app.fetch_static_map(hospital, route)
             # map_filename = input.option("map_filename", String) || "#{name}.png"
             style.success "Printing file #{map_filename}"
             File.write(map_filename, map)
          end
          ACON::Command::Status::SUCCESS
        else
          style.error "No route found"
          return ACON::Command::Status::FAILURE
        end
      else
        style.error "No hospital found"
        return ACON::Command::Status::FAILURE
      end
    else
      style.error "Invalid coordinates"
      ACON::Command::Status::FAILURE
    end
  end
end
