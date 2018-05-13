#!/bin/env tclsh
# ~/Biblepix/prog/src/biblepix.tcl
# Main program, called by System Autostart
# Projects The Word from "Bible 2.0" on a daily changing backdrop image 
# OR displays The Word in the terminal OR adds The Word to e-mail signatures
# Authors: Peter Vollmar, Joel Hochreutener, biblepix.vollmar.ch
# Updated: 11may18
######################################################################

#Verify location & source Globals
set srcdir [file dirname [info script]]
set Globals "[file join $srcdir com globals.tcl]"
source $Globals
source $TwdTools

#Set TwdFileName for the 1st time, else run Setup
if [catch {set twdfile [getRandomTwdFile]}] {
  source -encoding utf-8 $SetupTexts
  setTexts $lang
  package require Tk
  tk_messageBox -title BiblePix -type ok -icon error -message $noTWDFilesFound
  #catch if run by running Setup
  catch {source $Setup}
  return
}

#Export TwdFilename to global space
set ::TwdFileName $twdfile

#1. U p d a t e   s i g n a t u r e s  if $enablesig
if {$enablesig} {
  source $Signature
}

#2. C r e a t e   t e r m . s h  for Unix terminal if $enableterm
if {[info exists enableterm] && $enableterm} {
  if {![catch {getTodaysTwdTerm $twdfile} dwTerm]} {
    #create shell script
    set chan [open $Terminal w]
    puts $chan "# ~/Biblepix/prog/unix/term.sh"
    puts $chan "# Bash script to display 'The Word' in a Linux terminal"
    puts $chan "# Recreated by biblepix.tcl on [clock format [clock seconds] -format {%d%b%Y at %H:%M}]\n"
    puts $chan ". $confdir/term.conf"
    puts $chan $dwTerm
    close $chan
    file attributes $Terminal -permissions +x
  } elseif { [info exists Debug] && $Debug } {
      error $dwTerm
  }
}

#3. P r e p a r e   c h a n g i n g   W i n   d e s k t o p

#TODO: move to ?tools
proc setWinBG {} {
  global TwdTIF regpath platform
  if {$platform=="windows"} {
    registry set $regpath Wallpaper [file nativename $TwdTIF]
    exec RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True
  }
}

if {$platform=="windows"} {
  package require registry
  set regpath [join {HKEY_CURRENT_USER {Control Panel} Desktop} \\]
  
} elseif {$os=="Linux"} {

  #procs found in ?tools 
  catch setLinuxBg ;#run always
  
  #TEST FOR NOW:
  exec swaymsg output DVI-I-2 bg $imgDir/theword.bmp stretch
#  catch setSwayBg

#  catch setXfceBg

#- combine all in 1 proc:
#  set setBg [setBackground]

}

#TODO: set setBg {get info from above!!!}

#Stop any running biblepix.tcl
foreach file [glob -nocomplain -directory $piddir *] {
  file delete -force $file
}
set pidfile [open $piddir/[pid] w]
close $pidfile

#4. C r e a t e   i m a g e   & start slideshow
if {$enablepic } {

  #run once with above TwdFileName
  source $Image
  setWinBG
  ##FOR TESTING:
  exec swaymsg output DVI-I-2 bg $imgDir/theword.bmp stretch
  #TODO: exec $setBg
  
  #exit if $crontab exists
  if {[info exists crontab]} {
    exit
  }

  #if Slideshow == 1
  if {$slideshow > 0} {
  
    #rerun until pidfile renamed by new instance
    set pidfile $piddir/[pid]
    set pidfiledatum [clock format [file mtime $pidfile] -format %d]
    while {[file exists $pidfile]} {
      if {$pidfiledatum==$heute} {
        sleep [expr $slideshow*1000]
        
        #export new TwdFile
        set ::TwdFileName [getRandomTwdFile]
        
        catch {source $Image}
        setWinBG
        
        ##FOR TESTING Wayland/Sway:
        exec swaymsg output DVI-I-2 bg $imgDir/theword.bmp stretch
      
      } else {
      
        #Calling new instance of myself
        source $Biblepix
      }
    }
  
  #if Slideshow == 0    
  } else {
    if {$platform=="windows"} {
      
      #run every 10s up to 10x so Windows has time to update
      set limit 0
      
      while {$limit<9} {
        sleep 10000
        setWinBG
        incr limit
      }
    }
  } ;#END if slideshow
} ;#END if enablepic

exit