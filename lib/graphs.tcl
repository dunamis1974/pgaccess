#==========================================================
# Graphs --
#
#   provides for visualization of data
#
#==========================================================
#
namespace eval Graphs {
    variable Win
}


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::init {} {
    variable oid 0
    variable name "New graph"
    variable source ""
    variable type "line"
    variable title "Graphs 1"
    variable ymin 0
    variable ymax 100
    variable numYIntervals 10
    variable ytitle ""
    variable xtitle ""
    variable xlabels {}
    variable xcolumn ""
    variable labelGap 5
    variable dataSeries
    variable dataSeriesColor
    variable dataSeriesNames [list]
    variable lineWidth 2
    variable xsize 400
    variable ysize 400
    variable markerSize 6
    variable tickSize 5
    variable leftMargin 50
    variable rightMargin 20
    variable header 50
    variable footer 60
    variable barGap {10 3}
}; # end proc ::Graphs::init


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::new {} {
    ::Graphs::design {}
}; # end proc ::Graphs::new


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::open {graphname_} {
    ::Graphs::init
    ::Graphs::preview $graphname_
}; # end proc ::Graphs::open


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::design {graphname_} {

    variable name
    variable source
    variable xcolumn
    variable dataSeriesNames
    variable dataSeriesColor
    variable Win

    ::Graphs::init

    Window show .pgaw:Graphs:design
    tkwait visibility .pgaw:Graphs:design

    # if there's a graphname_ then try to load it
    if {$graphname_ != ""} {
        ::Graphs::load $graphname_
        ::Graphs::updateSource
        # add each data series
        foreach ds $dataSeriesNames {
            focus $Win(serieslb)
            $Win(serieslb) selection set $ds
            ::Graphs::addDataSeries
            $Win(serieslb) itemconfigure $ds -fill $dataSeriesColor($ds)
        }
        # configure combobox selections
        $Win(settings).cbsource configure -text $source
        $Win(settings).cbxcol configure -text $xcolumn

    } else {
        set name "New graph"
    }

}; # end proc ::Graphs::design


#----------------------------------------------------------
# close --
#
#   Clears all variables in this namespace.
#
#----------------------------------------------------------
#
proc ::Graphs::close {} {

    foreach var [info vars ::Graphs::*] {
        if {[info exists [subst {$var}]]} {
            unset $var
        }
    }

}; # end proc ::Graphs::close


#----------------------------------------------------------
# print --
#
#   Sets up the printer dialog by handing a callback to it.
#
#----------------------------------------------------------
#
proc ::Graphs::print {} {
    ::Printer::init "::Graphs::printcallback"
}; # end proc ::Graphs::print


#----------------------------------------------------------
# printcallback --
#
#   Called with a file handle, hand it a canvas.
#
# Arguments:
#   fid     Open file descriptor for printing to
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Graphs::printcallback {fid} {

    variable Win

    variable xsize
    variable ysize

    ::Printer::printStart $fid $xsize $ysize 1
    ::Printer::printPage $fid 1 $Win(preview).c
    ::Printer::printStop $fid

}; # end proc ::Graphs::printcallback


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::preview {{graphname_ ""}} {

    global CurrentDB

    variable Win

    variable dataSeries
    variable dataSeriesColor
    variable dataSeriesNames
    variable xlabels
    variable xcolumn
    variable xsize
    variable ysize

    # phantom data is a menace
    ::Graphs::clearDataSeries

    if {$graphname_ != ""} {
        # attempts to load the graph if a graphname_ was provided
        # for use in preview mode
        ::Graphs::load $graphname_
    } else {
        # or just set up the data series colors, everything else
        # can be gotten from the design window as this must be design mode
        foreach col [$Win(serieslb) items] {
            if {[lindex [$Win(serieslb) itemcget $col -data] 0]} {
                set dataSeriesColor($col) [$Win(serieslb) itemcget $col -fill]
            }
        }
    }

    # this is the actual data the graph will be displaying
    set sql "
        SELECT *
          FROM [::Database::quoteObject $::Graphs::source]"
    set res [wpg_exec $CurrentDB $sql]
    set nrecs [pg_result $res -numTuples]
    if {$nrecs<1} {return}
    pg_result $res -assign ra

    set xlabels {}
    for {set i 0} {$i<$nrecs} {incr i} {
        if {[info exists ra($i,$xcolumn)]} {
            lappend xlabels $ra($i,$xcolumn)
        }
    }

    foreach ds $dataSeriesNames {
        set dstmp {}
        for {set i 0} {$i<$nrecs} {incr i} {
            lappend dstmp $ra($i,$ds)
        }
        set dataSeries($ds) $dstmp
    }

    pg_result $res -clear

    Window show .pgaw:Graphs:preview
    tkwait visibility .pgaw:Graphs:preview

    set newsize ""

    # allow a little extra room for the button box
    append newsize $xsize "x" [expr {$ysize + 100}]

    wm geometry .pgaw:Graphs:preview $newsize

    ::Graphs::draw $Win(preview) 0 0

}; # end proc ::Graphs::preview


