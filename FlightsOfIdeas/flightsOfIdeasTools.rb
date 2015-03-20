require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

###########################################################
#
#    Google Sketchup Flights of Ideas Tools
#    Copyright (C) 2009 Simon Beard (Flights Of Ideas)
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

# Create toolbar icon for website
toolbar = UI::Toolbar.new "FlightsOfIdeas"
cmd = UI::Command.new("flightsofideas") { 
	UI.openURL("http://simonbeard.github.io/sketchup-svg-outline-plugin/")
}		
path = Sketchup.find_support_file "FlightsOfIdeas.png", "plugins/FlightsOfIdeas/Images/"		
cmd.small_icon = path
cmd.large_icon = path
cmd.tooltip = "Flights of Ideas Website"
cmd.status_bar_text = "Flights of Ideas Website"
cmd.menu_text = "Flights of Ideas Website"				
toolbar = toolbar.add_item cmd
toolbar.show
