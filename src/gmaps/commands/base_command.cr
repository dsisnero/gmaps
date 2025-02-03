require "athena-console"
require "../key_provider"
require "./hospital_command_helpers"

module Gmaps
  abstract class BaseCommand < ACON::Command
    include Gmaps::HospitalCommandHelpers

    protected def create_style(input, output)
      ACON::Style::Athena.new(input, output)
    end

    protected def configure : Nil
              self.option("api_key", value_mode: :required, description: "API key")
    end
  end
end