#----------------------------------------------------------
# introspect --
#
#   Given a graphname, returns the SQL needed to recreate
#   it.
#
# Arguments:
#   graphname_  name of a graph to introspect
#   dbh_        an optional database handle
#
# Returns:
#   insql       the INSERT statement to make this graph
#----------------------------------------------------------
#
proc ::Graphs::introspect {graphname_ {dbh_ ""}} {

    set insql [::Graphs::clone $graphname_ $graphname_ $dbh_]

    return $insql

}; # end proc ::Graphs::introspect


#----------------------------------------------------------
# ::Graphs::clone --
#
#   Like introspect, only changes the graphname
#
# Arguments:
#   srcgraph_   the original graph
#   destgraph_  the clone graph
#   dbh_        an optional database handle
#
# Returns:
#   insql       the INSERT statement to clone this graph
#----------------------------------------------------------
#
proc ::Graphs::clone {srcgraph_ destgraph_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set insql ""

    set sql "SELECT graphsource, graphcode
               FROM pga_graphs
              WHERE graphname='$srcgraph_'"

    wpg_select $dbh_ $sql rec {
        set insql "
            INSERT INTO pga_graphs (graphsource, graphcode, graphname)
                 VALUES ('[::Database::quoteSQL $rec(graphsource)]','[::Database::quoteSQL $rec(graphcode)]','[::Database::quoteSQL $destgraph_]');"
    }

    return $insql

}; # end proc ::Graphs::clone


