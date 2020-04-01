# Updated 1mch20
# thanks to Richard Suchenwirth!
# from: https://wiki.tcl-lang.org/page/Photo+image+rotation

#TODO integrate in BiblePix photo manipulation!

package require Tk
package require Img

proc image_rotate {img angle} {
  set ::update 0

    set angle [expr {fmod($angle, 360.0)}]
    if {$angle < 0} {set angle [expr {$angle + 360.0}]}
    if {$angle} {
       set w [image width  $img]
       set h [image height $img]
       set tmp [image create photo]
       $tmp copy $img
       $img blank
       set buf {}
       if {$angle == 90} {
          # This would be easier with lrepeat
          set row {}
          for {set i 0} {$i<$h} {incr i} {
             lappend row "#000000"
          }
          for {set i 0} {$i<$w} {incr i} {
             lappend buf $row
          }
          set i 0
          foreach row [$tmp data] {
             set j 0
             foreach pixel $row {
                lset buf $j $i $pixel
                incr j
             }
             incr i
          }
          $img config -width $h -height $w
          $img put $buf
       } elseif {$angle == 180} {
          $img copy $tmp -subsample -1 -1
       } elseif {$angle == 270} {
          # This would be easier with lrepeat
          set row {}
          for {set i 0} {$i<$h} {incr i} {
             lappend row "#000000"
          }
          for {set i 0} {$i<$w} {incr i} {
             lappend buf $row
          }
          set i $h
          foreach row [$tmp data] {
             set j 0
             incr i -1
             foreach pixel $row {
                lset buf $j $i $pixel
                incr j
             }
          }
          $img config -width $h -height $w
          $img put $buf
       } else {
          set a   [expr {atan(1)*8*$angle/360.}]
          set xm  [expr {$w/2.}]
          set ym  [expr {$h/2.}]
          set w2  [expr {round(abs($w*cos($a)) + abs($h*sin($a)))}]
          set xm2 [expr {$w2/2.}]
          set h2  [expr {round(abs($h*cos($a)) + abs($w*sin($a)))}]
          set ym2 [expr {$h2/2.}]
          $img config -width $w2 -height $h2
          for {set i 0} {$i<$h2} {incr i} {
             set toX -1
             for {set j 0} {$j<$w2} {incr j} {
                set rad [expr {hypot($ym2-$i,$xm2-$j)}]
                set th  [expr {atan2($ym2-$i,$xm2-$j) + $a}]
                if {
                   [set x [expr {$xm-$rad*cos($th)}]] < 0 || $x >= $w ||
                   [set y [expr {$ym-$rad*sin($th)}]] < 0 || $y >= $h
                } then {
                   continue
                }
                set x0 [expr {int($x)}]
                set x1 [expr {($x0+1)<$w? $x0+1: $x0}]
                set dx_ [expr {1.-[set dx [expr {$x1-$x}]]}]
                set y0 [expr {int($y)}]
                set y1 [expr {($y0+1)<$h? $y0+1: $y0}]
                set dy_ [expr {1.-[set dy [expr {$y1-$y}]]}]
                # This is the fastest way to get the data, because
                # in 8.4 [$photo get] returns a string and not a
                # list. This is horrible, but fast...
                scan "[$tmp get $x0 $y0] [$tmp get $x0 $y1]\
                        [$tmp get $x1 $y0] [$tmp get $x1 $y1]" \
                        "%d %d %d %d %d %d %d %d %d %d %d %d" \
                        r0 g0 b0  r1 g1 b1  r2 g2 b2  r3 g3 b3
                set r [expr {
                    round($dx*($r0*$dy+$r1*$dy_)+$dx_*($r2*$dy+$r3*$dy_))
                }]
                set g [expr {
                    round($dx*($g0*$dy+$g1*$dy_)+$dx_*($g2*$dy+$g3*$dy_))
                }]
                set b [expr {
                    round($dx*($b0*$dy+$b1*$dy_)+$dx_*($b2*$dy+$b3*$dy_))
                }]
                lappend buf [format "#%02x%02x%02x" $r $g $b]
                if {$toX == -1} {
                    set toX $j
                }
             }
             if {$toX>=0} {
                $img put [list $buf] -to $toX $i
                set buf {}
                if {$::update} { update }
             }
          }
       }
       image delete $tmp
    }
 }
 
#TESTING
set sample ~/Biblepix/TodaysPicture/theword.png
#set ::angle 10
#set ::update 1

#if {[file tail [info script]] == [file tail $argv0]} {
    pack [canvas .c -height 160 -width 250]
    #---assume standard installation paths:
#    set sample [file join [lindex $auto_path 2] images logo100.gif]
    set im [image create photo -file $sample]
    set im2 [image create photo]
    $im2 copy $im
    .c create image 50  90 -image $im
    .c create image 170 90 -image $im2
    entry .c.e -textvar angle -width 4
    set angle 99
    bind .c.e <Return> {
        $im2 config -width [image width $im] -height [image height $im]
        $im2 copy $im
        wm title . [time {image_rotate $im2 $::angle}]
    }
    .c create window 5 5 -window .c.e -anchor nw
    checkbutton .c.cb -text Update -variable update
#    set ::update 1
    .c create window 40 5 -window .c.cb -anchor nw

    bind . <Escape> {exec wish $argv0 &; exit}
#}
