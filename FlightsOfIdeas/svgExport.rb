require 'sketchup.rb'
require 'FlightsOfIdeas/flightsOfIdeasCommon.rb'
require 'FlightsOfIdeas/laserScript.rb'

###########################################################
#
#    Scalable Vector Graphics (SVG) from Google Sketchup Faces
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

class SvgExport
	
	#######################################################
	# New Template
	#######################################################	
	def initialize()					
		# The dialog object		
		@dlg = nil	
		# Whether the ok dlg is currently open
		@dlgOpen = false	
		# The ok dialog object
		@okdlg = nil	
		# Whether the dlg is currently open
		@okdlgOpen = false		
		# The face to make into an SVG file		
		@exportFace = nil	
		# The actual SVG file for writing
		@svgFile = nil		
		# Global transform for points (initialise as identity)
		transformMatrix = Geom::Transformation.new 
		# Min and Max XY of each face in mm
		@minx = Array.new; @miny = Array.new; @maxx = Array.new; @maxy = Array.new		
		# Array for holding 2D projected points in mm of faces
		@pointArrayGFXY = Array.new		
		# Groups of co-planar faces that are joined
		@faceGroups = Array.new;
		# Groups of co-planar faces that are joined
		@pointArrayGFXY = Array.new;		
		# Whether the current face has been selected by the user		
		@faceInSelection = false
		
		# Get dictionary preferences (create if none)
		@prefs = Sketchup.active_model.attribute_dictionary "foi_svg_export", true
		# File name to export SVG
		@svgFilename = Sketchup.active_model.get_attribute "foi_svg_export", "svgFilename", "flightsOfIdeas.svg"
		# Border inside of SVG document
		@paperBorder = Sketchup.active_model.get_attribute "foi_svg_export", "paperBorder", "10"	
		# Units to use in SVG file
		@units = Sketchup.active_model.get_attribute "foi_svg_export", "units", "mm"		
		# Whether to export hidden lines
		@exportHiddenLines = Sketchup.active_model.get_attribute "foi_svg_export", "exportHidden", false
		# Whether to export outlines
		@exportOutlines = Sketchup.active_model.get_attribute "foi_svg_export", "exportOutlines", true		
		# Whether to export disecting lines (useful when laser etching)
		@exportInternalLines = Sketchup.active_model.get_attribute "foi_svg_export", "exportEtch", true		
		# Whether to export internal lines which are not part of a faces loops (useful when laser etching)
		@exportOrphanLines = Sketchup.active_model.get_attribute "foi_svg_export", "exportOrphans", true	
		# Whether to export SketchUp text annotations
		@exportAnnotations = Sketchup.active_model.get_attribute "foi_svg_export", "exportAnnotations", false
		# The size of text annotations
		@annotationHeight = Sketchup.active_model.get_attribute "foi_svg_export", "annotationHeight", "10"	
		# The type of text exported (SVG or laser script)
		@annotationType = Sketchup.active_model.get_attribute "foi_svg_export", "annotationType", "SVG"
		# Whether to export as path or lines to SVG file
		@exportSvgType = Sketchup.active_model.get_attribute "foi_svg_export", "exportSVG", "paths"	
		# Colours for SVG file
		@outlineRGB = Sketchup.active_model.get_attribute "foi_svg_export", "outlineRGB", "0000FF"
		@dissectRGB = Sketchup.active_model.get_attribute "foi_svg_export", "dissectRGB", "FF0000"
		@orphanRGB = Sketchup.active_model.get_attribute "foi_svg_export", "orphanRGB", "00FF00"
		@annotationRGB = Sketchup.active_model.get_attribute "foi_svg_export", "annotationRGB", "000000"
		# Width of lines for SVG file
		@outlineWidth = Sketchup.active_model.get_attribute "foi_svg_export", "outlineWidth", "1"
		@dissectWidth = Sketchup.active_model.get_attribute "foi_svg_export", "dissectWidth", "1"
		@orphanWidth = Sketchup.active_model.get_attribute "foi_svg_export", "orphanWidth", "1"
		@annotationWidth = Sketchup.active_model.get_attribute "foi_svg_export", "annotationWidth", "1"		
		# SVG Editor to execute if desired
		@svgEditor = Sketchup.active_model.get_attribute "foi_svg_export", "svgEditor", ""
		@execEditor = Sketchup.active_model.get_attribute "foi_svg_export", "execEditor", false;
	end

	#######################################################
	# Create UI context menu for creating SVG templates
	#######################################################	
	def template_context_menu()
		UI.add_context_menu_handler { |menu|
			selection=Sketchup.active_model.selection
			if FlightsOfIdeasCommon.contains_face selection 
				menu.add_separator				
				item = menu.add_item("Export to SVG file") { self.preferences_dialog(); }				
			end
		}
	end
	
	#######################################################
	# Create UI toolbar for creating SVG templates
	#######################################################	
	def template_toolbar()
		toolbar = UI::Toolbar.new "FlightsOfIdeas"

		cmd = UI::Command.new("Export to SVG File") { 
			selection=Sketchup.active_model.selection
			if FlightsOfIdeasCommon.contains_face selection 
				self.preferences_dialog();
			end
		}		
		path = Sketchup.find_support_file "CreateSvg.png", "plugins/FlightsOfIdeas/Images/"		
		cmd.small_icon = path
		cmd.large_icon = path
		cmd.tooltip = "Create 2D SVG file from selected face(s)"
		cmd.status_bar_text = "The 2D format is used for simple CNC milling, laser cutting, documentation, and layout"
		cmd.menu_text = "Create SVG file"				
		toolbar = toolbar.add_item cmd
		toolbar.show
	end

