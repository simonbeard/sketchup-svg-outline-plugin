require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

###########################################################
#
#    Scalable Vector Graphics (SVG) from Google Sketchup Faces
#    Copyright (C) 2008 Simon Beard
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

$uStrings = LanguageHandler.new("FlightsOfIdeas")
flightsOfIdeasExtension = SketchupExtension.new $uStrings.GetString("FlightsOfIdeas"), "FlightsOfIdeas/templateMaker.rb"                  
flightsOfIdeasExtension.description=$uStrings.GetString("These tools allow the creation of SVG files using objects faces.")                        
Sketchup.register_extension flightsOfIdeasExtension, true

###########################################################