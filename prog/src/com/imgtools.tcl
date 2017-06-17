# ~/Biblepix/prog/src/com/imgtools.tcl
# Image manipulating procs
# Called by SetupGui & Image
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated: 17jun17

package require Img

####### Procs for $Hgbild #####################


proc rgb2hex {rgb} {
#called by setShade + setSun
	set rgblist [split $rgb]
	set hex [format "#%02x%02x%02x" [lindex $rgblist 0] [lindex $rgblist 1] [lindex $rgblist 2] ]
	return $hex
}

proc hex2rgb {hex} {
#called by Hgbild 
	set rgb [scan $hex "#%2x %2x %2x"]
	foreach i [split $rgb] {
		lappend rgblist $i
	}
	return $rgb
}

proc setShade {rgb} {
#called by ??? - now in Setup, var saved to Config!!!
global shadefactor
	foreach c [split $rgb] {
		lappend shadergb [expr {int($shadefactor*$c)}]
	}
	#darkness values under 0 don't matter 	
	set shade [rgb2hex $shadergb]
	return $shade
}

proc setSun {rgb} {
#called by Hgbild
global sunfactor
	foreach c [split $rgb] {
		lappend sunrgbList [expr {int($sunfactor*$c)}]
	} 

	#avoid brightness values over 255
	foreach i $sunrgbList {
		if {$i>255} {set i 255}
		lappend sunrgb $i
	}
	set sun [rgb2hex $sunrgb]
	return $sun
}

proc setCanvasText {fontcolor} {
global inttextCanv internationaltext
	set rgb [hex2rgb $fontcolor]
	set shade [setShade $rgb]
	set sun [setSun $rgb]
	$inttextCanv itemconfigure main -fill $fontcolor
	$inttextCanv itemconfigure sun -fill $sun
	$inttextCanv itemconfigure shade -fill $shade
}

proc checkImgSize {hgfile} {
#Checks and resizes badly fitting hgbild
global screenx screeny
	
	#Compare img dimensions with screen dimensions
	set imgx [image width hgbild]
	set imgy [image height hgbild]

	set reqRatio [expr $screenx./$screeny]
	set imgRatio [expr $imgx./$imgy]

puts "Real image height: $imgy"

	#Bild zu hoch
	if {$imgRatio<$reqRatio} {

	set reqImgY  [expr round($imgx/$reqRatio)]
	set diffY [expr round($imgy - $reqImgY)]

puts "Difference: $diffY"
	
	#Bild zu breit
	} else {

	set reqImgX [expr round($imgy*$reqRatio)]
	set diffX  [expr round($imgx - $reqImgX)]

puts "ReqImgX $reqImgX"
puts "Difference: $diffX"
	}

if { [info exists diffY] } {

puts "Cuttyng Y..."
	
		cutY hgbild $imgx $imgy $diffY
	
	} elseif  { [info exists diffX] } {
		
		cutX hgbild $imgx $imgy $diffX
}




	#2. Resize evenly
	resize hgbild $screenx $screeny
	
#3. Overwrite corrected image - T O D O  - resized JPEGs tend to be worse quality !!!!!!!!!!!!!!!!!!!!!!!!	
	hgbild write $hgfile -format JPEG
			
} ;#end checkImageSize

# Syntax: oberen Punkt einer Diagonale: x1+y1
# mit unterem Punkt: x2+y2 verbinden
#  0/0 ######
#  #######
#  ####### 7/3

proc cutX {src imgx imgy diffX} {
#TODO GEHT NICHT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#Cuts left+right edges by $diffX/2
	puts "Cutting X $diffX"
	set diffhalb [expr $diffX/2]
puts $diffX
puts $diffhalb
	regsub {\-} $diffhalb {} diffhalb	
	image create photo ausschnitt
	
	set x1 $diffhalb
	set y1 0
	set x2 [expr $imgx-$diffhalb]
	set y2 $imgy
	ausschnitt copy $src -from $x1 $y1 $x2 $y2 -shrink
	
	$src blank 
	$src copy ausschnitt 
#	ausschnitt blank	
	return $src
}

proc cutY {src imgx imgy diffY} {	
#Cuts top+bottom edges by $diffY/2
	puts "Cutting Y $diffY"
	set diffhalb [expr $diffY/2]
	regsub {\-} $diffhalb {} diffhalb
	image create photo ausschnitt
		
	set x1 0
	set y1 $diffhalb
	set x2 $imgx
	set y2 [expr $imgy-$diffhalb]
	ausschnitt copy $src -from $x1 $y1 $x2 $y2 -shrink

	$src blank
	$src copy ausschnitt -shrink
	ausschnitt blank
	return $src
}

