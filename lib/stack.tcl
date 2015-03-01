##############################################################################
#
# Namespace for simple stack procedures.
#
# Usage: 
#
# 	-initializing the stack:
#		Stack::reset $Stack
#
#	-pop from the stack:
#		set data [Stack::pop $Stack]
#
#	-push in the stack:
#		Stack:: push $Stack $data
#
#	-quireing the item on the top of the stack:
#		set stack_top [Stack::top $Stack]
#
#	-emptiing the Stack:
#		set empty_stack [Stack::is_empty $Stack]
#
# Bartus Levente (bartus.l at bitel.hu)
#
##############################################################################

namespace eval Stack {

proc reset {Stack} {
	set Stack ""
}

proc pop {Stack} {
	set res [lindex $Stack [expr [llength $Stack] - 1 ]]
	if {[llength $Stack] == 0 } {
		# error "Error: stack empty"
		return ""
	} else {
		set Stack [lreplace $Stack end end]
		return $res
	}
}

proc push {Stack arg} {
	lappend Stack $arg
}

proc top {Stack} {
	return [lindex $Stack [expr [llength $Stack] - 1 ]]
}

proc is_empty {Stack} {
	if {[llength $Stack] == 0} {
		return 1
	} else {
		return 0
	}
}

}




