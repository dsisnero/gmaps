require "../../spec_helper"

require "../../../src/gmaps/commands/nearest_hospital_command"

struct NearestHospitalsCommandTest < ASPEC::TestCase
  def test_given_no_lat_and_lng : Nil
    tester = self.command_tester
    ret = tester.execute
    tester.display.should contain "Usage:"
  end

  def test_given_lat_and_lng_in_wrong_format : Nil
    tester = self.command_tester
    ret = tester.execute({"--latitude" => "a", "--longitude" => "b"})
    ret.should eq ACON::Command::Status::FAILURE
    tester.display.should contain "Failed to parse coordinates"
  end

  def test_given_lat_and_lng_with_correct_format : Nil
    tester = self.command_tester
    tester.execute({"--latitude" => "40d52m30sN", "--longitude" => "111d51m7sW"})
    tester.display.should contain "Nearest hospitals:"
    tester.inputs = ["1"]
    tester.display.should contain "Getting the file"
    puts tester.display
  end

  private def command : Gmaps::NearestHospitalsCommand
    Gmaps::NearestHospitalsCommand.new
  end

  private def command_tester : ACON::Spec::CommandTester
    ACON::Spec::CommandTester.new self.command
  end
end
