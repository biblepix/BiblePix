# ~/Biblepix/prog/src/setup/setupTools.tcl
# Procs used in Setup, called by SetupGui
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated: 27may2020 pv 
 
source $JList

#######################################################################
###### P r o c s   f o r   N e w s   h a n d l i n g ##################
#######################################################################

namespace eval NewsHandler {
  namespace export QueryNews

  variable queryTextJList ""
  variable queryColorJList ""
  variable counter 0
  variable isShowing 0

  proc QueryNews {text color} {
    variable queryTextJList
    variable queryColorJList
    variable counter

    set queryTextJList [jappend $queryTextJList $text]
    set queryColorJList [jappend $queryColorJList $color]

    incr counter

    ShowNews
  }

  proc ShowNews {} {
    variable queryTextJList
    variable queryColorJList
    variable counter
    variable isShowing

    if {$counter > 0} {
      if {!$isShowing} {
        set isShowing 1

        set text [jlfirst $queryTextJList]
        set queryTextJList [jlremovefirst $queryTextJList]

        set color [jlfirst $queryColorJList]
        set queryColorJList [jlremovefirst $queryColorJList]

        incr counter -1

        .news configure -bg $color
        set ::news $text

        after 7000 {
          NewsHandler::FinishShowing
        }
      }
    }
  }

  proc FinishShowing {} {
    variable isShowing

    .news configure -bg grey
    set ::news "biblepix.vollmar.ch"
    set isShowing 0

    ShowNews
  }
}

##########################################################################
###### P r o c s   f o r   S e t u p G U I   +   S e t u p D e s k t o p #
##########################################################################

# setCanvasFontSize
##changes canvas font's size||weight||family
##called by SetupGUI for intTextCanv
proc setCanvasFontSize args {
  if [string is integer $args] {
    #set size in pt as in BDF
    font conf intCanvFont -size $args
    font conf movingTextFont -size [expr round($args / 3) + 3]
    
  } elseif {$args == "bold" || $args == "normal"} {
    font conf intCanvFont -weight $args
    font conf movingTextFont -weight $args
    
  } elseif {$args == "Serif" || $args == "Sans"} {
    font conf intCanvFont -family $args
    font conf movingTextFont -family $args
  }
  return 0 
}

# setCanvasFontColour
##changes canvas' font's colour
##called by SetGUI for inttextCanv & .textposCanv
proc setCanvasFontColour {c colour} {
  
  set rgb [hex2rgb $colour]
  set shade [setShade $rgb]
  set sun [setSun $rgb]
  
  #A) International Canvas
  $c itemconf main -fill $colour
  $c itemconf sun -fill $sun
  $c itemconf shade -fill $shade
  
  return 0
}

# Grey out all spinboxes if !$enablepic
proc setSpinState {imgyesState} {

  if {$imgyesState} {
    set com normal
  } else {
    set com disabled
  }
  lappend widgetlist .showdateBtn .slideBtn .slideSpin .fontcolorSpin .fontsizeSpin .fontweightBtn .fontfamilySpin

  foreach i $widgetlist {
    $i configure -state $com
  }
}

# Grey out Slideshow spinbox if !enableSlideshow
proc setSlideSpin {state} {
  global slideshow

  if {$state==1} {
    .slideSpin conf -state normal
    #set standard if changed from 0
    if {$slideshow==0} {
      set slideshow 300
    }
    .slideSpin set $slideshow
    .slideTxt conf -fg black
    .slideSecTxt conf -fg black
  } else {
    .slideSpin conf -state disabled
    .slideSpin set 0
    .slideTxt conf -fg grey
    .slideSecTxt conf -fg grey
  }
}

proc setFlags {} {
global Flags
  #Configure language flags
  source $Flags
  flag::show .en -flag {hori blue; x white red; cross white red}
  flag::show .de -flag {hori black red yellow}
  .en config -relief raised
  .de config -relief raised

  #Configure English button
  bind .en <ButtonPress-1> {
    set lang en
    setTexts en
    .manualF.man configure -state normal
    .manualF.man replace 1.1 end [setManText en]
    .manualF.man configure -state disabled
    .en configure -relief flat
  }
  bind .en <ButtonRelease> { .en configure -relief raised}

  #Configure Deutsch button
  bind .de <ButtonPress-1> {
    set lang de
    setTexts de
    .manualF.man configure -state normal
    .manualF.man replace 1.1 end [setManText de]
    .de configure -relief flat
  }
  bind .de <ButtonRelease> { .de configure -relief raised}
}

