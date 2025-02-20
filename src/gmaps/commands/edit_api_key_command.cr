require "./base_command"
@[ACONA::AsCommand("edit_api_key", description: "Edit the API key")]
class Gmaps::EditApiKeyCommand < Gmaps::BaseCommand
  property config_loader : ConfigLoader = ConfigLoader.new

  def configure : Nil
    argument("api_key", mode: :optional, description: "Gmaps api key")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = create_style(input, output)
    api_key = input.argument("api_key", String?)
    if !api_key || api_key.empty?
      style.error "Need to provide argument 'api_key'"
      ACON::Command::Status::FAILURE
    else
      @config_loader.edit_key("GMAPS_API_KEY", api_key)
      style.success "API key updated in #{@config_loader.config_file}"
      ACON::Command::Status::SUCCESS
    end
  end
end
