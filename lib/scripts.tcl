#==========================================================
# Scripts --
#
#   allows for inclusion of lots of Tcl code into small apps
#
#==========================================================
#
namespace eval Scripts {
    variable Win
    variable xprintsize
    variable yprintsize
}


#----------------------------------------------------------
# ::Scripts::new --
#
#   A new script will open a window to design a nameless script.
#
# Arguments:
#   none
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::Scripts::new {} {
    design {}
}; # end proc ::Scripts::new


#----------------------------------------------------------
# ::Scripts::open --
#
#   Evaluates the script commands.
#   Scripts are only retrieved from the database once.
#
# Arguments:
#   scriptname_     The name of the script
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::Scripts::open {scriptname_} {
global CurrentDB PgAcVar

    set ss {}

    # check if script has already been cached
    if {[info exists PgAcVar(script,cache,$scriptname_)]} {
        set ss $PgAcVar(script,cache,$scriptname_)

    } else {
        wpg_select $CurrentDB "
            SELECT *
              FROM pga_scripts
             WHERE scriptname='$scriptname_'" \
        rec {
            set ss $rec(scriptsource)
            # cache the script
            set PgAcVar(script,cache,$scriptname_) $ss
        }
    }

    # evaluated either the new script or the cached version
    if {[string length $ss] > 0} {
        eval $ss
    }

}; # end proc ::Scripts::open


#----------------------------------------------------------
# ::Scripts::design --
#
#   The selected script will be opened for editing.
#
# Arguments:
#   scriptname_     The name of the script
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::Scripts::design {scriptname_} {
global PgAcVar CurrentDB

    Window show .pgaw:Scripts
    set PgAcVar(script,name) $scriptname_
    .pgaw:Scripts.src delete 1.0 end

    if {[string length $scriptname_]==0} return;

    wpg_select $CurrentDB "
        SELECT oid,*
          FROM pga_scripts
         WHERE scriptname='$scriptname_'" \
    rec {
        set PgAcVar(script,oid) $rec(oid)
        .pgaw:Scripts.src insert end $rec(scriptsource)
        ::Syntax::highlight .pgaw:Scripts.src tcl
    }

}; # end proc ::Scripts::design


#----------------------------------------------------------
# ::Scripts::execute --
#
#   A wrapper, passes execution to the open command.
#
# Arguments:
#   scriptname_     The name of the script
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::Scripts::execute {scriptname_} {
    # a wrap for execute command
    open $scriptname_
}; # end proc ::Scripts::execute


#----------------------------------------------------------
# ::Scripts::introspect --
#
#   Given a scriptname, returns the SQL needed to recreate
#   it.
#
# Arguments:
#   scriptname_ name of a script to introspect
#   dbh_        an optional database handle
#
# Returns:
#   insql       the INSERT statement to make this script
#----------------------------------------------------------
#
proc ::Scripts::introspect {scriptname_ {dbh_ ""}} {

    set insql [::Scripts::clone $scriptname_ $scriptname_ $dbh_]

    return $insql

}; # end proc ::Scripts::introspect


#----------------------------------------------------------
# ::Scripts::clone --
#
#   Like introspect, only changes the scriptname
#
# Arguments:
#   srcscript_  the original script
#   destscript_ the clone script
#   dbh_        an optional database handle
#
# Returns:
#   insql       the INSERT statement to clone this script
#----------------------------------------------------------
#
proc ::Scripts::clone {srcscript_ destscript_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set insql ""

    set sql "SELECT scriptsource
               FROM pga_scripts
              WHERE scriptname='$srcscript_'"

    wpg_select $dbh_ $sql rec {
        set insql "
            INSERT INTO pga_scripts (scriptsource, scriptname)
                 VALUES ('[::Database::quoteSQL $rec(scriptsource)]','[::Database::quoteSQL $destscript_]');"
    }

    return $insql

}; # end proc ::Scripts::clone


