ENV["CRYSTAL_PATH"] = "#{__DIR__}/../src"

require "spec"
require "athena-spec"
require "athena-console"
require "athena-console/spec"
require "vcr"
require "../src/gmaps/app"
require "../src/gmaps/config"
require "dotenv"
require "path"

TEST_ROOT = Path[__DIR__].expand
ROOT      = TEST_ROOT.parent
SRC       = ROOT / "src"
TEST_DATA = TEST_ROOT / "testdata"
require "./support/**"

# Helper module for keyring testing
module KeyringSpecHelper
  def with_test_credentials(&)
    backend = Keyring::WindowsCredentialBackend.new
    yield backend
  ensure
    backend.try &.delete_password("GMapsTest", "test_user") rescue nil
  end
end

VCR.configure do |config|
  config.cassette_library_dir = "#{TEST_ROOT}/fixtures/vcr_cassettes"
  config.filter_sensitive_data["GMAPS_API_KEY"] = ENV["GMAPS_API_KEY"]? || Gmaps.config.gmaps_api_key
end

def load_dotenv
  Dotenv.load
end

class TestKeyProvider
  include Gmaps::IKeyProvider

  def initialize(key : String? = nil)
    @key = key
  end

  def get_api_key
    @key
  end
end

ASPEC.run_all
