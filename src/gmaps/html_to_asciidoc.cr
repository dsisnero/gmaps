# Required for file operations

# Converts HTML to AsciiDoc format by replacing HTML tags with AsciiDoc formatting.
#
# Replaces `<strong>`, `<b>`, `<em>`, and `<i>` tags with AsciiDoc bold (`*...*`) and italic (`_..._`) formatting.
# Replaces `<h1>`-`<h6>` tags with AsciiDoc section headings using `=` characters.
# Replaces `<wbr/>` with a line break (`+`).
# Unwraps content from `<div>` tags and removes inline styles.
#
# Can call `convert` to convert a full HTML document, or individual functions like `convert_headings` and `convert_bold`
# to selectively convert parts of HTML.
class HtmlToAsciiDoc
  BOLD_RE   = /<(strong|b)>(.*?)<\/\1>/
  ITALIC    = /<(em|i)>(.*?)<\/\1>/
  HEADING   = /<h([1-6])>(.*?)<\/h\1>/
  BREAK     = /\/<wbr\/>/
  DIV_STYLE = /<div style=[^>]*>(.*)<\/div>/

  # (?<=<div[^>]*>)(.*?)(?=<\/div>)
  def self.convert(html : String)
    new().convert(html)
  end

  def extract_headings(html : String)
  end

  def convert_headings(html : String)
    html.gsub(HEADING) do |_|
      level = $1.to_i
      text = $2.rstrip
      result = %(#{"=" * (level + 1)} #{text})
      "#{result}\n\n"
    end
  end

  def convert_bold(html : String)
    html.gsub(BOLD_RE, "*\\2*")
  end

  def convert_italic(html : String)
    html.gsub(ITALIC, "_\\2_")
  end

  def convert_break(html : String)
    html.gsub(BREAK, " +\n")
  end

  def convert_style(html : String)
    html.gsub(DIV_STYLE, " \\1")
  end

  def convert_table
  end

  def convert(html : String)
    s = convert_headings(html)
    s2 = convert_bold(s)
    s3 = convert_italic(s2)
    s4 = convert_break(s3)

    convert_style(s4)
  end

  # Define a function to convert HTML5 to AsciiDoc
end
