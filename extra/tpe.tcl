#!/usr/bin/wish

#############################################################################
#
#   Tcl Project Editor v.1.0
#
#  
# Copyright (c) 2002 Constantin Teodorescu , Braila, ROMANIA
# All Rights Reserved
#
# this code is freely distributable, but is provided as-is with
# no waranty expressed or implied.
#
# send comments to teo@flex.ro
#
# Licensed as .... let's see , LGPL is good ?
#
# Feel free to improve it, share it with other developers
#
#

global TPEVAR; 
global syntax; 
global widget; 
	set widget(currentFileLabel) {.mw.fsl.lcurfile}
	set widget(files) {.mw.cpd17.01.cpd18.01.cpd19.01}
	set widget(procs) {.mw.cpd17.01.cpd18.02.cpd20.01}
	set widget(grep) {.mw.cpd17.02.cpd23.01}
	set widget(src) {.mw.cpd17.02.cpd21.03}
	set widget(srcParent) {.mw.cpd17.02}
	set widget(rev,.mw.cpd17.01.cpd18.01.cpd19.01) {files}
	set widget(rev,.mw.cpd17.01.cpd18.02.cpd20.01) {procs}
	set widget(rev,.mw.cpd17.02.cpd21.03) {src}
	set widget(rev,.mw.sl.lcurfile) {currentFileLabel}
	set widget(rev,.mw.cpd17.02.cpd23.01) {grep}
	

####################################
# USER DEFINED PROCEDURES
#
proc init {argc argv} {
global TPEVAR syntax tcl_traceExec tcl_platform
	set TPEVAR(projname) ""
	set TPEVAR(clipboard) ""
	set TPEVAR(files) ""
	set TPEVAR(currentFile) ""
	set TPEVAR(whatToFind) ""
	set TPEVAR(history) {}
	set TPEVAR(forward) {}
	set TPEVAR(syntaxHighlight) 0
	set TPEVAR(autoCompletion) 1
	set TPEVAR(procedureTip) 1
	set TPEVAR(currentFileIsTclSource) 0

	set TPEVAR(overwrite) 0
	set TPEVAR(ovrMessage) "INS"

	foreach command [info commands] {
		set syntax(.tcl,$command) 1
	}
	if {[string toupper $tcl_platform(platform)] == "WINDOWS"} {
		set TPEVAR(font_normal) {"MS Sans Serif" 9}
		set TPEVAR(font_bold) {"MS Sans Serif" 9 Bold}
		set TPEVAR(font_fixed) {"Courier New" 9}
		set TPEVAR(font_small) {"Arial" 8}
	} else {
		set TPEVAR(font_normal) {"Helvetica" -12}
		set TPEVAR(font_bold) {"Helvetica" -12 Bold}
		set TPEVAR(font_fixed) {"Clean" 13}
		set TPEVAR(font_small) {"Helvetica" -10}
	}
}


init $argc $argv


#
#
#    Checks if edited source is changed, and if so, save it into
#    the global array   TPEVAR(source,filename)
#    Saves also the cursor position for future restoring
#
#

proc check_for_changed {} {
global TPEVAR widget

	if {$TPEVAR(currentFile) == ""} {return}

	src:checkForProcedureDefinition

	# Check to see if current edited source is changed and if so
	# it saves it into a memory variable

	set fileName $TPEVAR(currentFile)

	# if not changed, don't save
	if {! $TPEVAR(changed,$fileName)} {return}

	# Time to save the edited source
	set nlines [lindex [split [$widget(src) index end] .] 0]

	# Ignore the last empty lines from the end of the source
	for {set i $nlines} {$i>1} {incr i -1} {
		if {[string trim [$widget(src) get $i.0 "$i.0 lineend"]] != ""} {
			break
		}
	}
	set TPEVAR(source,$fileName) [$widget(src) get 1.0 "$i.0 lineend"]
	set TPEVAR(cursor,$fileName) [$widget(src) index insert]
}

proc src:loadAndJumpLine {} {
global TPEVAR widget

	if {[set curselection [$widget(grep) curselection]] == ""} {return}
	$widget(src) tag delete showline
	set infoline [$widget(grep) get $curselection]
	set infolist [split $infoline " "]
	set filename [lindex $infolist 0]
	set lineno [lindex $infolist 1]
	src:addHistory
	if {$filename != $TPEVAR(currentFile)} {
		check_for_changed
		project:select_file $filename
		$widget(src) see $lineno.0
		$widget(src) mark set insert $lineno.0
		$widget(src) tag add showline $lineno.0 $lineno.end
		$widget(src) tag configure showline -background yellow
		return
	}
	$widget(src) see $lineno.0
	$widget(src) mark set insert $lineno.0
	$widget(src) tag add showline $lineno.0 $lineno.end
	$widget(src) tag configure showline -background yellow
}

# Add current insert position of cursor into history list
proc src:addHistory {} {
	global TPEVAR widget
	if {$TPEVAR(currentFile) == ""} {return}
	set insertpos [$widget(src) index insert]
	if {$insertpos == "1.0"} {return}
	# Forget the forward list now
	set TPEVAR(forward) {}
	#showTrace "Acum fac ADD la history"
	lappend TPEVAR(history) [list $TPEVAR(currentFile) $insertpos]
	if {[llength $TPEVAR(history)] > 100} {
		set TPEVAR(history) [lrange $TPEVAR(history) 1 end]
	}
	#set TPEVAR(lastMessage) "$TPEVAR(history) : $TPEVAR(forward)"
}


# Back one step into history
proc src:backHistory {} {
	global TPEVAR widget
	if {[llength $TPEVAR(history)] == 0} {bell ; return}
	if {[llength $TPEVAR(forward)] == 0} {
		# if there is no forward list, put this place there in order
		# to be able to reach that position too
		lappend TPEVAR(forward) [list $TPEVAR(currentFile) [$widget(src) index insert]]
	}
	set where [lindex $TPEVAR(history) end]
	set unmsg "La inceputul lui back\n\nHISTORY: $TPEVAR(history)\nNOW: $where\nFORWARD: $TPEVAR(forward)"
	lappend TPEVAR(forward) $where
	set TPEVAR(history) [lrange $TPEVAR(history) 0 end-1]
	set filename  [lindex $where 0]
	set insertpos [lindex $where 1]
	if {$filename != $TPEVAR(currentFile)} {
		project:select_file $filename
	}
	$widget(src) mark set insert $insertpos
	$widget(src) see $insertpos
	#showTrace "$unmsg\n\n\nLa finalul lui back\n\nHISTORY: $TPEVAR(history)\nNOW: $where\nFORWARD: $TPEVAR(forward)"
	#set TPEVAR(lastMessage) "B $TPEVAR(history) :  : $TPEVAR(forward)"
}

# Forward again in history
proc src:forwardHistory {} {
	global TPEVAR widget
	if {[llength $TPEVAR(forward)] == 0} {bell ; return}
	set where [lindex $TPEVAR(forward) end]
	set unmsg "La inceputul lui forward\n\nHISTORY: $TPEVAR(history)\nNOW: $where\nFORWARD: $TPEVAR(forward)"
	lappend TPEVAR(history) $where
	set TPEVAR(forward) [lrange $TPEVAR(forward) 0 end-1]
	if {[llength $TPEVAR(forward)] == 0} {return}
	set where [lindex $TPEVAR(forward) end]
	# If we are at the final position, we reset the forward list
	if {[llength $TPEVAR(forward)] == 1} {
		set TPEVAR(forward) {}
	}
	set filename  [lindex $where 0]
	set insertpos [lindex $where 1]
	if {$filename != $TPEVAR(currentFile)} {
		project:select_file $filename
	}
	$widget(src) mark set insert $insertpos
	$widget(src) see $insertpos
	#showTrace "$unmsg\n\n\nLa finalul lui forward\n\nHISTORY: $TPEVAR(history)\nNOW: $where\nFORWARD: $TPEVAR(forward)"
	#set TPEVAR(lastMessage) "F $TPEVAR(history) :  : $TPEVAR(forward)"
}

proc project:jumpToProcedureImplementation {} {
global TPEVAR widget

	$widget(src) tag delete showline

	# If no selection is made , ignore
	if {[catch {set seltext [$widget(src) get sel.first sel.last]}]} {
		return
	}

	# Extract the portion of text that might be a procedure
	if {![regexp {[A-Za-z\.:_]+} $seltext procname]} {
		return
	}

	# set the right pattern for procedure definition
	set procPattern "^\[ \t\]*proc\[ \t\]+\{$procname\}\[ \t\]+\{.*\}\[ \t\]*\{\[ \t\]*$|^\[ \t\]*proc\[ \t\]+$procname\[ \t\]+\{.*\}\[ \t\]*\{\[ \t\]*$"

	# first of all, try to find that procedure in the current edited file
	set i [$widget(src) search -forwards -regexp $procPattern 1.0 end]
	if {$i != ""} {
		src:addHistory
		$widget(src) see $i
		$widget(src) yview $i
		$widget(src) mark set insert $i
		$widget(src) tag add showline "$i linestart" "$i lineend"
		$widget(src) tag configure showline -background yellow
		return
	}		

	set found ""
	foreach fullfilename $TPEVAR(files) {
		set filename [file tail $fullfilename]

		# Do I have the source for that file in memory ?
		if {[info exists TPEVAR(source,$filename)]} {
			set source $TPEVAR(source,$filename)
			foreach line [split $source "\n"] {
				if {[regexp $procPattern $line]} {
					set found $filename
					break
				}
			}
		} else {
			# Load every line from file and search it
			if {![file exists $fullfilename]} {
				tk_messageBox -title Error -icon error -type ok -parent .mw -message "File '$filename' not found!\nIgnoring that file when searching for procedure '$procname'"
				break
			}
			set fid [open $fullfilename r]
			while {![eof $fid]} {
				set line [gets $fid]
				if {[regexp $procPattern $line]} {
					#showTrace "Found $procname into line $line"
					set found $filename
					break
				}
			}
			close $fid
		}
		# Break search if already found the file
		if {$found != ""} {
			break
		}
	}
	if {$found != ""} {
		src:addHistory
		project:select_file $found
		src:selectProcedureFromList $procname
		src:showProcedureBody
		set TPEVAR(lastMessage) "Procedure '$procname' found in file '$found'"
	} else {
		tk_messageBox -title Error -icon error -type ok -parent .mw -message "Procedure '$procname' not found in this project!"
		set TPEVAR(lastMessage) "Procedure '$procname' not found in current project!"
	}
}


proc project:new_file {} {
	global TPEVAR
	set types {
	    {{Tcl file}       {.tcl}        }
	}

	set fileName [tk_getSaveFile -defaultextension .tcl -filetypes $types -title "New file"]
	if {$fileName == ""} {
		return
	}
	# Save that file
	set fid [open $fileName w]
	puts $fid "# Created with Tcl Project Editor"
	close $fid
	project:addFileToProject $fileName
	project:select_file $fileName
	project:save
}


