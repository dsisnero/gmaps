module Keyring
  abstract class Backend
    abstract def set_password(service_name : String, username : String, password : String)
    abstract def get_password(service_name : String, username : String) : String?
    abstract def delete_password(service_name : String, username : String)
  end

  # Backend discovery and loading 
  class KeyringLoader
    def self.get_keyring : Backend
      WindowsCredentialBackend.new
    end
  end
end
