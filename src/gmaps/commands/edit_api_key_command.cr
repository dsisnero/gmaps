@[ACONA::AsCommand("edit_api_key", description: "Edit the API key")]
class Gmaps::EditApiKeyCommand < ACON::Command
  protected def configure
    self
      .argument("gmaps_api_key", ACON::Input::Argument::Mode::REQUIRED, "API key")
  end
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    # if config_file_exists? and master_keyfile exists
    # load config_file and update api_key
    # else generate new config file and master_keyfile and update api_key
    if api_key = input.argument("gmaps_api_key", String)
      loader = ConfigLoader.new
      loader.edit_key(api_key)
      output.puts "API key updated in #{loader.config_file}"
      ACON::Command::Status::SUCCESS
    else
      output.puts "No API key provided"
      ACON::Command::Status::FAILURE
    end
  end
end



      #   config = Gmaps::Config.from_yaml(config_file_path)
      #   config.api_key = input.get_argument("api_key").as_s
      #   config.save
      # else
      #   config = Gmaps::Config.new
