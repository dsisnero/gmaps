require "../key_provider"
require "athena-console"
require "./base_command"
require "../app"

@[ACONA::AsCommand("nearest_hospital", description: "Get nearest hospital")]
class Gmaps::NearestHospitalsCommand < Gmaps::BaseCommand
  private record CommandOptions,
    latitude : String,
    longitude : String,
    directions_filename : String,
    map_filename : String,
    retry : Bool

  protected def configure : Nil
    super()
    option("latitude", value_mode: :required, description: "Latitude coordinate")
    option("longitude", value_mode: :required, description: "Longitude coordinate")
    option("directions_filename", value_mode: :required, description: "Filename for directions")
    option("map_filename", value_mode: :required, description: "Filename for map")
    option("retry", description: "Retry with increased radius if no hospitals found")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = create_style(input, output)
    input.validate
    api_key = Gmaps.key_provider.get_api_key
    if api_key.nil?
      handle_no_api_key(style, input, output)
    end

    api_key = api_key.not_nil!

    return ACON::Command::Status::FAILURE unless options = parse_options(input)
    if options.latitude.empty? || options.longitude.empty?
      output.puts help
      ACON::Command::Status::FAILURE
    end
    coordinates = parse_coordinates(options)
    process_hospital_search(coordinates, options, style, api_key, input, output)
  rescue ex : ParseException
    style.not_nil!.error "Failed to parse coordinates: #{ex.message}"
    ACON::Command::Status::FAILURE
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

  private def process_hospital_search(coordinates, options, style, api_key, input, output) : ACON::Command::Status
    app = Gmaps::App.new(api_key)
    base_radius = 50000.0 # 50km ≈ 31 miles
    max_radius = 160934.0 # 100 miles in meters
    current_radius = base_radius
    begin
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
    rescue ex : NoApiKeyError
      handle_no_api_key(style, input, output)
    rescue ex : InvalidApiKeyError
      handle_invalid_api_key(style, input, output)
    end

    # Ask if user wants to search by name
    helper = ACON::Helper::Question.new
    question = ACON::Question::Confirmation.new("Would you like to search for a specific hospital or clinic by name?", true)

    if helper.ask(input, output, question)
      search_hospitals_by_name(coordinates, options, style, api_key, input, output)
    else
      style.error "No hospitals found within 100 miles"
      ACON::Command::Status::FAILURE
    end
  end

  private def search_hospitals_by_name(coordinates, options, style, key, input, output) : ACON::Command::Status
    helper = ACON::Helper::Question.new
    question = ACON::Question(String?).new("Enter hospital or clinic name to search for:", nil)

    if answer = helper.ask(input, output, question)
      search_term = answer.to_s
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
      return process_selected_hospital(hospital, coordinates, options, style, app, output)
    end

    style.error "No search term provided"
    ACON::Command::Status::FAILURE
  end
end
