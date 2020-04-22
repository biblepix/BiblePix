# ~/Biblepix/prog/src/pic/ImgTools.tcl
# Image manipulating procs
# Called by SetupGui & Image
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated: 19apr20 pv

#TODO pv change pic names to something reasonable - what's cutPic anyway Joel????

#Check for Img package
if [catch {package require Img} ] {
  tk_messageBox -type ok -icon error -title "BiblePix Error Message" -message $packageRequireImg
  exit
}

proc mean {rgbList} {
  namespace path {::tcl::mathop ::tcl::mathfunc}
  set average [/ [+ {*}$rgbList] [double [llength $rgbList]]]
  return [expr round($average)]
}

#called by setShade + setSun
proc rgb2hex {rgb} {
  set rgblist [split $rgb]
  set hex [format "#%02x%02x%02x" [lindex $rgblist 0] [lindex $rgblist 1] [lindex $rgblist 2] ]
  return $hex
}

proc hex2rgb {hex} {
  set rgb [scan $hex "#%2x %2x %2x"]
  foreach i [split $rgb] {
    lappend rgblist $i
  }
  return $rgb
}

# computeAvColours
##fetches R G B from a section & computes avarages into ::rgb namespace
##called by BdfPrint - TODO: still testing!!!
proc computeAvColours {img} {
  global marginleft margintop RtL
  #no. of pixels to be skipped
  set skip 5

  set imgX [image width $img]
  set imgY [image height $img]
  set x1 $marginleft
  set y1 $margintop
  set x2 [expr $imgX / 3]
  set y2 [expr $imgY / 3]

  if $RtL {
    set x2 [expr $imgX - $marginleft]
    set x1 [expr $x2 - ($imgX / 3)]
  }    

puts "Computing pixels..."

    for {set x $x1} {$x<$x2} {incr x $skip} {

      for {set y $y1} {$y<$y2} {incr y $skip} {
        
        lassign [$img get $x $y] r g b
        lappend R $r
        lappend G $g
        lappend B $b
      }
    }
puts "Done computing pixels"
#zisisnt workin, donno why...
return

  #Compute avarage colours
  set avR [mean $R]
  set avG [mean $G]
  set avB [mean $B]
  set avBri [mean [list $avR $avG $avB]]
#puts "avR $avR"
#puts "avG $avG"
#puts "avB $avB"

  #Export vars to ::rgb namespace
  catch {namespace delete rgb}
  namespace eval rgb {}
  set rgb::avRed $avR
  set rgb::avGreen $avG
  set rgb::avBlue $avB
  set rgb::avBrightness $avBri

  #Compute strong colour
  namespace path {::tcl::mathfunc}
  set rgb::maxCol [max $avR $avG $avB]
  set rgb::minCol [min $avR $avG $avB]

#puts "strongCol $rgb::maxCol"

  #Delete colour lists
  catch {unset R G B}


} ;#END computeAvColours


# changeFontColour - TODO just testing
#TODO: to be implemented in above! - MAY NOT BE NECESSARY!!!
#Theory: 
##wenn HG überwiegend dunkelblau, fontcolor-> silver
##wenn HG überwiegend dunkelgrün, fontcolor-> gold

#TODO don't change colour, but only shades of colour (brighter/darker)
proc changeFontColour {} {
  if {$rgb::avBrightness <= 100 &&
  [expr $rgb::maxCol - $rgb::minCol] > 70} {
  #puts "Not resetting colour."
    return 0
  }

  if {$rgb::maxCol == $rgb::avBlue} {
    set newFontcolortext silver
  } elseif {$rgb::maxCol == $rgb::avGreen} {
    set newFontcolortext gold
  }

  set rgb::fontcolortext $newFontcolortext
  puts "Changed font colour to $fontcolortext"
  return 1
}

proc setShade {rgb} {
#called by ??? - now in Setup, var saved to Config!!! ????
  global shadefactor
  foreach c [split $rgb] {
    lappend shadergb [expr {int($shadefactor*$c)}]
  }
  #darkness values under 0 don't matter   
  set shade [rgb2hex $shadergb]
  return $shade
}

#called by Hgbild
proc setSun {rgb} {
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

proc setPngFileName {fileName} {
  set fileExt [file extension $fileName]
  if {![regexp png|PNG $fileExt]} {
    set fileName "[file rootname $fileName].png"
  }
  return $fileName
}







# doResize
## organises all resizing processes
## called by addPic
proc doResize {canv} {
  set origX [image width photosOrigPic]
  set origY [image height photosOrigPic]
  
#TODO besser mit winfo, falls fenster überdeckt ...
  set canvX [lindex [$canv conf -width] end]
  set canvY [lindex [$canv conf -height] end]
  lassign [$canv bbox img] canvPicX1 canvPicY1 canvPicX2 canvPicY2
  
  set scale [expr $origX. / $canvX]
  if {[expr $canvY. * $scale] > $origY} {
    set scale [expr $origY. / $canvY]
  }
  
  set cutX1 [expr int($canvPicX1 * -1 * $scale)]
  set cutY1 [expr int($canvPicY1 * -1 * $scale)]
  set cutX2 [expr int($canvX * $scale + $cutX1)]
  set cutY2 [expr int($canvY * $scale + $cutY1)]
  
  set cutImg [trimPic photosOrigPic $cutX1 $cutY1 $cutX2 $cutY2]
  
  ResizeHandler::QueryResize $cutImg
  after idle {
    ResizeHandler::Run
    #openReposWin
  }
}




proc processResize {cutImg} {
  global dirlist picPath

  set screenX [winfo screenwidth .]
  set screenY [winfo screenheight .]

  NewsHandler::QueryNews "$::resizingPic" orange


#TODO vorläufig bleibt's in cutOrigPic - no saving!  
  set finalImage [resizePic $cutImg $screenX $screenY]
  image create photo cutOrigPic
  #resizePic $cutImg $screenX $screenY cutOrigPic

  set targetPicPath [file join $dirlist(photosDir) [setPngFileName [file tail $picPath]]]
  $finalImage write $targetPicPath -format PNG

#  image delete $cutImg
#image delete $finalImage

  NewsHandler::QueryNews "[copiedPicMsg $picPath]" lightblue

} ;#END doResize





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
proc resizePic {src newx newy {dest ""} } { 

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

 ######## IDEAL FOR EVEN SIDED ZOOMING , else picture is distorted ##########

  set mx [image width $src]
  set my [image height $src]

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