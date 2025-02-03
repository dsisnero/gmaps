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
Spec.before_each do
  # Ensure we have a test API key for all tests
  test_key = "test_api_key_for_specs"
  test_provider = TestKeyProvider.new(test_key)
  Gmaps.key_provider = test_provider
end

VCR.configure do |config|
  config.cassette_library_dir = "#{TEST_ROOT}/fixtures/vcr_cassettes"
  config.filter_sensitive_data["GMAPS_API_KEY"] = ENV["GMAPS_API_KEY"]? || "test_api_key_for_specs"
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
    @key || "test_api_key_for_specs"
  end
end

ASPEC.run_all
