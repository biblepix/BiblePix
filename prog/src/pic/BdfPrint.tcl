# ~/Biblepix/prog/src/pic/BdfPrint.tcl
# Top level BDF printing prog
# sourced by Image
# Authors: Peter Vollmar & Joel Hochreutener, www.biblepix.vollmar.ch
# Updated: 26feb21 pv
source $TwdTools
source $BdfTools
source $ImgTools

set TwdLang [getTwdLang $TwdFileName]
set RtL [isRtL $TwdLang]
puts $TwdLang

# S O U R C E   F O N T S   I N T O   N A M E S P A C E S

##Chinese: (regular_24)
if {$TwdLang == "zh"} {
  set ::prefix Z
  if {! [namespace exists Z]} {
    namespace eval Z {
      source -encoding utf-8 $BdfFontPaths(ChinaFont)
    }
  }
##Thai: (regular_20)
} elseif {$TwdLang == "th"} {
  set ::prefix T
  if {! [namespace exists T]} {
    namespace eval T {
      source -encoding utf-8 $BdfFontPaths(ThaiFont)
    }
  }
##All else: Regular / Bold / Italic
} else {

  if {$fontweight == "bold"} {
    set ::prefix B
  } else {
    set ::prefix R
  }

  if {! [namespace exists R] && $fontweight != "bold"} {
    namespace eval R {
      puts "sourcing $BdfFontPaths($fontname)"
      source -encoding utf-8 $BdfFontPaths($fontname)
    }
  }
  
  #Source Italic for all except Asian
  if {! [namespace exists I]} {
    namespace eval I {
      puts "sourcing $BdfFontPaths($fontnameItalic)"
      source -encoding utf-8 $BdfFontPaths($fontnameItalic)
    }
  }
  
  #Source Bold if $enabletitle OR $fontweight==bold
  if {$enabletitle || $fontweight == "bold"} { 
    if {! [namespace exists B]} {
      namespace eval B {
        puts "sourcing $BdfFontPaths($fontnameBold)"
        source -encoding utf-8 $BdfFontPaths($fontnameBold)
      }
    }
  }
} ;#END source fonts


# 2) C O M P U T E   C O L O U R S   A N D   M A R G I N S
puts "Computing colours..."
puts $fontcolortext

#Compute avarage colours of text section - to be saved in colour:: as regHex sunHex shaHex
setFontShades $fontcolortext

# 3)  I N I T I A L I S E   P R I N T I N G

puts "Printing TWD text..."

##print image
#set finalImg [bdf::printTwd $TwdFileName hgbild $marginleft $margintop]
set finalImg [bdf::printTwd $TwdFileName hgbild]

##save image
if {$platform=="windows"} {  
  $finalImg write $TwdTIF -format TIFF
  puts "Saved new image to:\n $TwdTIF"
} elseif {$platform=="unix"} {
  $finalImg write $TwdBMP -format BMP
  $finalImg write $TwdPNG -format PNG
  puts "Saved new images to:\n $TwdBMP\n $TwdPNG"
}

#Cleanup original and final image
image delete $finalImg
