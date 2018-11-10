# ~/Biblepix/prog/src/com/http.tcl
# Fetches TWD file list from bible2.net
# called by Installer / Setup
# Authors: Peter Vollmar, Joel Hochreutener, biblepix.vollmar.ch
# Updated: 7oct18

package require http

########### PROCS FOR SETUP UPDATE #################

proc setProxy {} {
  if { [catch {package require autoproxy} ] } {
    set host localhost
    set port 80
  } else {
    autoproxy::init
    set host [autoproxy::cget -host]
    set port [autoproxy::cget -port]
  }

  http::config -proxyhost $host -proxyport $port
}

proc getTesttoken {} {
  global bpxReleaseUrl

  set testfile "$bpxReleaseUrl/README"
  set testtoken [http::geturl $testfile -validate 1]

  if {[http::error $testtoken] != ""} {
    error [string cat "testtoken -> error:" [http::error $testtoken]]
  }

  if {[http::ncode $testtoken] != 200} {
    error [string cat "testtoken -> ncode:" [http::ncode $testtoken]]
  }

  return $testtoken
}

# throws an error if the test fails
proc testHttpCon {} {
  if { [catch getTesttoken error] } {
    puts "ERROR: http.tcl -> testHttpCon: $error"

    #try proxy & retry connexion
    setProxy

    if { [catch getTesttoken error] } {
      puts "ERROR: http.tcl -> testHttpCon -> proxy: $error"
      error $error
    }
  }
}

proc downloadFileArray {fileArrayName url} {
  upvar $fileArrayName fileArray
  foreach fileName [array names fileArray] {
    puts $fileName
    set filePath [lindex [array get fileArray $fileName] 1]
    set chan [open $filePath w]

    fconfigure $chan -encoding binary -translation binary
    http::geturl $url/$fileName -channel $chan

    close $chan
  }
}

proc downloadFile {pathArrayName varName isInitial} {
  set filepath [array get ::$pathArrayName $varName]
  set filename [file tail $filepath]

  puts $filename

  #get remote 'meta' info (-validate 1)
  set token [http::geturl $::bpxReleaseUrl/$filename -validate 1]
  array set meta [http::meta $token]

  #a) Overwrite file if "Initial"
  if {$isInitial} {
    downloadFileIntoDir $filepath $filename $token

  #b) Overwrite file if remote is newer
  } else {

    catch {set newtime $meta(Last-Modified)}
    catch {clock scan $newtime} newsecs
    catch {file mtime $filepath} oldsecs

    #download if times incorrect OR if oldfile is older/non-existent
    if { ! [string is digit $newsecs] ||
         ! [string is digit $oldsecs] ||
         $oldsecs<$newsecs } {
      downloadFileIntoDir $filepath $filename $token
    }
  }
}

proc downloadFileIntoDir {filePath fileName token} {
  #download file into channel unless error message
  puts $filePath

  if { "[http::ncode $token]" == 200 } {
    set chan [open $filePath w]

    fconfigure $chan -encoding utf-8
    http::geturl $::bpxReleaseUrl/$fileName -channel $chan

    close $chan
    http::cleanup $token
  }
}

proc runHTTP isInitial {
  global FilePaths BdfFontsPaths

  #Test connexion & start download
  if { [catch testHttpCon Error] } {
    set ::ftpStatus $::noConnHttp
    catch {NewsHandler::QueryNews $::noConnHttp red}

    puts "ERROR: http.tcl -> runHTTP($args): $Error"
    error $Error
  } else {
    foreach varName [array names FilePaths] {
      downloadFile FilePaths $varName $isInitial
    }

    foreach varName [array names BdfFontsPaths] {
      if {$varName == "ChinaFont"} {continue}

      downloadFile BdfFontsPaths $varName $isInitial
    }

    #Success message (source Texts again for Initial)
    catch {.if.initialMsg configure -bg green}
    catch {NewsHandler::QueryNews $::uptodateHttp green}
    catch {set ::ftpStatus $::uptodateHttp}

  } ;#end main condition
} ;#end runHTTP