# setManText
## Formats Manual & switches between languages
## called by [bind] above
proc setManText {lang} {
  global ManualD ManualE

  set manW .manualF.man
  $manW configure -state normal

  if {$lang=="de"} {
    set manFile $ManualD
  } elseif {$lang=="en"} {
    set manFile $ManualE
  }

  set chan [open $manFile]
  chan configure $chan -encoding utf-8
  set manText [read $chan]
  close $chan

  $manW replace 1.0 end $manText

  #Determine & tag headers
  set numLines [$manW count -lines 1.0 end]

  for {set line 1} {$line <= $numLines} {incr line} {

    ##Level H3 (all caps header) if min. 2 caps at beg. of line
    if { [$manW search -regexp {^[[:upper:]]{2}} $line.0 $line.end] != ""} {
      $manW tag add H3 $line.0 $line.end

    ##Level H2 (1x spaced Header)
    } elseif { [$manW search -regexp {^[[:upper:]] [[:upper:]]} $line.0 $line.end] != ""} {
      $manW tag add H2 $line.0 $line.end

    ##Level H1 (2x spaced Header)
    } elseif { [$manW search -regexp {^[[:upper:]]  [[:upper:]]} $line.0 $line.end] != ""} {
      $manW tag add H1 $line.0 $line.end

    ##Level Addenda (dash at line start > all following in small script)
    } elseif { [$manW search -regexp {^-} $line.0 $line.end] != ""} {
      $manW tag add Addenda $line.0 end
    }
  }


  #Configure font tags
  $manW tag conf H1 -font "TkCaptionFont 20 bold"
  $manW tag conf H2 -font "TkHeadingFont 16 bold"
  $manW tag conf H3 -font "TkSmallCaptionFont 14 bold"
  $manW tag conf Addenda -font "TkTooltipFont"
  ##tabs in pixels?
  $manW configure -tabs 30
  $manW configure -state disabled

}

#########################################################################
##### C A N V A S   M O V E   P R O C S #################################
#########################################################################

# createMovingTextBox
## Creates textbox with TW text on canvas $c
## Called by SetupDesktop & SetupResizePhoto
proc createMovingTextBox {c} {
  global marginleft margintop textPosFactor fontcolor fontsize fontfamily fontweight setupTwdText

  #Verkleinerungsfaktor für textposition window
  #set displayFactor 2
  
  set screenx [winfo screenwidth .]
  set screeny [winfo screenheight .]
  #set textPosSubwinX [expr $screenx/20]
  #set textPosSubwinY [expr $screeny/30]
  set x1 [expr $marginleft/$textPosFactor]
  set y1 [expr $margintop/$textPosFactor]
 
  #Create movingTextFont here, configure later with setCanvasFontSize
  catch {font create movingTextFont}
  catch {font create movingTextReposFont}

  set shadeX [expr $x1 + 1]
  set shadeY [expr $y1 + 1]
  set sunX [expr $x1 - 1]
  set sunY [expr $y1 - 1]

#source $ImgTools
  set rgb [hex2rgb $fontcolor]
  set shade [setShade $rgb]
  set sun [setSun $rgb]
  
  $c create text $shadeX $shadeY -anchor nw -justify left -tags {canvTxt txt mv shade} -fill $shade
  $c create text $sunX $sunY -anchor nw -justify left -tags {canvTxt txt mv sun} -fill $sun
  $c create text $x1 $y1 -anchor nw -justify left -tags {canvTxt txt mv main} -fill $fontcolor
  $c itemconf canvTxt -text $setupTwdText
  $c itemconf canvTxt -font movingTextFont -activefill red

} ;#END createMovingTextBox

# dragCanvasItem
##adapted from a proc by ? ...THANKS TO  ...
##called by SetupDesktop & setupRespositionText
proc dragCanvasItem {c item newX newY args} {

  set xDiff [expr {$newX - $::x}]
  set yDiff [expr {$newY - $::y}]

  #test margins before moving
  if {![info exists args]} {set args ""}
  
  if [checkItemInside $c $item $xDiff $yDiff $args] {
    $c move $item $xDiff $yDiff
  }
  set ::x $newX
  set ::y $newY
}

