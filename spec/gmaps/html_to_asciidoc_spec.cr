require "../../src/gmaps/html_to_asciidoc"

describe "HTML to AsciiDoc conversion" do
  describe "#extract_headings" do
    it "returns an same string if no headings found" do
      html_content = "<p>Paragraph</p>"
      HtmlToAsciiDoc.new.convert_headings(html_content).should eq(html_content)
    end
  end

  describe "#convert_headings" do
    it "converts headings to AsciiDoc syntax" do
      headings = (1.upto(6)).to_a.map { |i| %(<h#{i}>content for #{i}</h#{i}>) }
      conv = HtmlToAsciiDoc.new
      result = headings.map { |i| conv.convert_headings(i) }
      result[0].should eq("== content for 1\n\n")
      result[1].should eq("=== content for 2\n\n")
    end

    it "returns an empty string if headings array is empty" do
      HtmlToAsciiDoc.new.convert_headings("").should eq("")
    end
  end

  describe "it works for escaped fields" do
    html_content = "Turn \u003cb\u003eright\u003c/b\u003e onto \u003cb\u003eS 650 E\u003c/b\u003e/\u003cwbr/\u003e\u003cb\u003eMedical Dr\u003c/b\u003e"
    conv = HtmlToAsciiDoc.new
    result = conv.convert(html_content)
    expected_result = "Turn *right* onto *S 650 E* +\n*Medical Dr*"
    result.should eq(expected_result)
  end

  describe "#convert_bold_italic" do
    it "converts bold and italic tags to AsciiDoc syntax" do
      html_content = "<strong>Bold</strong> and <em>Italic</em>"
      conv = HtmlToAsciiDoc.new
      result = conv.convert_bold(conv.convert_italic(html_content))
      expected_result = "*Bold* and _Italic_"
      result.should eq(expected_result)
    end

    it "returns the same string if no bold or italic tags found" do
      html_content = "No bold or italic"
      conv = HtmlToAsciiDoc.new
      result = conv.convert_bold(conv.convert_italic(html_content))
      result.should eq(html_content)
    end
  end

  describe "#html_to_asciidoc" do
    it "converts HTML to AsciiDoc" do
      input_html = "<h1>Heading</h1><strong>Bold</strong>"
      result = HtmlToAsciiDoc.convert(input_html)
      expected_output = "== Heading\n\n*Bold*"
      result.should eq(expected_output)
    end
  end
end