proc resize {src newx newy {dest ""} } { 
#Proc called for even-sided resizing, after cutting
 #  Decsription:  Copies a source image to a destination
 #   image and resizes it using linear interpolation
 #
 #  Parameters:   newx   - Width of new image
 #                newy   - Height of new image
 #                src    - Source image
 #                dest   - Destination image (optional)
 #
 #  Returns:      destination image
 #  Author: David Easton, wiki.tcl.tk, 2004 - God bless you David, you have saved us a lot of trouble!

 ######## IDEAL FOR EVEN SIDED ZOOMING ############# pv
	
	set mx [image width $src]
	set my [image height $src]
	
	puts "Resizing from $mx $my to $newx $newy" 
	
	if { "$dest" == ""} {
		set dest [image create photo]
	}
	$dest configure -width $newx -height $newy
	
	# Check if we can just zoom using -zoom option on copy
	if { $newx % $mx == 0 && $newy % $my == 0} {
		set ix [expr {$newx / $mx}]
		set iy [expr {$newy / $my}]
		$dest copy $src -zoom $ix $iy
		return $dest
	}
	
	set ny 0
	set ytot $my
	
	for {set y 0} {$y < $my} {incr y} {
		
		#
		# Do horizontal resize
		#
		
		foreach {pr pg pb} [$src get 0 $y] {break}
		
		set row [list]
		set thisrow [list]
		
		set nx 0
		set xtot $mx
		
		for {set x 1} {$x < $mx} {incr x} {
			
			# Add whole pixels as necessary
			while { $xtot <= $newx } {
				lappend row [format "#%02x%02x%02x" $pr $pg $pb]
				lappend thisrow $pr $pg $pb
				incr xtot $mx
				incr nx
			}
			
			# Now add mixed pixels
			
			foreach {r g b} [$src get $x $y] {break}
			
			# Calculate ratios to use
			
			set xtot [expr {$xtot - $newx}]
			set rn $xtot
			set rp [expr {$mx - $xtot}]
			
			# This section covers shrinking an image where
			# more than 1 source pixel may be required to
			# define the destination pixel
			
			set xr 0
			set xg 0
			set xb 0
			
			while { $xtot > $newx } {
				incr xr $r
				incr xg $g
				incr xb $b
				
				set xtot [expr {$xtot - $newx}]
				incr x
				foreach {r g b} [$src get $x $y] {break}
			}
			
			# Work out the new pixel colours
			
			set tr [expr {int( ($rn*$r + $xr + $rp*$pr) / $mx)}]
			set tg [expr {int( ($rn*$g + $xg + $rp*$pg) / $mx)}]
			set tb [expr {int( ($rn*$b + $xb + $rp*$pb) / $mx)}]
			
			if {$tr > 255} {set tr 255}
			if {$tg > 255} {set tg 255}
			if {$tb > 255} {set tb 255}
			
			# Output the pixel
			
			lappend row [format "#%02x%02x%02x" $tr $tg $tb]
			lappend thisrow $tr $tg $tb
			incr xtot $mx
			incr nx
			
			set pr $r
			set pg $g
			set pb $b
		}
		
		# Finish off pixels on this row
		while { $nx < $newx } {
			lappend row [format "#%02x%02x%02x" $r $g $b]
			lappend thisrow $r $g $b
			incr nx
		}
		
		#
		# Do vertical resize
		#
		
		if {[info exists prevrow]} {
			
			set nrow [list]
			
			# Add whole lines as necessary
			while { $ytot <= $newy } {
				
				$dest put -to 0 $ny [list $prow]
				
				incr ytot $my
				incr ny
			}
			
			# Now add mixed line
			# Calculate ratios to use
			
			set ytot [expr {$ytot - $newy}]
			set rn $ytot
			set rp [expr {$my - $rn}]
			
			# This section covers shrinking an image
			# where a single pixel is made from more than
			# 2 others.  Actually we cheat and just remove 
			# a line of pixels which is not as good as it should be
			
			while { $ytot > $newy } {
				
				set ytot [expr {$ytot - $newy}]
				incr y
				continue
			}
			
			# Calculate new row
			
			foreach {pr pg pb} $prevrow {r g b} $thisrow {
				
				set tr [expr {int( ($rn*$r + $rp*$pr) / $my)}]
				set tg [expr {int( ($rn*$g + $rp*$pg) / $my)}]
				set tb [expr {int( ($rn*$b + $rp*$pb) / $my)}]
				
				lappend nrow [format "#%02x%02x%02x" $tr $tg $tb]
			}
			
			$dest put -to 0 $ny [list $nrow]
			
			incr ytot $my
			incr ny
		}
		
		set prevrow $thisrow
		set prow $row
		
		update idletasks
	}
	
	# Finish off last rows
	while { $ny < $newy } {
		$dest put -to 0 $ny [list $row]
		incr ny
	}
	update idletasks
	
	return $dest
}

