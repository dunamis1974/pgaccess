package provide CueCat 1.0

# CueCat, a CueCat Encoder/Decoder Package 
# copyright 2000 Michael Jacobson <jakeforce@home.com>

# This software is copyrighted by Michael Jacobson,
# 2000.  The following terms apply to all files associated with the software 
# unless explicitly disclaimed in individual files.
# 
# The authors hereby grant permission to use, copy, modify, distribute,
# and license this software and its documentation for any purpose, provided
# that existing copyright notices are retained in all copies and that this
# notice is included verbatim in any distributions. No written agreement,
# license, or royalty fee is required for any of the authorized uses.
# Modifications to this software may be copyrighted by their authors
# and need not follow the licensing terms described here, provided that
# the new terms are clearly indicated on the first page of each file where
# they apply.
# 
# IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
# FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
# ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
# DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# 
# THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE
# IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE
# NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
# MODIFICATIONS.
# 
# GOVERNMENT USE: If you are acquiring this software on behalf of the
# U.S. government, the Government shall have only "Restricted Rights"
# in the software and related documentation as defined in the Federal 
# Acquisition Regulations (FARs) in Clause 52.227.19 (c) (2).  If you
# are acquiring the software on behalf of the Department of Defense, the
# software shall be classified as "Commercial Computer Software" and the
# Government shall have only "Restricted Rights" as defined in Clause
# 252.227-7013 (c) (1) of DFARs.  Notwithstanding the foregoing, the
# authors grant the U.S. Government and others acting in its behalf
# permission to use and distribute the software in accordance with the
# terms specified in this license. 
 
namespace eval CueCat {
  # make the procedures visiable
  namespace export Decode Encode InvCase
  # charater position array used to determine the offset (zero based!!!)
  variable seq "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-"
	   	       #0123456789012345678901234567890123456789012345678901234567890123
               #          1         2         3         4         5         6
   
  proc Decode {inputstr} {
    variable seq
	 #remove grouping if brackets get applied
	regsub -all ^{ $inputstr "" inputstr
	regsub -all }$ $inputstr "" inputstr
	set outstr {}
	foreach catstr [split $inputstr .] {
		foreach {a b c d} [split $catstr ""] {
	  		set shiftnum 0
  			foreach catlet "$a $b $c $d" {
   				# get the position of each char (zero based)
		   		set num [string first $catlet $seq]
	   			# shift existing data right 6 and add new data
   				set shiftnum [expr [expr $shiftnum <<6] | $num]
			}
   			# now take the 24 bits and group them into 8 bit fields
   			set tempstr {}
   			for {set x 0} {$x<3} {incr x} {
   				# xor the data with dec 67 (aka hex 43) and get the char value
	   			# add the char to the end of the output string
                set tempstr [format %c [expr [expr $shiftnum & 255] ^ 0x43]]$tempstr
   				set shiftnum [expr $shiftnum >> 8]
			}
			append outstr $tempstr
		}
		# add a seperator in the string so you can use lindex command to get results
		append outstr " "
	}
	return [string trim $outstr]
  }

  proc Encode {args} {
    variable seq
	set outstr {}
	append outstr .
    #remove grouping if brackets get applied
	regsub -all ^{ $args "" args
	regsub -all }$ $args "" args
	#loop over each string set
	foreach catstr $args {
	    #read in 3 chars at a time (need to error check this) 
		foreach {a(0) a(1) a(2)} [split $catstr ""] {
		    set totnum 0
			for {set x 0} {$x<3} {incr x} {
			    # scanned char convert to ordinal num
				scan $a($x) %c decnum
				# existing number move it overs and put current num in lower 8 bit 
				# also xor 67 into the lower 8 bit number
				set totnum [expr [expr $totnum << 8] + [expr $decnum ^ 67]]
			}	
			set tempstr {}
			for {set x 0} {$x<4} {incr x} {
				#take the lower 6 bits of the totnum word and find its index in seq index list
				#prepend it to the tempstr array (to get the order correctly since we are doing it backwards
				set tempstr [string index $seq [expr $totnum & 0x3F]]$tempstr
				#get rid of the bits just processed
				set totnum [expr $totnum >> 6]	
			}
			#append the decode 3 chars (now 4 chars) to the output string
			append outstr $tempstr
		}
		append outstr .
	}
	return [string trim $outstr]
  }
  
  proc InvCase {inputstr} {
  	set original "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  	set inverse  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	regsub -all ^{ $inputstr "" inputstr
	regsub -all }$ $inputstr "" inputstr
  	set outstr {}
  	foreach letter [split $inputstr ""] {
      	set num [string first $letter $original]
      	if {$num > -1} {
        	append outstr [string index $inverse $num]
      	} else {
        	append outstr $letter
      	}
  	}
  	return [string trim $outstr]
  }
  
 proc ISBN {args}  {
	# the procedure to generate ISBN check sum is to:
	# take first 9 digits, and multiply the MSB by 10 the next by 9 etc
	# till the last digit is mult by 2. then add all these values and mod 11
	# subtract 11 from this value and add it onto the end as the ninth digit
	#978013022028890000
	#   0123456789
	#01234567890123
	regsub -all ^{ $args "" args
	regsub -all }$ $args "" args
	set isbnum [string range [lindex $args [expr [llength $args] -1]] 3 11]
	set check 0
    for {set i 0} {$i < 9} {incr i} {
		set check [expr $check + [expr [string index $isbnum $i] * (10 - $i)]]
	}
	set numcheck [expr $check % 11]
    if { $numcheck == 0} {
		append isbnum "0"
	} elseif { $numcheck == 1} {
		append isbnum "X"
	} else {
		append isbnum [expr 11-$numcheck]
	}
	#formated return statement (not needed) but keep just in case I reimplement it
	#return "[string range $isbnum 0 0]-[string range $isbnum 1 2]-[string range $isbnum 3 8]-[string range $isbnum 9 9]"
	return $isbnum
  }
}
