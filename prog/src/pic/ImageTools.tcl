# ~/Biblepix/prog/src/pic/ImgTools.tcl
# Image manipulating procs
# Sourced by SetupGui & Image
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated: 2jan21 pv

#Check for Img package
if [catch {package require Img} ] {
  tk_messageBox -type ok -icon error -title "BiblePix Error Message" -message $packageRequireImg
  exit
}

proc getRandomBMP {} {
  #Ausgabe ohne Pfad
  set bmplist [getBMPlist]
  set randIndex [expr {int(rand()*[llength $bmplist])}]
  return [lindex $bmplist $randIndex]
}

proc getRandomPhotoPath	 {} {
  #Ausgabe JPG/PNG mit Pfad
  global platform dirlist
  if {$platform=="unix"} {
    set imglist [glob -nocomplain -directory $dirlist(photosDir) *.jpg *.jpeg *.JPG *.JPEG *.png *.PNG]
  } elseif {$platform=="windows"} {
    set imglist [glob -nocomplain -directory $dirlist(photosDir) *.jpg *.jpeg *.png]
  }
  return [ lindex $imglist [expr {int(rand()*[llength $imglist])}] ] 
}

proc calcAverage {list} {
  foreach n $list {
    incr sum $n
  }
  set avg [expr $sum / [llength $list]]
  return $avg
}

# rgb2hex
##computes r/g/b into a hex digit
##called by LoadConfig etc.
proc rgb2hex {r g b} {
  #set rgblist [split $rgb]
  #set hex [format "#%02x%02x%02x" [lindex $rgblist 0] [lindex $rgblist 1] [lindex $rgblist 2] ]
  set hex [format "#%02x%02x%02x" $r $g $b]
  return $hex
}

proc hex2rgb {hex} {

  lassign [scan $hex "#%2x %2x %2x"] r g b
#  foreach i [split $rgb] {
#    lassign 
#    lappend rgblist $i
#  }
  return "$r $g $b"
}

# setShade
##reduces r/g/b by $shadefactor, avoiding values below 0
##with args = return as hex
##called by BdfPrint
proc setShade {r g b args} {
  global shadefactor
  set shadeR [expr max(int($shadefactor*$r),0)]
  set shadeG [expr max(int($shadefactor*$g),0)]
  set shadeB [expr max(int($shadefactor*$b),0)]
  #A) without args return as r g b
  if {$args == ""} {
    return "$shadeR $shadeG $shadeB"
  #B) with args return as hex
  } else {
    return [rgb2hex $shadeR $shadeG $shadeB]
  }
}

# setSun
##increases r/g/b (or one single colour) by $sunfactor, avoiding values over 255
##with args = return as hex
##called by BdfPrint
proc setSun {r g b args} {
  global sunfactor
  set sunR [expr min(int($sunfactor*$r),255)]
  set sunG [expr min(int($sunfactor*$g),255)]
  set sunB [expr min(int($sunfactor*$b),255)]
  
  #A) without args return as r g b
  if {$args == ""} {
    return "$sunR $sunG $sunB"
  #B) with args return as hex
  } else {
    return [rgb2hex $sunR $sunG $sunB]
  }
}

proc setPngFileName {fileName} {
  set fileExt [file extension $fileName]
  if {![regexp png|PNG $fileExt]} {
    set fileName "[file rootname $fileName].png"
  }
  return $fileName
}

# trimPic
## Reduces pic size by cutting 1 or more edges
## pic must be a function or a variable
## called by doResize
proc trimPic {pic x1 y1 x2 y2} {
  set cutPic [image create photo]
  $cutPic copy $pic -from $x1 $y1 $x2 $y2 -shrink
  return $cutPic
}

# resizePic
## TODOS: CHANGE NAME? MOVE TO BACKGROUND!!!!
## called for even-sided resizing, after cutting
proc resizePic {src newx newy} { 

 #  Decsription:  Copies a source image to a destination
 #   image and resizes it using linear interpolation
 #
 #  Parameters:   newx   - Width of new image
 #                newy   - Height of new image
 #                src    - Source image
 #
 #  Returns:      destination image
 #  Author: David Easton, wiki.tcl.tk, 2004 - God bless you David, you have saved us a lot of trouble!

 ######## IDEAL FOR EVEN SIDED ZOOMING , else picture is distorted ##########

  set mx [image width $src]
  set my [image height $src]

  set dest [image create photo]

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

      update
    }

    set prevrow $thisrow
    set prow $row

    update
  }

  # Finish off last rows
  while { $ny < $newy } {
    $dest put -to 0 $ny [list $row]
    incr ny
  }
  update
  
  puts $dest
  return $dest
} ;#END resizePic
