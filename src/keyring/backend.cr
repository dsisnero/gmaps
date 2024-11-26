module Keyring
  # Abstract base class for all keyring backends
  abstract class Backend
    abstract def set_password(service_name : String, username : String, password : String)
    abstract def get_password(service_name : String, username : String) : String?
    abstract def delete_password(service_name : String, username : String)
  end

  # Backend discovery and loading 
  class KeyringLoader
    def self.get_keyring : Backend
      {% if flag?(:windows) %}
        WindowsCredentialBackend.new
      {% else %}
        raise "Platform not supported"
      {% end %}
    end
  end
end

require "./backends/*"