#----------------------------------------------------------
# ::Scripts::save --
#
#   Save checks if the script has a name
#   and if it is valid Tcl code.
#
# Arguments:
#   badtcl_         yes if Tcl code should be validated
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::Scripts::save {{badtcl_ {no}} {copy_ 0}} {
global PgAcVar CurrentDB

    if {$PgAcVar(script,name)==""} {
        tk_messageBox \
            -title [intlmsg Warning] \
            -parent .pgaw:Scripts \
            -message [intlmsg "The script must have a name!"]

    } elseif {![info complete [.pgaw:Scripts.src get 1.0 end]] \
    && $badtcl_=="no"} {

        set badtcl_ [tk_messageBox -title [intlmsg {Warning}] \
        -parent .pgaw:Scripts -type yesno \
        -message [intlmsg "There appears to be invalid Tcl code in the Script.  Are you sure you want to save it?"]]

        if {$badtcl_=="yes"} {::Scripts::save $badtcl_ $copy_}

    } else {

        if {$copy_ == 0 && [info exists PgAcVar(script,oid)]} {
            sql_exec noquiet "
                DELETE FROM pga_scripts
                      WHERE oid=$PgAcVar(script,oid)"
        }

        regsub -all {\\} [.pgaw:Scripts.src get 1.0 end] {\\\\} \
            PgAcVar(script,body)
        regsub -all ' $PgAcVar(script,body)  \\' PgAcVar(script,body)

        set sql "
            INSERT INTO pga_scripts
                 VALUES ('$PgAcVar(script,name)','$PgAcVar(script,body)')"
        sql_exec noquiet $sql

        # refresh the OID
        set sql "
            SELECT oid
              FROM pga_scripts
             WHERE scriptname='$PgAcVar(script,name)'"
        set res [wpg_exec $CurrentDB $sql]
        set PgAcVar(script,oid) [lindex [pg_result $res -getTuple 0] 0]
        pg_result $res -clear

        # highlight the tcl code
        ::Syntax::highlight .pgaw:Scripts.src tcl

        # refresh the list in the window
        ::Mainlib::cmd_Scripts

        # refresh the cache
        set PgAcVar(script,cache,$PgAcVar(script,name)) $PgAcVar(script,body)

    }

}; # end proc ::Scripts::save


#----------------------------------------------------------
# ::Scripts::print --
#
#   Creates a canvas for printing, and opens print dialog
#
# Arguments:
#   none
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::Scripts::print {} {

    global PgAcVar
    variable Win
    variable xprintsize
    variable yprintsize

    if {[info exists Win(tpc)]} {
        destroy $Win(tpc)
    }

    # turn text into canvas
    set Win(tpc) .pgaw:Scripts:PrintCanvas
    canvas $Win(tpc)
    $Win(tpc) create text 20 20 \
        -anchor nw \
        -font $PgAcVar(pref,font_bold) \
        -justify left \
        -width 800 \
        -text $PgAcVar(script,name)
    $Win(tpc) create text 20 40 \
        -anchor nw \
        -font $PgAcVar(pref,font_fix) \
        -justify left \
        -width 800 \
        -text [$Win(src) get 1.0 end]

    $Win(tpc) addtag printem all
    set geo [$Win(tpc) bbox printem]
    set xprintsize [expr {[lindex $geo 2] - [lindex $geo 0]}]
    set yprintsize [expr {[lindex $geo 3] - [lindex $geo 1]}]

    ::Printer::init "::Scripts::printcallback"

}; # end proc ::Scripts::print


#----------------------------------------------------------
# ::Scripts::printcallback --
#
#   Feeds a canvas to the printer
#
# Arguments:
#   fid     open file to stick with canvas
#
#
#----------------------------------------------------------
#
proc ::Scripts::printcallback {fid} {

    variable Win
    variable xprintsize
    variable yprintsize

    ::Printer::printStart $fid $xprintsize $yprintsize 1
    ::Printer::printPage $fid 1 $Win(tpc)
    ::Printer::printStop $fid

}; # end proc ::Scripts::printcallback



########################## END OF NAMESPACE SCRIPTS ##################



