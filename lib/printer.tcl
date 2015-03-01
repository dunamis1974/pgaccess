#==========================================================
# Printer --
#
#   generic interface for printing from PGA
#
#==========================================================
#
namespace eval Printer {
    variable width
    variable height
    variable total_pages
    variable output_format
    variable print_cmd "|lpr"
    variable callback
    variable canvase
    variable anchor
    variable rotate
    variable copies 1
    variable Win
}


#==========================================================
# USER INTERFACE
#==========================================================


#----------------------------------------------------------
# printStart --
#
#   initialize common print parameters for any output format
#   then call the specific start proc for a particular format
#
# Arguments:
#   ch_         the channel to write output to
#   width_      the printed width of the page
#   height_     the printed height of the page
#   pgtot_      the total number of pages to print
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStart {ch_ width_ height_ pgtot_} {

    variable width
    variable height
    variable total_pages
    variable output_format

    set width $width_
    set height $height_
    set total_pages $pgtot_
    printStart$output_format $ch_

}; # end proc ::Printer::printStart


#----------------------------------------------------------
# printStop --
#
#   stops printing on the specified channel by calling the
#   format specific print stop proc
#
# Arguments:
#   ch_     the channel to stop printing output to
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStop {ch_} {

    variable output_format

    printStop$output_format $ch_

}; # end proc ::Printer::printStop


#----------------------------------------------------------
# printStartPage --
#
#   starts printing one specific page
#
# Arguments:
#   ch_     the channel to print the page on
#   pg_     the page number to print
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStartPage {ch_ pg_} {

    variable output_format

    printStartPage$output_format $ch_ $pg_

}; # end proc ::Printer::printStartPage


#----------------------------------------------------------
# printStopPage --
#
#   finishes printing one specific page
#
# Arguments:
#   ch_     the channel to finish printing the page on
#   pg_     the page number
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStopPage {ch_ pg_} {

    variable output_format

    printStopPage$output_format $ch_ $pg_

}; # end proc ::Printer::printStopPage


#----------------------------------------------------------
# printPage --
#
#   prints a specific page given its canvas
#
# Arguments:
#   ch_     the channel to print the page on
#   pg_     the page number to print
#   canvas_ the canvas from the page
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printPage {ch_ pg_ canvas_} {

    variable output_format
    variable total_pages

    printPage$output_format $ch_ $pg_ $canvas_

}; # end proc ::Printer::printPage


#----------------------------------------------------------
# init --
#
#   called by module wanting to print
#   module must provide a callback function in order for printing to do anything
#   that callback should take an open channel as a parameter,
#   and stuff it with canvases
#
# Arguments:
#   callback_   a procedure to call to get output to print
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::init {callback_} {

    global PgAcVar
    variable callback
    variable output_format
    variable print_cmd

    set callback $callback_
    set output_format "PS"
    # try to listen to the preferences
    if {[info exists PgAcVar(pref,print_cmd)]} {
        set print_cmd $PgAcVar(pref,print_cmd)
    }
    # BUT always obey the command line
    if {[info exists PgAcVar(PGACCESS_PRINTCMD)]} {
        set print_cmd $PgAcVar(PGACCESS_PRINTCMD)
    }

    Window show .pgaw:PrinterSettings
    tkwait visibility .pgaw:PrinterSettings

}; # end proc ::Printer::init


#----------------------------------------------------------
# initCanvas --
#
#   just prints one canvas
#
# Arguments:
#   canvas_     the canvas to print
#   width_      the width of the canvas
#   height_     the height of the canvas
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::initCanvas {canvas_ width_ height_} {

    variable width
    variable height
    variable total_pages
    variable canvase

    set width $width_
    set height $height_
    set total_pages 1
    set canvase $canvas_

    ::Printer::init "::Printer::defaultCallback"

}; # end proc ::Printer::init


#----------------------------------------------------------
# defaultCallback --
#
#   us if we just want to print one canvas
#
# Arguments:
#   ch_     the channel to print on
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::defaultCallback {ch_} {

    variable width
    variable height
    variable canvase
    variable total_pages

    ::Printer::printStart $ch_ $width $height $total_pages
    ::Printer::printPage $ch_ $total_pages $canvase
    ::Printer::printStop $ch_

}; # end proc ::Printer::defaultCallback


#==========================================================
# GUI
#==========================================================