########## PROCS FOR TWD LIST ####################

proc getRemoteRoot {} {
global twdUrl

  #tDom is standard in ActiveTcl, Linux distros vary
  if {[catch {package require tdom}]} {
    package require Tk
    tk_messageBox -type ok -icon error -title "BiblePix Installation" -message $::packageRequireTDom
     exit
  }

  #get twd list
  if {[catch "http::geturl $twdUrl"]} {
    setProxy
  }
  set con [http::geturl $twdUrl]
  set data [http::data $con]
    if {$data==""} {
      setProxy
      set con [http::geturl $twdUrl]
      set data [http::data $con]
    }
  return [dom parse -html $data]
}

proc listAllRemoteTWDFiles {lBox} {
  set root [getRemoteRoot]
  $lBox delete 0 end

  #set langlist
  set file [ $root selectNodes {//tr/td[text()="file"]} ]
  set spaceSize 12

  foreach node $file {
    set jahr [$node nextSibling]
    set lang [$jahr nextSibling]
    set version [[$lang nextSibling] nextSibling]
    set langText [$lang text]

    set name " $langText"
    for {set i [string length $langText]} {$i < $spaceSize} {incr i} {append name " "}
    append name "[$jahr text]        [$version text]"

    lappend sortlist $name
  }

  set sortlist [lsort $sortlist]

  foreach line $sortlist {
    $lBox insert end $line
  }
}

proc getRemoteTWDFileList {} {

  if {![catch {listAllRemoteTWDFiles .internationalF.twdremoteframe.lb}]} {
    .internationalF.status conf -bg green
    set status $::connTwd
  } else {
    .internationalF.status conf -bg red
    set status $::noConnTwd
  }
  return $status
}

proc downloadTWDFiles {} {
  global twdDir noConnTwd gettingTwd

  if { [catch {set root [getRemoteRoot]}] } {
    NewsHandler::QueryNews $::noConnTwd red
    return 1
  }

#  NewsHandler::QueryNews "$gettingTwd" orange - falsche Message!

  cd $twdDir
  #get hrefs alphabetically ordered
  set urllist [$root selectNodes {//tr/td/a}]
  set hrefs ""

  foreach url $urllist {lappend hrefs [$url @href]}
  set urllist [lsort $hrefs]
  set selectedindices [.internationalF.twdremoteframe.lb curselection]

  foreach item $selectedindices {
    set url [lindex $urllist $item]

    # https mit http ersetzen
    # TODO soon to be removed
    set indexOfSInHttps [expr [string first https $url] + 4]
    set url [string replace $url $indexOfSInHttps $indexOfSInHttps]

    set filename [file tail $url]

    NewsHandler::QueryNews "Downloading $filename..." lightblue

    if [regexp zh- $url] {
      set filepath $::FilePaths(ChinaFont)
      set filename [file tail $filepath]

      #get remote 'meta' info (-validate 1)
      set token [http::geturl $::bpxReleaseUrl/$filename -validate 1]
      array set meta [http::meta $token]

      #a) Overwrite file if "Initial"
      if {$isInitial} {
        downloadFile $filepath $filename $token

      #b) Overwrite file if remote is newer
      } else {

        set newtime $meta(Last-Modified)
        catch {clock scan $newtime} newsecs
        catch {file mtime $filepath} oldsecs

        #download if times incorrect OR if oldfile is older/non-existent
        if { ! [string is digit $newsecs] ||
             ! [string is digit $oldsecs] ||
             $oldsecs<$newsecs } {
          downloadFile $filepath $filename $token
        }
      }
    }


    set chan [open $filename w]
    fconfigure $chan -encoding utf-8
    http::geturl $url -channel $chan
    close $chan

    after 5000 .internationalF.f1.twdlocal insert end $filename
  }
    #deselect all downloaded files
    .internationalF.twdremoteframe.lb selection clear 0 end

}
