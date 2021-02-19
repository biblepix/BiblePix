# ~/Biblepix/prog/src/com/BdfTools.tcl
# BDF printing tools
# sourced by BdfPrint
# Authors: Peter Vollmar & Joel Hochreutener, www.biblepix.vollmar.ch
# Updated: 16feb21 pv

namespace eval bdf {

  variable xBase
  variable YBase  
  variable x
  variable y
  
  # printTwd
  ##Toplevel printing proc
  ##called by BdfPrint
  proc printTwd {TwdFileName img marginleft margintop} {
    
    global RtL fontcolortext
    global colour::pngInfo
    
    set minmarg 25
    set screenW [winfo screenwidth .]
    
    parseTwdTextParts $TwdFileName
    
    image create photo textbild
    printTwdTextParts $minmarg $minmarg textbild

    set textpicX [image width textbild]
    set textpicY [image height textbild]
puts $textpicX
puts $textpicY
  
    lassign [setupTextpic textbild] marginleft margintop
     
    #recompute luminance for non-pngInfo pics
    if ![info exists pngInfo(Luminacy)] {
      set newLum [getAreaLuminacy hgbild "$marginleft $margintop $textpicX $textpicY"]
      
 #TODO this confuses cropPic2Textsize - do we need it after here?
 #     set colour::pngInfo(Luminacy) $newLum
      applyChangedLuminacy $marginleft $margintop
      set newLum changed
    }
    
    # R T L   
        
    if $RtL {
      set textpicX [image width textbild]
  
      ##A) Crop textbild to text width, create 'croppic' global function
      cropPic2Textwidth textbild $fontcolortext
textbild blank
textbild copy croppic

      ##B) If no png info found: correct margin to the right
      if { ![info exists pngInfo(Marginleft)] && $marginleft < [expr $screenW/3] } {
      
        #a) align text with right margin
        set marginleft [expr $screenW - $marginleft - $textpicX]
      
        #b) correct text colour if luminacy changed        
      #TODO wozu das?
        if [info exists pngInfo(Luminacy)] {
          set curLum $pngInfo(Luminacy)
        }
              
        ##check if newLum previously set - TODO where is this read in?
        if ![info exists newLum] {
          set newLum [getAreaLuminacy hgbild "$marginleft $margintop $textpicX $textpicY"]
          set colour::pnginfo(Luminacy) $newLum
          applyChangedLuminacy $marginleft $margintop
        }        
      } ;#END if no png info found 
    } ;#END if RtL
      
    #C) Copy textpic to final image  
    hgbild copy textbild -to $marginleft $margintop -compositingrule overlay
    
    #Cleanup
    namespace delete [namespace current]
    catch {namespace delete colour}
    #Return pic as function
    return hgbild
  
  } ;#End printTwd

  # setupTextpic
  ##creates & fits textpic to text width
  ##called by twdPrint
  proc setupTextpic {textpic} {
    set minmarg 25
    global marginleft margintop
    
#    image create photo textpic
#    printTwdTextParts $minmarg $minmarg textpic
    
    #Correct right & top margins
    set screenW [winfo screenwidth .]
    set screenH [winfo screenheight .]
    set textpicX [image width $textpic]
    set textpicY [image height $textpic]
    set reservedW [expr $screenW - $marginleft]
    set reservedH [expr $screenH - $margintop]
    
    ##zu weit unten -> Move textpic up
    if {$reservedH < $textpicY} {
      set diff [expr $textpicY - $reservedH]
      set margintop [expr $margintop - $diff - $minmarg] 
    }
    
    ##zu weit rechts -> move textpic left
    if {$reservedW < $textpicX} {
      set diff [expr $textpicX - $reservedW]
      set marginleft [expr $marginleft - $diff - $minmarg] 
    }
  
    return "$marginleft $margintop"
  }

  proc applyChangedLuminacy {marginleft margintop} {
    global fontcolortext colour::pngInfo
    
    #TODO what's the point of this?
    if [catch {set curLum $pngInfo(Luminacy)}] {
      set curLum 2
    }
    
    set textpicY [image height textbild]
    set textpicX [image width  textbild]
#    if [catch {image inuse croppic}] {
#      set textpicX [image width textbild]
#    } else {
#      set textpicX [image width croppic]
#    }
 
 #TODO this is called twice by printTWD !!!!!!!!!!!!!!!!!!!!!!!!!!
              
    set newLum [getAreaLuminacy hgbild "$marginleft $margintop $textpicX $textpicY"]
    
    ##recompute if luminacy changed
    if {$curLum != $newLum} {
      
      lassign [setFontShades $fontcolortext] newReg newSun newSha
    
      ##get old shades 
      set oldReg $colour::regHex
      set oldSun $colour::sunHex
      set oldSha $colour::shaHex      
 
 #TODO jesch abalagan
      ##replace colours
#      set dataL [croppic data]
 set dataL [textbild data]
      
      regsub -all $oldReg $dataL $newReg newData
      regsub -all $oldSun $dataL $newSun newData
      regsub -all $oldSha $dataL $newSha newData
  
  
  #TODO schwarzer hintergrund?!
      ##copy new data to croppic
      image create photo croppic
      croppic put $newData        
      textbild blank
      textbild copy croppic -compositingrule overlay
    }
  } ;#END applyChangedLuminacy
  
