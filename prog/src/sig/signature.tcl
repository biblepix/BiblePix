# ~/Biblepix/prog/src/sig/signature.tcl
# Adds The Word to e-mail signature files once daily
# called by Biblepix
# Author: Peter Vollmar, biblepix.vollmar.ch
# Updated: 29sep20

source $TwdTools
source $SigTools

puts "Updating signatures..."
set twdFileList [getSigTwdList]

foreach twdFileName $twdFileList {
  
  #set endung mit 8 Extrabuchstaben nach Sprache_
  set endung [string range $twdFileName 0 8] 
  set sigFile [file join $sigdir signature-$endung.txt]
  
  #check date, skip if today's and not empty
  set dateidatum [clock format [file mtime $sigFile] -format %d]
  if {$heute == $dateidatum && [file size $sigFile] != 0} {
    puts " [file tail $sigFile] is up-to-date"
    continue
  }

  #Recreate The Word for each file
  set dw [getTodaysTwdSig $twdFileName]
  set twdPath [file join $twdDir $twdFileName]
  set cleanSig [cleanSigfile $twdPath]

  #Write new sig to file
  set sigPath [file join $sigdir $sigFile]
  set chan [open $sigPath w]
  puts $chan $cleanSig 
  puts $chan \n${dw}
  close $chan
  
  puts "Created signature for signature-$endung"
  
} ;#END main loop

#####################################################################
### TROJITA IMAP MAILER 
#####################################################################

#Check presence of Trojita Win/Lin config || exit
##Windoze bug: auto_execok can't find executable in C:\Program Files (x86)\trojita.exe 
set trojitaLinConfFile [file join $env(HOME) .config flaska.net trojita.conf]
set trojitaWinRegpath [join {HKEY_CURRENT_USER SOFTWARE flaska.net trojita} \\]

if {$os=="Windows NT"} {
  package require registry
  
  if [catch {registry keys $trojitaWinRegpath}] {
    return "No Registry entry for Trojitá found. Exiting."
  }
	  catch doSigTrojitaWin err

} elseif {$os=="Linux"} {

  if {[auto_execok trojita] == "" || ![file exists $trojitaLinConfFile]} {
    return "No Trojitá executable / configuration file found. Exiting."
  }
  catch doSigTrojitaLin err
}

if [info exists err] {
  puts $err
}

###########################################################################
### EVOLUTION MAIL CLIENT (only Linux)
###########################################################################

#Check presence of Evolution
if {[auto_execok evolution] != ""} {
  puts "Updating signatures for Evolution..."
  doSigEvolution
}

#Clean up global vars
catch {unset ::sigChanged}
