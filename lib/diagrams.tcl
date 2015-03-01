#==========================================================
# Diagrams --
#
#       pretty pictures for the boss (formerly the Diagrams)
#
#==========================================================
#
namespace eval Diagrams {
    variable Win
    variable newtablename
    variable diagramname
    variable xsize
    variable ysize
}


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::clm_rename {{tbl_name} {old_name} {new_name}} {
    global PgAcVar CurrentDB
    catch {
        wpg_select $CurrentDB "
            SELECT diagramname
              FROM pga_diagrams
             WHERE (diagramtables LIKE '%$tbl_name %')
          ORDER BY diagramname" \
        rec {
            set Names $rec(diagramname)
            do_clm_rename $tbl_name $old_name $new_name $Names
        }
    }
}; # end proc ::Diagrams::clm_rename


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::do_clm_rename {{tbl_name} {old_name} {new_name} {diagrams}} {
    global PgAcVar CurrentDB
    variable diagramname

    init
    set diagramname $diagrams
    if {[set pgres [wpg_exec $CurrentDB "
        SELECT diagramtables,diagramlinks,oid
          FROM pga_diagrams
         WHERE diagramname='$diagramname'"]]==0} then {
        showError [intlmsg "Error retrieving diagrams definition"]
        return
    }
    if {[pg_result $pgres -numTuples]==0} {
        showError [format [intlmsg "Diagram '%s' was not found!"] $diagramname]
        pg_result $pgres -clear
        return
    }
    set tuple [pg_result $pgres -getTuple 0]
    set links [lindex $tuple 1]
    pg_result $pgres -clear
    set linkslist {}
    set PgAcVar(diagrams,links) $links
    foreach link $PgAcVar(diagrams,links) {
        set linklist { }
        foreach {tbl fld} $link {
            if {$tbl==$tbl_name} {
                if {$fld==$old_name} { set fld $new_name}
            }
            lappend linklist $tbl $fld
        }
        lappend linkslist $linklist
    }
        sql_exec noquiet "
            UPDATE pga_diagrams
               SET diagramlinks='$linkslist'
             WHERE diagramname='$diagrams'"
}; # end proc ::Diagrams::do_clm_rename


#----------------------------------------------------------
#----------------------------------------------------------
proc ::Diagrams::tbl_rename {{old_name} {new_name}} {
    global PgAcVar CurrentDB
    catch {
        wpg_select $CurrentDB "
            SELECT diagramname
              FROM pga_diagrams
             WHERE (diagramtables LIKE '$old_name %')
                OR (diagramtables LIKE '% $old_name %')
          ORDER BY diagramname" \
        rec {
            set Names $rec(diagramname)
            do_tbl_rename $old_name $new_name $Names
        }
    }
}; # end proc ::Diagrams::tbl_rename


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::do_tbl_rename {{old_name} {new_name} {diagrams}} {
    global PgAcVar CurrentDB
    variable diagramname

    init
    set diagramname $diagrams
    if {[set pgres [wpg_exec $CurrentDB "
        SELECT diagramtables,diagramlinks,oid
          FROM pga_diagrams
         WHERE diagramname='$diagramname'"]]==0} then {
        showError [intlmsg "Error retrieving diagrams definition"]
        return
    }
    if {[pg_result $pgres -numTuples]==0} {
        showError [format [intlmsg "Diagram '%s' was not found!"] $diagramname]
        pg_result $pgres -clear
        return
    }
    set tuple [pg_result $pgres -getTuple 0]
    set tables [lindex $tuple 0]
    set links [lindex $tuple 1]
    pg_result $pgres -clear
    set tablelist {}
    foreach {t x y} $tables {
        if {$t==$old_name} { set t $new_name}
        lappend tablelist $t $x $y
    }
    set linkslist {}

    set PgAcVar(diagrams,links) $links
    foreach link $PgAcVar(diagrams,links) {
        set linklist { }
        foreach {tbl fld} $link {
                        if {$tbl==$old_name} { set tbl $new_name}
                        lappend linklist $tbl $fld
        }
        lappend linkslist $linklist
    }
    sql_exec noquiet "
        UPDATE pga_diagrams
           SET diagramtables='$tablelist', diagramlinks='$linkslist'
         WHERE diagramname='$diagrams'"
}; # end proc ::Diagrams::do_tbl_rename


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::new {} {
    global PgAcVar
    variable Win
    variable diagramname

    init
    Window show .pgaw:Diagrams
    set PgAcVar(diagrams,oid) 0
    set diagramname {}
    set PgAcVar(diagrams,tables) {}
    set PgAcVar(diagrams,links) {}
    set PgAcVar(diagrams,results) {}
    focus $Win(diagramname)
    ::Diagrams::drawCoord
}; # end proc ::Diagrams::new


#----------------------------------------------------------
# ::Diagrams::introspect --
#
#   Given a diagramname, returns the SQL needed to recreate
#   it.
#
# Arguments:
#   diagramname_    name of a diagram to introspect
#   dbh_            an optional database handle
#
# Returns:
#   insql       the INSERT statement to make this diagram
#----------------------------------------------------------
#
proc ::Diagrams::introspect {diagramname_ {dbh_ ""}} {

    set insql [::Diagrams::clone $diagramname_ $diagramname_ $dbh_]

    return $insql

}; # end proc ::Diagrams::introspect


#----------------------------------------------------------
# ::Diagrams::clone --
#
#   Like introspect, only changes the diagramname
#
# Arguments:
#   srcdiagram_     the original diagram
#   destdiagram_    the clone diagram
#   dbh_            an optional database handle
#
# Returns:
#   insql           the INSERT statement to clone this diagram
#----------------------------------------------------------
#
proc ::Diagrams::clone {srcdiagram_ destdiagram_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set insql ""

    set sql "SELECT diagramtables, diagramlinks
               FROM pga_diagrams
              WHERE diagramname='$srcdiagram_'"

    wpg_select $dbh_ $sql rec {
        set insql "
            INSERT INTO pga_diagrams (diagramtables, diagramlinks, diagramname)
                 VALUES ('[::Database::quoteSQL $rec(diagramtables)]','[::Database::quoteSQL $rec(diagramlinks)]','[::Database::quoteSQL $destdiagram_]');"
    }

    return $insql

}; # end proc ::Diagrams::clone



#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::design {obj} {
    ::Diagrams::open $obj
}; # end proc ::Diagrams::design


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::open {obj} {
    global PgAcVar CurrentDB
    variable newtablename
    variable diagramname

    init
    set diagramname $obj
    if {[set pgres [wpg_exec $CurrentDB "
        SELECT diagramtables,diagramlinks,oid
          FROM pga_diagrams
         WHERE diagramname='$diagramname'"]]==0} then {
        showError [intlmsg "Error retrieving diagrams definition"]
        return
    }
    if {[pg_result $pgres -numTuples]==0} {
        showError [format [intlmsg "Diagram '%s' was not found!"] $diagramname]
        pg_result $pgres -clear
        return
    }
    set tuple [pg_result $pgres -getTuple 0]
    set tables [lindex $tuple 0]
    set links [lindex $tuple 1]
    set PgAcVar(diagrams,oid) [lindex $tuple 2]
    pg_result $pgres -clear
    Window show .pgaw:Diagrams
    foreach {t x y} $tables {
        set newtablename $t
        ::Diagrams::addNewTable $x $y
    }
    set PgAcVar(diagrams,links) $links
    ::Diagrams::drawLinks
    ::Diagrams::drawCoord
#### This makes new page size
    foreach {ulx uly lrx lry} [.pgaw:Diagrams.c bbox all] {
#		wm geometry .pgaw:Diagrams [expr {$lrx+30}]x[expr {$lry+30}]
    }
}; # end proc ::Diagrams::open


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::save {{saveas_ 0}} {
    global PgAcVar CurrentDB
    variable diagramname

    if {$diagramname==""} {
        showError [intlmsg "You have to supply a name for this diagrams!"]
        focus .pgaw:Diagrams.f.esn
    } else {
        setCursor CLOCK
        set tables [Diagrams::getDiagramsTables]
        if {$PgAcVar(diagrams,oid)==0 || $saveas_} then {
            set pgres [wpg_exec $CurrentDB "
                INSERT INTO pga_diagrams
                     VALUES ('$diagramname','$tables','$PgAcVar(diagrams,links)')"]
        } else {
            set pgres [wpg_exec $CurrentDB "
                UPDATE pga_diagrams
                   SET diagramname='$diagramname',diagramtables='$tables',diagramlinks='$PgAcVar(diagrams,links)'
                 WHERE oid=$PgAcVar(diagrams,oid)"]
        }
        setCursor DEFAULT
        if {$PgAcVar(pgsql,status)!="PGRES_COMMAND_OK"} {
            showError "[intlmsg {Error executing query}]\n$PgAcVar(pgsql,errmsg)"
        } else {
            Mainlib::tab_click Diagrams
            if {$PgAcVar(diagrams,oid)==0} {
                set PgAcVar(diagrams,oid) [pg_result $pgres -oid]
            }
        }
        catch {pg_result $pgres -clear}
    }

}; # end proc ::Diagrams::save


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::addNewTable {{tabx 0} {taby 0}} {
    global PgAcVar CurrentDB
    variable newtablename
    variable Win

    if {$newtablename==""} return
    if {$newtablename=="*"} {
        set tbllist [::Database::getTablesList]
        foreach tn [array names PgAcVar diagrams,tablename*] {
            if { [set linkid [lsearch $tbllist $PgAcVar($tn)]] != -1 } {
                set tbllist [lreplace $tbllist $linkid $linkid]
            }
        }
        foreach t $tbllist {
            set newtablename $t
            ::Diagrams::addNewTable
        }
        return
    }

    foreach tn [array names PgAcVar diagrams,tablename*] {
        if {$newtablename==$PgAcVar($tn)} {
            showError [format [intlmsg "Table '%s' already in diagrams"] $PgAcVar($tn)]
            return
        }
    }

    set fldlist {}
    setCursor CLOCK
    set fldlist [::Database::getColumnsTypesList $newtablename]
    setCursor DEFAULT
    if {$fldlist==""} {
        showError [format [intlmsg "Table '%s' not found!"] $newtablename]
        return
    }

    set PgAcVar(diagrams,tablename$PgAcVar(diagrams,ntables)) $newtablename
    # the split-join removes the inner list column name-type pairs & makes one list
    set PgAcVar(diagrams,tablestruct$PgAcVar(diagrams,ntables)) [split [join $fldlist]]
    set PgAcVar(diagrams,tablex$PgAcVar(diagrams,ntables)) $tabx
    set PgAcVar(diagrams,tabley$PgAcVar(diagrams,ntables)) $taby
    incr PgAcVar(diagrams,ntables)
    if {$PgAcVar(diagrams,ntables)==1} {
        ::Diagrams::drawAll
    } else {
        ::Diagrams::drawTable [expr {$PgAcVar(diagrams,ntables)-1}]
    }
    #lappend PgAcVar(diagrams,tables) $PgAcVar(diagrams,newtablename)  $PgAcVar(diagrams,tablex[expr {$PgAcVar(diagrams,ntables)-1}]) $PgAcVar(diagrams,tabley[expr $PgAcVar(diagrams,ntables)-1])
    lappend PgAcVar(diagrams,tables) $newtablename  $PgAcVar(diagrams,tablex[expr {$PgAcVar(diagrams,ntables)-1}]) $PgAcVar(diagrams,tabley[expr {$PgAcVar(diagrams,ntables)-1}])
    set newtablename {}
    focus $Win(entertable)
    ::Diagrams::drawCoord

}; # end proc ::Diagrams::addNewTable


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::drawAll {} {
global PgAcVar
    .pgaw:Diagrams.c delete all
    for {set it 0} {$it<$PgAcVar(diagrams,ntables)} {incr it} {
        drawTable $it
    }
    .pgaw:Diagrams.c lower rect
    ::Diagrams::drawLinks

    .pgaw:Diagrams.c bind mov <Button-1> {Diagrams::dragStart %W %x %y %s}
    .pgaw:Diagrams.c bind mov <B1-Motion> {Diagrams::dragMove %W %x %y}
    bind .pgaw:Diagrams.c <ButtonRelease-1> {Diagrams::dragStop %x %y}
    bind .pgaw:Diagrams <Button-1> {Diagrams::canvasClick %x %y %W}
    bind .pgaw:Diagrams <B1-Motion> {Diagrams::canvasPanning %x %y}
    bind .pgaw:Diagrams <Key-Delete> {Diagrams::deleteObject}
}; # end proc ::Diagrams::drawAll


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::drawTable {it} {
global PgAcVar

if {$PgAcVar(diagrams,tablex$it)==0} {
    set posx 380
    set posy 265

#	set posy $PgAcVar(diagrams,nexty)
#	set posx $PgAcVar(diagrams,nextx)
    set PgAcVar(diagrams,tablex$it) $posx
    set PgAcVar(diagrams,tabley$it) $posy
} else {
    set posx [expr {int($PgAcVar(diagrams,tablex$it))}]
    set posy [expr {int($PgAcVar(diagrams,tabley$it))}]
}
set tablename $PgAcVar(diagrams,tablename$it)
.pgaw:Diagrams.c create text $posx $posy -text "$tablename" -anchor nw -tags [list tab$it f-oid mov tableheader] -font $PgAcVar(pref,font_bold)
incr posy 16
foreach {fld ftype} $PgAcVar(diagrams,tablestruct$it) {
if {[set cindex [lsearch $PgAcVar(pref,typelist) $ftype]] == -1} {set cindex 1}
.pgaw:Diagrams.c create text $posx $posy -text $fld -fill [lindex $PgAcVar(pref,typecolors) $cindex] -anchor nw -tags [list f-$fld tab$it mov] -font $PgAcVar(pref,font_normal)
incr posy 14
}
set reg [.pgaw:Diagrams.c bbox tab$it]
.pgaw:Diagrams.c create rectangle [lindex $reg 0] [lindex $reg 1] [lindex $reg 2] [lindex $reg 3] -fill #EEEEEE -tags [list rect outer tab$it]
.pgaw:Diagrams.c create line [lindex $reg 0] [expr {[lindex $reg 1]+15}] [lindex $reg 2] [expr {[lindex $reg 1]+15}] -tags [list rect tab$it]
.pgaw:Diagrams.c lower tab$it
.pgaw:Diagrams.c lower rect
set reg [.pgaw:Diagrams.c bbox tab$it]


set nexty [lindex $reg 1]
set nextx [expr {20+[lindex $reg 2]}]
if {$nextx > [winfo width .pgaw:Diagrams.c] } {
    set nextx 10
    set allbox [.pgaw:Diagrams.c bbox rect]
    set nexty [expr {20 + [lindex $allbox 3]}]
}
set PgAcVar(diagrams,nextx) $nextx
set PgAcVar(diagrams,nexty) $nexty
}; # end proc ::Diagrams::drawTable


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::drawCoord {} {
        global PgAcVar
        .pgaw:Diagrams.c create line 365 265 395 265 \
            -fill "#ff0000" \
            -width "1.0" \
            -tags [list redcross]
        .pgaw:Diagrams.c create line 380 250 380 280 \
            -fill "#ff0000" \
            -width "1.0" \
            -tags [list redcross]
}; # end proc ::Diagrams::drawCoord


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::deleteObject {} {
global PgAcVar
# Checking if there
set objs [.pgaw:Diagrams.c find withtag hili]
set numobj [llength $objs]
if {$numobj == 0 } return
# Is object a link ?
foreach obj $objs {
    if {[getTagInfo $obj link]=="s"} {
        if {[tk_messageBox -title [intlmsg Warning] -icon question -parent .pgaw:Diagrams -message [intlmsg "Remove link ?"] -type yesno -default no]=="no"} return
        set linkid [getTagInfo $obj lkid]
        set PgAcVar(diagrams,links) [lreplace $PgAcVar(diagrams,links) $linkid $linkid]
        .pgaw:Diagrams.c delete links
        ::Diagrams::drawLinks
        return
    }
    # Is object a table ?
    set tablealias [getTagInfo $obj tab]
    set tablename $PgAcVar(diagrams,tablename$tablealias)
    if {"$tablename"==""} return
    if {[tk_messageBox -title [intlmsg Warning] -icon question -parent .pgaw:Diagrams -message [format [intlmsg "Remove table %s from diagrams?"] $tablename] -type yesno -default no]=="no"} return
    for {set i [expr {[llength $PgAcVar(diagrams,links)]-1}]} {$i>=0} {incr i -1} {
        set thelink [lindex $PgAcVar(diagrams,links) $i]
        if {($tablename==[lindex $thelink 0]) || ($tablename==[lindex $thelink 2])} {
            set PgAcVar(diagrams,links) [lreplace $PgAcVar(diagrams,links) $i $i]
        }
    }
    for {set i 0} {$i<$PgAcVar(diagrams,ntables)} {incr i} {
        set temp {}
        catch {set temp $PgAcVar(diagrams,tablename$i)}
        if {"$temp"=="$tablename"} {
            unset PgAcVar(diagrams,tablename$i)
            unset PgAcVar(diagrams,tablestruct$i)
            break
        }
    }
    #incr PgAcVar(diagrams,ntables) -1
    .pgaw:Diagrams.c delete tab$tablealias
    .pgaw:Diagrams.c delete links
    ::Diagrams::drawLinks
    }
}; # end proc ::Diagrams::deleteObject


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::dragMove {w x y} {
global PgAcVar
    if {"$PgAcVar(draginfo,obj)" == ""} {return}
    set dx [expr {$x - $PgAcVar(draginfo,x)}]
    set dy [expr {$y - $PgAcVar(draginfo,y)}]
    if {$PgAcVar(draginfo,is_a_table)} {
        $w move dragme $dx $dy
        ::Diagrams::drawLinks
    } else {
        $w move $PgAcVar(draginfo,obj) $dx $dy
    }
#	showError [intlmsg "$dx\n$dy"]
    set PgAcVar(draginfo,x) $x
    set PgAcVar(draginfo,y) $y
}; # end proc ::Diagrams::dragMove


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::dragStart {w x y state} {
global PgAcVar
PgAcVar:clean draginfo,*
set PgAcVar(draginfo,obj) [$w find closest $x $y]
if {[getTagInfo $PgAcVar(draginfo,obj) r]=="ect"} {
    # If it'a a rectangle, exit
    set PgAcVar(draginfo,obj) {}
    return
}
.pgaw:Diagrams configure -cursor hand1
.pgaw:Diagrams.c raise $PgAcVar(draginfo,obj)
set PgAcVar(draginfo,table) 0
if {[getTagInfo $PgAcVar(draginfo,obj) table]=="header"} {
    set PgAcVar(draginfo,is_a_table) 1
    set taglist [.pgaw:Diagrams.c gettags $PgAcVar(draginfo,obj)]
    set PgAcVar(draginfo,tabletag) [lindex $taglist [lsearch -regexp $taglist "^tab\[0-9\]*"]]
    .pgaw:Diagrams.c raise $PgAcVar(draginfo,tabletag)
    if {$state == 0} {
        .pgaw:Diagrams.c itemconfigure hili -fill black
        .pgaw:Diagrams.c dtag hili
        .pgaw:Diagrams.c dtag dragme
    }
    .pgaw:Diagrams.c addtag dragme withtag $PgAcVar(draginfo,tabletag)
    .pgaw:Diagrams.c addtag hili withtag $PgAcVar(draginfo,obj)
    .pgaw:Diagrams.c itemconfigure hili -fill blue
} else {
    set PgAcVar(draginfo,is_a_table) 0
}
set PgAcVar(draginfo,x) $x
set PgAcVar(draginfo,y) $y
set PgAcVar(draginfo,sx) $x
set PgAcVar(draginfo,sy) $y
}; # end proc ::Diagrams::dragStart


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::dragStop {x y} {
global PgAcVar
# when click Close, diagrams window is destroyed but event ButtonRelease-1 is fired
if {![winfo exists .pgaw:Diagrams]} return;
.pgaw:Diagrams configure -cursor left_ptr
set este {}
catch {set este $PgAcVar(draginfo,obj)}
if {$este==""} return
# Re-establish the normal paint order so
# information won't be overlapped by table rectangles
# or link lines
if {$PgAcVar(draginfo,is_a_table)} {
    .pgaw:Diagrams.c lower $PgAcVar(draginfo,tabletag)
} else {
    .pgaw:Diagrams.c lower $PgAcVar(draginfo,obj)
}
.pgaw:Diagrams.c lower rect
.pgaw:Diagrams.c lower links
set PgAcVar(diagrams,panstarted) 0
if {$PgAcVar(draginfo,is_a_table)} {
    set tabnum [getTagInfo $PgAcVar(draginfo,obj) tab]
    foreach w [.pgaw:Diagrams.c find withtag $PgAcVar(draginfo,tabletag)] {
#						$PgAcVar(diagrams,coordx)\n$PgAcVar(diagrams,coordy)
        if {[lsearch [.pgaw:Diagrams.c gettags $w] outer] != -1} {
            foreach [list PgAcVar(diagrams,tablex$tabnum) PgAcVar(diagrams,tabley$tabnum) x1 y1] [.pgaw:Diagrams.c coords $w] {}
            set PgAcVar(diagrams,tablex$tabnum) [expr {$PgAcVar(diagrams,tablex$tabnum)+$PgAcVar(diagrams,coordx)+1}]
            set PgAcVar(diagrams,tabley$tabnum) [expr {$PgAcVar(diagrams,tabley$tabnum)+$PgAcVar(diagrams,coordy)-1}]
            break
        }
    }
    set PgAcVar(draginfo,obj) {}
    .pgaw:Diagrams.c delete links
    ::Diagrams::drawLinks
    return
}
# not a table
.pgaw:Diagrams.c move $PgAcVar(draginfo,obj) [expr {$PgAcVar(draginfo,sx)-$x}] [expr {$PgAcVar(draginfo,sy)-$y}]
set droptarget [.pgaw:Diagrams.c find overlapping $x $y $x $y]
set targettable {}
foreach item $droptarget {
    set targettable $PgAcVar(diagrams,tablename[getTagInfo $item tab])
    set targetfield [getTagInfo $item f-]
    if {($targettable!="") && ($targetfield!="")} {
        set droptarget $item
        break
    }
}
# check if target object isn't a rectangle
if {[getTagInfo $droptarget rec]=="t"} {set targettable {}}
if {$targettable!=""} {
    # Target has a table
    # See about originate table
    set sourcetable $PgAcVar(diagrams,tablename[getTagInfo $PgAcVar(draginfo,obj) tab])
    if {$sourcetable!=""} {
        # Source has also a tab .. tag
        set sourcefield [getTagInfo $PgAcVar(draginfo,obj) f-]
        if {$sourcetable!=$targettable} {
            lappend PgAcVar(diagrams,links) [list $sourcetable $sourcefield $targettable $targetfield]
            ::Diagrams::drawLinks
        }
    }
}
# Erase information about object beeing dragged
set PgAcVar(draginfo,obj) {}
}; # end proc ::Diagrams::dragStop


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::drawLinks {} {
global PgAcVar
.pgaw:Diagrams.c delete links
set i 0
foreach link $PgAcVar(diagrams,links) {
    set sourcenum -1
    set targetnum -1
    # Compute the source and destination right edge
    foreach t [array names PgAcVar diagrams,tablename*] {
        set sl [string length "diagrams,tablename"]
        if {[regexp "^$PgAcVar($t)$" [lindex $link 0] ]} {
            set sourcenum [string range $t $sl end]
        } elseif {[regexp "^$PgAcVar($t)$" [lindex $link 2] ]} {
            set targetnum [string range $t $sl end]
        }
    }
    set sb [::Diagrams::findField $sourcenum [lindex $link 1]]
    set db [::Diagrams::findField $targetnum [lindex $link 3]]
    if {($sourcenum == -1 )||($targetnum == -1)||($sb ==-1)||($db==-1)} {
        set PgAcVar(diagrams,links) [lreplace $PgAcVar(diagrams,links) $i $i]
        showError "Link from [lindex $link 0].[lindex $link 1] to [lindex $link 2].[lindex $link 3] not found!"
    } else {

        set sre [lindex [.pgaw:Diagrams.c bbox tab$sourcenum] 2]
        set dre [lindex [.pgaw:Diagrams.c bbox tab$targetnum] 2]
        # Compute field bound boxes
        set sbbox [.pgaw:Diagrams.c bbox $sb]
        set dbbox [.pgaw:Diagrams.c bbox $db]
        # Compute the auxiliary lines
        if {[lindex $sbbox 2] < [lindex $dbbox 0]} {
            # Source object is on the left of target object
            set x1 $sre
            set y1 [expr {([lindex $sbbox 1]+[lindex $sbbox 3])/2}]
            set x2 [lindex $dbbox 0]
            set y2 [expr {([lindex $dbbox 1]+[lindex $dbbox 3])/2}]
            .pgaw:Diagrams.c create line $x1 $y1 [expr {$x1+10}] $y1 \
                    [expr {$x1+10}] $y1 [expr {$x2-10}] $y2 \
                    [expr {$x2-10}] $y2 $x2 $y2 \
                    -tags [list links lkid$i] -width 2
        } else {
            # source object is on the right of target object
            set x1 [lindex $sbbox 0]
            set y1 [expr {([lindex $sbbox 1]+[lindex $sbbox 3])/2}]
            set x2 $dre
            set y2 [expr {([lindex $dbbox 1]+[lindex $dbbox 3])/2}]
            .pgaw:Diagrams.c create line $x1 $y1 [expr $x1-10] $y1 \
                    [expr {$x1-10}] $y1 [expr {$x2+10}] $y2 \
                    $x2 $y2 [expr {$x2+10}] $y2 \
                    -tags [list links lkid$i] -width 2
        }
        incr i
    }
}
.pgaw:Diagrams.c lower links
.pgaw:Diagrams.c bind links <Button-1> {Diagrams::linkClick %x %y}
}; # end proc ::Diagrams::drawLinks


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::getDiagramsTables {} {
global PgAcVar
    set tablelist {}
    foreach key [array names PgAcVar diagrams,tablename*] {
        regsub diagrams,tablename $key "" num
        lappend tablelist $PgAcVar($key) $PgAcVar(diagrams,tablex$num) $PgAcVar(diagrams,tabley$num)
    }
    return $tablelist
}; # end proc ::Diagrams::getDiagramsTables


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::findField {alias field} {
    foreach obj [.pgaw:Diagrams.c find withtag f-${field}] {
        if {[lsearch [.pgaw:Diagrams.c gettags $obj] tab$alias] != -1} {
            return $obj
        }
    }
    return -1
}; # end proc ::Diagrams::findField


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::addLink {sourcetable sourcefield targettable targetfield} {
global PgAcVar
    lappend PgAcVar(diagrams,links) [list $sourcetable $sourcefield $targettable $targetfield]
}; # end proc ::Diagrams::addLink


#----------------------------------------------------------
#----------------------------------------------------------
proc ::Diagrams::getTagInfo {obj prefix} {
    set taglist [.pgaw:Diagrams.c gettags $obj]
    set tagpos [lsearch -regexp $taglist "^$prefix"]
    if {$tagpos==-1} {return ""}
    set thattag [lindex $taglist $tagpos]
    return [string range $thattag [string length $prefix] end]
}; # end proc ::Diagrams::getTagInfo


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::init {} {
global PgAcVar
variable newtablename
    PgAcVar:clean diagrams,*
    set PgAcVar(diagrams,nexty) 10
    set PgAcVar(diagrams,nextx) 10
    set PgAcVar(diagrams,links) {}
    set PgAcVar(diagrams,ntables) 0
    set newtablename {}
    set PgAcVar(diagrams,coordx) 0
    set PgAcVar(diagrams,coordy) 0
}; # end proc ::Diagrams::init


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::linkClick {x y} {
global PgAcVar
    set obj [.pgaw:Diagrams.c find closest $x $y 1 links]
    if {[getTagInfo $obj link]!="s"} return
    .pgaw:Diagrams.c itemconfigure hili -fill black
    .pgaw:Diagrams.c dtag hili
    .pgaw:Diagrams.c addtag hili withtag $obj
    .pgaw:Diagrams.c itemconfigure $obj -fill blue
}; # end proc ::Diagrams::linkClick


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::canvasPanning {x y} {
global PgAcVar
    set panstarted 0
    catch {set panstarted $PgAcVar(diagrams,panstarted) }
    if {!$panstarted} return
    set dx [expr {$x-$PgAcVar(diagrams,panstartx)}]
    set dy [expr {$y-$PgAcVar(diagrams,panstarty)}]
    set PgAcVar(diagrams,panstartx) $x
    set PgAcVar(diagrams,panstarty) $y
    set PgAcVar(diagrams,coordx) [expr {$PgAcVar(diagrams,coordx)-$dx}]
    set PgAcVar(diagrams,coordy) [expr {$PgAcVar(diagrams,coordy)-$dy}]
    if {$PgAcVar(diagrams,panobject)=="tables"} {
        .pgaw:Diagrams.c move mov $dx $dy
        .pgaw:Diagrams.c move links $dx $dy
        .pgaw:Diagrams.c move rect $dx $dy
    } else {
        .pgaw:Diagrams.c move resp $dx 0
        .pgaw:Diagrams.c move resgrid $dx 0
        .pgaw:Diagrams.c raise reshdr
    }
}; # end proc ::Diagrams::canvasPanning


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::print {} {

    variable xsize
    variable ysize

    #.pgaw:Diagrams.c addtag printem all
    #set box [.pgaw:Diagrams.c bbox printem]
    #set xsize [expr {[lindex $box 2] - [lindex $box 0]}]
    #set ysize [expr {[lindex $box 3] - [lindex $box 1]}]

    set g [string trimleft [wm geometry .pgaw:Diagrams] "="]
    set xsize [lindex [split $g "x+"] 0]
    set ysize [lindex [split $g "x+"] 1]

    ::Printer::init "::Diagrams::printcallback"

}; # end proc ::Diagrams::print


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::printcallback {fid} {

    variable xsize
    variable ysize

    # hide the red cross
    .pgaw:Diagrams.c itemconfigure redcross -state hidden

    ::Printer::printStart $fid $xsize $ysize 1
    ::Printer::printPage $fid 1 .pgaw:Diagrams.c
    ::Printer::printStop $fid

    # get the cross back
    .pgaw:Diagrams.c itemconfigure redcross -state normal

}; # end proc ::Diagrams::print


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Diagrams::canvasClick {x y w} {
global PgAcVar
set PgAcVar(diagrams,panstarted) 0
    if {$w==".pgaw:Diagrams.c"} {
        set canpan 1
        if {[llength [.pgaw:Diagrams.c find overlapping $x $y $x $y]]!=0} {set canpan 0}
        set PgAcVar(diagrams,panobject) tables
        if {$canpan} {
            if {[.pgaw:Diagrams.c find withtag hili]!=""} {
                .pgaw:Diagrams.c itemconfigure hili -fill black
                .pgaw:Diagrams.c dtag hili
                .pgaw:Diagrams.c dtag dragme

            }

            .pgaw:Diagrams configure -cursor hand1
            set PgAcVar(diagrams,panstartx) $x
            set PgAcVar(diagrams,panstarty) $y
            set PgAcVar(diagrams,panstarted) 1
        }
    }

}; # end proc ::Diagrams::canvasClick



#==========================================================
# END Diagrams NAMESPACE
# BEGIN VisualTcl
#==========================================================



proc vTclWindow.pgaw:Diagrams {base} {

    global PgAcVar
    global CurrentDB

    if {$base == ""} {
        set base .pgaw:Diagrams
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm geometry $base 760x530+10+13
    wm maxsize $base [winfo screenwidth .] [winfo screenheight .]
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm title $base [intlmsg "Visual Designer"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Key-F1> "::Help::load diagrams"

    canvas $base.c \
        -background #fefefe \
        -borderwidth 2 \
        -relief ridge \
        -takefocus 0 \
        -width 295 \
        -height 300

    bind $base.c <B1-Motion> {
        Diagrams::canvasPanning %x %y
    }
    bind $base.c <Button-1> {
        Diagrams::canvasClick %x %y %W
    }
    bind $base.c <ButtonRelease-1> {
        Diagrams::dragStop %x %y
    }
    bind $base.c <Key-Delete> {
        Diagrams::deleteObject
    }

    Label $base.ltable \
        -borderwidth 0 \
        -text [intlmsg "Add table"]
    ComboBox $base.cbtable \
        -background #fefefe \
        -borderwidth 1 \
        -highlightthickness 0 \
        -values [concat [::Database::getPrefObjList Tables $CurrentDB 0 1] \
            [::Database::getPrefObjList Views $CurrentDB 0 1]] \
        -editable true \
        -textvariable ::Diagrams::newtablename \
        -modifycmd {::Diagrams::addNewTable}
    set ::Diagrams::Win(entertable) $base.cbtable

    LabelEntry $base.lediagram \
        -padx 50 \
        -borderwidth 1 \
        -label [intlmsg "Diagram name"] \
        -textvariable ::Diagrams::diagramname
    set ::Diagrams::Win(diagramname) $base.lediagram

    ButtonBox $base.bbox \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $base.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::filesave-22 \
        -helptext [intlmsg "Save"] \
        -command ::Diagrams::save
    $base.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::filesaveas-22 \
        -helptext [intlmsg "Save As"] \
        -command {::Diagrams::save 1}
    $base.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::fileprint-22 \
        -helptext [intlmsg "Print"] \
        -command ::Diagrams::print
    $base.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::help-22 \
        -helptext [intlmsg "Help"] \
        -command {::Help::load diagrams}
    $base.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::exit-22 \
        -helptext [intlmsg "Close"] \
        -command {
            Diagrams::init
            Window destroy .pgaw:Diagrams
        }

    grid $base.ltable \
        -row 0 \
        -column 0 \
        -sticky e
    grid $base.cbtable \
        -row 0 \
        -column 1 \
        -sticky we
    grid $base.lediagram \
        -row 0 \
        -column 2 \
        -sticky w
    grid $base.bbox \
        -row 0 \
        -column 3 \
        -sticky e
    grid $base.c \
        -row 1 \
        -column 0 \
        -columnspan 4 \
        -sticky news

    grid columnconfigure $base 1 \
        -weight 5
    grid columnconfigure $base 3 \
        -weight 5
    grid rowconfigure $base 1 \
        -weight 10

}