  # parseTwdTextParts
  ## prepares Twd nodes in a separate namespace for further processing
  ## called by printTwd
  proc parseTwdTextParts {TwdFileName} {
    global TwdLang
    set screenW [winfo screenwidth .]
    set screenH [winfo screenheight .]
    
    #A: SET TWD NODE NAMES
    set domDoc [parseTwdFileDomDoc $TwdFileName]
    set todaysTwdNode [getDomNodeForToday $domDoc]
    set parolNode1 [$todaysTwdNode child 2]
    set parolNode2 [$todaysTwdNode lastChild]
    
    if {$todaysTwdNode == ""} {
      source $SetupTexts
      set text1 $noTwdFilesFound
    } else {
      set titleNode [$todaysTwdNode selectNodes title]
    }
    
    set introNode1 [$parolNode1 selectNodes intro]
    set introNode2 [$parolNode2 selectNodes intro]
    set refNode1 [$parolNode1 selectNodes ref]
    set refNode2 [$parolNode2 selectNodes ref]
    set textNode1 [$parolNode1 selectNodes text]
    set textNode2 [$parolNode2 selectNodes text]

    # B: EXTRACT TWD TEXT PARTS
     
    ##title
    set title [$titleNode text]
    ##intros
    if {![catch {$introNode1 text} res]} {
      set intro1 $res
    }
    if {![catch {$introNode2 text} res]} {
      set intro2 $res
    }
    
    ##refs
    set ref1 [$refNode1 text]
    set ref2 [$refNode2 text]

    # Detect texts with <em> tags & mark as Italic
    foreach node "[split [$textNode1 selectNodes em/text()]] [split [$textNode2 selectNodes em/text()]]" {
      set nodeText [$node nodeValue]
      if {$nodeText != ""} {
        $node nodeValue \<$nodeText\~
      }
    }
    ##extract text including any tagged
    set text1 [$textNode1 asText]
    set text2 [$textNode2 asText]
        
    #export text parts to namespace current:
    if [info exists intro1] {
     set [namespace current]::intro1 $intro1
    }
    if [info exists intro2] {
      set [namespace current]::intro2 $intro2
    }
    if [info exists title] {
      set [namespace current]::title $title
    }
    set [namespace current]::ref1 $ref1
    set [namespace current]::ref2 $ref2
    set [namespace current]::text1 $text1
    set [namespace current]::text2 $text2
        
  } ;#END parseTwdTextParts
  
  # printTwdTextParts  
  ## called by printTwd
  proc printTwdTextParts {x y img} {
  
  #TODO testing
  set x 20
  set y 20
  
    set screenW [winfo screenwidth .]
    set screenH [winfo screenheight .]
    global enabletitle TwdLang
    global [namespace current]::title
    global [namespace current]::intro1
    global [namespace current]::intro2
    global [namespace current]::ref1
    global [namespace current]::ref2
    global [namespace current]::text1
    global [namespace current]::text2
    
    
    #2) SORT OUT markrefs for Italic & Bold
    if {$TwdLang == "th" || $TwdLang == "zh" } {
      set markTitle ""
      set markRef ""
      set markText ""
    } elseif {[isArabicScript $TwdLang]} {
      #Arabic has no Italics!
      set markTitle +
      set markRef ~
      set markText ~
    } elseif {$::fontweight == "bold"} {
      set markTitle +
      set markRef <
      set markText +
    } else {
      set markTitle +
      set markRef <
      set markText ~
    }

    #3) START PRINTING

    # 1. Print Title in Bold +...~
    if {$enabletitle} {
      set y [printTextLine ${markTitle}${title} $x $y $img]
    }
    #Print intro1 in Italics <...~
    if [info exists intro1] {
      set y [printTextLine ${markRef}${intro1} $x $y $img IND]
    }
    #Print text1
    set textLines [split $text1 \n]
    foreach line $textLines {
      set y [printTextLine ${markText}$line $x $y $img IND]
    }
    #Print ref1 in Italics
    set y [printTextLine ${markRef}${ref1} $x $y $img TAB]
    #Print intro2 in Italics
    if [info exists intro2] {
      set y [printTextLine ${markRef}${intro2} $x $y $img IND]
    }
    #Print text2
    set textLines [split $text2 \n]
    foreach line $textLines {
      set y [printTextLine ${markText}$line $x $y $img IND]
    }
    #Print ref2
    set y [printTextLine ${markRef}${ref2}${markText} $x $y $img TAB]


#TODO yor x's and y's are in a muddle!!!!!!!!!!!!!!!!!!!!!!!!!!!
#it's probably evalMargin...
    #EVALUATE MARGIN ERRORS
#    lassign [evalMarginErrors $x $y] newX newY
#puts "$x $y"
#puts "$newX $newY"
#    ##A) if none, return $img
#    if {$newX == $x && $newY == $y} {
#      
#      return $img
#      
#    ##B) if some, return new coords for fresh run of this prog
#    } else {

#      if {$newX != $x} {set x $newX} 
#      if {$newY != $y} {set y $newY}
#      
#      return "$x $y"
#    }
#    

#  testoverlay write /tmp/testoverlay.png -format PNG

  } ;#END printTwdTextParts