proc project:load_file {} {
global TPEVAR widget

	if {[$widget(files) curselection] == ""} {
		return
	}
	check_for_changed
	set filename [$widget(files) get [$widget(files) curselection]]
	set longfilename $TPEVAR(longname,$filename)

	$widget(src) delete 1.0 end

	# Checking if the source was edited and saved into TPEVAR array

	if {[info exists TPEVAR(source,$filename)]} {
		$widget(src) insert 1.0 $TPEVAR(source,$filename)
		$widget(src) mark set insert $TPEVAR(cursor,$filename)
		$widget(src) see $TPEVAR(cursor,$filename)
		$widget(currentFileLabel) configure -fg red
	} else {
		if {![file exists $longfilename]} {
			tk_messageBox -title Error -icon error -type ok -parent .mw -message "File '$longfilename' not found!"
			return
		}
		set fid [open $longfilename r]
		while {![eof $fid]} {
			set linie [gets $fid]
			$widget(src) insert end "$linie\n"
		}
		close $fid
		set TPEVAR(changed,$filename) 0
		$widget(currentFileLabel) configure -fg black
		$widget(src) mark set insert 1.0
	}
	$widget(src) clearundo

	update ; update idletasks

	# Provide procedure scanning and syntax highlighting just for .tcl files
	if {[string toupper [file extension $longfilename]]==".TCL"} {
		src:getCurrentFileProcedureList
		update ; update idletasks
		set TPEVAR(currentFileIsTclSource) 1
		src:syntax_highlight 1 end
	} else {
		set TPEVAR(currentFileIsTclSource) 0
		$widget(procs) delete 0 end
	}

	set TPEVAR(currentFile) $filename
}

proc project:showAddFileDialog {} {

	set types {
	    {{Tcl Scripts}      {.tcl}        }
	    {{All Files}          {.*}        }
	}

	set fileName [tk_getOpenFile -defaultextension .tpj -filetypes $types -title "Add file to project"]
	if {$fileName == ""} {
		return
	}

	project:addFileToProject $fileName
}

proc project:addFileToProject {fileName} {
	global TPEVAR widget

	lappend TPEVAR(files) $fileName

	set shortFileName [file tail $fileName]
	set TPEVAR(longname,$shortFileName) $fileName
	$widget(files) insert end $shortFileName
	# Parse and load procedure definitions from this file
	project:loadUserProceduresFromFile $fileName
}

proc project:exit {} {
	global TPEVAR widget

	project:save
	# save last project name, last opened file
	set fid [open "~/.tperc" w]
	puts $fid "set lastProjectName $TPEVAR(projname)"
	if {$TPEVAR(currentFile) != ""} {
		puts $fid "set currentFile $TPEVAR(currentFile)"
		puts $fid "set insertPlace [$widget(src) index insert]"
	}
	close $fid
	exit
}

proc project:load {projname} {
global TPEVAR widget

	$widget(files) delete 0 end
	$widget(procs) delete 0 end
	$widget(src) delete 1.0 end

	set TPEVAR(files) {}

	catch {source $projname}
	set TPEVAR(projname) $projname

	set projectNeedSave 0
	set newProjectList {}

	foreach filename [lsort $TPEVAR(files)] {
		if {![file exists $filename]} {
			tk_messageBox -title Error -message "File '$filename' not found!\n\nWe are removing it from project!"
			set projectNeedSave 1
			continue
		} else {
			lappend newProjectList $filename
		}
		set shortname [file tail $filename]
		$widget(files) insert end $shortname
		set TPEVAR(longname,$shortname) $filename
	}

	if {$projectNeedSave} {
		set TPEVAR(files) $newProjectList
		project:save
	} 

	set TPEVAR(currentFile) ""
	set TPEVAR(clipboard) ""

	wm title .mw "Tcl Project Editor - [string toupper [file tail $projname]]"


	# Saving preferences
	set fid [open "~/.tperc" w]
	puts $fid "set lastProjectName $projname"
	close $fid

	# Scanning project for procedure definitions
	project:loadUserProcedures
}


proc project:loadUserProceduresFromLine {line} {
global TPEVAR TCLPROCS

	# The regular expression to identify a proper line with procedure definition is:

	if {[regexp "^\[ \t\]*proc\[ \t\]+\{\[A-Za-z\.:_\]+\}\[ \t\]+\{.*\}\[ \t\]*\{\[ \t\]*$|^\[ \t\]*proc\[ \t\]+\[A-Za-z\.:_\]+\[ \t\]+\{.*\}\[ \t\]*\{\[ \t\]*$" $line]} {
		set line [string trim $line]
		set line [string range $line 0 [expr {[string length $line]-2}]]
		set errcode [catch {
			set procname [lindex $line 1]
			set args     [lindex $line 2]
		}]
		if {$errcode} {
			#set TPEVAR(lastMessage) "Bad line definition !"
		} else {
			set TCLPROCS($procname) "proc $procname \{$args\}"
			#set TPEVAR(lastMessage) "Procname=$procname    Args=$args"
		}
	}
}

proc project:unloadUserProceduresFromLine {line} {
global TCLPROCS
	if {[regexp "^\[ \t\]*proc\[ \t\]+\{\[A-Za-z\.:_\]+\}\[ \t\]+\{.*\}\[ \t\]*\{\[ \t\]*$|^\[ \t\]*proc\[ \t\]+\[A-Za-z\.:_\]+\[ \t\]+\{.*\}\[ \t\]*\{\[ \t\]*$" $line]} {
		set line [string trim $line]
		set line [string range $line 0 [expr {[string length $line]-2}]]
		set errcode [catch {
			set procname [lindex $line 1]
		}]
		if {! $errcode} {
			catch { unset TCLPROCS($procname) }
		}
	}
}

proc project:loadUserProceduresFromFile {fileName} {
	# Load every line from specified file and search for procedure definition
	if {![file exists $fileName]} {
		return
	}
	set fid [open $fileName r]
	while {![eof $fid]} {
		set line [gets $fid]
		project:loadUserProceduresFromLine $line
	}
	close $fid
}

proc project:unloadUserProceduresFromFile {fileName} {
	# Load every line from specified file and search for procedure definition
	if {![file exists $fileName]} {
		return
	}
	set fid [open $fileName r]
	while {![eof $fid]} {
		set line [gets $fid]
		project:unloadUserProceduresFromLine $line
	}
	close $fid
}


proc project:loadUserProcedures {} {
	global TPEVAR TCLPROCS

	# Delete all old procedure information
	foreach key [array names TCLPROCS] {
		catch {unset TCLPROCS($key)}
	}

	# Scan all files and load procedures
	foreach fileName $TPEVAR(files) {
		project:loadUserProceduresFromFile $fileName
	}

	# Now we are defining a couple of Tcl procedures with their syntax
	set TCLPROCS(regexp)   "regexp ?switches? exp string matchVar1 ?matchVar2? ..."
	set TCLPROCS(regsub)   "regsub ?switches? exp string subSpec varName\n Switches:\n   -nocase\n   -all"
	set TCLPROCS(lreplace) "lreplace list first last ?element element ...?"
	set TCLPROCS(lsearch)  "lsearch ?mode? list pattern\n Mode:\n    -exact\n    -glob\n    -regexp"
	set TCLPROCS(linsert)  "linsert list index element ?element element ...?"
	set TCLPROCS(lrange)   "lrange list first last"

	set TPEVAR(lastMessage) "[llength [array names TCLPROCS]] procedures found"
}

proc project:new {} {
global TPEVAR TCLPROCS widget


	set types {
	    {{Tcl project}       {.tpj}        }
	}

	set projname [tk_getSaveFile -defaultextension .tpj -filetypes $types -title "New project"]
	if {$projname == ""} {
		return
	}

	wm title .mw "Tcl Project - [string toupper $projname]"

	set TPEVAR(projname) $projname
	set TPEVAR(clipboard) ""
	set TPEVAR(files) ""
	set TPEVAR(currentFile) ""
	set TPEVAR(whatToFind) ""
	set TPEVAR(history) {}
	set TPEVAR(forward) {}

	$widget(files) delete 0 end
	$widget(procs) delete 0 end
	$widget(src) delete 1.0 end
	$widget(src) clearundo

	# forget any information about procedures defined in previous project
	foreach key [array names TCLPROCS] {
		catch { unset TCLPROCS($key) }
	}
}

proc project:open {} {
global TPEVAR widget

	set types {
 	   {{Tcl project}       {.tpj}        }
	    {{TCL Scripts}      {.tcl}        }
	}

	set projname [tk_getOpenFile -defaultextension .tpj -filetypes $types -title "Proiect Tcl"]
	if {$projname == ""} {
		return
	}

	project:load $projname
}

proc project:remove_file {} {
global TPEVAR widget

	set i [$widget(files) curselection]
	if {$i == ""} {
		bell
		return
	}
	set shortfilename [$widget(files) get $i]
	set filename ""

	foreach longfilename $TPEVAR(files) {
		if {[file tail $longfilename] == $shortfilename} {
			set filename $longfilename
			break
		}
	}

	if {$filename == ""} {
		return
	}
	if {[tk_messageBox -title Warning -icon warning -type yesno -parent .mw -message "Remove file '$filename' from project?"] == "no"} {
		return
	}

	set newlist {}
	foreach longfilename $TPEVAR(files) {
		if {$longfilename != $filename} {
			lappend newlist $longfilename
		}
	}
	set TPEVAR(files) $newlist
	project:save
	project:unloadUserProceduresFromFile $longfilename

	$widget(files) delete $i
	$widget(procs) delete 0 end
	$widget(src) delete 1.0 end
}

proc project:save {} {
global TPEVAR widget

	if {$TPEVAR(projname) == ""} {
		return
	}

	# save project
	set fid [open $TPEVAR(projname) w]
	puts $fid "set TPEVAR(files) \{$TPEVAR(files)\}"
	puts $fid "set TPEVAR(autoCompletion) $TPEVAR(autoCompletion)"
	puts $fid "set TPEVAR(procedureTip) $TPEVAR(procedureTip)"
	puts $fid "set TPEVAR(syntaxHighlight) $TPEVAR(syntaxHighlight)"
	close $fid

	# Here we should save all the files that have been changed

	check_for_changed

	foreach fullfilename $TPEVAR(files) {
		set filename [file tail $fullfilename]
		if {[info exists TPEVAR(changed,$filename)]} {
			if {$TPEVAR(changed,$filename)} {
				puts "Saving '$fullfilename' ..."
				# Now we will make a backup copy of that file before saving
				catch {file rename -force $fullfilename $fullfilename.bak}
				set fid [open $fullfilename w]
				puts $fid $TPEVAR(source,$filename)
				close $fid
				set TPEVAR(lastMessage) "File '$fullfilename' has been saved!"
				set TPEVAR(changed,$filename) 0
			}
		}
	}
}


proc project:select_file {fileName} {
global widget

	check_for_changed
	for {set i 0} {$i < [$widget(files) size]} {incr i} {
		if {[$widget(files) get $i] == [file tail $fileName]} {
			$widget(files) selection clear 0 end
			$widget(files) selection set $i
			$widget(files) see $i
			project:load_file
			break
		}
	}
}


proc src:copy {} {
global TPEVAR widget

	if {[catch {set what [$widget(src) get sel.first sel.last]}]} {
		return
	}

	set TPEVAR(clipboard) $what
}

proc src:cut {} {
global TPEVAR widget

	if {[catch {set what [$widget(src) get sel.first sel.last]}]} {
		return
	}

	set TPEVAR(clipboard) $what
	$widget(src) delete sel.first sel.last
	src:mark_changed
}

