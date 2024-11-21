require "../../spec_helper"

require "../../../src/gmaps/commands/edit_api_key_command"

struct EditApiKeyCommandTest < ASPEC::TestCase
  def test_given_no_api_key : Nil
    tester = self.command_tester
    ret = tester.execute
    tester.display.should contain "Usage:"
  end

  def test_given_api_key : Nil
    tester = self.command_tester
    tester.execute gmaps_api_key: "a"
    tester.display.should contain "API key updated"
  end

  private def command : Gmaps::EditApiKeyCommand
    Gmaps::EditApiKeyCommand.new
  end

  private def command_tester : ACON::Spec::CommandTester
    ACON::Spec::CommandTester.new self.command
  end
end
