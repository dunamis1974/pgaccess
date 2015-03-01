package provide Barcode 1.0

#barcode generator by F. Voloch

namespace eval Barcode {

    # we only need one proc visible
    namespace export Checksum Left Plus Code

    #right hand digit encoding, digit i is encoded as i-th term of list
    variable right {"1110010" "1100110" "1101100" "1000010" "1011100" "1001110" "1010000" "1000100" "1001000" "1110100"}

    #list for encoding first digit
    set first {"11111" "10100" "10010" "10001" "01100" "00110" "00011" "01010" "01001" "00101"}

    #checksum calculation for EAN code
    proc Checksum {str} {
        set c 0
        for {set i 0} {$i < 12} {incr i} {
            set c [expr $c + (1 + 2*($i%2))*[string index $str $i]]
        }
        return [expr (-$c)%10]
    }; # end proc Checksum


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
    }; # end proc Left


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
    }; # end proc Plus


    #producing the binary string for the barcode
    proc Code {str} {
        variable first
        variable right
		append str [Checksum $str]
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
    }; # end proc Code


}; # end namespace Barcode