#----------------------------------------------------------
# print --
#
#   opens the channel and calls the callback to feed it with postscript
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::print {} {

    variable print_cmd
    variable callback
    variable Win

    variable print_ch

    set print_ch $print_cmd

    if {[catch {::open $print_ch "w" } print_ch]} {
        return -code error "Error: Unable to open '$print_cmd' for writing\n"
    }
    if {[string first "\{" $callback]!=-1} {
        foreach cbcmd $callback {
            eval [subst $cbcmd]
        }
    } elseif {$callback!=""} {
        $callback $print_ch
    }
    ::close $print_ch
    Window destroy $Win(settings)

}; # end proc ::Printer::print


#----------------------------------------------------------
# browseFiles --
#
#   simple file browser for files
#   also used to browse commands
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::browseFiles {} {

    variable Win
    variable print_cmd

    set types {
        {{Postscript Files}    {.ps}}
        {{HTML Files}    {.html}}
        {{Text Files}    {.txt}}
        {{All Files}    *}
    }

    if {[catch {tk_getSaveFile \
        -parent $Win(settings) \
        -defaultextension .ps \
        -filetypes $types \
        -title [intlmsg "Print to File or Select a Command"]} print_cmd] || [string match {} $print_cmd]} return

}; # end proc ::Printer::browseFiles


#==========================================================
# INTERNAL HELPERS
#==========================================================


#----------------------------------------------------------
# sortCanvas --
#
#   returns a list of the canvas widget ids in x,y order from nw to se
#
# Arguments:
#   canvas_     the canvas to sort
#
# Returns:
#   scanvas     the sorted canvas
#----------------------------------------------------------
#
proc ::Printer::sortCanvas {canvas_} {
    set scanvas {}
    foreach obj [$canvas_ find all] {
        set bb [$canvas_ bbox $obj]
        if {[$canvas_ itemcget $obj -anchor]=="nw"} then {set x [expr [lindex $bb 0]+1]} else {set x [expr [lindex $bb 2]-2]}
        set y [lindex $bb 1]
        set c 0
        foreach sobj $scanvas {
            set sbb [$canvas_ bbox $sobj]
            if {[$canvas_ itemcget $sobj -anchor]=="nw"} then {set sx [expr [lindex $sbb 0]+1]} else {set sx [expr [lindex $sbb 2]-2]}
            set sy [lindex $sbb 1]
            if { $sx>$x && $sy>$y } {
                break
            }
            incr c
        }
        set scanvas [linsert $scanvas $c $obj]
    }
    return $scanvas

}; # end proc ::Printer::sortCanvas


#==========================================================
# HTML
#==========================================================


#----------------------------------------------------------
# printPageHTML --
#
#   prints a page in HTML format
#
# Arguments:
#   ch_     channel to print on
#   pg_     page number to print
#   canvas_ canvas to print
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printPageHTML {ch_ pg_ canvas_} {

    printStartPageHTML $ch_ $pg_

    set scanvas [sortCanvas $canvas_]
    set oldy 0

    foreach obj $scanvas {
        set bb [$canvas_ bbox $obj]
        set w [expr [lindex $bb 2]-[lindex $bb 0]]
        set y [lindex $bb 1]
        if {$oldy==0} {set oldy $y}
        set str ""
        if {[$canvas_ type $obj]=="text"} {
            set font [split [$canvas_ itemcget $obj -font] "-"]
            append str "<font face='" [lindex $font 2] "'"
            append str " point-size='" [expr round([lindex $font 8]/10)] "'"
            append str ">"
            if {[lindex $font 3]=="Bold"} {
                append str "<b>"
            }
            if {[lindex $font 4]=="O"} {
                append str "<i>"
            }
            append str [$canvas_ itemcget $obj -text]
            if {[lindex $font 4]=="O"} {
                append str "</i>"
            }
            if {[lindex $font 3]=="Bold"} {
                append str "</b>"
            }
            append str "</font>"
        }
        if {[$canvas_ type $obj]=="image"} {
            append str "<img src='"
            append str [[$canvas_ itemcget $obj -image] cget -file]
            append str "'>"
        }
        if {[expr abs($y-$oldy)]<10} {
            puts $ch_ "<td width=$w>$str</td>"
        } else {
            puts $ch_ "</tr>"
            puts $ch_ "<tr>"
            puts $ch_ "<td width=$w>$str</td>"
        }
        set oldy $y
    }

    printStopPageHTML $ch_ $pg_

}; # end proc ::Printer::printPageHTML


