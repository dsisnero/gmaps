require "./direction_result"

module Gmaps
  abstract class DirectionsFormatter




    def output_report(route : Gmaps::Route , io : String | IO, heading_level : Int32 = 1)
    end



  end


  class AsciidocFormatter < DirectionsFormatter


    def output_report(route : Gmaps::Route, io : String | IO, heading_level : Int32 = 1)
      leg = route.legs[0]
      io << "#" * heading_level + " Directions\n\n"
      io << "Starting Address: #{leg.start_address}\n"
      io << "Ending Address: #{leg.end_address}\n\n"
      print_steps(io, leg.steps)
    end

    def print_steps(io, steps)
      io << "*Steps*\n\n"
      steps.each do |step|
      instruction = as_asciidoc(step.html_instructions)
        io << ". #{instruction} for #{step.distance}\n"
      end
      io << "\n\n"
    end

    def as_asciidoc(str : String)
      str.gsub("\u003cb\u003e", "*").gsub("\u003c/b\u003e","*")
    end



  end


  class DirectionsReporter

    getter formatter
    getter route

    def initialize( @formatter : DirectionsFormatter)
    end

    def output_report(route : Gmaps::Route , io : String | IO, heading_level : Int32 = 1)
      @formatter.output_report(route: route, io: io, heading_level: heading_level)
    end

  end



end
