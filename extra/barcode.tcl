#!/usr/local/bin/wish
#barcode generator by F. Voloch



#checksum calculation for EAN code

proc Checksum {str} {
set c 0
for {set i 0} {$i < 12} {incr i} {
set c [expr $c + (1 + 2*($i%2))*[string index $str $i]]
}
return [expr (-$c)%10]
}

#right hand digit encoding, digit i is encoded as i-th term of list

set right {"1110010" "1100110" "1101100" "1000010" "1011100" \
"1001110" "1010000" "1000100" "1001000" "1110100"}

#turns right encoding into left, byt is the right encoding of
#a digit and par is its parity. For odd parity is "ones complement"
#and even parity is reverse string

proc Left {byt par} {
if {$par} {
set r [Plus $byt "1111111"]
} else {
set r ""
for {set i 0} {$i < 7} {incr i} {
append r [string index $byt [expr 6 - $i]]
}
}
return $r
}

#addition of binary strings as F_2-vectors.

proc Plus {a b} {
set t $a
set n [string length $b]
if {[string length $a] < $n} {
set n [string length $a]
set t $b
}
set s ""
for {set i 0} {$i < $n} {incr i} {
set s [append s [expr {[string index $a $i]^[string index $b $i]}]]
}
set r [append s [string range $t $n [string length $t]]]
return $r
}

#list for encoding first digit

set first {"11111" "10100" "10010" "10001" "01100" "00110" "00011" \
"01010" "01001" "00101"}

#producing the binary string for the barcode
#12-digit barcodes are UPC so add a zero
#no checksum performed yet.

proc Barcode {str} {
global first right
if {[string length $str] == 12} {
set str "0$str"
}
set sys [lindex $first [string index $str 0]]
set r "101"
append r [Left [lindex $right [string index $str 1]] 1]
for {set i 0} {$i < 5} {incr i} {
append r [Left [lindex $right [string index $str [expr {$i + 2}]]] [string index $sys $i]]
}
append r "01010"
for {set i 0} {$i < 6} {incr i} {
append r [lindex $right [string index $str [expr {$i + 7}]]]
}
append r "101"
return $r
}

#The GUI
#uncomment lines about ".g" to allow printing

canvas .c -height 100 -width 220 -bg white
entry .e -width 15 -textvariable bcode
#frame .g
#set fil "canvas.ps"
#button .g.s -text "save file:" -command ".c postscript -file $fil"
#entry .g.f -width 10 -textvariable fil
pack .c .e  -side top
#pack .g -side top
#pack .g.s .g.f -side left
bind . <Return> "Do 0"

#plotting the barcode!!
#it is set to make barcodes twice as long as standard sized ones
#for better viewing. If you want to print standard sized ones then,
#on the line ".c create rectangle ..." below, change the 2*$i to simply $i
# and change the 12 to an 11.

proc Do {str} {
global bcode
if {$str == "0"} {
set str "$bcode"
}
.c delete all
set bst [Barcode $str]
for {set i 0} {$i < 95} {incr i} {
if {[string index $bst $i]} {
.c create rectangle [expr {10 + 2*$i}] 10 [expr {12 + 2*$i}] 60 -fill black -width 0
}
}
}

set bcode "9780122612053"
Do $bcode
