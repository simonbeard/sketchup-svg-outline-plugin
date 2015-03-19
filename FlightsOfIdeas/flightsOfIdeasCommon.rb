require 'sketchup.rb'

###########################################################
#
#    Google Sketchup Common Routines for Flights of Ideas Plugins
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

class FlightsOfIdeasCommon
	
	def initialize()
		@@exportFace = nil					# The face to export
		@@selectedEdge = nil					# The edge to export
		@@transformMatrix
	end
	
	#######################################################
	# Parse routine for context menu and toolbar
	#######################################################	
	def FlightsOfIdeasCommon.parse_for_face(suEntity)
		if suEntity.typename == "Face"
			if (@@exportFace == nil)
				@@exportFace = suEntity
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
	def FlightsOfIdeasCommon.contains_face(selection)	
		@@exportFace = nil
		
		for i in 0...selection.length
			self.parse_for_face selection[i]
		end
		if @@exportFace==nil
			return false
		end
		return true
	end
	
	#######################################################
	# Parse routine for context menu and toolbar
	#######################################################	
	def FlightsOfIdeasCommon.parse_for_edge(suEntity)
		if suEntity.typename == "Edge"
			if (@@selectedEdge == nil)
				@@selectedEdge = suEntity
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
	# Parse routine for context menu and toolbar (check if edges are selected)
	#######################################################	
	def FlightsOfIdeasCommon.contains_edge(selection)	
		@@selectedEdge = nil
		
		for i in 0...selection.length
			self.parse_for_edge selection[i]
		end
		if @@selectedEdge==nil
			return false
		end
		return true
	end	

	#######################################################
	# Parse parents of entity for transformations
	#######################################################	
	def FlightsOfIdeasCommon.parse_parent_transforms(suEntity)
		# If a group then process transforms within
		if suEntity.typename == "Group"
			if (suEntity.transformation)
				@@transformMatrix = @@transformMatrix * suEntity.transformation				
			end
		
		# If a component definition holding group then process transforms within
		elsif suEntity.typename == "ComponentDefinition"				
			if (suEntity.group?)
				for instance in 0...suEntity.instances.length
					parse_parent_transforms(suEntity.instances[instance])
				end
			end
		
		# If a component then process transforms within
		elsif suEntity.typename == "ComponentInstance"
			if (suEntity.transformation)
				@@transformMatrix = @@transformMatrix * suEntity.transformation				
			end	
		end
		
		# Recursive call to this function if parent exists (and is not root - active model)
		if suEntity.parent
			if suEntity.parent != Sketchup.active_model
				self.parse_parent_transforms suEntity.parent
			end
		end
		
		
	end
	
	#######################################################
	# Parse parents of entity for transformations
	#######################################################	
	def FlightsOfIdeasCommon.get_transform_product(suEntity)
		@@transformMatrix = Geom::Transformation.new	
			
		# Get parent transformations
		if suEntity.parent
			if suEntity.parent != Sketchup.active_model
				self.parse_parent_transforms(suEntity.parent)
			end
		end	
		
		return @@transformMatrix		
	end	

	#######################################################
	# Find vector resolution for transforming to 2D
	#######################################################	
	def FlightsOfIdeasCommon.calculate_2d_vector(vec1, vec2, norm)
					
		# Check for non vectors
		if vec1.x==0 and vec1.y==0 and vec1.z==0
			vec3 = Geom::Vector3d.new(0,0,0)
			return vec3
		end
		if vec2.x==0 and vec2.y==0 and vec2.z==0
			vec3 = Geom::Vector3d.new(0,0,0)
			return vec3
		end
		if norm.x==0 and norm.y==0 and norm.z==0
			vec3 = Geom::Vector3d.new(0,0,0)
			return vec3
		end
					
		# Find angle between vectors
		angle = vec1.angle_between vec2
		cross = vec1.cross vec2

		if (not vec1.valid?) or (not vec2.valid?)
			angle = 0
		elsif vec1.samedirection? vec2
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

		return vec3		
	end
	
	#######################################################
	# Project 3D point as 2D on a face
	#######################################################	
	def FlightsOfIdeasCommon.project_2d_point (vertex, tMatrix, face)
		refPoint = face.loops[0].vertices[0].position
		normal = face.normal
		axes = normal.axes		
		
		# Apply Sketchup transformation
		point = vertex.position											
		point = tMatrix*point
						
		# Express as vectors
		vec1 = Geom::Vector3d.new(point.x-refPoint.x,point.y-refPoint.y,point.z-refPoint.z)
		vec2 = normal.axes[1]			
		vec3 = FlightsOfIdeasCommon.calculate_2d_vector(vec1, vec2, normal)

		# Calculate 2D point
		point.x = refPoint.x+vec3.x
		point.y = refPoint.y+vec3.y
		
		return(point)
	end	
	
	#######################################################
	# Project 3D point as 2D on a face
	#######################################################	
	def FlightsOfIdeasCommon.project_2d_position (position, tMatrix, face)
		refPoint = face.loops[0].vertices[0].position
		normal = face.normal
		axes = normal.axes		
		
		# Apply Sketchup transformation
		point = position											
		point = tMatrix*point
						
		# Express as vectors
		vec1 = Geom::Vector3d.new(point.x-refPoint.x,point.y-refPoint.y,point.z-refPoint.z)
		vec2 = normal.axes[1]			
		vec3 = FlightsOfIdeasCommon.calculate_2d_vector(vec1, vec2, normal)

		# Calculate 2D point
		point.x = refPoint.x+vec3.x
		point.y = refPoint.y+vec3.y
		
		return(point)
	end		
		
end