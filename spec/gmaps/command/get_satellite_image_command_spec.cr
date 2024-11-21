require "../../spec_helper"
require "../../../src/gmaps/commands/get_satellite_image_command"

struct GetSatelliteImageCommandTest < ASPEC::TestCase
  def test_given_lat_and_lng_with_correct_format
    tempfile = File.tempfile("satellite_test.png")
    tester = self.command_tester

    ret = tester.execute({"--latitude" => "40.7128", "--longitude" => "-74.0060", "--output" => tempfile.path})

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "Satellite image saved to"
    File.exists?(tempfile.path).should be_true
    File.size(tempfile.path).should be > 0
  end

  def test_given_lat_and_lng_in_wrong_format : Nil
    tester = self.command_tester
    ret = tester.execute({"--latitude" => "a", "--longitude" => "b"})
    ret.should eq ACON::Command::Status::FAILURE
    tester.display.should contain "Failed to parse coordinates"
  end

  def accepts_custom_radius
    tempfile = File.tempfile("satellite_test_wide.png")
    tester = self.command_tester
    tester.inputs = ["--latitude", "40.7128", "--longitude", "-74.0060", "--radius", "5000", "--output", tempfile.path]

    ret = tester.execute

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "Satellite image saved to"
    File.exists?(tempfile.path).should be_true
    File.size(tempfile.path).should be > 0
  end

  # def test_given_no_api_key
  #   tester = self.command_tester
  #
  #   # Temporarily clear API key
  #   original_key = ENV["GMAPS_API_KEY"]?
  #   ENV.delete("GMAPS_API_KEY")
  #
  #   begin
  #     status = tester.execute(
  #       options: {
  #       "latitude"  => "40.7128",
  #       "longitude" => "-74.0060",
  #       "output"    => "test.png",
  #       }
  #     )
  #
  #     status.should eq ACON::Command::Status::FAILURE
  #     tester.display.should contain "API key not found"
  # ensure
  #   # Restore API key
  #   ENV["GMAPS_API_KEY"] = original_key if original_key
  # end

  private def command : Gmaps::GetSatelliteImageCommand
    Gmaps::GetSatelliteImageCommand.new
  end

  private def command_tester : ACON::Spec::CommandTester
    ACON::Spec::CommandTester.new self.command
  end
end
