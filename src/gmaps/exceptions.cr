module Gmaps
  class ConfigError < Exception; end

  class EncryptionKeyMissing < Exception
    def initialize(file_path, encrypt_env)
      super(%(Encryption key not found. Please set it via '#{file_path}' or 'ENV[#{encrypt_env}]'.\n\n).colorize(:yellow).to_s)
    end
  end
end
