# ~/Biblepix/prog/src/setup/setupRotate.tcl
# Creates Rotate toplevel window
# sourced by ?
# Authors: Peter Vollmar, Joel Hochreutener, biblepix.vollmar.ch
# Updated: 17oct20 pv

#Load rotate command
source $RotateTools

#Toplevel main window
set T .rotateW
toplevel $T -width 600 -height 400

set C $T.rotateC
set mC $T.meterC
canvas $mC -width 200 -height 110 -borderwidth 2 -relief sunken -bg lightblue

set scale $T.scale

image create photo rotateCanvPic
rotateCanvPic copy photosCanvPic
set im rotateCanvPic
set ::v 0

#Picture & buttons
button $T.previewBtn -textvar computePreview -bg orange -activebackground yellow -command {vorschau $im $::v $C}
button $T.cancelBtn -textvar cancel -activebackground red -command {catch {destroy $T} ; return 0}
button $T.180Btn -text "180° Bild auf Kopf" -command {vorschau $im 180 $C ; set ::v 180}

#TODO Move to doRotateOrigPic
button $T.saveBtn -textvar save -activebackground lightgreen -command {
  #TODO erscheint nicht!
  NewsHandler::QueryNews "Rotating original picture; this could take some time..." orange

  set rotatedImg [doRotateOrig photosOrigPic $::v]
  destroy $T
  addPic $rotatedImg $::picPath
}

catch { canvas $C }
$C create image 20 20 -image $im -anchor nw -tags img
$C conf -width [image width $im] -height [image height $im]
pack $C

#Create Meter
source $setupdir/setupRotateMeter.tcl
pack [makeMeter] -pady 20

#Pack Scale
#pack [scale $s -orient h -length 300 -from -90 -to 90 -variable v]
pack $scale
trace add variable v write updateMeter
updateMeterTimer


#$T.okBtn conf -command "imageRotate photosCanvPic [$s get]"

#TODO!!! - seems to happen after topwindow is closed
#can't set "v": invalid command name "$T.scale"
#invalid command name "$T.scale"
#    while executing
#"$s cget -from"
#    (procedure "updateMeter" line 4)
pack $T.180Btn
pack $T.previewBtn -pady 30
pack $T.cancelBtn $T.saveBtn -side right

#    set im photosCanvPic
#    set im2 [image create photo]
#    $im2 copy $im
#    set C $T.rotateC
#    
#$C create image 50  90 -image $im
#$C create image 170 90 -image $im2
#entry $C.e -textvar angle -width 4
#    set angle 99
#    bind $C.e <Return> {
#        $im2 config -width [image width $im] -height [image height $im]
#        $im2 copy $im
#        wm title . [time {imageRotate $im2 $::angle}]
#    }

#$C create window 5 5 -window $C.e -anchor nw
#    checkbutton $C.cb -text Update -variable update
#    set ::update 1
#    $C create window 40 5 -window $C.cb -anchor nw

bind $T <Escape> {destroy $T}
bind $T <Return> "imageRotate photosCanvPic $v; return 0 "
#$T.okBtn conf -bg red -command "imageRotate photosCanvPic $v"
#return