#----------------------------------------------------------
# printStartHTML --
#
#   starts a page of HTML using proper tags
#
# Arguments:
#   ch_     channel to print on
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStartHTML {ch_} {

    puts $ch_ "<html>"
    puts $ch_ "<head><title>PgAccess Report</title></head>"
    puts $ch_ "<body>"

}; # end proc ::Printer::printStartHTML


#----------------------------------------------------------
# printStopHTML --
#
#   stops printing a page of HTML by closing the tags
#
# Arguments:
#   ch_     the channel to print on
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStopHTML {ch_} {

    puts $ch_ "</body>"
    puts $ch_ "</html>"

}; # end proc ::Printer::printStopHTML


#----------------------------------------------------------
# printStartPageHTML --
#
#   puts each new page in a separate table
#
# Arguments:
#   ch_     channel to print on
#   pg_     not used but required by interface
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStartPageHTML {ch_ pg_} {

    puts $ch_ "<table border=1>"
    puts $ch_ "<tr>"

}; # end proc ::Printer::printStartPageHTML


#----------------------------------------------------------
# printStopPageHTML --
#
#   closes out the table and leaves a little space
#   for the next page
#
# Arguments:
#   ch_     channel to print on
#   pg_     not used but required by the interface
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStopPageHTML {ch_ pg_} {

    puts $ch_ "</tr>"
    puts $ch_ "</table>"
    puts $ch_ "<p>"

}; # end proc ::Printer::printStopPageHTML


##########################################
# Text
##########################################


#----------------------------------------------------------
# printPageTEXT --
#
#   prints a page of text
#
# Arguments:
#   ch_     channel to print on
#   pg_     page to print
#   canvas_ canvas to print from
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printPageTEXT {ch_ pg_ canvas_} {

    printStartPageTEXT $ch_ $pg_

    set scanvas [sortCanvas $canvas_]
    set oldy 0

    foreach obj $scanvas {
        set bb [$canvas_ bbox $obj]
        if {[$canvas_ itemcget $obj -anchor]=="nw"} {
            set x [expr [lindex $bb 0]+1]
        } else {
            set x [expr [lindex $bb 2]-2]
        }
        set y [lindex $bb 1]
        if {$oldy==0} {set oldy $y}
        set x [expr round($x/10)]
        set str ""
        for {set i 0} {$i<$x} {incr i} {append str " "}
        if {[$canvas_ type $obj]=="text"} {
            append str [$canvas_ itemcget $obj -text]
        }
        if {[$canvas_ type $obj]=="image"} {
            append str "IMAGE"
        }
        if {[expr abs($y-$oldy)]<10} {
            puts -nonewline $ch_ $str
        } else {
            puts $ch_ ""
            puts -nonewline $ch_ $str
        }
        set oldy $y
    }

    printStopPageTEXT $ch_ $pg_

}; # end proc ::Printer::printPageTEXT


#----------------------------------------------------------
# printStartTEXT --
#
#   starts printing out a report as text output
#
# Arguments:
#   ch_     channel to print on
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStartTEXT {ch_} {

    variable total_pages

    puts $ch_ "PgAccess Report"
    puts $ch_ "Pages: $total_pages"
    puts $ch_ ""

}; # end proc ::Printer::printStartTEXT


#----------------------------------------------------------
# printStopTEXT --
#
#   finishes the report with the appropriate end chars
#
# Arguments:
#   ch_     channel to print on
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStopTEXT {ch_} {

    puts $ch_ ""
    puts $ch_ ""
    puts $ch_ "###"

}; # end proc ::Printer::printStopTEXT


#----------------------------------------------------------
# printStartPageTEXT --
#
#   starts printing one page of text by labelling it as such
#
# Arguments:
#   ch_     channel to print on
#   pg_     page number to print
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStartPageTEXT {ch_ pg_} {

    variable total_pages

    puts $ch_ ""
    puts $ch_ "Page: $pg_ of $total_pages"
    puts $ch_ ""

}; # end proc ::Printer::printStopTEXT


