require "../../spec_helper"
require "../../../src/gmaps/commands/edit_api_key_command"

struct EditApiKeyCommandTest < ASPEC::TestCase
  class MockConfigLoader < Gmaps::ConfigLoader
    property last_edited_key : String?
    property last_edited_value : String?

    def edit_key(key : String, value : String)
      @last_edited_key = key
      @last_edited_value = value
    end
  end

  def test_given_no_api_key : Nil
    api_key = Gmaps.key_provider.get_api_key
    tester = command_tester
    tester.execute interactive: true
    tester.display.should contain "Need to provide argument 'api_key'"
  end

  def test_given_api_key : Nil
    mock_loader = MockConfigLoader.new
    command = Gmaps::EditApiKeyCommand.new
    command.config_loader = mock_loader

    tester = ACON::Spec::CommandTester.new(command)
    provided_key = "a"

    tester.execute interactive: true, api_key: provided_key

    tester.display.should contain "API key updated"
    mock_loader.last_edited_key.should eq "GMAPS_API_KEY"
    mock_loader.last_edited_value.should eq provided_key
  end

  private def command : Gmaps::EditApiKeyCommand
    Gmaps::EditApiKeyCommand.new
  end

  private def command_tester : ACON::Spec::CommandTester
    ACON::Spec::CommandTester.new command
  end
end
