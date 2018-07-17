# ~/Biblepix/prog/src/save/setupSaveLin.tcl
# Sourced by SetupSave
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated: 17jul18

source $SetupSaveLinHelpers
source $SetupTools
source $SetBackgroundChanger

set Error 0
set hasError 0

#Check / Amend Linux executables - TODO: Test again
catch formatLinuxExecutables Error
puts "linExec $Error"

##################################################
# 1 Set up Linux A u t o s t a r t for all Desktops
##################################################
if [catch setupLinAutostart Err] {
puts $Err
  tk_messageBox -type ok -icon error -title "BiblePix Installation" -message $linSetAutostartProb
}


####################################################
# 2 Set up Menu entries for all Desktops
####################################################

# Check running desktop
##returns 1 if GNOME
##returns 2 if KDE
##returns 3 if XFCE4
##returns 4 if Wayland/Sway
##returns 0 if no running desktop detected
set runningDesktop [detectRunningLinuxDesktop]

#Install crontab autostart if no Desktop found - TODO: Test again
#TODO: apologize for not making menu entry...
if {$runningDesktop == 0} {
  puts "No Running Desktop found"
  catch setupLinCrontab Error0
  puts "Crontab $Error0"
}

#Install Menu entries for all desktops - no error handling
catch setupLinMenu Error
puts "LinMenu $Error"
catch setupKdeActionMenu Error
puts "KdeAction $Error"


#################################################
# 3 Set up Linux terminal -- TODO? error handling?
#################################################
if {$enableterm} {
  catch setupLinTerminal Error
  puts "Terminal $Error"
  
}

#Exit if no picture desired
if {!$enablepic} {
  return 0
}


#####################################################
## 4 Set up Desktop Background Image - with error handling
#####################################################

#xfconf-query syntax für neue 'property':
# xfconf-query -c -p* -n -t -s
# * ganzer (neuer) Pfad
##########################################

