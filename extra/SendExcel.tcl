# contributed by Karl Swisher

# Send Data To Excel Sheet
#
# There is not much code here for what it does.  I use this
# feature frequently in Quickbooks.  It might be handy to 
# have in PGAccess.  I'm sure some more experience programmers
# would be able to improve on it and make it more efficient.
#
# This is one of the TCL demo programs but modified to extract
# the cell values from a TCL list variable and incorporates  
# some PGAccess variable names from its ImportExport program.
# 
# 
package require tcom
set application [::tcom::ref createobject "Excel.Application"]

# This starts Excel and makes it appear on the screen
$application Visible 1

set workbooks [$application Workbooks]

# This adds a new workbook
set workbook [$workbooks Add]
set worksheets [$workbook Worksheets]
set worksheet [$worksheets Item [expr 1]]
set cells [$worksheet Cells]

# exporting
# A select statement would be done here or already have been done
# and the data passed.  This is where the "while" statement starts
# is in the PGAccess Import/Export script.
# Put some test data in the list variable and loop through the rows 3 times
for {set row 1} {$row <4} {incr row} {
	if {$row ==1} {
		set buf ""
		lappend buf {Cell A1} {Cell B1} {Cell C1}
	}
	if {$row ==2} {
		# This part will test the code for >26 columns
		set buf ""
		lappend buf {Cell A2} {Cell B2} {Cell C2} {Cell D2} \
				{Cell E2} {Cell F2} {Cell G2} {Cell H2} \
				{Cell I2} {Cell J2} {Cell K2} {Cell L2} \
				{Cell M2} {Cell N2} {Cell O2} {Cell P2} \
				{Cell Q2} {Cell R2} {Cell S2} {Cell T2} \
				{Cell U2} {Cell V2} {Cell W2} {Cell X2} \
				{Cell Y2} {Cell Z2} {Cell AA2} {Cell AB2}
	}
	if {$row ==3} {
		set buf ""
		# Note data may even be a formula
		lappend buf {Cell A3} {Cell B3} {Cell C3} {=2+2}
	}

	# get the total number of columns by counting the items in the list
	set totnumcol [llength $buf]

	if {$totnumcol > 256} {
		# Query or table greater than the max cols allowed.
		# This will not be executed in this demo since nothing gets close
		# to that limit.   Not sure with the offsets where column IV will be
		# 255 or 256.   Use 256 for now.
		# Should bring up a requester to alert the user.   Future code to give
		# the user additional options to cancel, cut it off at the max, or add an
		# additional Excel sheet and continue the export.  For now we will just limit
		# it to the max.

		set totnumcol 256
	}
	if {$row >65536} {
		# Same thing is done with the max rows.  There is also the memory maximum at which
		# point we could say, "Are you crazy ?  Do you know how much memory this will take ?"
		# Should bring up a requester to alert the user.   Future code to give
		# the user additional options to cancel, cut it off at the max by exiting the loop, or add an
		# additional Excel sheet and continue the export.
	}
	#loop through the list
	for {set i 0} {$i<[expr $totnumcol]} {incr i} {
		# convert the item position in the list to an Excel column
		if {$i<26} {
			# < column AA
			set column [format %c [expr $i+65]]
		} else {
			# > column Z
			set column {}
			append column [format %c [expr int(($i/26)-1)+65]] [format %c [expr $i-(int($i/26)*26)+65]]
		}

		# extract the value for the cell from the list
		set cellvalue [lindex $buf $i]

		if {[string length $cellvalue]>255} {
			# cell contents greater than 255 chars
			# chop it off. 0 to 254 is 255 chars
			set cellvalue [string range 0 254]
		}
		# send the cell to excel
		$cells Item $row $column $cellvalue

		# orginal command line in PGAccess 
		# catch {puts $fid $buf}
	}
	
#	incr row
}

exit
