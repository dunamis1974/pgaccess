#==============================================================================
# Contains the implementation of interactive cell editing in tablelist widgets.
#
# Structure of the module:
#   - Namespace initialization
#   - Private procedures implementing the interactive cell editing
#   - Private procedures used in bindings related to interactive cell editing
#   - Private utility procedures related to interactive cell editing
#
# Copyright (c) 2003  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#
# Namespace initialization
# ========================
#

namespace eval tablelist {
    #
    # Define some bindings for the binding tag TablelistEntry
    #
    bind TablelistEntry <Control-i>        { tablelist::entryInsert  %W \t }
    bind TablelistEntry <Control-j>        { tablelist::entryInsert  %W \n }
    bind TablelistEntry <Control-Return>   { tablelist::entryInsert  %W \n }
    bind TablelistEntry <Control-KP_Enter> { tablelist::entryInsert  %W \n }
    bind TablelistEntry <Escape>	   { tablelist::cancelEditing   %W }
    bind TablelistEntry <Return>	   { tablelist::finishEditing   %W }
    bind TablelistEntry <KP_Enter>	   { tablelist::finishEditing   %W }
    bind TablelistEntry <Tab>	           { tablelist::moveToNext      %W }
    bind TablelistEntry <Shift-Tab>	   { tablelist::moveToPrev      %W }
    bind TablelistEntry <<PrevWindow>>     { tablelist::moveToPrev      %W }
    bind TablelistEntry <Alt-Left>         { tablelist::moveLeft        %W }
    bind TablelistEntry <Meta-Left>        { tablelist::moveLeft        %W }
    bind TablelistEntry <Alt-Right>        { tablelist::moveRight       %W }
    bind TablelistEntry <Meta-Right>       { tablelist::moveRight       %W }
    bind TablelistEntry <Up>	           { tablelist::moveOneLineUp   %W }
    bind TablelistEntry <Down>	           { tablelist::moveOneLineDown %W }
    bind TablelistEntry <Prior>            { tablelist::moveOnePageUp   %W }
    bind TablelistEntry <Next>             { tablelist::moveOnePageDown %W }
    bind TablelistEntry <Control-Home>     { tablelist::moveToNext %W 0 -1 }
    bind TablelistEntry <Control-End>      { tablelist::moveToPrev %W 0  0 }
    bind TablelistEntry <Control-Tab> {
	mwutil::generateEvent %W Tablelist <Tab>
    }
    bind TablelistEntry <Meta-Tab> {
	mwutil::generateEvent %W Tablelist <Tab>
    }
    bind TablelistEntry <Control-Shift-Tab> {
	mwutil::generateEvent %W Tablelist <Shift-Tab>
    }
    bind TablelistEntry <Meta-Shift-Tab> {
	mwutil::generateEvent %W Tablelist <Shift-Tab>
    }
    bind TablelistEntry <Destroy> {
	array set tablelist::ns[tablelist::parseEntryPath %W]::data \
		  {editRow -1  editCol -1}
    }

    #
    # Define some emacs-like key bindings for the binding tag TablelistEntry
    #
    bind TablelistEntry <Meta-b> {
	if {!$tk_strictMotif} {
	    tablelist::moveLeft %W
	}
    }
    bind TablelistEntry <Meta-f> {
	if {!$tk_strictMotif} {
	    tablelist::moveRight %W
	}
    }
    bind TablelistEntry <Control-p> {
	if {!$tk_strictMotif} {
	    tablelist::moveOneLineUp %W
	}
    }
    bind TablelistEntry <Control-n> {
	if {!$tk_strictMotif} {
	    tablelist::moveOneLineDown %W
	}
    }
    bind TablelistEntry <Meta-less> {
	if {!$tk_strictMotif} {
	    tablelist::moveToNext %W 0 -1
	}
    }
    bind TablelistEntry <Meta-greater> {
	if {!$tk_strictMotif} {
	    tablelist::moveToPrev %W 0 0
	}
    }

    #
    # Define some bindings for the binding tag TablelistEntry that
    # propagate the mousewheel events to the tablelist's body
    #
    bind TablelistEntry <MouseWheel> {
	tablelist::genMouseWheelEvent [winfo parent [winfo parent %W]] %D
    }
    bind TablelistEntry <Button-4> {
	event generate [winfo parent [winfo parent %W]] <Button-4>
    }
    bind TablelistEntry <Button-5> {
	event generate [winfo parent [winfo parent %W]] <Button-5>
    }
}