#----------------------------------------------------------
# load --
#
#   Given a graphname, loads the code for it and sets
#   all appropriate variables for either design or preview.
#
# Arguments:
#   graphname_  name of a graph to load
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Graphs::load {graphname_} {

    global CurrentDB

    variable name
    variable oid
    variable source

    set name $graphname_

    set sql "SELECT oid, graphsource, graphcode
               FROM pga_graphs
              WHERE graphname='$graphname_'"

    wpg_select $CurrentDB $sql rec {
        set oid $rec(oid)
        set source $rec(graphsource)
        eval $rec(graphcode)
    }

}; # end proc ::Graphs::load


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::save {{copy_ 0}} {

    global CurrentDB

    variable name
    variable source
    variable oid

    # delete the old graph if necessary
    if {$copy_ == 0 && [info exists oid]} {
        set sql "DELETE FROM pga_graphs
                       WHERE oid=$oid"
        sql_exec noquiet $sql
    }

    # determine the variables and their values that need to be preserved
    set code ""
    foreach var [info vars ::Graphs::*] {
        if {[info exists $var]} {
            if {[array exists [subst $var]]} {
                set val [array get [subst {$var}]]
                append code "variable $var ; array set $var {$val} ; "
            # we really cant allow duplicate data series names
            # this should be generalized to all list cases
            } elseif {$var=="::Graphs::dataSeriesNames"} {
                append code "variable $var \[list\] ; "
                set tmp ""
                foreach val [subst {$$var}] {
                    if {$tmp!=[subst {$val}]} {
                        set tmp [subst {$val}]
                        append code "lappend $var {$val} ; "
                    }
                }
            } elseif {$var!="::Graphs::source" \
                && $var!="::Graphs::oid" } {
                    set val [subst {[subst {$$var}]}]
                    append code "variable $var ; set $var {$val} ; "
            }
        }
    }
    # then add the graph to the database
    set sql "INSERT INTO pga_graphs (graphname,graphsource,graphcode)
                  VALUES ('$name','$source','[subst $code]')"
    sql_exec noquiet $sql

    # refresh OID of the graph
    set sql "SELECT oid
               FROM pga_graphs
              WHERE graphname='$name'"
    wpg_select $CurrentDB $sql rec {
        set oid $rec(oid)
    }

    # refresh the list of graphs in the right pane
    ::Mainlib::cmd_Graphs

}; # end proc ::Graphs::save


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::updateSource {} {

    variable Win

    variable source

    $Win(settings).cbxcol configure -values \
        [::Database::getColumnsList $source]
    $Win(serieslb) delete \
        [$Win(serieslb) items]

    foreach col [::Database::getColumnsList $source] {
        $Win(serieslb) insert end $col \
            -text $col \
            -fill "#000000" \
            -image ::icon::hotlistdel-16 \
            -data {0}
    }

}; # end proc ::Graphs::updateSource


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::addDataSeries {} {

    variable Win

    variable dataSeriesNames

    foreach c [$Win(serieslb) selection get] {
        $Win(serieslb) itemconfigure $c \
            -image ::icon::hotlistadd-16 \
            -data {1}
        if {![info exists dataSeriesNames]} {
            set dataSeriesNames [list]
        }
        set idx [lsearch $dataSeriesNames [$Win(serieslb) itemcget $c -text]]
        if {$idx == -1} {
            lappend dataSeriesNames [$Win(serieslb) itemcget $c -text]
        }
    }

}; # end proc ::Graphs::addDataSeries


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::removeDataSeries {} {

    variable Win

    variable dataSeriesNames

    foreach c [$Win(serieslb) selection get] {
        $Win(serieslb) itemconfigure $c \
            -image ::icon::hotlistdel-16 \
            -data {0}
        if {![info exists dataSeriesNames]} {
            set dataSeriesNames [list]
        }
        set idx [lsearch $dataSeriesNames [$Win(serieslb) itemcget $c -text]]
        if {$idx != -1} {
            set dataSeriesNames [lreplace dataSeriesNames $idx $idx]
        }
    }

}; # end proc ::Graphs::removeDataSeries


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::changeDataSeriesColor {} {

    variable Win

    variable dataSeriesColor

    foreach c [$Win(serieslb) selection get] {
        set oldc [$Win(serieslb) itemcget $c \
            -fill]
        if {$oldc==""} {set oldc "#000000"}
        set newc [SelectColor .colordlg \
            -title [intlmsg {"Select Color"}] \
            -parent .pgaw:Graphs:design \
            -color $oldc]
        if {$newc==""} {set newc $oldc}
        $Win(serieslb) itemconfigure $c -fill $newc
        set dataSeriesColor($c) [$Win(serieslb) itemcget $c -fill]
    }

}; # end proc ::Graphs::changeDataSeriesColor


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::clearDataSeries {} {

    variable dataSeries

    foreach i [array name dataSeries] {
        unset dataSeries($i)
    }

}; # end proc ::Graphs::clearDataSeries


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::calcy {series index} {

    variable ysize
    variable footer
    variable dataSeries
    variable ymax
    variable ymin
    variable ysize
    variable header

    set res [expr "$ysize - $footer - ([lindex $dataSeries($series) $index] - $ymin) * ($ysize - $footer - $header) / ($ymax - $ymin)"]

    if {$res < [expr {$ysize-$footer}]} {
        return $res
    } else {
        return [expr {$ysize-$footer}]
    }

}; # end proc ::Graphs::calcy


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::draw {{base ""} {xpos 0} {ypos 0}} {

    variable Win

    variable xsize
    variable ysize
    variable header
    variable footer
    variable title
    variable xtitle
    variable tickSize
    variable leftMargin
    variable rightMargin
    variable numYIntervals
    variable lineWidth
    variable ymax
    variable ymin
    variable type

    if {$base == "" } {
        set base $Win(preview)
    }

    $base.c delete [$base.c find all]
    $base.c configure -width $xsize -height $ysize

    # title
    $base.c create text \
        [expr {$xsize/2}] \
        [expr {$header/2}] \
        -text $title

    # x title
    $base.c create text \
        [expr {$leftMargin+($xsize-$leftMargin-$rightMargin)/2}] \
        [expr {$ysize-($footer-$tickSize-5)/2}] \
        -text $xtitle \
        -anchor n

    # axes
    $base.c create line \
        $leftMargin $header \
        $leftMargin [expr {$ysize-$footer}] \
        -width $lineWidth
    $base.c create line \
        $leftMargin [expr {$ysize-$footer}] \
        [expr {$xsize-$rightMargin}] [expr {$ysize-$footer}] \
        -width $lineWidth

    # loop through the y-axis labels
    for {set i 0} {$i <= $numYIntervals} {incr i} {
        set y [expr "$header + $i*($ysize - $header - $footer)/$numYIntervals"]

        # vertical ticks
        $base.c create line \
            [expr {$leftMargin-$tickSize}] $y \
            $leftMargin $y \
            -width $lineWidth

        # vertical labels
        $base.c create text \
            [expr {$leftMargin-$tickSize-5}] $y \
            -anchor e \
            -text [expr {$ymax-($ymax-$ymin)*$i/$numYIntervals}]
    }

    # switch to appropriate graph type
    ::Graphs::draw_$type $base

}; # end proc ::Graphs::draw


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::draw_line {base} {
    variable xsize
    variable ysize
    variable header
    variable footer
    variable tickSize
    variable leftMargin
    variable rightMargin
    variable lineWidth
    variable dataSeries
    variable dataSeriesColor
    variable xlabels
    variable markerSize

    set names [array name dataSeries]
    set numXVals [llength $dataSeries([lindex $names 0])]

    for {set i 0} {$i < $numXVals} {incr i} {
        if {$numXVals > 1} {
            set x [expr "$leftMargin + $i*($xsize - $leftMargin - $rightMargin)/($numXVals - 1)"]
        } else {
            set x [expr "($xsize - $leftMargin - $rightMargin) / 2 + $leftMargin"]
        }

        # horizontal ticks
        $base.c create line \
            $x [expr {$ysize-$footer}] \
            $x [expr {$ysize-$footer+$tickSize}] \
            -width $lineWidth

        # x axis labels
        if {[llength $xlabels] >= $numXVals} {
            $base.c create text \
                $x [expr {$ysize-$footer+$tickSize+5}] \
                -anchor n \
                -text [lindex $xlabels $i]
        }
    }

    foreach series [array name dataSeries] {

        if {[llength $dataSeriesColor($series)] < 4} {
            for {set i [expr [llength $dataSeriesColor($series)]+1]} {$i <= 4} {incr i} {
                lappend dataSeriesColor($series) \
                    [lindex $dataSeriesColor($series) 0]
            }
        }

        for {set i 0} {$i < [llength $dataSeries($series)]} {incr i} {
            if {[llength $dataSeries($series)] > 1} {
                set x [expr "$leftMargin + $i*($xsize - $leftMargin - $rightMargin)/([llength $dataSeries($series)] - 1)"]
            } else {
                    set x [expr "($xsize - $leftMargin - $rightMargin) / 2 + $leftMargin"]
            }

            # data points
            if {$i > 0} {
                if {[lindex $dataSeries($series) $i] > [lindex $dataSeries($series) [expr {$i-1}]]} {
                    $base.c create line $lastx [calcy $series [expr {$i-1}]] $x [calcy $series $i] -width $lineWidth -fill [lindex $dataSeriesColor($series) 0]
                } elseif {[lindex $dataSeries($series) $i] == [lindex $dataSeries($series) [expr {$i-1}]]} {
                    $base.c create line $lastx [calcy $series [expr {$i-1}]] $x [calcy $series $i] -width $lineWidth -fill [lindex $dataSeriesColor($series) 1]
                } else {
                    $base.c create line $lastx [calcy $series [expr {$i-1}]] $x [calcy $series $i] -width $lineWidth -fill [lindex $dataSeriesColor($series) 2]
                }
            }

            set lastx $x
        }

        # point markers
        for {set i 0} {$i < [llength $dataSeries($series)]} {incr i} {
            if {[llength $dataSeries($series)] > 1} {
                set x [expr "$leftMargin + $i*($xsize - $leftMargin - $rightMargin)/([llength $dataSeries($series)] - 1)"]
            } else {
                set x [expr "($xsize - $leftMargin - $rightMargin) / 2 + $leftMargin"]
            }

            $base.c create oval \
                [expr {$x-$markerSize/2}] \
                [expr {[calcy $series $i]-$markerSize/2}] \
                [expr {$x+$markerSize/2}] \
                [expr {[calcy $series $i]+$markerSize/2}] \
                -fill [lindex $dataSeriesColor($series) 3] \
                -outline [lindex $dataSeriesColor($series) 3]
        }
    }

}; # end proc ::Graphs::draw_line


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Graphs::draw_bar {base} {
    variable xsize
    variable ysize
    variable header
    variable footer
    variable tickSize
    variable leftMargin
    variable rightMargin
    variable lineWidth
    variable dataSeries
    variable dataSeriesColor
    variable xlabels
    variable barGap

    set names [array name dataSeries]
    set numXVals [llength $dataSeries([lindex $names 0])]
    set xSpacing [expr "($xsize - $leftMargin - $rightMargin) / $numXVals"]
    set barWidth [expr "($xSpacing - [lindex $barGap 0] - ([llength $names] - 1) * [lindex $barGap 1]) / [llength $names]"]
    set barSpacing [expr "$barWidth +  [lindex $barGap 1]"]

    for {set i 0} {$i < $numXVals} {incr i} {
        if {$numXVals > 1} {
            set x [expr "$leftMargin + $xSpacing/2 + $i*$xSpacing"]
        } else {
            set x [expr "($xsize - $leftMargin - $rightMargin) / 2 + $leftMargin"]
        }

        # horizontal ticks
        $base.c create line \
            $x [expr {$ysize-$footer}] \
            $x [expr {$ysize-$footer+$tickSize}] \
            -width $lineWidth

        # x axis labels
        if {[llength $xlabels] >= $numXVals} {
            $base.c create text \
                $x [expr {$ysize-$footer+$tickSize+5}] \
                -anchor n \
                -text [lindex $xlabels $i]
        }

        # bars
        set j 0
        foreach series [array name dataSeries] {
            set xbar [expr "$x - ($xSpacing - [lindex $barGap 0])/2 + $j*$barSpacing - 1"]
            $base.c create rectangle \
                $xbar [calcy $series $i] \
                [expr {$xbar+$barWidth}] [expr {$ysize-$footer-1}] \
                -fill [lindex $dataSeriesColor($series) 0]
            incr j
        }
   }

}; # end proc ::Graphs::draw_bar



