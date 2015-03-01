#==========================================================
# Queries --
#
#   provides handling for stored SQL queries
#
#==========================================================
#
namespace eval Queries {
    variable Win
    variable xprintsize
    variable yprintsize
}


#----------------------------------------------------------
# ::Queries::export --
#
#   Given a piece of SQL, exports the results to a file.
#   If no SQL, then use what's in the query window.
#
# Arguments:
#   sql_    the query to execute and export results for
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Queries::export {{sql_ ""}} {

    global CurrentDB

    variable Win

    if {$sql_==""} {
        set sql_ [$Win(qrytxt) get 1.0 end]
    }

    # setup the name for the temporary table
    set tmptbl "results"
    append tmptbl "_" [clock format [clock seconds] -format "%H%M%S"]

    # start the clock and open the import/export window
    setCursor CLOCK
    ::ImportExport::setup 0

    # create the table
    set sql "CREATE TEMP TABLE $tmptbl
                            AS $sql_"
    set pgres [wpg_exec $CurrentDB $sql]
    setCursor NORMAL

    # get one row from the table so we can get a column list
    # may look sloppy but faster than pulling it from the query itself
    set sql "SELECT *
               FROM $tmptbl
              LIMIT 1"
    set pgres [wpg_exec $CurrentDB $sql]
    set lcols [pg_result $pgres -attributes]

    # set a default for the text file
    set ::ImportExport::tablename $tmptbl
    set ::ImportExport::filename $tmptbl.txt
    set ::ImportExport::wizard::tablecols [join $lcols]

}; # end proc ::Tables::export


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Queries::new {} {

    global PgAcVar
    variable Win

    Window show .pgaw:QueryBuilder

    PgAcVar:clean query,*
    set PgAcVar(query,oid) 0
    set PgAcVar(query,name) {}
    set PgAcVar(query,asview) 0
    set PgAcVar(query,tables) {}
    set PgAcVar(query,links) {}
    set PgAcVar(query,results) {}

    $Win(saveasview) configure -state normal

}; # end proc ::Queries::new


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Queries::open {queryname} {

    global PgAcVar

    if {! [loadQuery $queryname]} return;
    if {$PgAcVar(query,type)=="S"} then {
        set wn [Tables::getNewWindowName]
        set PgAcVar(mw,$wn,query) [subst $PgAcVar(query,sqlcmd)]
        set PgAcVar(mw,$wn,updatable) 0
        set PgAcVar(mw,$wn,isaquery) 1
        Tables::createWindow
        wm title $wn "Query result: $PgAcVar(query,name)"
        Tables::loadLayout $wn $PgAcVar(query,name)
        Tables::selectRecords $wn $PgAcVar(mw,$wn,query)
    } else {
        set answ [tk_messageBox -title [intlmsg Warning] -type yesno -message "This query is an action query!\n\n[string range $PgAcVar(query,sqlcmd) 0 30] ...\n\nDo you want to execute it?"]
        if {$answ} {
            if {[sql_exec noquiet $PgAcVar(query,sqlcmd)]} {
                tk_messageBox -title Information -message "Your query has been executed without error!"
            }
        }
    }

    return $wn

}; # end ::Queries::open


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Queries::design {queryname} {

    global PgAcVar
    variable Win

    if {! [loadQuery $queryname]} return;
    Window show .pgaw:QueryBuilder
    $Win(qrytxt) delete 0.0 end
    $Win(qrytxt) insert end $PgAcVar(query,sqlcmd)
    $Win(comtxt) delete 0.0 end
    $Win(comtxt) insert end $PgAcVar(query,comments)

    Syntax::highlight $Win(qrytxt) sql

}; # end proc ::Queries::design


#----------------------------------------------------------
# introspect --
#
#   Given a queryname, returns the SQL needed to recreate
#   it.
#
# Arguments:
#   queryname_  name of a query to introspect
#   dbh_        an optional database handle
#
# Returns:
#   insql       the INSERT statement to make this query
#----------------------------------------------------------
#
proc ::Queries::introspect {queryname_ {dbh_ ""}} {

    set insql [::Queries::clone $queryname_ $queryname_ $dbh_]

    return $insql

}; # end proc ::Queries::introspect


