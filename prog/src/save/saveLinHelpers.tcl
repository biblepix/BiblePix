#~/Biblepix/prog/src/save/setupSaveLinHelpers.tcl
# Sourced by SetupSaveLin
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated: 28sep18

################################################################################################
# A)  A U T O S T A R T : KDE / GNOME / XFCE4 all respect the Linux Desktop Autostart mechanism
#   more exotic Desktops NEED CONFIGURING via CRONTAB (see below)
#
# B)  D E S K T O P   M E N U : (Rightclick for Setup) works with KDE / GNOME / XFCE4 
#   other desktops can't be configured, hence information about Setup path is important >Manual
################################################################################################

#Set & create general Linux Desktop dirs
##recognised by alle Desktops, including KDE5
set LinConfDir $HOME/.config
set LinLocalShareDir $HOME/.local/share
set LinDesktopFilesDir $LinLocalShareDir/applications

#Create dirs if missing (needed for [open] command)
file mkdir $LinDesktopFilesDir

#Set KDE dirs & Create ~/.kde if missing
set KdeDir [glob -nocomplain $HOME/.kde*]
set KdeConfDir $KdeDir/share/config
file mkdir $KdeConfDir


#Determine KDE config files
set Kde4ConfFile $KdeConfDir/plasma-desktop-appletsrc
set Kde5ConfFile $LinConfDir/plasma-org.kde.plasma.desktop-appletsrc

if [file exists $Kde4ConfFile] {
  set KdeVersion 4
} else {
  set KdeVersion 5
}

##KDE4 deprecated service path - only respected if KdeVersion=4
set Kde4ServiceDir ~/.kde/share/kde4/services

#Wayland/Sway
set SwayConfFile $LinConfDir/sway/config


# 1  M E N U   E N T R Y   .DESKTOP   F I L E 

## A) GNOME/XFCE/KDE5
set LinDesktopFile $LinDesktopFilesDir/biblepixSetup.desktop

## B) KDE4
set Kde4DesktopFile $KdeConfDir/share/kde4/services/biblepixSetup.desktop

## C) MENU ENTRY RIGHTCLICK FILE (works only for some Plasma 5 versions of Konqueror/Dolphin?)
set Kde5DesktopActionFile $LinDesktopFilesDir/biblepixSetupAction.desktop


# 3 Autostart files
##this is obsolete:
set Kde4AutostartDir $KdeDir/Autostart
set Kde4AutostartFile $Kde4AutostartDir/biblepix.desktop

set LinAutostartDir $LinConfDir/autostart
file mkdir $LinAutostartDir
set LinAutostartFile $LinAutostartDir/biblepix.desktop

#TODO: move to?
set Xfce4ConfigFile $LinConfDir/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml


# formatLinuxExecutables
## 1 Check first line of Linux executables for correct 'env' path
#### Standard env path as in Ubuntu/Debian/Gentoois /usr/bin/env
## 2 Make files executable
## 3 make ~/bin/biblepix-setup.sh
## 4 Add ~/bin to PATH in .bashrc
proc formatLinuxExecutables {} {
  global Setup Biblepix env
  
  set standardEnvPath {/usr/bin/env}
  set currentEnvPath [auto_execok env]

  #1. Set permissions to executable
  file attributes $Biblepix -permissions +x
  file attributes $Setup -permissions +x
  
  #2. Reset 1st Line if not standard
  if {$currentEnvPath != $standardEnvPath} {
    setShebangLine $currentEnvPath
  }

  # 3. Put Setup bash script in ~/bin (precaution in case it can't be found in menus)
  set homeBin $env(HOME)/bin
  set homeBinFile $homeBin/biblepix-setup.sh
  
  if { ![file exists $homeBin] } {
    file mkdir $homeBin
    file attributes $homeBin -permissions +x
  }
  #Create script text and save
  set chan [open $homeBinFile w]
  append t #!/bin/sh \n exec { } $Setup
  puts $chan $t
  close $chan
  
  # 4. Add ~/bin to $PATH in .bashrc
  set bashrc "$env(HOME)/.bashrc"
  set PATH $env(PATH)

  ##check PATH & make entry text
  if {![regexp $homeBin $PATH]} {
    set homeBinText "
if \[ -d $env(HOME)/bin \] ; then
export PATH=\$HOME/bin:\$PATH
fi"
    #read out existing .bashrc
    if [file exists $bashrc] {
      set chan [open $bashrc r]
      set t [read $chan]
      close $chan
    } {
      set t ""
    }
    
    #append text if missing
    if {![regexp $homeBin $t]} {
      puts "Adding path entry to .bashrc..."
      set chan [open $bashrc a]
      puts $chan $homeBinText
      close $chan
    }
  }

  #Clean up & make file executable
  catch {unset shBangLine $t}
  file attributes $homeBinFile -permissions +x

} ;#END formatLinuxExecutables


