require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'
require 'FlightsOfIdeas/svgTemplate.rb'

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

# Create a new template
$template = SvgTemplate.new()

# Add toolbar and context menu (right-click)
$template.template_toolbar
$template.template_context_menu