proc src:find {} {
global TPEVAR widget

	if {$TPEVAR(whatToFind) == ""} {
		return
	}

	if {$TPEVAR(searchAllFiles)} {
		if {![winfo exists .mw.cpd17.02.cpd23]} {
			frame .mw.cpd17.02.cpd23 \
				-borderwidth 1 -height 30 -relief raised -width 30 
			listbox .mw.cpd17.02.cpd23.01 \
				-font $::TPEVAR(font_normal)  \
				-xscrollcommand ".mw.cpd17.02.cpd23.02 set" \
				-yscrollcommand ".mw.cpd17.02.cpd23.03 set" 
			scrollbar .mw.cpd17.02.cpd23.02 \
				-command ".mw.cpd17.02.cpd23.01 xview" -orient horizontal 
			scrollbar .mw.cpd17.02.cpd23.03 \
				-command ".mw.cpd17.02.cpd23.01 yview" 
			pack .mw.cpd17.02.cpd23 \
				-in .mw.cpd17.02 -anchor center -expand 0 -fill x -side bottom 	
			grid columnconf .mw.cpd17.02.cpd23 0 -weight 1
			grid rowconf .mw.cpd17.02.cpd23 0 -weight 1
			grid .mw.cpd17.02.cpd23.01 \
				-in .mw.cpd17.02.cpd23 -column 0 -row 0 -columnspan 1 -rowspan 1 -sticky nesw 
			grid .mw.cpd17.02.cpd23.02 \
				-in .mw.cpd17.02.cpd23 -column 0 -row 1 -columnspan 1 -rowspan 1 -sticky ew 
			grid .mw.cpd17.02.cpd23.03 \
				-in .mw.cpd17.02.cpd23 -column 1 -row 0 -columnspan 1 -rowspan 1 -sticky ns
			bind .mw.cpd17.02.cpd23.01 <Double-Button-1> {src:loadAndJumpLine}
		}
		src:findAllFiles
		return
	}

	# Now we are searching into the source that is displayed
	if {$TPEVAR(findRegexp)} {
		set i [$widget(src) search -forwards -regexp -nocase -- $TPEVAR(whatToFind) 1.0 end]
	} else {
		set i [$widget(src) search -forwards -nocase -- $TPEVAR(whatToFind) 1.0 end]
	}

	if {$i != ""} {
		src:addHistory
		$widget(src) see $i
		$widget(src) yview $i
		$widget(src) mark set insert $i
		focus $widget(src)
		Window hide .find
	} else {
		bell
	}
}

proc src:findAllFiles {} {
	global TPEVAR widget
	
	$widget(grep) delete 0 end
	set pattern $TPEVAR(whatToFind)
	set howmany 0
	cursor wait

	# Check and save in memory the current edited file
	check_for_changed 

	foreach fullfilename [lsort $TPEVAR(files)] {
		set filename [file tail $fullfilename]

		# Do I have the source for that file in memory ?
		if {[info exists TPEVAR(source,$filename)]} {
			set source $TPEVAR(source,$filename)
			set lineno 0
			foreach line [split $source "\n"] {
				incr lineno
				if {[regexp -- "$pattern" $line]} {
					regsub -all "\t" $line "    " dline
					$widget(grep) insert end "$filename $lineno $dline"
					incr howmany
				}
			}
		} else {
			# Load every line from file and search it
			if {![file exists $fullfilename]} {
				tk_messageBox -title Error -icon error -type ok -parent .mw -message "File '$filename' not found!\nIgnoring that file when searching for '$pattern'"
				break
			}
			set fid [open $fullfilename r]
			set lineno 0
			while {![eof $fid]} {
				set line [gets $fid]
				incr lineno
				if {[regexp -- "$pattern" $line]} {
					regsub -all "\t" $line "    " dline
					$widget(grep) insert end "$filename $lineno $dline"
					incr howmany
				}
			}
			close $fid
		}
	}
	if {$howmany > 0} {
		Window hide .find
	} else {
		bell
	}
	cursor normal
}

proc src:findNext {} {
global TPEVAR widget

	if {$TPEVAR(whatToFind) == ""} {
		return
	}

	set i [$widget(src) search -forwards -nocase $TPEVAR(whatToFind) "insert + 1 char" end]

	if {$i != ""} {
		src:addHistory
		$widget(src) see $i
		$widget(src) yview $i
		$widget(src) mark set insert $i
		focus $widget(src)
		Window hide .find
	} else {
		bell
	}
}

proc src:getCurrentFileProcedureList {} {
global TPEVAR widget

	set unde "1.0"
	$widget(procs) delete 0 end

	set proclist {}
	set procPattern "^\[ \t\]*proc\[ \t\]+\{\[A-Za-z\.:_\]+\}\[ \t\]+\{.*\}\[ \t\]*\{\[ \t\]*$|^\[ \t\]*proc\[ \t\]+\[A-Za-z\.:_\]+\[ \t\]+\{.*\}\[ \t\]*\{\[ \t\]*$"
	while {$unde != ""} {
		set unde [$widget(src) search -forwards -regexp $procPattern "$unde + 1 chars" end]
	   if {$unde != ""} {
			set procline "[string trim [$widget(src) get "$unde linestart" "$unde lineend"]] \}"
			set args [string trim [lindex $procline 2]]
			regsub -all "\t" $args " " args
			lappend proclist "[lindex $procline 1] \{$args\}"
	   }
	}

	foreach procname [lsort $proclist] {
 	  $widget(procs) insert end $procname
	}
}


proc src:goToLine {} {
global TPEVAR widget

	if {$TPEVAR(lineToGo) == ""} {
		return
	}
	set i $TPEVAR(lineToGo).0
	src:addHistory
	catch {
		$widget(src) see $i
		$widget(src) yview $i
		$widget(src) mark set insert $i
	}
	focus $widget(src)
	Window hide .goto
}

proc src:paste {} {
global TPEVAR widget
	set filename $TPEVAR(currentFile)
	if {$filename == ""} {
		return
	}
	#puts "pasting from clipboard: $TPEVAR(clipboard)"
	$widget(src) insert insert $TPEVAR(clipboard)
	src:mark_changed
}

proc src:replace {} {
global TPEVAR widget

	if {$TPEVAR(whatToFind) == ""} {
		Window hide .replace
		return
	}

	set i 1.0
	set replacements 0

	while {$i != ""} {
		set i [$widget(src) search -forwards -nocase $TPEVAR(whatToFind) "$i" end]
		if {$i != ""} {
			$widget(src) delete $i "$i + [string length $TPEVAR(whatToFind)] chars"
			$widget(src) insert $i $TPEVAR(replaceWith)
			incr replacements
			set lastPlace $i
			set i "$i + [string length $TPEVAR(replaceWith)] chars"
		}
	}

	if {$replacements == 0} {
		# no replacements were made
		set TPEVAR(lastMessage) "String '$TPEVAR(whatToFind)' not found! No replacements were made!"
		bell
	} else {
		# go to the last replacement place
		$widget(src) see $lastPlace
		$widget(src) yview $lastPlace
		$widget(src) mark set insert $lastPlace
		focus $widget(src)
		Window hide .replace
		set TPEVAR(lastMessage) "'$TPEVAR(whatToFind)' replaced with '$TPEVAR(replaceWith)' $replacements times"
	}
}

proc src:showFindDialog {} {
	Window show .find
	wm transient .find .mw
	.find.e1 selection range 0 end
	focus .find.e1
}

proc src:showReplaceDialog {} {
	Window show .replace
	wm transient .replace .mw
	.replace.e1 selection range 0 end
	focus .replace.e1
}

proc src:syntax_highlight {start_line end_line} {
global widget syntax TPEVAR

	if {! $TPEVAR(syntaxHighlight)} {return}
	if {! $TPEVAR(currentFileIsTclSource)} {return} 
	
	set t $widget(src)
	set editor_no 0

	$t tag configure command -foreground blue
	$t tag configure number -foreground DarkGreen
	$t tag configure proc -foreground blue
	$t tag configure comment -foreground green4
	$t tag configure variable -foreground red
	$t tag configure string -foreground purple

	if {$end_line == "end"} {
		set end $end_line
	} else {
		set end $end_line.end
	}

	# remove all existing tags from the text (excluding the proc tag)
	foreach tag {command comment string number variable} {
		$t tag remove $tag $start_line.0 $end
	}

	set line_no $start_line
	set next_no [expr {$start_line + 1}]

	while {[set line [$t get $line_no.0 $next_no.0]] != "" && $line_no <= $end_line} {
		# replace all tabs with spaces for consistency/simpler comparisons
		regsub -all "\t" $line " " line

		set trimmed [string trim $line]
		set we [string wordend $trimmed 0]
		set first_word [string range $trimmed 0 [expr {$we - 1}]]

		if {[string range $trimmed 0 0] == "#"} {
			# comment line, simply colour the whole line
			$t tag add comment $line_no.0 $line_no.end
		} elseif {$first_word == "proc"} {
			# proc statement, colour the whole line
			set end [string first " " $trimmed [expr {$we + 1}]]
			if {$end == -1} {
				# provide some extra handling for procedure names ending with semi-colon
				# this to support some other languages besides tcl
				set end [string first ";" $trimmed [expr {$we + 1}]]
			}
		} else {
			# general line, review all words within the line and colourise appropriately
			set startx 0
			set word ""
			set length [string length $line]
			set quote 0

			for {set x 0} {$x < $length} {incr x} {
				set c [string range $line $x $x]
				if {$quote != 0} {
					if {$c == $quote} {
						src:tagWord $editor_no $word $t $line_no $startx [expr {$x + 1}] "string"
						set quote 0
						set word ""
					}
				} elseif {[string first $c "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.$:"] != -1} {
					if {$word == ""} { set startx $x }
					append word $c
				} elseif {$word != ""} {
					src:tagWord $editor_no $word $t $line_no $startx $x
					set word ""
				} elseif {$c == "\"" || $c == "'"} {
					set startx $x
					set quote $c
				}
				if {$c == "\\"} { incr x }
			}
			if {$word != ""} {
				src:tagWord $editor_no $word $t $line_no $startx $x
			}
		}
		incr line_no
		incr next_no
	}
}

proc src:mark_changed {} {
global TPEVAR widget

	set filename $TPEVAR(currentFile)
	if {$filename == ""} {
		return
	}
	if {$TPEVAR(changed,$filename)} {
		return
	}
	set TPEVAR(changed,$filename) 1
	$widget(currentFileLabel) configure -fg red
}

proc src:checkForProcedureDefinition {} {
	global TPEVAR widget

	if {! $TPEVAR(currentFileIsTclSource)} {return} 

	# Check for procedure definition into the current line
	# and if there is one, define it
	set here [$widget(src) index insert]
	project:loadUserProceduresFromLine [$widget(src) get "$here linestart" "$here lineend"]
}