# checkItemInside
## makes sure movingItem stays inside canvas
## called by setupResizePhoto (tag: img) & setupDesktop moving text (tag: txt) 
## 'args' is for compulsory margin for text item
proc checkItemInside {c item xDiff yDiff args} {

  set canvX [lindex [$c conf -width] end]
  set canvY [lindex [$c conf -height] end]

  #A) Image (resizePic)
  if {$item == "img"} {
  
    set imgname [lindex [$c itemconf img -image] end]
    set itemX [image width $imgname]
    set itemY [image height $imgname]
    
    set can(maxx) 0
    set can(maxy) 0
    set can(minx) [expr ($canvX - $itemX)]
    set can(miny) [expr ($canvY - $itemY)]
   
  #B) Text (moving Text)
  } elseif {$item == "txt"} {

    lassign [$c bbox canvTxt] x1 y1 x2 y2
    set itemY [expr $y2 - $y1]
    set itemX [expr $x2 - $x1]

    set can(maxx) [expr $canvX - $itemX - $args]
    set can(maxy) [expr $canvY - $itemY - $args]
    set can(minx) $args
    set can(miny) $args
  }
  
  #item coords
  set itemPos [$c coords $item]

  #check min values
  foreach {x y} $itemPos {
    set x [expr $x + $xDiff]
    set y [expr $y + $yDiff]
    
    if {$x < $can(minx)} {
      return 0
          }
          
    if {$y < $can(miny)} {
      return 0
    }
    
    if {$x > $can(maxx)} {
      return 0
    }
    if {$y > $can(maxy)} {
      return 0
    }
  }
  return 1
  
} ;#END checkItemInside



##################################################################################
##### S E T U P   P H O T O S   P R O C S #########################################
##################################################################################

# addPic - called by SetupPhoto
# adds new Picture to BiblePix Photo collection
# setzt Funktion 'photosOrigPic' voraus und leitet Subprozesse ein
proc addPic {} {
  global picPath dirlist setupdir
  
  #TODO add file path to Globals
  source $setupdir/setupResizePhoto.tcl
  set targetPicPath [file join $dirlist(photosDir) [setPngFileName [file tail $picPath]]]
  
  #Check which original pic to use
  if [catch {image inuse rotateOrigPic}] {
    set origPic photosOrigPic
  } else {
    set origPic rotateOrigPic
  }
  
  if { [file exists $targetPicPath] } {
    NewsHandler::QueryNews $::picSchonDa red
    return 1
  }
  
  #export targetPicPath + scaleFactor + origPic to 'addpicture' namespace
  namespace eval addpicture {}
  set addpicture::targetPicPath $targetPicPath
  set addpicture::origPic $origPic
  
  #A) wrong size: open resizeWindow > reposWindow
  if [needsResize $origPic] {
  
    openResizeWindow
    
  #B) right size: save pic & open repos window
  } else {
    ##save pic
    $origPic write $targetPicPath -format PNG
    #image delete $origPic - DONT!
    NewsHandler::QueryNews "[copiedPicMsg $picPath]" lightblue
    
    openReposWindow

  }
  
} ;#END addPic

proc delPic {} {
  global fileJList picPath
  file delete $picPath
  set fileJList [deleteImg $fileJList .imgCanvas]
  NewsHandler::QueryNews "[deletedPicMsg $picPath]" orange
}

# needsResize
##compares photosOrigPic OR rotateOrigPic with screen dimensions
##called by addPic
proc needsResize {pic} {
  set screenX [winfo screenwidth .]
  set screenY [winfo screenheight .]

  set imgX [image width $pic]
  set imgY [image height $pic]

  #Compare img dimensions with screen dimensions
  if {$screenX == $imgX && $screenY == $imgY} {
    return 0
  } else {
    return 1
  }
}

