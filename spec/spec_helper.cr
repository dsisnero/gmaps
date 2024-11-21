ENV["CRYSTAL_PATH"] = "#{__DIR__}/../src"

require "spec"
require "athena-spec"
require "athena-console"
require "athena-console/spec"
require "vcr"
require "../src/gmaps/client"
require "dotenv"
require "path"

TEST_ROOT = Path[__DIR__].expand
ROOT      = TEST_ROOT.parent
SRC       = ROOT / "src"
TEST_DATA = TEST_ROOT / "testdata"
require "./support/**"

VCR.configure do |config|
  config.cassette_library_dir = "#{TEST_ROOT}/fixtures/vcr_cassettes"
  config.filter_sensitive_data("<API_KEY>") do |interaction|
    ENV["GMAPS_API_KEY"]? || Gmaps.config.gmaps_api_key
  end
end

def load_dotenv
  Dotenv.load
end
