require "poncho"
require "option_parser"
require "log"
require "./gmaps/coordinate_parser"
require "./gmaps/client"

def print_help(parser : OptionParser)
  puts parser
end

ROOT = Path["."].parent

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

def parse_coordinates(lat : String?, lng : String?)
  coordinates = Gmaps::CoordinateParser.parse_lat_lng(lat, lng)
end

begin
  parser.parse
  Log.debug { "after options parse lat: #{latitude}, lng: #{longitude}" }
  coordinates = parse_coordinates(latitude, longitude)
  if coordinates
    Log.debug { "Coordinates parsed correctly" }
    client = Gmaps::Client.new(api_key)
    hospitals = client.find_nearest_hospitals(coordinates.latitude, coordinates.longitude)

    # Get the two nearest hospitals
    if hospitals.size > 0
      nearest_hospitals = hospitals[0, 2]

      # Generate map URLs with driving directions for each hospital
      map_urls = nearest_hospitals.map do |hospital|
        # {hospital, client.generate_directions_response(coordinates.latitude, coordinates.longitude, hospital.latitude, hospital.longitude) }
        {hospital, client.generate_directions_response(coordinates, hospital)}
      end

      hospitals.each(&.display)

      # Print the URLs
      map_urls.each_with_index do |(hosp, resp), _|
        File.write(hosp.name.downcase.gsub(" ", "_"), resp.body)
        puts hosp.name
      end
    end
  else
    puts "No coordinates"
  end
rescue e : Gmaps::ParseException
  Log.error { e.message }
  puts parser
  exit(1)
end
