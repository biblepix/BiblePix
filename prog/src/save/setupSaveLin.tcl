# ~/Biblepix/prog/src/share/setupSaveLin.tcl
# Sourced by SetupSave
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated: 21dec2016

source $SetupSaveLinHelpers

## REMOVE ANY OLD BIBLEPIX INSTALLATIONS
file delete -force ~/.biblepix
#check .bashrc for old entry and remove
set chan [open ~/.bashrc]
set readfile [read $chan]
close $chan
set string1 {biblepix}
set string2 {prog/bash}

if {[regexp $string1 $readfile] || [regexp $string2 $readfile]} {
	regsub -all -line "^$string1.*$" $readfile {} readfile
        regsub $string2 $readfile {prog/unix} readfile
        set chan [open ~/.bashrc w]
	puts $chan $readfile
	close $chan
}

#move any old jpegs to $picsdir
set jpglist [glob -nocomplain -directory $rootdir *.jpg *.jpeg *.JPG *.JPEG] 
foreach file $jpglist {
	file copy -force $file $picsdir
	file delete $file
}

set Error [catch setLinAutostart]

## SET BACKGROUND PICTURE/SLIDESHOW if $enablepic
if {$enablepic} {

	tk_messageBox -type ok -title "BiblePix Installation" -message $linChangeDesktop
	set Error [catch setLinBackground]

}

if {$Error} {
	tk_messageBox -type ok -icon error -title "BiblePix Installation" -message $linChangeDesktopProb

} else {
	tk_messageBox -type ok -icon info -title "BiblePix Installation" -message $changeDesktopOk
#	exit
}
