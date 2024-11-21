require "athena-console"
require "./base_command"

@[ACONA::AsCommand("get_satellite_image", description: "Get a satellite image for a specific location")]
class Gmaps::GetSatelliteImageCommand < Gmaps::BaseCommand
  private record CommandOptions,
    latitude : String,
    longitude : String,
    radius : Int32,
    output_file : String

  protected def configure : Nil
    self
      .option("latitude", value_mode: :required, description: "Latitude coordinate")
      .option("longitude", value_mode: :required, description: "Longitude coordinate")
      .option("radius", value_mode: :optional, description: "Radius in meters (default: 1000)")
      .option("output", value_mode: :required, description: "Output filename for the satellite image")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = create_style(input, output)
    
    return ACON::Command::Status::FAILURE unless key = verify_api_key(output)
    return ACON::Command::Status::FAILURE unless options = parse_options(input)
    return ACON::Command::Status::FAILURE unless coordinates = parse_coordinates(options, style)

    begin
      client = Gmaps::Client.new(key)
      image_data = client.get_satellite_image(
        coordinates.latitude,
        coordinates.longitude,
        options.radius
      )

      File.write(options.output_file, image_data)
      style.success "Satellite image saved to #{options.output_file}"
      ACON::Command::Status::SUCCESS
    rescue ex
      style.error "Failed to get satellite image: #{ex.message}"
      ACON::Command::Status::FAILURE
    end
  end

  private def parse_options(input) : CommandOptions
    CommandOptions.new(
      latitude: input.option("latitude", String),
      longitude: input.option("longitude", String),
      radius: input.option("radius", String, "1000").to_i,
      output_file: input.option("output", String)
    )
  end

  private def parse_coordinates(options, style) : Gmaps::LatLon?
    begin
      lat = options.latitude.to_f64
      lon = options.longitude.to_f64
      Gmaps::LatLon.new(lat, lon)
    rescue ex
      style.error "Invalid coordinates. Please provide valid latitude and longitude values."
      nil
    end
  end
end