  # printLetter
  ## prints single letter to $img
  ## called by printTextLine
  proc printLetter {letterName img x y} {
    global colour::regHex
    global colour::sunHex
    global colour::shaHex
    global RtL prefix
    upvar $letterName curLetter

    set imgW [image width $img]
    set imgH [image height $img]

    set BBxoff $curLetter(BBxoff)
    set BBx $curLetter(BBx)

    if {$RtL} {
      set x [expr $x - $curLetter(DWx)]
    }

    set xLetter [expr $x + $BBxoff]
    set yLetter [expr $y - $curLetter(BByoff) - $curLetter(BBy)]

    set yCur $yLetter
    set pixelLines $curLetter(BITMAP)
    
    foreach pxLine $pixelLines {
      set xCur $xLetter
      for {set i 0} {$i < $curLetter(BBx)} {incr i} {
        set pxValue [string index $pxLine $i]
        
        if {$pxValue != 0} {
          switch $pxValue {
            1 { set pxColor $regHex }
            2 { set pxColor $sunHex }
            3 { set pxColor $shaHex }
          }
           
        #A) Truncate text (break loop) if it exceeds image width or height
        #if {$xCur >= $imgW || $yCur >= $imgH} {break}
        #B) else put colour pixel
        if {$xCur <0} {set xCur 1} 
          $img put $pxColor -to $xCur $yCur
        }
        incr xCur
      }  
    incr yCur
    }
  } ;#END printLetter


  # printTextLine - prints 1 line of text to $img
  ## calls printLetter
  ## use 'args' for TAB or IND
  ## Called by printTwd
  proc printTextLine {textLine x y img args} {
      
    global TwdLang enabletitle RtL BdfBidi prefix

    #set textpic width for RtL, to be cropped later
    if $RtL {
      $img conf -width 800
      set x 800
    } 

    set FontAsc "$${prefix}::FontAsc"
    set tab 400
    set ind 0
    if {$enabletitle} {set ind 20}
    
    set xBase $x
    if [catch {set yBase [expr $y + $FontAsc]}] {
      set yBase $y
    }

    #Set text alignment: 
 
    ##for normal text
    if !$RtL {
      set operator +

    ##for RtL text
    } else {
      ##a) if no png info found, move text to the right - #?TODO? recompute luminacy for new area?!
      set operator -
      source $BdfBidi
      set textLine [bidi $textLine $TwdLang]
    }

    #Compute indentations
    if {$args=="IND"} {
      set xBase [expr $xBase $operator $ind]
    } elseif {$args=="TAB"} {
      set xBase [expr $xBase $operator $tab]
    }

    set letterList [split $textLine {}]
    
    foreach letter $letterList {

      #Set new fontstyle if marked
      if {$letter == "<"} {
        set prefix I
        continue
      } elseif {$letter == "~"} {
        set prefix R
        continue
      } elseif {$letter == "+"} {
        set prefix B
        continue
      }

      set encLetter [scan $letter %c]

      if { [catch {upvar 3 ${prefix}::print_$encLetter print_$encLetter} error] } {
        puts $error
        continue
        
      } else {
        
        array set curLetter [array get print_$encLetter]
        if [catch {printLetter curLetter $img $xBase $yBase} error] {
          puts "could not print letter: $encLetter"
          error $error
          continue
        }
        set xBase [expr $xBase $operator $curLetter(DWx)]
      }
    } ;#END foreach

    set yBase [expr $y + $${prefix}::FBBy]
    
    #return new Y position for next line
    return $yBase

  } ;#END printTextLine

} ;#END bdf:: namespace



