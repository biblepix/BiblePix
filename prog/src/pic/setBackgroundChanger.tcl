# ~/Biblepix/prog/src/pic/setBackgroundChanger.tcl
# Searches system for current Desktop manager, gives out appropriate BG changing command
# Called by Biblepix
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated: 22may18

# WINDOWS: accepts command through RUNDLL32.EXE - a bit buggy still...
# LINUX SWAY (WAYLAND): accepts command through 'swaymsg'
# GNOME: needs no image changer, detects image change, so just provide imgPath (in setupSave)
# KDE: needs to be configured (in setupSave)
# XFCE4: needs to be configured (in setupSave)

# B a c k g r o u n d  c h a n g e r s
proc setWinBG {} {
  package require registry
  set regpath [join {HKEY_CURRENT_USER {Control Panel} Desktop} \\]
  registry set $regpath Wallpaper [file nativename $::TwdTIF]
}

proc setSwayBg {} {
  set outputs [exec swaymsg -t get_outputs]
  #find lines with 'Output' and copy last/next word - 2 different formats found!
  foreach line [split $outputs \n] {
    #Bash format (as in Bash shell)
    if [regexp "Output" $line] {
      return "swaymsg $line bg $::TwdBMP stretch"
    #JSON format (as in tclsh/tkcon)
    } elseif [regexp "name" $line] {
      set s [regexp -line -inline -lineanchor {name.*$} $line]
      regsub -all {[name",: {}"]} $s {} outputName
    }
  }
  return $outputName
}

# C r e a t e   'setBg'   p r o c   i f   a p p l i c a b l e

#Create setBg proc for Windows 
if {$platform=="windows"} {
  setWinBg
  proc setBg {} {
    exec RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True
  }
  return
}

#Skip Gnome
if {! [info exists env(GNOME_KEYRING_CONTROL)] &&    
  ! [info exists env(GNOME_DESKTOP_SESSION_ID)] } {
  return ""
}

#Skip KDE & XFCE4
if { [info exists env(XDG_CURRENT_DESKTOP)] &&
     $env(XDG_CURRENT_DESKTOP) == "KDE" ||
     $env(XDG_CURRENT_DESKTOP) == "XFCE" ||
     [info exists env(DESKTOP_SESSION)] &&
     $env(DESKTOP_SESSION == "kde-plasma" ||
     $env(DESKTOP_SESSION == "xfce"
     } {
  return ""
}

#Create setBg for Wayland/Sway 
if { [info exists env(SWAYSOCK)] ||
     [info exists env(WAYLAND_DISPLAY)] } {
  set outputName [setSwayBg]

  proc setBg {} {
    upvar 1 outputName outputName
    exec swaymsg output $outputName bg $::TwdBMP stretch
  }

  return
}

#Create setBg for Xloadimage (general Linux)
if {[auto_execok xloadimage] != ""} {
  proc setBg {} {
    exec xloadimage -onroot $::TwdPNG
  }
  return
}

#Create setBg for ImageMagick (general Linux)
if {[auto_execok display] != ""} {
  proc setBg {} {
    exec display -window root $::TwdPNG
  }
  return
}