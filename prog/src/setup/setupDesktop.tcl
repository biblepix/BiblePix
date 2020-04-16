# ~/Biblepix/prog/src/setup/setupDesktop.tcl
# Sourced by SetupGUI
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated Easter 15apr20 pv

#Create left & right main frames
pack [frame .desktopF.leftF] -fill y -side left
pack [frame .desktopF.rightF] -fill y -side right -pady 5 -padx 5
#Create right subframes
pack [frame .rtopF -relief ridge -borderwidth 0]  -in .desktopF.rightF -fill x
pack [frame .rbot1F -relief ridge -borderwidth 3] -in .desktopF.rightF -pady $py -padx $px -fill x
pack [frame .rbot1F.1F] -fill x
pack [frame .rbot1F.2F] -fill x
pack [frame .rbot2F -relief ridge -borderwidth 3] -in .desktopF.rightF -pady $py -padx $px -fill both

##Create generic Serif or Sans font
font create intCanvFont -family $fontfamily -size $fontsize -weight $fontweight
font create widgetFont -family Serif -size 11 -weight normal -slant italic

#F I L L   L E F T 

#Create title
label .desktopF.leftF.baslik -textvar f2.tit -font bpfont3

#1. ImageYesno checkbutton 
checkbutton .desktopF.leftF.imgyes -textvar f2.box -variable imgyesState -width 20 -justify left -command {setSpinState $imgyesState}
if {$enablepic} {set imgyesState 1} else {set imgyesState 0}
set imgyesnoBtn .desktopF.leftF.imgyes

#2. Main text
message .desktopF.leftF.intro -textvar f2.txt -font bpfont1 -width 500 -padx $px -pady $py -justify left

#P A C K   L E F T 
pack .desktopF.leftF.baslik -anchor w
pack $imgyesnoBtn -side top -anchor w
pack .desktopF.leftF.intro -anchor nw


# F I L L   R I G H T
canvas .textposCanv -bg lightgrey -borderwidth 1

#3. ShowDate checkbutton
checkbutton .showdateBtn -textvar f2.introline -variable enabletitle
.showdateBtn configure -command {
  if {$setupTwdFileName != ""} {
    .textposCanv itemconf mv -text [getTodaysTwdText $setupTwdFileName]
  }
}

#4. SlideshowYesNo checkbutton
checkbutton .slideBtn -textvar f2.slideshow -variable slideshowState -command {setSlideSpin $slideshowState}

#5. Slideshow spinbox
message .slideTxt -textvar f2.int -width 200
message .secTxt -text sec -width 100
spinbox .slideSpin -from 10 -to 600 -increment 10 -width 3
.slideSpin set $slideshow

if {!$slideshow} {
  .slideBtn deselect 
  set slideshowState 0
  .slideSpin configure -state disabled
} else {
  .slideBtn select
  set slideshowState 1
  .slideSpin configure -state normal
}

#Initial setting of TextPos Canvas
#TODO mit Faktor berechnen! od. Faktor in proc integrieren
#TODO can't get font , not ready
#setCanvasFont .textposCanv $fontsize $fontweight $fontfamily $fontcolor






#1. Create InternationalText Canvas - Fonts based on System fonts, not Bdf!!!!
    ## Tcl picks any available Sans or Serif font from the system
canvas .inttextCanv -width 700 -height 150 -borderwidth 2 -relief raised

##create background image
image create photo intTextBG -file $SetupDesktopPng
.inttextCanv create image 0 0 -image intTextBG -anchor nw 

# Set international text
label .inttextTit -font TkCaptionFont -textvar f2.fontexpl
label .inttextFN -width 50 -font TkSmallCaptionFont -textvar ::textposFN
 
if {$os=="Linux"} {
  #Unix needs a lot of formatting for Arabic & Hebrew
  puts "Computing Arabic"
  source $BdfBidi
  
  #TODO pv: ARABISCH BLOCKIERT ALLES!!!! - vorläufig lassen
  #set f2ar_txt [bidi $f2ar_txt ar revert]
  set f2ar_txt [string reverse $f2ar_txt]
  set f2he_txt [bidi $f2he_txt he revert]
} 

