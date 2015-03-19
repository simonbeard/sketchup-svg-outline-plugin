require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

###########################################################
#
#    Scalable Vector Graphics (SVG) from Google Sketchup Faces
#    Copyright (C) 2009 Simon Beard
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################

$uStrings = LanguageHandler.new("FlightsOfIdeasSVG")
flightsOfIdeasExtensionSVG = SketchupExtension.new $uStrings.GetString("FlightsOfIdeasSVG"), "FlightsOfIdeas/svgExportTools.rb"                  
flightsOfIdeasExtensionSVG.description=$uStrings.GetString("These tools allow the creation of SVG files using object faces.")                        
Sketchup.register_extension flightsOfIdeasExtensionSVG, true
#$uStrings = LanguageHandler.new("FlightsOfIdeasSTL") #STL coming soon...
#flightsOfIdeasExtensionSTL = SketchupExtension.new $uStrings.GetString("FlightsOfIdeasSTL"), "FlightsOfIdeas/stlExportTools.rb"                  
#flightsOfIdeasExtensionSTL.description=$uStrings.GetString("These tools allow the creation of STL files using object faces.")                        
#Sketchup.register_extension flightsOfIdeasExtensionSTL, true
$uStrings = LanguageHandler.new("FlightsOfIdeasTools")
flightsOfIdeasExtensionTools = SketchupExtension.new $uStrings.GetString("FlightsOfIdeasTools"), "FlightsOfIdeas/flightsOfIdeasTools.rb"                  
flightsOfIdeasExtensionTools.description=$uStrings.GetString("Go straight to the Flights Of Ideas website.")                        
Sketchup.register_extension flightsOfIdeasExtensionTools, true

###########################################################