proc src:updated {kc kn ka} {
global TPEVAR widget

	#set TPEVAR(lastMessage) "KC=>$kc<        KN=>$kn<       KA=>$ka<"
	src:hideProcedureTip
	$widget(src) tag delete showline

	# Are we editing a real file ?
	set filename $TPEVAR(currentFile)
	if {$filename == ""} {
		return 0
	}

	# If there is a movement key, update the procedure list definition
	if {[lsearch {Up Down Return Next Prior} $kn] != -1} {
		src:checkForProcedureDefinition
	}
	# Was a Delete key or a printable one ?
	if {($kn == "Delete") || ($ka != "")} {
		src:mark_changed
		# Forget the procedure definition (if any) from this line
		set here [$widget(src) index insert]

		if {$TPEVAR(currentFileIsTclSource)} {
			project:unloadUserProceduresFromLine [$widget(src) get "$here linestart" "$here lineend"]
		} 

		if {$kn == "Delete"} {src:removeProcedureDefinitionsFromBlock}
		if {$ka == " "} {src:autoCompletion}
		if {$ka == "#"} {src:checkBlockComment}
		if {$kn == "Tab"} {src:checkBlockIdent}
		if {$kn == "Tab"} {src:checkProcedureNameCompletion}

		set linie    [lindex [split $here "."] 1]
		set endLinie [lindex [split [$widget(src) index "$here lineend"] "."] 1]

		if {($TPEVAR(overwrite)) &&  $linie < $endLinie} {
			$widget(src) delete $here $here+1char
		}

		return 1
	}
	#showTrace "kn=$kn , kc=$kc , ka=$ka"
	return 0
}



proc src:checkBlockComment {} {
	global TPEVAR widget
	set selstart ""
	catch {
		set selstart [$widget(src) index sel.first]
		set selstop  [$widget(src) index sel.last]
	}
	if {$selstart == ""} {return}
	# See if selection is applied to multiple lines
	set linestart [lindex [split $selstart .] 0]
	set linestop  [lindex [split $selstop .] 0]
	if {$linestart == $linestop} {return}
	incr linestop
	for {set i $linestart} {$i<$linestop} {incr i} {
		$widget(src) insert $i.0 "#"
		src:highlightSingleLine $i
	}
	set TPEVAR(doNotInsertCharacter) 1
}

proc src:removeProcedureDefinitionsFromBlock {} {
	global widget
	set selstart ""
	catch {
		set selstart [$widget(src) index sel.first]
		set selstop  [$widget(src) index sel.last]
	}
	if {$selstart == ""} {return}
	# See if selection is applied to multiple lines
	set linestart [lindex [split $selstart .] 0]
	set linestop  [lindex [split $selstop .] 0]
	if {$linestart == $linestop} {return}
	incr linestop
	for {set i $linestart} {$i<$linestop} {incr i} {
		project:unloadUserProceduresFromLine [$widget(src) get "$i.0" "$i.0 lineend"]
	}
}

proc src:checkBlockIdent {} {
	global TPEVAR widget
	set selstart ""
	catch {
		set selstart [$widget(src) index sel.first]
		set selstop  [$widget(src) index sel.last]
	}
	if {$selstart == ""} {return}
	# See if selection is applied to multiple lines
	set linestart [lindex [split $selstart .] 0]
	set linestop  [lindex [split $selstop .] 0]
	if {$linestart == $linestop} {return}
	incr linestop
	for {set i $linestart} {$i<$linestop} {incr i} {
		# Do not ident empty lines
		set line [$widget(src) get $i.0 "$i.0 lineend"]
		if {[string trim $line] == ""} {continue}
		$widget(src) insert $i.0 "\t"
	}
	set TPEVAR(doNotInsertCharacter) 1
}

proc src:checkBlockUnident {} {
	global TPEVAR widget
	set TPEVAR(doNotInsertCharacter) 1
	set selstart ""
	catch {
		set selstart [$widget(src) index sel.first]
		set selstop  [$widget(src) index sel.last]
	}
	if {$selstart == ""} {return}
	# See if selection is applied to multiple lines
	set linestart [lindex [split $selstart .] 0]
	set linestop  [lindex [split $selstop .] 0]
	if {$linestart == $linestop} {return}
	incr linestop
	# Are there enough tab characters on all lines ?
	for {set i $linestart} {$i<$linestop} {incr i} {
		# Do not check empty lines
		set line [$widget(src) get $i.0 "$i.0 lineend"]
		if {[string trim $line] == ""} {continue}
		# Now check if there is a tab there
		if {[$widget(src) get $i.0] != "\t"} {
			return
		}
	}
	for {set i $linestart} {$i<$linestop} {incr i} {
		set line [$widget(src) get $i.0 "$i.0 lineend"]
		if {[string trim $line] == ""} {continue}
		$widget(src) delete $i.0
	}
}


proc src:getHelpOnFunction {functionName} {
	global TCLPROCS
	if {[info exists TCLPROCS($functionName)]} {
		return $TCLPROCS($functionName)
	}
	return ""
}


proc src:showProcedureTip {helpText {delay 4000}} {
	global TPEVAR widget
	set coord [$widget(src) bbox insert]
	if {$coord != ""} {
		foreach {x y w h} $coord {break}
		set x [expr {$x+10+[winfo x $widget(src)]+[winfo x $widget(srcParent)]}]
		set y [expr {$y+$h+10+[winfo y $widget(src)]+[winfo y $widget(srcParent)]}]
		label .mw.proctip -text $helpText -foreground blue -background yellow -anchor w -justify left
		place .mw.proctip -x $x -y $y
		set TPEVAR(procTipAfterId) [after $delay "catch {destroy .mw.proctip}"]
	}
}

proc src:showProcedureBody {} {
global TPEVAR widget

	$widget(src) tag delete showline
	if {[$widget(procs) curselection] == ""} {
		return
	}

	src:addHistory
	set procname [lindex [$widget(procs) get [$widget(procs) curselection]] 0]

	# set the right pattern for procedure definition
	set procPattern "^\[ \t\]*proc\[ \t\]+\{$procname\}\[ \t\]+\{.*\}\[ \t\]*\{\[ \t\]*$|^\[ \t\]*proc\[ \t\]+$procname\[ \t\]+\{.*\}\[ \t\]*\{\[ \t\]*$"

	set i [$widget(src) search -forwards -regexp $procPattern 1.0 end]

	if {$i != ""} {
		$widget(src) see $i
		$widget(src) yview $i
		$widget(src) mark set insert "$i lineend"
		$widget(src) tag add showline "$i linestart" "$i lineend"
		$widget(src) tag configure showline -background yellow
		focus $widget(src)
	}
}

proc src:hideProcedureTip {} {
	global TPEVAR
	catch { after cancel $TPEVAR(procTipAfterId) }
	catch { destroy .mw.proctip }
}

proc src:checkProcedureNameCompletion {} {
	global TPEVAR TCLPROCS widget
	set where [$widget(src) index insert]
	set frontline [$widget(src) get "$where linestart" $where]
	if {[regexp {[A-Za-z:_0-9]+$} $frontline procname]} {
		set TPEVAR(lastMessage) "Searching for '$procname*'"
		set proclist [array names TCLPROCS $procname*]
		# If there isn't such a procedure, just beep
		if {[llength $proclist] == 0} {
			bell
			set TPEVAR(doNotInsertCharacter) 1
			return
		}
		# Is there only one procedure that match text ?
		if {[llength $proclist] == 1} {
			set fullProcName [lindex $proclist 0]
			$widget(src) insert insert "[string range $fullProcName [string length $procname] end] "
			# Now let's show him how to put the arguments
			set helpText [src:getHelpOnFunction $fullProcName]
			src:showProcedureTip $helpText 4000
			set TPEVAR(doNotInsertCharacter) 1
			return
		}
		set helpText ""
		foreach procname [lsort $proclist] {
			append helpText "$TCLPROCS($procname)\n"
		}
		src:showProcedureTip $helpText 6000
		set TPEVAR(doNotInsertCharacter) 1
	}
}



proc src:autoCompletion {} {
	global TPEVAR widget
	if {! $TPEVAR(currentFileIsTclSource)} {
		return
	} 
	set where [$widget(src) index insert]
	set endofline [$widget(src) index "insert lineend"]
	set restofline [$widget(src) get $where "$where lineend"]
	set frontline [$widget(src) get "$where linestart" $where]

	# Check for user defined functions if procedureTip feature is set

	if {$TPEVAR(procedureTip)} {
		set procname "unknown"
		if {[regexp {[A-Za-z:_0-9]+$} $frontline procname]} {
			#set procname [string range $frontline [expr {[string last "\[" $frontline]+1}] end]
			set TPEVAR(lastMessage) "Search definition for >$procname<"
			set helpText [src:getHelpOnFunction $procname]
			if {$helpText != ""} {
				src:showProcedureTip $helpText
				return
			}
		}
	}	

	# Continue only if autoCompleton feature is set
	if {! $TPEVAR(autoCompletion)} {
		return
	}

	# Accept space just at the end of line
	if {$where != $endofline} {
		# There are other characters till the end of line ?
		if {![regexp "^\[ \t\]*$" $restofline]} {
			# Cannot do auto-completion
			return
		}
		# Delete the unused white space till the end of line
		$widget(src) delete $where "$where lineend"
	}
	set lineno [lindex [split $where .] 0]
	set line [$widget(src) get $lineno.0 $lineno.end]
	if {[regexp "^\[ \t\]*foreach$" $line]} {
		regexp "^\[ \t\]*f" $line match
		set ident [string range $match 0 [expr {[string length $match]-2}]]
		$widget(src) insert insert "  {\n$ident\t\n$ident}"
		$widget(src) mark set insert "$where + 1 chars"
		set TPEVAR(doNotInsertCharacter) 1
		return
	}
	if {[regexp "^\[ \t\]*switch$" $line]} {
		regexp "^\[ \t\]*s" $line match
		set ident [string range $match 0 [expr {[string length $match]-2}]]
		$widget(src) insert insert "  {\n$ident\t\"\" \{\n$ident\t\t\n$ident\t\}\n$ident\t\"\" \{\n$ident\t\t\n$ident\t\}\n$ident}"
		$widget(src) mark set insert "$where + 1 chars"
		set TPEVAR(doNotInsertCharacter) 1
		return
	}
	if {[regexp "^\[ \t\]*for$" $line ident]} {
		$widget(src) insert insert " {} {} {} {\n[string range $ident 0 [expr {[string length $ident]-4}]]}"
		$widget(src) mark set insert "$where + 2 chars"
		set TPEVAR(doNotInsertCharacter) 1
		return
	}
	if {[regexp "^\[ \t\]*if$" $line match]} {
		set ident [string range $match 0 [expr {[string length $match]-3}]]
		$widget(src) insert insert " {} {\n$ident\t\n$ident} "
		$widget(src) mark set insert "$where + 2 chars"
		set TPEVAR(doNotInsertCharacter) 1
		return
	}
	if {[regexp "^\[ \t\]*\}\[ \t\]*elseif$" $line]} {
		regexp "^\[ \t\]*\}" $line match
		set ident [string range $match 0 [expr {[string length $match]-2}]]
		$widget(src) insert insert " {} \{\n$ident\t\n$ident\} "
		$widget(src) mark set insert "$where + 2 chars"
		set TPEVAR(doNotInsertCharacter) 1
		return
	}
	if {[regexp "^\[ \t\]*\}\[ \t\]*else$" $line]} {
		regexp "^\[ \t\]*\}" $line match
		set ident [string range $match 0 [expr {[string length $match]-2}]]
		$widget(src) insert insert " \{\n$ident\t\n$ident\}"
		$widget(src) mark set insert "$where + 1 lines"
		set TPEVAR(doNotInsertCharacter) 1
		return
	}
	if {[regexp "^\[ \t\]*proc$" $line ident]} {
		$widget(src) insert insert "  {} {\n[string range $ident 0 [expr {[string length $ident]-5}]]}"
		$widget(src) mark set insert "$where + 1 chars"
		set TPEVAR(doNotInsertCharacter) 1
		return
	}
	if {[regexp "^\[ \t\]*while$" $line]} {
		regexp "^\[ \t\]*w" $line match
		set ident [string range $match 0 [expr {[string length $match]-2}]]
		$widget(src) insert insert " {} {\n$ident\t\n$ident}"
		$widget(src) mark set insert "$where + 2 chars"
		set TPEVAR(doNotInsertCharacter) 1
		return
	}
}

