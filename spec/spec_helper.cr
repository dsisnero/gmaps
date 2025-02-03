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

# Set up test environment
VALID_API_KEY = begin
  key = ENV["GMAPS_API_KEY"]? || Gmaps.config.gmaps_api_key
  key.empty? ? "valid_test_api_key" : key
end

INVALID_API_KEY = "invalid_test_api_key_123"

# Helper to set up API key for tests
def with_api_key(key : String, &)
  original_provider = Gmaps.key_provider
  test_provider = TestKeyProvider.new(key)
  Gmaps.key_provider = test_provider
  yield
ensure
  Gmaps.key_provider = original_provider.not_nil!
end

# Helper to run test with valid API key
def with_valid_api_key(&)
  with_api_key(VALID_API_KEY) { yield }
end

# Helper to run test with invalid API key
def with_invalid_api_key(&)
  with_api_key(INVALID_API_KEY) { yield }
end

Spec.before_each do
  # Default to valid API key unless specifically changed in test
  test_provider = TestKeyProvider.new(VALID_API_KEY)
  Gmaps.key_provider = test_provider
end

VCR.configure do |config|
  config.cassette_library_dir = "#{TEST_ROOT}/fixtures/vcr_cassettes"
  config.filter_sensitive_data["key=#{VALID_API_KEY}"] = "key=<VALID_API_KEY>"
  config.filter_sensitive_data["key=#{INVALID_API_KEY}"] = "key=<INVALID_API_KEY>"
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