# grabCanvSection
##berechnet resizeCanvPic Bildausschnitt für Kopieren nach reposCanvSmallPic
##called by addPic & ?processPngInfo?
proc grabCanvSection {c} { 
  
  lassign [$c bbox img] imgX1 imgY1 imgX2 imgY2
  set canvX [lindex [$c conf -width] end]
  set canvY [lindex [$c conf -height] end]

  set cutX1 0
  set cutY1 0
  set cutX2 $canvX
  set cutY2 $canvY
  
  ##alles gleich
  if {$imgX2 == $canvX &&
      $imgY2 == $canvY
  } {
    puts "No need for resizing."
    Return 0
  }
  
  ##Breite ungleich
  if {$imgX2 > $canvX} {
  
    puts "Breite verschieben"
    if {$imgX1 < 0} {
      set cutX1 [expr $imgX1 - ($imgX1 + $imgX1) ]
      set cutX2 [expr $canvX + $cutX1]

    ##nach rechts verschoben
    } else {
      set cutX1 0
      set cutX2 $canvX
    }
    
  ##Höhe ungleich
  } elseif {$imgY2 > $canvY} {
  
    puts "Höhe verschieben"
    if {$imgY1 < 0} {
      set cutY1 [expr $imgY1 - ($imgY1 + $imgY1) ]
      set cutY2 [expr $canvY + $cutY1]

    ##nach unten verschoben
    } else {
      set cutY1 0
      set cutY2 $canvY
    }
  
  }
  
  return "$cutX1 $cutY1 $cutX2 $cutY2"
  
} ;#END grabCanvSection

proc doOpen {bildordner c} {
  set localJList [openFileDialog $bildordner]
  refreshImg $localJList $c

  if {$localJList != ""} {
    pack .addBtn -in .photosF.mainf.right.unten -side left -fill x
  }

  pack .picPath -in .photosF.mainf.right.unten -side left -fill x
  pack .photosF.mainf.right.bar.collect -side right -fill x
  pack forget .delBtn

  #Add Rotate button
  pack .rotateBtn -in .photosF.mainf.right.unten -side right
  
  return $localJList
}

proc doCollect {c} {
  set localJList [refreshFileList]
  set localJList [step $localJList 0 .imgCanvas]
  refreshImg $localJList $c

  pack .delBtn .picPath -in .photosF.mainf.right.unten -side left -fill x
  pack forget .addBtn .photosF.mainf.right.bar.collect .rotateBtn

  return $localJList
}

proc step {localJList fwd c} {
  set localJList [jlstep $localJList $fwd]
  refreshImg $localJList $c

  return $localJList
}

proc openFileDialog {bildordner} {
  global types tcl_platform

  set storage ""
  set parted 0
  set localJList ""

  set selectedFile [tk_getOpenFile -filetypes $types -initialdir $bildordner]
  if {$selectedFile != ""} {
    set pos [string last "/" $selectedFile]
    set folder [string range $selectedFile 0 [expr $pos - 1]]

    if {$tcl_platform(os) == "Linux"} {
      set fileNames [glob -nocomplain -directory $folder *.jpg *.jpeg *.JPG *.JPEG *.png *.PNG]
    } elseif {$tcl_platform(platform) == "windows"} {
      set fileNames [glob -nocomplain -directory $folder *.jpg *.jpeg *.png]
    }

    foreach fileName $fileNames {
      if { [file exists $fileName] } {
        set localJList [jappend $localJList $fileName]
      } else {
        if {$parted} {
          append storage " " $fileName
          if { [file exists $storage] } {
            set parted 0
            set localJList [jappend $localJList $storage]
          }
        } else {
          set parted 1
          set storage $fileName
        }
      }
    }

    set fn [string range [jlfirst $localJList] [expr $pos + 1] end]
    set selectedFN [string range $selectedFile [expr $pos + 1] end]

    while {![string equal $fn $selectedFN]} {
      set localJList [jlstep $localJList 1]
      set fn [string range [jlfirst $localJList] [expr $pos + 1] end]
     }
  }

  return $localJList
}

proc refreshFileList {} {
  global tcl_platform dirlist
  set storage ""
  set parted 0
  set localJList ""

  if {$tcl_platform(os) == "Linux"} {
    set fileNames [glob -nocomplain -directory $dirlist(photosDir) *.jpg *.jpeg *.JPG *.JPEG *.png *.PNG]
  } elseif {$tcl_platform(platform) == "windows"} {
    set fileNames [glob -nocomplain -directory $dirlist(photosDir) *.jpg *.jpeg *.png]
  }

  foreach fileName $fileNames {
    if { [file exists $fileName] } {
      set localJList [jappend $localJList $fileName]
    } else {
      if {$parted} {
        append storage " " $fileName
        if { [file exists $storage] } {
          set parted 0
          set localJList [jappend $localJList $storage]
        }
      } else {
        set parted 1
        set storage $fileName
      }
    }
  }

  return $localJList
}

proc refreshImg {localJList c} {
  global picPath

  set fn ""
  if {$localJList != ""} {
    set fn [jlfirst $localJList]
    openImg $fn $c
    } else {
      hideImg $c
  }
  set picPath $fn
}