#  Do syntax highlight for the specified line or, if not specified, to the current insert line
proc src:highlightSingleLine {{line ""}} {
	global TPEVAR widget
	if {$line == ""} {
		set where [$widget(src) index insert]
		set line [lindex [split $where .] 0]
	}
	src:syntax_highlight $line $line
}

proc src:selectProcedureFromList {procname} {
global  widget
	for {set i 0} {$i < [$widget(procs) size]} {incr i} {
		if {[regexp "\{?$procname" [$widget(procs) get $i]]} {
			$widget(procs) selection clear 0 end
			$widget(procs) selection set $i
			$widget(procs) see $i
			break
		}
	}
}


proc src:tagWord {editor_no word t line_no startx x {tag_name {}}} {
	global syntax

	set ext .tcl

	if {$tag_name != ""} {
		$t tag add $tag_name $line_no.$startx $line_no.$x
	} elseif {[array names syntax $ext,$word] != ""} {
		$t tag add command $line_no.$startx $line_no.$x
	} elseif {[string is double -strict $word]} {
		$t tag add number $line_no.$startx $line_no.$x
	} elseif {[string range $word 0 0] == "$"} {
		$t tag add variable $line_no.$startx $line_no.$x
	}
}


proc src:markWord {x y} {
	global widget
	set here [$widget(src) index @$x,$y]
	set word [$widget(src) get "$here wordstart" "$here wordend"]
}

proc showTrace {{userMsg ""}} {
	set procTrace ""
	for {set i 1} {$i < [info level]} {incr i} {
		append procTrace "[info level $i]\n"
	}

	tk_messageBox -title "Procedure stack" -message "$userMsg\n\nCall stack:\n$procTrace"
}


# Show/hide the watch pointer in order to show activities
proc cursor {cum} {

	if {$cum == "wait"} {
		set forma watch
	} else {
		set forma left_ptr
	}

	foreach wname [winfo children .] {
		catch {$wname configure -cursor $forma}
	}

	update
	update idletasks
}


proc main {argc argv} {
	global widget

	# Autoload the last opened project
	update
	update idletasks
	if {[file exists "~/.tperc"]} {
		set lastProjectName ""
		set currentFile ""
		set insertPlace ""
	   catch {source "~/.tperc"}
	   if {$lastProjectName != ""} {
	      project:load $lastProjectName
	   }
		if {$currentFile != ""} {
			project:select_file $currentFile
			catch {
				$widget(src) see $insertPlace
				$widget(src) mark set insert $insertPlace
				focus $widget(src)
			}
		}
	}
}

proc Window {args} {
global vTcl
    set cmd [lindex $args 0]
    set name [lindex $args 1]
    set newname [lindex $args 2]
    set rest [lrange $args 3 end]
    if {$name == "" || $cmd == ""} {return}
    if {$newname == ""} {
        set newname $name
    }
    set exists [winfo exists $newname]
    switch $cmd {
        show {
            if {$exists == "1" && $name != "."} {wm deiconify $name; return}
            if {[info procs vTclWindow(pre)$name] != ""} {
                eval "vTclWindow(pre)$name $newname $rest"
            }
            if {[info procs vTclWindow$name] != ""} {
                eval "vTclWindow$name $newname $rest"
            }
            if {[info procs vTclWindow(post)$name] != ""} {
                eval "vTclWindow(post)$name $newname $rest"
            }
        }
        hide    { if $exists {wm withdraw $newname; return} }
        iconify { if $exists {wm iconify $newname; return} }
        destroy { if $exists {destroy $newname; return} }
    }
}

#################################
# VTCL GENERATED GUI PROCEDURES
#

proc vTclWindow. {base} {
	if {$base == ""} {
		set base .
	}
	###################
	# CREATING WIDGETS
	###################
	wm focusmodel $base passive
	wm geometry $base 1x1+0+0
	wm maxsize $base 1137 834
	wm minsize $base 1 1
	wm overrideredirect $base 0
	wm resizable $base 1 1
	wm withdraw $base
	wm title $base "vt.tcl"
	###################
	# SETTING GEOMETRY
	###################
}

proc vTclWindow.find {base} {
	if {$base == ""} {
		set base .find
	}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	###################
	# CREATING WIDGETS
	###################
	toplevel $base -class Toplevel  -background #dcdcdc -highlightbackground #dcdcdc  -highlightcolor #000000 
	wm focusmodel $base passive
	wm geometry $base 232x138+418+348
	wm maxsize $base 1137 834
	wm minsize $base 1 1
	wm overrideredirect $base 0
	wm resizable $base 0 0
	wm title $base "Find"
	bind $base <Key-Escape> {
		Window hide .find
		catch {destroy .mw.cpd17.02.cpd23}
    }
	label $base.l1    -background #dcdcdc -borderwidth 1 -font $::TPEVAR(font_normal)  -foreground #000000 -highlightbackground #dcdcdc  -highlightcolor #000000 -text Find 
	entry $base.e1  -background #ffffff -borderwidth 1 -foreground #000000  -highlightbackground #ffffff -highlightcolor #000000  -selectbackground #0a5f89 -selectforeground #ffffff  -textvariable TPEVAR(whatToFind) 
	bind $base.e1 <Key-KP_Enter> {
		src:find
    }
	bind $base.e1 <Key-Return> {
		src:find
    }
	checkbutton $base.cbregexp -background #dcdcdc -font $::TPEVAR(font_normal) -text "Regular expression" -variable TPEVAR(findRegexp)
	checkbutton $base.cballfiles -background #dcdcdc -font $::TPEVAR(font_normal) -text "Search in all files" -variable TPEVAR(searchAllFiles)
	button $base.okbtn -background #dcdcdc -borderwidth 1 -command src:find  -font $::TPEVAR(font_normal) -foreground #000000  -highlightbackground #dcdcdc -highlightcolor #000000 -text OK 
	button $base.btncancel -background #dcdcdc -borderwidth 1 -command {Window hide .find ; catch {destroy .mw.cpd17.02.cpd23}}  -font $::TPEVAR(font_normal) -foreground #000000  -highlightbackground #dcdcdc -highlightcolor #000000 -text Cancel 
	###################
	# SETTING GEOMETRY
	###################
	place $base.l1  -x 20 -y 24 -width 29 -height 18 -anchor nw -bordermode ignore 
	place $base.e1  -x 61 -y 23 -width 146 -height 20 -anchor nw -bordermode ignore 
	place $base.cbregexp -x 40 -y 50
	place $base.cballfiles -x 40 -y 70
	place $base.okbtn  -x 25 -y 105 -width 80 -height 24 -anchor nw -bordermode ignore 
	place $base.btncancel  -x 115 -y 105 -width 77 -height 24 -anchor nw -bordermode ignore
}

proc vTclWindow.goto {base} {
	if {$base == ""} {
		set base .goto
	}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	###################
	# CREATING WIDGETS
	###################
	toplevel $base -class Toplevel  -background #dcdcdc -highlightbackground #dcdcdc  -highlightcolor #000000 
	wm focusmodel $base passive
	wm geometry $base 232x98+418+348
	wm maxsize $base 1137 834
	wm minsize $base 1 1
	wm overrideredirect $base 0
	wm resizable $base 0 0
	wm title $base "Goto line"
	bind $base <Key-Escape> {
		Window hide .goto
    }
	label $base.l1    -background #dcdcdc -borderwidth 1 -font $::TPEVAR(font_normal)  -foreground #000000 -highlightbackground #dcdcdc  -highlightcolor #000000 -text Find 
	entry $base.e1  -background #ffffff -borderwidth 1 -foreground #000000  -highlightbackground #ffffff -highlightcolor #000000  -selectbackground #0a5f89 -selectforeground #ffffff  -textvariable TPEVAR(lineToGo) 
	bind $base.e1 <Key-KP_Enter> {
		src:goToLine
    }
	bind $base.e1 <Key-Return> {
		src:goToLine
    }
	button $base.okbtn    -background #dcdcdc -borderwidth 1 -command src:goToLine  -font $::TPEVAR(font_normal) -foreground #000000  -highlightbackground #dcdcdc -highlightcolor #000000 -text OK 
	button $base.btncancel    -background #dcdcdc -borderwidth 1 -command {Window hide .goto}  -font $::TPEVAR(font_normal) -foreground #000000  -highlightbackground #dcdcdc -highlightcolor #000000 -text Cancel 
	###################
	# SETTING GEOMETRY
	###################
	place $base.l1  -x 20 -y 24 -width 29 -height 18 -anchor nw -bordermode ignore 
	place $base.e1  -x 61 -y 23 -width 146 -height 20 -anchor nw -bordermode ignore 
	place $base.okbtn  -x 25 -y 65 -width 80 -height 24 -anchor nw -bordermode ignore 
	place $base.btncancel  -x 115 -y 65 -width 77 -height 24 -anchor nw -bordermode ignore
}