set internationalText "$f2ltr_txt $f2ar_txt $f2he_txt\n$f2thai_txt\nAn Bríathar"

source $ImgTools
set rgb [hex2rgb $fontcolor]
  set shade [setShade $rgb]
  set sun [setSun $rgb]

.inttextCanv create text 11 11 -anchor nw -text $internationalText -font intCanvFont -fill $shade -tags {shade textitem}
.inttextCanv create text 9 9 -anchor nw -text $internationalText -font intCanvFont -fill $sun -tags {sun textitem}
.inttextCanv create text 10 10 -anchor nw -text $internationalText -font intCanvFont -fill $fontcolor -tags {main textitem}



#1. Fontcolour spinbox
message .fontcolorTxt -width 150 -textvar f2.farbe -font widgetFont
spinbox .fontcolorSpin -width 12 -values {blue green gold silver} 
.fontcolorSpin conf -bg $fontcolor -fg white -font TkCaptionFont
.fontcolorSpin set $fontcolortext

#TODO include setCanvasFont 
.fontcolorSpin configure -command {
  %W conf -bg [set %s]
  setIntCanvText [set %s]
  .textposCanv itemconf mv -fill [set %s]
  #setCanvasFont
}

#set Fontsize spinbox
message .fontsizeTxt -width 200 -textvar f2.fontsizetext -font widgetFont
spinbox .fontsizeSpin -width 2 -values $fontSizeList -font TkCaptionFont 
.fontsizeSpin conf -command {font conf intCanvFont -size %s}
.fontsizeSpin set $fontsize

#set Fontweight checkbutton
checkbutton .fontweightBtn -width 5 -variable fontweightState -font widgetFont -textvar f2.fontweight 
.fontweightBtn conf -command {
  if {$fontweightState} {
    font configure intCanvFont -weight bold
  } else {
    font configure intCanvFont -weight normal
  }
  return 0
}

#set Fontfamily spinbox
message .fontfamilyTxt -width 200 -textvar f2.fontfamilytext -font widgetFont
lappend Fontlist Serif Sans
spinbox .fontfamilySpin -width 12 -bg lightblue -font TkCaptionFont
.fontfamilySpin conf -values $Fontlist -command {font conf intCanvFont -family %s}
.fontfamilySpin set $fontfamily


label .textposTxt -textvar textpos -font TkCaptionFont

proc olacak {} {
#2. Create TextPos Canvas

#TODO this makes no sense, link to Textsize window! 
set textPosFactor 3

image create photo origbild -file [getRandomPhoto]
image create photo canvasbild
canvasbild copy origbild -subsample $textPosFactor -shrink
set screeny [winfo screenheight .]


$c conf -width [image width canvasbild] -height [expr $screeny/$textPosFactor]
$c create image 0 0 -image canvasbild -anchor nw -tags img


#TODO
createMovingTextBox $c

.textposCanv bind mv <1> {
     set ::x %X
     set ::y %Y
 }
.textposCanv bind mv <Button1-Motion> [list dragCanvasItem %W mv %X %Y]

}

#P A C K   R I G H T
#Top right
pack .showdateBtn -in .rtopF -anchor w
pack .slideBtn -in .rtopF -anchor w -side left
pack .secTxt .slideSpin .slideTxt -in .rtopF -anchor nw -side right

#Bottom 1.1
pack .inttextTit -in .rbot1F.1F -pady 7
#Bottom 1.2
pack .inttextCanv -in .rbot1F.2F -fill x

pack .fontcolorTxt .fontcolorSpin .fontfamilyTxt .fontfamilySpin -in .rbot1F.2F -side left -anchor n
pack .fontweightBtn .fontsizeSpin .fontsizeTxt -in .rbot1F.2F -side right -anchor n

#Bottom 2
pack .textposTxt -in .rbot2F -pady 7
pack .textposCanv -in .rbot2F -fill y
pack .inttextFN -in .rbot2F -fill x

