require "./direction_result"
require "./html_to_asciidoc"

module Gmaps
  abstract class DirectionsFormatter
    def output_report(name : String, route : Gmaps::Route, io : String | IO, heading_level : Int32 = 1)
    end
  end

  class AsciidocFormatter < DirectionsFormatter
    getter converter : HtmlToAsciiDoc

    def initialize
      @converter = HtmlToAsciiDoc.new
    end

    def output_report(name : String, route : Gmaps::Route, io : String | IO, heading_level : Int32 = 1)
      leg = route.legs[0]
      io << "#" * heading_level + " Directions to #{name}\n\n"
      io << "Starting Address: #{leg.start_address}\n\n"
      io << "Ending Address: #{leg.end_address}\n\n"
      print_steps(io, leg.steps)
    end

    def print_steps(io, steps)
      io << "*Steps*\n\n"
      step_last = steps.pop
      steps.each do |step|
        instruction = converter.convert(step.html_instructions)
        if instruction =~ /continue/i
          io << ". #{instruction} for #{step.distance}.\n"
        else
          io << ". #{instruction} and continue for #{step.distance}.\n"
        end
      end
      io << ". #{converter.convert(step_last.html_instructions)} after #{step_last.distance}."
      io << "\n\n"
    end
  end

  class DirectionsReporter
    getter formatter
    getter route

    def initialize(@formatter : DirectionsFormatter)
    end

    def output_report(name : String, route : Gmaps::Route, io : String | IO, heading_level : Int32 = 1)
      @formatter.output_report(name: name, route: route, io: io, heading_level: heading_level)
    end
  end
end
