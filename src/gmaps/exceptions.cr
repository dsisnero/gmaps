module Gmaps
  class ConfigError < Exception; end

  class EncryptionKeyMissing < Exception
    def initialize(file_path, encrypt_env)
      super(%(Encryption key not found. Please set it via '#{file_path}' or 'ENV[#{encrypt_env}]'.\n\n).colorize(:yellow).to_s)
    end
  end

  class InvalidApiKeyError < Exception
    def initialize(key : String? = nil)
      message = key ? "The provided API key #{key} is invalid" : "The provided API key is invalid"
      super(message)
    end
  end

  class NoApiKeyError < Exception
    def initialize
      super("API key is required and cannot be empty")
    end
  end
end