proc vTclWindow.pgaw:Scripts {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:Scripts
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 650x440+192+152
    wm maxsize $base 1009 738
    wm minsize $base 300 300
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm title $base [intlmsg "Design script"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Key-F1> "::Help::load scripts"

    LabelEntry $base.lescriptname \
        -borderwidth 1 \
        -textvariable PgAcVar(script,name) \
        -label [intlmsg {Script name}]

    ButtonBox $base.bbox \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $base.bbox add \
        -relief link \
        -borderwidth 1 \
        -command {::Scripts::save {no} 0} \
        -helptext [intlmsg "Save"] \
        -image ::icon::filesave-22
    $base.bbox add \
        -relief link \
        -borderwidth 1 \
        -command {::Scripts::save {no} 1} \
        -helptext [intlmsg "Save As"] \
        -image ::icon::filesaveas-22
    $base.bbox add \
        -relief link \
        -borderwidth 1 \
        -command {::Scripts::print} \
        -helptext [intlmsg "Print"] \
        -image ::icon::fileprint-22
    $base.bbox add \
        -relief link \
        -borderwidth 1 \
        -command {::Help::load scripts} \
        -helptext [intlmsg "Help"] \
        -image ::icon::help-22
    $base.bbox add \
        -relief link \
        -borderwidth 1 \
        -command {Window destroy .pgaw:Scripts} \
        -helptext [intlmsg "Close"] \
        -image ::icon::exit-22

    text $base.src  \
        -background #ffffff \
        -foreground #000000 \
        -font $PgAcVar(pref,font_normal) \
        -height 2 \
        -width 2 \
        -wrap none \
        -highlightthickness 1 \
        -selectborderwidth 0 \
        -xscrollcommand "$base.hscroll set" \
        -yscrollcommand "$base.vscroll set"
    set ::Scripts::Win(src) $base.src

    scrollbar $base.hscroll \
        -orient horiz \
        -command "$base.src xview"
    scrollbar $base.vscroll \
        -command "$base.src yview"

    bind $base <Escape> {
        Window destroy .pgaw:Scripts
    }
    bind $base.src <Control-Key-s> {
        ::Scripts::save
    }

    # searching with Ctrl-f
    bind $base.src <Control-Key-f> {
        set limit 100
        set fndtxt [parameter [intlmsg "Enter text to find:"]]
        set fndlen [string length $fndtxt]
        %W tag delete fndbind
        %W tag configure fndbind -background #ffff00
        if {$fndlen>0} {
            set fnd [%W search $fndtxt 1.0 end]
            if {[string length $fnd]>0} {
                %W see $fnd
                while {[string length $fnd]>0 && $limit>0} {
                    incr limit -1
                    %W tag add fndbind $fnd "$fnd + $fndlen chars"
                    set fnd [%W search $fndtxt "$fnd + $fndlen chars" end]
                }
            } else {
                tk_messageBox \
                    -parent %W \
                    -icon error \
                    -title [intlmsg "Failed"] \
                    -message [format [intlmsg "Couldn't find '%s'!"] $fndtxt]
            }
        }
    }

    # add Ctrl-x|c|v for cut, copy, paste
    bind $base.src <Control-Key-x> {
        set PgAcVar(shared,curseltext) [%W get sel.first sel.last]
        %W delete sel.first sel.last
    }
    bind $base.src <Control-Key-c> {
        set PgAcVar(shared,curseltext) [%W get sel.first sel.last]
    }
    bind $base.src <Control-Key-v> {
        if {[info exists PgAcVar(shared,curseltext)]} {
            catch {%W delete sel.first sel.last}
            %W insert insert $PgAcVar(shared,curseltext)
            %W see current
        }
    }

    grid $base.lescriptname \
        -row 0 \
        -column 0 \
        -sticky we
    grid $base.bbox \
        -row 0 \
        -column 1 \
        -columnspan 2 \
        -sticky e

    grid $base.hscroll \
        -row 2 \
        -column 0 \
        -columnspan 2 \
        -sticky wen
    grid $base.vscroll \
        -row 1 \
        -column 2 \
        -sticky swn
    grid $base.src \
        -row 1 \
        -column 0 \
        -columnspan 2 \
        -sticky news

    grid columnconfigure $base 0 \
        -weight 10
    grid columnconfigure $base 1 \
        -weight 10
    grid rowconfigure $base 1 \
        -weight 10

}
