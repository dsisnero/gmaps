require "./app"
require "athena-console"
require "option_parser"
require "./gmaps/commands/edit_api_key_command"
require "./gmaps/commands/nearest_hospital_command"
require "./gmaps/commands/find_hospital_command"

begin
  application = ACON::Application.new "GMaps"

  application.add Gmaps::NearestHospitalsCommand.new
  application.add Gmaps::EditApiKeyCommand.new
  application.add Gmaps::FindHospitalCommand.new

  exit_code = application.run
  exit(exit_code.to_i)
rescue ex : Exception
  STDERR.puts ex.message
  exit(1)
end
# require "log"
#
# # require "./gmaps/client"
#
# def print_help(parser : OptionParser)
#   puts parser
# end
#
# latitude = ""
# longitude = ""
#
# parser = OptionParser.new do |parser|
#   parser.banner = "Usage: crystal nearest_hospitals.cr [options] [latitude] [longitude]"
#
#   parser.on("-h", "--help", "Show help") do
#     puts parser
#     exit(0)
#   end
#
#   parser.on("-v", "--version", "Show version") do
#     puts "GMaps Crystal 1.0"
#     exit(0)
#   end
#
#   parser.on("-lat LAT", "--latitude=LAT", "Latitude coordinate") do |lat|
#     latitude = lat
#   end
#
#   parser.on("-lng LNG", "--longitude=LNG", "Longitude coordinate") do |lng|
#     longitude = lng
#   end
# end
#
# def get_route(origin : Gmaps::LatLon, destination : Gmaps::Hospital)
#   response = client.generate_directions_response(origin, destination)
#   if response.success?
#     result = Gmaps::DirectionResult.from_json(response.body)
#     {hospital, result.routes[0]}
#   end
# end
#
# begin
#   parser.parse
#   Log.debug { "after options parse lat: #{latitude}, lng: #{longitude}" }
#   key = Gmaps.get_api_key
#   app = Gmaps::App.new(key)
#
#   coordinates = app.parse_coordinates(latitude, longitude)
#   if coordinates
#     app.run(coordinates)
#   else
#     puts "No coordinates"
#   end
# rescue e : Gmaps::ParseException
#   Log.error { e.message }
#   puts parser
#   exit(1)
# end