#----------------------------------------------------------
# printStopPageTEXT --
#
#   not really sure what we should print on the bottom of each
#   page, maybe the date ?
#
# Arguments:
#   ch_     channel to print on
#   pg_     page number to stop printing
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStopPageTEXT {ch_ pg_} {

}; # end proc ::Printer::printStopPageTEXT


##########################################
# Postscript
##########################################


#----------------------------------------------------------
# printPagePS --
#
#   takes care of starting and stopping a postscript page, plus cleaning
#   so that encapsulated postscript may be put in one page of postscript
#
# Arguments:
#   ch_     channel to print on
#   pg_     page number to print
#   canvas_ canvas to print
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printPagePS {ch_ pg_ canvas_} {

    variable width
    variable height
    variable anchor
    variable rotate

    printStartPagePS $ch_ $pg_
    printCleanPS $ch_ [$canvas_ postscript -width $width -height $height -pagex 0 -pagey 0 -pageanchor $anchor -rotate $rotate]
    printStopPagePS $ch_ $pg_

}; # end proc ::Printer::printPagePS


#----------------------------------------------------------
# printStartPS --
#
#   header for postscript output
#
# Arguments:
#   ch_     channel to print on
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStartPS {ch_} {

    variable width
    variable height
    variable total_pages

    puts $ch_ "%!PS-Adobe-3.0"
    puts $ch_ "%%Creator: PgAccess"
    puts $ch_ "%%LanguageLevel: 2"
    puts $ch_ "%%Title: Report"
    puts $ch_ "%%CreationDate: [clock format [clock seconds]]"
    puts $ch_ "%%Pages: $total_pages"
    puts $ch_ "%%PageOrder: Ascend"
    puts $ch_ "%%BoundingBox: 0 0 $width $height"
    puts $ch_ "%%EndComments"
    puts $ch_ "/EncapDict 200 dict def EncapDict begin"
    puts $ch_ "/showpage {} def /erasepage {} def /copypage {} def end"
    puts $ch_ "%%EndProlog"

}; # end proc ::Printer::printStartPS


#----------------------------------------------------------
# printStopPS --
#
#   terminate the postscript
#
# Arguments:
#   ch_     channel to print on
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStopPS {ch_} {

    puts $ch_ "%%EOF"

}; # end proc ::Printer::printStopPS


#----------------------------------------------------------
# printStartPagePS --
#
#   start a new page of postscript
#
# Arguments:
#   ch_     channel to print on
#   pg_     page number to print
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStartPagePS {ch_ pg_} {

    puts $ch_ "%%Page: $pg_ $pg_"
    puts $ch_ "save EncapDict begin"

}; # end proc ::Printer::printStartPagePS


#----------------------------------------------------------
# printStopPagePS --
#
#   finish a page of postscript
#
# Arguments:
#   ch_     channel to print on
#   pg_     page number to print
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printStopPagePS {ch_ pg_} {

    puts $ch_ "restore end showpage"

}; # end proc ::Printer::printStopPagePS


#----------------------------------------------------------
# printCleanPS --
#
#   rip stuff out of encapsulated postscript
#   so we can display regular old postscript
#
# Arguments:
#   ch_     channel to print on
#   ps_     postscript from a tk canvas that we need to clean
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Printer::printCleanPS {ch_ ps_} {

    set start [string first "%%BeginProlog\n" "$ps_"]
    set stop [expr [string first "%%EOF\n" "$ps_"] - 1]
    puts $ch_ "[stripCommentsPS [string range $ps_ $start $stop]]"

}; # end proc ::Printer::printCleanPS


#----------------------------------------------------------
# stripCommentsPS --
#
#   adapted from Bridge.tcl StripPSComments procedure 
#   by Robert Heller <Heller@deepsoft.com>
#   borrowed with permission
#
#   12/23/03 - modified by Chris Maj to fix printing of %'s
#
# Arguments:
#   ps_     postscript to strip comments from
#
# Returns:
#   stript  stripped postscript
#----------------------------------------------------------
#
proc ::Printer::stripCommentsPS {ps_} {

  set stript ""

  foreach l [split "$ps_" "\n"] {
    set i [string first "%" "$l$"]
    if {$i == 0} {
      append stript "\n"
    } elseif {$i > 0 && [regexp {(^.*[^\\])(.*$)} "$l" whole prefix comment]} {
      append stript "$prefix\n"
    } else {
      append stript "$l\n"
    }
  }

  return $stript

}; # end proc ::Printer::stripCommentsPS



