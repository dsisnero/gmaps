require "./base_command"
@[ACONA::AsCommand("edit_api_key", description: "Edit the API key")]
class Gmaps::EditApiKeyCommand < Gmaps::BaseCommand
  property config_loader : ConfigLoader = ConfigLoader.new

  def configure : Nil
    argument("api_key", mode: :required, description: "Gmaps api key")
  end

  def interact(input : ACON::Input::Interface, output : ACON::Output::Interface)
     style = create_style(input,output)
     if input.has_argument?("api_key")
       style.puts "Api key given"
     else
       style.puts "No Api key given"
     raise Gmaps::NoApiKeyError.new unless input.has_argument?("api_key")
    end

        
  end
      

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = create_style(input,output)
    begin
    input.validate
    rescue ex      
       style.not_nil! ex.not_nil!.message
        ACON::Command::Status::FAILURE
    end
    style = create_style(input, output)
    api_key = input.argument("api_key", String)
      @config_loader.edit_key("GMAPS_API_KEY", api_key)
      style.puts "API key updated in #{@config_loader.config_file}"
      ACON::Command::Status::SUCCESS
    rescue ex : NoApiKeyError
        style.not_nil! "need to provide argument 'api_key'"
        ACON::Command::Status::FAILURE
    rescue ex
       style.not_nil! ex.not_nil!.message
        ACON::Command::Status::FAILURE
    end

end
