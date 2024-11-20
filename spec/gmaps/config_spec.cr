require "./../spec_helper"
require "./../../src/gmaps/config"

describe Gmaps::Config do
  # Test basic properties and serialization
  it "has an api_key property and can be serialized to YAML" do
    config = Gmaps::Config.new(gmaps_api_key: "YOUR_API_KEY")
    config.gmaps_api_key.should eq "YOUR_API_KEY"
    yaml_string = config.to_yaml
    yaml_string.should contain "gmaps_api_key: YOUR_API_KEY"
  end
end

describe Gmaps::ConfigLoader do
  # Use a temporary directory for testing

  # Test config file and directory creation
  it "creates a config directory and file if they don't exist" do
    with_tempfile("mydir") do |path|
      config_loader = Gmaps::ConfigLoader.new(path)
      File.exists?(config_loader.config_dir).should be_true
      File.exists?(config_loader.config_file).should be_true
    end
  end

  # Test API key management
  it "can get and set the API key" do
    with_tempfile("mydir") do |path|
      config_loader = Gmaps::ConfigLoader.new(path)
      config_loader.edit_key("TEST_KEY")
      config_loader.get_key.should eq "TEST_KEY"
    end
  end

  # Test that the config file is actually encrypted
  it "encrypts the config file content" do
    with_tempfile("mydir") do |path|
      config_loader = Gmaps::ConfigLoader.new(path)
      File.basename(config_loader.config_file).should eq "config.yml.enc"
      config_loader.edit_key("TEST_KEY")
      encrypted_content = File.read(config_loader.config_file)
      puts "Encrypted content:\n#{encrypted_content}"
      encrypted_content.should_not contain "TEST_KEY" # The key should not be visible in plain text
      encrypted_content.should_not contain "api_key"  # The key name should also not be visible
    end
  end

  # it errors if no key set yet
  it "errors if no key set yet" do
    with_tempfile("mydir") do |path|
      config_loader = Gmaps::ConfigLoader.new(path)
      expect_raises(Gmaps::ConfigError) { config_loader.get_key }
    end
  end

  # (Additional tests can be added here for other functionalities, such as open_config_file and error handling)
end
