require "poncho"
require "option_parser"
require "log"
require "./gmaps/coordinate_parser"
require "./gmaps/app"
# require "./gmaps/client"

ROOT = Path["."].parent.expand

def print_help(parser : OptionParser)
  puts parser
end

def get_api_key
  api_key = ENV["API_KEY"]?

  unless api_key
    poncho = Poncho.from_file (ROOT / ".env").expand.to_s
    api_key = poncho["HOSPITAL_APP_KEY"]?
  end

  if api_key.nil? || api_key.empty?
    puts "Error: API_KEY environment variable is missing."
    puts "Please set the API_KEY environment variable before running the program."
    exit(1)
  end
  api_key
end

latitude = ""
longitude = ""

parser = OptionParser.new do |parser|
  parser.banner = "Usage: crystal nearest_hospitals.cr [options] [latitude] [longitude]"

  parser.on("-h", "--help", "Show help") do
    puts parser
    exit(0)
  end

  parser.on("-v", "--version", "Show version") do
    puts "GMaps Crystal 1.0"
    exit(0)
  end

  parser.on("-lat LAT", "--latitude=LAT", "Latitude coordinate") do |lat|
    latitude = lat
  end

  parser.on("-lng LNG", "--longitude=LNG", "Longitude coordinate") do |lng|
    longitude = lng
  end
end

def get_route(origin : Gmaps::LatLon, destination : Gmaps::Hospital)
  response = client.generate_directions_response(origin, destination)
  if response.success?
    result = Gmaps::DirectionResult.from_json(response.body)
    {hospital, result.routes[0]}
  end
end

begin
  parser.parse
  Log.debug { "after options parse lat: #{latitude}, lng: #{longitude}" }
  key = get_api_key
  app = Gmaps::App.new(key)

  coordinates = app.parse_coordinates(latitude, longitude)
  if coordinates
    app.run(coordinates)
  else
    puts "No coordinates"
  end
rescue e : Gmaps::ParseException
  Log.error { e.message }
  puts parser
  exit(1)
end
