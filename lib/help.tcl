#==========================================================
# Help --
#
#   provides a hyperlinked help system
#
#==========================================================
#
namespace eval Help {}


#----------------------------------------------------------
# ::Help::findLink
#
#   determines if a tag is a link or not, loads it if it is
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Help::findLink {} {

    foreach tagname [.pgaw:Help.f.t tag names current] {
        if {$tagname!="link"} {
            ::Help::load $tagname
            return
        }
    }

}

proc ::Help::replace_escaped_items {str} {
    set index [string first "\\" $str 0]
    while {$index != -1} {
	set str [string replace $str $index $index]
        set index [string first "\\" $str 0]
    }
    return $str
}

#----------------------------------------------------------
# ::Help::display_tex_line
#
#   displays a tex formatted line in the help window
#
# Arguments:
#
#   l		the formatted line
#   start	the starting point
#   end		the end point
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Help::display_tex_line {l} {
		if [string equal $l {}] {
		    .pgaw:Help.f.t insert end "\n\n\t"
		} elseif {[string index $l 0] == "\%"} {
		} elseif {[string range $l 1 10] == "newcommand"} {
		} else {
		    set start 0
		    set new_start [string first "\\" $l $start]
		    while {$new_start != -1} {
			.pgaw:Help.f.t insert end [string range $l $start [expr $new_start - 1]]
			set next_char [string index $l [expr $new_start + 1]]
			if {![string is alpha -strict $next_char]} {
			    .pgaw:Help.f.t insert end $next_char
			    set start [expr $new_start + 2]
			    set new_start [string first "\\" $l $start]
			    continue
			}
			set env_str_start [expr $new_start + 1]
			set env_str_end [expr [string wordend $l $env_str_start] - 1]
			set env_str [string range $l $env_str_start $env_str_end]
			set env_val_start [expr $env_str_end + 1]
			if {[string index $l $env_val_start] == "\{"} {
			    set env_val_end [string first "\}" $l $env_val_start]
			    set env_val [string range $l [expr $env_val_start + 1] [expr $env_val_end - 1]]
			    set env_val [replace_escaped_items $env_val]
			} elseif {[string index $l $env_val_start] == "\["} {
			    set env_val_end [string first "\]" $l $env_val_start]
			    set env_val [string range $l [expr $env_val_start + 1] [expr $env_val_end - 1]]
			    set env_val [replace_escaped_items $env_val]
			} else {
			    set env_val_end $env_val_start
			    set env_val ""
			}
			set env_val2_start [expr $env_val_end + 1]
			if {[string index $l $env_val2_start] == "\{"} {
			    set env_val2_end [string first "\}" $l $env_val2_start]
			    set env_val2 [string range $l [expr $env_val2_start + 1] [expr $env_val2_end - 1]]
			    set env_val2_end [expr $env_val2_end + 1]
			    set env_val2 [replace_escaped_items $env_val2]
			} else {
			    set env_val2_end $env_val2_start
			    set env_val2 ""
			}
			switch $env_str {
			    "documentclass"	{}
			    "usepackage"	{}
			    "maketitle"		{}
			    "newcommand"	{}
			    "tableofcontents"	{}
			    "newpage"		{}
			    "input"		{}
			    "title"		{.pgaw:Help.f.t insert end "\n" normal $env_val maintitle "\n\n\t"}
			    "section"		{.pgaw:Help.f.t insert end "\n" normal $env_val title "\n\n\t"}
			    "subsection"	{.pgaw:Help.f.t insert end "\n" normal $env_val subtitle "\n\n\t"}
			    "label"		{}
			    "begin"		{}
			    "end"		{
						    if {$env_val == "itemize"} {
							.pgaw:Help.f.t insert end "\n\t"
						    } elseif {$env_val == "description"} {
							.pgaw:Help.f.t insert end "\n\t"
						    }
						}
			    "emph"		{.pgaw:Help.f.t insert end $env_val italic}
			    "textbf"		{.pgaw:Help.f.t insert end $env_val bold}
			    "textit"		{.pgaw:Help.f.t insert end $env_val italic}
			    "texttt"		{.pgaw:Help.f.t insert end $env_val code}
			    "htmlref"		{.pgaw:Help.f.t insert end $env_val "link $env_val2"}
			    "item"		{
						    if {$env_val == ""} {
							.pgaw:Help.f.t insert end "\n\t\t* " italic
						    } else {
							.pgaw:Help.f.t insert end "\n\t\t$env_val " italic
						    }
						}
			    "topics"		{.pgaw:Help.f.t insert end "Topics available:\n"}
			    "topic"		{.pgaw:Help.f.t insert end "\n\t\t* " italic}
			    "docinsert"		{.pgaw:Help.f.t insert end $env_val "link $env_val2"}
			    "LaTeX"		{.pgaw:Help.f.t insert end LaTeX}
			    default		{::debug "ERROR: Unknown tex command '$env_str'"}
			}
			set start $env_val2_end
			set new_start [string first "\\" $l $start]
		    }
		    .pgaw:Help.f.t insert end [replace_escaped_items [string range $l $start end]]
		    if {$start < [string length $l]} {
			.pgaw:Help.f.t insert end " "
		    }
		}
}

