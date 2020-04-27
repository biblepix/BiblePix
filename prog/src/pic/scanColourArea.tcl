# Updated 27apr20 pv

#TODO move scanArea & scanRow to Setup>Photos>addPic !!!
catch {namespace delete colour}

namespace eval colour {



  # scanArea - SCHON EINGEBAUT!
  ##scans image by desired height
  ##runs scanRow for each line
#  proc scanArea {img imgY} {
#    for {set y 1} {$y < $imgY} {incr y} {
#      scanRow $img $y
# puts "Scanning $y..."
#    }
#  }
  
  # scanRows
  ##scans ...
  ##called by scanArea
  proc scanColourArea {img} {

  #TODO? furnish these from outside? 
    set colourTol 10
    set margin 10
    
    #Limit scanning area by excluding margins
    set imgX [image width $img]
    set imgY [image height $img]
    set begX $margin
    set endX [expr $imgX - $margin]
    set begY $margin
    set endY [expr $imgY - $margin]
    set prevxPos [expr $begX - 1]    
    #min.width of area should be ¼ of pic
    set xMinArea [expr $imgX / 4]
    
    #pretend prevC array & prevX for 1st run & LNL (list number per row)
    array set prevCArr {r 0 g 0 b 0}
    
    #Run through rows of limited height area
    for {set yPos $begY} {$yPos < $endY} {incr yPos} {
    
        #set first time prevC (=identical with curC)
        set c [$img get $begX $begY]
        set r [lindex $c 0]
        set g [lindex $c 1]
        set b [lindex $c 2]
        array set prevC "r $r g $g b $b"
        
      #Run through pixels of limited row width
      for {set xPos $begX} {$xPos < $endX} {incr xPos} {
      
        #Get current rgb
        set c [$img get $xPos $yPos]
        set r [lindex $c 0]
        set g [lindex $c 1]
        set b [lindex $c 2]
        array set curCArr "r $r g $g b $b"
  
        #Compare current rgb with previous      
        set maxr [expr max($curC(r),$prevC(r))]
        set minr [expr min($curC(r),$prevC(r))]  
        set maxg [expr max($curC(g),$prevC(g))]
        set ming [expr min($curC(g),$prevC(g))]
        set maxb [expr max($curC(b),$prevC(b))]
        set minb [expr min($curC(b),$prevC(b))]
      
       #Add consecutive pixelPositions to Matchlist(s) per row  
        set diffr [expr $maxr - $minr]
        set diffg [expr $maxg - $ming]
        set diffb [expr $maxb - $minb]
        
      if {
        
        $diffr < $colourTol &&
        $diffg < $colourTol &&
        $diffb < $colourTol
                 
      } {
      
        lappend [namespace current]::matchlist${yPos} $xPos
        
#        lappend brightL [calcMean $r $g $b]
    
        set prevxPos $xPos       
        array set prevCArr "r $r g $g b $b"

      #skip non-matching
      } else {
      
      #  lappend [namespace current]::matchlist${yPos} .

      } ;#End if match 
            
 
       
          #Eliminate too short lists
#          if {[llength rowMatchList${matchlistNo}] < $xMinArea} {
#          
#            puts "zu schmal"
##            unset rowMatchList${ML}
##    continue      
#          }

 #       } ;#End matchList loop
                    
                    
      } ;#END x loop
      
      #Append brightness code: N(ormal) / L(ight) / D(ark) at end of each matchrow
      set brightCode [setBrightCode prevCArr]
      append [namespace current]::matchlist${yPos} $brightCode
        
    } ;#END y loop
     
  } ;# END scanColourArea


} ;#END ::colour namespace


