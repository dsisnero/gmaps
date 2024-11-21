require "athena-console"
require "./base_command"

@[ACONA::AsCommand("get_satellite_image", description: "Get a satellite image for a specific location")]
class Gmaps::GetSatelliteImageCommand < Gmaps::BaseCommand
  private record CommandOptions,
    latitude : String,
    longitude : String,
    zoom : Int32,
    output_file : String

  protected def configure : Nil
    self
      .option("latitude", value_mode: :required, description: "Latitude coordinate")
      .option("longitude", value_mode: :required, description: "Longitude coordinate")
      .option("zoom", value_mode: :optional, description: "Zoom level (1-20, default: 19)", default: "19")
      .option("output", value_mode: :required, description: "Output filename for the satellite image")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = create_style(input, output)

    return ACON::Command::Status::FAILURE unless key = verify_api_key(output)
    return ACON::Command::Status::FAILURE unless options = parse_options(input)
    begin
      parsed_coordinates = parse_coordinates(options, style)
    rescue ex : ParseException
      style.error "Failed to parse coordinates: #{ex.message}"
      return ACON::Command::Status::FAILURE
    end

    coordinates = parsed_coordinates.not_nil!

    # Validate zoom level
    zoom = options.zoom
    unless (1..20).includes?(zoom)
      style.error "Zoom level must be between 1 and 20"
      return ACON::Command::Status::FAILURE
    end

    begin
      client = Gmaps::Client.new(key)
      image_data = client.get_satellite_image(
        coordinates.latitude,
        coordinates.longitude,
        zoom: zoom
      )

      File.write(options.output_file, image_data)
      style.success "Satellite image saved to #{options.output_file} (zoom level: #{zoom})"
      ACON::Command::Status::SUCCESS
    rescue ex
      style.error "Failed to get satellite image: #{ex.message}"
      ACON::Command::Status::FAILURE
    end
  end

  private def parse_options(input) : CommandOptions
    input.validate

    CommandOptions.new(
      latitude: input.option("latitude", String),
      longitude: input.option("longitude", String),
      output_file: input.option("output", String),
      zoom: input.option("zoom", Int32)
    )
  end
end
