#==========================================================
# Views --
#
#   handling of PostgreSQL views, most of which is in
#   Queries namespace
#==========================================================
#
namespace eval Views {}


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Views::new {} {

    global PgAcVar

    set PgAcVar(query,oid) 0
    set PgAcVar(query,name) {}

    Window show .pgaw:QueryBuilder

    set PgAcVar(query,asview) 1

    $::Queries::Win(saveasview) configure -state disabled

}; # end proc ::Views::new


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Views::open {viewname_} {

    global PgAcVar

    if {$viewname_==""} return;
    set wn [Tables::getNewWindowName]

    Tables::createWindow

    set PgAcVar(mw,$wn,query) "
        SELECT * FROM [::Database::quoteObject $viewname_]"
    set PgAcVar(mw,$wn,isaquery) 0
    set PgAcVar(mw,$wn,updatable) 0
    set PgAcVar(mw,$wn,ukey) ""

    Tables::loadLayout $wn $viewname_
    Tables::selectRecords $wn $PgAcVar(mw,$wn,query)
    wm title $wn "$viewname_"

    return $wn

}; # end proc ::Views::open


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Views::design {viewname_} {

    global PgAcVar CurrentDB

    set vd {}
    set vdesc {}
    set sql {}

    set viewname_ [string map {\" ""} $viewname_]
    foreach {s t} [split $viewname_ .] {break}
    if {[string length "$t"] == 0} {
        set sql "
            SELECT v.definition,
                   obj_description(c.oid) AS description
              FROM pg_views v,
                   pg_class c
             WHERE v.viewname='$viewname_'
               AND c.relname='$viewname_'"
    } else {
        set sql "
            SELECT v.definition,
                   obj_description(c.oid) AS description
              FROM pg_catalog.pg_views v,
                   pg_catalog.pg_class c,
                   pg_catalog.pg_namespace n
             WHERE v.viewname='$t'
               AND v.schemaname='$s'
               AND c.relname='$t'
               AND c.relnamespace=n.oid"
    }

    wpg_select $CurrentDB $sql tup {
        set vd $tup(definition)
        set vdesc $tup(description)
    }

    if {$vd==""} {
        showError "[intlmsg {Error retrieving view definition for}] '$viewname_'!"
        return
    }

    Window show .pgaw:QueryBuilder
    $::Queries::Win(qrytxt) delete 0.0 end
    $::Queries::Win(qrytxt) insert end $vd

    $::Queries::Win(comtxt) delete 0.0 end
    $::Queries::Win(comtxt) insert end $vdesc

    set PgAcVar(query,asview) 1

    $::Queries::Win(saveasview) configure -state disabled

    set PgAcVar(query,name) $viewname_

    Syntax::highlight $::Queries::Win(qrytxt) sql

}; # end proc ::Views::design


#----------------------------------------------------------
# ::Views::introspect --
#
#   Given a viewname, returns the SQL needed to recreate it
#
# Arguments:
#   viewname_  name of a view to introspect
#   dbh_       an optional database handle
#
# Returns:
#   insql      the CREATE statement to make this view
#----------------------------------------------------------
#
proc ::Views::introspect {viewname_ {dbh_ ""}} {

    set insql [::Views::clone $viewname_ $viewname_ $dbh_]

    return $insql

}; # end proc ::Views::introspect


#----------------------------------------------------------
# ::Views::clone --
#
#   Like introspect, only changes the viewname
#
# Arguments:
#   srcview_    the original view
#   destview_   the clone view
#   dbh_        an optional database handle
#
# Returns:
#   insql       the CREATE statement to clone this view
#----------------------------------------------------------
#
proc ::Views::clone {srcview_ destview_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set insql ""

    set srcview_ [string map {\" {}} $srcview_]

    set sql "SELECT definition
               FROM pg_views
              WHERE viewname='$srcview_'"

    wpg_select $dbh_ $sql rec {
        set insql "
            CREATE VIEW [::Database::quoteObject $destview_]
                     AS $rec(definition)"
    }

    return $insql

}; # end proc ::Views::clone


