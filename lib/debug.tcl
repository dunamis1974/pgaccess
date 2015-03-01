#==========================================================
# Debug --
#
#   tool for debug purposes
#
#==========================================================
#
namespace eval Debug {
    variable var
    variable command
}

proc ::Debug::open {} {
	Window show .pgaw:Debug
}

proc ::Debug::dispVar {} {

    uplevel #0 {
    if {![info exists $::Debug::var]} {
	set val "DOES NOT EXIST"
    } else {
	set val [set $::Debug::var]
    }

    .pgaw:Debug.fs.text1 delete 0.0 end
    .pgaw:Debug.fs.text1 insert 0.0 "$::Debug::var = $val"
    }

    return
    
}; #end proc ::Debug::dispVar



proc vTclWindow.pgaw:Debug {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:Debug
    }

    if {[winfo exists $base]} {
        wm deiconify $base; return
    }

    toplevel $base -class Toplevel

    wm geometry $base 400x400+100+100
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Debug"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    bind $base <Escape> {Window destroy .pgaw:Debug}

    #
    # main window
    #
    frame $base.fp
    label $base.fp.l1 \
        -borderwidth 0 \
        -relief raised \
        -text [intlmsg Command]

    entry $base.fp.e1 \
        -background #fefefe \
        -borderwidth 1 \
        -textvariable ::Debug::command \
        -width 40
    bind $base.fp.e1 <Key-Return> {
		.pgaw:Debug.fs.text1 delete 0.0 end
		.pgaw:Debug.fs.text1 insert 0.0 [eval $::Debug::command]
    }

    label $base.fp.l2 \
        -borderwidth 0 \
        -relief raised \
        -text [intlmsg Variable]

    entry $base.fp.e2 \
        -background #fefefe \
        -borderwidth 1 \
        -textvariable ::Debug::var 
    bind $base.fp.e2 <Key-Return> {::Debug::dispVar}

    button $base.fp.debug \
	-command {
		.pgaw:Debug.fs.text1 delete 0.0 end
		.pgaw:Debug.fs.text1 insert 0.0 $PgAcVar(DEBUG_STR)
	} \
	-borderwidth 1 \
	-text [intlmsg "Debug messages"]

    #
    # new frame
    #
    frame $base.fs 

    text $base.fs.text1 \
        -background #fefefe \
        -foreground #000000 \
        -borderwidth 1 \
        -font $PgAcVar(pref,font_fix) \
        -tabs {20 40 60 80 100 120} \
        -yscrollcommand {.pgaw:Debug.fs.vsb set}

    scrollbar $base.fs.vsb \
        -borderwidth 1 \
        -command {.pgaw:Debug.fs.text1 yview} \
        -orient vert

    #
    # button frames
    #
    pack $base.fp \
        -in .pgaw:Debug -anchor center -expand 0 -fill x -side top 

    grid $base.fp.l1 \
        -in .pgaw:Debug.fp -column 0 -row 0 -columnspan 1 -sticky w 
    grid $base.fp.e1 \
        -in .pgaw:Debug.fp -column 1 -row 0 -columnspan 1 -sticky ew
    grid $base.fp.l2 \
        -in .pgaw:Debug.fp -column 0 -row 1 -columnspan 1 -sticky w 
    grid $base.fp.e2 \
        -in .pgaw:Debug.fp -column 1 -row 1 -columnspan 1 -sticky ew
    grid $base.fp.debug \
        -in .pgaw:Debug.fp -column 0 -row 2 -columnspan 1 -columnspan 2

    pack $base.fs \
        -in .pgaw:Debug -anchor center -expand 1 -fill both -side top 
    pack $base.fs.text1 \
        -in .pgaw:Debug.fs -anchor center -expand 1 -fill both -side left 
    pack $base.fs.vsb \
        -in .pgaw:Debug.fs -anchor center -expand 0 -fill y -side right 

}
