require "yaml"
require "./support/*"
require "./exceptions"
require "secrets"

module Gmaps
  class Config
    ::Log.for(self)
    {% if flag?(:windows) %}
      # Determine the default editor based on the platform
      DEFAULT_EDITOR = "notepad.exe"
    {% else %}
      # Determine the default editor for non-Windows platforms
      DEFAULT_EDITOR = "nano"
    {% end %}

    property gmaps_api_key : String

    include YAML::Serializable

    # load key using ConfigLoader
    def self.load_from_config(config_dir : String? = nil)
      loader = ConfigLoader.new(config_dir)
      yaml = loader.to_yaml
      Log.debug { "Config YAML:\n#{yaml}" }
      Config.from_yaml(loader.to_yaml)
    end


    def initialize(@gmaps_api_key : String)
    end
  end

  class ConfigLoader
    # Getter for the configuration directory path
    getter config_dir : Path
    # Getter for the configuration file path
    getter config_file : Path
    # Getter for the keyfile path
    getter keyfile : Path

    # does config_dir exist?
    def self.config_dir_exists?(config_dir : String? = nil) : Bool
      config_dir = get_config_dir(config_dir)
      Dir.exists?(config_dir)
    end

    # Constructor
    # Initializes the API key and sets up the config directory and file path
    #
    # Params:
    # + config_dir (String?) - Optional custom configuration directory path
    def initialize(config_dir : String? = nil)
      @config_dir = self.class.get_config_dir(config_dir)
      @keyfile = @config_dir / "master"
      @config_file = @config_dir / "config.yml.enc"

      # Create config directory if it doesn't exist
      Dir.mkdir_p(@config_dir) unless Dir.exists?(@config_dir)

      # Create config file if it doesn't exist
      Secrets.generate(config_file.to_s, keyfile.to_s) unless File.exists?(config_file)

    end

    # Edits the API key stored in the config file
    #
    # Params:
    # + api_key (String) - The new API key to store
    def edit_key(api_key : String)
      secrets = Secrets.new(config_file.to_s, keyfile.to_s)
      secrets["gmaps_api_key"] = api_key
      secrets.save
    end

    def secrets_class
      Secrets.new(config_file.to_s, keyfile.to_s)
    end

    # Retrieves the API key from the config file
    #
    # Returns:
    # + (String) - The API key
    def get_key
      secrets = Secrets.new(config_file.to_s, keyfile.to_s)
      if secret = secrets["gmaps_api_key"]?
        secret.as_s
      else
        raise ConfigError.new("No gmaps_api_key found")
      end
    end

# Retrieves the API key from the config file, returning nil if not found
    #
    # Returns:
    # + (String | Nil) - The API key or nil if not found
    def get_key?
      secrets = Secrets.new(config_file.to_s, keyfile.to_s)
      if secret = secrets["api_key"]?
        secret.as_s
      else
        nil
      end

    end

    def to_yaml
      secrets_class.raw
    end

    # Determines the default configuration directory based on environment variables or a fallback
    #
    # Returns:
    # + (Path) - The configuration directory path
    def self.get_config_dir(config_dir : String? = nil) : Path
      return Path[config_dir] if config_dir
      # Use XDG_CONFIG_HOME if set, otherwise use the default config directory
      if xdg_env = ENV["XDG_CONFIG_HOME"]?
        Path[xdg_env] / "gmaps"
      else
        Path.home / ".config/gmaps"
      end
    end

    # Checks if the config file exists
    def config_file_exists?
      File.exists?(config_file)
    end

    def yaml_config
      if key = get_key
        secret = Secrets.new(config_file.to_s, keyfile.to_s).raw
      else
        Config.new(api_key: "").to_yaml
      end
    end

    # Opens the config file for editing using the default editor or the EDITOR environment variable
    def open_config_file
      # Determine the editor to use
      editor = ENV["EDITOR"]? || DEFAULT_EDITOR

      # Create temporary file for editing
      temp_file = File.temp("config.temp")

      yaml = yaml_config
      File.write(temp_file, yaml)

      # Reack initial modified time of the temporary file
      initial_modified_time = File.stat(temp_file).mtime

      # Open the temporary file with the chosen editor
      system("#{editor} #{temp_file}")

      # Wait for user to finish editing
      puts "Please edit the configuration file and save it. Press Enter when done..."
      gets

      # Check if the file was modified
      current_modified_time = File.stat(temp_file).mtime
      if current_modified_time == initial_modified_time
        puts "Config file was not modified. No changes saved."
        File.delete(temp_file)
        return
      end

      # Encrypt and save the edited data back to the config file
      begin
        saved_data = File.read(temp_file)
        config = Config.from_yaml(saved_data)
        edit_key(config.api_key)
      rescue ex : Exception
        raise ConfigError.new("Failed to encrypt config file: #{ex.message}")
      end

      # Delete the temporary file
      File.delete(temp_file)
    end
  end
end
