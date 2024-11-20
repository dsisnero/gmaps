require "athena-console"

module Gmaps
  abstract class BaseCommand < ACON::Command
    protected def create_style(input, output)
      ACON::Style::Athena.new(input, output)
    end

    protected def verify_api_key(output) : String?
      key = Gmaps.get_api_key
      unless key
        output.puts "No API key found. Please run `gmaps edit_api_key`"
        return nil
      end
      key
    end
  end
end