#
# Private procedures implementing the interactive cell editing
# ============================================================
#

#------------------------------------------------------------------------------
# tablelist::editcellSubCmd
#
# This procedure is invoked to process the tablelist editcell subcommand.
# charPos stands for the character position component of the index in the body
# text widget of the character underneath the mouse cursor if this command was
# invoked by clicking mouse button 1 in the body of the tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::editcellSubCmd {win row col restore {charPos -1}} {
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled) || $data($col-hide) ||
	![isCellEditable $win $row $col]} {
	return ""
    }
    if {$data(editRow) == $row && $data(editCol) == $col} {
	return ""
    }
    if {$data(editRow) >= 0 && ![finisheditingSubCmd $win]} {
	return ""
    }

    #
    # Replace the cell contents between the two tabs with an embedded frame
    #
    set w $data(body)
    set item [lindex $data(itemList) $row]
    set key [lindex $item end]
    findCellTabs $win [expr {$row + 1}] $col tabIdx1 tabIdx2
    $w delete $tabIdx1+1c $tabIdx2
    set pixels [lindex $data(colList) [expr {2*$col}]]
    if {$pixels == 0} {				;# convention: dynamic width
	set pixels $data($col-width)
    }
    set f $data(bodyFr)
    frame $f -borderwidth 0 -container 0 -height 0 \
	     -highlightthickness 0 -relief flat -takefocus 0 \
	     -width [expr {$pixels + $data($col-delta) + 6}]
    $w window create $tabIdx1+1c -padx -3 -pady -2 -stretch 1 -window $f

    #
    # Create an entry widget as a child of the above frame
    #
    set e $data(bodyFrEnt)
    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
    entry $e -borderwidth 2 -font [cellFont $win $key $col] \
	     -highlightthickness 0 -justify $alignment \
	     -relief ridge -takefocus 0
    place $e -relheight 1.0 -relwidth 1.0
    set data(editKey) $key
    set data(editRow) $row
    set data(editCol) $col

    #
    # Insert the binding tag TablelistEntry before
    # Entry in the list of binding tags of the entry
    #
    bindtags $e [linsert [bindtags $e] 1 TablelistEntry]

    #
    # Restore or initialize some of the entry's data
    #
    if {$restore} {
	restoreEntryData $win
    } else {
	set data(canceled) 0
	set text [lindex $item $col]
	if {[lindex $data(fmtCmdFlagList) $col]} {
	    set text [uplevel #0 $data($col-formatcommand) [list $text]]
	}
	$e insert 0 $text
	if {[string compare $data(-editstartcommand) ""] != 0} {
	    set text [uplevel #0 $data(-editstartcommand) \
		      [list $win $row $col $text]]
	    if {$data(canceled)} {
		return ""
	    }
	}

	$e delete 0 end
	$e insert 0 $text
	if {$charPos >= 0} {
	    #
	    # Determine the position of the insertion cursor
	    #
	    set image [doCellCget $row $col $win -image]
	    if {[string compare $alignment right] == 0} {
		scan $tabIdx2 %d.%d line tabCharIdx2
		set entryIdx [expr {[$e index end] - $tabCharIdx2 + $charPos}]
		if {[string compare $image ""] != 0} {
		    incr entryIdx 2
		}
	    } else {
		scan $tabIdx1 %d.%d line tabCharIdx1
		set entryIdx [expr {$charPos - $tabCharIdx1 - 1}]
		if {[string compare $image ""] != 0} {
		    incr entryIdx -2
		}
	    }
	    $e icursor $entryIdx
	} else {
	    $e icursor end
	    $e selection range 0 end
	}

	seecellSubCmd $win $row $col
	focus $e
	set data(rejected) 0
	set data(origEditText) $text
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::canceleditingSubCmd
#
# This procedure is invoked to process the tablelist cancelediting subcommand.
# Aborts the interactive cell editing and restores the cell's contents after
# destroying the embedded entry widget.
#------------------------------------------------------------------------------
proc tablelist::canceleditingSubCmd win {
    upvar ::tablelist::ns${win}::data data

    if {[set row $data(editRow)] < 0} {
	return ""
    }
    set col $data(editCol)

    destroy $data(bodyFr)
    set item [lindex $data(itemList) $row]
    doCellConfig $row $col $win -text [lindex $item $col]
    focus $data(body)
    set data(canceled) 1
    return ""
}

#------------------------------------------------------------------------------
# tablelist::finisheditingSubCmd
#
# This procedure is invoked to process the tablelist finishediting subcommand.
# Invokes the command specified by the -editendcommand option if needed, and
# updates the element just edited after destroying the embedded entry widget if
# the latter's contents was not rejected.  Returns 1 on normal termination and
# 0 otherwise.
#------------------------------------------------------------------------------
proc tablelist::finisheditingSubCmd win {
    upvar ::tablelist::ns${win}::data data

    if {[set row $data(editRow)] < 0} {
	return 1
    }
    set col $data(editCol)

    set w $data(bodyFrEnt)
    set text [$w get]
    if {[string compare $text $data(origEditText)] == 0} {
	set item [lindex $data(itemList) $row]
	set text [lindex $item $col]
    } elseif {[string compare $data(-editendcommand) ""] != 0} {
	set text [uplevel #0 $data(-editendcommand) [list $win $row $col $text]]
    }

    if {$data(rejected)} {
	seecellSubCmd $win $row $col
	focus $w
	set data(rejected) 0
	return 0
    } else {
	destroy $data(bodyFr)
	doCellConfig $row $col $win -text $text
	focus $data(body)
	return 1
    }
}

#
# Private procedures used in bindings related to interactive cell editing
# =======================================================================
#

#------------------------------------------------------------------------------
# tablelist::entryInsert
#
# Inserts the string str into the entry widget w at the point of the insertion
# cursor.
#------------------------------------------------------------------------------
proc tablelist::entryInsert {w str} {
    if {[string compare [info procs ::tkEntryInsert] ::tkEntryInsert] == 0} {
	tkEntryInsert $w $str
    } else {
	tk::EntryInsert $w $str
    }
}

#------------------------------------------------------------------------------
# tablelist::cancelEditing
#
# Invokes the canceleditingSubCmd procedure.
#------------------------------------------------------------------------------
proc tablelist::cancelEditing w {
    canceleditingSubCmd [parseEntryPath $w]
}

#------------------------------------------------------------------------------
# tablelist::finishEditing
#
# Invokes the finisheditingSubCmd procedure.
#------------------------------------------------------------------------------
proc tablelist::finishEditing w {
    finisheditingSubCmd [parseEntryPath $w]
}

#------------------------------------------------------------------------------
# tablelist::moveToNext
#
# Moves the embedded entry widget w into the next editable cell different from
# the one indicated by the given row and column, if there is such a cell.
#------------------------------------------------------------------------------
proc tablelist::moveToNext {w {row -1} {col -1}} {
    set win [parseEntryPath $w]
    upvar ::tablelist::ns${win}::data data

    if {$row == -1 && $col == -1} {
	set row $data(editRow)
	set col $data(editCol)
    }

    set oldRow $row
    set oldCol $col

    while 1 {
	incr col
	if {$col > $data(lastCol)} {
	    incr row
	    if {$row > $data(lastRow)} {
		set row 0
	    }
	    set col 0
	}

	if {$row == $oldRow && $col == $oldCol} {
	    return -code break ""
	} elseif {!$data($col-hide) && [isCellEditable $win $row $col]} {
	    editcellSubCmd $win $row $col 0
	    return -code break ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::moveToPrev
#
# Moves the embedded entry widget w into the previous editable cell different
# from the one indicated by the given row and column, if there is such a cell.
#------------------------------------------------------------------------------
proc tablelist::moveToPrev {w {row -1} {col -1}} {
    set win [parseEntryPath $w]
    upvar ::tablelist::ns${win}::data data

    if {$row == -1 && $col == -1} {
	set row $data(editRow)
	set col $data(editCol)
    }

    set oldRow $row
    set oldCol $col

    while 1 {
	incr col -1
	if {$col < 0} {
	    incr row -1
	    if {$row < 0} {
		set row $data(lastRow)
	    }
	    set col $data(lastCol)
	}

	if {$row == $oldRow && $col == $oldCol} {
	    return -code break ""
	} elseif {!$data($col-hide) && [isCellEditable $win $row $col]} {
	    editcellSubCmd $win $row $col 0
	    return -code break ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::moveLeft
#
# Moves the embedded entry widget w into the previous editable cell of the
# current row if the cell being edited is not the first editable one within
# that row.  Otherwise sets the insertion cursor to the beginning of the entry
# and clears the selection in it.
#------------------------------------------------------------------------------
proc tablelist::moveLeft w {
    set win [parseEntryPath $w]
    upvar ::tablelist::ns${win}::data data

    set row $data(editRow)
    set col $data(editCol)

    while 1 {
	incr col -1
	if {$col < 0} {
	    #
	    # On Windows the "event generate" command does not behave
	    # as expected if a Tk version older than 8.2.2 is used.
	    #
	    if {[string compare $::tk_patchLevel 8.2.2] < 0} {
		tkEntrySetCursor $w 0
	    } else {
		event generate $w <Home>
	    }
	    return -code break ""
	} elseif {!$data($col-hide) && [isCellEditable $win $row $col]} {
	    editcellSubCmd $win $row $col 0
	    return -code break ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::moveRight
#
# Moves the embedded entry widget w into the next editable cell of the current
# row if the cell being edited is not the last editable one within that row.
# Otherwise sets the insertion cursor to the end of the entry and clears the
# selection in it.
#------------------------------------------------------------------------------
proc tablelist::moveRight w  {
    set win [parseEntryPath $w]
    upvar ::tablelist::ns${win}::data data

    set row $data(editRow)
    set col $data(editCol)

    while 1 {
	incr col
	if {$col > $data(lastCol)} {
	    #
	    # On Windows the "event generate" command does not behave
	    # as expected if a Tk version older than 8.2.2 is used.
	    #
	    if {[string compare $::tk_patchLevel 8.2.2] < 0} {
		tkEntrySetCursor $w end
	    } else {
		event generate $w <End>
	    }
	    return -code break ""
	} elseif {!$data($col-hide) && [isCellEditable $win $row $col]} {
	    editcellSubCmd $win $row $col 0
	    return -code break ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::moveOneLineUp
#
# Moves the embedded entry widget w into the last editable cell that is located
# in the current column and has a row index less than the given one, if there
# is such a cell.
#------------------------------------------------------------------------------
proc tablelist::moveOneLineUp {w {row -1}} {
    set win [parseEntryPath $w]
    upvar ::tablelist::ns${win}::data data

    if {$row == -1} {
	set row $data(editRow)
    }

    set col $data(editCol)

    while 1 {
	incr row -1
	if {$row < 0} {
	    return 0
	} elseif {[isCellEditable $win $row $col]} {
	    editcellSubCmd $win $row $col 0
	    return 1
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::moveOneLineDown
#
# Moves the embedded entry widget w into the first editable cell that is
# located in the current column and has a row index greater than the given one,
# if there is such a cell.
#------------------------------------------------------------------------------
proc tablelist::moveOneLineDown {w {row -1}} {
    set win [parseEntryPath $w]
    upvar ::tablelist::ns${win}::data data

    if {$row == -1} {
	set row $data(editRow)
    }

    set col $data(editCol)

    while 1 {
	incr row
	if {$row > $data(lastRow)} {
	    return 0
	} elseif {[isCellEditable $win $row $col]} {
	    editcellSubCmd $win $row $col 0
	    return 1
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::moveOnePageUp
#
# Moves the embedded entry widget w up by one page within the current column if
# the cell being edited is not the first editable one within that column.
#------------------------------------------------------------------------------
proc tablelist::moveOnePageUp w {
    set win [parseEntryPath $w]
    upvar ::tablelist::ns${win}::data data

    #
    # Check whether there is any editable cell
    # above the current one, in the same column
    #
    set row $data(editRow)
    set col $data(editCol)
    while 1 {
	incr row -1
	if {$row < 0} {
	    return ""
	} elseif {[isCellEditable $win $row $col]} {
	    break
	}
    }

    #
    # Scroll up the view by one page and get the corresponding row index
    #
    set row $data(editRow)
    seeSubCmd $win $row
    set bbox [bboxSubCmd $win $row]
    yviewSubCmd $win {scroll -1 pages}
    set newRow [rowIndex $win @0,[lindex $bbox 1] 0]

    if {$newRow < $row} {
	if {![moveOneLineUp $w [expr {$newRow + 1}]]} {
	    moveOneLineDown $w $newRow
	}
    } else {
	moveOneLineDown $w -1
    }
}

#------------------------------------------------------------------------------
# tablelist::moveOnePageDown
#
# Moves the embedded entry widget w down by one page within the current column
# if the cell being edited is not the last editable one within that column.
#------------------------------------------------------------------------------
proc tablelist::moveOnePageDown w {
    set win [parseEntryPath $w]
    upvar ::tablelist::ns${win}::data data

    #
    # Check whether there is any editable cell
    # below the current one, in the same column
    #
    set row $data(editRow)
    set col $data(editCol)
    while 1 {
	incr row
	if {$row > $data(lastRow)} {
	    return ""
	} elseif {[isCellEditable $win $row $col]} {
	    break
	}
    }

    #
    # Scroll down the view by one page and get the corresponding row index
    #
    set row $data(editRow)
    seeSubCmd $win $row
    set bbox [bboxSubCmd $win $row]
    yviewSubCmd $win {scroll 1 pages}
    set newRow [rowIndex $win @0,[lindex $bbox 1] 0]

    if {$newRow > $row} {
	if {![moveOneLineDown $w [expr {$newRow - 1}]]} {
	    moveOneLineUp $w $newRow
	}
    } else {
	moveOneLineUp $w $data(itemCount)
    }
}

#------------------------------------------------------------------------------
# tablelist::genMouseWheelEvent
#
# Generates a <MouseWheel> event with the given delta on the widget w.
#------------------------------------------------------------------------------
proc tablelist::genMouseWheelEvent {w delta} {
    set focus [focus -displayof $w]
    focus $w
    event generate $w <MouseWheel> -delta $delta
    focus $focus
}

#
# Private utility procedures related to interactive cell editing
# ==============================================================
#

#------------------------------------------------------------------------------
# tablelist::saveEntryData
#
# Saves some data of the entry widget associated with the tablelist win.
#------------------------------------------------------------------------------
proc tablelist::saveEntryData win {
    upvar ::tablelist::ns${win}::data data

    #
    # Configuration options
    #
    set w $data(bodyFrEnt)
    foreach configSet [$w configure] {
	if {[llength $configSet] != 2} {
	    set opt [lindex $configSet 0]
	    set data(entry$opt) [lindex $configSet 4]
	}
    }

    #
    # Widget callbacks
    #
    if {[info exists ::wcb::version]} {
	foreach when {before after} {
	    foreach opt {insert delete motion} {
		set data(entryCb-$when-$opt) [::wcb::callback $w $when $opt]
	    }
	}
    }

    #
    # Other data
    #
    set data(entryText) [$w get]
    set data(entryPos)  [$w index insert]
    if {[set data(entryHadSel) [$w selection present]]} {
	set data(entrySelFrom) [$w index sel.first]
	set data(entrySelTo)   [$w index sel.last]
    }
    set data(entryHadFocus) \
	[expr {[string compare [focus -lastfor $w] $w] == 0}]
}

#------------------------------------------------------------------------------
# tablelist::restoreEntryData
#
# Saves some data of the entry widget associated with the tablelist win.
#------------------------------------------------------------------------------
proc tablelist::restoreEntryData win {
    upvar ::tablelist::ns${win}::data data

    #
    # Configuration options
    #
    set w $data(bodyFrEnt)
    foreach name [array names data entry-*] {
	set opt [string range $name 5 end]
	$w configure $opt $data($name)
    }

    #
    # Widget callbacks
    #
    if {[info exists ::wcb::version]} {
	foreach when {before after} {
	    foreach opt {insert delete motion} {
		eval [list ::wcb::callback $w $when $opt] \
		     $data(entryCb-$when-$opt)
	    }
	}
    }

    #
    # Other data
    #
    $w insert 0 $data(entryText)
    $w icursor $data(entryPos)
    if {$data(entryHadSel)} {
	$w selection range $data(entrySelFrom) $data(entrySelTo)
    }
    if {$data(entryHadFocus)} {
	focus $w
    }
}

#------------------------------------------------------------------------------
# tablelist::parseEntryPath
#
# Extracts the path name of the tablelist widget from the path name w of the
# embedded entry widget.
#------------------------------------------------------------------------------
proc tablelist::parseEntryPath w {
    regexp {^(.+)\.body\.f\.e$} $w dummy win
    return $win
}