############################ END NAMESPACE GRAPHS
############################ BEGIN VISUAL TCL



proc vTclWindow.pgaw:Graphs:preview {base} {

    global Win

    if {$base == "" } {
        set base .pgaw:Graphs:preview
    }
    if {[winfo exists $base]} {
        wm deiconify $base
        return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 400x500+270+209
    wm maxsize $base 1265 994
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm title $base [intlmsg {Graph Preview}]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    bind $base <Destroy> {
        if {![winfo exists .pgaw:Graphs:design]} {
            ::Graphs::close
        }
    }

    set ::Graphs::Win(preview) $base.fbottom

    frame $base.ftop
    frame $base.fbottom

    canvas $base.fbottom.c \
        -background #ffffff \
        -height 400 \
        -width 400

    ButtonBox $base.ftop.bbox \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $base.ftop.bbox add \
        -relief link \
        -helptext [intlmsg {Print}] \
        -borderwidth 1 \
        -image ::icon::fileprint-22 \
        -command {
            ::Graphs::print
        }
    $base.ftop.bbox add \
        -relief link \
        -helptext [intlmsg {Close}] \
        -borderwidth 1 \
        -image ::icon::exit-22 \
        -command {
            Window destroy .pgaw:Graphs:preview
        }

    pack $base.ftop \
        -in $base \
        -expand 1 \
        -fill both \
        -side top
    pack $base.fbottom \
        -in $base \
        -expand 1 \
        -fill both \
        -side top
    pack $base.ftop.bbox \
        -in $base.ftop \
        -anchor e \
        -side right
    pack $base.fbottom.c \
        -in $base.fbottom \
        -expand 1 \
        -fill both \
        -side top

}


proc vTclWindow.pgaw:Graphs:design {base} {

    global Win

    if {$base == "" } {
        set base .pgaw:Graphs:design
    }

    if {[winfo exists $base]} {
        wm deiconify $base
        return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 300x450+220+159
    wm maxsize $base 1265 994
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm title $base [intlmsg "Graph Design"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    bind $base <Destroy> {
        ::Graphs::close
    }

    set ::Graphs::Win(fx) $base.fx

    # main frames
    frame $base.fx \
        -borderwidth 2 \
        -height 300 \
        -width 300 \
        -relief groove
    pack $base.fx \
        -in $base \
        -fill both \
        -expand 1
    frame $base.fx.fbtns
    frame $base.fx.fsettings
    frame $base.fx.fseries
    pack $base.fx.fbtns \
        -in $base.fx \
        -fill both \
        -expand 1 \
        -side top
    pack $base.fx.fsettings \
        -in $base.fx \
        -fill both \
        -expand 1 \
        -side top
    pack $base.fx.fseries \
        -in $base.fx \
        -fill both \
        -expand 1 \
        -side top

    set base .pgaw:Graphs:design
    set base $base.fx.fsettings
    set ::Graphs::Win(settings) $base

    grid columnconf $base 2 -weight 2
    grid columnconf $base 4 -weight 2

    # name
    set row 0
    Label $base.lname \
        -text [intlmsg {Name}]
    Entry $base.ename \
        -textvariable ::Graphs::name
    grid $base.lname \
        -in $base \
        -column 0 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    grid $base.ename \
        -in $base \
        -column 2 \
        -row $row \
        -columnspan 6 \
        -rowspan 1 \
        -sticky we
    # title
    incr row
    Label $base.ltit \
        -text [intlmsg {Title}]
    Entry $base.etit \
        -textvariable ::Graphs::title
    grid $base.ltit \
        -in $base \
        -column 0 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    grid $base.etit \
        -in $base \
        -column 2 \
        -row $row \
        -columnspan 6 \
        -rowspan 1 \
        -sticky we
    # source
    incr row
    Label $base.lsource \
        -text [intlmsg {Source}]
    ComboBox $base.cbsource \
        -textvariable ::Graphs::source \
        -editable false \
        -modifycmd {
            ::Graphs::updateSource
        } \
        -values [concat [::Database::getPrefObjList Tables] \
            [::Database::getPrefObjList Views]]
    grid $base.lsource \
        -in $base \
        -column 0 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    grid $base.cbsource \
        -in $base \
        -column 2 \
        -row $row \
        -columnspan 6 \
        -rowspan 1 \
        -sticky we
    # type
    incr row
    Label $base.ltype \
        -text [intlmsg {Type}]
    radiobutton $base.rline \
        -text [intlmsg {Line}] \
        -variable ::Graphs::type \
        -value "line"
    radiobutton $base.rbar \
        -text [intlmsg {Bar}] \
        -variable ::Graphs::type \
        -value "bar"
    grid $base.ltype \
        -in $base \
        -column 0 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    grid $base.rline \
        -in $base \
        -column 2 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    grid $base.rbar \
        -in $base \
        -column 4 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    # width
    incr row
    Label $base.lxsize \
        -text [intlmsg {Width}]
    SpinBox $base.sbx \
        -background #fefefe \
        -highlightthickness 0 \
        -relief groove \
        -textvariable ::Graphs::xsize \
        -range {0 1280 1} \
        -text 400 \
        -width 0
    grid $base.lxsize \
        -in $base \
        -column 0 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    grid $base.sbx \
        -in $base \
        -column 2 \
        -row $row \
        -columnspan 6 \
        -rowspan 1 \
        -sticky we
    # height
    incr row
    Label $base.lysize \
        -text [intlmsg {Height}]
    SpinBox $base.sby \
        -background #fefefe \
        -highlightthickness 0 \
        -relief groove \
        -textvariable ::Graphs::ysize \
        -range {0 1280 1} \
        -text 400 \
        -width 0
    grid $base.lysize \
        -in $base \
        -column 0 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    grid $base.sby \
        -in $base \
        -column 2 \
        -row $row \
        -columnspan 6 \
        -rowspan 1 \
        -sticky we
    # y-axis
    incr row
    Label $base.lymax \
        -text [intlmsg {Y-Max}]
    SpinBox $base.sbymax \
        -background #fefefe \
        -highlightthickness 0 \
        -relief groove \
        -textvariable ::Graphs::ymax \
        -range {-1000 1000 10} \
        -text 100 \
        -width 0
    grid $base.lymax \
        -in $base \
        -column 0 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    grid $base.sbymax \
        -in $base \
        -column 2 \
        -row $row \
        -columnspan 6 \
        -rowspan 1 \
        -sticky we
    # y-axis
    incr row
    Label $base.lymin \
        -text [intlmsg {Y-Min}]
    SpinBox $base.sbymin \
        -background #fefefe \
        -highlightthickness 0 \
        -relief groove \
        -textvariable ::Graphs::ymin \
        -range {-1000 1000 10} \
        -text 0 \
        -width 0
    grid $base.lymin \
        -in $base \
        -column 0 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    grid $base.sbymin \
        -in $base \
        -column 2 \
        -row $row \
        -columnspan 6 \
        -rowspan 1 \
        -sticky we
    # x-axis title
    incr row
    Label $base.lxtit \
        -text [intlmsg {X-Title}]
    Entry $base.extit \
        -textvariable ::Graphs::xtitle
    grid $base.lxtit \
        -in $base \
        -column 0 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    grid $base.extit \
        -in $base \
        -column 2 \
        -row $row \
        -columnspan 6 \
        -rowspan 1 \
        -sticky we
    # x-axis labels
    incr row
    Label $base.lxcol \
        -text [intlmsg {X-Labels}]
    ComboBox $base.cbxcol \
        -textvariable ::Graphs::xcolumn
    grid $base.lxcol \
        -in $base \
        -column 0 \
        -row $row \
        -columnspan 2 \
        -rowspan 1 \
        -sticky w
    grid $base.cbxcol \
        -in $base \
        -column 2 \
        -row $row \
        -columnspan 6 \
        -rowspan 1 \
        -sticky we

    set base .pgaw:Graphs:design
    set base $base.fx.fseries
    set ::Graphs::Win(series) $base

    # series frame
    frame $base.fsc \
        -borderwidth 2 \
        -height 100 \
        -width 300
    pack $base.fsc \
        -in $base
    frame $base.fsc.fcol \
        -borderwidth 2 \
        -height 100 \
        -width 100
    pack $base.fsc.fcol \
        -in $base.fsc \
        -side left
    Label $base.fsc.fcol.lcol \
        -text [intlmsg {Series (Columns)}]
    ListBox $base.fsc.fcol.lbcol \
        -background #fefefe \
        -selectmode single \
        -width 20
    set ::Graphs::Win(serieslb) $base.fsc.fcol.lbcol
    pack $base.fsc.fcol.lcol \
        -in $base.fsc.fcol \
        -side top
    pack $base.fsc.fcol.lbcol \
        -in $base.fsc.fcol \
        -side top
    frame $base.fsc.fbb \
        -borderwidth 2 \
        -height 100 \
        -width 50
    pack $base.fsc.fbb \
        -in $base.fsc \
        -side right
    ButtonBox $base.fsc.fbb.bbox \
        -orient vertical \
        -homogeneous 1 \
        -spacing 2
    $base.fsc.fbb.bbox add \
        -image ::icon::hotlistadd-16 \
        -helptext [intlmsg {Add series}] \
        -borderwidth 1 \
        -command {
            ::Graphs::addDataSeries
        }
    $base.fsc.fbb.bbox add \
        -image ::icon::hotlistdel-16 \
        -helptext [intlmsg {Remove series}] \
        -borderwidth 1 \
        -command {
            ::Graphs::removeDataSeries
        }
    $base.fsc.fbb.bbox add \
        -image ::icon::colorize-16 \
        -helptext [intlmsg {Change series color}] \
        -borderwidth 1 \
        -command {
            ::Graphs::changeDataSeriesColor
        }
    pack $base.fsc.fbb.bbox \
        -in $base.fsc.fbb

    set base .pgaw:Graphs:design
    set base $base.fx.fbtns
    set ::Graphs::Win(btns) $base

    # control frame
    frame $base.fcon \
        -borderwidth 2 \
        -height 100 \
        -width 300
    pack $base.fcon \
        -in $base \
        -anchor e \
        -side right
    ButtonBox $base.fcon.bbox \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $base.fcon.bbox add \
        -relief link \
        -image ::icon::filesave-22 \
        -helptext [intlmsg {Save}] \
        -borderwidth 1 \
        -command {
            ::Graphs::save 0
        }
    $base.fcon.bbox add \
        -relief link \
        -image ::icon::filesaveas-22 \
        -helptext [intlmsg {Save As}] \
        -borderwidth 1 \
        -command {
            ::Graphs::save 1
        }
    $base.fcon.bbox add \
        -relief link \
        -image ::icon::imagegallery-22 \
        -helptext [intlmsg {Preview}] \
        -borderwidth 1 \
        -command {
            ::Graphs::preview
        }
    $base.fcon.bbox add \
        -relief link \
        -image ::icon::help-22 \
        -helptext [intlmsg {Help}] \
        -borderwidth 1 \
        -command {
            ::Help::load graphs
        }
    $base.fcon.bbox add \
        -relief link \
        -image ::icon::exit-22 \
        -helptext [intlmsg {Close}] \
        -borderwidth 1 \
        -command {
            catch {Window destroy .pgaw:Graphs:design}
            catch {Window destroy .pgaw:Graphs:preview}
        }
    pack $base.fcon.bbox \
        -in $base.fcon \
        -side right \
        -expand 0 \
        -fill x

}

