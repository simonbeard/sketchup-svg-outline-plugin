#require 'sketchup.rb'
#require 'FlightsOfIdeas/flightsOfIdeasCommon.rb'

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

class LaserScript

		@@laserFontPath = {
			"a" => "M 3 7 L 3 3 L 0 4 L 0 7 L 3 6",
			"b" => "M 0 0 L 0 7 L 3 6 L 3 3 L 0 4",
			"c" => "M 3 3 L 0 4 L 0 7 L 3 6",		
			"d" => "M 3 0 L 3 7 M 3 3 L 0 4 L 0 7 L 3 6",
			"e" => "M 0 5 L 3 4 L 3 3 L 0 4 L 0 7 L 3 6 L 3 5",	
			"f" => "M 0 4 L 4 3 M 4 1 L 4 0 L 1 1 L 1 7",
			"g" => "M 0 8 L 0 9 L 3 8 L 3 3 L 0 4 L 0 7 L 3 6",
			"h" => "M 0 0 L 0 7 M 0 4 L 3 3 L 3 7",
			"i" => "M 0 2 L 0 3 M 0 4 L 0 7",
			"j" => "M 2 2 L 2 3 M 2 4 L 2 8 L 0 9 L 0 8",
			"k" => "M 0 0 L 0 7 M 3 3 L 0 4 L 3 7",
			"l" => "M 0 0 L 0 7",
			"m" => "M 0 3 L 0 7 M 0 4 L 2 3 L 2 4 L 4 3 L 4 7",
			"n" => "M 0 3 L 0 7 M 0 4 L 3 3 L 3 7",
			"o" => "M 0 4 L 3 3 L 3 6 L 0 7 L 0 4",
			"p" => "M 0 3 L 0 9 M 0 4 L 3 3 L 3 6 L 0 7",
			"q" => "M 3 6 L 0 7 L 0 4 L 3 3 L 3 9",
			"r" => "M 0 3 L 0 7 M 0 4 L 3 3",
			"s" => "M 3 3 L 0 4 L 0 5 L 3 4 L 3 6 L 0 7 L 0 6",
			"t" => "M 0 4 L 3 3 M 1 0 L 1 7",
			"u" => "M 0 4 L 0 7 L 3 6 M 3 3 L 3 7",
			"v" => "M 0 5 L 1 4 L 1 7 L 3 6 L 3 3 L 4 4",
			"w" => "M 0 4 L 0 7 L 2 6 L 2 7 L 4 6 L 4 4",
			"x" => "M 0 4 L 3 5 M 0 7 L 3 3",
			"y" => "M 0 4 L 0 7 L 3 6 M 3 3 L 3 8 L 0 9 L 0 8",
			"z" => "M 0 4 L 3 3 L 0 7 L 3 6",
			"A" => "M 0 7 L 0 2 L 3 1 L 3 7 M 0 4 L 3 3",
			"B" => "M 0 2 L 0 7 L 3 6 L 3 1 L 0 2 L 0 4 L 3 3",
			"C" => "M 3 1 L 0 2 L 0 7 L 3 6",		
			"D" => "M 0 2 L 0 7 L 3 6 L 3 2 L 0 2",
			"E" => "M 3 1 L 0 2 L 0 7 L 3 6 M 0 4 L 3 3",	
			"F" => "M 3 1 L 0 2 L 0 7 M 0 4 L 3 3",
			"G" => "M 3 1 L 0 2 L 0 7 L 3 6 M 2 4 L 3 4 L 3 7",
			"H" => "M 0 2 L 0 7 M 0 4 L 3 3 M 3 1 L 3 7",
			"I" => "M 0 1 L 0 7",
			"J" => "M 3 1 L 3 6 L 0 7 L 0 5",
			"K" => "M 0 2 L 0 7 M 3 1 L 0 4 L 3 6",
			"L" => "M 0 2 L 0 7 L 3 6",
			"M" => "M 0 1 L 0 7 M 0 2 L 2 1 L 2 2 L 4 1 L 4 7",
			"N" => "M 0 7 L 0 2 L 3 6 L 3 1",
			"O" => "M 0 2 L 0 7 L 3 6 L 3 1 L 0 2",
			"P" => "M 0 4 L 3 3 L 3 1 L 0 2 L 0 7",
			"Q" => "M 0 2 L 0 7 L 3 6 L 3 1 L 0 2 M 2 6 L 3 7 L 3 8",
			"R" => "M 0 7 L 0 2 L 3 1 L 3 3 L 0 4 L 3 6",
			"S" => "M 3 1 L 0 2 L 0 4 L 3 3 L 3 6 L 0 7 L 0 6",
			"T" => "M 1 1 L 1 7 M 0 2 L 3 1",
			"U" => "M 0 2 L 0 7 L 3 6 L 3 1 M 3 6 L 3 7",
			"V" => "M 0 2 L 2 6 L 4 1",
			"W" => "M 0 2 L 0 7 L 2 6 L 2 7 L 4 6 L 4 2",
			"X" => "M 0 2 L 3 6 M 3 1 L 0 7",
			"Y" => "M 0 2 L 2 3 L 4 1 M 2 3 L 2 7",
			"Z" => "M 0 2 L 3 1 L 0 7 L 3 6",	
			"\`" => "M 0 1 L 1 2",
			"~" => "M 0 2 L 2 1 L 2 2 L 4 1",
			"!" => "M 0 1 L 0 5 M 0 6 L 0 7",		
			"@" => "M 0 2 L 0 6 L 1 6 L 4 5 L 4 1 L 3 1 L 0 2 M 3 5 L 3 2 L 1 3 L 1 5 L 3 5",
			"#" => "M 0 4 L 5 2 M 0 6 L 5 4 M 1 2 L 1 7 M 4 1 L 4 6",	
			"$" => "M 3 2 L 0 3 L 0 4 L 3 3 L 3 5 L 0 6 M 1 1 L 1 7 M 2 1 L 2 7",
			"%" => "M 0 7 L 3 1 M 0 2 L 0 3 M 3 5 L 3 6",
			"^" => "M 0 3 L 2 1 L 3 2",
			"&" => "M 1 1 L 1 7 M 2 1 L 2 7 M 0 3 L 3 2 L 3 5 L 0 6 M 0 4 L 3 3",
			"*" => "M 0 2 L 3 5 M 3 1 L 0 6 M 0 4 L 3 3",
			"(" => "M 2 1 L 0 2 L 0 5 L 2 6",
			")" => "M 0 1 L 2 2 L 2 5 L 0 6",
			"-" => "M 0 4 L 3 3",
			"_" => "M 0 7 L 3 6",
			"+" => "M 0 5 L 4 3 M 2 2 L 2 6",
			"=" => "M 0 4 L 3 3 M 0 5 L 3 4",
			"[" => "M 2 1 L 0 2 L 0 7 L 2 6",
			"]" => "M 0 2 L 2 1 L 2 6 L 0 7",
			"{" => "M 3 1 L 1 2 L 1 4 L 0 5 L 1 5 L 1 7 L 3 6",
			"}" => "M 0 2 L 2 1 L 2 3 L 3 3 L 2 4 L 2 6 L 0 7",
			"|" => "M 0 1 L 0 3 M 0 5 L 0 7",
			"\\" => "M 0 2 L 3 6",
			":" => "M 0 2 L 0 3 M 0 4 L 0 5",
			";" => "M 1 2 L 1 3 M 1 4 L 0 5",
			"," => "M 1 2 L 1 3 M 1 4 L 0 5",
			"\"" => "M 0 1 L 0 2 M 1 1 L 1 2",
			"\'" => "M 0 1 L 0 2",	
			"<" => "M 3 2 L 0 4 L 3 6",	
			">" => "M 0 2 L 3 4 L 0 6",	
			"," => "M 0 7 L 1 6",	
			"." => "M 0 7 L 1 7",	
			"?" => "M 0 2 L 3 1 L 3 3 L 1 4 L 1 5 M 1 6 L 1 7",
			"/" => "M 0 6 L 3 1",
			"1" => "M 0 3 L 0 7",
			"2" => "M 0 5 L 0 4 L 3 3 L 3 5 L 0 6 L 0 7 L 3 6",
			"3" => "M 0 4 L 3 3 L 3 6 L 0 7 M 0 5 L 3 4",		
			"4" => "M 0 4 L 0 6 L 3 5 M 3 3 L 3 7",
			"5" => "M 3 3 L 0 4 L 0 5 L 2 4 L 3 5 L 3 6 L 0 7",	
			"6" => "M 3 3 L 0 4 L 0 7 L 3 6 L 3 4 L 0 5",
			"7" => "M 0 4 L 3 3 L 1 7",
			"8" => "M 0 4 L 3 3 L 3 6 L 0 7 L 0 4 M 0 5 L 3 4",
			"9" => "M 3 5 L 0 6 L 0 4 L 3 3 L 3 6 L 0 7",
			"0" => "M 0 4 L 3 3 L 3 6 L 0 7 L 0 4"
		}
		
		@@laserFontSpacing = {
			"a" => [ 1, 3, 1 ],
			"b" => [ 1, 3, 1 ],
			"c" => [ 1, 3, 1 ],
			"d" => [ 1, 3, 1 ],
			"e" => [ 1, 3, 1 ],
			"f" => [ 1, 4, 0 ],
			"f" => [ 1, 3, 1 ],
			"g" => [ 1, 3, 1 ],
			"h" => [ 1, 3, 1 ],
			"i" => [ 1, 0, 1 ],
			"j" => [ 0, 2, 1 ],
			"k" => [ 1, 3, 1 ],
			"l" => [ 1, 0, 1 ],
			"m" => [ 1, 4, 1 ],
			"n" => [ 1, 3, 1 ],
			"o" => [ 1, 3, 1 ],
			"p" => [ 1, 3, 1 ],
			"q" => [ 1, 3, 1 ],
			"r" => [ 1, 3, 0 ],
			"s" => [ 1, 3, 1 ],
			"t" => [ 0, 3, 0 ],
			"u" => [ 1, 3, 1 ],
			"v" => [ 1, 4, 1 ],
			"w" => [ 1, 4, 1 ],
			"x" => [ 1, 3, 1 ],
			"y" => [ 1, 3, 1 ],
			"z" => [ 1, 3, 1 ],
			"A" => [ 1, 3, 1 ],
			"B" => [ 1, 3, 1 ],
			"C" => [ 1, 3, 1 ],
			"D" => [ 1, 3, 1 ],
			"E" => [ 1, 3, 1 ],
			"F" => [ 1, 3, 1 ],
			"G" => [ 1, 3, 1 ],
			"H" => [ 1, 3, 1 ],
			"I" => [ 1, 0, 1 ],
			"J" => [ 1, 3, 1 ],
			"K" => [ 1, 3, 1 ],
			"L" => [ 1, 3, 1 ],
			"M" => [ 1, 4, 1 ],
			"N" => [ 1, 3, 1 ],
			"O" => [ 1, 3, 1 ],
			"P" => [ 1, 3, 1 ],
			"Q" => [ 1, 3, 1 ],
			"R" => [ 1, 3, 1 ],
			"S" => [ 1, 3, 1 ],
			"T" => [ 1, 3, 1 ],
			"U" => [ 1, 3, 1 ],
			"V" => [ 1, 4, 1 ],
			"W" => [ 1, 4, 1 ],
			"X" => [ 1, 3, 1 ],
			"Y" => [ 1, 3, 1 ],
			"Z" => [ 1, 3, 1 ],	
			"\`" => [ 1, 1, 1 ],
			"~" => [ 1, 4, 1 ],
			"!" => [ 1, 0, 1 ],
			"@" => [ 1, 3, 1 ],
			"#" => [ 1, 5, 1 ],
			"$" => [ 1, 3, 1 ],
			"%" => [ 1, 3, 1 ],
			"^" => [ 1, 3, 1 ],
			"&" => [ 1, 3, 1 ],
			"*" => [ 1, 3, 1 ],
			"(" => [ 1, 2, 1 ],
			")" => [ 1, 2, 1 ],
			"-" => [ 1, 3, 1 ],
			"_" => [ 1, 3, 1 ],
			"+" => [ 1, 4, 1 ],
			"=" => [ 1, 3, 1 ],
			"[" => [ 1, 2, 1 ],
			"]" => [ 1, 2, 1 ],
			"{" => [ 1, 3, 1 ],
			"}" => [ 1, 3, 1 ],
			"|" => [ 1, 0, 1 ],
			"\\" => [ 1, 3, 1 ],
			":" => [ 1, 0, 1 ],
			";" => [ 1, 1, 1 ],
			"," => [ 1, 1, 1 ],
			"\"" => [ 1, 1, 1 ],
			"\'" => [ 1, 0, 1 ],
			"<" => [ 1, 3, 1 ],
			">" => [ 1, 3, 1 ],
			"," => [ 1, 1, 1 ],	
			"." => [ 1, 1, 1 ],
			"?" => [ 1, 3, 1 ],
			"/" => [ 1, 3, 1 ],
			"1" => [ 1, 0, 1 ],
			"2" => [ 1, 3, 1 ],
			"3" => [ 1, 3, 1 ],
			"4" => [ 1, 3, 1 ],
			"5" => [ 1, 3, 1 ],
			"6" => [ 1, 3, 1 ],
			"7" => [ 1, 3, 1 ],
			"8" => [ 1, 3, 1 ],
			"9" => [ 1, 3, 1 ],
			"0" => [ 1, 3, 1 ]
		}

	def initialize()

	end
	
	def LaserScript.getHeight() 
		return (9);
	end
	
	def LaserScript.getSvgText(text) 
		svg = "<g>";
		tX = 0;
		tY = 0;
		prevSpace=0
		for i in 0...text.length		
			str = String.new("X")
			str[0] = text[i]
			
			if (str=="\n")
				tY = tY+9
				tX = 0
				svg = svg+"</g><g>";
			elsif (str==" ")
				tX = tX+3
			elsif (str!="")				
				path = ""
				space = @@laserFontSpacing["X"][1]+@@laserFontSpacing["X"][2]
				prevSpace = @@laserFontSpacing["X"][2]
				path = @@laserFontPath["X"]
				if str.match(/[a-z,A-Z,0-9,\`,\~,\!,\@,\#,\$,\%,\^,\&,\*,\(,\),\_,\+,\-,\=,\{,\},\|,\[,\],\\,\;,\',\:,\",\,,\.,\/,\<,\>,\?]/)
					if (prevSpace > 0) and (@@laserFontSpacing[str][0] == 0)
						tX = tX-1
					end					
					path = @@laserFontPath[str]
					space = @@laserFontSpacing[str][1]+@@laserFontSpacing[str][2];
					prevSpace = @@laserFontSpacing[str][2]
				end
					
				svg = svg+"    <g fill=\"none\" transform=\"translate("+tX.to_s+","+tY.to_s+")\" >\n"
				svg = svg+"      <path d=\""+path+"\"/>\n";
				svg = svg+"    </g>\n";			
				tX = tX+space				
			end
		end
		svg = svg+"</g>";
		return(svg);
	end		
	
end