# setShebangLine
## changes 1st line of executables (Biblepix+Setup) if wrong
## called by formatLinuxExecutables
proc setShebangLine {currentEnvPath} {
    global Biblepix Setup
    append shBangLine #! $currentEnvPath { } tclsh

    ##read out Biblepix & Setup texts
    set chan1 [open $Biblepix r]
    set chan2 [open $Setup r]
    set text1 [read $chan1]
    set text2 [read $chan2]
    close $chan1
    close $chan2

    ##replace 1st line with current sh-bang
    regsub -line {^#!.*$} $text1 $shBangLine text1
    set chan [open $Biblepix w]
    puts $chan $text1
    close $chan
    regsub -line {^#!.*$} $text2 $shBangLine text2
    set chan [open $Setup w]
    puts $chan $text2
    close $chan

    #Cleanup
    catch {unset $text1 $text2}

} ;#END setShebangLine


####################################
# A U T O S T A R T   S E T T E R S
####################################

# setupLinAutostart
## makes Autostart entries for Linux Desktops: GNOME, XFCE4, KDE4, KDE5, Wayland/Sway
## args == delete
## called by SetupSaveLin
proc setupLinAutostart args {
  global Biblepix Setup LinIcon bp LinAutostartFile Kde4AutostartDir Kde4AutostartFile SwayConfFile
  #set Err 0
  
  #If args exists, delete any autostart files and exit
  if  {$args != ""} {
    file delete $LinAutostartFile $Kde4AutostartFile
    catch {setSwayConfig delete}
    return 0
  }
  
  #Delete any previous crontab entry
  catch {setupLinCrontab delete}

  #set Texts
  set desktopText "\[Desktop Entry\]
Name=$bp
Type=Application
Icon=$LinIcon
Comment=Runs BiblePix at System boot
StartupNotify=false
X-KDE-StartupNotify=False
Exec=$Biblepix
"
  #Make .desktop file for KDE4 Autostart (obsolete)
  if [file exists $Kde4AutostartDir] {
    set chan [open $Kde4AutostartFile w]
    puts $chan $desktopText
    close $chan
    file attributes $Kde4AutostartFile -permissions +x
  }

  #Make .desktop file for GNOME/XFCE/KDE5 Autostart
  set chan [open $LinAutostartFile w]
  puts $chan $desktopText
  close $chan
  file attributes $LinAutostartFile -permissions +x
  
  
  #Set up Sway if conf file found
  if [file exists $SwayConfFile] {
    if [catch setupSwayBackground] {
      puts "Having problem setting up Sway background"
      return 1
    }
  }
    return 0
  
} ;#END setLinAutostart

# setupSwayBackground
## makes entries for BP autostart and initial background pic
## args==delete entry
## called by setupLinAutostart
proc setupSwayBackground args {
  global LinConfDir SwayConfFile Biblepix env

  #Read out text
  set chan [open $SwayConfFile r]
  set configText [read $chan]
  close $chan

  #Check previous entries
  set entryFound 0
  if [regexp {[Bb]ible[Pp]ix} $configText] {
    set entryFound 1
  }

  #Delete any entry if "args"
  if {$args!="" && $entryFound} {
    set chan [open $SwayConfFile w]
    regsub -all -line {^.*ible[Pp]ix.*$} $configText {} configText
    puts $chan $configText
    close $chan
    puts "Deleted BiblePix entry from $SwayConfFile"
    return 0
  }
  
  #Skip if entry found
  if {$entryFound} {
    puts "Sway config: Nothing to do."
    return 0
  }
  #Append entry
  append autostartLine \n # {BiblePix: this runs BiblePix & sets initial background picture} \n exec { } $Biblepix
  set outputList [getSwayOutputName]

  #append lines at end of file
  set chan [open $SwayConfFile a]
  puts $chan $autostartLine
  foreach outputName $outputList {
    puts $chan "exec swaymsg output $outputName bg $::TwdBMP center"
  }
  close $chan

  puts "Made BiblePix entry in $SwayConfFile"
  return 0
}

#TESTING WESTON (if running): 
##THIS WONT WORK WITHOUT Weston providing an Autostart mechanism!
#TODO: implemented in checkRunningLinuxDesktop
proc setupWestonBackground {} {
	global TwdPNG env

	if [info exists env(WESTON_CONFIG_FILE)] {
		set westonConfFile $env(WESTON_CONFIG_FILE)
	} elseif [file exists .config/weston.ini] {
		set westonConfFile .config/weston.ini
	}
	set chan [file open $westonConfFile r]
	set fileText [read $chan]
	close $chan

	if [regexp iblepix $fileText] {
	puts "Nothing to do"		
	return 1
	}
	
	set chan [file open $westonConfFile w]
	
	if [regexp background-image $fileText] {
		regsub -line {(background-image=)(.*$) $fileText \2$TwdPNG} fileText
	} elseif [regexp Shell $fileText] {
		regsub -line {^\[Shell\].*$} $fileText {[Shell]
background-image=$TwdPNG} fileText
	} else {
		append fileText \n \[Shell\] \n background-image=$TwdPNG \n background-type=scale-crop
	}

	puts $chan $fileText
	close $chan
	return 0
}


################################################################################
#  M E N U  E N T R Y   C R E A T E R   F O R   L I N U X   D E S K T O P S
################################################################################

# setupLinMenu
## Makes .desktop files for Linux Program Menu entries 
## Works on KDE / GNOME / XFCE4
## called by SetupSaveLin

########################################################
## Possible paths:
#
## General Linux & KDE5: 
# ~/.local/share/applications
#
## KDE4 - deprecated, used if dirs exist:
## ~/.kde/share/kde4/services
## KDE5 - ignored (see general Linux):
## ~/.local/share/applications/kservices5/ServiceMenus
## ~/.local/share/kservices5/ServiceMenus
########################################################
proc setupLinMenu {} {
  global LinIcon srcdir Setup bp LinDesktopFilesDir KdeVersion Kde4ServiceDir
  set filename "biblepixSetup.desktop"
  set categories "Settings;Utility;Education;DesktopSettings;Core"
  
  #set Texts
  set desktopText "\[Desktop Entry\]
Name=$bp Setup
Type=Application
Icon=$LinIcon
Categories=$categories
Comment=Runs & configures $bp
Exec=$Setup
"

  #make .desktop file for GNOME & KDE prog menu
  set chan [open $LinDesktopFilesDir/$filename w]
  puts $chan $desktopText
  close $chan
  
  #make .desktop file for KDE4, if dir exists
  if {$KdeVersion==4} {
    set categories "Education;Graphics"
    set chan [open $Kde4ServiceDir/$filename w]
    puts $chan $desktopText
    close $chan
  }
  return 0
  
} ;#END setupLinMenu

# setupKdeActionMenu
## Produces right-click action menu in Konqueror (and possibly Dolphin?)
## seen to work only in some versions of KDE5 - very buggy!
## Called by SetupSaveLin ?if KDE detected?

########################################################
#Below proved to work sometimes:
#  reference Text:
#[Desktop Entry]
#Type=Service
#ServiceTypes=KonqPopupMenu/Plugin
#MimeType=all/all;
#Actions=countlines;
#X-KDE-Submenu=Count
#X-KDE-StartupNotify=false
#X-KDE-Priority=TopLevel

#[Desktop Action countlines]
#Name=Count lines
#Exec=kdialog --msgbox "$(wc -l %F)"
############################################################

#This works with Konqueror and Dolphin (only KDE4?)
proc setupKdeActionMenu {} {
  global bp LinIcon Setup Kde5DesktopActionFile
  set desktopFilename "biblepixSetupAction.desktop"
  set desktopText "\[Desktop Entry\]
Type=Service
MimeType=all/all;
Actions=BPSetup;
X-KDE-ServiceTypes=KonqPopupMenu/Plugin
X-KDE-StartupNotify=true
X-KDE-Priority=TopLevel
OnlyShowIn=Old;

\[Desktop Action BPSetup\]
Name=$bp Setup
Icon=$LinIcon
Exec=$Setup
"
  set chan [open $Kde5DesktopActionFile w]
  puts $chan $desktopText
  close $chan
  
  return 0
}


################################################
# B A C K G R O U N D   P I C   S E T T E R S
################################################

# setupKdeBackground
## Configures KDE4 or KDE5 Plasma for single pic or slideshow
# TODO: > Anleitung in Manpage für andere KDE-Versionen/andere Desktops (Rechtsklick > Desktop-Einstellungen >Einzelbild/Diaschau)

proc setupKdeBackground {} {
  global KdeVersion Kde4ConfFile Kde5ConfFile TwdPNG slideshow imgDir

  #check kread/kwrite executables
  if {[auto_execok kreadconfig5] != "" && 
      [auto_execok kwriteconfig5] != ""} {
    set kread kreadconfig5
    set kwrite kwriteconfig5

  } elseif { [auto_execok kreadconfig] != "" && 
      [auto_execok kwriteconfig] != ""} {
    set kread kreadconfig
    set kwrite kwriteconfig

puts $kwrite
puts $kread
  } else {

    return 1
  }

  #set KDE4 if detected
  set errCode4 ""
  if {$KdeVersion==4} {
    catch {setupKde4Bg $Kde4ConfFile $kread $kwrite} errCode4
puts $errCode4

  }

  #set KDE5 always
  catch {setupKde5Bg $Kde5ConfFile $kread $kwrite} errCode5
puts $errCode5

  if {$errCode4=="" && $errCode5==""} {
    return 0
  } else {
    return "KDE4: $errCode4 / \nKDE5: $errCode5"
  }
  
} ;#END setKdeBackground

# setupKde4Bg
# called by setKdeBackground if KDE4 rcfile found
proc setupKde4Bg {Kde4ConfFile kread kwrite} {
  global slideshow imgDir
  set rcfile [file tail $Kde4ConfFile]
  puts "Setting up KDE4 background..."
  
  if {!$slideshow} {
    set interval 3600
  } else {
    set interval $slideshow
  }
  
  set slidepaths $imgDir
  set mode Slideshow
        
  for {set g 1} {$g<200} {incr g} {

    if {[exec $kread --file $rcfile --group Containments --group $g --key wallpaperplugin] != ""} {
    
      puts "Changing KDE $rcfile Containments $g ..."

      #1. [Containments][$g]
      ##this is always 'image'
      exec $kwrite --file $rcfile --group Containments --group $g --key wallpaperplugin image
      exec $kwrite --file $rcfile --group Containments --group $g --key wallpaperpluginmode $mode

      #2. [Containments][$g][Wallpaper][image]
      ##this is in seconds:
      exec $kwrite --file $rcfile --group Containments --group $g --group Wallpaper --group image --key slideTimer $interval
      exec $kwrite --file $rcfile --group Containments --group $g --group Wallpaper --group image --key slidepaths $slidepaths
      exec $kwrite --file $rcfile --group Containments --group $g --group Wallpaper --group image --key wallpaper $::TwdPNG
      ##position: 1 seems to be 'centered'
      exec $kwrite --file $rcfile --group Containments --group $g --group Wallpaper --group image --key wallpaperposition 1
    }
  }
  return 0
} ;#END setKde4Bg

# setupKde5Bg
## called by setKdeBackground if KdeVersion==5
## expects rcfile [file join $env(HOME) .config plasma-org.kde.plasma.desktop-appletsrc]
## expects correct version of kreadconfig(?5) kwriteconfig(?5)
## must be set to slideshow even if single picture, otherwise it is never renewed at boot
#

###This was produced by KDE5 upon choosing slideshow: #########################
# [Containments][1][Wallpaper][General]
# Image=file:///usr/share/desktop-base/joy-inksplat-theme/wallpaper/contents/images/1280x1024.svg
# SlidePaths=/usr/share/images

#(We don't (re)produce this section)
# [Containments][1][Wallpaper][org.kde.image][General]
# Image=file:///usr/share/desktop-base/joy-inksplat-theme/wallpaper/contents/images/1280x1024.svg
# height=1024
# width=1280

# [Containments][1][Wallpaper][org.kde.slideshow][General]
# SlideInterval=30
# SlidePaths=/home/pv/Biblepix/Image
# height=1024
# width=1280
################################################################################3
proc setupKde5Bg {Kde5ConfFile kread kwrite} {
  global slideshow TwdPNG imgDir
  set rcfile $Kde5ConfFile
  
  puts "Setting up KDE5 background..."
  
  #Always set wallpaperplugin=slideshow, set single pic hourly (else never renewed!)
  set oks "org.kde.slideshow"
  if {!$slideshow} {
    set interval 3600
  } else {
    set interval $slideshow
  }
  
  for {set g 1} {$g<200} {incr g} {
        
    if {[exec $kread --file $rcfile --group Containments --group $g --key activityId] != ""} {
    
      puts "Changing KDE $rcfile Containments $g ..."
      
      ##1. [Containments][$g] : Set wallpaperplugin
      exec $kwrite --file $rcfile --group Containments --group $g --key wallpaperplugin $oks
      
      ##2.[Containments][$g][Wallpaper][General] - General settings (not sure if needed)
      exec $kwrite --file $rcfile --group Containments --group $g --group Wallpaper --group General --key Image file://$TwdPNG
      exec $kwrite --file $rcfile --group Containments --group $g --group Wallpaper --group General --key SlidePaths $imgDir
      
      ##3. [Containments][$g][Wallpaper][org.kde.slideshow][General]: Set SlideInterval+SlidePaths+height+width
      exec $kwrite --file $rcfile --group Containments --group $g --group Wallpaper --group $oks --group General --key SlidePaths $imgDir
      exec $kwrite --file $rcfile --group Containments --group $g --group Wallpaper --group $oks --group General --key SlideInterval $interval
      exec $kwrite --file $rcfile --group Containments --group $g --group Wallpaper --group $oks --group General --key height [winfo screenheight .]
      exec $kwrite --file $rcfile --group Containments --group $g --group Wallpaper --group $oks --group General --key width [winfo screenwidth .]
      #FillMode 6=centered
      exec $kwrite --file $rcfile --group Containments --group $g --group Wallpaper --group $oks --group General --key FillMode 6
  
    }
  }
  return 0
} ;#END setupKde5Bg

# setupXfceBackground
##configures XFCE4 single pic or slideshow - TODO: >update MANPAGE!!!!!!!!!
### configFile hierarchy: 
  #<channel name="xfce4-desktop" ...>
  #<property name="backdrop" type="empty">
  #  <property name="screen0" type="empty">
  #    <property name="monitor0" type="empty">
  #      <property name="image-path"..."/>
#xfconf-query syntax für neue 'property':
# xfconf-query -c -p* -n -t -s
# * ganzer (neuer) Pfad
##########################################

proc setupXfceBackground {} {
  global slideshow

  #Exit if xfconf-query not found
  if {[auto_execok xfconf-query] == ""} {
    return 1
  }
  
  #Our 'channel' is actually an XML file found in .config/xfce4/xfconf/xfce-perchannel-xml/
  set channel "xfce4-desktop"
  
  puts "Configuring XFCE background image..."

  #This rewrites backdrop.list for old Xfce4 installations
  ##not used now
  if {$slideshow} {
    set backdropDir ~/.config/xfce4/desktop
    file mkdir $backdropDir
    set backdropList $backdropDir/backdrop.list
    set chan [open $backdropList w]
    puts $chan {# xfce backdrop list}
    puts $chan "$::TwdBMP\n$::TwdPNG"
    close $chan
    file attributes $backdropList -permissions 00644
    set monPicPath $backdropList
    set cycleEnableValue true
  } else {
    set monPicPath $::TwdBMP
    set cycleEnableValue false
  }


 #Set monitoring - no Luck, holds up everything!
#exec xfconf-query -c xfce4-desktop -m
#DIESE PFADE SIND IMMER DA:
##  A) /backdrop/screen?/monitor?/workspace[0-3]/last-image
##  B) /backdrop/screen?/monitor?/image-path
    
#xfconf-query -c xfce4-desktop -l >
#/backdrop/screen0/monitor0/image-path NEEDED? [path]
#/backdrop/screen0/monitor0/workspace0/backdrop-cycle-enable NEEDED true
#/backdrop/screen0/monitor0/workspace0/backdrop-cycle-timer NEEDED int

# xfconf-query 'set' = set property if existent
# xfconf-query 'create' = create property

  #Check monitor name
  set desktopXmlTree [exec xfconf-query -c xfce4-desktop -l]

  if [regexp {monitor0} $desktopXmlTree] {
    set monitorName "monitor"
  } else {
    regexp -line {(backdrop/screen0/)(.*)(/.*$)} $t var1 monitorName var3
  }

  #1. Scan through 4 screeens & monitors
  ##NOTE: Never seen more than screen0 , but 4 each is a reasonable compromise.
  for {set s 0} {$s<5} {incr s} {
    for {set m 0} {$m<5} {incr m} {

      #This key was added in new inst., not needed here:
#      set CycleTimerPeriodMonPath /backdrop/screen$s/$monitorName$m/backdrop-cycle-period
      set ImgMonPath /backdrop/screen$s/${monitorName}${m}/image-path

      if [catch {exec xfconf-query -c $channel -p $ImgMonPath}] {
      
        continue
      
      } else {
      
        puts "Setting $ImgMonPath"
        
        #A: MONITOR SECTION

        ##most of this is only needed for old inst.
        #must set single img path even if slideshow?
        ##old inst. needs path to backdrop.list!
        #imgStyle seems to be: 1==centred
        #imgShow seems to be needed for old inst. 
        
        set ImgStyleMonPath /backdrop/screen$s/$monitorName$m/image-style
        set ImgShowMonPath /backdrop/screen$s/$monitorName$m/image-show
        
        #these are needed here for old inst., and also in the screen section below for the new!!
        set LastImgMonPath /backdrop/screen$s/$monitorName$m/last-image
        set CycleEnableMonPath /backdrop/screen$s/$monitorName$m/backdrop-cycle-enable
        set CycleTimerMonPath /backdrop/screen$s/$monitorName$m/backdrop-cycle-timer
        
        #Old inst. has only minutes ; set type to 'uint', timer to >1 minute
        set minutes [expr max($slideshow/60, 1)]
        puts "minutes: $minutes"

        exec xfconf-query -c $channel -p $ImgMonPath -n -t string -s $monPicPath
        
        exec xfconf-query -c $channel -p $ImgStyleMonPath -n -t int -s 1
        exec xfconf-query -c $channel -p $ImgShowMonPath -n -t bool -s true
        exec xfconf-query -c $channel -p $LastImgMonPath -n -t string -s $::TwdBMP        
        exec xfconf-query -c $channel -p $CycleEnableMonPath -n -t bool -s $cycleEnableValue
        exec xfconf-query -c $channel -p $CycleTimerMonPath -n -t uint -s $minutes
        #exec xfconf-query -c $channel -p $CycleTimerPeriodMonPath -n -t int -s 1
        
        #this makes no sense.... TODO!
        
        set ctrlBit 1
      }

puts "Ad hena azaranu 1"

      #B: WORKSPACE SECTION
      
      ## Scan through 9 workspaces! (w) 
      #NOTE1: any number of ws's can be added, but standard is 4.
      #NOTE2: old inst. doesn't seem to respect workspaces, 
      # >> put all information in the /screen0/monitor0 main section for now
      for {set w 0} {$w<10} {incr w} {
      
        #check if workspace exists, else skip
        set LastImgWsPath /backdrop/screen$s/$monitorName$m/workspace$w/last-image
        if [catch {exec xfconf-query -c xfce4-desktop -p $LastImgWsPath}] {

          continue
          
        } else {

          puts "Setting $LastImgWsPath"
          
          set CycleEnableWsPath /backdrop/screen$s/$monitorName$m/workspace$w/backdrop-cycle-enable
          set CycleTimerWsPath /backdrop/screen$s/$monitorName$m/workspace$w/backdrop-cycle-timer
          set CycleTimerPeriodWsPath /backdrop/screen$s/$monitorName$m/workspace$w/backdrop-cycle-period
          set ImgStyleWsPath /backdrop/screen$s/$monitorName$m/workspace$w/image-style
          
          exec xfconf-query -c $channel -p $LastImgWsPath -n -t string -s $::TwdBMP
          exec xfconf-query -c $channel -p $CycleEnableWsPath -n -t bool -s $cycleEnableValue
          exec xfconf-query -c $channel -p $CycleTimerWsPath -n -t uint -s $slideshow
          exec xfconf-query -c $channel -p $CycleTimerPeriodWsPath -n -t int -s 0
          exec xfconf-query -c $channel -p $ImgStyleWsPath -n -t int -s 1
        }
      } ;#END for3
    } ;#END for2
  } ;#END for1
    puts "Ad hena azaranu 2"

#TODO: this dunnot work!
  if [info exists ctrlBit] {
      return 0
  } {
    puts NoLuckSettingXfce
    return 1
  }
  
} ;#END setXfceBackground


# setupGnomeBackground - TODO: das funktioniert nicht mit return!
##configures Gnome single pic
##setting up slideshow not needed because Gnome detects picture change automatically
proc setupGnomeBackground {} {
  #Gnome2
  if {[auto_execok gconftool-2] != ""} {
    catch {exec gconftool-2 --type=string --set /desktop/gnome/background/picture_filename $::TwdPNG} errCode
  #Gnome3
  } elseif {[auto_execok gsettings] != ""} {
    catch {exec gsettings set org.gnome.desktop.background picture-uri file:///$::TwdBMP} errCode
  #no Gnome
  } else {
    return 1
  }
  
  if {$errCode==""} {
    return 0
  } else {
  return $errCode
  }
} ;#END setGnomeBackground


########## R E L O A D   D E S K T O P S  ##########################

# reloadKdeDesktop - TODO: DONT BOTZHER!!
##Rereads all .desktop and XML files
##Called by SetupSaveLin after changing config files
proc reloadKdeDesktop {} {
  set k4 [auto_execok kbuildsycoca4]
  set k5 [auto_execok kbuildsycoca5]
  if {$k5 != ""} {
    set command $k5
  } elseif {$k4 != ""} {
    set command $k4
  }
#  tk_messageBox -type ok -icon info -title "BiblePix Installation" -message "TODO:MUSTRELOADDESKTOP"
  exec $command
}

# reloadXfceDesktop
##Rereads XFCE4 Desktop configuration
##Called by SetupSaveLin after changing config files
proc reloadXfceDesktop {} {
  if {[auto_execok xfdesktop-setting?] != ""} {
    exec xfdesktop-settings
    tk_messageBox -type ok -icon info -title "BiblePix Installation" -message "Testing XFCE reload" -parent .
    exec killall xfdesktop-settings
  }
  xfdesktop --reload
}

######################################
####### C R O N T A B ################
######################################

# setupLinCrontab
##Detects running cron(d) & installs new crontab
##returns 0 or 1 for calling prog
##called by SetupSaveLin & Uninstall
##    T O D O: USE CRONTAB ONLY FOR INITIAL START, NOT FOR SLIDESHOW 
#    only FOR DESKTOPS OTHER THAN KDE/GNOME/XFCE4
proc setupLinCrontab args {

  global Biblepix Setup slideshow tclpath unixdir env linConfDir
  set cronfileOrig $unixdir/crontab.ORIG
  
  #if ARGS: Delete any crontab entries & exit
  if {$args != ""}  {
    if [file exists $cronfileOrig] {
      exec crontab $cronfileOrig
    } else {
      exec crontab -r
    }
    return
  }
  
  #Exit if [crontab] not found
  if { [auto_execok crontab] ==""} {
    return 0
  }

  #Check for running cron/crond & exit if not running
  catch {exec pidof crond} crondpid
  catch {exec pidof cron} cronpid

  if {! [string is digit $cronpid] && 
      ! [string is digit $crondpid] } {
    return 0
  }


###### 1. Prepare crontab text #############################
 
  #Check for user's crontab & save 1st time
  if {! [catch {exec crontab -l}] && 
      ! [file exists $cronfileOrig] } { 
    set runningCrontext [exec crontab -l]
    #save only if not B|biblepix
    if {! [regexp iblepix $runningCrontext] } {
      set chan [open $cronfileOrig w]
      puts $chan $runningCrontext
      close $chan
    }
  }

  #Prepare new crontab entry for running BiblePix at boot
  set cronScript $unixdir/cron.sh
  set cronfileTmp /tmp/crontab.TMP
  append BPcrontext \n @daily $cronScript \n @reboot $cronScript

  #Check presence of saved crontab
  if [file exists $cronfileOrig] {
    set chan [open $cronfileOrig r]
    set crontext [read $chan]
    close $chan
  }

  #Create/append new crontext, save&execute
  if [info exists crontext] {
    append crontext $BPcrontext
  } else {
    set crontext $BPcrontext
  }
  set chan [open $cronfileTmp w]
  puts $chan $crontext
  close $chan

  exec crontab $cronfileTmp
  file delete $cronfileTmp
  
  
##### 2. Prepare cronscript text ############################

  set cronScriptText "# ~/Biblepix/prog/unix/cron.sh\n# Bash script to add BiblePix to crontab
count=0
limit=5
#wait max. 5 min. for X or Wayland (should work with either)
export DISPLAY=:0
$tclpath $Biblepix
#get exit code
while [ $? -ne 0 ] \&\& \[ \"\$count\" -lt \"\$limit\" \] ; do 
  sleep 60
  ((count++))
  $tclpath $Biblepix
done
"
  #save cronscript & make executable
  set chan [open $cronScript w]
  puts $chan $cronScriptText
  close $chan
  file attributes $cronScript -permissions +x


### 3. Set ::crontab global var & delete any previous Autostart entries
  set ::crontab 1
 # setLinAutostart delete

  #Return success
  return 1
    
} ;#end setupLinCrontab


##################################################
# L I N U X   T E R M I N A L   S E T T E R 
##################################################

# setupLinTerminal
## Copies configuration file for Linux terminal to $confdir
## Makes entry in .bashrc for 
##use 'args' to delete - T O D O > Uninstall !!
# Called by SetupSaveLin if $enableterm==1
proc setupLinTerminal {args} {
  global confdir HOME Terminal
  
  #Delete any previous/erroneous entries in .bash_profile
  set f $HOME/.bash_profile
  if [file exists $f] {
    set chan [open $f r]
    set t [read $chan]
    close $chan
    if [regexp {[Bb]iblepix} $t] {
      regsub -all -line {^.*iblepix.*$} $t {} t
      set chan [open $f w]
      puts $chan $t
      close $chan
    }
  }
  
  #Read out .bashrc
  set f $HOME/.bashrc
  
  if [file exists $f] {
    set chan [open $f r]
    set t [read $chan]
    close $chan

    #If 'args' delete any previous entries 
    if {$args != "" && $t != ""} {  
      regsub -all -line {^.*iblepix.*$} $t {} t
      set chan [open $f w]
      puts $chan $t
      close $chan
      return
    }

    # Set entry text for .bashrc
    append bashrcEntry {
#Biblepix: This line shows The Word each terminal
} {[ -f } $Terminal { ] && } $Terminal

    if [regexp {[Bb]iblepix} $t] {
    
      #Ignore if previous entries found
      puts "Bashrc/Terminal: Nothing to do"

    } else {

      #Append line
      append t $bashrcEntry
      set chan [open $f w]
      puts $chan $t
      close $chan
    }
    
  } ;#End if file exists
  
  
  #### 2. Create Terminal Config file always ###
  
  set configText {
  #!/bin/sh
  # ~/Biblepix/prog/conf/term.conf
  # Sets font variables for display of 'The Word' in a Linux terminal
  # Called by ~/Biblepix/prog/unix/term.sh
  # This command will produce 'The Word' in your shells:
  #   sh ~/Biblepix/prog/unix/term.sh
  # You can put it in ~/.bashrc for automation.
  # Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
  # Updated: 5oct17  

  ############################################################
  # N O  C H A N G E S  H E R E !
  # To change, replace variables further down!
  ############################################################
  #text colours (for normal text)
  txtred='\e[0;31m' # Red
  txtylw='\e[0;33m' # Yellow
  txtblu='\e[0;34m' # Blue
  txtpur='\e[0;35m' # Purple
  txtcyn='\e[0;36m' # Cyan
  txtwht='\e[0;37m' # White
  txtgrn='\e[0;32m' # Green
  #bold text colours (for title)
  bldblu='\e[1;34m' # Bold blue
  bldblk='\e[1;30m' # Bold black
  bldred='\e[1;31m' # Bold red
  bldgrn='\e[1;32m' # Bold green
  bldylw='\e[1;33m' # Bold yellow
  bldwht='\e[1;37m' # Bold white
  yontem=f$x
  #background colours (for title)
  bakblu='\e[44m'   # Blue
  bakcyn='\e[46m'   # Cyan
  bakwht='\e[47m'   # White
  bakred='\e[41m'   # Red
  bakgrn='\e[42m'   # Green
  #Reset colour to shell default
  txtrst='\e[0m'

  #########################################################
  # M A K E   A N Y  C H A N G E S   H E R E :
  # Variables used by BiblePix
  # To change, replace with any of the above, preceded by $
  #########################################################

  #Title background
  titbg=$bakblu
  #Title
  tit=$bldylw
  #Introline
  int=$txtred
  #Reference
  ref=$txtgrn
  #Reset to default
  txt=$txtrst
  #Tabulators
  tab="\t\t\t"
  }
  
  #Copy to file if new or corrupt
  set termConfFile "$confdir/term.conf"
  catch {file size $termConfFile} size
  if {![string is digit $size] || $size<50} {
    set chan [open $termConfFile w]
    puts $chan $configText
    close $chan
  }

} ;#END setupLinTerminal