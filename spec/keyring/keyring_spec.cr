require "../spec_helper"
require "../../src/keyring/backend"

{% if flag?(:windows) %}
  require "./windows_credential_backend_spec"
{% else %}
  require "./mock_credential_backend_spec"
{% end %}

# Platform-independent tests for the Keyring module
describe Keyring do
  TEST_SERVICE = "GMapsTest"
  TEST_USERNAME = "test_user"
  TEST_PASSWORD = "test_password_123"

  describe "KeyringLoader" do
    it "returns appropriate backend" do
      backend = Keyring::KeyringLoader.get_keyring
      {% if flag?(:windows) %}
        backend.should be_a(Keyring::WindowsCredentialBackend)
      {% else %}
        backend.should be_a(Keyring::MockCredentialBackend)
      {% end %}
    end
  end

  describe "credential operations" do
    it "performs basic credential operations" do
      backend = Keyring::KeyringLoader.get_keyring

      # Set password
      backend.set_password(TEST_SERVICE, TEST_USERNAME, TEST_PASSWORD)

      # Get password
      retrieved = backend.get_password(TEST_SERVICE, TEST_USERNAME)
      retrieved.should eq(TEST_PASSWORD)

      # Delete password
      backend.delete_password(TEST_SERVICE, TEST_USERNAME)
      backend.get_password(TEST_SERVICE, TEST_USERNAME).should be_nil
    end
  end
end