###########################################################

	#######################################################
	# Create preferences dialog box for SVG templates
	#######################################################	
	def preferences_dialog()
		
		# Check that dlg not already opened
		if not @dlgOpen
			@dlgOpen = true
			
			# Get HTML file for dlg
			html = File.dirname(__FILE__) + "/svgExportDialog.html";
			if (html.length == 0)
				return false;
			end
			
			# Create new dlg
			@dlg = UI::WebDialog.new "SVG Export Preferences", true
			@dlg.min_height=600;
			@dlg.min_width=1024;

			# Set close callback function
			@dlg.add_action_callback("on_close") {|d,p| @dlgOpen = false; d.close(); }
			
			# Set close callback function
			@dlg.add_action_callback("on_ok") {|d,p| 
				
				# Get arguments
				args = p.split(','); 
				@svgFilename=args[0]; @paperBorder = args[1]; @units=args[2];
				@exportSvgType = args[3];				
				@exportHiddenLines = false;
				if args[4] == "true"
					@exportHiddenLines = true;
				end					
				@exportOutlines = false;
				if args[5] == "true"
					@exportOutlines = true;
				end					
				@outlineRGB = args[6];
				@outlineWidth = args[7];
				@exportInternalLines = false;
				if args[8] == "true"
					@exportInternalLines = true;
				end
				@dissectRGB = args[9];
				@dissectWidth = args[10];
				@exportOrphanLines = false;
				if args[11] == "true"
					@exportOrphanLines = true;
				end
				@orphanRGB = args[12];
				@orphanWidth = args[13];
				@exportAnnotations = false;
				if args[14] == "true"
					@exportAnnotations = true;
				end			
				@annotationRGB = args[15];
				@annotationWidth = args[16];
				@annotationType = args[17];
				@annotationHeight = args[18];							
				@execEditor = false;
				if args[19] == "true"
					@execEditor = true;
					@svgEditor = args[20];
				end
				
				# Store preferences
				Sketchup.active_model.attribute_dictionary "foi_svg_export", true
				Sketchup.active_model.set_attribute "foi_svg_export", "svgFilename", @svgFilename
				Sketchup.active_model.set_attribute "foi_svg_export", "paperBorder", @paperBorder					
				Sketchup.active_model.set_attribute "foi_svg_export", "units", @units		
				Sketchup.active_model.set_attribute "foi_svg_export", "exportHidden", @exportHiddenLines
				Sketchup.active_model.set_attribute "foi_svg_export", "exportOutlines", @exportOutlines				
				Sketchup.active_model.set_attribute "foi_svg_export", "exportEtch", @exportInternalLines	
				Sketchup.active_model.set_attribute "foi_svg_export", "exportOrphans", @exportOrphanLines										
				Sketchup.active_model.set_attribute "foi_svg_export", "exportSVG", @exportSvgType						
				Sketchup.active_model.set_attribute "foi_svg_export", "exportAnnotations", @exportAnnotations
				Sketchup.active_model.set_attribute "foi_svg_export", "annotationType", @annotationType
				Sketchup.active_model.set_attribute "foi_svg_export", "annotationHeight", @annotationHeight
				Sketchup.active_model.set_attribute "foi_svg_export", "outlineRGB", @outlineRGB
				Sketchup.active_model.set_attribute "foi_svg_export", "dissectRGB", @dissectRGB
				Sketchup.active_model.set_attribute "foi_svg_export", "orphanRGB", @orphanRGB
				Sketchup.active_model.set_attribute "foi_svg_export", "annotationRGB", @annotationRGB
				Sketchup.active_model.set_attribute "foi_svg_export", "execEditor", @execEditor
				if (@execEditor)				
					if (@svgEditor.length > 0)	
						Sketchup.active_model.set_attribute "foi_svg_export", "svgEditor", @svgEditor;
					end
				end
				
				# Create the SVG file
				create_svg;
				
				# Close dialog
				@dlgOpen = false; d.close(); 				
			}			
					
			# Set save as callback function
			@dlg.add_action_callback("on_file_save") {|d,p| 							
				name = p.split('/')
				name = name[name.length-1]
						
				output_filename = UI.savepanel("Export to SVG", "", name);
				
				# Tidy filename path
				if (output_filename)
					name = output_filename.split('\\')
					@svgFilename = name[0]
					for i in 1...name.length
						@svgFilename  = @svgFilename+'/'+name[i]
					end					
				end
				
				cmd = "setFilename('"+@svgFilename+"')";				
				d.execute_script(cmd);
			}			
			
			# Set help callback
			@dlg.add_action_callback("on_help") {|d,p|
				UI.openURL("http://extensions.sketchup.com/en/content/svg-outline-plugin")
			}
			
			# Set SVG editor configure callback function
			@dlg.add_action_callback("on_svg_editor_configure") {|d,p| 							
				name = p.split('/')
				name = name[name.length-1]
						
				@svgEditor = UI.openpanel "Select your SVG editor", "", "*"						
				
				# Tidy filename path				
				if (@svgEditor)
					name = @svgEditor.split('\\')
					@svgEditor = name[0]
					for i in 1...name.length										
						@svgEditor  = @svgEditor+'/'+name[i]
					end					
				end
				if (@svgEditor)						
					cmd = "setSvgEditor('"+@svgEditor+"')";				
					d.execute_script(cmd);
				end
			}				
			
			# Show the dlg
			@dlg.set_background_color("f3f0f0");
			@dlg.set_file(html, nil)
			@dlg.show{
				hiddenCheck = "false";
				if (@exportHiddenLines)
					hiddenCheck = "true"
				end		
				outlineCheck = "false";
				if (@exportOutlines)
					outlineCheck = "true"
				end	
				linesCheck = "false";
				if (@exportInternalLines)
					linesCheck = "true"
				end
				orphansCheck = "false";
				if (@exportOrphanLines)
					orphansCheck = "true"
				end	
				textCheck = "false";
				if (@exportAnnotations)
					textCheck = "true"
				end
				exec = "false";
				if (@execEditor)
					exec = "true"
				end
				ed = "";
				if (@svgEditor)
					ed = @svgEditor;
				end
								
				cmd = "setDefaults('"+@svgFilename+","+@paperBorder+","+
					@units+","+@exportSvgType+","+hiddenCheck+","+
					outlineCheck+","+@outlineRGB+","+@outlineWidth+","+
					linesCheck+","+@dissectRGB+","+@dissectWidth+","+
					orphansCheck+","+@orphanRGB+","+@orphanWidth+","+
					textCheck+","+@annotationRGB+","+@annotationWidth+","+
					@annotationType+","+@annotationHeight+","+exec+","+ed+"')";
				
				@dlg.execute_script(cmd);
			}
			@dlg.set_on_close { @dlgOpen = false; }	
			
		else # Close if dlg already open
			@dlgOpen = false; 
			@dlg.close();
		end
	end
	
	
	#######################################################
	# Create export ok dialog box for SVG templates
	#######################################################	
	def export_ok_dialog()
		
		# Check that dlg not already opened
		if not @okdlgOpen
			@okdlgOpen = true
			
			# Get HTML file for dlg
			html = File.dirname(__FILE__) + "/svgOkDialog.html";
			if (html.length == 0)
				return false;
			end
			
			# Create new dlg
			@okdlg = UI::WebDialog.new("SVG Export Ok", false, "FlightsOfIdeasOk", 400, 190, 150, 150, true);

			# Set close callback function
			@okdlg.add_action_callback("on_close") {|d,p| @okdlgOpen = false; d.close(); }
			
			# Set close callback function
			@okdlg.add_action_callback("on_ok") {|d,p| @dlgOpen = false; d.close(); }	
		
			# Show the dlg
			@okdlg.set_background_color("f3f0f0");
			@okdlg.set_file(html, nil)
			@okdlg.show{}
			@okdlg.set_on_close { @okdlgOpen = false; }	
			
		else # Close if dlg already open
			@okdlgOpen = false; 
			@okdlg.close();
		end
	end		
		
