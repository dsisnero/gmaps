@[ACONA::AsCommand("edit_api_key", description: "Edit the API key")]
class Gmaps::EditApiKeyCommand < ACON::Command
  property config_loader : ConfigLoader = ConfigLoader.new
  
  protected def configure
    self
      .argument("gmaps_api_key", ACON::Input::Argument::Mode::REQUIRED, "API key")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    api_key = input.argument("gmaps_api_key", String)
    @config_loader.edit_key("GMAPS_API_KEY", api_key)
    output.puts "API key updated in #{@config_loader.config_file}"
    ACON::Command::Status::SUCCESS
  end
end

#   config = Gmaps::Config.from_yaml(config_file_path)
#   config.api_key = input.get_argument("api_key").as_s
#   config.save
# else
#   config = Gmaps::Config.new