# openImg - called by refreshImg
#Creates functions 'photosOrigPic' and 'photosCanvPic'
##to be processed by all other progs (no vars!)
proc openImg {imgFilePath imgCanvas} {

  set screenX [winfo screenwidth .]
  set screenY [winfo screenheight .]
  set factor [expr $screenX./$screenY]
  set photosCanvMargin 6
  set photosCanvX 650
  set photosCanvY [expr round($photosCanvX/$factor)]

  image create photo photosOrigPic -file $imgFilePath

  #scale photosOrigPic to photosCanvPic
  set imgX [image width photosOrigPic]
  set imgY [image height photosOrigPic]
  set factor [expr round(($imgX / $photosCanvX)+0.999999)]

  if {[expr $imgY / $factor] > $photosCanvY} {
    set factor [expr round(($imgY / $photosCanvY)+0.999999)]
  }

  catch {image delete photosCanvPic}
  image create photo photosCanvPic

  photosCanvPic copy photosOrigPic -subsample $factor -shrink
  $imgCanvas create image $photosCanvMargin $photosCanvMargin -image photosCanvPic -anchor nw -tag img
  
}

proc hideImg {imgCanvas} {
  $imgCanvas delete img
}

proc deleteImg {localJList c} {
  global imgName

  set localJList [jlremovefirst $localJList]
  refreshImg $localJList $c

  if {$localJList == ""} {
    pack forget .delBtn
  }

  return $localJList
}

# copyAndResizeSamplePhotos
## copies sample Jpegs to PhotosDir unchanged if size OK
## else calls [resize]
## no cutting intended because these pics can be stretched
## called by BiblepixSetup
proc copyAndResizeSamplePhotos {} {
  global sampleJpgArray dirlist
  source $::ImgTools
  set screenX [winfo screenwidth .]
  set screenY [winfo screenheight .]

  foreach fileName [array names sampleJpgArray] {

    set origJpgPath [file join $dirlist(sampleJpgDir) $fileName]
    set newJpgPath [file join $dirlist(photosDir) $fileName]
    set newPngPath [setPngFileName $newJpgPath]

    #Skip if JPG or PNG found in $photosDir
    if { [file exists $newJpgPath] || [file exists $newPngPath] } {
      puts "Skipping $fileName"
      continue
    }

    #Copy over as JPG if size OK
    image create photo origJpeg -file $origJpgPath
    set imgX [image width origJpeg]
    set imgY [image height origJpeg]

    if {$screenX == $imgX && $screenY == $imgY} {
      puts "Copying $fileName unchanged"
      file copy $origJpgPath $newJpgPath

    #else resize & save as PNG
    } else {

      puts "Resizing $origJpgPath"
      set newPic [resize origJpeg $screenX $screenY]
      $newPic write $newPngPath -format PNG
    }
  } ;#END foreach
} ;#END copyAndResizeSamplePhotos

# fitPic2Canv
##fits ill-dimensioned photo into screen-dimensioned canvas, hiding over-dimensioned side
##called by setupResizePhoto for .resizePhoto.resizeCanv & .reposPhoto.reposCanv
proc fitPic2Canv {c} {
  set screenX [winfo screenwidth .]
  set screenY [winfo screenheight .]
  set imgX [image width $addpicture::origPic]
  set imgY [image height $addpicture::origPic]
  
  #TODO nur canvas hat korrekte Dimensionen
  set canvImgName [lindex [$c itemconf img -image] end]
  
  set canvImgX [image width $canvImgName] 
  set canvImgY [image height $canvImgName]

  set screenFactor [expr $screenX. / $screenY]
  set origImgFactor [expr $imgX. / $imgY]        
  
  $c conf 
  ##zu hoch
  if {$origImgFactor < $screenFactor} {
    puts "Cutting height.."
    set canvCutY [expr round($canvImgX / $screenFactor)]
    set canvCutX [expr round($canvCutY * $screenFactor)]
   
  ##zu breit
  } elseif {$origImgFactor > $screenFactor} {
    puts "Cutting width.."
    set canvCutX [expr round($canvImgX / $screenFactor)]
    set canvCutY $canvImgY
    
  ##no cutting needed
  } else  {
    set canvCutX $imgX
    set canvCutY $imgY
  }
  
  return "$canvCutX $canvCutY"

} ;#END fitPic2Canv