#NEW ATTEMPT WITH native tools!!!!
proc setupXfceBackground {} {
  global slideshow TwdBMP TwdTIF
  
  #Exit if xfconf-query not found
  if {[auto_execok xfconf-query] == ""} {
    return 1
  }
  
  #Our 'channel' is actually an XML file found in .config/xfce4/xfconf/xfce-perchannel-xml/
  set channel "xfce4-desktop"
  
  puts "Configuring XFCE background image..."

proc meyutar {} {
  #TODO: Check if this is really needed !!!!!!!!!!!!!!
  #was dropped back in 2015 !!!!!!!!!!!!!¨
  #Create/Change backdrop.list if $slideshow
  if {$slideshow} {
    set backdropdir ~/.config/xfce4/desktop
    file mkdir $backdropdir
    set backdroplist $backdropdir/backdrop.list
    set chan [open $backdroplist w]
    puts $chan "$TwdBMP\n$TwdTIF"
    close $chan
  }
}

 #Set monitoring - no Luck, holds up everything!
#exec xfconf-query -c xfce4-desktop -m
  
#xfconf-query -c xfce4-desktop -l >
#/backdrop/screen0/monitor0/image-path NEEDED [path]
#/backdrop/screen0/monitor0/workspace0/backdrop-cycle-enable NEEDED true
#/backdrop/screen0/monitor0/workspace0/backdrop-cycle-timer NEEDED int

#Check monitor name
set desktopXmlTree [xfconf-query -c xfce4-desktop -l]
if [regexp {monitor[0-9]} $desktopXmlTree] {
  set monitorName "monitor"
} else {
  regexp -line {(backdrop/screen0/)(.*)(/.*$)} $t var1 monitorName var3
  set imgpath /backdrop/screen$s/$monitorName$m/image-path
      set imgStylePath /backdrop/screen$s/$monitorName$m/image-style
      exec xfconf-query -c $channel -p $imgpath -n -t string -s $TwdBMP
        exec xfconf-query -c $channel -p $imgStylePath -n -t int -s 3
}

  #Scan through 4 screeens & monitors
  for {set s 0} {$s<5} {incr s} {
    for {set m 0} {$m<5} {incr m} {
    
      # 'set' = set if existent
      # 'create' = create if non-existent

      set imgpath /backdrop/screen$s/$monitorName$m/image-path
      set imgStylePath /backdrop/screen$s/$monitorName$m/image-style
      if [catch "exec xfconf-query -c $channel -p $imgpath"] {
      
        continue
      
      } else {
      
        puts "Setting $imgpath"
      
        #must set single img path even if slideshow!
        exec xfconf-query -c $channel -p $imgpath -n -t string -s $TwdBMP
        exec xfconf-query -c $channel -p $imgStylePath -n -t int -s 3
        set ctrlBit 1
      }

      if {$slideshow} {
        
        #run through 4 workspaces (w) 
        #NOTE: any number of ws's can be added, but standard is 4.
        for {set w 0} {$w<4} {incr w} {
        puts "Setting workspace $w"
        
        #set cycle-timer in secs, set cycle-period to secs (=0), set type to 'uint'
          set backdropCycleEnablePath /backdrop/screen$s/$monitorName$m/workspace$w/backdrop-cycle-enable
          set backdropCycleTimerPath /backdrop/screen$s/$monitorName$m/workspace$w/backdrop-cycle-timer
          set backdropCycleTimerPeriod /backdrop/screen$s/$monitorName$m/workspace$w/backdrop-cycle-period
          exec xfconf-query -c $channel -p $backdropCycleEnablePath -n -t bool -s true
          exec xfconf-query -c $channel -p $backdropCycleTimerPath -n -t uint -s $slideshow
          exec xfconf-query -c $channel -p $backdropCycleTimerPeriod -n -t int -s 0
          
        } ;#END for3
      } ;#END if slideshow
    } ;#END for2
  } ;#END for1
    

#reload XFCE4 desktop if running - TODO hammer des net scho woanders?
proc reloadXfceDesktop {} {
  if {! [catch "exec pidof xfdesktop"] } {
    wm withdraw .
    exec xfdesktop --reload
  }
}

  if [info exists ctrlBit] {
      return 0
  } {
    puts NoLuckSettingXfce
    return 1
  }
  
} ;#END setXfceBackground


tk_messageBox -type ok -icon info -title "BiblePix Installation" -message $linChangingDesktop

set GnomeErr [setupGnomeBackground]
set KdeErr [setupKdeBackground]
set XfceErr [setupXfceBackground]

#Create OK message for each successful desktop configuration
if {$GnomeErr==0} {
  append desktopList GNOME
}
if {$KdeErr==0} {
  append desktopList KDE
}
if {$XfceErr==0} {
  append desktopList XFCE4
}
#puts "desktopList: $desktopList"

#Create Ok message if desktopList not empty
if {$desktopList != ""} {
  foreach desktopName $desktopList {
    tk_messageBox -type ok -icon info -title "BiblePix Installation" -message "$desktopName: $changeDesktopOk" 
  }
#Create Error message if no desktop configured
} else {
  tk_messageBox -type ok -icon error -title "BiblePix Installation" -message $linChangeDesktopProb
}


########################################################
# 5 Try reloading KDE & XFCE Desktops - no error handling
# Gnome & Sway need no reloading
########################################################
if {$runningDesktop==2} {set desktopName KDE}
if {$runningDesktop==3} {set desktopName XFCE4}
tk_messageBox -type ok -icon info -title "BiblePix Installation" -message "$desktopName: $linReloadingDesktop"

#Run progs end finish
if {$runningDesktop == 2} {
  catch reloadKdeDesktop Error
  puts "reloadKde $Error"
  
} elseif {$runningDesktop == 3} {
  catch reloadXfceDesktop
  puts "runningDesktop $Error"
}

return 0