proc evalRowlists {img} {

  set minwidth [expr [image width $img] / 4]
  
  #TODO Move outside?
  proc createRowmatch {matchNo} {
  
  #TODO get first matching after first run! -put into namespace!
    if [info exists $endPos] {set prevX $endPos} {set prevX 0}

    while { [expr $curX - $prevX] == 1} { 

      lappend rowmatch${matchNo} [lindex $curlist $curX]
      incr curX
      incr prevX
    }
  }
  
  
  #get consecutive area(s) per row & extract 1st + last pos
  foreach rowlist [lsort [info vars colour::matchlist*]] {
    
    #scan rowlist
    set prevX 0
    set curX 1
    
    #only count consecutive pixels
    #1st run
    set matchNo 1
    createRowmatch $matchNo
        
    #TODO Put into namespace!
    set begPos [lindex $rowmatch 0]
    set endPos [lindex $rowmatch end]
    
    #delete sequence if too short
    #2nd and following run
    while {[expr $endPos - $begPos] < $minwidth} {
    
      unset rowmatch${matchNo}
      incr matchNo
      createRowmatch $matchNo
    }
    
   
    #set begPos [lindex $rowlist $i]
    if {info exists ?any_rowmatch?} {
    
    #TODO get rid of regexp, change name to digit!
      regexp {(matchlist)(.*)} $rowlist {\2} yBeg
    
      lappend [namespace current]::begPosList $begPos
      lappend [namespace current]::endPosList $endPos
  
    }
  
    if {[info exists [namespace current]::begPosList] &&
        [info exists [namespace current]::endPosList] } {
    
      set avXBeg [mean [namespace current]::begPosList]
      set avXEnd [mean [namespace current]::endPosList]
      
      if {[expr $avXEnd - $avXBeg] > $minXwidth} {
        
        #Return text postion x + y
        puts "Found suitable text area at $avXbeg $yBeg"
        return "$avXBeg $yBeg"
    
      } else {
      
        puts "No suitable area found."
        return 0
      }
    }
  } ;#END foreach  
} ;#END evalRowlists


# scanSimlist
##scans simlist for fake sections (with spaces over $spacetol pixels) 
proc scanList {simlist spacetol} {
  
  set prev 0
  
  foreach cur $simlist {
    
    if {[expr $cur - $prev] > $spacetol } {
      continue
  
    } else {
      
      lappend $simlist_ok $cur   
    }
  }
} ;#END scanSimlist


# determineSimilarColourArea
##evaluates $simlist_ok lists for suitably large areas (minwidth=? / maxheight=?)
proc determineSimilarColourArea {img minwidth minheight} {

  if ! [array exists colour::sim.0] {
    puts "No similar colours array found!"
    return 1
  }

  #Compare first and last positions of rows
  foreach simlist [info vars colour::simlist.*] {
    set beg [lindex $simlist 0]
    set end [lindex $simlist end]
    
    lappend $beg beginlist
    lappend $end endlist
  

  }
 
 #Compute average start positions   
  foreach pos $beginlist {
    incr beginTotal $pos
    incr beginCount
  }
  set beginAverage [expr $beginTotal / $beginCount]
    
  #Compute average end positions


#A) Eliminate fake ranges with a min. of ?500? consecutive pixels     

#B) List consecutive rows from A)
  
  
  #C Return coords
  set x1 ... ...
  lappend area $x1 $y1 $x2 $y2
  return $area

} ;#END determineSimilarColourArea

# tagPhoto
##tags photo name with preceding ° (=no area found) OR °+[X1 Y1 in HEX]° (=area found)
##this way BiblePix can know if (old) picture has been scanned yet
##called by ?above to indicate text area for photo
proc tagPhoto {imgname {args}} {
  
  append tag °

  if [info exists args] {
    set coord $args
    set coordHex [binary encode hex $coord]
    append tag + $coordHex °
  }

  append newname $tag $imgname  
  return $newname
}

# getPhotoScancode
##scans photo name for scan code
##called by ?getRandomPhoto?
proc getPhotoScancode {imgname} {
  
  #Check scan status (gibt 0 aus wenn da)
  if ![string first ° $imgname] {
    catch {string last ° $imgname} res
    
    ##A) Scanned, no area found
    if {$res == 0} {
      puts "Bild gescannt. Kein Bereich."
      set returncode "scanned"
      
    ##B) Scanned, special area found
    } else {
      
      set coordHex [string range 1 $res-1]
      set coords [binary decode hex $coordHex]
      set returncode $coords
    }
  
  ##C) Not scanned
  } else {
    
    set returncode "unscanned"
  
  }
  
  return $returncode
}