#----------------------------------------------------------
# ::Queries::clone --
#
#   Like introspect, only changes the queryname
#
# Arguments:
#   srcquery_   the original query
#   destquery_  the clone query
#   dbh_        an optional database handle
#
# Returns:
#   insql       the INSERT statement to clone this query
#----------------------------------------------------------
#
proc ::Queries::clone {srcquery_ destquery_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set insql ""

    set sql "SELECT querytype, querycommand, querytables, querylinks, queryresults, querycomments
            FROM pga_queries
            WHERE queryname='$srcquery_'"

    wpg_select $dbh_ $sql rec {
        set insql "
            INSERT INTO pga_queries (querytype, querycommand, querytables, querylinks, queryresults, querycomments, queryname)
            VALUES ('$rec(querytype)','[::Database::quoteSQL $rec(querycommand)]','[::Database::quoteSQL $rec(querytables)]','$rec(querylinks)','$rec(queryresults)','[::Database::quoteSQL $rec(querycomments)]','[::Database::quoteSQL $destquery_]');"
    }

    return $insql

}; # end proc ::Queries::clone


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Queries::loadQuery {queryname {visual 1}} {

    global PgAcVar CurrentDB

    regsub -all {'} $queryname {''} queryname
    regsub -all {\\} $queryname {\\\\} queryname

    set PgAcVar(query,name) $queryname

    set sql "SELECT querycommand, querytype, querytables, querylinks, queryresults, querycomments, oid
               FROM pga_queries
              WHERE queryname=\'$PgAcVar(query,name)\'"
     if {[set pgres [wpg_exec $CurrentDB $sql]]==0} {
        if {$visual} {
            showError [intlmsg "Error retrieving query definition"]
        }
        return 0
    }
    if {[pg_result $pgres -numTuples]==0} {
        if {$visual} {
            showError [format [intlmsg "Query '%s' was not found!"] \
                $PgAcVar(query,name)]
        }
        pg_result $pgres -clear
        return 0
    }

    set tuple [pg_result $pgres -getTuple 0]
    set PgAcVar(query,sqlcmd)   [lindex $tuple 0]
    set PgAcVar(query,type)     [lindex $tuple 1]
    set PgAcVar(query,tables)   [lindex $tuple 2]
    set PgAcVar(query,links)    [lindex $tuple 3]
    set PgAcVar(query,results)  [lindex $tuple 4]
    set PgAcVar(query,comments) [lindex $tuple 5]
    set PgAcVar(query,oid)      [lindex $tuple 6]

    pg_result $pgres -clear

    return 1

}; # end proc ::Queries::loadQuery


#----------------------------------------------------------
# returns the SQL of the query
# for use in, for example, forms
#----------------------------------------------------------
#
proc ::Queries::getSQL {queryname_} {

    global PgAcVar

    if {[loadQuery $queryname_ 0]} {
        return $PgAcVar(query,sqlcmd)
    } else {
        return ""
    }

}; # end proc ::Queries::getSQL


#----------------------------------------------------------
# returns the fields as a list from the query (or SQL)
#----------------------------------------------------------
#
proc ::Queries::getFieldList {queryname_} {

    global PgAcVar CurrentDB

    if {![loadQuery $queryname_ 0]} {
        set PgAcVar(query,sqlcmd) $queryname_
    }
    set pgres [wpg_exec $CurrentDB $PgAcVar(query,sqlcmd)]
    set fields [pg_result $pgres -attributes]
    pg_result $pgres -clear

    return $fields

}; # end proc ::Queries::getFieldList


#----------------------------------------------------------
# returns a list of all the queries in the db
# (defaults to SELECT-type queries only)
#----------------------------------------------------------
#
proc ::Queries::getQueriesList {{type "S"}} {

    global CurrentDB

    set sql "
        SELECT queryname
          FROM pga_queries
         WHERE querytype='$type'"
    set qlist {}
    pg_select $CurrentDB $sql array {
        lappend qlist $array(queryname)
    }

    return $qlist

}; # end proc ::Queries::getQueriesList


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Queries::visualDesigner {} {

    global PgAcVar

    Window show .pgaw:VisualQuery
    VisualQueryBuilder::loadVisualLayout
    focus $::VisualQueryBuilder::Win(entertable)

}; # end proc ::Queries::visualDesigner


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Queries::save {{saveas_ 0}} {

    global PgAcVar CurrentDB
    variable Win

    set overwrite "no"

    if {$PgAcVar(query,name)==""} then {
        showError [intlmsg "You have to supply a name for this query!"]
        focus $Win(qryname)
    } else {
        set qcmd [$Win(qrytxt) get 1.0 end]
        set PgAcVar(query,comments) [$Win(comtxt) get 1.0 end]
        regsub -all "\n" $qcmd " " qcmd
        if {$qcmd==""} then {
            showError [intlmsg "This query has no commands?"]
        } else {
            if { [lindex [split [string toupper [string trim $qcmd]]] 0] == "SELECT" } {
                set qtype S
            } else {
                set qtype A
            }
            # careful we don't f*ck up the view
            # this could look a little cleaner
            if {$PgAcVar(query,asview)} {
                set sql "SELECT pg_get_viewdef('$PgAcVar(query,name)')"
                set pgres [wpg_exec $CurrentDB $sql]
                if {[string length [pg_result $pgres -error]]==0} {
                     set sql "SELECT pg_get_viewdef('$PgAcVar(query,name)')
                                  AS vd"
                     wpg_select $CurrentDB $sql tup {
                        if {$tup(vd)!="Not a view"} {
                            set overwrite [tk_messageBox -title [intlmsg Warning] -message [format [intlmsg "View '%s' already exists!\nOverwrite ?"] $PgAcVar(query,name)] -type yesno -default no]
                            if {$overwrite=="yes"} {
                                # preserve the permissions
                                set grantperms [join [::Database::getPermissionsAsGrants $CurrentDB [::Database::quoteObject $PgAcVar(query,name)] view]]
                                set sql "
                                BEGIN;
                                DROP VIEW [::Database::quoteObject $PgAcVar(query,name)];
                                "
                            }
                        }
                    }
                }
                set sql2 "CREATE VIEW [::Database::quoteObject $PgAcVar(query,name)]
                                  AS $qcmd;"
                if {[string length $sql]>0
                  && $overwrite=="yes"} {
                    append sql $sql2
                    append sql "\n" $grantperms
                    append sql "\n" "COMMIT;"
                } else {
                    set sql $sql2
                }
                set pgres [wpg_exec $CurrentDB $sql]
                if {$PgAcVar(pgsql,status)!="PGRES_COMMAND_OK"} {
                    showError "[intlmsg {Error defining view}]\n\n$PgAcVar(pgsql,errmsg)"
                } else {
                    if {[string length [string trim $PgAcVar(query,comments)]]>0} {
                        regsub -all "'" $PgAcVar(query,comments) "''" PgAcVar(query,comments)
                        set sql3 "COMMENT ON VIEW [::Database::quoteObject $PgAcVar(query,name)] IS '$PgAcVar(query,comments)'"
                        sql_exec noquiet $sql3
                    }
                    Mainlib::tab_click Views
                    Window destroy .pgaw:QueryBuilder
                }
                catch {pg_result $pgres -clear}
            } else {
                regsub -all "'" $qcmd "''" qcmd
                regsub -all "'" $PgAcVar(query,comments) "''" PgAcVar(query,comments)
                regsub -all "'" $PgAcVar(query,results) "''" PgAcVar(query,results)
                setCursor CLOCK
                if {$PgAcVar(query,oid)==0 || $saveas_} then {
                    set sql "INSERT INTO pga_queries (queryname, querytype, querycommand, querytables, querylinks, queryresults, querycomments)
                                  VALUES ('$PgAcVar(query,name)','$qtype','$qcmd','$PgAcVar(query,tables)','$PgAcVar(query,links)','$PgAcVar(query,results)','$PgAcVar(query,comments)')"
                    set pgres [wpg_exec $CurrentDB $sql]
                } else {
                    set sql "UPDATE pga_queries
                                SET queryname='$PgAcVar(query,name)',querytype='$qtype',querycommand='$qcmd',querytables='$PgAcVar(query,tables)',querylinks='$PgAcVar(query,links)',queryresults='$PgAcVar(query,results)',querycomments='$PgAcVar(query,comments)'
                              WHERE oid=$PgAcVar(query,oid)"
                    set pgres [wpg_exec $CurrentDB $sql]
                }
                setCursor DEFAULT
                if {$PgAcVar(pgsql,status)!="PGRES_COMMAND_OK"} then {
                    showError "[intlmsg {Error executing query}]\n$PgAcVar(pgsql,errmsg)"
                } else {
                    Mainlib::tab_click Queries
                    if {$PgAcVar(query,oid)==0} {set PgAcVar(query,oid) [pg_result $pgres -oid]}
                }
                catch {pg_result $pgres -clear}
            }
        }
    }

}; # end proc ::Queries::save


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Queries::execute {} {

    global PgAcVar
    variable Win

    set qcmd [$Win(qrytxt) get 0.0 end]
    regsub -all "\n" [string trim $qcmd] " " qcmd
    if {[lindex [split [string toupper $qcmd]] 0]!="SELECT"} {
        if {[tk_messageBox -title [intlmsg Warning] -parent .pgaw:QueryBuilder -message [intlmsg "This is an action query!\n\nExecute it?"] -type yesno -default no]=="yes"} {
            sql_exec noquiet $qcmd
        }
    } else {
        set wn [Tables::getNewWindowName]
        set PgAcVar(mw,$wn,query) [subst $qcmd]
        set PgAcVar(mw,$wn,updatable) 0
        set PgAcVar(mw,$wn,isaquery) 1
        set PgAcVar(mw,$wn,ukey) ""
        Tables::createWindow
        Tables::loadLayout $wn $PgAcVar(query,name)
        Tables::selectRecords $wn $PgAcVar(mw,$wn,query)
    }

}; # end proc ::Queries::execute


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Queries::close {} {

    global PgAcVar
    variable Win

    $Win(saveasview) configure -state normal
    set PgAcVar(query,asview) 0
    set PgAcVar(query,name) {}
    $Win(qrytxt) delete 1.0 end
    Window destroy .pgaw:QueryBuilder

}; # end proc ::Queries::close


#----------------------------------------------------------
# ::Queries::print --
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
proc ::Queries::print {} {

    global PgAcVar
    variable Win
    variable xprintsize
    variable yprintsize

    if {[info exists Win(tpc)]} {
        destroy $Win(tpc)
    }

    # turn text into canvas
    set Win(tpc) .pgaw:QueryBuilder:PrintCanvas
    canvas $Win(tpc)
    $Win(tpc) create text 20 20 \
        -anchor nw \
        -font $PgAcVar(pref,font_bold) \
        -justify left \
        -width 800 \
        -text $PgAcVar(query,name)
    $Win(tpc) create text 20 40 \
        -anchor nw \
        -font $PgAcVar(pref,font_fix) \
        -justify left \
        -width 800 \
        -text [$Win(qrytxt) get 1.0 end]

    # cant put the comment on top of the query
    $Win(tpc) addtag printem all
    set geo [$Win(tpc) bbox printem]
    set yprintsize [expr {[lindex $geo 3] - [lindex $geo 1]}]
    $Win(tpc) create text 20 [expr {2*$yprintsize}] \
        -anchor nw \
        -font $PgAcVar(pref,font_normal) \
        -justify left \
        -width 800 \
        -text [$Win(comtxt) get 1.0 end]

    $Win(tpc) addtag printem all
    set geo [$Win(tpc) bbox printem]
    set xprintsize [expr {[lindex $geo 2] - [lindex $geo 0]}]
    set yprintsize [expr {[lindex $geo 3] - [lindex $geo 1]}]

    ::Printer::init "::Queries::printcallback"

}; # end proc ::Queries::print


#----------------------------------------------------------
# ::Queries::printcallback --
#
#   Feeds a canvas to the printer
#
# Arguments:
#   fid     open file to stick with canvas
#
#
#----------------------------------------------------------
#
proc ::Queries::printcallback {fid} {

    variable Win
    variable xprintsize
    variable yprintsize

    ::Printer::printStart $fid $xprintsize $yprintsize 1
    ::Printer::printPage $fid 1 $Win(tpc)
    ::Printer::printStop $fid

    destroy $Win(tpc)

}; # end proc ::Queries::printcallback



################### END Queries NAMESPACE
################### BEGIN VisualTcl CODE



proc vTclWindow.pgaw:QueryBuilder {base} {

    global PgAcVar

    if {$base == ""} {
        set base .pgaw:QueryBuilder
    }
    set ::Queries::Win(qb) $base

    if {[winfo exists $base]} {
        wm deiconify $base; return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 542x364+150+150
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Query builder"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Control-Key-s> {::Queries::save}

    bind $base <Key-F1> "Help::load queries"

    frame $base.fr \
        -borderwidth 10
    pack $base.fr \
        -in $base \
        -expand 1 \
        -fill both
    # make the base setting a little easier
    set base $base.fr

    LabelEntry $base.leqn \
        -borderwidth 1 \
        -label [intlmsg "Query name"] \
        -textvariable PgAcVar(query,name)
    set ::Queries::Win(qryname) $base.leqn

    frame $base.fbb \
        -borderwidth 5
    checkbutton $base.fbb.cbsav \
        -borderwidth 1 \
        -text [intlmsg "Save this query as a view"] \
        -variable PgAcVar(query,asview)
    set ::Queries::Win(saveasview) $base.fbb.cbsav

    ButtonBox $base.fbb.bbox \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $base.fbb.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::filesave-22 \
        -helptext [intlmsg "Save query definition"] \
        -command ::Queries::save
    $base.fbb.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::filesaveas-22 \
        -helptext [intlmsg "Save As"] \
        -command {::Queries::save 1}
    $base.fbb.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::misc-16 \
        -helptext [intlmsg "Execute query"] \
        -command ::Queries::execute
    $base.fbb.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::imagegallery-22 \
        -helptext [intlmsg "Visual designer"] \
        -command ::Queries::visualDesigner
    $base.fbb.bbox add \
        -relief link \
        -borderwidth 1 \
        -command {::Queries::print} \
        -helptext [intlmsg "Print"] \
        -image ::icon::fileprint-22
    $base.fbb.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::up-22 \
        -helptext [intlmsg "Export"] \
        -command ::Queries::export
    $base.fbb.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::help-22 \
        -helptext [intlmsg "Help"] \
        -command "::Help::load queries"
    $base.fbb.bbox add \
        -relief link \
        -borderwidth 1 \
        -image ::icon::exit-22 \
        -helptext [intlmsg "Close"] \
        -command ::Queries::close

    frame $base.fsql \
        -borderwidth 5
    text $base.fsql.txt \
        -background #ffffff \
        -borderwidth 1 \
        -font $PgAcVar(pref,font_normal) \
        -foreground #000000 \
        -highlightthickness 0 \
        -wrap word \
        -height 2 \
        -width 2 \
        -tabs {20 40 60 80 100 120 140 160 180 200} \
        -xscrollcommand "$base.fsql.hscroll set" \
        -yscrollcommand "$base.fsql.vscroll set"
    set ::Queries::Win(qrytxt) $base.fsql.txt
    scrollbar $base.fsql.hscroll \
        -orient horiz \
        -command "$base.fsql.txt xview"
    scrollbar $base.fsql.vscroll \
        -command "$base.fsql.txt yview"

    Label $base.lcom \
        -borderwidth 2 \
        -text [intlmsg "Comments"]

    frame $base.fcom \
        -borderwidth 5
    text $base.fcom.txt \
        -background #ffffff \
        -borderwidth 1 \
        -font $PgAcVar(pref,font_normal) \
        -foreground #000000 \
        -highlightthickness 0 \
        -wrap word \
        -height 2 \
        -width 2 \
        -tabs {20 40 60 80 100 120 140 160 180 200} \
        -xscrollcommand "$base.fcom.hscroll set" \
        -yscrollcommand "$base.fcom.vscroll set"
    set ::Queries::Win(comtxt) $base.fcom.txt
    scrollbar $base.fcom.hscroll \
        -orient horiz \
        -command "$base.fcom.txt xview"
    scrollbar $base.fcom.vscroll \
        -command "$base.fcom.txt yview"

    # add Ctrl-x|c|v for cut, copy, paste
    bind $base.fsql.txt <Control-Key-x> {
        set PgAcVar(shared,curseltext) [%W get sel.first sel.last]
        %W delete sel.first sel.last
    }
    bind $base.fsql.txt <Control-Key-c> {
        set PgAcVar(shared,curseltext) [%W get sel.first sel.last]
    }
    bind $base.fsql.txt <Control-Key-v> {
        if {[info exists PgAcVar(shared,curseltext)]} {
            catch {%W delete sel.first sel.last}
            %W insert insert $PgAcVar(shared,curseltext)
            %W see current
        }
    }

    # add Ctrl-x|c|v for cut, copy, paste
    bind $base.fcom.txt <Control-Key-x> {
        set PgAcVar(shared,curseltext) [%W get sel.first sel.last]
        %W delete sel.first sel.last
    }
    bind $base.fcom.txt <Control-Key-c> {
        set PgAcVar(shared,curseltext) [%W get sel.first sel.last]
    }
    bind $base.fcom.txt <Control-Key-v> {
        if {[info exists PgAcVar(shared,curseltext)]} {
            catch {%W delete sel.first sel.last}
            %W insert insert $PgAcVar(shared,curseltext)
            %W see current
        }
    }

    grid $base.leqn \
        -row 0 \
        -column 0 \
        -sticky news

    grid $base.fbb \
        -row 1 \
        -column 0 \
        -sticky news
    pack $base.fbb.cbsav \
        -in $base.fbb \
        -side left
    pack $base.fbb.bbox \
        -in $base.fbb \
        -side right \
        -expand 0 \
        -fill x

    grid $base.fsql \
        -row 2 \
        -column 0 \
        -sticky news
    grid $base.fsql.hscroll \
        -row 1 \
        -column 0 \
        -sticky wen
    grid $base.fsql.vscroll \
        -row 0 \
        -column 1 \
        -sticky swn
    grid $base.fsql.txt \
        -row 0 \
        -column 0 \
        -sticky news
    grid columnconfigure $base.fsql 0 \
        -weight 10
    grid rowconfigure $base.fsql 0 \
        -weight 10

    grid $base.lcom \
        -row 3 \
        -column 0 \
        -sticky news

    grid $base.fcom \
        -row 4 \
        -column 0 \
        -sticky news
    grid $base.fcom.hscroll \
        -row 1 \
        -column 0 \
        -sticky wen
    grid $base.fcom.vscroll \
        -row 0 \
        -column 1 \
        -sticky swn
    grid $base.fcom.txt \
        -row 0 \
        -column 0 \
        -sticky news
    grid columnconfigure $base.fcom 0 \
        -weight 10
    grid rowconfigure $base.fcom 0 \
        -weight 10

    grid columnconfigure $base 0 \
        -weight 10
    grid rowconfigure $base 2 \
        -weight 4
    grid rowconfigure $base 4 \
        -weight 2

}

