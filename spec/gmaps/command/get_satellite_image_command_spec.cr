require "../../spec_helper"
require "../../../src/gmaps/commands/get_satellite_image_command"

describe Gmaps::GetSatelliteImageCommand do
  it "downloads satellite image for valid coordinates" do
    VCR.use_cassette("get_satellite_image_command") do
      tempfile = TempfileHelper.tempfile("satellite_test.png")
      
      command = Gmaps::GetSatelliteImageCommand.new
      tester = ACON::Spec::CommandTester.new command

      status = tester.execute(
        options: {
          "latitude" => "40.7128",
          "longitude" => "-74.0060",
          "output" => tempfile.path
        }
      )

      status.should eq ACON::Command::Status::SUCCESS
      tester.display.should contain "Satellite image saved to"
      File.exists?(tempfile.path).should be_true
      File.size(tempfile.path).should be > 0
    end
  end

  it "handles invalid coordinates" do
    command = Gmaps::GetSatelliteImageCommand.new
    tester = ACON::Spec::CommandTester.new command

    status = tester.execute(
      options: {
        "latitude" => "invalid",
        "longitude" => "invalid",
        "output" => "test.png"
      }
    )

    status.should eq ACON::Command::Status::FAILURE
    tester.display.should contain "Invalid coordinates"
  end

  it "accepts custom radius" do
    VCR.use_cassette("get_satellite_image_command_custom_radius") do
      tempfile = TempfileHelper.tempfile("satellite_test_wide.png")
      
      command = Gmaps::GetSatelliteImageCommand.new
      tester = ACON::Spec::CommandTester.new command

      status = tester.execute(
        options: {
          "latitude" => "40.7128",
          "longitude" => "-74.0060",
          "radius" => "5000",
          "output" => tempfile.path
        }
      )

      status.should eq ACON::Command::Status::SUCCESS
      tester.display.should contain "Satellite image saved to"
      File.exists?(tempfile.path).should be_true
      File.size(tempfile.path).should be > 0
    end
  end

  it "handles missing API key" do
    command = Gmaps::GetSatelliteImageCommand.new
    tester = ACON::Spec::CommandTester.new command
    
    # Temporarily clear API key
    original_key = ENV["GMAPS_API_KEY"]?
    ENV.delete("GMAPS_API_KEY")

    begin
      status = tester.execute(
        options: {
          "latitude" => "40.7128",
          "longitude" => "-74.0060",
          "output" => "test.png"
        }
      )

      status.should eq ACON::Command::Status::FAILURE
      tester.display.should contain "API key not found"
    ensure
      # Restore API key
      ENV["GMAPS_API_KEY"] = original_key if original_key
    end
  end
end
