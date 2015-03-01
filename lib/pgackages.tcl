#==========================================================
# PgAckages --
#
#   procedures for making small-app installation easier
#
#==========================================================
#
namespace eval PgAckages {
    variable Win
    variable filename
    variable usage
    variable pga_objs
    variable pg_objs
    variable dbconn
    variable dbhand
}


#----------------------------------------------------------
# ::PgAckages::init --
#
#   sets up window, whether we are saving or loading a package
#
# Arguments:
#   usage_  either "save" or "load"
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::PgAckages::init {usage_} {

    variable usage
    variable pga_objs
    variable pg_objs

    set usage $usage_

    foreach pgaobj [list "Queries" "Reports" "Graphs" "Forms" "Scripts" "Images" "Diagrams"] {
        set pga_objs($pgaobj) 1
    }

    foreach pgobj [list "Tables" "Views" "Sequences" "Functions"] {
        set pg_objs($pgobj) 1
    }

    Window show .pgaw:PgAckages:file
    tkwait visibility .pgaw:PgAckages:file

}; # end proc ::PgAckages::init


#----------------------------------------------------------
# ::PgAckages::save --
#
#   introspects the PG and PGA objects to create a new package
#
# Arguments:
#   none
#
# Results:
#   none
#----------------------------------------------------------
#
proc ::PgAckages::save {} {

    variable filename
    variable pga_objs
    variable pg_objs
    variable dbconn
    variable dbhand

    set ilist [list]

    # make sure we have a handle
    set dbhand [::Connections::getHandles $dbconn]

    # first we introspect the PGA objects
    foreach pgaobj [array names pga_objs] {
        if {$pga_objs($pgaobj)} {
            foreach item [::Database::getObjectsList $pgaobj $dbhand] {
                lappend ilist [::[subst {$pgaobj}]::introspect $item]
            }
        }
    }

    # next we introspect the PG objects
    # this has to be a little bit more anal than PGA stuff
    if {$pg_objs(Sequences)} {
        foreach item [::Database::getObjectsList Sequences $dbhand] {
            lappend ilist [::Sequences::introspect $item]
        }
    }
    if {$pg_objs(Tables)} {
        foreach item [::Database::getObjectsList Tables $dbhand] {
            # dont get pg_ or pga_ tables involved
            if {![string match "pg_*" [string trim $item "\""]] \
              && ![string match "pga_*" [string trim $item "\""]]} {
                lappend ilist [::Tables::introspect $item]
            }
        }
    }
    if {$pg_objs(Functions)} {
        foreach item [::Database::getObjectsList Functions $dbhand] {
            lappend ilist [::Functions::introspect $item]
        }
    }
    if {$pg_objs(Views)} {
        foreach item [::Database::getObjectsList Views $dbhand] {
            lappend ilist [::Views::introspect $item]
        }
    }

    catch {
        set fid [open $filename w]
        puts $fid \
"
--
-- PgAccess PgAckage
--
"
        foreach i $ilist {
            puts $fid \
"-- PGA"
            puts $fid $i

        }
        puts $fid \
"-- PGA"
        close $fid
    }

}; # end proc ::PgAckages::save


#----------------------------------------------------------
# ::PgAckages::load --
#
#   loads a package of PG and PGA objects into the database
#
# Arguments:
#   none
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::PgAckages::load {} {

    variable filename
    variable dbconn
    variable dbhand

    # make sure we have a handle
    set dbhand [::Connections::getHandles $dbconn]

    set retval [catch {set fid [open $filename r]} errmsg]
    if {! $retval} {
        set sql [read $fid [file size $filename]]
        close $fid
        set str "-- PGA"
        set sql [string trim [string range $sql [expr {[string first $str $sql]+[string length $str]}] end]]
        while {[string length $sql]>0} {
            set qry [string trim [string range $sql 0 [expr {[string first $str $sql]-1}]]]
            set sql [string trim [string range $sql [expr {[string first $str $sql]+[string length $str]}] end]]
            if {[string length $qry]>0} {
                sql_exec noquiet $qry $dbhand
                #puts "qry: $qry"
            }
        }
    }

    return $retval

}; # end proc ::PgAckages::load


#----------------------------------------------------------
# ::PgAckages::createFileBox --
#
#   sets up the file dialog to either load or save the package
#
# Arguments:
#   none
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::PgAckages::createFileBox {} {

    variable Win
    variable usage

    set types {
        {{PgAckage Files} {.pga}}
        {{All Files} *}
    }

    if {$usage == "load"} {
        if {[catch {tk_getOpenFile \
                -parent $::PgAckages::Win(fdlg) \
                -filetypes $types \
                -title [intlmsg {Load PgAckage}]} \
                ::PgAckages::filename] || \
                [string match {} $::PgAckages::filename]} return
    } else {
        if {[catch {tk_getSaveFile \
                -parent $::PgAckages::Win(fdlg) \
                -filetypes $types \
                -title [intlmsg {Save PgAckage}]} \
                ::PgAckages::filename] || \
                [string match {} $::PgAckages::filename]} return
    }

}; # end proc ::PgAckages::createFileBox



########## END NAMESPACE PgAckages



