# ~/Biblepix/prog/src/pic/setupAnnotatePng.tcl
# Sourced by ?
# Authors: Peter Vollmar & Joel Hochreutener, biblepix.vollmar.ch
# Updated 13apr20
proc evalPngComment {file} {
  set T [readPngComment $file]

#TODO get list indexes of x / y / b (=brightness)
#TODO get rid of non-pertaining bits of info

#To set text bits into vars:
  set [lindex $T 0] [lindex $T 1]

#To process vars  >> PrintBdf??
  namespace eval somenamespace {}
  set somenamespace::x $x
  set somenamespace::y $y
  set somenamespace::b $b

}

##################################################################
# Below procs have been copied from: https://wiki.tcl-lang.org
# With thanks and God's blessings to AF!
##################################################################

# readPngComment
#adapted from: https://wiki.tcl-lang.org/page/Writing+PNG+Comments
##reads the comment blocks from a PNG file. This functionality is also present in the tcllib png module.
##currently only supports uncompressed comments. Does not attempt to verify checksum.
##called by ...
proc readPngComment {file} {
    set fh [open $file r]
    fconfigure $fh -encoding binary -translation binary -eofchar {}
    if {[read $fh 8] != "\x89PNG\r\n\x1a\n"} { close $fh; return }
    set text {}

    while {[set r [read $fh 8]] != ""} {
        binary scan $r Ia4 len type
        set r [read $fh $len]
        if {[eof $fh]} { close $fh; return }
        if {$type == "tEXt"} {
            lappend text [split $r \x00]
        } elseif {$type == "iTXt"} {
            set keyword [lindex [split $r \x00] 0]
            set r [string range $r [expr {[string length $keyword] + 1}] end]
            binary scan $r cc comp method
            if {$comp == 0} {
                lappend text [linsert [split [string range $r 2 end] \x00] 0 $keyword]
            }
        }
        seek $fh 4 current
    }
    close $fh
    return $text
}


# writePngComment
##adapted from: https://wiki.tcl-lang.org/page/Reading+PNG+Comments
##reads the comment blocks from a PNG file. This functionality is also present in the tcllib png module.
##called by ...

#TODO write 3 keywords with text at 1 go!
proc writePngComment {file keyword text} {

    set fh [open $file r+]

    fconfigure $fh -encoding binary -translation binary -eofchar {}

    if {[read $fh 8] != "\x89PNG\r\n\x1a\n"} { close $fh; return }



    while {[set r [read $fh 8]] != ""} {

        binary scan $r Ia4 len type

        if {$type ==  "IDAT"} {

            seek $fh -8 current

            set pos [tell $fh]

            set data [read $fh]

            seek $fh $pos start

            set size [binary format I [string length "${keyword}\x00${text}"]]

            puts -nonewline $fh "${size}tEXt${keyword}\x00${text}\x00\x00\x00\x00$data"

            close $fh

            return

        }

        seek $fh [expr {$len + 4}] current

    }

    close $fh

    return -code error "no data section found"

}