#==========================================================
# END Printer NAMESPACE
# BEGIN VisualTcl
#==========================================================



proc vTclWindow.pgaw:PrinterSettings {base} {

    global PgAcVar Win

    if {$base == "" } {
        set base .pgaw:PrinterSettings
    }
    set ::Printer::Win(settings) $base

    if {[winfo exists $base]} {
        wm deiconify $base; return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 465x250+200+200
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm title $base [intlmsg "Print Settings"]

    frame $base.fcmd \
        -borderwidth 2 \
        -height 50 \
        -width 465 \
        -relief groove
    LabelEntry $base.fcmd.eprint_cmd \
        -label [intlmsg "Command or File"] \
        -textvariable ::Printer::print_cmd
    Button $base.fcmd.bbrowse \
        -text [intlmsg "Browse"] \
        -command ::Printer::browseFiles

    frame $base.fczr \
        -borderwidth 2 \
        -height 50 \
        -width 465 \
        -relief groove
    Label $base.fczr.lcopies \
        -text [intlmsg "Copies"]
    Label $base.fczr.lanchor \
        -text [intlmsg "Anchor"]
    Label $base.fczr.lrot \
        -text [intlmsg "Rotation"]
    SpinBox $base.fczr.ecopies \
        -state disabled \
        -range {1 999 1} \
        -width 5 \
        -textvariable ::Printer::copies
    ComboBox $base.fczr.cbanchor \
         -textvariable ::Printer::anchor \
         -values {sw w nw n ne e se s center} \
         -width 10 \
         -text sw
    ComboBox $base.fczr.cbrot \
         -textvariable ::Printer::rotate \
         -values {0 1} \
         -width 5 \
         -text 0

    frame $base.fout \
        -borderwidth 2 \
        -height 50 \
        -width 465 \
        -relief groove
    radiobutton $base.fout.rad_out_ps \
        -text [intlmsg {Postscript}] \
        -variable ::Printer::output_format \
        -value "PS"
    radiobutton $base.fout.rad_out_html \
        -text [intlmsg {HTML}] \
        -variable ::Printer::output_format \
        -value "HTML"
    radiobutton $base.fout.rad_out_text \
        -text [intlmsg {Text}] \
        -variable ::Printer::output_format \
        -value "TEXT"

    frame $base.fbtn \
        -borderwidth 5 \
        -height 50 \
        -width 465
    Button $base.fbtn.bprint \
        -text [intlmsg "Print"] \
        -command Printer::print
    Button $base.fbtn.bcancel \
        -text [intlmsg "Cancel"] \
        -command {Window destroy .pgaw:PrinterSettings}

    pack $base.fcmd \
        -in $base -anchor center -expand 1 -fill both -side top
    pack $base.fcmd.eprint_cmd \
        -in $base.fcmd -expand 1 -fill x -side left
    pack $base.fcmd.bbrowse \
        -in $base.fcmd -expand 0 -fill x -side left

    pack $base.fczr \
        -in $base -anchor center -expand 1 -fill both -side top
    pack $base.fczr.lcopies \
        -in $base.fczr -expand 1 -fill x -side left
    pack $base.fczr.ecopies \
        -in $base.fczr -expand 0 -fill x -side left
    pack $base.fczr.lanchor \
        -in $base.fczr -expand 1 -fill x -side left
    pack $base.fczr.cbanchor \
        -in $base.fczr -expand 0 -fill x -side left
    pack $base.fczr.lrot \
        -in $base.fczr -expand 1 -fill x -side left
    pack $base.fczr.cbrot \
        -in $base.fczr -expand 0 -fill x -side left

    pack $base.fout \
        -in $base -anchor center -expand 1 -fill both -side top
    pack $base.fout.rad_out_ps \
        -in $base.fout -expand 1 -fill both -side left -anchor center
    pack $base.fout.rad_out_html \
        -in $base.fout -expand 1 -fill both -side left -anchor center
    pack $base.fout.rad_out_text \
        -in $base.fout -expand 1 -fill both -side left -anchor center

    pack $base.fbtn \
        -in $base -anchor center -expand 0 -fill none -side bottom
    pack $base.fbtn.bprint \
        -in $base.fbtn -expand 0 -fill none -side left
    pack $base.fbtn.bcancel \
        -in $base.fbtn -expand 0 -fill none -side left

}