proc vTclWindow.pgaw:PgAckages:file {base} {

    global PgAcVar
    variable ::PgAckages::Win
    variable ::PgAckages::pga_objs
    variable ::PgAckages::pg_objs

    if {$base == "" } {
        set base .pgaw:PgAckages:file
    }

    set Win(fdlg) $base

    if {[winfo exists $base]} {
        wm deiconify $base
        return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 400x300+520+559
    wm maxsize $base 1265 994
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm title $base [intlmsg {PgAckages}]

    frame $base.ffile \
        -borderwidth 2 \
        -height 50 \
        -width 400
    LabelEntry $base.ffile.lefilename \
        -label [intlmsg {PgAckage File}] \
        -textvariable ::PgAckages::filename
    Button $base.ffile.bbrowse \
        -text [intlmsg {Browse}] \
        -command {
            ::PgAckages::createFileBox
        }
    pack $base.ffile \
        -in $base \
        -anchor center \
        -expand 1 \
        -fill x \
        -side top
    pack $base.ffile.lefilename \
        -in $base.ffile \
        -anchor center \
        -expand 1 \
        -fill x \
        -side left
    pack $base.ffile.bbrowse \
        -in $base.ffile \
        -anchor center \
        -expand 1 \
        -fill x \
        -side left

    frame $base.fconn \
        -borderwidth 2 \
        -height 50 \
        -width 200
    Label $base.fconn.lconn \
        -borderwidth 0 \
        -text [intlmsg {Connection}]
    ComboBox $base.fconn.comboconn \
        -textvariable ::PgAckages::dbconn \
        -background #fefefe \
        -borderwidth 1 \
        -width 200 \
        -values [::Connections::getConnectionsList] \
        -editable false
    $base.fconn.comboconn setvalue first

    pack $base.fconn \
        -in $base \
        -expand 1 \
        -fill both \
        -anchor center \
        -side top
    pack $base.fconn.lconn \
        -in $base.fconn \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left
    pack $base.fconn.comboconn \
        -in $base.fconn \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left

    frame $base.fobj \
        -borderwidth 0 \
        -height 200 \
        -width 400
    pack $base.fobj \
        -in $base \
        -anchor center \
        -expand 1 \
        -fill x \
        -side top


    Label $base.fobj.lobjects \
        -text [intlmsg {Objects}]
    grid $base.fobj.lobjects \
        -in $base.fobj -column 0 -row 0 -columnspan 3 -rowspan 1

    # this row col stuff is just plain laziness...

    set row 1
    set col 0
    set base $base.fobj

    Label $base.$row-$col \
        -text [intlmsg {PgAccess}]
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row
    checkbutton $base.$row-$col \
        -text [intlmsg {Queries}] \
        -variable ::PgAckages::pga_objs(Queries)
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row
    checkbutton $base.$row-$col \
        -text [intlmsg {Reports}] \
        -variable ::PgAckages::pga_objs(Reports)
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row
    checkbutton $base.$row-$col \
        -text [intlmsg {Graphs}] \
        -variable ::PgAckages::pga_objs(Graphs)
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row
    checkbutton $base.$row-$col \
        -text [intlmsg {Forms}] \
        -variable ::PgAckages::pga_objs(Forms)
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row
    checkbutton $base.$row-$col \
        -text [intlmsg {Scripts}] \
        -variable ::PgAckages::pga_objs(Scripts)
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row
    checkbutton $base.$row-$col \
        -text [intlmsg {Images}] \
        -variable ::PgAckages::pga_objs(Images)
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row
    checkbutton $base.$row-$col \
        -text [intlmsg {Diagrams}] \
        -variable ::PgAckages::pga_objs(Diagrams)
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row


    # gotta keep em separated
    incr col
    Separator $base.$row-$col -relief groove -orient vertical
    grid $base.$row-$col \
        -sticky news \
        -in $base -column $col -row 1 -columnspan 1 -rowspan $row


    set row 1
    incr col

    Label $base.$row-$col \
        -text [intlmsg {PostgreSQL}]
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row
    checkbutton $base.$row-$col \
        -text [intlmsg {Tables}] \
        -variable ::PgAckages::pg_objs(Tables)
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row
    checkbutton $base.$row-$col \
        -text [intlmsg {Views}] \
        -variable ::PgAckages::pg_objs(Views)
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row
    checkbutton $base.$row-$col \
        -text [intlmsg {Sequences}] \
        -variable ::PgAckages::pg_objs(Sequences)
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1
    incr row
    checkbutton $base.$row-$col \
        -text [intlmsg {Functions}] \
        -variable ::PgAckages::pg_objs(Functions)
    grid $base.$row-$col \
        -sticky w \
        -in $base -column $col -row $row -columnspan 1 -rowspan 1

    set base $Win(fdlg)

    frame $base.fbtn \
        -borderwidth 2 \
        -height 50 \
        -width 400
    ButtonBox $base.fbtn.bbox \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    if {$::PgAckages::usage == "save"} {
        $base.fbtn.bbox add \
            -image ::icon::filesave-22 \
            -helptext [intlmsg {Save}] \
            -command [subst {
                ::PgAckages::save
                destroy $Win(fdlg)
            }]
    } else {
        $base.fbtn.bbox add \
            -image ::icon::fileopen-22 \
            -helptext [intlmsg {Load}] \
            -command [subst {
                ::PgAckages::load
                destroy $Win(fdlg)
            }]
    }

    $base.fbtn.bbox add \
        -image ::icon::exit-22 \
        -helptext [intlmsg {Close}] \
        -command [subst {
            destroy $Win(fdlg)
        }]

    pack $base.fbtn \
        -in $base \
        -expand 1 \
        -fill both \
        -side top
    pack $base.fbtn.bbox \
        -in $base.fbtn \
        -side right \
        -expand 1 \
        -fill both

}