#----------------------------------------------------------
# ::Help::load
#
#   loads the help info for a link
#
# Arguments:
#
#   topic_  the help topic to load
#   args_   name of the previous help topic, if any
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Help::load {topic_ {args_ ""}} {

    global PgAcVar

    if {![winfo exists .pgaw:Help]} {
        Window show .pgaw:Help
        tkwait visibility .pgaw:Help
    }
    wm deiconify .pgaw:Help

    .pgaw:Help.fb.tex configure -text ""

    if {![info exists PgAcVar(help,history)]} {
        set PgAcVar(help,history) {}
    }

    if {[llength $args_]==1} {
        set PgAcVar(help,current_topic) [lindex $args_ 0]
        set PgAcVar(help,history) [lrange $PgAcVar(help,history) 0 [lindex $args_ 0]]
    } else {
        lappend PgAcVar(help,history) $topic_
        set PgAcVar(help,current_topic) [expr {[llength $PgAcVar(help,history)]-1}]
    }

    # Limit the history length to 100 topics
    if {[llength $PgAcVar(help,history)]>100} {
        set PgAcVar(help,history) [lrange $PgAcVar(help,history) 1 end]
    }

    .pgaw:Help.f.t configure -state normal
    .pgaw:Help.f.t delete 1.0 end
    .pgaw:Help.f.t tag configure normal -font $PgAcVar(pref,font_normal)
    .pgaw:Help.f.t tag configure bold -font $PgAcVar(pref,font_bold)
    .pgaw:Help.f.t tag configure italic -font $PgAcVar(pref,font_italic)
    .pgaw:Help.f.t tag configure large -font {Helvetica -14 bold}
    .pgaw:Help.f.t tag configure title -font $PgAcVar(pref,font_bold) -justify center
    .pgaw:Help.f.t tag configure maintitle -font {Helvetica -16 bold} -justify center
    .pgaw:Help.f.t tag configure subtitle -font $PgAcVar(pref,font_bold)
    .pgaw:Help.f.t tag configure link -font {Helvetica -14 underline} -foreground #000080
    .pgaw:Help.f.t tag configure code -font $PgAcVar(pref,font_fix)
    .pgaw:Help.f.t tag configure warning -font $PgAcVar(pref,font_bold) -foreground #800000
    .pgaw:Help.f.t tag bind link <Button-1> {Help::findLink}
    set errmsg {}
    .pgaw:Help.f.t configure -tabs {30 60 90 120 150 180 210 240 270 300 330 360 390}
    catch {
    	if {! [file exists [file join $PgAcVar(PGACCESS_HOME) lib help $topic_.tex]]} {
		source [file join $PgAcVar(PGACCESS_HOME) lib help $topic_.hlp]
	} else {
	    set fd [open [file join $PgAcVar(PGACCESS_HOME) lib help $topic_.tex] r]
	    set str [read $fd]
	    close $fd
	    .pgaw:Help.fb.tex configure -text "tex"
	    set lines [split $str \n]
	    set i 0
	    foreach l $lines {
		set l [string trim $l]
		display_tex_line $l
	    }
	}
    } errmsg
    if {$errmsg!=""} {
        .pgaw:Help.f.t insert end "Error loading help file [file join $PgAcVar(PGACCESS_HOME) $topic_.hlp]\n\n$errmsg" bold
    }
    .pgaw:Help.f.t configure -state disabled
    focus .pgaw:Help.f.sb
}


