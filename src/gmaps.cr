require "./gmaps/key_provider"
require "./gmaps/app"
require "athena-console"
# require "option_parser"
require "./gmaps/commands/edit_api_key_command"
require "./gmaps/commands/nearest_hospital_command"
require "./gmaps/commands/find_hospital_command"
require "./gmaps/commands/get_satellite_image_command"

begin
  application = ACON::Application.new "GMaps"

  application.add Gmaps::NearestHospitalsCommand.new
  application.add Gmaps::EditApiKeyCommand.new
  application.add Gmaps::FindHospitalCommand.new
  application.add Gmaps::GetSatelliteImageCommand.new

  exit_code = application.run
  exit(exit_code.to_i)
rescue ex : Exception
  STDERR.puts ex.message
  exit(1)
end