# setpic2CanvScalefactor
##sets scale factor in 'addpicture' namespace
##for largest possible display size
##called by ?addPic & openResizeWindow & openReposWindow
proc setPic2CanvScalefactor {} {

  #Check which original pic to use
  if [catch {image inuse rotateOrigPic}] {
    set origPic photosOrigPic
  } else {
    set origPic rotateOrigPic
  }
  
  set screenX [winfo screenwidth .]
  set screenY [winfo screenheight .]
  set imgX [image width $origPic]
  set imgY [image height $origPic]

  set maxX [expr $screenX - 200]
  set maxY [expr $screenY - 200]
  
  ##Reduktionsfaktor ist Ganzzahl
  set scaleFactor 1
  while { $imgX >= $maxX && $imgY >= $maxY } {
    incr scaleFactor
    set imgX [expr $imgX / 2]
    set imgY [expr $imgY / 2]
  }
  
  #export scaleFactor to 'addpicture' namespace
  set addpicture::scaleFactor $scaleFactor

} ;#END setPic2CanvScalefactor

################################################################################
##### P r o c s   f o r   S e t u p W e l c o m e  #############################
################################################################################

proc fillWidgetWithTodaysTwd {twdWidget} {
  global TwdTools

  if {[info procs getRandomTwdFile] == ""} {
    source $TwdTools
  }

  set twdFileName [getRandomTwdFile]

  if {$twdFileName == ""} {
    $twdWidget conf -fg black -bg red
    $twdWidget conf -activeforeground black -activebackground orange
    set twdText $::noTwdFilesFound
  } else {
    if {[isRtL [getTwdLang $twdFileName]]} {
      $twdWidget conf -justify right
    } else {
      $twdWidget conf -justify left
    }

    set twdText [getTodaysTwdText $twdFileName]
  }

  $twdWidget conf -text $twdText
}

# deleteOldStuff
##Removes stale prog files & dirs not listed in Globals
##called by Setup
proc deleteOldStuff {} {
  global dirlist

  #############################################
  # 1. Delete stale directories
  #############################################

  #1.List current directory paths starting from progdir
  foreach path [glob -directory $dirlist(progdir) -type d *] {
    lappend curFolderList $path
  }

  foreach path [glob -directory $dirlist(srcdir) -type d *] {
    lappend curFolderList $path
  }

  #2.List latest directory paths from Globals
  foreach name [array names dirlist] {
    lappend latestFolderList [lindex [array get dirlist $name] 1]
  }

  #3. Delete dir paths
  foreach path $curFolderList {
    catch {lsearch -exact $latestFolderList $path} res
    if {$res == -1} {
      file delete -force $path
      NewsHandler::QueryNews "Deleted obsolete folder: $path" red
    }
  }

  ####################################
  # 2. Delete stale single files
  ####################################

  ##get latest file list from Globals
  foreach path [array names FilePaths] {
    lappend latestFileList [lindex [array get FilePaths $path] 1]
  }

  ##list all subdirs in $srcdir
  foreach dir [glob -directory $dirlist(srcdir) -type d *] {
    lappend curFolderList $dir
  }
  ##list all files in subdirs
  foreach dir $curFolderList {
    foreach f [glob -nocomplain $dir/*] { 
      lappend curFileList $f
    }
  }
  ##delete any obsolete files
  foreach path $curFileList {
    catch {lsearch -exact $latestFileList $path} res
    if {$res == -1 && [file isfile $path]} {
      file delete $path
      NewsHandler::QueryNews "Deleted obsolete file: $path" red 
    }
  } 


  #########################################
  # 3. Delete stale fonts 
  #########################################

  #1. Get latest font paths from globals
  foreach path [array names BdfFontPaths] {
    lappend latestFontList [lindex [array get BdfFontPaths $path] 1]
  }
  #2. list installed font names including asian
  foreach path [glob -directory $dirlist(fontdir) *] {
    lappend curFontList $path
  }
  foreach path [glob -directory $dirlist(fontdir)/asian *] {
    lappend curFontList $path
  }
  #3. delete any obsolete fonts
  foreach path $curFontList {
    catch {lsearch -exact $latestFontList $path} res
    if {$res == "-1" && [file isfile $path]} {
      file delete $path 
      NewsHandler::QueryNews "Deled obsolete font file: $path" red
    }
  }

  NewsHandler::QueryNews "$::uptodateHttp" lightgreen

} ;#END deleteOldStuff