#----------------------------------------------------------
# ::Help::back --
#
#   moves backwards in the help topics list
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Help::back {} {
global PgAcVar

    if {![info exists PgAcVar(help,history)]} {return}
    if {[llength $PgAcVar(help,history)]==0} {return}
    set i $PgAcVar(help,current_topic)
    if {$i<1} {return}
    incr i -1

    ::Help::load [lindex $PgAcVar(help,history) $i] $i

}



#==========================================================
# END HELP NAMESPACE
# BEGIN VISUAL TCL CODE
#==========================================================



proc vTclWindow.pgaw:Help {base} {
global PgAcVar

    if {$base == ""} {
        set base .pgaw:Help
    }

    if {[winfo exists $base]} {
        wm deiconify $base; return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    set sw [winfo screenwidth .]
    set sh [winfo screenheight .]
    set x [expr {($sw - 640)/2}]
    set y [expr {($sh - 480)/2}]

    wm geometry $base 640x480+$x+$y
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Help"]
    bind $base <Key-Escape> "Window destroy .pgaw:Help"

    frame $base.fb \
        -borderwidth 2 -height 75 -relief groove -width 125
    button $base.fb.bback \
        -command Help::back -padx 9 -pady 3 -text [intlmsg Back]
    button $base.fb.bi \
        -command {Help::load index} -padx 9 -pady 3 -text [intlmsg Index]
    button $base.fb.bp \
        -command {Help::load postgresql} -padx 9 -pady 3 -text PostgreSQL
    button $base.fb.bd \
        -command {Help::load develop} -padx 9 -pady 3 -text Development
    button $base.fb.btnclose \
        -command {Window destroy .pgaw:Help} -padx 9 -pady 3 -text [intlmsg Close]
    frame $base.f \
        -borderwidth 2 -height 75 -relief groove -width 125
    text $base.f.t \
        -borderwidth 1 -cursor {} -font $PgAcVar(pref,font_normal) -height 2 \
        -highlightthickness 0 -state disabled \
        -tabs {30 60 90 120 150 180 210 240 270 300 330 360 390} -width 8 \
        -wrap word -yscrollcommand {.pgaw:Help.f.sb set}
    scrollbar $base.f.sb \
        -borderwidth 1 -command {.pgaw:Help.f.t yview} -highlightthickness 0 \
        -orient vert

    pack $base.fb \
        -in .pgaw:Help -anchor center -expand 0 -fill x -side top
    pack $base.fb.bback \
        -in .pgaw:Help.fb -anchor center -expand 0 -fill none -side left
    pack $base.fb.bi \
        -in .pgaw:Help.fb -anchor center -expand 0 -fill none -side left
    pack $base.fb.bp \
        -in .pgaw:Help.fb -anchor center -expand 0 -fill none -side left
    pack $base.fb.bd \
        -in .pgaw:Help.fb -anchor center -expand 0 -fill none -side left
#####
# just for debug purposes
    label $base.fb.tex
    pack $base.fb.tex \
        -in .pgaw:Help.fb -anchor center -expand 0 -fill none -side left
#####
    pack $base.fb.btnclose \
        -in .pgaw:Help.fb -anchor center -expand 0 -fill none -side right
    pack $base.f \
        -in .pgaw:Help -anchor center -expand 1 -fill both -side top
    pack $base.f.t \
        -in .pgaw:Help.f -anchor center -expand 1 -fill both -side left
    pack $base.f.sb \
        -in .pgaw:Help.f -anchor center -expand 0 -fill y -side right

}

