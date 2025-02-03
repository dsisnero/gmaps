require "../../spec_helper"

require "../../../src/gmaps/commands/edit_api_key_command"

struct EditApiKeyCommandTest < ASPEC::TestCase
  def test_given_no_api_key : Nil
    api_key = Gmaps.key_provider.get_api_key
    tester = self.command_tester
    expect_raises(ACON::Exceptions::ValidationFailed, "gmaps_api_key") { tester.execute }
    Gmaps.key_provider.get_api_key.should eq api_key
  end

  def test_given_api_key : Nil
    orig_key = Gmaps.key_provider.get_api_key
    tester = self.command_tester
    provided_key = "a"
    tester.execute gmaps_api_key: provided_key
    tester.display.should contain "API key updated"
    new_key = Gmaps.key_provider.get_api_key
    new_key.should eq provided_key
    tester.execute gmaps_api_key: orig_key
  end

  private def command : Gmaps::EditApiKeyCommand
    Gmaps::EditApiKeyCommand.new
  end

  private def command_tester : ACON::Spec::CommandTester
    ACON::Spec::CommandTester.new self.command
  end
end
