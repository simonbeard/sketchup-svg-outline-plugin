require 'sketchup.rb'

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

class SvgTemplate
	
	#######################################################
	# New Template
	#######################################################	
	def initialize()					
		@svgFilename = "flightsOfIdeas.svg" 	# Name of file to which to export SVG templates		
		@dlg = nil							# The dialog object
		@dlgOpen = false					# Whether the ok dlg is currently open
		@okdlg = nil						# The ok dialog object
		@okdlgOpen = false					# Whether the dlg is currently open		
		@paperWidth = "210"					# A4 width
		@paperHeight = "297"					# A4 height
		@paperBorder = "10"					# 10mm border
		@exportFace = nil					# The face to make into an SVG file		
		@svgFile = nil						# The actual SVG file for writing
		@transformMatrix = Geom::Transformation.new # Global transform for points (initialise as identity)
		@minx = Array.new					# Min and Max XY of each face in mm
		@miny = Array.new
		@maxx = Array.new					
		@maxy = Array.new					
		@pointArrayFXY = Array.new				# Array for holding 2D projected points in mm of faces
		@faceIndex=0						# The current face being processed
		@scaleTemplate=1					# How much to scale for templates
		@units="mm"						# Units for dlg box
	end


	#######################################################
	# Create UI context menu for creating SVG templates
	#######################################################	
	def template_context_menu()
		UI.add_context_menu_handler { |menu|
			selection=Sketchup.active_model.selection
			if self.contains_face selection 
				menu.add_separator				
				item = menu.add_item("Create SVG template") { self.preferences_dialog(); }				
			end
		}
	end
	
	#######################################################
	# Create UI toolbar for creating SVG templates
	#######################################################	
	def template_toolbar()
		toolbar = UI::Toolbar.new "FlightsOfIdeas"

		cmd = UI::Command.new("Create SVG template") { 
			selection=Sketchup.active_model.selection
			if self.contains_face selection
				self.preferences_dialog();
			else
				UI.messagebox "You must select at least a single face", MB_OK, "Error"
			end
		}		
		path = Sketchup.find_support_file "Create.png", "plugins/FlightsOfIdeas/Images/"		
		cmd.small_icon = path
		cmd.large_icon = path
		cmd.tooltip = "Create SVG from selected face"
		cmd.status_bar_text = "Create SVG from selected face"
		cmd.menu_text = "Create"				
		toolbar = toolbar.add_item cmd
	
		cmd = UI::Command.new("flightsofideas") { 
			UI.openURL("http://www.flightsofideas.com")
		}		
		path = Sketchup.find_support_file "FlightsOfIdeas.png", "plugins/FlightsOfIdeas/Images/"		
		cmd.small_icon = path
		cmd.large_icon = path
		cmd.tooltip = "Flights of Ideas Website"
		cmd.status_bar_text = "Flights of Ideas Website"
		cmd.menu_text = "Flights of Ideas Website"				
		toolbar = toolbar.add_item cmd
		
		toolbar.show
	end
	
	#######################################################
	# Parse routine for context menu and toolbar
	#######################################################	
	def parse_for_face(suEntity)
		if suEntity.typename == "Face"
			if (@exportFace == nil)
				@exportFace = suEntity
			else
				@multipleFacesSelected = true
			end
		elsif suEntity.typename == "Group"
			for i in 0...suEntity.entities.length						
				self.parse_for_face suEntity.entities[i]
			end			
		elsif suEntity.typename == "ComponentInstance"
			for i in 0...suEntity.definition.entities.length						
				self.parse_for_face suEntity.definition.entities[i]
			end			
		end		
	end	
	
	#######################################################
	# Parse routine for context menu and toolbar (make sure that one face is selected)
	#######################################################	
	def contains_face(selection)	
		@exportFace = nil
		
		for i in 0...selection.length
			self.parse_for_face selection[i]
		end
		if @exportFace==nil
			return false
		end
		return true
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
			html = File.dirname(__FILE__) + "/svgTemplateDialog.html";
			if (html.length == 0)
				return false;
			end
			
			# Create new dlg
			@dlg = UI::WebDialog.new("SVG Template Preferences", false, "FlightsOfIdeas", 670, 290, 300, 150, true);

			# Set close callback function
			@dlg.add_action_callback("on_close") {|d,p| @dlgOpen = false; d.close(); }
			
			# Set close callback function
			@dlg.add_action_callback("on_ok") {|d,p| @dlgOpen = false; d.close(); args = p.split(','); 
				@paperBorder = args[0]; @svgFilename=args[1]; @scaleTemplate=args[2].to_f;  @units=args[3];
				create_svg;}			
					
			# Set save as callback function
			@dlg.add_action_callback("on_file_save") {|d,p| 							
				name = p.split('/')
				name = name[name.length-1]
						
				output_filename = UI.savepanel("Export to SVG", "", name);
				
				if (output_filename)
					name = output_filename.split('\\')
					@svgFilename = name[0]
					for i in 1...name.length
						@svgFilename  = @svgFilename+'/'+name[i]
					end					
				end
				
				cmd = "setFilename('"+@svgFilename+"');";				
				d.execute_script(cmd);
			}			
			
			# Show the dlg
			@dlg.set_background_color("f3f0f0");
			@dlg.set_file(html, nil)
			@dlg.show{
				scaleCheck = "false";
				if (@scaleTemplate != 1)
					scaleCheck = "true"
				end
				cmd = "setDefaults('"+@svgFilename+","+@paperBorder+","+scaleCheck+","+@units+"');";				
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
			@okdlg = UI::WebDialog.new("SVG Export Ok", false, "FlightsOfIdeasOk", 400, 190, 300, 150, true);

			# Set close callback function
			@okdlg.add_action_callback("on_close") {|d,p| @okdlgOpen = false; d.close(); }
			
			# Set close callback function
			@okdlg.add_action_callback("on_ok") {|d,p| @dlgOpen = false; d.close(); }	

			# Set close callback function
			@okdlg.add_action_callback("on_launch") {|d,p| UI.openURL("file://"+@svgFilename); }
			
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
	# Parse parents of entity for transformations
	#######################################################	
	def parse_parent_transforms(suEntity)
		
		# If a group then process transforms within
		if suEntity.typename == "Group"
			if (suEntity.transformation)
				@transformMatrix = @transformMatrix * suEntity.transformation
			end
		
		# If a component then process transforms within
		elsif suEntity.typename == "ComponentInstance"
			if (suEntity.transformation)
				@transformMatrix = @transformMatrix * suEntity.transformation
			end	
		end
		
		# Recursive call to this function if parent exists (and is not root - active model)
		if suEntity.parent
			if suEntity.parent != Sketchup.active_model
				parse_parent_transforms (suEntity.parent)
			end
		end
	end

	#######################################################
	# Create SVG by parsing Sketchup selected entities
	#######################################################	
	def parse_selected_entity(suEntity)
		if suEntity.typename == "Face"			

			# Initialise global transform
			@transformMatrix = Geom::Transformation.new	

			# Get parent transformations
			if suEntity.parent
				if suEntity.parent != Sketchup.active_model
					parse_parent_transforms(suEntity.parent)
				end
			end				
			
			# Get normal, and right and up axes
			norm = suEntity.normal
			axes = norm.axes

			# Get loops that bound face
			loops = suEntity.loops
			@pointArrayFXY[@faceIndex] = Array.new(loops.length)
			for i in 0...loops.length
			
				# Get vertices
				vertices = loops[i].vertices

				# New loop of points				
				@pointArrayFXY[@faceIndex][i] = Array.new(vertices.length)		
				
				# Initialise if first loop
				startLoop=0
				if (i == 0)
					
					# Start from point 0
					lastPoint = vertices[0].position
					lastPoint = @transformMatrix*lastPoint				
					
					# Start 2D plot from XY of first point
					last2dPoint = lastPoint

					# Store points
					point = last2dPoint.to_a
					@pointArrayFXY[@faceIndex][i][0] = Array.new(2)
					@pointArrayFXY[@faceIndex][i][0][0] = point[0].to_mm
					@pointArrayFXY[@faceIndex][i][0][1] = point[1].to_mm					
					
					# Initialise min and max XY for face
					@minx[@faceIndex] = point[0].to_mm
					@miny[@faceIndex] = point[1].to_mm
					@maxx[@faceIndex] = point[0].to_mm
					@maxy[@faceIndex] = point[1].to_mm
					
					# Skip first point
					startLoop = 1
				end
					
				# Process vertices
				for j in startLoop...vertices.length
					
					# Apply Sketchup transformation
					point = vertices[j].position											
					point = @transformMatrix*point					
					
					# Express as vectors
					vec1 = Geom::Vector3d.new(point.x-lastPoint.x,point.y-lastPoint.y,point.z-lastPoint.z);
					vec2 = axes[1];				
					
					# Find angle between vectors
					angle = vec1.angle_between vec2
					cross = vec1.cross vec2
					if vec1.samedirection? vec2
						angle = 0
					elsif vec1.parallel? vec2
						angle = Math::PI
					elsif not cross.samedirection? norm
						angle = angle * -1
					end
					
					# Find length of line
					magnitude = Math.sqrt((vec1.x*vec1.x)+(vec1.y*vec1.y)+(vec1.z*vec1.z))
					
					# Plot along x-axis
					vec3 = Geom::Vector3d.new(magnitude,0,0);

					# Create rotation matrix for xy axes (around z)
					rotation = Geom::Transformation.rotation Geom::Point3d.new(0,0,0), Geom::Vector3d.new(0,0,1), angle
					
					# Apply matrix rotation
					vec3 = rotation * vec3

					# Calculate 2D point
					last2dPoint.x = last2dPoint.x+vec3.x
					last2dPoint.y = last2dPoint.y+vec3.y

					# Update for next iteration
					lastPoint = point;					
					
					# Store points
					point = last2dPoint.to_a
					@pointArrayFXY[@faceIndex][i][j] = Array.new(2)
					@pointArrayFXY[@faceIndex][i][j][0] = point[0].to_mm
					@pointArrayFXY[@faceIndex][i][j][1] = point[1].to_mm
					
					# Update min and max XY for face
					if point[0].to_mm < @minx[@faceIndex]
						@minx[@faceIndex] = point[0].to_mm
					end
					if point[1].to_mm < @miny[@faceIndex]
						@miny[@faceIndex] = point[1].to_mm
					end
					if point[0].to_mm > @maxx[@faceIndex]
						@maxx[@faceIndex] = point[0].to_mm
					end
					if point[1].to_mm > @maxy[@faceIndex]
						@maxy[@faceIndex] = point[1].to_mm
					end						
				end							
			end
			@faceIndex=@faceIndex+1
		# If a group then process entities within
		elsif suEntity.typename == "Group"
			for i in 0...suEntity.entities.length						
				self.parse_selected_entity suEntity.entities[i]
			end
		# If a component then process entities within
		elsif suEntity.typename == "ComponentInstance"
			for i in 0...suEntity.definition.entities.length						
				self.parse_selected_entity suEntity.definition.entities[i]
			end			
		end
	end

	#######################################################
	# Create SVG by parsing Sketchup selected entities
	#######################################################	
	def parse_selection() 
		
		# Initialise 2D point storage
		@pointArrayXY = Array.new
		@faceIndex=0
		
		selection=Sketchup.active_model.selection;
		for i in 0...selection.length
			self.parse_selected_entity selection[i]
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
		for f in 0...@faceIndex
			for i in 0...@pointArrayFXY[f].length

				# For points in loop
				for j in 0...@pointArrayFXY[f][i].length
					@pointArrayFXY[f][i][j][0] = (@pointArrayFXY[f][i][j][0] - @minx[f])+border;
					@pointArrayFXY[f][i][j][1] = (@pointArrayFXY[f][i][j][1] - @miny[f])+border+height;
					if @pointArrayFXY[f][i][j][0]  > pageX
						pageX = @pointArrayFXY[f][i][j][0]
					end
					if @pointArrayFXY[f][i][j][1]  > pageY
						pageY = @pointArrayFXY[f][i][j][1]
					end
				end
			end
			
			# Recalculate
			height = (@maxy[f]- @miny[f])+height+border;
		end
		
		pageX = (pageX+border)*@scaleTemplate;
		pageY = (pageY+border)*@scaleTemplate;
		
		# Write header to file
		@svgFile.write "<?xml version=\"1.0\" standalone=\"no\"?>\n"
		
		# SVG DTD
		@svgFile.write "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n"
		
		# SVG width and height in mm
		@svgFile.write "<svg width=\""+pageX.to_s+"mm\" height=\""+pageY.to_s+"mm\"\n"
		
		# SVG view of objects
		@svgFile.write " viewBox=\"0 0 "+pageX.to_s+" "+pageY.to_s+"\"\n"
		
		# SVG 1.1 namespace
		@svgFile.write " xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\"\n"
		
		# XLink namesapce
		@svgFile.write " xmlns:xlink=\"http://www.w3.org/1999/xlink\">\n"
		
		# SVG description
		@svgFile.write "<desc>Output from Flights of Ideas SVG Sketchup Plugin</desc>\n\n"
	  	  
		# Group
		faceNumber=0
	  
		
		# Scale for template
		# For each loop
		for f in 0...@faceIndex			
			for i in 0...@pointArrayFXY[f].length

				# For points in loop
				for j in 0...@pointArrayFXY[f][i].length					
					@pointArrayFXY[f][i][j][0] = @pointArrayFXY[f][i][j][0]*@scaleTemplate
					@pointArrayFXY[f][i][j][1] = @pointArrayFXY[f][i][j][1]*@scaleTemplate
				end
			end
		end
									
		for f in 0...@faceIndex
			@svgFile.write "  <g id=\"face"+faceNumber.to_s+"\" fill=\"none\" stroke=\"rgb(0,0,255)\" stroke-width=\"1\">\n"
			for i in 0...@pointArrayFXY[f].length

				# For points in loop
				for j in 0...@pointArrayFXY[f][i].length-1
					@svgFile.write "    <line x1=\""+@pointArrayFXY[f][i][j][0].to_s+"\" y1=\""+@pointArrayFXY[f][i][j][1].to_s+"\" x2=\""+@pointArrayFXY[f][i][j+1][0].to_s+"\" y2=\""+@pointArrayFXY[f][i][j+1][1].to_s+"\"/>\n"
				end
				@svgFile.write "    <line x1=\""+@pointArrayFXY[f][i][j+1][0].to_s+"\" y1=\""+@pointArrayFXY[f][i][j+1][1].to_s+"\" x2=\""+@pointArrayFXY[f][i][0][0].to_s+"\" y2=\""+@pointArrayFXY[f][i][0][1].to_s+"\"/>\n"			
			end	
			@svgFile.write "  </g>\n"
			faceNumber = faceNumber+1;
		end
		
		# Write footer and close
		@svgFile.write "</svg>\n"
		@svgFile.close
		
		self.export_ok_dialog();		
	end

end