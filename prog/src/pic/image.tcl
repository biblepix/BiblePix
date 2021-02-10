# ~/Biblepix/progs/src/pic/image.tcl
# Initiates BdfPrint, called by biblepix.tcl
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated 10feb21 pv

source $ImgTools
source $AnnotatePng
namespace eval colour {}
package require Tk
    
#Load Img/tkimg (part of ActiveTcl, Linux distros need to install separately)
if [catch {package require Img}] {
  source -encoding utf-8 $Texts
  setTexts $lang
  if [catch {tk_messageBox -title BiblePix -type ok -icon error -message $packageRequireImg} {
    return -error "Packages Tk and Img cannot be loaded. Exiting."
  }
}

#Hide Tk window as not needed
wm overrideredirect . 1
wm geometry . +0-30
wm withdraw .

#Select & create random background PNG
set picPath [getRandomPhotoPath]
image create photo hgbild -file $picPath

#get random fontcolour if activated
if {$enableRandomFontcolor} {
  set fontcolortext [getRandomFontcolor]
}

#Extract any info from PNG & export pngInfo to ::colour ns
puts "Reading PNG info from [file tail $picPath] ..."
if {[readPngComment $picPath] == 0} {
  puts "*No PNG info found!"
  
} else {

  namespace eval colour {
    variable picPath $::picPath
    array set pnginfo "[split [evalPngComment $picPath]]"
  } 
}

#Printing   B D F 
puts "Creating BDF picture..."
source $BdfPrint
