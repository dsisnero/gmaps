require "./../spec_helper"
require "./../../src/gmaps/direction_result"

module Gmaps
  describe Gmaps::DirectionResult do
    it "parses result correctly" do
      json = File.read("spec/testdata/direction_result.json")
      result = DirectionResult.from_json(json)
      result.geocoded_waypoints.size.should eq(2)
      result.geocoded_waypoints[0].place_id.should eq("ChIJnykGkXRYUocRD1MgHH_zs60")
      result.routes.should be_a(Array(Route))
    end

    it "Route has an overlay_polyline" do
      json = File.read("spec/testdata/direction_result.json")
      result = DirectionResult.from_json(json)
      route1 = result.routes[0]
      overview = route1.overview_polyline
      overview.should be_a(Gmaps::Polyline)
      encoded = overview.encoded_points
      encoded.should be_a(String)
      encoded.should eq "alnxFj_uiT}AVIFEL@NFx@F^?~D?jFVnAFhBAzBEh@Md@O^iBlCY`@Qf@q@xBShAq@jMw@dH[bFGb@Oh@q@rBQVWRg@LmEAyAlLq@|FsDv[UbCMr@Sp@y@hCk@tA[p@o@fA_AbBKFoA?mCGsDA?rL@tI?hH@vK?nNBb]?vJBrG?zCCFENEtADz@RpAA|A?\\Jf@DLNV^LF@z@IdD]jBQnAK~@CN[vCBfLHtNHvSRtETvALtC\\bEn@`Cf@hDz@jDlAnDrAhEnBfE`CrChBnEfDpD~ChK~IxApAVRd@f@xDdDpCbC`KxIhVzSdDtCdDrClCpBdCzAzAv@|Ar@zAf@z@XrA^hB^pAThBTjBRrAJhCLvLLpJFhJDbGDz@@lBAbA@`@Zz@L`Bd@dA`@rAn@zBdAbA^f@NnAXxATjAF`BCfLsB~Bc@t@Gr@CbCDxXt@~CL~AT`ARl@Vr@^~@n@dA~@lBxA~@f@r@ZfAZrBPh@@rFLhFNlA?nACjEUlDS~F_@bPs@|BO~@O^IpAc@l@[nAs@fBwAdBqBtAgB\\k@Ja@NSRWdB_CJAdGcIfFgHpHsJnM{PhHwJdDkEl@u@`@YDWJG\\UNMLa@@g@BQJU\\c@fAuAF]~B}C~AkB`EgDvMkKvMmK`CuBnAyA|DmFdDoEp@w@dAgA`BuArEkDj@[fAy@~@q@`@I~@O|@D^DVHx@^\\JjBPdDVvAL~@RlDhA`@L?i@?gB?yD?yADa@@k@HUDYFOHIfA?nB?`AApIBd@@^HJBdB@nAACk@QeBO{AE}AAkB?{A@mUs]C{C@?iH_@?oB?"
    end

    it "allows you to fetch a static map" do
      json = File.read("spec/testdata/direction_result.json")
      result = DirectionResult.from_json(json)
      map = result.fetch_static_map(api_key: Gmaps.get_api_key)
      map.should be_a(String)
      File.write("spec/testdata/direction_result.png", map)
    end
  end
end