###########################################################	

	#######################################################
	# Check whether a given face has been selected
	#######################################################
	def face_in_selection (suEntity, match)
		if suEntity.typename == "Face"
			
			if suEntity == match
				@faceInSelection = true
			end
		
		# If a group then process entities within
		elsif suEntity.typename == "Group"
			for i in 0...suEntity.entities.length						
				self.face_in_selection(suEntity.entities[i],match)
			end

		# If a component then process entities within
		elsif suEntity.typename == "ComponentInstance"
			for i in 0...suEntity.definition.entities.length						
				self.face_in_selection(suEntity.definition.entities[i],match)
			end			
		end					
	end
	
	
	#######################################################
	# Create groups of faces that are joined
	#######################################################
	def collect_text_entities (suEntity)
		if suEntity.typename == "Text"
			@textEntities.push(Array.new)
			index = @textEntities.length-1;
			@textEntities[index].push(suEntity.text)
			@textEntities[index].push(suEntity.point)
			@textEntities[index].push(suEntity.vector)
			@textEntities[index].push(false)
			@textEntities[index].push(-1)
			@textEntities[index].push(-1)
			@textEntities[index].push(0.0)
			@textEntities[index].push(0.0)
			
		# If a group then process entities within
		elsif suEntity.typename == "Group"
			for i in 0...suEntity.entities.length						
				self.collect_text_entities suEntity.entities[i]
			end

		# If a component then process entities within
		elsif suEntity.typename == "ComponentInstance"
			for i in 0...suEntity.definition.entities.length						
				self.collect_text_entities suEntity.definition.entities[i]
			end			
		end				
	end
	
	#######################################################
	# Create groups of faces that are joined
	#######################################################
	def group_joined_faces (suEntity)
			
		if suEntity.typename == "Face"
		
			# Skip if not exporting hidden entities
			if (suEntity.hidden?) and not (@exportHiddenLines)
				return
			end

			# Is face already in a group?
			grouped = false
			for i in 0...@faceGroups.length
				for j in 0...@faceGroups[i].length
					if suEntity == @faceGroups[i][j]
						grouped = true
						break
					end
				end
				if grouped
					break
				end
			end
			
			if not grouped												
				
				# Get all connected elements
				connected = suEntity.all_connected
				if connected
				
					@faceGroups = @faceGroups.push(Array.new)
					j = @faceGroups.length-1
					
					for i in 0...connected.length
						
						# Filter for type face
						if connected[i].typename == "Face"
							
							# Filter for co-planar
							if connected[i].normal.parallel? suEntity.normal and connected[i].vertices[0].position.on_plane? suEntity.plane
								
								# Filter for selected
								@faceInSelection = false								
								for k in 0...Sketchup.active_model.selection.length
									face_in_selection(Sketchup.active_model.selection[k],connected[i])
									if @faceInSelection
										break
									end
								end
								if @faceInSelection
									@faceGroups[j] = @faceGroups[j].push(connected[i])
								end
							end
						end
					end				
				end
			end
		
		# If a group then process entities within
		elsif suEntity.typename == "Group"
			for i in 0...suEntity.entities.length						
				self.group_joined_faces suEntity.entities[i]
			end

		# If a component then process entities within
		elsif suEntity.typename == "ComponentInstance"
			for i in 0...suEntity.definition.entities.length						
				self.group_joined_faces suEntity.definition.entities[i]
			end			
		end			
	end
	
	#######################################################
	# Group lines into the existing face groups if they are on a face (otherwise create new groups)
	#######################################################	
	def group_orphan_edges (suEntity)
		if suEntity.typename == "Edge"

			# Skip if not exporting hidden entities
			if (suEntity.hidden?) and not (@exportHiddenLines)
				return
			end
			
			# If edge is not defining an actual face
			if suEntity.faces.length == 0
				
				# Test whether both end points are on a face (i.e. colinear and within face bounds)				
				for i in 0...@faceGroups.length
					for j in 0...@faceGroups[i].length
						if @faceGroups[i][j].typename == "Face"
							resultS = @faceGroups[i][j].classify_point(suEntity.start)
							resultE = @faceGroups[i][j].classify_point(suEntity.end)	

							# If points on face
							if (resultS !=16)  and (resultS !=8)  and (resultS !=0)  and (resultE !=16)  and (resultE !=8)  and (resultE !=0) 
							
								# Add to group and exit
								@faceGroups[i] = @faceGroups[i].push(suEntity)
								j = @faceGroups[i].length
								i = @faceGroups.length	
								
								return
							end
						end
					end
				end
			end	
			
		# If a group then process entities within
		elsif suEntity.typename == "Group"
			for i in 0...suEntity.entities.length						
				self.group_orphan_edges suEntity.entities[i]
			end

		# If a component then process entities within
		elsif suEntity.typename == "ComponentInstance"
			for i in 0...suEntity.definition.entities.length						
				self.group_orphan_edges suEntity.definition.entities[i]
			end			
		end
	end
	
	#######################################################
	# Create SVG by parsing Sketchup selected faces
	#######################################################	
	def parse_groups(group, groupIndex)

		# Get normal, and right and up axes
		# First face always reference point (all have same normal and axes)
		norm = group[0].normal
		axes = norm.axes
		
		# Get reference point for group
		refPoint = group[0].loops[0].vertices[0].position
		
		# Get parent transformations
		transformMatrix = FlightsOfIdeasCommon.get_transform_product group[0]
		
		# Transfrom reference point
		refPoint = transformMatrix*refPoint
		
		# Initialise min and max XY for face
		point = refPoint.to_a
		@minx[groupIndex] = point[0].to_mm
		@miny[groupIndex] = point[1].to_mm
		@maxx[groupIndex] = point[0].to_mm
		@maxy[groupIndex] = point[1].to_mm
		
		# Initialise point storage		
		@pointArrayGFXY[groupIndex] = Array.new(group.length)
		
		# For each face
		for i in 0...group.length
			
			# Get parent transforms
			transformMatrix = FlightsOfIdeasCommon.get_transform_product group[i]
			
			if group[i].typename == "Face"
			
				# Test if there is a text entity pointing to face
				for txt in 0...@textEntities.length

					# Only test unused text entities
					if not (@textEntities[txt][3])			

						# Apply inverse transformation to point and test if on face
						classification = group[i].classify_point (transformMatrix.inverse*@textEntities[txt][1])				
						
						# If on edge, vertex, or inside face bounds
						if (classification == 1) or (classification == 2) or (classification == 4)							
							
							# Set as used
							@textEntities[txt][3] = true
							
							# Set face referencing text
							@textEntities[txt][4] = groupIndex
							@textEntities[txt][5] = i
							
							# Set point for text in SVG
							insertPoint = FlightsOfIdeasCommon.project_2d_position(transformMatrix.inverse*@textEntities[txt][1], transformMatrix, group[0])
							@textEntities[txt][6] = insertPoint[0].to_mm
							@textEntities[txt][7] = insertPoint[1].to_mm
						end						
					end
				end			
			
				# Get loops that bound face
				loops = group[i].loops			
				
				@pointArrayGFXY[groupIndex][i] = Array.new(loops.length)
				for j in 0...loops.length
		
					edges = loops[j].edges			
					
					# Get vertices
					vertices = loops[j].vertices		
					
					# New loop of points				
					@pointArrayGFXY[groupIndex][i][j] = Array.new(vertices.length)							
						
					# Process vertices
					for k in 0...vertices.length
						
						# Calculate 2D point
						point = FlightsOfIdeasCommon.project_2d_point(vertices[k], transformMatrix, group[0])

						# Store point
						point = point.to_a
						@pointArrayGFXY[groupIndex][i][j][k] = Array.new(3)
						@pointArrayGFXY[groupIndex][i][j][k][0] = point[0].to_mm
						@pointArrayGFXY[groupIndex][i][j][k][1] = point[1].to_mm							
						
						# Find out if edge is across face (etch), or on boundary (cut), or should be dropped (already part of another group as a boundary)
						etch = false
						drop = false
						if edges[k].faces
							for l in 0...edges[k].faces.length
								for m in 0...group.length
									if (edges[k].faces[l] == group[m]) and (edges[k].faces[l] != group[i])
										etch = true
										if m < i 
											drop = true
										end
									end
								end
							end
						end
						
						# Set cutting parameters
						if etch 
							@pointArrayGFXY[groupIndex][i][j][k][2] = 2.0
						else 
							@pointArrayGFXY[groupIndex][i][j][k][2] = 1.0
						end
						if drop or ((edges[k].hidden?) and not (@exportHiddenLines))
							@pointArrayGFXY[groupIndex][i][j][k][2] = 0
						end
							
						# Update min and max XY for face
						if point[0].to_mm < @minx[groupIndex] 
							@minx[groupIndex] = point[0].to_mm
						end
						if point[1].to_mm < @miny[groupIndex] 
							@miny[groupIndex] = point[1].to_mm
						end
						if point[0].to_mm > @maxx[groupIndex] 
							@maxx[groupIndex] = point[0].to_mm
						end
						if point[1].to_mm > @maxy[groupIndex] 
							@maxy[groupIndex] = point[1].to_mm
						end
					end					
				end
			elsif group[i].typename == "Edge" 
				
				# Calculate 2D point
				pointS = FlightsOfIdeasCommon.project_2d_point(group[i].start, transformMatrix, group[0])
				pointE = FlightsOfIdeasCommon.project_2d_point(group[i].end, transformMatrix, group[0])
							
				# Store points		
				@pointArrayGFXY[groupIndex][i] = Array.new(1)		
				@pointArrayGFXY[groupIndex][i][0] = Array.new(2)
				@pointArrayGFXY[groupIndex][i][0][0] = Array.new(3)
				@pointArrayGFXY[groupIndex][i][0][0][0] = pointS[0].to_mm
				@pointArrayGFXY[groupIndex][i][0][0][1] = pointS[1].to_mm
				@pointArrayGFXY[groupIndex][i][0][0][2] = 3.0
				@pointArrayGFXY[groupIndex][i][0][1] = Array.new(3)
				@pointArrayGFXY[groupIndex][i][0][1][0] = pointE[0].to_mm
				@pointArrayGFXY[groupIndex][i][0][1][1] = pointE[1].to_mm
				@pointArrayGFXY[groupIndex][i][0][1][2] = 3.0
			end
		end
	end

	#######################################################
	# Create SVG by parsing Sketchup selected entities
	#######################################################	
	def parse_selection() 
			
		@textEntities=Array.new
		entities = Sketchup.active_model.entities
		for i in 0...entities.length
			collect_text_entities entities[i]
		end			
			
		# Initialise 2D point storage
		@faceGroups=Array.new
					
		selection=Sketchup.active_model.selection;
		
		# Grouped joined and colinear faces
		for i in 0...selection.length			
			self.group_joined_faces selection[i]
		end
		
		# Group edges that are on a face (or add as own groups)
		if (@exportOrphanLines)
			for i in 0...selection.length			
				self.group_orphan_edges selection[i]
			end			
		end
			
		@pointArrayGFXY = Array.new(@faceGroups.length)
			
		@minx = Array.new(@faceGroups.length)
		@maxx = Array.new(@faceGroups.length)
		@miny = Array.new(@faceGroups.length)
		@maxy = Array.new(@faceGroups.length)
		for i in 0...@faceGroups.length			
			self.parse_groups(@faceGroups[i],i)
		end	
	end

	#######################################################
	# Write the current selected faces to an SVG file
	#######################################################	
	def create_svg()
		
		#  Check if file already exists		
		if File.exist?(@svgFilename)
			code = UI.messagebox "File exists, are you sure you want to overwrite?", MB_OKCANCEL, "Error"		
			if code == 2
				return
			end
		end
		
		# Check if writeable
		if (File.exist?(@svgFilename)) and (not File.writable?(@svgFilename))			
			UI.messagebox "Problem opening "+@svgFilename+" for writing", MB_OK, "Error"
			return
		end
		
		# Open file
		@svgFile = nil
		@svgFile = File.new(@svgFilename, "w")
		if not @svgFile			
			UI.messagebox "Problem opening "+@svgFilename+" for writing", MB_OK, "Error"
			return
		end
		
		# Parse the selected face geometry (stored in @pointArrayXY)
		parse_selection	

		# Translate points into positive XY space with origin at border, border
		border = @paperBorder.to_f

		# For each loop
		height = 0;
		pageX = 0;
		pageY = 0;

		for g in 0...@pointArrayGFXY.length
			
			# Change global maximums and minimums if using inches
			if @units == "in"
				@minx[g] = @minx[g]*0.0393700787
				@miny[g] = @miny[g]*0.0393700787
				@maxy[g] = @maxy[g]*0.0393700787
				@maxx[g] = @maxx[g]*0.0393700787
			end
			for f in 0...@pointArrayGFXY[g].length	

				# If a text entity references the current face
				for txt in 0...@textEntities.length
					if (@textEntities[txt][4] == g) and (@textEntities[txt][5] == f)
						if @units == "in"
							@textEntities[txt][6] = @textEntities[txt][6]*0.0393700787
							@textEntities[txt][7] = @textEntities[txt][7]*0.0393700787
						end
						@textEntities[txt][6] = (@textEntities[txt][6]-@minx[g])+border;
						@textEntities[txt][7] = ((@textEntities[txt][7]-@miny[g])+border+height);
					end
				end

				for i in 0...@pointArrayGFXY[g][f].length

					# For points in loop
					for j in 0...@pointArrayGFXY[g][f][i].length
						
						# Change units if using inches
						if @units == "in"
							@pointArrayGFXY[g][f][i][j][0] = @pointArrayGFXY[g][f][i][j][0]*0.0393700787
							@pointArrayGFXY[g][f][i][j][1] = @pointArrayGFXY[g][f][i][j][1]*0.0393700787
						end		

						# Move points to reflect border and bounds
						@pointArrayGFXY[g][f][i][j][0] = (@pointArrayGFXY[g][f][i][j][0] - @minx[g])+border;
						@pointArrayGFXY[g][f][i][j][1] = (@pointArrayGFXY[g][f][i][j][1] - @miny[g])+border+height;
						
						# Record new page size for SVG
						if @pointArrayGFXY[g][f][i][j][0]  > pageX
							pageX = @pointArrayGFXY[g][f][i][j][0]
						end
						if @pointArrayGFXY[g][f][i][j][1]  > pageY
							pageY = @pointArrayGFXY[g][f][i][j][1]
						end
					end
				end
			end

			# Recalculate
			height = (@maxy[g]- @miny[g])+height+border;
		end
		
		pageX = (pageX+border);
		pageY = (pageY+border);
		
		# Write header to file
		@svgFile.write "<?xml version=\"1.0\" standalone=\"no\"?>\n"
		
		# SVG DTD
		@svgFile.write "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n"
		
		# SVG width and height in mm
		@svgFile.write "<svg width=\""+pageX.to_s+@units+"\" height=\""+pageY.to_s+@units+"\"\n"
		
		# SVG view of objects
		@svgFile.write " viewBox=\"0 0 "+pageX.to_s+" "+pageY.to_s+"\"\n"
		
		# SVG 1.1 namespace
		@svgFile.write " xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\"\n"
		
		# XLink namesapce
		@svgFile.write " xmlns:xlink=\"http://www.w3.org/1999/xlink\">\n"
		
		# SVG description
		@svgFile.write "<desc>Output from Flights of Ideas SVG Sketchup Plugin</desc>\n\n"
		
		# Write text to file
		if (@exportAnnotations)
			@svgFile.write "<g id=\"text_annotations\" font-size=\""+@annotationHeight.to_s+"\" stroke=\"#"+@annotationRGB+"\" stroke-width=\""+@annotationWidth.to_s+"\">\n"			
			for txt in 0...@textEntities.length
						
				# If a text entitiy references this face
				if (@textEntities[txt][3])
					if (@annotationType == "SVG")
						lines = @textEntities[txt][0].split("\n");
						@svgFile.write "<text style=\"fill:none\" stroke=\"#"+@annotationRGB+"\" stroke-width=\""+@annotationWidth.to_s+"\" x=\""+@textEntities[txt][6].to_s+"\" y=\""+@textEntities[txt][7].to_s+"\">"
						for line in 0...lines.length
							lines[line] = lines[line].sub(/\&/) {|s| s = "&amp;"}
							lines[line] = lines[line].sub(/\"/) {|s| s = "&quot;"}
							lines[line] = lines[line].sub(/\</) {|s| s = "&lt;"}
							lines[line] = lines[line].sub(/\>/) {|s| s = "&gt;"}
							@svgFile.write "\n<tspan dy=\""+@annotationHeight.to_s+"\" "
							if line > 0
								@svgFile.write "x=\""+@textEntities[txt][6].to_s+"\""
							end
							@svgFile.write ">"+lines[line]+"</tspan>";
						end
						@svgFile.write "\n</text>\n"
					else
						svg = LaserScript.getSvgText(@textEntities[txt][0]) 
						scale = @annotationHeight.to_f/LaserScript.getHeight
						svg = "  <g transform=\"translate("+@textEntities[txt][6].to_s+","+@textEntities[txt][7].to_s+") scale("+scale.to_s+")\" fill=\"none\" stroke=\"#"+@annotationRGB+"\" stroke-width=\""+(@annotationWidth.to_f/scale).to_s+"\" stroke-miterlimit=\"4\" stroke-dasharray=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\">\n"+svg
						svg = svg+"  </g>\n";	
						@svgFile.write svg
					end
				end
			end
			@svgFile.write "</g>\n"
		end
	  	  
		# Group
		faceNumber=0
			
		if @exportSvgType == "lines"
			
			# Write each face as a series of grouped lines
			for g in 0...@pointArrayGFXY.length
				for f in 0...@pointArrayGFXY[g].length
					@svgFile.write "  <g id=\"face"+faceNumber.to_s+"\" fill=\"none\" stroke=\"#"+@outlineRGB+"\" stroke-width=\""+@outlineWidth.to_s+"\" stroke-miterlimit=\"4\" stroke-dasharray=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\">\n"
					for i in 0...@pointArrayGFXY[g][f].length											
							
						# For points in loop
						for j in 0...@pointArrayGFXY[g][f][i].length-1
							if @pointArrayGFXY[g][f][i][j][2] > 0.0
								
								# If internal line (etch)
								if @pointArrayGFXY[g][f][i][j][2] == 2.0 and @exportInternalLines
									@svgFile.write "    <line stroke-width=\""+@dissectWidth.to_s+"\" stroke=\"#"+@dissectRGB+"\" x1=\""+@pointArrayGFXY[g][f][i][j][0].to_s+"\" y1=\""+@pointArrayGFXY[g][f][i][j][1].to_s+"\" x2=\""+@pointArrayGFXY[g][f][i][j+1][0].to_s+"\" y2=\""+@pointArrayGFXY[g][f][i][j+1][1].to_s+"\"/>\n"									
								elsif @pointArrayGFXY[g][f][i][j][2] == 1.0
									@svgFile.write "    <line x1=\""+@pointArrayGFXY[g][f][i][j][0].to_s+"\" y1=\""+@pointArrayGFXY[g][f][i][j][1].to_s+"\" x2=\""+@pointArrayGFXY[g][f][i][j+1][0].to_s+"\" y2=\""+@pointArrayGFXY[g][f][i][j+1][1].to_s+"\"/>\n"
								elsif @pointArrayGFXY[g][f][i][j][2] == 3.0 and @exportOrphanLines	
									@svgFile.write "    <line stroke-width=\""+@orphanWidth.to_s+"\" stroke=\"#"+@orphanRGB+"\" x1=\""+@pointArrayGFXY[g][f][i][j][0].to_s+"\" y1=\""+@pointArrayGFXY[g][f][i][j][1].to_s+"\" x2=\""+@pointArrayGFXY[g][f][i][j+1][0].to_s+"\" y2=\""+@pointArrayGFXY[g][f][i][j+1][1].to_s+"\"/>\n"																		
								end
							end
						end
						
						# Join to start						
						if @pointArrayGFXY[g][f][i][j+1][2] > 0.0
							if @pointArrayGFXY[g][f][i][j+1][2] == 2.0 and @exportInternalLines								
								@svgFile.write "    <line stroke-width=\""+@dissectWidth.to_s+"\" stroke=\"#"+@dissectRGB+"\" x1=\""+@pointArrayGFXY[g][f][i][j+1][0].to_s+"\" y1=\""+@pointArrayGFXY[g][f][i][j+1][1].to_s+"\" x2=\""+@pointArrayGFXY[g][f][i][0][0].to_s+"\" y2=\""+@pointArrayGFXY[g][f][i][0][1].to_s+"\"/>\n"
							elsif @pointArrayGFXY[g][f][i][j+1][2] == 1.0
								@svgFile.write "    <line x1=\""+@pointArrayGFXY[g][f][i][j+1][0].to_s+"\" y1=\""+@pointArrayGFXY[g][f][i][j+1][1].to_s+"\" x2=\""+@pointArrayGFXY[g][f][i][0][0].to_s+"\" y2=\""+@pointArrayGFXY[g][f][i][0][1].to_s+"\"/>\n"
							elsif @pointArrayGFXY[g][f][i][j+1][2] == 3.0 and @exportOrphanLines							
								@svgFile.write "    <line stroke-width=\""+@orphanWidth.to_s+"\" stroke=\"#"+@orphanRGB+"\" x1=\""+@pointArrayGFXY[g][f][i][j+1][0].to_s+"\" y1=\""+@pointArrayGFXY[g][f][i][j+1][1].to_s+"\" x2=\""+@pointArrayGFXY[g][f][i][0][0].to_s+"\" y2=\""+@pointArrayGFXY[g][f][i][0][1].to_s+"\"/>\n"
							end								
						end															
					end
					@svgFile.write "  </g>\n"
					faceNumber = faceNumber+1;					
				end
			end			
		else
		
			# Write each face as a path (thanks Uli)
			for g in 0...@pointArrayGFXY.length
				for f in 0...@pointArrayGFXY[g].length
					@svgFile.write "  <path id=\"face"+faceNumber.to_s+"-cut\"\n"
					@svgFile.write " style=\"fill:none;stroke:#"+@outlineRGB+";stroke-width:"+@outlineWidth.to_s+";stroke-miterlimit:4;stroke-dasharray:none;stroke-linejoin:round;stroke-linecap:round\"\n"
					@svgFile.write "        d=\""
					for i in 0...@pointArrayGFXY[g][f].length
						@svgFile.write "M "+@pointArrayGFXY[g][f][i][0][0].to_s+","+@pointArrayGFXY[g][f][i][0][1].to_s+" "				
					
						# For points in loop
						for j in 1...@pointArrayGFXY[g][f][i].length		
							if @pointArrayGFXY[g][f][i][j-1][2] == 1.0
								@svgFile.write "L "+@pointArrayGFXY[g][f][i][j][0].to_s+","+@pointArrayGFXY[g][f][i][j][1].to_s+" "
							else
								@svgFile.write "M "+@pointArrayGFXY[g][f][i][j][0].to_s+","+@pointArrayGFXY[g][f][i][j][1].to_s+" "
							end
						end
						
						if @pointArrayGFXY[g][f][i][j][2] == 1.0
							@svgFile.write "L "+@pointArrayGFXY[g][f][i][0][0].to_s+","+@pointArrayGFXY[g][f][i][0][1].to_s+" "	
						end
					end	
					@svgFile.write "\"\n"
					@svgFile.write "  />\n"
					faceNumber = faceNumber+1;
				end
			end
			
			# If there are etch lines - they have to be seperate paths
			faceNumber=0
			if @exportInternalLines
				for g in 0...@pointArrayGFXY.length
					for f in 0...@pointArrayGFXY[g].length
						@svgFile.write "  <path id=\"face"+faceNumber.to_s+"-interior\"\n"
						@svgFile.write " style=\"fill:none;stroke:#"+@dissectRGB+";stroke-width:"+@dissectWidth.to_s+";stroke-miterlimit:4;stroke-dasharray:none;stroke-linejoin:round;stroke-linecap:round\"\n"
						@svgFile.write "        d=\""
						for i in 0...@pointArrayGFXY[g][f].length
							@svgFile.write "M "+@pointArrayGFXY[g][f][i][0][0].to_s+","+@pointArrayGFXY[g][f][i][0][1].to_s+" "				
						
							# For points in loop
							for j in 1...@pointArrayGFXY[g][f][i].length		
								if @pointArrayGFXY[g][f][i][j-1][2] == 2.0
									@svgFile.write "L "+@pointArrayGFXY[g][f][i][j][0].to_s+","+@pointArrayGFXY[g][f][i][j][1].to_s+" "
								else
									@svgFile.write "M "+@pointArrayGFXY[g][f][i][j][0].to_s+","+@pointArrayGFXY[g][f][i][j][1].to_s+" "
								end
							end
							
							if @pointArrayGFXY[g][f][i][j][2] == 2.0
								@svgFile.write "L "+@pointArrayGFXY[g][f][i][0][0].to_s+","+@pointArrayGFXY[g][f][i][0][1].to_s+" "
							end
						end	
						@svgFile.write "\"\n"
						@svgFile.write "  />\n"
						faceNumber = faceNumber+1;
					end
				end	
			end
			
			# If there are orphan lines - they have to be seperate paths
			faceNumber=0
			if @exportOrphanLines
				for g in 0...@pointArrayGFXY.length
					for f in 0...@pointArrayGFXY[g].length
						@svgFile.write "  <path id=\"face"+faceNumber.to_s+"-interior\"\n"
						@svgFile.write " style=\"fill:none;stroke:#"+@orphanRGB+";stroke-width:"+@orphanWidth.to_s+";stroke-miterlimit:4;stroke-dasharray:none;stroke-linejoin:round;stroke-linecap:round\"\n"
						@svgFile.write "        d=\""
						for i in 0...@pointArrayGFXY[g][f].length
							@svgFile.write "M "+@pointArrayGFXY[g][f][i][0][0].to_s+","+@pointArrayGFXY[g][f][i][0][1].to_s+" "				
						
							# For points in loop
							for j in 1...@pointArrayGFXY[g][f][i].length		
								if @pointArrayGFXY[g][f][i][j-1][2] == 3.0
									@svgFile.write "L "+@pointArrayGFXY[g][f][i][j][0].to_s+","+@pointArrayGFXY[g][f][i][j][1].to_s+" "
								else
									@svgFile.write "M "+@pointArrayGFXY[g][f][i][j][0].to_s+","+@pointArrayGFXY[g][f][i][j][1].to_s+" "
								end
							end
							
							if @pointArrayGFXY[g][f][i][j][2] == 3.0
								@svgFile.write "L "+@pointArrayGFXY[g][f][i][0][0].to_s+","+@pointArrayGFXY[g][f][i][0][1].to_s+" "
							end
						end	
						@svgFile.write "\"\n"
						@svgFile.write "  />\n"
						faceNumber = faceNumber+1;
					end
				end	
			end			
		end
			
		# Write footer and close
		@svgFile.write "</svg>\n"				
		
		@svgFile.close	
		
		self.export_ok_dialog();		
		
		# Execute SVG editor
		if (@svgEditor)
			if (@svgEditor.length > 0)
				IO.popen "\""+@svgEditor+"\" \""+@svgFilename+"\""
			end
		end
		
	end

end