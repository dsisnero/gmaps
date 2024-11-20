require "../../spec_helper"

struct EditApiKeyCommandTest < ASPEC::TestCase
  def test_given_no_api_key : Nil
    tester = self.command_tester
    ret = tester.execute
    tester.display.should contain "Usage:"
  end

  def test_given_api_key : Nil
    tester = self.command_tester
    tester.execute ["--api-key", "a"]
    tester.display.should contain "API key updated"
  end

  private def command : GMaps::EditApiKeyCommand
    GMaps::EditApiKeyCommand.new
  end

  private def command_tester : ACON::Spec::CommandTester
    ACON::Spec::CommandTester.new self.command
  end
end
