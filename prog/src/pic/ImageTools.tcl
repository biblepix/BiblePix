# ~/Biblepix/prog/src/pic/ImgTools.tcl
# Image manipulating procs
# Sourced by SetupGui & Image
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated: 16jan21 pv

#Check for Img package
if [catch {package require Img} ] {
  tk_messageBox -type ok -icon error -title "BiblePix Error Message" -message $packageRequireImg
  exit
}


#####################################################################
################ General procs ######################################
#####################################################################

proc getRandomBMP {} {
  #Ausgabe ohne Pfad
  set bmplist [getBMPlist]
  set randIndex [expr {int(rand()*[llength $bmplist])}]
  return [lindex $bmplist $randIndex]
}

proc getRandomPhotoPath	{} {
  #Ausgabe JPG/PNG mit Pfad
  global platform dirlist
  if {$platform=="unix"} {
    set imglist [glob -nocomplain -directory $dirlist(photosDir) *.jpg *.jpeg *.JPG *.JPEG *.png *.PNG]
  } elseif {$platform=="windows"} {
    set imglist [glob -nocomplain -directory $dirlist(photosDir) *.jpg *.jpeg *.png]
  }
  return [ lindex $imglist [expr {int(rand()*[llength $imglist])}] ] 
}

proc setPngFileName {fileName} {
  set fileExt [file extension $fileName]
  if {![regexp png|PNG $fileExt]} {
    set fileName "[file rootname $fileName].png"
  }
  return $fileName
}

proc calcAverage {list} {
  foreach n $list {
    incr sum $n
  }
  set avg [expr $sum / [llength $list]]
  return $avg
}

#############################################################
############### Colour procs ################################
#############################################################

# rgb2hex
##computes r/g/b array into a hex digit
##called by LoadConfig etc.
proc rgb2hex {arrname} {
  upvar $arrname myarr
  set hex [format "#%02x%02x%02x" $myarr(r) $myarr(g) $myarr(b)]
  return $hex
}
proc hex2rgb {hex} {
  lassign [scan $hex "#%2x %2x %2x"] r g b
  return "$r $g $b"
}
# setShade
##reduces colour array's r/g/b by $shadefactor, avoiding values below 0
##with args = return as hex
##called by BdfPrint
proc setShade {arrname args} {
  global shadefactor
  upvar $arrname myarr
  
  set shadeR [expr max(int($shadefactor*$myarr(r)),0)]
  set shadeG [expr max(int($shadefactor*$myarr(g)),0)]
  set shadeB [expr max(int($shadefactor*$myarr(b)),0)]

  #A) without args return as r g b
  if {$args == ""} {
    return "$shadeR $shadeG $shadeB"
  #B) with args return as hex
  } else {
    array set myarr "r $shadeR g $shadeG b $shadeB"
    return [rgb2hex myarr]
  }
}
# setSun
##increases colour array's r/g/b by $sunfactor, avoiding values over 255
##with args = return as hex
##called by BdfPrint
proc setSun {arrname args} {
  global sunfactor
  upvar $arrname myarr
  set sunR [expr min(int($sunfactor*$myarr(r)),255)]
  set sunG [expr min(int($sunfactor*$myarr(g)),255)]
  set sunB [expr min(int($sunfactor*$myarr(b)),255)]
  
  #A) without args return as r g b
  if {$args == ""} {
    return "$sunR $sunG $sunB"
  #B) with args return as hex
  } else {
    array set myarr "r $sunR g $sunG b $sunB"
    return [rgb2hex myarr]
  }
}
# setBdfFontcolour
##uses above procs & exports hex values to ::colour NS
##called by BdfPrint
proc setBdfFontcolours {fontcolortext} {
  ##get font array from fontcolortext
  append fontArrname $fontcolortext Arr
  global $fontArrname
  array set regArr [array get $fontArrname]
  ##export vars to ::colour
  namespace eval colour {
    variable regHex
    variable sunHex
    variable shaHex
  }
  set colour::regHex [rgb2hex regArr]
  set colour::sunHex [setSun regArr ashex]
  set colour::shaHex [setSun regArr ashex]
}
# getAreaLuminacy
##computes luminance 1-3 for canvas text section
##called by BdfPrint & SetupRepos
proc getAreaLuminacy {c textitem} {
  global pnginfo lumThreshold
  
  #get image name from canvas
  set img [lindex [$c itemconf img -image] end]
  
  #A) for Biblepix/BdfPrint: check if pnginfo exists & return
  if [info exists pnginfo] {
    set lum $pnginfo(Luminacy)
    return $lum
  }

  #B) For Setup: compute text area luminacy
  puts "Scanning text area for luminance..."
  lassign [$c bbox $textitem] x1 y1 x2 y2
  set skip 2
  set leftmost $x1
  set rightmost $x2
  set topmost $y1
  set botmost $y2 

  #scan given canvas area
  for {set yPos $topmost} {$yPos < $botmost} {incr yPos $skip} {
    for {set xPos $leftmost} {$xPos < $rightmost} {incr xPos $skip} {
      #add up r+g+b to sumTotal, dividing sum by 3 for each rgb
      lassign [$img get $xPos $yPos] r g b
      incr sumTotal [expr int($r + $g + $b)]
      incr numColours 3
    }
  }
  set avLum [expr int($sumTotal / $numColours)]

  ##very dark
  if {$avLum <= $lumThreshold} {
    set lum 1
  ##very bright
  } elseif {$avLum >= [expr $lumThreshold * 2]} {
    set lum 3
  ##normal
  } else {
    set lum 2
  }

  return $lum
} ;#END getAreaLuminacy
 
# setFontShades
##computes font shades according to luminance of background colour 
##returns 3 hex values: reg/sun/shade
##called by setCanvasFontColour
proc setFontShades {fontcolortext lum} {
  global BlackArr BlueArr GreenArr SilverArr GoldArr
  
  #1)Determine colour arrays
#  set arrName [join $fontcolortext Arr]
#  array set regArr [array get $arrName]
  array set regArr [array get ${fontcolortext}Arr]
  lassign [setShade regArr] shaR shaG shaB
  lassign [setSun regArr] sunR sunG sunB
  array set shaArr "r $shaR g $shaG b $shaB"
  array set sunArr "r $sunR g $sunG b $sunB"
  
  #2)Compute hex values
  ##Normal (=lum 2)  
  set regHex [rgb2hex regArr]
  set sunHex [rgb2hex sunArr]
  set shaHex [rgb2hex shaArr]
  ##Dunkel
  if {$lum == 1} {
    set shaHex $regHex
    set regHex $sunHex
    set shaHex [setSun sunArr ashex]
  ##Hell
  } elseif {$lum == 3} {
    set sunHex $regHex
    set regHex $shaHex
    set shaHex [setShade shaArr ashex]
  }
  return "$regHex $sunHex $shaHex"
}


################################################################
################# Cutting procs ################################
################################################################

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
