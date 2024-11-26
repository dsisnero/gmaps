require "../spec_helper"
require "../../src/keyring/backend"

# Mock implementation for non-Windows platforms
class Keyring::MockCredentialBackend < Keyring::Backend
  @store = {} of String => String

  def set_password(service_name : String, username : String, password : String) : Nil
    @store["#{service_name}:#{username}"] = password
  end

  def get_password(service_name : String, username : String) : String?
    @store["#{service_name}:#{username}"]?
  end

  def delete_password(service_name : String, username : String) : Nil
    key = "#{service_name}:#{username}"
    raise "Failed to delete credential" unless @store.delete(key)
  end
end

describe Keyring::MockCredentialBackend do
  it "works with mock implementation" do
    backend = Keyring::MockCredentialBackend.new
    backend.set_password("test", "user", "pass")
    backend.get_password("test", "user").should eq("pass")
    backend.delete_password("test", "user")
    backend.get_password("test", "user").should be_nil
  end
end
