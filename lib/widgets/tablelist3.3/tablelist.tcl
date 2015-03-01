#==============================================================================
# Main Tablelist package module.
#
# Copyright (c) 2000-2003  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

package require Tcl 8
package require Tk  8

namespace eval tablelist {
    #
    # Public variables:
    #
    variable version	3.3
    if {[string compare $::tcl_platform(platform) macintosh] != 0} {
	#
	# On the Macintosh, the tablelist::library variable is
	# set in the file pkgIndex.tcl, because of a bug in
	# [info script] in some Tcl releases for that platform.
	#
	variable library	[file dirname [info script]]
    }

    #
    # Creates a new tablelist widget:
    #
    namespace export	tablelist

    #
    # Sorts the items of a tablelist widget based on one of its columns:
    #
    namespace export	sortByColumn
}

package provide Tablelist $tablelist::version
package provide tablelist $tablelist::version

lappend auto_path [file join $tablelist::library scripts]
