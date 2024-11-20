ENV["CRYSTAL_PATH"] = "#{__DIR__}/../src"

require "spec"
require "athena-spec"
require "athena-console"
require "athena-console/spec"
require "../src/gmaps"
require "dotenv"
# require "../src/nearest_hospitals"
require "path"

TEST_ROOT = Path[__DIR__].expand
ROOT      = TEST_ROOT.parent
SRC       = ROOT / "src"
TEST_DATA = TEST_ROOT / "testdata"
require "./support/**"

def load_dotenv
  Dotenv.load
end
