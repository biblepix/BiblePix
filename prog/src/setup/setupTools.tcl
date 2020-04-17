# ~/Biblepix/prog/src/setup/setupTools.tcl
# Procs used in Setup, called by SetupGui
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated: 17apr20 pv

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
    font conf intCanvFont -size $args
    font conf movingTextFont -size [expr round($args / 3) + 2]
    
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

# dragCanvasItem
##adapted from a proc by ? ...THANKS TO  ...
##called by SetupDesktop & setupRespositionText
proc dragCanvasItem {c item newX newY} {

  set xDiff [expr {$newX - $::x}]
  set yDiff [expr {$newY - $::y}]

  #test margins before moving
  if [checkItemInside $c $item $xDiff $yDiff] {
    $c move $item $xDiff $yDiff
  }
  set ::x $newX
  set ::y $newY
}

# checkItemInside
## makes sure movingItem stays inside canvas
## called by dragCanvasItem
proc checkItemInside {c item xDiff yDiff} {

  #The 'img' tag should work with any calling prog
  set img [$c itemcget img -image]
  
  set imgX [image width $img]
  set imgY [image height $img]
  set canvX [expr [winfo width $c] - 8]
  set canvY [expr [winfo height $c] - 8]


#TODO set item tags more intelligently !
#TODO soluciona para ambas pantallas
lassign [$c bbox canvTxt] x1 y1 x2 y2
set textHeight [expr $y2 - $y1]
set textWidth  [expr $x2 - $x1]
set minMargin 15
set can(minx) $minMargin
set can(miny) $minMargin
set can(maxx) [expr $imgX - $textWidth - $minMargin]
set can(maxy) [expr $imgY - $textHeight - $minMargin]

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

# createMovingTextBox
## Creates textbox with TW text on canvas $c
## Called by SetupDesktop
proc createMovingTextBox {c} {
  global marginleft margintop textPosFactor fontcolor fontsize fontfamily fontweight setupTwdText

  #Verkleinerungsfaktor für textposition window
  set displayFactor 2
  
  set screenx [winfo screenwidth .]
  set screeny [winfo screenheight .]
  set textPosSubwinX [expr $screenx/20]
  set textPosSubwinY [expr $screeny/30]
  set x1 [expr $marginleft/$textPosFactor]
  set y1 [expr $margintop/$textPosFactor]
 
  #Create movingTextFont here, configure later with setCanvasFontSize
  font create movingTextFont

  set shadeX [expr $x1 + 1]
  set shadeY [expr $y1 + 1]
  set sunX [expr $x1 - 1]
  set sunY [expr $y1 - 1]

  $c create text $shadeX $shadeY -anchor nw -justify left -tags {canvTxt mv shade}
  $c create text $sunX $sunY -anchor nw -justify left -tags {canvTxt mv sun}
  $c create text $x1 $y1 -anchor nw -justify left -tags {canvTxt mv main}
  $c itemconf canvTxt -text $setupTwdText
  $c itemconf canvTxt -font movingTextFont -activefill red

} ;#END createMovingTextBox


##### S E T U P P H O T O S   P R O C S ####################################################

proc needsResize {} {
  set screenX [winfo screenwidth .]
  set screenY [winfo screenheight .]

  set imgX [image width photosOrigPic]
  set imgY [image height photosOrigPic]

  #Compare img dimensions with screen dimensions
  if {$screenX == $imgX && $screenY == $imgY} {
    return 0
  } else {
    return 1
  }
}

# addPic - called by SetupPhoto
# adds new Picture to BiblePix Photo collection
# setzt Funktion 'photosOrigPic' voraus und leitet Subprozesse ein
proc addPic {} {
  global picPath dirlist

  set targetPicPath [file join $dirlist(photosDir) [setPngFileName [file tail $picPath]]]

  if { [file exists $targetPicPath] } {
    NewsHandler::QueryNews $::picSchonDa lightblue
    return
  }

  if [needsResize] {
    source $::SetupResizePhoto
    openResizeWindow
  } else {
    photosOrigPic write $targetPicPath -format PNG
    NewsHandler::QueryNews "[copiedPicMsg $picPath]" lightblue
  }
  
#addRotate
  
} ;#END addPic

proc delPic {} {
  global fileJList picPath
  file delete $picPath
  set fileJList [deleteImg $fileJList .imgCanvas]
  NewsHandler::QueryNews "[deletedPicMsg $picPath]" red
}

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


##### Procs for SetupWelcome ####################################################

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
