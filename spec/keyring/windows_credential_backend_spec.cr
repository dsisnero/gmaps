require "../spec_helper"
require "../../src/keyring/backends/windows_credential_backend"

include KeyringSpecHelper

{% if flag?(:windows) %}
describe Keyring::WindowsCredentialBackend do
  TEST_SERVICE = "GMapsTest"
  TEST_USERNAME = "test_user"
  TEST_PASSWORD = "test_password_123"

  describe "#set_password" do
    after_each do
      with_test_credentials { }  # Cleanup
    end

    it "successfully stores a password" do
      with_test_credentials do |backend|
        backend.set_password(TEST_SERVICE, TEST_USERNAME, TEST_PASSWORD)
        retrieved = backend.get_password(TEST_SERVICE, TEST_USERNAME)
        retrieved.should eq(TEST_PASSWORD)
      end
    end

    it "can overwrite an existing password" do
      with_test_credentials do |backend|
        backend.set_password(TEST_SERVICE, TEST_USERNAME, TEST_PASSWORD)
        new_password = "new_password_456"
        backend.set_password(TEST_SERVICE, TEST_USERNAME, new_password)
        
        retrieved = backend.get_password(TEST_SERVICE, TEST_USERNAME)
        retrieved.should eq(new_password)
      end
    end

    it "handles empty passwords" do
      with_test_credentials do |backend|
        backend.set_password(TEST_SERVICE, TEST_USERNAME, "")
        retrieved = backend.get_password(TEST_SERVICE, TEST_USERNAME)
        retrieved.should eq("")
      end
    end
  end

  describe "#get_password" do
    it "returns nil for non-existent credential" do
      with_test_credentials do |backend|
        password = backend.get_password("NonExistentService", "NonExistentUser")
        password.should be_nil
      end
    end

    it "retrieves stored password correctly" do
      with_test_credentials do |backend|
        backend.set_password(TEST_SERVICE, TEST_USERNAME, TEST_PASSWORD)
        retrieved = backend.get_password(TEST_SERVICE, TEST_USERNAME)
        retrieved.should eq(TEST_PASSWORD)
      end
    end
  end

  describe "#delete_password" do
    it "successfully deletes existing password" do
      with_test_credentials do |backend|
        backend.set_password(TEST_SERVICE, TEST_USERNAME, TEST_PASSWORD)
        backend.delete_password(TEST_SERVICE, TEST_USERNAME)
        
        retrieved = backend.get_password(TEST_SERVICE, TEST_USERNAME)
        retrieved.should be_nil
      end
    end

    it "raises when deleting non-existent password" do
      with_test_credentials do |backend|
        expect_raises(Exception, /Failed to delete credential/) do
          backend.delete_password("NonExistentService", "NonExistentUser")
        end
      end
    end
  end

  describe "special characters handling" do
    it "handles unicode characters correctly" do
      with_test_credentials do |backend|
        special_chars = {
          "unicode" => "パスワード123",
          "symbols" => "!@#$%^&*()",
          "spaces"  => "password with spaces",
          "emoji"   => "🔑password🔒",
        }

        special_chars.each do |test_name, password|
          backend.set_password(TEST_SERVICE, "#{TEST_USERNAME}_#{test_name}", password)
          retrieved = backend.get_password(TEST_SERVICE, "#{TEST_USERNAME}_#{test_name}")
          retrieved.should eq(password)
        end
      end
    end
  end

  describe "integration with Google Maps API" do
    it "stores and retrieves API key" do
      with_test_credentials do |backend|
        api_key = "test_maps_api_key_12345"
        backend.set_password("GMapsApp", "ApiKey", api_key)
        retrieved = backend.get_password("GMapsApp", "ApiKey")
        retrieved.should eq(api_key)
      end
    end
  end
end
{% else %}
# Mock implementation for non-Windows platforms
class MockWindowsCredentialBackend < Keyring::Backend
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

describe "Keyring::WindowsCredentialBackend (Mock)" do
  it "works with mock implementation" do
    backend = MockWindowsCredentialBackend.new
    backend.set_password("test", "user", "pass")
    backend.get_password("test", "user").should eq("pass")
    backend.delete_password("test", "user")
    backend.get_password("test", "user").should be_nil
  end
end
{% end %}
