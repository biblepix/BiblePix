# ~/Biblepix/prog/src/biblepix-setup.tcl
# Main Setup program for BiblePix, starts Setup dialogue
# Called by User via Windows/Unix Desktop entry
# If called by BiblePix-Installer, this is the first file downloaded + executed
################################################################################
# Version: 2.3
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated: 10apr17

package require Tk

#Verify location & source vars
set srcdir [file dirname [info script]]
set Globals "[file join $srcdir share globals.tcl]"

#Set initial FTP message & progress bar
frame .updateFrame -padx 40 -pady 50 -borderwidth 20
pack .updateFrame -fill y -expand true

label .updateFrame.pbTitle -justify center -bg lightblue -fg black -borderwidth 10 -textvariable pbTitle
ttk::progressbar .updateFrame.progbar -mode indeterminate -length 200

pack .updateFrame.pbTitle .updateFrame.progbar

if {[catch {source $Globals}]} {
	set pbTitle "Update not possible.\nYou must download and rerun the BiblePix Installer from bible2.net."
	after 7000 {exit}
} else {

	#Make empty dirs in case of GIT download
	file mkdir $sigdir $imgdir $twddir $bmpdir $piddir $confdir
	#Rename $maindir from 2.3
	catch {file rename $srcdir/main $srcdir/pic}

	#Set initial texts if missing
	if {[catch {source -encoding utf-8 $SetupTexts ; setTexts $lang}]} {
		set updatingHttp "Updating BiblePix program files..."
		set noConnHttp "No connection for BiblePix update. Try later."
	}

	# 1.  D O   H T T P  U P D A T E   (if not initial)

	.updateFrame.progbar start

	if { [info exists InitialJustDone] } {
		set pbTitle $uptodateHttp
	} else {	
		set pbTitle $updatingHttp
		source $Http
			
		# a) Do Update if $config exists
		if { [file exists $Config] } {
			set error [runHTTP]
		# b) Do Reinstall
			} else {
			set error [runHTTP Initial]
		}
	}

	.updateFrame.progbar stop

	# 2. B U I L D  M A I N  G U I

	source $SetupMainFrame
}