proc vTclWindow.mw {base} {
	if {$base == ""} {
		set base .mw
	}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	###################
	# CREATING WIDGETS
	###################
	toplevel $base -class Toplevel \
        -background #dcdcdc -highlightbackground #dcdcdc \
        -highlightcolor #000000 
	wm focusmodel $base passive
	wm geometry $base 853x630+126+118
	wm maxsize $base 1280 1024
	wm minsize $base 1 1
	wm overrideredirect $base 0
	wm resizable $base 1 1
	wm deiconify $base
	wm title $base "Tcl Project"
	wm protocol $base WM_DELETE_WINDOW {
		project:exit
	}
	bind $base <Key-Control_L>f {
		src:showFindDialog
	}
	bind $base <Key-Control_L>g {
		Window show .goto
		focus .goto.e1
	}
	bind $base <Key-Control_L>r {
		src:showReplaceDialog
	}
	bind $base <Key-Control_L>s {
		project:save
	}
	bind $base <Key-Control_L>n {
		project:new_file
	}
	bind $base <Key-Alt_L>x {
		project:exit
	}
	bind $base <Key-F11> {
		src:backHistory
		break
	}
	bind $base <Key-F12> {
		src:forwardHistory
		break
	}
	#bind $base <Key-F10> {
	#	$::widget(src) showundo
	#	break
	#}

	frame $base.fm \
        -background #dcdcdc -borderwidth 2 -height 26 \
        -highlightbackground #dcdcdc -highlightcolor #000000 -relief groove \
        -width 125 
	menubutton $base.fm.mfiles \
        -background #dcdcdc -font $::TPEVAR(font_normal) -foreground #000000 \
        -highlightbackground #dcdcdc -highlightcolor #000000 \
        -menu .mw.fm.mfiles.m -padx 4 -pady 3 -text Files 
	menu $base.fm.mfiles.m \
        -background #dcdcdc -cursor {} -font $::TPEVAR(font_normal) \
        -foreground #000000 -tearoff 0 
	$base.fm.mfiles.m add command \
        -command project:new -label {New project} 
	$base.fm.mfiles.m add command \
        -command project:open -label {Open project} 
	$base.fm.mfiles.m add command \
        -command project:showAddFileDialog -label {Add file to project} 
	$base.fm.mfiles.m add command \
        -accelerator Ctrl/N -command project:new_file -label {Create new file} 
	$base.fm.mfiles.m add command \
        -command project:remove_file -label {Remove file from project} 
	$base.fm.mfiles.m add command \
        -accelerator Ctrl/S -command project:save -label {Save all} 
	$base.fm.mfiles.m add separator
	$base.fm.mfiles.m add command \
        -accelerator Alt/X -command project:exit -label Exit 
	menubutton $base.fm.medit \
        -background #dcdcdc -font $::TPEVAR(font_normal) -foreground #000000 \
        -highlightbackground #dcdcdc -highlightcolor #000000 \
        -menu .mw.fm.medit.m -padx 4 -pady 3 -text Edit 
	menu $base.fm.medit.m \
        -background #dcdcdc -cursor {} -font $::TPEVAR(font_normal) \
        -foreground #000000 -tearoff 0 
	$base.fm.medit.m add command \
        -accelerator Ctrl/Z -command "$::widget(src) undo" -label Undo
	$base.fm.medit.m add separator
	$base.fm.medit.m add command \
        -accelerator Ctrl/C -command src:copy -label Copy 
	$base.fm.medit.m add command \
        -accelerator Ctrl/X -command src:cut -label Cut 
	$base.fm.medit.m add command \
        -accelerator Ctrl/V -command src:paste -label Paste 
	$base.fm.medit.m add separator
	$base.fm.medit.m add command \
        -accelerator Ctrl/F -command src:showFindDialog -label Find 
	$base.fm.medit.m add command \
        -accelerator F3 -command src:findNext -label {Find next} 
	$base.fm.medit.m add command \
        -accelerator Ctrl/R -command src:showReplaceDialog -label Replace 
	$base.fm.medit.m add command \
        -accelerator Ctrl/G -command {Window show .goto ; focus .goto.e1} \
        -label {Go to line} 
	$base.fm.medit.m add separator
	$base.fm.medit.m add command \
        -accelerator F11 -command "src:backHistory" \
        -label {Navigation back} 
	$base.fm.medit.m add command \
        -accelerator F12 -command "src:forwardHistory" \
        -label {Navigation forward} 
	$base.fm.medit.m add separator
	$base.fm.medit.m add command \
        -accelerator "#" -command "src:checkBlockComment" \
		-label "Comment entire block"
	menubutton $base.fm.mtools \
         \
        -background #dcdcdc -font $::TPEVAR(font_normal) -foreground #000000 \
        -highlightbackground #dcdcdc -highlightcolor #000000 \
        -menu .mw.fm.mtools.m -padx 4 -pady 3 -text Tools 
	menu $base.fm.mtools.m \
         \
        -background #dcdcdc -cursor {} -font $::TPEVAR(font_normal) \
        -foreground #000000 -tearoff 0 
	$base.fm.mtools.m add command \
        -command src:getCurrentFileProcedureList -label Rescan 
	$base.fm.mtools.m add command \
        -label Execute -command {tk_messageBox -title Information -message "Not yet implemented!"}
	$base.fm.mtools.m add checkbutton \
        -offvalue 0 -onvalue 1 -variable TPEVAR(syntaxHighlight) \
        -accelerator {} -background {} \
        -command {# TODO: Your menu handler here} -font $::TPEVAR(font_normal) -foreground {} \
        -image {} -label {Syntax highlight} 
	$base.fm.mtools.m add checkbutton \
        -offvalue 0 -onvalue 1 -variable TPEVAR(autoCompletion) \
        -accelerator {} -background {} \
        -command {# TODO: Your menu handler here} -font $::TPEVAR(font_normal) -foreground {} \
        -image {} -label {Language auto-completion} 
	$base.fm.mtools.m add checkbutton \
        -offvalue 0 -onvalue 1 -variable TPEVAR(procedureTip) \
        -accelerator {} -background {} \
        -command {# TODO: Your menu handler here} -font $::TPEVAR(font_normal) -foreground {} \
        -image {} -label {User procedure tip} 
	frame $base.ftb \
        -background #dcdcdc -borderwidth 2 -height 30 \
        -highlightbackground #dcdcdc -highlightcolor #000000 -relief groove \
        -width 125 
	button $base.ftb.btnback -font $::TPEVAR(font_normal) -width 7 -borderwidth 1 -text "Back" -command {src:backHistory}
	button $base.ftb.btnforward -font $::TPEVAR(font_normal) -width 7 -borderwidth 1 -text "Forward" -command {src:forwardHistory}
	frame $base.cpd17 \
        -background #000000 -height 100 -highlightbackground #dcdcdc \
        -highlightcolor #000000 -width 200 
	frame $base.cpd17.01 \
        -background #9900991B99FE -highlightbackground #dcdcdc \
        -highlightcolor #000000 
	frame $base.cpd17.01.cpd18 \
        -background #000000 -height 100 -highlightbackground #dcdcdc \
        -highlightcolor #000000 -width 200 
	frame $base.cpd17.01.cpd18.01 \
        -background #9900991B99FE -highlightbackground #dcdcdc \
        -highlightcolor #000000 
	frame $base.cpd17.01.cpd18.01.cpd19 \
        -background #dcdcdc -borderwidth 1 -height 30 \
        -highlightbackground #dcdcdc -highlightcolor #000000 -relief raised \
        -width 30 
	listbox $base.cpd17.01.cpd18.01.cpd19.01 \
        -background #ffffca -exportselection 0 \
        -font $::TPEVAR(font_normal) \
        -foreground #000000 -highlightbackground #ffffff \
        -highlightcolor #000000 -selectbackground #0a5f89 \
        -selectforeground #ffffff \
        -xscrollcommand {.mw.cpd17.01.cpd18.01.cpd19.02 set} \
        -yscrollcommand {.mw.cpd17.01.cpd18.01.cpd19.03 set} 
	bind $base.cpd17.01.cpd18.01.cpd19.01 <ButtonRelease-1> {
		src:addHistory
		project:load_file
	}
	scrollbar $base.cpd17.01.cpd18.01.cpd19.02 \
        -background #dcdcdc -borderwidth 1 \
        -command {.mw.cpd17.01.cpd18.01.cpd19.01 xview} -cursor left_ptr \
        -highlightbackground #dcdcdc -highlightcolor #000000 \
        -orient horizontal -troughcolor #dcdcdc -width 16 
	scrollbar $base.cpd17.01.cpd18.01.cpd19.03 \
        -background #dcdcdc -borderwidth 1 \
        -command {.mw.cpd17.01.cpd18.01.cpd19.01 yview} -cursor left_ptr \
        -highlightbackground #dcdcdc -highlightcolor #000000 \
        -troughcolor #dcdcdc -width 16 
	frame $base.cpd17.01.cpd18.02 \
        -background #9900991B99FE -highlightbackground #dcdcdc \
        -highlightcolor #000000 
	frame $base.cpd17.01.cpd18.02.cpd20 \
        -background #dcdcdc -borderwidth 1 -height 30 \
        -highlightbackground #dcdcdc -highlightcolor #000000 -relief raised \
        -width 30 
	listbox $base.cpd17.01.cpd18.02.cpd20.01 \
        -background #b4ffff -exportselection 0 \
        -font $::TPEVAR(font_small) \
        -foreground #000000 -highlightbackground #ffffff \
        -highlightcolor #000000 -selectbackground #0a5f89 \
        -selectforeground #ffffff \
        -xscrollcommand {.mw.cpd17.01.cpd18.02.cpd20.02 set} \
        -yscrollcommand {.mw.cpd17.01.cpd18.02.cpd20.03 set} 
	bind $base.cpd17.01.cpd18.02.cpd20.01 <ButtonRelease-1> {
		src:showProcedureBody
    }
	scrollbar $base.cpd17.01.cpd18.02.cpd20.02 \
        -background #dcdcdc -borderwidth 1 \
        -command {.mw.cpd17.01.cpd18.02.cpd20.01 xview} -cursor left_ptr \
        -highlightbackground #dcdcdc -highlightcolor #000000 \
        -orient horizontal -troughcolor #dcdcdc -width 16 
	scrollbar $base.cpd17.01.cpd18.02.cpd20.03 \
        -background #dcdcdc -borderwidth 1 \
        -command {.mw.cpd17.01.cpd18.02.cpd20.01 yview} -cursor left_ptr \
        -highlightbackground #dcdcdc -highlightcolor #000000 \
        -troughcolor #dcdcdc -width 16 
	frame $base.cpd17.01.cpd18.03 \
        -background #ff0000 -borderwidth 2 -highlightbackground #dcdcdc \
        -highlightcolor #000000 -relief raised 
	bind $base.cpd17.01.cpd18.03 <B1-Motion> {
		set root [ split %W . ]
    set nb [ llength $root ]
    incr nb -1
    set root [ lreplace $root $nb $nb ]
    set root [ join $root . ]
    set height [ winfo height $root ].0
    
    set val [ expr (%Y - [winfo rooty $root]) /$height ]

    if { $val >= 0 && $val <= 1.0 } {
    
        place $root.01 -relheight $val
        place $root.03 -rely $val
        place $root.02 -relheight [ expr 1.0 - $val ]
    }
    }
	frame $base.cpd17.02 \
        -background #9900991B99FE -highlightbackground #dcdcdc \
        -highlightcolor #000000 
	frame $base.cpd17.02.cpd21 \
        -background #dcdcdc -borderwidth 1 -height 30 \
        -highlightbackground #dcdcdc -highlightcolor #000000 -relief raised \
        -width 30 
	scrollbar $base.cpd17.02.cpd21.01 \
        -background #dcdcdc -borderwidth 1 \
        -command {.mw.cpd17.02.cpd21.03 xview} -cursor left_ptr \
        -highlightbackground #dcdcdc -highlightcolor #000000 \
        -orient horizontal -troughcolor #dcdcdc -width 16 
	scrollbar $base.cpd17.02.cpd21.02 \
        -background #dcdcdc -borderwidth 1 \
        -command {.mw.cpd17.02.cpd21.03 yview} -cursor left_ptr \
        -highlightbackground #dcdcdc -highlightcolor #000000 \
        -troughcolor #dcdcdc -width 16 
	Supertext::text $base.cpd17.02.cpd21.03 \
        -background gray -font $::TPEVAR(font_fixed) -foreground black -height 1 \
        -highlightbackground #000000 -highlightcolor #ffffff \
        -selectbackground #0a5f89 -selectforeground #ffffff \
			-insertbackground white -insertwidth 3\
        -tabs {20 40 60 80 100 120 140 160 180 200} -width 8 -wrap none \
        -xscrollcommand {.mw.cpd17.02.cpd21.01 set} \
        -yscrollcommand {.mw.cpd17.02.cpd21.02 set} \
	-insertontime 400 -insertofftime 200 
	bind $base.cpd17.02.cpd21.03 <ButtonPress-1> {
		$::widget(src) tag delete showline
		src:checkForProcedureDefinition
	}
	bind $base.cpd17.02.cpd21.03 <Button-3> {
		src:markWord %x %y
	}
	bind $base.cpd17.02.cpd21.03 <Shift-Key-Tab> {
		src:checkBlockUnident
	}
	bind $base.cpd17.02.cpd21.03 <ButtonRelease-3> {
		project:jumpToProcedureImplementation
	}
	bind $base.cpd17.02.cpd21.03 <Key-Control_L>c {
		src:copy
	}
	bind $base.cpd17.02.cpd21.03 <Key-Control_L>p {
		project:jumpToProcedureImplementation
		break
    }
	bind $base.cpd17.02.cpd21.03 <Key-Control_L>v {
		src:paste
		break
    }
	bind $base.cpd17.02.cpd21.03 <Key-Control_L>x {
		src:cut
		break
    }
	bind $base.cpd17.02.cpd21.03 <Key-Control_R>c {
		src:copy
    }
	bind $base.cpd17.02.cpd21.03 <Key-Control_R>v {
		src:paste
		break
    }
	bind $base.cpd17.02.cpd21.03 <Key-Control_R>x {
		src:cut
		break
    }
	bind $base.cpd17.02.cpd21.03 <Key-F3> {
		src:findNext
    }
	bind $base.cpd17.02.cpd21.03 <Key-Insert> {
		if {$TPEVAR(overwrite)} {
			set TPEVAR(overwrite) 0
			set TPEVAR(ovrMessage) "INS"
			$widget(src) configure -insertbackground "white" -insertwidth 2
		} else {
			set TPEVAR(overwrite) 1
			set TPEVAR(ovrMessage) "OVR"
			$widget(src) configure -insertbackground "yellow" -insertwidth 14
		}
	}
	bind $base.cpd17.02.cpd21.03 <Key> {
		set TPEVAR(doNotInsertCharacter) 0
		if {[src:updated %k %K %A]} {
			src:highlightSingleLine
			if {$TPEVAR(doNotInsertCharacter)} {
				break
			}
		}
    }
	frame $base.cpd17.03 \
        -background #ff0000 -borderwidth 2 -highlightbackground #dcdcdc \
        -highlightcolor #000000 -relief raised 
	bind $base.cpd17.03 <B1-Motion> {
		set root [ split %W . ]
		set nb [ llength $root ]
    		incr nb -1
    		set root [ lreplace $root $nb $nb ]
    		set root [ join $root . ]
    		set width [ winfo width $root ].0
    
    		set val [ expr (%X - [winfo rootx $root]) /$width ]

    		if { $val >= 0 && $val <= 1.0 } {
        		place $root.01 -relwidth $val
        		place $root.03 -relx $val
        		place $root.02 -relwidth [ expr 1.0 - $val ]
    		}
    }
	frame $base.fsl \
        -background #dcdcdc -borderwidth 2 -height 21 \
        -highlightbackground #dcdcdc -highlightcolor #000000 -relief groove \
        -width 125 
	label $base.fsl.lcurfile \
         -anchor w \
        -background #dcdcdc -borderwidth 1 -font $::TPEVAR(font_normal) \
        -foreground #000000 -highlightbackground #dcdcdc \
        -highlightcolor #000000 -relief sunken \
        -textvariable TPEVAR(currentFile) -width 25 
	label $base.fsl.lmsg \
         -anchor w \
        -background #dcdcdc -borderwidth 1 -font $::TPEVAR(font_normal) \
        -foreground #000000 -highlightbackground #dcdcdc \
        -highlightcolor #000000 -relief sunken -text {} \
        -textvariable TPEVAR(lastMessage) 
	label $base.fsl.lovr \
         -anchor center -width 4 \
        -background #dcdcdc -borderwidth 1 -font $::TPEVAR(font_normal) \
        -foreground #000000 -highlightbackground #dcdcdc \
        -highlightcolor #000000 -relief sunken -text {} \
        -textvariable TPEVAR(ovrMessage) 
	###################
	# SETTING GEOMETRY
	###################
	pack $base.fm \
        -in .mw -anchor center -expand 0 -fill x -side top 
	pack $base.fm.mfiles \
        -in .mw.fm -anchor center -expand 0 -fill none -side left 
	pack $base.fm.medit \
        -in .mw.fm -anchor center -expand 0 -fill none -side left 
	pack $base.fm.mtools \
        -in .mw.fm -anchor center -expand 0 -fill none -side left 
	pack $base.ftb \
        -in .mw -anchor center -expand 0 -fill x -side top 
	pack $base.ftb.btnback -in $base.ftb -side left
	pack $base.ftb.btnforward -in $base.ftb -side left
	pack $base.cpd17 \
        -in .mw -anchor center -expand 1 -fill both -side top 
	place $base.cpd17.01 \
        -x 0 -y 0 -width -1 -relwidth 0.2169 -relheight 1 -anchor nw \
        -bordermode ignore 
	pack $base.cpd17.01.cpd18 \
        -in .mw.cpd17.01 -anchor center -expand 1 -fill both -side top 
	place $base.cpd17.01.cpd18.01 \
        -x 0 -y 0 -relwidth 1 -height -1 -relheight 0.28 -anchor nw \
        -bordermode ignore 
	pack $base.cpd17.01.cpd18.01.cpd19 \
        -in .mw.cpd17.01.cpd18.01 -anchor center -expand 1 -fill both \
        -side top 
	grid columnconf $base.cpd17.01.cpd18.01.cpd19 0 -weight 1
	grid rowconf $base.cpd17.01.cpd18.01.cpd19 0 -weight 1
	grid $base.cpd17.01.cpd18.01.cpd19.01 \
        -in .mw.cpd17.01.cpd18.01.cpd19 -column 0 -row 0 -columnspan 1 \
        -rowspan 1 -sticky nesw 
	grid $base.cpd17.01.cpd18.01.cpd19.02 \
        -in .mw.cpd17.01.cpd18.01.cpd19 -column 0 -row 1 -columnspan 1 \
        -rowspan 1 -sticky ew 
	grid $base.cpd17.01.cpd18.01.cpd19.03 \
        -in .mw.cpd17.01.cpd18.01.cpd19 -column 1 -row 0 -columnspan 1 \
        -rowspan 1 -sticky ns 
	place $base.cpd17.01.cpd18.02 \
        -x 0 -y 0 -rely 1 -relwidth 1 -height -1 -relheight 0.72 -anchor sw \
        -bordermode ignore 
	pack $base.cpd17.01.cpd18.02.cpd20 \
        -in .mw.cpd17.01.cpd18.02 -anchor center -expand 1 -fill both \
        -side top 
	grid columnconf $base.cpd17.01.cpd18.02.cpd20 0 -weight 1
	grid rowconf $base.cpd17.01.cpd18.02.cpd20 0 -weight 1
	grid $base.cpd17.01.cpd18.02.cpd20.01 \
        -in .mw.cpd17.01.cpd18.02.cpd20 -column 0 -row 0 -columnspan 1 \
        -rowspan 1 -sticky nesw 
	grid $base.cpd17.01.cpd18.02.cpd20.02 \
        -in .mw.cpd17.01.cpd18.02.cpd20 -column 0 -row 1 -columnspan 1 \
        -rowspan 1 -sticky ew 
	grid $base.cpd17.01.cpd18.02.cpd20.03 \
        -in .mw.cpd17.01.cpd18.02.cpd20 -column 1 -row 0 -columnspan 1 \
        -rowspan 1 -sticky ns 
	place $base.cpd17.01.cpd18.03 \
        -x 0 -relx 0.9 -y 0 -rely 0.28 -width 10 -height 10 -anchor e \
        -bordermode ignore 
	place $base.cpd17.02 \
        -x 0 -relx 1 -y 0 -width -1 -relwidth 0.7831 -relheight 1 -anchor ne \
        -bordermode ignore 
	pack $base.cpd17.02.cpd21 \
        -in .mw.cpd17.02 -anchor center -expand 1 -fill both -side top 
	grid columnconf $base.cpd17.02.cpd21 0 -weight 1
	grid rowconf $base.cpd17.02.cpd21 0 -weight 1
	grid $base.cpd17.02.cpd21.01 \
        -in .mw.cpd17.02.cpd21 -column 0 -row 1 -columnspan 1 -rowspan 1 \
        -sticky ew 
	grid $base.cpd17.02.cpd21.02 \
        -in .mw.cpd17.02.cpd21 -column 1 -row 0 -columnspan 1 -rowspan 1 \
        -sticky ns 
	grid $base.cpd17.02.cpd21.03 \
        -in .mw.cpd17.02.cpd21 -column 0 -row 0 -columnspan 1 -rowspan 1 \
        -sticky nesw 
	place $base.cpd17.03 \
        -x 0 -relx 0.2169 -y 0 -rely 0.9 -width 10 -height 10 -anchor s \
        -bordermode ignore 
	pack $base.fsl \
        -in .mw -anchor center -expand 0 -fill x -side bottom 
	pack $base.fsl.lcurfile \
        -in .mw.fsl -anchor center -expand 0 -fill none -side left 
	pack $base.fsl.lmsg \
        -in .mw.fsl -anchor center -expand 1 -fill x -side left 
	pack $base.fsl.lovr \
        -in .mw.fsl -anchor center -expand 0 -fill x -side right 
}

proc vTclWindow.replace {base} {
	if {$base == ""} {
		set base .replace
	}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	###################
	# CREATING WIDGETS
	###################
	toplevel $base -class Toplevel  -background #dcdcdc -highlightbackground #dcdcdc  -highlightcolor #000000 
	wm focusmodel $base passive
	wm geometry $base 232x98+422+368
	wm maxsize $base 1137 834
	wm minsize $base 1 1
	wm overrideredirect $base 0
	wm resizable $base 0 0
	wm title $base "Find and replace"
	bind $base <Key-Escape> {
		Window hide .replace
    }
	label $base.l1    -background #dcdcdc -borderwidth 1 -font $::TPEVAR(font_normal)  -foreground #000000 -highlightbackground #dcdcdc  -highlightcolor #000000 -text Find 
	entry $base.e1  -background #ffffff -borderwidth 1 -foreground #000000  -highlightbackground #ffffff -highlightcolor #000000  -selectbackground #0a5f89 -selectforeground #ffffff  -textvariable TPEVAR(whatToFind) 
	entry $base.e2  -background #ffffff -borderwidth 1 -foreground #000000  -highlightbackground #ffffff -highlightcolor #000000  -selectbackground #0a5f89 -selectforeground #ffffff  -textvariable TPEVAR(replaceWith) 
	bind $base.e1 <Key-KP_Enter> {
		focus .replace.e2
	}
	bind $base.e1 <Key-Return> {
		focus .replace.e2
	}
	bind $base.e2 <Key-KP_Enter> {
		src:replace
	}
	bind $base.e2 <Key-Return> {
		src:replace
	}
	button $base.okbtn    -background #dcdcdc -borderwidth 1 -command src:replace  -font $::TPEVAR(font_normal) -foreground #000000  -highlightbackground #dcdcdc -highlightcolor #000000 -text OK 
	button $base.btncancel    -background #dcdcdc -borderwidth 1 -command {Window hide .replace}  -font $::TPEVAR(font_normal) -foreground #000000  -highlightbackground #dcdcdc -highlightcolor #000000 -text Cancel 
	label $base.lre     -background #dcdcdc -borderwidth 1 -font $::TPEVAR(font_normal)  -foreground #000000 -highlightbackground #dcdcdc  -highlightcolor #000000 -text Replace 
	###################
	# SETTING GEOMETRY
	###################
	place $base.l1  -x 20 -y 10 -width 29 -height 18 -anchor nw -bordermode ignore 
	place $base.e1  -x 81 -y 9 -width 126 -height 20 -anchor nw -bordermode ignore 
	place $base.okbtn  -x 25 -y 65 -width 80 -height 24 -anchor nw -bordermode ignore 
	place $base.btncancel  -x 115 -y 65 -width 77 -height 24 -anchor nw -bordermode ignore 
	place $base.lre  -x 20 -y 36 -width 50 -height 18 -anchor nw -bordermode ignore 
	place $base.e2  -x 81 -y 35 -width 126 -height 20 -anchor nw -bordermode ignore
}

########################3
#
# Supertext.tcl v1.0b1
#
# Copyright (c) 1998 Bryan Oakley
# All Rights Reserved
#
# this code is freely distributable, but is provided as-is with
# no waranty expressed or implied.

# send comments to boakley@austin.rr.com

# What is this?
# 
# This is a replacement for (or superset of , or subclass of, ...) 
# the tk text widget. Its big feature is that it supports unlimited
# undo. It also has two poorly documented options: -preproc and 
# -postproc. 

# The entry point to this widget is Supertext::text; it takes all of
# the same arguments as the standard text widget and exhibits all of
# the same behaviors.  The proc Supertext::overrideTextCommand may be
# called to have the supertext widget be used whenever the command
# "text" is used (ie: it imports Supertext::text as the command "text"). 
# Use at your own risk...

# To access the undo feature, use ".widget undo". It will undo the
# most recent insertion or deletion. On windows and the mac
# this command is bound to <Control-z>; on unix it is bound to
# <Control-_>

# if you are lucky, you might find documentation here:
# http://www1.clearlight.com/~oakley/tcl/supertext.html

namespace eval Supertext {

    variable undo
    variable undoIndex
    variable text "::text"
    variable preProc
    variable postProc

    namespace export text
}

# this proc is probably attempting to be more clever than it should...
# When called, it will (*gasp*) rename the tk command "text" to "_text_", 
# then import our text command into the global scope. 
#
# Use at your own risk!

proc Supertext::overrideTextCommand {} {
    variable text

    set text "::_text_"
    rename ::text $text
    uplevel #0 namespace import Supertext::text
}

proc Supertext::text {w args} {
    variable text
    variable undo
    variable undoIndex
    variable preProc
    variable postProc

    # this is what we will rename our widget proc to...
    set original __$w

    # do we have any of our custom options? If so, process them and 
    # strip them out before sending them to the real text command
    if {[set i [lsearch -exact $args "-preproc"]] >= 0} {
		set j [expr $i + 1]
		set preProc($original) [lindex $args $j]
		set args [lreplace $args $i $j]
    } else {
		set preProc($original) {}
    }

    if {[set i [lsearch -exact $args "-postproc"]] >= 0} {
		set j [expr $i + 1]
		set postProc($original) [lindex $args $j]
		set args [lreplace $args $i $j]
    } else {
		set postProc($original) {}
    }

    # let the text command create the widget...
    eval $text $w $args

    # now, rename the resultant widget proc so we can create our own
    rename ::$w $original

    # here is where we create our own widget proc.
    proc ::$w {command args} \
        "namespace eval Supertext widgetproc $w $original \$command \$args"
    
    # set up platform-specific binding for undo; the only one I am
    # really sure about is winders; what should the mac be? On unix
    # I just picked what I am used to in emacs :-)
    switch $::tcl_platform(platform) {
		unix 		{event add <<Undo>> <Control-z>}
		windows 	{event add <<Undo>> <Control-z>}
		macintosh 	{event add <<Undo>> <Control-z>}
    }
    bind $w <<Undo>> "$w undo"

    set undo($original)	{}
    set undoIndex($original) -1
    set clones($original) {}

    return $w
}

# this is the command that we associate with a supertext widget. 
proc Supertext::widgetproc {this w command args} {

    variable undo
    variable undoIndex
    variable preProc
    variable postProc

    # these will be the arguments to the pre and post procs
    set originalCommand $command
    set originalArgs $args

    # is there a pre-proc? If so, run it. If there is a problem,
    # die. This is potentially bad, because once there is a problem
    # in a preproc the user must fix the preproc -- there is no
    # way to unconfigure the preproc. Oh well. The other choice
    # is to ignore errors, but then how will the caller know if
    # the proc fails?
    if {[info exists preProc($w)] && $preProc($w) != ""} {
		if {[catch "$preProc($w) command args" error]} {
			return -code error "error during processing of -preproc: $error"
		}
    }


    # if the command is "undo", we need to morph it into the appropriate
    # command for undoing the last item on the stack
    if {$command == "undo"} {

		if {$undoIndex($w) == ""} {
			# ie: last command was anything _but_ an undo...
			set undoIndex($w) [expr [llength $undo($w)] -1]
		}

		# if the index is pointing to a valid list element, 
		# lets undo it...
		if {$undoIndex($w) < 0} {
			# nothing to undo...
			bell

		} else {
			
			# data is a list comprised of a command token
			# (i=insert, d=delete) and parameters related 
			# to that token
			set data [lindex $undo($w) $undoIndex($w)]

			if {[lindex $data 0] == "d"} {
				set command "delete"
			} else {
				set command "insert"
			}
			set args [lrange $data 1 end]

			# adjust the index
			incr undoIndex($w) -1

		}
    }

    # now, process the command (either the original one, or the morphed
    # undo command
    switch $command {

	#showundo {
	#	::showTrace "Undo= $undo($w)\n\nundoIndex= $undoIndex($w)"
	#	set result {}
	#}

	clearundo {
		set undo($w) {}
		set undoIndex($w) -1
		set result {}
	}

	configure {
	    # we have to deal with configure specially, since the
	    # user could try to configure the -preproc or -postproc
	    # options...
	    
	    if {[llength $args] == 0} {
			# first, the case where they just type "configure"; lets 
			# get it out of the way
			set list [$w configure]
			lappend list [list -preproc preproc Preproc {} $preProc($w)]
			lappend list [list -postproc postproc Postproc {} $postProc($w)]
			set result $list		
	    } elseif {[llength $args] == 1} {
			# this means they are wanting specific configuration 
			# information
			set option [lindex $args 0]
			if {$option == "-preproc"} {
				set result [list -preproc preproc Preproc {} $preProc($w)]

			} elseif {$option == "-postproc"} {
				set result [list -postproc postproc Postproc {} $postProc($w)]
				
			} else {
				if {[catch "$w $command $args" result]} {
				regsub $w $result $this result
				return -code error $result
				}
			}
	    } else {
			# ok, the user is actually configuring something... 
			# we'll deal with our special options first
			if {[set i [lsearch -exact $args "-preproc"]] >= 0} {
				set j [expr $i + 1]
				set preProc($w) [lindex $args $j]
				set args [lreplace $args $i $j]
				set result {}
			}

			if {[set i [lsearch -exact $args "-postproc"]] >= 0} {
				set j [expr $i + 1]
				set postProc($w) [lindex $args $j]
				set args [lreplace $args $i $j]
				set result {}
			}

			# now, process any remaining args
			if {[llength $args] > 0} {
				if {[catch "$w $command $args" result]} {
				regsub $w $result $this result
				return -code error $result
				}
			}
	    }
	}

	undo {
	    # if an undo command makes it to here, that means there 
	    # was not anything to undo; this effectively becomes a
	    # no-op
	    set result {}
	}

	insert {

	    if {[catch {set index  [text_index $w [lindex $args 0]]}]} {
			set index [lindex $args 0]
	    }

	    # since the insert command can have an arbitrary number
	    # of strings and possibly tags, we need to ferret that out
	    # now... what a pain!
	    set myargs [lrange $args 1 end]
	    set length 0
	    while {[llength $myargs] > 0} {
			incr length [string length [lindex $myargs 0]]
			if {[llength $myargs] > 1} {
				# we have a tag...
				set myargs [lrange $myargs 2 end]
			} else {
				set myargs [lrange $myargs 1 end]
			}
	    }

	    # now, let the real widget command do the dirty work
	    # of inserting the text. If we fail, do some munging 
	    # of the error message so the right widget name appears...

	    if {[catch "$w $command $args" result]} {
			regsub $w $result $this result
			return -code error $result
	    }

	    # we need this for the undo stack; index2 could not be
	    # computed until after we inserted the data...
	    set index2 [text_index $w "$index + $length chars"]

	    if {$originalCommand == "undo"} {
			# let's do a "see" so what we just did is visible;
			# also, we'll move the insertion cursor to the end
			# of what we just did...
			$w see $index2
			$w mark set insert $index2
	    } else {
			# since the original command wasn't undo, we need
			# to reset the undoIndex. This means that the next
			# time an undo is called for we'll start at the 
			# end of the stack
			set undoIndex($w) ""
	    }

	    # add a delete command on the undo stack.
	    lappend undo($w) "d $index $index2"

	}

	delete {

	    # this converts the insertion index into an absolute address
	    set index [text_index $w [lindex $args 0]]

	    # lets get the data we are about to delete; we will need
	    # it to be able to undo it (obviously. Duh.)
	    set data [eval $w get $args]

	    # add an insert on the undo stack
	    lappend undo($w) [list "i" $index $data]

	    if {$originalCommand == "undo"} {
			# let's do a "see" so what we just did is visible;
			# also, we'll move the insertion cursor to a suitable
			# spot
			$w see $index
			$w mark set insert $index
	    } else {
			# since the original command wasn't undo, we need
			# to reset the undoIndex. This means that the next
			# time an undo is called for we'll start at the 
			# end of the stack
			set undoIndex($w) ""
	    }

	    # let the real widget command do the actual deletion. If
	    # we fail, do some munging of the error message so the right
	    # widget name appears...
	    if {[catch "$w $command $args" result]} {
			regsub $w $result $this result
			return -code error $result
	    }
	}
	
	default {
	    # if the command was not one of the special commands above,
	    # just pass it on to the real widget command as-is. If
	    # we fail, do some munging of the error message so the right
	    # widget name appears...
	    if {[catch "$w $command $args" result]} {
			regsub $w $result $this result
			return -code error $result
	    }
	}
    }

    # is there a post-proc? If so, run it. 
    if {[info exists postProc($w)] && $postProc($w) != ""} {
		if {[catch "$postProc($w) originalCommand originalArgs" error]} {
			return -code error "error during processing of -postproc: $error"
		}
    }


    # we are outta here!
    return $result
}

# this returns a normalized index (ie: line.column), with special
# handling for the index "end"; to undo something we pretty much
# _have_ to have a precise row and column number.
proc Supertext::text_index {w i} {
    if {$i == "end"} {
		set index [$w index "end-1c"]
    } else {
		set index [$w index $i]
    }

    return $index
}



Window show .
Window show .mw

main $argc $argv
