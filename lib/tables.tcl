#==========================================================
# Tables --
#
#   creation and management of database tables
#
#==========================================================
#
namespace eval Tables {
    variable Win
}

#------------------------------------------------------------
# ::Tables::export --
#
#   Given an open window name, performs the export of results
#   in that window.
#
# Arguments:
#   wn_     name of a window
#
# Returns:
#   none
#------------------------------------------------------------
#
proc ::Tables::export {wn_} {

    global PgAcVar CurrentDB

    # setup the name for the temporary table
    set tmptbl "results"
    append tmptbl "_" [clock format [clock seconds] -format "%H%M%S"]

    # start the clock and open the import/export window
    setCursor CLOCK
    ::ImportExport::setup 0

    # set a default for the text file
    set ::ImportExport::tablename $tmptbl
    set ::ImportExport::filename $tmptbl.txt
    set ::ImportExport::wizard::tablecols $PgAcVar(mw,$wn_,colnames)

    # create the table
    if {$PgAcVar(mw,$wn_,isaquery)
      || !$PgAcVar(mw,$wn_,updatable)
      || [info exists PgAcVar(mw,$wn_,activequery)]} {
        # if its a query or view then dont worry about the ctid column
        # but we need to clean out the oid column
        set act [string map {"oid," {}} $PgAcVar(mw,$wn_,activequery)]
        set sql "CREATE TEMP TABLE $tmptbl
                                AS $act"
    } else {
        set sql "CREATE TEMP TABLE $tmptbl
                                AS SELECT * FROM $PgAcVar(mw,$wn_,tablename)"
    }
    set pgres [wpg_exec $CurrentDB $sql]
    setCursor NORMAL

};# # end proc ::Tables::export

#----------------------------------------------------------
# ::Tables::introspect --
#
#   Given a tablename, returns the SQL needed to recreate it
#
# Arguments:
#   tablename_  name of a table to introspect
#   dbh_        an optional database handle
#
# Returns:
#   insql       the CREATE and INSERT statements to make this table
#----------------------------------------------------------
#
proc ::Tables::introspect {tablename_ {dbh_ ""}} {

    set insql [::Tables::clone $tablename_ $tablename_ $dbh_]

    return $insql

}; # end proc ::Tables::introspect


#----------------------------------------------------------
# ::Tables::clone --
#
#   Like introspect, only changes the tablename
#
# Arguments:
#   srctable_   the original table
#   desttable_  the clone table
#   dbh_        an optional database handle
#
# Returns:
#   insql       the INSERT statement to clone this table
#----------------------------------------------------------
#
proc ::Tables::clone {srctable_ desttable_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set insql ""
    set colnames ""

    # first we build the CREATE statement
    set insql "CREATE TABLE $desttable_ ("
    foreach c [::Database::getColumnsTypesList $srctable_ $dbh_] {
        append colnames [lindex $c 0] ","
        append insql [lindex $c 0] " " [lindex $c 1] ","
    }
    set colnames [string trimright $colnames ,]
    set insql [string trimright $insql ,]
    append insql ");"

    # then we built INSERT statements for each row in the table
    set sql "SELECT $colnames
               FROM [::Database::quoteObject $srctable_]"
    wpg_select $dbh_ $sql rec {
        append insql "INSERT INTO [::Database::quoteObject $desttable_] ($colnames) VALUES ("
        foreach c [split $colnames ,] {
            # lets check for empty fields and replace them with NULLs
            if {[string length $rec($c)] == 0 } {
                append insql "NULL,"
            } else {
                append insql "'" [::Database::quoteSQL $rec($c)] "',"
            }
        }
        set insql [string trimright $insql ,]
        append insql ");"
    }

    return $insql

}; # end proc ::Tables::clone


# ---------------------------------------------------------------
#
#   For tables design
#
# ---------------------------------------------------------------
#
proc ::Tables::design {tablename} {

    global PgAcVar CurrentDB

    if {$CurrentDB==""} return;
    set PgAcVar(tblinfo,tablename) $tablename
    Window show .pgaw:TableInfo
    wm title .pgaw:TableInfo "[intlmsg {Table information}] : $PgAcVar(tblinfo,tablename)"

}; # end proc ::Tables::design


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::addNewIndex {} {

    global PgAcVar

    set iflds [$PgAcVar(tblinfo,cols) curselection]
    if {$iflds==""} {
        showError [intlmsg "You have to select index fields!"]
        return
    }
    set ifldslist {}
    foreach i $iflds {
        lappend ifldslist "\"[lindex [$PgAcVar(tblinfo,cols) get $i] 0]\""
    }
    set PgAcVar(addindex,indexname) $PgAcVar(tblinfo,tablename)_[join $ifldslist _]
    # Replace the quotes with underlines
    regsub -all {"} $PgAcVar(addindex,indexname) {_} PgAcVar(addindex,indexname)
    # Replace the double underlines
    while {[regsub -all {__} $PgAcVar(addindex,indexname) {_} PgAcVar(addindex,indexname)]} {}
    # Replace the final underline
    regsub -all {_$} $PgAcVar(addindex,indexname) {} PgAcVar(addindex,indexname)
    set PgAcVar(addindex,indexfields) [join $ifldslist ,]
    Window show .pgaw:AddIndex
    wm transient .pgaw:AddIndex .pgaw:TableInfo

}; # end proc ::Tables::addNewIndex


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::deleteIndex {} {

    global PgAcVar

    set sel [$PgAcVar(tblinfo,indexes) curselection]
    if {$sel == ""} {
        showError [intlmsg "You have to select an index!"]
        return
    }
    if {[tk_messageBox -title [intlmsg Warning] -parent .pgaw:TableInfo \
            -message [format [intlmsg "You choose to delete index\n\n %s \n\nProceed?"] [lindex [$PgAcVar(tblinfo,indexes) get $sel] 0]] \
            -type yesno -default no]=="no"} {return}
    if {[sql_exec noquiet "DROP INDEX \"[lindex [$PgAcVar(tblinfo,indexes) get $sel] 0]\""]} {
        refreshInfo Indexes
    }

}; # end proc ::Tables::deleteIndex


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::clusterIndex {{mw_ ""}} {

    global PgAcVar

    set sel [$PgAcVar(tblinfo,indexes) curselection]
    if {$sel == ""} {
        # its not an index but a table that we are clustering
        #
        # this should move to the database namespace
        # because it is only available in PG 7.4 (maybe 7.3) or later
        #
        if {[tk_messageBox \
                    -title [intlmsg Warning] \
                    -parent .pgaw:TableInfo \
                    -message [format [intlmsg "You choose to cluster table\n\n %s \n\nProceed?"] [::Database::quoteObject $PgAcVar(tblinfo,tablename)]] \
                    -type yesno -default no]=="no"} {return}

        if {[sql_exec noquiet "CLUSTER [::Database::quoteObject $PgAcVar(tblinfo,tablename)]"]} {
            refreshInfo Indexes
        }
    } else {
        if {[tk_messageBox \
                    -title [intlmsg Warning] \
                    -parent .pgaw:TableInfo \
                    -message [format [intlmsg "You choose to cluster index\n\n %s \n\nAll other indices will be lost!\nProceed?"] [lindex [$PgAcVar(tblinfo,indexes) get $sel] 0]] \
                    -type yesno -default no]=="no"} {return}

        if {[sql_exec noquiet "CLUSTER \"[lindex [$PgAcVar(tblinfo,indexes) get $sel] 0]\" ON [::Database::quoteObject $PgAcVar(tblinfo,tablename)]"]} {
            refreshInfo Indexes
        }
    }

}; # end proc ::Tables::clusterIndex


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::addNewColumn {} {

    global PgAcVar

    if {$PgAcVar(addfield,name)==""} {
        showError [intlmsg "Empty field name ?"]
        focus .pgaw:AddField.e1
        return
    }
    if {$PgAcVar(addfield,type)==""} {
        showError [intlmsg "No field type ?"]
        focus .pgaw:AddField.e2
        return
    }
    if {![sql_exec quiet "
        ALTER TABLE \"$PgAcVar(tblinfo,tablename)\"
         ADD COLUMN \"$PgAcVar(addfield,name)\" $PgAcVar(addfield,type)"]} {
        showError "[intlmsg {Cannot add column}]\n\n$PgAcVar(pgsql,errmsg)"
        return
    }
    Window destroy .pgaw:AddField
    sql_exec quiet "
        UPDATE pga_layout
           SET colnames=colnames || ' {$PgAcVar(addfield,name)}', colwidth=colwidth || ' 150',nrcols=nrcols+1
         WHERE tablename='$PgAcVar(tblinfo,tablename)'"
    refreshInfo Columns

}; # end proc ::Tables::addNewColumn


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::renameColumn {} {

    global PgAcVar CurrentDB

    if {[string length [string trim $PgAcVar(tblinfo,new_cn)]]==0} {
        showError [intlmsg "Field name not entered!"]
        return
    }
    set PgAcVar(tblinfo,new_cn) [string trim $PgAcVar(tblinfo,new_cn)]
    if {$PgAcVar(tblinfo,old_cn) == $PgAcVar(tblinfo,new_cn)} {
        showError [intlmsg "New name is the same as the old one!"]
        return
    }
    foreach col [$PgAcVar(tblinfo,cols) get 0 end] {
        if {[lindex $col 0]==$PgAcVar(tblinfo,new_cn)} {
            showError [format [intlmsg {Column name '%s' already exists in this table!}] $PgAcVar(tblinfo,new_cn)]
            return
        }
    }

    if {[sql_exec noquiet "
        ALTER TABLE \"$PgAcVar(tblinfo,tablename)\"
      RENAME COLUMN \"$PgAcVar(tblinfo,old_cn)\"
                 TO \"$PgAcVar(tblinfo,new_cn)\""]} {
        refreshInfo Columns
        Window destroy .pgaw:RenameField
        #
        # this should rebuild the index frame but it doesnt
        #
        #.pgaw:TableInfo.f2.fl.ilb insert end [::Database::getTableIndexes $PgAcVar(tblinfo,tablename)]
        #
        # showing permissions
        set temp $PgAcVar(tblinfo,permissions)
        regsub "^\{" $temp {} temp
        regsub "\}$" $temp {} temp
        regsub -all "\"" $temp {} temp
        foreach token [split $temp ,] {
            set oli [split $token =]
            set uname [lindex $oli 0]
            set rights [lindex $oli 1]
            if {$uname == ""} {set uname PUBLIC}
            set r_select " "
            set r_update " "
            set r_insert " "
            set r_rule   " "
            if {[string first r $rights] != -1} {set r_select x}
            if {[string first w $rights] != -1} {set r_update x}
            if {[string first a $rights] != -1} {set r_insert x}
            if {[string first R $rights] != -1} {set r_rule   x}
            #
            # changing the format of the following line can affect the loadPermissions procedure
            # see below
            # well this line doesnt work anymore
            #.pgaw:TableInfo.f3.plb insert end [format "%-23.23s %11s %11s %11s %11s" $uname $r_select $r_update $r_insert $r_rule]
        }
    }
}; # end proc ::Tables::renameColumn


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::loadPermissions {} {

    global PgAcVar

    set sel [$PgAcVar(tblinfo,perms) curselection]
    if {$sel == ""} {
        bell
        return
    }
    set uname [lindex [$PgAcVar(tblinfo,perms) get $sel] 0]
    Window show .pgaw:Permissions
    wm transient .pgaw:Permissions .pgaw:TableInfo
    set PgAcVar(permission,username) $uname
    set PgAcVar(permission,select) [expr {"x"==[lindex [$PgAcVar(tblinfo,perms) get $sel] 1]}]
    set PgAcVar(permission,update) [expr {"x"==[lindex [$PgAcVar(tblinfo,perms) get $sel] 2]}]
    set PgAcVar(permission,insert) [expr {"x"==[lindex [$PgAcVar(tblinfo,perms) get $sel] 3]}]
    set PgAcVar(permission,rule)   [expr {"x"==[lindex [$PgAcVar(tblinfo,perms) get $sel] 4]}]
    focus .pgaw:Permissions.f1.ename

}; # end proc ::Tables::loadPermissions


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::savePermissions {} {

    global PgAcVar

    if {$PgAcVar(permission,username) == ""} {
        showError [intlmsg "User without name?"]
        return
    }
    if {$PgAcVar(permission,username)=="PUBLIC"} {
        set usrname PUBLIC
    } else {
        set usrname "\"$PgAcVar(permission,username)\""
    }
    sql_exec noquiet "revoke all on [::Database::quoteObject $PgAcVar(tblinfo,tablename)] from $usrname"
    if {$PgAcVar(permission,select)} {
        sql_exec noquiet "GRANT SELECT on [::Database::quoteObject $PgAcVar(tblinfo,tablename)] to $usrname"
    }
    if {$PgAcVar(permission,insert)} {
        sql_exec noquiet "GRANT INSERT on [::Database::quoteObject $PgAcVar(tblinfo,tablename)] to $usrname"
    }
    if {$PgAcVar(permission,update)} {
        sql_exec noquiet "GRANT UPDATE on [::Database::quoteObject $PgAcVar(tblinfo,tablename)] to $usrname"
    }
    if {$PgAcVar(permission,rule)} {
        sql_exec noquiet "GRANT RULE on [::Database::quoteObject $PgAcVar(tblinfo,tablename)] to $usrname"
    }
    refreshInfo Permissions

}; # end proc ::Tables::savePermissions


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::refreshInfo {page} {

    global PgAcVar CurrentDB

    switch $page {
        "General" {    
            set recs [::Database::getTableInfo $PgAcVar(tblinfo,tablename)]
            foreach recl $recs {
                 array set rec $recl
                set PgAcVar(tblinfo,owner) $rec(usename)
                set PgAcVar(tblinfo,tableoid) $rec(oid)
                set PgAcVar(tblinfo,ownerid) $rec(usesysid)
                set PgAcVar(tblinfo,numtuples) $rec(reltuples)
                set PgAcVar(tblinfo,numpages) $rec(relpages)
                set PgAcVar(tblinfo,permissions) $rec(relacl)
                if {$rec(relhaspkey)=="t"} {
                    set PgAcVar(tblinfo,hasprimarykey) [intlmsg Yes]
                } else {
                    set PgAcVar(tblinfo,hasprimarykey) [intlmsg No]
                }
                if {$rec(relhasrules)=="t"} {
                    set PgAcVar(tblinfo,hasrules) [intlmsg Yes]
                } else {
                    set PgAcVar(tblinfo,hasrules) [intlmsg No]
                }
            }
        }
        "Columns" {
            $PgAcVar(tblinfo,cols) delete 0 end
            set recs [::Database::getTableInfo $PgAcVar(tblinfo,tablename)]
             foreach recl $recs {
                array set rec $recl
                set fsize $rec(attlen)
                set fsize1 $rec(atttypmod)
                set ftype $rec(typname)
                if { $fsize=="-1" && $fsize1!="-1" } {
                    set fsize $rec(atttypmod)
                    incr fsize -4
                }
                if { $fsize1=="-1" && $fsize=="-1" } {
                    set fsize ""
                }
                if {$rec(attnotnull) == "t"} {
                    set notnull "NOT NULL"
                } else {
                    set notnull {}
                }
                if {$rec(attnum)>0} {
                    $PgAcVar(tblinfo,cols) insert end [list $rec(attname) $ftype $fsize $notnull]
                }
            }
        }
        "Indexes" {
            $PgAcVar(tblinfo,indexes) delete 0 end
            foreach idxname [::Database::getTableIndexes $PgAcVar(tblinfo,tablename)] {
                wpg_select $CurrentDB "SELECT pg_index.*,pg_class.oid
                                FROM [::Database::qualifySysTable pg_index],[::Database::qualifySysTable pg_class] 
                                WHERE pg_class.relname='$idxname' 
                                    AND pg_class.oid=pg_index.indexrelid" rec {
                    if {$rec(indisunique)=="t"} {
                        set isunique [intlmsg Yes]
                    } else {
                        set isunique [intlmsg No]
                    }
                    if {$rec(indisclustered)=="t"} {
                        set isclustered [intlmsg Yes]
                    } else {
                        set isclustered [intlmsg No]
                    }
                    set indexfields {}
                    foreach field $rec(indkey) {
                        if {$field!=0} {
                            wpg_select $CurrentDB "SELECT attname FROM [::Database::qualifySysTable pg_attribute] WHERE attrelid=$PgAcVar(tblinfo,tableoid) AND attnum=$field" rec1 {
                                lappend indexfields $rec1(attname)
                            }
                        }
                    }
                    $PgAcVar(tblinfo,indexes) insert end [list $idxname [join $indexfields ,] $isunique $isclustered]
                }
            }
        }
        "Permissions" {
            set recs [::Database::getTableInfo $PgAcVar(tblinfo,tablename)]
            foreach recl $recs {
                 array set rec $recl
                set PgAcVar(tblinfo,permissions) $rec(relacl)
            }
            $PgAcVar(tblinfo,perms) delete 0 end
            set temp $PgAcVar(tblinfo,permissions)
            regsub "^\{" $temp {} temp
            regsub "\}$" $temp {} temp
            regsub -all "\"" $temp {} temp
            foreach token [split $temp ,] {
                set oli [split $token =]
                set uname [lindex $oli 0]
                set rights [lindex $oli 1]
                if {$uname == ""} {set uname PUBLIC}
                set r_select ""
                set r_update ""
                set r_insert ""
                set r_rule   ""
                if {[string first r $rights] != -1} {set r_select x}
                if {[string first w $rights] != -1} {set r_update x}
                if {[string first a $rights] != -1} {set r_insert x}
                if {[string first R $rights] != -1} {set r_rule   x}
                $PgAcVar(tblinfo,perms) insert end [list $uname $r_select $r_update $r_insert $r_rule]
            }
        }
    }

}; # end proc ::Tables::refreshInfo


# ---------------------------------------------------------------
#
#    For tables new/open/
#
# ---------------------------------------------------------------
proc ::Tables::new {} {

    PgAcVar:clean nt,*
    Window show .pgaw:NewTable
    focus .pgaw:NewTable.etabn

}; # end proc ::Tables::new


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::open {tablename {filter ""} {order ""}} {

    global PgAcVar

    set wn [getNewWindowName]
    createWindow
    set PgAcVar(mw,$wn,tablename) $tablename
    loadLayout $wn $tablename

        foreach {a b} [split $order] break
        if {![info exists a]} {set a ""}
        if {![info exists b]} {set b ""}
    set PgAcVar(mw,$wn,sortfield) $a
    set PgAcVar(mw,$wn,sortdirection) $b
    set PgAcVar(mw,$wn,filter) $filter
    #set PgAcVar(mw,$wn,query) "SELECT oid,\"$tablename\".* FROM \"$tablename\""

###    set l [split $tablename .]
###    if {[llength $l] == 2} {
###        set s [lindex $l 0]
###        set t [lindex $l 1]
###        set PgAcVar(mw,$wn,query) "SELECT ctid,* FROM \"$s\".\"$t\""
###    } else {
###        set PgAcVar(mw,$wn,query) "SELECT ctid,* FROM \"$tablename\""
###    }

    set PgAcVar(mw,$wn,ukey) [::Database::getUniqueKeys $::CurrentDB [::Database::quoteObject $tablename]]

    set PgAcVar(mw,$wn,updatable) 1
    if {[llength $PgAcVar(mw,$wn,ukey)] == 0} {
        set PgAcVar(mw,$wn,updatable) 0
    }
#puts "*** UNIQUE $tablename : $PgAcVar(mw,$wn,ukey)"
    set PgAcVar(mw,$wn,query) "SELECT [join [linsert $PgAcVar(mw,$wn,ukey) end *] ,]
                                 FROM [::Database::quoteObject $tablename]"
#puts "$PgAcVar(mw,$wn,query)"

    set PgAcVar(mw,$wn,isaquery) 0
    initVariables $wn
    refreshRecords $wn
    catch {wm title $wn "$tablename"}

    return $wn

}; # end proc ::Tables::open


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::get_tag_info {wn itemid prefix} {

    set taglist [$wn.c itemcget $itemid -tags]
    set i [lsearch -glob $taglist $prefix*]
    set thetag [lindex $taglist $i]

    return [string range $thetag 1 end]

}; # end proc ::Tables::get_tag_info


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::dragMove {w x y} {

    global PgAcVar

    set dlo ""
    catch { set dlo $PgAcVar(draglocation,obj) }
    if {$dlo != ""} {
        set dx [expr {$x - $PgAcVar(draglocation,x)}]
        set dy [expr {$y - $PgAcVar(draglocation,y)}]
        $w move $dlo $dx $dy
        set PgAcVar(draglocation,x) $x
        set PgAcVar(draglocation,y) $y
    }

}; # end proc ::Tables::dragMove


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::dragStart {wn w x y} {

    global PgAcVar

    PgAcVar:clean draglocation,*
    set object [$w find closest $x $y]
    if {[lsearch [$wn.c gettags $object] movable]==-1} return;
    $wn.c bind movable <Leave> {}
    set PgAcVar(draglocation,obj) $object
    set PgAcVar(draglocation,x) $x
    set PgAcVar(draglocation,y) $y
    set PgAcVar(draglocation,start) $x

}; # end proc ::Tables::dragStart


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::dragStop {wn w x y} {

    global PgAcVar CurrentDB

    set dlo ""
    catch { set dlo $PgAcVar(draglocation,obj) }
    if {$dlo != ""} {
        $wn.c bind movable <Leave> "$wn configure -cursor left_ptr"
        $wn configure -cursor left_ptr
        set ctr [get_tag_info $wn $PgAcVar(draglocation,obj) v]
        set diff [expr {$x-$PgAcVar(draglocation,start)}]
        if {$diff==0} return;
        set newcw {}
        for {set i 0} {$i<$PgAcVar(mw,$wn,colcount)} {incr i} {
            if {$i==$ctr} {
        lappend newcw [expr {[lindex $PgAcVar(mw,$wn,colwidth) $i]+$diff}]
            } else {
        lappend newcw [lindex $PgAcVar(mw,$wn,colwidth) $i]
            }
        }
        set PgAcVar(mw,$wn,colwidth) $newcw
        $wn.c itemconfigure c$ctr -width [expr {[lindex $PgAcVar(mw,$wn,colwidth) $ctr]-5}]
        drawHeaders $wn
        drawHorizontalLines $wn
        if {$PgAcVar(mw,$wn,crtrow)!=""} {showRecord $wn $PgAcVar(mw,$wn,crtrow)}
        for {set i [expr {$ctr+1}]} {$i<$PgAcVar(mw,$wn,colcount)} {incr i} {
            $wn.c move c$i $diff 0
        }
        setCursor CLOCK
        sql_exec quiet "UPDATE pga_layout SET colwidth='$PgAcVar(mw,$wn,colwidth)' WHERE tablename='$PgAcVar(mw,$wn,layout_name)'"
        setCursor DEFAULT
    }

    if {![string match "" $PgAcVar(mw,$wn,sortfield)]} {
        moveArrow $wn $PgAcVar(mw,$wn,sortfield)
    }

}; # end proc ::Tables::dragStop


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::canvasClick {wn x y} {

    global PgAcVar

    if {![finishEdit $wn]} return
    # make sure we have a valid window
    if {![info exists PgAcVar(mw,$wn,nrecs)]} {return}
    # Determining row
    for {set row 0} {$row<$PgAcVar(mw,$wn,nrecs)} {incr row} {
        if {[lindex $PgAcVar(mw,$wn,rowy) $row]>$y} break
    }
    incr row -1
    if {$y>[lindex $PgAcVar(mw,$wn,rowy) $PgAcVar(mw,$wn,last_rownum)]} {set row $PgAcVar(mw,$wn,last_rownum)}
    if {$row<0} return
    set PgAcVar(mw,$wn,row_edited) $row
    set PgAcVar(mw,$wn,crtrow) $row
    showRecord $wn $row
    if {$PgAcVar(mw,$wn,errorsavingnew)} return
    # Determining column
    set posx [expr {-$PgAcVar(mw,$wn,leftoffset)}]
    set col 0
    foreach cw $PgAcVar(mw,$wn,colwidth) {
        incr posx [expr {$cw+2}]
        if {$x<$posx} break
        incr col
    }
    set itlist [$wn.c find withtag r$row]
    foreach item $itlist {
        if {[get_tag_info $wn $item c]==$col} {
            startEdit $wn $item $x $y
            break
        }
    }

}; # end proc ::Tables::canvasClick


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::deleteRecord {wn} {

    global PgAcVar CurrentDB

    if {!$PgAcVar(mw,$wn,updatable)} return;
    if {![finishEdit $wn]} return;
    set taglist [$wn.c gettags hili]
    if {[llength $taglist]==0} return;
    set rowtag [lindex $taglist [lsearch -regexp $taglist "^r"]]
    set row [string range $rowtag 1 end]
    #set ctid [lindex $PgAcVar(mw,$wn,keylist) $row]
    set ukey [lindex $PgAcVar(mw,$wn,keylist) $row]
    if {[tk_messageBox \
        -title [intlmsg "FINAL WARNING"] \
        -icon question \
        -parent $wn \
        -message [intlmsg "Delete current record ?"] \
        -type yesno \
        -default no]=="no"} return

    set where [list]
    foreach K $PgAcVar(mw,$wn,ukey) V $ukey {
        lappend where ${K}='${V}'
    }
    if {[sql_exec noquiet "
        DELETE FROM [::Database::quoteObject $PgAcVar(mw,$wn,tablename)]
              WHERE [join $where " AND "]"]} {
        $wn.c delete hili
    }

}; # end proc ::Tables::deleteRecord


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::drawHeaders {wn} {

    global PgAcVar

    $wn.c delete header
    set posx [expr {5-$PgAcVar(mw,$wn,leftoffset)}]
        set i 0
        foreach W $PgAcVar(mw,$wn,colwidth) N $PgAcVar(mw,$wn,colnames) {
        set xf [expr {$posx+$W}]

        $wn.c create rectangle $posx 1 $xf 22 \
                    -fill #CCCCCC \
                    -outline "" \
                    -width 0 \
                    -tags [list header $N ${N}rect moveable]

        $wn.c create text [expr {$posx+$W*1.0/2}] 14 \
                    -text $N \
                    -tags [list header $N] \
                    -fill navy \
                    -font $PgAcVar(pref,font_normal)

        $wn.c create line $posx 22 [expr {$xf-1}] 22 \
                    -fill #AAAAAA \
                    -tags header

        $wn.c create line [expr {$xf-1}] 5 [expr {$xf-1}] 22 \
                    -fill #AAAAAA \
                    -tags header

        $wn.c create line [expr {$xf+1}] 5 [expr {$xf+1}] 22 \
                    -fill white \
                    -tags header

        $wn.c create line $xf -15000 $xf 15000 \
                    -fill #CCCCCC \
                    -tags [list header movable v$i]

        set posx [expr {$xf+2}]

                $wn.c bind $N <Double-Button-1> [list Tables::sortFromHeader $wn $N]

                if {![info exists PgAcVar(mw,$wn,$N,sortdirection)]} {
                    set PgAcVar(mw,$wn,$N,sortdirection) "DESC" 
                }

                incr i
    }

        ##
        ##    Create the arrow now, so later
        ##    we can move it. Also give it
        ##    the same background as the
        ##    header rectangle
        ##
        $wn.c create polygon 0 0 0 0 0 0 \
            -tags [list arrow triangle] \
            -fill #CCCCCC

        $wn.c create line 0 0 0 0 \
            -tags [list arrow darkline] \
            -fill #CCCCCC

        $wn.c create line 0 0 0 0 \
            -tags [list arrow lightline] \
            -fill #CCCCCC

    set PgAcVar(mw,$wn,r_edge) $posx
    $wn.c bind movable <Button-1> "Tables::dragStart $wn %W %x %y"
    $wn.c bind movable <B1-Motion> {Tables::dragMove %W %x %y}
    $wn.c bind movable <ButtonRelease-1> "Tables::dragStop $wn %W %x %y"
    $wn.c bind movable <Enter> "$wn configure -cursor left_side"
    $wn.c bind movable <Leave> "$wn configure -cursor left_ptr"

}; # end proc ::Tables::drawHeaders


#----------------------------------------------------------
# ::Tables::moveArrow --
#
#    Draws the arrow on the header for the selected column
#
# Arguments:
#    wn_    The window for the table display
#    name_  The name of the column
#
# Results:
#    0 if Arrow is drawn header.
#   -1 if column doesn't exist (ie bad query)
#----------------------------------------------------------
#
proc ::Tables::moveArrow {wn_ name_} {

    global PgAcVar

    array set clr {triangle #BBBBBB darkline #666666 lightline #E0E0E0}

    set can ${wn_}.c

    foreach {x1 y1 x2 y2} [$can bbox ${name_}rect] {break}

    if {![info exists y2]} {
        return -1
    }

    set ymarg [expr {($y2 - $y1 - 8)/2}]

    set X1 [expr {$x2 - 12}]
    set X2 [expr {$X1 + 8}]
    set X3 [expr {$X1 + 4}]

    if {[string match "ASC" $PgAcVar(mw,$wn_,$name_,sortdirection)]} {

        set Y1 [expr {$y2 - $ymarg}]
        set Y2 $Y1
        set Y3 [expr {$y1 + $ymarg}]

        $can coords triangle $X1 $Y1 $X2 $Y2 $X3 $Y3
        $can coords darkline $X3 $Y3 $X1 $Y1
        $can coords lightline $X1 $Y1 $X2 $Y2 $X3 $Y3

    } else {

        set Y1 [expr {$y1 + $ymarg}]
        set Y2 $Y1
        set Y3 [expr {$y2 - $ymarg}]

        $can coords triangle $X1 $Y1 $X2 $Y2 $X3 $Y3
        $can coords darkline $X3 $Y3 $X1 $Y1 $X2 $Y2
        $can coords lightline $X2 $Y2 $X3 $Y3

    }

    foreach i {triangle darkline lightline} {
        $can itemconfigure $i -fill $clr($i) -tags [list arrow $i $name_]
    }

    $can raise arrow

    return

}; # end proc ::Tables::moveArrow


#----------------------------------------------------------
# ::Tables::sortFromHeader --
#
#    Sorts a table based on the column that was selected
#
# Arguments:
#    wn_    The window of the table display
#    name_  The name of the column that was selected
#
# Results:
#    nothing return. The selected column gets sorted
#----------------------------------------------------------
#
proc ::Tables::sortFromHeader {wn_ name_} {

    global PgAcVar

    set PgAcVar(mw,$wn_,sortfield) $name_

    if {[string match -nocase "DESC" $PgAcVar(mw,$wn_,$name_,sortdirection)]} {
        set PgAcVar(mw,$wn_,$name_,sortdirection) "ASC"
    } else {
        set PgAcVar(mw,$wn_,$name_,sortdirection) "DESC"
    }
    refreshRecords $wn_

    return

}; # end proc ::Tables::sortFromHeader


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::drawHorizontalLines {wn} {

    global PgAcVar

    $wn.c delete hgrid
    set posx 10
    for {set j 0} {$j<$PgAcVar(mw,$wn,colcount)} {incr j} {
        set ledge($j) $posx
        incr posx [expr {[lindex $PgAcVar(mw,$wn,colwidth) $j]+2}]
        set textwidth($j) [expr {[lindex $PgAcVar(mw,$wn,colwidth) $j]-5}]
    }
    incr posx -6
    for {set i 0} {$i<$PgAcVar(mw,$wn,nrecs)} {incr i} {
        $wn.c create line [expr {-$PgAcVar(mw,$wn,leftoffset)}] [lindex $PgAcVar(mw,$wn,rowy) [expr {$i+1}]] [expr {$posx-$PgAcVar(mw,$wn,leftoffset)}] [lindex $PgAcVar(mw,$wn,rowy) [expr {$i+1}]] -fill gray -tags [subst {hgrid g$i}]
    }
    if {$PgAcVar(mw,$wn,updatable)} {
        set i $PgAcVar(mw,$wn,nrecs)
        set posy [expr {14+[lindex $PgAcVar(mw,$wn,rowy) $PgAcVar(mw,$wn,nrecs)]}]
        $wn.c create line [expr {-$PgAcVar(mw,$wn,leftoffset)}] $posy [expr {$posx-$PgAcVar(mw,$wn,leftoffset)}] $posy -fill gray -tags [subst {hgrid g$i}]
    }

}; # end proc ::Tables::drawHorizontalLines


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::drawNewRecord {wn} {

    global PgAcVar

    set posx [expr {10-$PgAcVar(mw,$wn,leftoffset)}]
    set posy [lindex $PgAcVar(mw,$wn,rowy) $PgAcVar(mw,$wn,last_rownum)]
    if {$PgAcVar(pref,tvfont)=="helv"} {
        set tvfont $PgAcVar(pref,font_normal)
    } else {
        set tvfont $PgAcVar(pref,font_fix)
    }
    if {$PgAcVar(mw,$wn,updatable)} {
      for {set j 0} {$j<$PgAcVar(mw,$wn,colcount)} {incr j} {
        $wn.c create text $posx $posy -text * -tags [list r$PgAcVar(mw,$wn,nrecs) c$j q new unt]  -anchor nw -font $tvfont -width [expr {[lindex $PgAcVar(mw,$wn,colwidth) $j]-5}]
        incr posx [expr {[lindex $PgAcVar(mw,$wn,colwidth) $j]+2}]
      }
      incr posy 14
      $wn.c create line [expr {-$PgAcVar(mw,$wn,leftoffset)}] $posy [expr {$PgAcVar(mw,$wn,r_edge)-$PgAcVar(mw,$wn,leftoffset)}] $posy -fill gray -tags [list hgrid g$PgAcVar(mw,$wn,nrecs)]
    }

}; # end proc ::Tables::drawNewRecord


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::editMove { wn {distance 1} {position end} } {

    global PgAcVar

    # This routine moves the cursor some relative distance
    # from one cell being editted to another cell in the table.
    # Typical distances are 1, +1, $PgAcVar(mw,$wn,colcount), and 
    # -$PgAcVar(mw,$wn,colcount).  Position is where
    # the cursor will be placed within the cell.  The valid
    # positions are 0 and end.

    # get the current row and column
    set current_cell_id $PgAcVar(mw,$wn,id_edited)
    set tags [$wn.c gettags $current_cell_id] 
    regexp {r([0-9]+)} $tags match crow
    regexp {c([0-9]+)} $tags match ccol


    # calculate next row and column
    set colcount $PgAcVar(mw,$wn,colcount)
    set ccell [expr {($crow * $colcount) + $ccol}]
    set ncell [expr {$ccell + $distance}]
    set nrow [expr {$ncell / $colcount}]
    set ncol [expr {$ncell % $colcount}]


    # find the row of the next cell
    if {$distance < 0} {
        set row_increment -1
    } else {
        set row_increment 1
    }
    set id_tuple [$wn.c find withtag r$nrow] 
    # skip over deleted rows...
    while {[llength $id_tuple] == 0} {
        # case above first row of table
        if {$nrow < 0} {
            return
        # case at or beyond last row of table
        } elseif {$nrow >= $PgAcVar(mw,$wn,nrecs)} {
            if {![insertNewRecord $wn]} {
           set PgAcVar(mw,$wn,errorsavingnew) 1
            return
          }
          set id_tuple [$wn.c find withtag r$nrow] 
          break
        }
    incr nrow $row_increment
        set id_tuple [$wn.c find withtag r$nrow] 
    }

    # find the widget id of the next cell
    set next_cell_id [lindex [lsort -integer $id_tuple] $ncol]
    if {[string compare $next_cell_id {}] == 0} {
        set next_cell_id [$wn.c find withtag $current_cell_id]
    }

    # make sure that the new cell is in the visible window
    set toprec $PgAcVar(mw,$wn,toprec)
    set numscreenrecs [getVisibleRecordsCount $wn]
    if {$nrow < $toprec} {
       # case nrow above visable window
       scrollWindow $wn moveto \
        [expr {$nrow *[recordSizeInScrollbarUnits $wn]}]
    } elseif {$nrow > ($toprec + $numscreenrecs - 1)} {
       # case nrow below visable window
        scrollWindow $wn moveto \
        [expr {($nrow - $numscreenrecs + 2) * [recordSizeInScrollbarUnits $wn]}]
    }
    # I need to find a better way to pan -kk
    foreach {x1 y1 x2 y2}  [$wn.c bbox $next_cell_id] {break}
    while {$x1 <= $PgAcVar(mw,$wn,leftoffset)} {
        panRight $wn
        foreach {x1 y1 x2 y2}  [$wn.c bbox $next_cell_id] {break}
    }
    set rightedge [expr {$x1 + [lindex $PgAcVar(mw,$wn,colwidth) $ncol]}]
    while {$rightedge > ($PgAcVar(mw,$wn,leftoffset) + [winfo width $wn.c])} {
        panLeft $wn
    }

    # move to the next cell
    foreach {x1 y1 x2 y2}  [$wn.c bbox $next_cell_id] {break}
    switch -exact -- $position {
        0 {
            canvasClick $wn [incr x1  ] [incr y1 ]
        }
        end -
        default {
            canvasClick $wn [incr x2  -1] [incr y2 -1]
        }
    }

}; # end proc ::Tables::editMove


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::editText {wn c k} {

    global PgAcVar

    set bbin [$wn.c bbox r$PgAcVar(mw,$wn,row_edited)]

    switch $k {

        BackSpace {
            set dp [expr {[$wn.c index $PgAcVar(mw,$wn,id_edited) insert]-1}]
            if {$dp>=0} {
                $wn.c dchars $PgAcVar(mw,$wn,id_edited) $dp $dp
                set PgAcVar(mw,$wn,dirtyrec) 1
            }
        }

        Home {
            $wn.c icursor $PgAcVar(mw,$wn,id_edited) 0
        }

        End {
            $wn.c icursor $PgAcVar(mw,$wn,id_edited) end
        }

        Left {
            set position [expr {[$wn.c index $PgAcVar(mw,$wn,id_edited) insert]-1}]
            if {$position < 0} {
                editMove $wn -1 end
                return
            }
            $wn.c icursor $PgAcVar(mw,$wn,id_edited) $position
        }

        Delete {}

        Right {
            set position [expr {[$wn.c index $PgAcVar(mw,$wn,id_edited) insert]+1}]
            if {$position > [$wn.c index $PgAcVar(mw,$wn,id_edited) end]} {
                editMove $wn 1 0
                return
            }
            $wn.c icursor $PgAcVar(mw,$wn,id_edited) $position
        }

        Return -

        Tab {
            editMove $wn
            return
        }

        ISO_Left_Tab {
            editMove $wn -1
            return
        }

        Up {
            editMove $wn -$PgAcVar(mw,$wn,colcount)
            return
        }

        Down {
            editMove $wn $PgAcVar(mw,$wn,colcount)
            return
        }

        Escape {
            set PgAcVar(mw,$wn,dirtyrec) 0
            $wn.c itemconfigure $PgAcVar(mw,$wn,id_edited) \
                -text $PgAcVar(mw,$wn,text_initial_value)
            $wn.c focus {}
        }

        default {
            if {[string compare $c " "]>-1} {
                $wn.c insert $PgAcVar(mw,$wn,id_edited) insert $c
                set PgAcVar(mw,$wn,dirtyrec) 1
            }
        }

    }

    set bbout [$wn.c bbox r$PgAcVar(mw,$wn,row_edited)]
    set dy [expr {[lindex $bbout 3]-[lindex $bbin 3]}]
    if {$dy==0} return
    set re $PgAcVar(mw,$wn,row_edited)
    $wn.c move g$re 0 $dy
    for {set i [expr {1+$re}]} {$i<=$PgAcVar(mw,$wn,nrecs)} {incr i} {
        $wn.c move r$i 0 $dy
        $wn.c move g$i 0 $dy
        set rh [lindex $PgAcVar(mw,$wn,rowy) $i]
        incr rh $dy
        set PgAcVar(mw,$wn,rowy) [lreplace $PgAcVar(mw,$wn,rowy) $i $i $rh]
    }

    showRecord $wn $PgAcVar(mw,$wn,row_edited)
# Delete is trapped by window interpreted as record delete
#    Delete {$wn.c dchars $PgAcVar(mw,$wn,id_edited) insert insert; set PgAcVar(mw,$wn,dirtyrec) 1}

}; # end proc ::Tables::editText


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::finishEdit {wn} {

    global PgAcVar CurrentDB

# User has edited the text ?
if {!$PgAcVar(mw,$wn,dirtyrec)} {
    # No, unfocus text
    $wn.c focus {}
    # For restoring * to the new record position
    if {$PgAcVar(mw,$wn,id_edited)!=""} {
        if {[lsearch [$wn.c gettags $PgAcVar(mw,$wn,id_edited)] new]!=-1} {
            $wn.c itemconfigure $PgAcVar(mw,$wn,id_edited) -text $PgAcVar(mw,$wn,text_initial_value)
        }
    }
    set PgAcVar(mw,$wn,id_edited) {};set PgAcVar(mw,$wn,text_initial_value) {}
    return 1
}
# Trimming the spaces
set fldval [string trim [$wn.c itemcget $PgAcVar(mw,$wn,id_edited) -text]]
$wn.c itemconfigure $PgAcVar(mw,$wn,id_edited) -text $fldval
if {[string compare $PgAcVar(mw,$wn,text_initial_value) $fldval]==0} {
    set PgAcVar(mw,$wn,dirtyrec) 0
    $wn.c focus {}
    set PgAcVar(mw,$wn,id_edited) {};set PgAcVar(mw,$wn,text_initial_value) {}
    return 1
}
setCursor CLOCK
#set ctid [lindex $PgAcVar(mw,$wn,keylist) $PgAcVar(mw,$wn,row_edited)]
set ukey [lindex $PgAcVar(mw,$wn,keylist) $PgAcVar(mw,$wn,row_edited)]
set fld [lindex $PgAcVar(mw,$wn,colnames) [get_tag_info $wn $PgAcVar(mw,$wn,id_edited) c]]
set fillcolor black
if {$PgAcVar(mw,$wn,row_edited)==$PgAcVar(mw,$wn,last_rownum)} {
    set fillcolor red
    set sfp [lsearch $PgAcVar(mw,$wn,newrec_fields) "\"$fld\""]
    if {$sfp>-1} {
        set PgAcVar(mw,$wn,newrec_fields) [lreplace $PgAcVar(mw,$wn,newrec_fields) $sfp $sfp]
        set PgAcVar(mw,$wn,newrec_values) [lreplace $PgAcVar(mw,$wn,newrec_values) $sfp $sfp]
    }
    lappend PgAcVar(mw,$wn,newrec_fields) "\"$fld\""
    lappend PgAcVar(mw,$wn,newrec_values) '$fldval'
    # Remove the untouched tag from the object
    $wn.c dtag $PgAcVar(mw,$wn,id_edited) unt
        $wn.c itemconfigure $PgAcVar(mw,$wn,id_edited) -fill red
    set retval 1
} else {
    set PgAcVar(mw,$wn,msg) "Updating record ..."
    after 1000 "set PgAcVar(mw,$wn,msg) {}"
    regsub -all ' $fldval  \\' sqlfldval

#FIXME rjr 4/29/1999 special case null so it can be entered into tables
#really need to write a tcl sqlquote proc which quotes the string only
#if necessary, so it can be used all over pgaccess, instead of explicit 's

    if {[llength $PgAcVar(mw,$wn,ukey)] != [llength $ukey]} {return 0}
    set where [list]
    foreach K $PgAcVar(mw,$wn,ukey) V $ukey {
        if {[string length $V] == 0} {
            lappend where "${K} ISNULL"
        } else {
            lappend where ${K}='${V}'
        }
    }

#puts "UPDATE: [join $where " AND "]"

    if {$sqlfldval == "null"} {
        set retval [sql_exec noquiet "
            UPDATE [::Database::quoteObject $PgAcVar(mw,$wn,tablename)] \
               SET \"$fld\"= null
             WHERE [join $where " AND "]"]
    } else {
        set retval [sql_exec noquiet "
            UPDATE [::Database::quoteObject $PgAcVar(mw,$wn,tablename)] \
               SET \"$fld\"='$sqlfldval'
             WHERE [join $where " AND "]"]
    }
}
setCursor DEFAULT
if {!$retval} {
    set PgAcVar(mw,$wn,msg) ""
    focus $wn.c
    return 0
}
set PgAcVar(mw,$wn,dirtyrec) 0
$wn.c focus {}
set PgAcVar(mw,$wn,id_edited) {};set PgAcVar(mw,$wn,text_initial_value) {}
return 1

}; # end proc ::Tables::finishLayout


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::loadLayout {wn layoutname} {

    global PgAcVar CurrentDB

    setCursor CLOCK

    set PgAcVar(mw,$wn,layout_name) $layoutname
    catch {unset PgAcVar(mw,$wn,colcount) PgAcVar(mw,$wn,colnames) PgAcVar(mw,$wn,colwidth)}
    set PgAcVar(mw,$wn,layout_found) 0
    set sql "
        SELECT *,oid
          FROM pga_layout
         WHERE tablename='$layoutname'
      ORDER BY oid DESC"
    set pgres [wpg_exec $CurrentDB $sql]
    set pgs [pg_result $pgres -status]
    if {$pgs!="PGRES_TUPLES_OK"} {
        # Probably table pga_layout isn't yet defined
        # MOVED to mainlib, pga_init function
        #sql_exec noquiet "create table pga_layout (tablename varchar(64) primary key,nrcols int2,colnames text,colwidth text)"
        #sql_exec quiet "grant ALL on pga_layout to PUBLIC"
    } else {
        set nrlay [pg_result $pgres -numTuples]
        if {$nrlay>=1} {
            set layoutinfo [pg_result $pgres -getTuple 0]
            set PgAcVar(mw,$wn,colcount) [lindex $layoutinfo 1]
            set PgAcVar(mw,$wn,colnames)  [lindex $layoutinfo 2]
            set PgAcVar(mw,$wn,colwidth) [lindex $layoutinfo 3]
            set goodoid [lindex $layoutinfo 4]
            set PgAcVar(mw,$wn,layout_found) 1
        }
        if {$nrlay>1} {
            #showError "Multiple ($nrlay) layout info found\n\nPlease report the bug!"
            #sql_exec quiet "DELETE FROM pga_layout WHERE (tablename='$PgAcVar(mw,$wn,tablename)') AND (oid<>$goodoid)"
            #
            # this is gross but we might have corrupt layout info
            # so we should delete it all for the table in question
            #
            set sql "
                DELETE FROM pga_layout
                      WHERE tablename='$layoutname'
                        AND oid<>$goodoid"
            sql_exec quiet $sql
        }
    }
    pg_result $pgres -clear

}; # end proc ::Tables::loadLayout


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::panLeft {wn } {

    global PgAcVar

    if {![finishEdit $wn]} return;
    if {$PgAcVar(mw,$wn,leftcol)==[expr {$PgAcVar(mw,$wn,colcount)-1}]} return;
    set diff [expr {2+[lindex $PgAcVar(mw,$wn,colwidth) $PgAcVar(mw,$wn,leftcol)]}]
    incr PgAcVar(mw,$wn,leftcol)
    incr PgAcVar(mw,$wn,leftoffset) $diff
    $wn.c move header -$diff 0
    $wn.c move q -$diff 0
    $wn.c move hgrid -$diff 0
    $wn.c move arrow -$diff 0

}; # end proc ::Tables::panLeft


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::panRight {wn} {

    global PgAcVar

    if {![finishEdit $wn]} return;
    if {$PgAcVar(mw,$wn,leftcol)==0} return;
    incr PgAcVar(mw,$wn,leftcol) -1
    set diff [expr {2+[lindex $PgAcVar(mw,$wn,colwidth) $PgAcVar(mw,$wn,leftcol)]}]
    incr PgAcVar(mw,$wn,leftoffset) -$diff
    $wn.c move header $diff 0
    $wn.c move q $diff 0
    $wn.c move hgrid $diff 0
    $wn.c move arrow $diff 0

}; # end proc ::Tables::panRight


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::insertNewRecord {wn} {

    global PgAcVar CurrentDB

    if {![finishEdit $wn]} {return 0}
    if {$PgAcVar(mw,$wn,newrec_fields)==""} {return 1}
    set PgAcVar(mw,$wn,msg) "Saving new record ..."
    after 1000 "set PgAcVar(mw,$wn,msg) {}"

    ##
    ##    We need to find the unique key values
    ##    so that we can update the table view
    ##
    foreach uk $PgAcVar(mw,$wn,ukey) {
        set idx [lsearch $PgAcVar(mw,$wn,newrec_fields) $uk]
    }

    set pgres [wpg_exec $CurrentDB "
        INSERT INTO [::Database::quoteObject $PgAcVar(mw,$wn,tablename)] 
                    ([join $PgAcVar(mw,$wn,newrec_fields) ,])
             VALUES ([join $PgAcVar(mw,$wn,newrec_values) ,])" ]

    if {[pg_result $pgres -status]!="PGRES_COMMAND_OK"} {
        set errmsg [pg_result $pgres -error]
        showError "[intlmsg {Error inserting new record}]\n\n$errmsg"
        return 0
    }

    if {[string equal -nocase "oid" $PgAcVar(mw,$wn,ukey)]} {
        lappend PgAcVar(mw,$wn,keylist) [pg_result $pgres -oid]
    } else {
        ##
        ##    We need to find the unique key values
        ##    so that we can update the table view
        ##
        set tmp [list]
        foreach uk $PgAcVar(mw,$wn,ukey) {
            set idx [lsearch $PgAcVar(mw,$wn,newrec_fields) $uk]
            lappend tmp [lindex $PgAcVar(mw,$wn,newrec_values) $idx]
        }
        lappend PgAcVar(mw,$wn,keylist) $tmp
    }
    pg_result $pgres -clear
    # Get bounds of the last record
    set lrbb [$wn.c bbox new]
    lappend PgAcVar(mw,$wn,rowy) [lindex $lrbb 3]
    $wn.c itemconfigure new -fill black
    $wn.c dtag q new
    # Replace * from untouched new row elements with "  "
    foreach item [$wn.c find withtag unt] {
        $wn.c itemconfigure $item -text "  "
    }
    $wn.c dtag q unt
    incr PgAcVar(mw,$wn,last_rownum)
    incr PgAcVar(mw,$wn,nrecs)
    drawNewRecord $wn
    set PgAcVar(mw,$wn,newrec_fields) {}
    set PgAcVar(mw,$wn,newrec_values) {}

    return 1

}; # end proc ::Tables::insertNewRecord


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::scrollWindow {wn par1 args} {

    global PgAcVar

    if {![finishEdit $wn]} return;
    if {$par1=="scroll"} {
        set newtop $PgAcVar(mw,$wn,toprec)
        if {[lindex $args 1]=="units"} {
            incr newtop [lindex $args 0]
        } else {
            incr newtop [expr {[lindex $args 0]*25}]
            if {$newtop<0} {set newtop 0}
            if {$newtop>=[expr {$PgAcVar(mw,$wn,nrecs)-1}]} {set newtop [expr {$PgAcVar(mw,$wn,nrecs)-1}]}
        }
    } elseif {$par1=="moveto"} {
        set newtop [expr {int([lindex $args 0]*$PgAcVar(mw,$wn,nrecs))}]
    } else {
        return
    }
    if {$newtop<0} return;
    if {$newtop>=[expr {$PgAcVar(mw,$wn,nrecs)-1}]} return;
    set dy [expr {[lindex $PgAcVar(mw,$wn,rowy) $PgAcVar(mw,$wn,toprec)]-[lindex $PgAcVar(mw,$wn,rowy) $newtop]}]
    $wn.c move q 0 $dy
    $wn.c move hgrid 0 $dy
    set newrowy {}
    foreach y $PgAcVar(mw,$wn,rowy) {lappend newrowy [expr {$y+$dy}]}
    set PgAcVar(mw,$wn,rowy) $newrowy
    set PgAcVar(mw,$wn,toprec) $newtop
    setScrollbar $wn

}; # end proc ::Tables::scrollWindow


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::initVariables {wn} {

    global PgAcVar

    set PgAcVar(mw,$wn,newrec_fields) {}
    set PgAcVar(mw,$wn,newrec_values) {}

}; # end proc ::Tables::initVariables


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::selectRecords {wn sql} {

    global PgAcVar CurrentDB

    variable Win

if {![finishEdit $wn]} return;
initVariables $wn
$wn.c delete q
$wn.c delete header
$wn.c delete hgrid
$wn.c delete new
set PgAcVar(mw,$wn,leftcol) 0
set PgAcVar(mw,$wn,leftoffset) 0
set PgAcVar(mw,$wn,crtrow) {}
set PgAcVar(mw,$wn,msg) [intlmsg "Accessing data. Please wait ..."]
catch {$wn.f1.b1 configure -state disabled}
setCursor CLOCK
set is_error 1
if {[sql_exec noquiet "BEGIN"]} {
    if {[sql_exec noquiet "declare mycursor cursor for $sql"]} {
        set pgres [wpg_exec $CurrentDB "fetch $PgAcVar(pref,rows) in mycursor"]
        if {$PgAcVar(pgsql,status)=="PGRES_TUPLES_OK"} {
            set is_error 0
        }
    }
}
if {$is_error} {
    sql_exec quiet "END"
    set PgAcVar(mw,$wn,msg) {}
    catch {$wn.f1.b1 configure -state normal}
    setCursor DEFAULT
    set PgAcVar(mw,$wn,msg) "Error executing : $sql"
    return
}
set shift 0
if {$PgAcVar(mw,$wn,updatable)} {
    set shift [llength $PgAcVar(mw,$wn,ukey)]
}

#
# checking at least the numer of fields
set attrlist [pg_result $pgres -lAttributes]
if {$PgAcVar(mw,$wn,layout_found)} then {
    if {  ($PgAcVar(mw,$wn,colcount) != [expr {[llength $attrlist]-$shift}]) ||
          ($PgAcVar(mw,$wn,colcount) != [llength $PgAcVar(mw,$wn,colnames)]) ||
          ($PgAcVar(mw,$wn,colcount) != [llength $PgAcVar(mw,$wn,colwidth)]) } then {
        # No. of columns don't match, something is wrong
        # tk_messageBox -title [intlmsg Information] -message "Layout info changed !\nRescanning..."
        set PgAcVar(mw,$wn,layout_found) 0
        sql_exec quiet "DELETE FROM pga_layout WHERE tablename='$PgAcVar(mw,$wn,layout_name)'"
    }
}
# Always take the col. names from the result
set PgAcVar(mw,$wn,colcount) [llength $attrlist]
if {$PgAcVar(mw,$wn,updatable)} {
    incr PgAcVar(mw,$wn,colcount) -[llength $PgAcVar(mw,$wn,ukey)]
}
set PgAcVar(mw,$wn,colnames) {}
# In defPgAcVar(mw,$wn,colwidth) prepare PgAcVar(mw,$wn,colwidth) (in case that not layout_found)
set defPgAcVar(mw,$wn,colwidth) {}

foreach A [lrange $attrlist $shift end] {
    lappend PgAcVar(mw,$wn,colnames) [lindex $A 0]
    lappend defPgAcVar(mw,$wn,colwidth) 150
}

    ##
    ##  We just populate the comobox widget
    ##  and make sure the combobox exists
    ##
    if {[info exists $Win(sortfield)]} {
        $Win(sortfield) configure \
            -values $PgAcVar(mw,$wn,colnames)
    }

if {!$PgAcVar(mw,$wn,layout_found)} {
    set PgAcVar(mw,$wn,colwidth) $defPgAcVar(mw,$wn,colwidth)
    sql_exec quiet "INSERT INTO pga_layout VALUES ('$PgAcVar(mw,$wn,layout_name)',$PgAcVar(mw,$wn,colcount),'$PgAcVar(mw,$wn,colnames)','$PgAcVar(mw,$wn,colwidth)')"
    set PgAcVar(mw,$wn,layout_found) 1
}
set PgAcVar(mw,$wn,nrecs) [pg_result $pgres -numTuples]
if {$PgAcVar(mw,$wn,nrecs)>$PgAcVar(pref,rows)} {
    set PgAcVar(mw,$wn,msg) "Only first $PgAcVar(pref,rows) records from $PgAcVar(mw,$wn,nrecs) have been loaded"
    set PgAcVar(mw,$wn,nrecs) $PgAcVar(pref,rows)
}
set tagoid {}
if {$PgAcVar(pref,tvfont)=="helv"} {
    set tvfont $PgAcVar(pref,font_normal)
} else {
    set tvfont $PgAcVar(pref,font_fix)
}
# Computing column's left edge
set posx 10
for {set j 0} {$j<$PgAcVar(mw,$wn,colcount)} {incr j} {
    set ledge($j) $posx
    incr posx [expr {[lindex $PgAcVar(mw,$wn,colwidth) $j]+2}]
    set textwidth($j) [expr {[lindex $PgAcVar(mw,$wn,colwidth) $j]-5}]
}
incr posx -6
set posy 24
drawHeaders $wn
set PgAcVar(mw,$wn,updatekey) oid
set PgAcVar(mw,$wn,keylist) {}
set PgAcVar(mw,$wn,rowy) {24}
set PgAcVar(mw,$wn,msg) "Loading maximum $PgAcVar(pref,rows) records ..."
set wupdatable $PgAcVar(mw,$wn,updatable)
for {set i 0} {$i<$PgAcVar(mw,$wn,nrecs)} {incr i} {
    set curtup [pg_result $pgres -getTuple $i]
    if {$wupdatable} {
        set tmp [lrange $curtup 0 [expr [llength $PgAcVar(mw,$wn,ukey)]-1]]
        lappend PgAcVar(mw,$wn,keylist) $tmp
    }
    for {set j 0} {$j<$PgAcVar(mw,$wn,colcount)} {incr j} {
        $wn.c create text $ledge($j) $posy -text [lindex $curtup [expr {$j+$shift}]] -tags [list r$i c$j q] -anchor nw -font $tvfont -width $textwidth($j) -fill black
    }
    set bb [$wn.c bbox r$i]
    incr posy [expr {[lindex $bb 3]-[lindex $bb 1]}]
    lappend PgAcVar(mw,$wn,rowy) $posy
    $wn.c create line 0 [lindex $bb 3] $posx [lindex $bb 3] -fill gray -tags [subst {hgrid g$i}]
    if {$i==25} {update; update idletasks}
}
after 3000 "set PgAcVar(mw,$wn,msg) {}"
set PgAcVar(mw,$wn,last_rownum) $i
# Defining position for input data
drawNewRecord $wn
pg_result $pgres -clear
sql_exec quiet "END"
set PgAcVar(mw,$wn,toprec) 0
setScrollbar $wn
if {$PgAcVar(mw,$wn,updatable)} then {
    $wn.c bind q <Key> "Tables::editText $wn %A %K"
} else {
    $wn.c bind q <Key> {}
}
set PgAcVar(mw,$wn,dirtyrec) 0
$wn.c raise header
$wn.c raise arrow

catch {$wn.f1.b1 configure -state normal}
setCursor DEFAULT

}; # end proc ::Tables::selectRecords


#----------------------------------------------------------
# record size in scrollbar units
#----------------------------------------------------------
#
proc ::Tables::recordSizeInScrollbarUnits {wn} {

    global PgAcVar

    return [expr {1.0/$PgAcVar(mw,$wn,nrecs)}]

}; # end proc ::Tables::recordSizeInScrollbarUnits


#----------------------------------------------------------
# number of records that fit in the window at its current size
#----------------------------------------------------------
#
proc ::Tables::getVisibleRecordsCount {wn} {
    expr {[winfo height $wn.c]/14}
}; # end proc ::Tables::getVisibleRecordsCount


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::setScrollbar {wn} {

    global PgAcVar

    if {$PgAcVar(mw,$wn,nrecs)==0} return;
    # Fixes problem of window resizing messing up the scrollbar size.
    set record_size [recordSizeInScrollbarUnits $wn]

    $wn.sb set [expr {$PgAcVar(mw,$wn,toprec)*$record_size}] \
        [expr {($PgAcVar(mw,$wn,toprec)+[getVisibleRecordsCount $wn])*$record_size}]

}; # end proc ::Tables::setScrollbar


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::keepFilterHistory {wn} {

    global PgAcVar
    variable Win

    set histvals [$Win(filterfield) cget -values]
    if {[lsearch $histvals $PgAcVar(mw,$wn,filter)]==-1} {
        lappend histvals $PgAcVar(mw,$wn,filter)
        $Win(filterfield) configure -values $histvals
    }

}; # end proc ::Tables::keepFilterHistory


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::refreshRecords {wn} {

    global PgAcVar
    variable Win

    if {[info exists PgAcVar(mw,$wn,$PgAcVar(mw,$wn,sortfield),sortdirection)]} {
        set sdir $PgAcVar(mw,$wn,$PgAcVar(mw,$wn,sortfield),sortdirection)
    } else {
        set sdir "DESC"
    }

    # make sure SQL key words are capitalized
    # would be nice to move to Syntax namespace
    set nq [string trim [string map -nocase {"SELECT " "SELECT " " FROM " " FROM " " WHERE " " WHERE " " GROUP " " GROUP " " BY " " BY " " HAVING " " HAVING " " UNION " " UNION " " INTERSECT " " INTERSECT " " EXCEPT " " EXCEPT " " ORDER " " ORDER " " BY " " BY " " ASC " " ASC " " DESC " " DESC " " LIMIT " " LIMIT " " OFFSET " " OFFSET "} $PgAcVar(mw,$wn,query)]]

    #
    # filtering and sorting for queries
    #
    if {$PgAcVar(mw,$wn,isaquery)} {
        # if it's a filter, we have to handle a WHERE
        # and every token possible after it
        if {$PgAcVar(mw,$wn,filter)!=""} {
            set pos1 [string first " WHERE " $nq]
            if {$pos1==-1} {
                set pos1 0
            } else {
                set pos1 [expr {$pos1 + [string length "WHERE "]}]
            }
            set pos2 -1
            foreach sq [list " WHERE " " GROUP " " HAVING " " UNION " " INTERSECT " " EXCEPT " " ORDER " " LIMIT " " OFFSET "] {
                if {$pos2==-1} {
                    set pos2 [string first $sq $nq $pos1]
                }
            }
            if {$pos2==-1} {
                set pos2 [string length $nq]
            }
            if {$pos1==0} {
                set pos1 $pos2
            }
            set newq [string range $nq 0 $pos1]
            if {$pos1==$pos2} {
                append newq " WHERE "
            } else {
                append newq " ( " [string range $nq $pos1 $pos2] " ) AND "
            }
            append newq " $PgAcVar(mw,$wn,filter) "
            append newq [string range $nq $pos2 end]
            set nq $newq
        } else {
            set nq $PgAcVar(mw,$wn,query)
        }; # end if - WHERE-filter

        if {$PgAcVar(mw,$wn,sortfield)!=""} {
            set pos1 [string first " ORDER " $nq]
            if {$pos1==-1} {
                set pos1 [string first " BY " $nq]
                if {$pos1==-1} {
                    set pos1 0
                }
            } else {
                set pos1 [expr {$pos1 + [string length "ORDER BY "]}]
            }
            set pos2 -1
            foreach sq [list " ORDER " " BY " " LIMIT " " OFFSET "] {
                if {$pos2==-1} {
                    set pos2 [string first $sq $nq $pos1]
                }
            }
            if {$pos2==-1} {
                set pos2 [string length $nq]
            }
            if {$pos1==0} {
                set pos1 $pos2
            }
            set newq [string range $nq 0 $pos1]
            if {$pos1==$pos2} {
                append newq " ORDER BY "
            } else {
                append newq [string range $nq $pos1 $pos2] " , "
            }
            append newq " \"$PgAcVar(mw,$wn,sortfield)\" "
            append newq " $sdir "
            append newq [string range $nq $pos2 end]
            set nq $newq
        } else {
            foreach i {triangle darkline lightline} {
                ${wn}.c coords $i 0 0 0 0 0 0
                    ${wn}.c itemconfigure $i -fill #CCCCCC
            }
        }

    # filtering and sorting for tables and views is much prettier
    } else {
        if {$PgAcVar(mw,$wn,filter)!=""} {
            set nq "$PgAcVar(mw,$wn,query) WHERE ($PgAcVar(mw,$wn,filter))"
        } else {
            set nq $PgAcVar(mw,$wn,query)
        }
        if {$PgAcVar(mw,$wn,sortfield)!=""} {
            set nq "$nq ORDER BY \"$PgAcVar(mw,$wn,sortfield)\" "
            append nq "$sdir"
        } else {
            foreach i {triangle darkline lightline} {
                ${wn}.c coords $i 0 0 0 0 0 0
                    ${wn}.c itemconfigure $i -fill #CCCCCC
            }
        }
    }

    if {[insertNewRecord $wn]} {selectRecords $wn $nq}

    if {$PgAcVar(mw,$wn,sortfield)!=""} {
        moveArrow $wn $PgAcVar(mw,$wn,sortfield)
    }

    set PgAcVar(mw,$wn,activequery) $nq

    return

}; # end proc refreshRecords


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::showRecord {wn row} {

    global PgAcVar

    set PgAcVar(mw,$wn,errorsavingnew) 0
    if {$PgAcVar(mw,$wn,newrec_fields)!=""} {
        if {$row!=$PgAcVar(mw,$wn,last_rownum)} {
            if {![insertNewRecord $wn]} {
        set PgAcVar(mw,$wn,errorsavingnew) 1
        return
            }
        }
    }
    set y1 [lindex $PgAcVar(mw,$wn,rowy) $row]
    set y2 [lindex $PgAcVar(mw,$wn,rowy) [expr {$row+1}]]
    if {$y2==""} {set y2 [expr {$y1+14}]}
    $wn.c dtag hili hili
    $wn.c addtag hili withtag r$row
    # Making a rectangle arround the record
    set x 3
    foreach wi $PgAcVar(mw,$wn,colwidth) {incr x [expr {$wi+2}]}
    $wn.c delete crtrec
    $wn.c create rectangle [expr {-1-$PgAcVar(mw,$wn,leftoffset)}] $y1 [expr {$x-$PgAcVar(mw,$wn,leftoffset)}] $y2 -fill #EEEEEE -outline {} -tags {q crtrec}
    $wn.c lower crtrec

}; # end proc ::Tables::showRecord


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::startEdit {wn id x y} {

    global PgAcVar

    if {!$PgAcVar(mw,$wn,updatable)} return
    set PgAcVar(mw,$wn,id_edited) $id
    set PgAcVar(mw,$wn,dirtyrec) 0
    set PgAcVar(mw,$wn,text_initial_value) [$wn.c itemcget $id -text]

    focus $wn.c
    $wn.c focus $id
    $wn.c icursor $id @$x,$y

    if {$PgAcVar(mw,$wn,row_edited)==$PgAcVar(mw,$wn,nrecs)} {
        if {[$wn.c itemcget $id -text]=="*"} {
            $wn.c itemconfigure $id -text ""
            $wn.c icursor $id 0
        }
    }

}; # end proc ::Tables::startEdit


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::canvasPaste {wn x y} {

    global PgAcVar

    $wn.c insert $PgAcVar(mw,$wn,id_edited) insert [selection get]
    set PgAcVar(mw,$wn,dirtyrec) 1

}; # end proc ::Tables::canvasPaste


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::getNewWindowName {} {

    global PgAcVar

    incr PgAcVar(mwcount)
    return .pgaw:$PgAcVar(mwcount)

}; # end proc ::Tables::getNewWindowName


#------------------------------------------------------------
# closeWin --
#
#    Closes the table view window
#
# Arguments:
#    wn    the window path
#
# Results:
#    none
#------------------------------------------------------------
#
proc ::Tables::closeWin {wn} {

    if {[Tables::insertNewRecord $wn]} {
        $wn.c delete rows
        $wn.c delete header
        Window destroy $wn
        PgAcVar:clean mw,$wn,*
    }

    return

}; # end proc ::Tables::closeWin


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::createWindow {{base ""}} {

    global PgAcVar

    variable Win

    if {$base == ""} {
        set base .pgaw:$PgAcVar(mwcount)
        set included 0
    } else {
        set included 1
    }
    set wn $base
    set PgAcVar(mw,$wn,dirtyrec) 0
    set PgAcVar(mw,$wn,id_edited) {}
    set PgAcVar(mw,$wn,filter) {}
    set PgAcVar(mw,$wn,sortfield) {}
    set PgAcVar(mw,$wn,sortdirection) "DESC"
    if {! $included} {
        if {[winfo exists $base]} {
            wm deiconify $base; return
        }
        toplevel $base -class Toplevel
        wm focusmodel $base passive
        wm geometry $base 650x400
        wm maxsize $base 1280 1024
        wm minsize $base 650 400
        wm overrideredirect $base 0
        wm resizable $base 1 1
        wm deiconify $base
        wm title $base [intlmsg "Table"]
    }
    bind $base <Key-Delete> "Tables::deleteRecord $wn"
    bind $base <Key-F1> "Help::load tables"
    if {! $included} {
        frame $base.f1  -borderwidth 2 -height 75 -relief groove -width 125 
        label $base.f1.l1  -borderwidth 0 -text [intlmsg {Sort field}]
        #entry $base.f1.e1  -background #fefefe -borderwidth 1 -width 14  -highlightthickness 1 -textvariable PgAcVar(mw,$wn,sortfield)

        set Win(sortfield) [ComboBox $base.f1.e1 \
            -editable 0 \
            -entrybg #fefefe \
            -background #fefefe \
            -borderwidth 1 \
            -width 14  \
            -highlightthickness 1 \
            -modifycmd [list Tables::refreshRecords $wn] \
            -textvariable PgAcVar(mw,$wn,sortfield)]

        $base.f1.e1 bind <Key-Return> "Tables::refreshRecords $wn"
        $base.f1.e1 bind <Key-KP_Enter> "Tables::refreshRecords $wn"
        #bind $base.f1.e1 <Key-Return> "Tables::refreshRecords $wn"    
        #bind $base.f1.e1 <Key-KP_Enter> "Tables::refreshRecords $wn"    
        label $base.f1.lb1  -borderwidth 0 -text {     } 
        label $base.f1.l2  -borderwidth 0 -text [intlmsg {Filter conditions}]
        set Win(filterfield) [ComboBox $base.f1.e2 \
            -editable 1 \
            -entrybg #fefefe \
            -background #fefefe \
            -borderwidth 1 \
            -highlightthickness 1 \
            -postcommand [list ::Tables::keepFilterHistory $wn] \
            -modifycmd [list ::Tables::refreshRecords $wn] \
            -command [list ::Tables::refreshRecords $wn] \
            -textvariable PgAcVar(mw,$wn,filter)]
        #bind $base.f1.e2 <Key-Return> "Tables::refreshRecords $wn"    
        #bind $base.f1.e2 <Key-KP_Enter> "Tables::refreshRecords $wn"    
        #button $base.f1.b1  -borderwidth 1 -text [intlmsg Close] -command 

        Button $base.f1.b3  \
                    -borderwidth 1 \
                    -image ::icon::up-22 \
                    -helptext "Export Results" \
                    -relief link \
                    -command [list ::Tables::export $wn]

        Button $base.f1.b1  \
                    -borderwidth 1 \
                    -image ::icon::exit-22 \
                    -helptext "Close Window" \
                    -relief link \
                    -command [list ::Tables::closeWin $wn]

        #button $base.f1.b2  -borderwidth 1 -text [intlmsg Reload] -command "Tables::refreshRecords $wn"
        Button $base.f1.b2  \
                    -borderwidth 1 \
                    -image ::icon::reload-22 \
                    -helptext "Reload" \
                    -relief link \
                    -command "Tables::refreshRecords $wn"
    }
    frame $base.frame20  -borderwidth 2 -height 75 -relief groove -width 125 
    #button $base.frame20.01  -borderwidth 1 -text < -command "Tables::panRight $wn"

    Button $base.frame20.01  \
            -borderwidth 1 \
            -image ::icon::back-22 \
            -relief link \
            -helptext "Scroll Left" \
            -command "Tables::panRight $wn"

    label $base.frame20.02  -anchor w -borderwidth 1 -height 1  -relief sunken -text {} -textvariable PgAcVar(mw,$wn,msg) 
    #button $base.frame20.03  -borderwidth 1 -text > -command "Tables::panLeft $wn"
    Button $base.frame20.03 \
            -borderwidth 1 \
            -image ::icon::forward-22 \
            -relief link \
            -helptext "Scroll Right" \
            -command "Tables::panLeft $wn"

    canvas $base.c  -background #fefefe -borderwidth 2 -height 207 -highlightthickness 0  -relief ridge -selectborderwidth 0 -takefocus 1 -width 295 
    scrollbar $base.sb  -borderwidth 1 -orient vert -width 12  -command "Tables::scrollWindow $wn"
    bind $base.c <Button-1> "Tables::canvasClick $wn %x %y"
    bind $base.c <Button-2> "Tables::canvasPaste $wn %x %y"
    bind $base.c <Button-3> "if {[Tables::finishEdit $wn]} \"Tables::insertNewRecord $wn\""

    # Prevent Tab from moving focus out of canvas widget
    bind $base.c <Tab> break

    if {! $included} {
        pack $base.f1  -in $wn -anchor center -expand 0 -fill x -side top 
        pack $base.f1.l1  -in $wn.f1 -anchor center -expand 0 -fill none -side left 
        pack $base.f1.e1  -in $wn.f1 -anchor center -expand 0 -fill none -side left 
        pack $base.f1.lb1  -in $wn.f1 -anchor center -expand 0 -fill none -side left 
        pack $base.f1.l2  -in $wn.f1 -anchor center -expand 0 -fill none -side left 
        pack $base.f1.e2  -in $wn.f1 -anchor center -expand 1 -fill x -side left 
        pack $base.f1.b3  -in $wn.f1 -anchor center -expand 0 -fill none -side right 
        pack $base.f1.b1  -in $wn.f1 -anchor center -expand 0 -fill none -side right 
        pack $base.f1.b2  -in $wn.f1 -anchor center -expand 0 -fill none -side right 
    }
    pack $base.frame20  -in $wn -anchor s -expand 0 -fill x -side bottom 
    pack $base.frame20.01  -in $wn.frame20 -anchor center -expand 0 -fill none -side left 
    pack $base.frame20.02  -in $wn.frame20 -anchor center -expand 1 -fill x -side left 
    pack $base.frame20.03  -in $wn.frame20 -anchor center -expand 0 -fill none -side right 
    pack $base.c -in $wn -anchor w -expand 1 -fill both -side left 
    pack $base.sb -in $wn -anchor e -expand 0 -fill y -side right

}; # end proc ::Tables::createWindow


#----------------------------------------------------------
# doesnt look we are using this proc
# since we have another one of the same name
# is this one old or is it new ?
#----------------------------------------------------------
#
proc ::Tables::renameColumn_DUPLICATE {} {

    global PgAcVar CurrentDB

    if {[string length [string trim $PgAcVar(tblinfo,new_cn)]]==0} {
        showError [intlmsg "Field name not entered!"]
        return
    }
    set old_name [string trim [string range $PgAcVar(tblinfo,old_cn) 0 31]]
    set PgAcVar(tblinfo,new_cn) [string trim $PgAcVar(tblinfo,new_cn)]
    if {$old_name == $PgAcVar(tblinfo,new_cn)} {
        showError [intlmsg "New name is the same as the old one!"]
        return
    }
    foreach line [.pgaw:TableInfo.f1.lb get 0 end] {
        if {[string trim [string range $line 0 31]]==$PgAcVar(tblinfo,new_cn)} {
            showError [format [intlmsg {Column name '%s' already exists in this table!}] $PgAcVar(tblinfo,new_cn)]
            return
        }
    }
    if {[sql_exec noquiet "alter table [::Database::quoteObject $PgAcVar(tblinfo,tablename)] rename column \"$old_name\" to \"$PgAcVar(tblinfo,new_cn)\""]} {
        refreshInfo Columns
        Window destroy .pgaw:RenameField
    }

}; # end proc ::Tables::renameColumn


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::createNewIndex {} {

    global PgAcVar

    if {$PgAcVar(addindex,indexname)==""} {
        showError [intlmsg "Index name cannot be null!"]
        return
    }

    setCursor CLOCK

    if {[sql_exec noquiet "CREATE $PgAcVar(addindex,unique) INDEX \"$PgAcVar(addindex,indexname)\" on [::Database::quoteObject $PgAcVar(tblinfo,tablename)] ($PgAcVar(addindex,indexfields))"]} {
        setCursor DEFAULT
        Window destroy .pgaw:AddIndex
        refreshInfo Columns
    }

    setCursor DEFAULT

}; # end proc ::Tables::createNewIndex


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::showIndexInformation {} {

    global PgAcVar CurrentDB

    set cs [.pgaw:TableInfo.f2.fl.ilb curselection]
    if {$cs==""} return

    set idxname [.pgaw:TableInfo.f2.fl.ilb get $cs]

    wpg_select $CurrentDB "
        SELECT pg_index.*,pg_class.oid
          FROM [::Database::qualifySysTable pg_index],[::Database::qualifySysTable pg_class]
         WHERE pg_class.relname='$idxname'
           AND pg_class.oid=pg_index.indexrelid" rec {

        if {$rec(indisunique)=="t"} {
            set PgAcVar(tblinfo,isunique) [intlmsg Yes]
        } else {
            set PgAcVar(tblinfo,isunique) [intlmsg No]
        }

        if {$rec(indisclustered)=="t"} {
            set PgAcVar(tblinfo,isclustered) [intlmsg Yes]
        } else {
            set PgAcVar(tblinfo,isclustered) [intlmsg No]
        }

        set PgAcVar(tblinfo,indexfields) {}
        .pgaw:TableInfo.f2.fr.lb delete 0 end

        foreach field $rec(indkey) {
            if {$field!=0} {
##               wpg_select $CurrentDB "select attname from pg_attribute where attrelid=$PgAcVar(tblinfo,tableoid) and attnum=$field" rec1 {
##                   set PgAcVar(tblinfo,indexfields) "$PgAcVar(tblinfo,indexfields) $rec1(attname)"
##               }
                set PgAcVar(tblinfo,indexfields) "$PgAcVar(tblinfo,indexfields) $PgAcVar(tblinfo,f$field)"
                .pgaw:TableInfo.f2.fr.lb insert end $PgAcVar(tblinfo,f$field)
            }

        }
    }

    set PgAcVar(tblinfo,indexfields) [string trim $PgAcVar(tblinfo,indexfields)]

}; # end proc ::Tables::showIndexInformation


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::addNewColumn {} {

    global PgAcVar

    if {$PgAcVar(addfield,name)==""} {
        showError [intlmsg "Empty field name ?"]
        focus .pgaw:AddField.e1
        return
    }

    if {$PgAcVar(addfield,type)==""} {
        showError [intlmsg "No field type ?"]
        focus .pgaw:AddField.e2
        return
    }

    if {![sql_exec quiet "
        ALTER TABLE [::Database::quoteObject $PgAcVar(tblinfo,tablename)]
         ADD COLUMN \"$PgAcVar(addfield,name)\" $PgAcVar(addfield,type)"]} {
        showError "[intlmsg {Cannot add column}]\n\n$PgAcVar(pgsql,errmsg)"
        return
    }

    Window destroy .pgaw:AddField
    sql_exec quiet "
        UPDATE pga_layout
           SET colnames=colnames || ' {$PgAcVar(addfield,name)}', colwidth=colwidth || ' 150',nrcols=nrcols+1
         WHERE tablename='$PgAcVar(tblinfo,tablename)'"

    refreshInfo Columns

}; # end proc ::Tables::addNewColumn


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::newtable:add_new_field {} {

    global PgAcVar

    if {$PgAcVar(nt,fieldname)==""} {
        showError [intlmsg "Enter a field name"]
        focus .pgaw:NewTable.e2
        return
    }

    if {$PgAcVar(nt,fldtype)==""} {
        showError [intlmsg "The field type is not specified!"]
        return
    }

    if {($PgAcVar(nt,fldtype)=="varchar")&&($PgAcVar(nt,fldsize)=="")} {
        focus .pgaw:NewTable.e3
        showError [intlmsg "You must specify field size!"]
        return
    }

    if {$PgAcVar(nt,fldsize)==""} {
        set sup ""
    } else {
        set sup "($PgAcVar(nt,fldsize))"
    }

    if {[regexp $PgAcVar(nt,fldtype) "varchartextdatetime"]} {
        set supc "'"
    } else {
        set supc ""
    }

    # Don't put the ' arround default value if it contains the now() function
    if {([regexp $PgAcVar(nt,fldtype) "datetime"]) \
        && ([regexp now $PgAcVar(nt,defaultval)])} {
        set supc ""
    }

    # Clear the notnull attribute if field type is serial
    if {$PgAcVar(nt,fldtype)=="serial"} {
        set PgAcVar(nt,notnull) " "
    }

    if {$PgAcVar(nt,defaultval)==""} {
        set sup2 ""
    } else {
        set sup2 " DEFAULT $supc$PgAcVar(nt,defaultval)$supc"
    }

    # Checking for field name collision
    set inspos end
    for {set i 0} {$i<[.pgaw:NewTable.lb size]} {incr i} {
        set linie [.pgaw:NewTable.lb get $i]
        if {$PgAcVar(nt,fieldname)==[string trim [string range $linie 2 33]]} {
            if {[tk_messageBox -title [intlmsg Warning] -parent .pgaw:NewTable -message [format [intlmsg "There is another field with the same name: '%s'!\n\nReplace it ?"] $PgAcVar(nt,fieldname)] -type yesno -default yes]=="no"} return
            .pgaw:NewTable.lb delete $i
            set inspos $i
            break
        }
    }

    .pgaw:NewTable.lb insert $inspos [format "%1s %-64.64s %-14s%-16s" $PgAcVar(nt,primarykey) $PgAcVar(nt,fieldname) $PgAcVar(nt,fldtype)$sup $sup2$PgAcVar(nt,notnull)]

    focus .pgaw:NewTable.e2

    set PgAcVar(nt,fieldname) {}
    set PgAcVar(nt,fldsize) {}
    set PgAcVar(nt,defaultval) {}
    set PgAcVar(nt,primarykey) " "

}; # end proc ::Tables::newtable:add_new_field {} {


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::newtable:create {} {

    global PgAcVar CurrentDB

    if {$PgAcVar(nt,tablename)==""} {
        showError [intlmsg "You must supply a name for your table!"]
        focus .pgaw:NewTable.etabn
        return
    }

    if {([.pgaw:NewTable.lb size]==0) && ($PgAcVar(nt,inherits)=="")} {
        showError [intlmsg "Your table has no columns!"]
        focus .pgaw:NewTable.e2
        return
    }

    set fl {}
    set pkf {}

    foreach line [.pgaw:NewTable.lb get 0 end] {
        set fldname "\"[string trim [string range $line 2 33]]\""
        lappend fl "$fldname [string trim [string range $line 35 end]]"
        if {[string range $line 0 0]=="*"} {
            lappend pkf "$fldname"
        }
    }

    set temp "CREATE TABLE [::Database::quoteObject $PgAcVar(nt,tablename)] ([join $fl ,]"

    if {$PgAcVar(nt,constraint)!=""} {
        set temp "$temp, constraint \"$PgAcVar(nt,constraint)\""
    }

    if {$PgAcVar(nt,check)!=""} {
        set temp "$temp check ($PgAcVar(nt,check))"
    }

    if {[llength $pkf]>0} {
        set temp "$temp, primary key([join $pkf ,])"
    }

    set temp "$temp)"

    if {$PgAcVar(nt,inherits)!=""} {
        set temp "$temp inherits ($PgAcVar(nt,inherits))"
    }

    setCursor CLOCK

    if {[sql_exec noquiet $temp]} {
        Window destroy .pgaw:NewTable
        Mainlib::cmd_Tables
    }

    setCursor DEFAULT

}; # end proc ::Tables::newtable:create {} {


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::tabSelect {i} {

    global PgAcVar

    set base .pgaw:TableInfo

    foreach tab {0 1 2 3} {
        if {$i == $tab} {
            place $base.l$tab -y 13
            place $base.f$tab -x 15 -y 45
            $base.l$tab configure -font $PgAcVar(pref,font_bold)
        } else {
            place $base.l$tab -y 15
            place $base.f$tab -x 15 -y 500
            $base.l$tab configure -font $PgAcVar(pref,font_normal)
        }
    }

    array set coord [place info $base.l$i]
    place $base.lline -x [expr {1+$coord(-x)}]

}; # end proc ::Tables::tabSelect



####################   END OF NAMESPACE TABLES ####################
####################   BEGIN VisualTcl CODE ####################



#----------------------------------------------------------
#----------------------------------------------------------
#
proc vTclWindow.pgaw:NewTable {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:NewTable
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 634x392+78+181
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm deiconify $base
    wm title $base [intlmsg "Create new table"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    bind $base <Key-F1> "Help::load new_table"
    entry $base.etabn \
        -background #fefefe -borderwidth 1 -selectborderwidth 0 \
        -textvariable PgAcVar(nt,tablename) 
    bind $base.etabn <Key-Return> {
        focus .pgaw:NewTable.einh
    }
    label $base.li \
        -anchor w -borderwidth 0 -text [intlmsg Inherits]
    entry $base.einh \
        -background #fefefe -borderwidth 1 -selectborderwidth 0 \
        -textvariable PgAcVar(nt,inherits) 
    bind $base.einh <Key-Return> {
        focus .pgaw:NewTable.e2
    }
    button $base.binh \
        -borderwidth 1 \
        -command {if {[winfo exists .pgaw:NewTable.ddf]} {
    destroy .pgaw:NewTable.ddf
} else {
    create_drop_down .pgaw:NewTable 386 23 220
    focus .pgaw:NewTable.ddf.sb
    foreach tbl [Database::getTablesList] {.pgaw:NewTable.ddf.lb insert end $tbl}
    bind .pgaw:NewTable.ddf.lb <ButtonRelease-1> {
        set i [.pgaw:NewTable.ddf.lb curselection]
        if {$i!=""} {
            if {$PgAcVar(nt,inherits)==""} {
        set PgAcVar(nt,inherits) [.pgaw:NewTable.ddf.lb get $i]
            } else {
        set PgAcVar(nt,inherits) "$PgAcVar(nt,inherits),[.pgaw:NewTable.ddf.lb get $i]"
            }
        }
        if {$i!=""} {focus .pgaw:NewTable.e2}
        destroy .pgaw:NewTable.ddf
        break
    }
}} \
        -highlightthickness 0 -takefocus 0 -image dnarw
    entry $base.e2 \
        -background #fefefe -borderwidth 1 -selectborderwidth 0 \
        -textvariable PgAcVar(nt,fieldname) 
    bind $base.e2 <Key-Return> {
        focus .pgaw:NewTable.e1
    }
    entry $base.e1 \
        -background #fefefe -borderwidth 1 -selectborderwidth 0 \
        -textvariable PgAcVar(nt,fldtype) 
    bind $base.e1 <Key-Return> {
        focus .pgaw:NewTable.e5
    }
    entry $base.e3 \
        -background #fefefe -borderwidth 1 -selectborderwidth 0 \
        -textvariable PgAcVar(nt,fldsize) 
    bind $base.e3 <Key-Return> {
        focus .pgaw:NewTable.e5
    }
    entry $base.e5 \
        -background #fefefe -borderwidth 1 -selectborderwidth 0 \
        -textvariable PgAcVar(nt,defaultval) 
    bind $base.e5 <Key-Return> {
        focus .pgaw:NewTable.cb1
    }
    checkbutton $base.cb1 \
        -borderwidth 1 \
        -offvalue { } -onvalue { NOT NULL} -text [intlmsg {field cannot be null}] \
        -variable PgAcVar(nt,notnull) 
    label $base.lab1 \
        -borderwidth 0 -text [intlmsg type]
    label $base.lab2 \
        -borderwidth 0 -anchor w -text [intlmsg {field name}]
    label $base.lab3 \
        -borderwidth 0 -text [intlmsg size]
    label $base.lab4 \
        -borderwidth 0 -anchor w -text [intlmsg {Default value}]
    button $base.addfld \
        -borderwidth 1 -command Tables::newtable:add_new_field \
        -text [intlmsg {Add field}]
    button $base.delfld \
        -borderwidth 1 -command {catch {.pgaw:NewTable.lb delete [.pgaw:NewTable.lb curselection]}} \
        -text [intlmsg {Delete field}]
    button $base.emptb \
        -borderwidth 1 -command {.pgaw:NewTable.lb delete 0 [.pgaw:NewTable.lb size]} \
        -text [intlmsg {Delete all}]
    button $base.maketbl \
        -borderwidth 1 -command Tables::newtable:create \
        -text [intlmsg Create]
    listbox $base.lb \
        -background #fefefe -foreground #000000 -borderwidth 1 \
        -selectbackground #c3c3c3 -font $PgAcVar(pref,font_fix) \
        -selectborderwidth 0 -yscrollcommand {.pgaw:NewTable.sb set} 
    bind $base.lb <ButtonRelease-1> {
        if {[.pgaw:NewTable.lb curselection]!=""} {
    set fldname [string trim [lindex [split [.pgaw:NewTable.lb get [.pgaw:NewTable.lb curselection]]] 0]]
}
    }
    button $base.exitbtn \
        -borderwidth 1 -command {Window destroy .pgaw:NewTable} \
        -text [intlmsg Cancel]
    button $base.helpbtn \
        -borderwidth 1 -command {Help::load new_table} \
        -text [intlmsg Help]
    label $base.l1 \
        -anchor w -borderwidth 1 \
        -relief raised -text "       [intlmsg {field name}]"
    label $base.l2 \
        -borderwidth 1 \
        -relief raised -text [intlmsg type]
    label $base.l3 \
        -borderwidth 1 \
        -relief raised -text [intlmsg options]
    scrollbar $base.sb \
        -borderwidth 1 -command {.pgaw:NewTable.lb yview} -orient vert 
    label $base.l93 \
        -background white \
        -anchor w -borderwidth 0 -text [intlmsg {Table name}]
    button $base.mvup \
        -borderwidth 1 \
        -command {if {[.pgaw:NewTable.lb size]>1} {
    set i [.pgaw:NewTable.lb curselection]
    if {($i!="")&&($i>0)} {
        .pgaw:NewTable.lb insert [expr {$i-1}] [.pgaw:NewTable.lb get $i]
        .pgaw:NewTable.lb delete [expr {$i+1}]
        .pgaw:NewTable.lb selection set [expr {$i-1}]
    }
}} \
        -text [intlmsg {Move up}]
    button $base.mvdn \
        -borderwidth 1 \
        -command {if {[.pgaw:NewTable.lb size]>1} {
    set i [.pgaw:NewTable.lb curselection]
    if {($i!="")&&($i<[expr {[.pgaw:NewTable.lb size]-1}])} {
        .pgaw:NewTable.lb insert [expr {$i+2}] [.pgaw:NewTable.lb get $i]
        .pgaw:NewTable.lb delete $i
        .pgaw:NewTable.lb selection set [expr {$i+1}]
    }
}} \
        -text [intlmsg {Move down}]
    button $base.button17 \
        -borderwidth 1 \
        -command {
if {[winfo exists .pgaw:NewTable.ddf]} {
    destroy .pgaw:NewTable.ddf
} else {
    create_drop_down .pgaw:NewTable 291 80 97
    focus .pgaw:NewTable.ddf.sb
    .pgaw:NewTable.ddf.lb insert end char varchar text int2 int4 serial float4 float8 money abstime date datetime interval reltime time timespan timestamp boolean box circle line lseg path point polygon
    bind .pgaw:NewTable.ddf.lb <ButtonRelease-1> {
        set i [.pgaw:NewTable.ddf.lb curselection]
        if {$i!=""} {set PgAcVar(nt,fldtype) [.pgaw:NewTable.ddf.lb get $i]}
        destroy .pgaw:NewTable.ddf
        if {$i!=""} {
            if {[lsearch {char varchar} $PgAcVar(nt,fldtype)]==-1} {
        set PgAcVar(nt,fldsize) {}
        .pgaw:NewTable.e3 configure -state disabled
        focus .pgaw:NewTable.e5
            } else {
        .pgaw:NewTable.e3 configure -state normal
        focus .pgaw:NewTable.e3
            }
        }
        break
    }
}} \
        -highlightthickness 0 -takefocus 0 -image dnarw 
    label $base.lco \
        -borderwidth 0 -anchor w -text [intlmsg Constraint]
    entry $base.eco \
        -background #fefefe -borderwidth 1 -textvariable PgAcVar(nt,constraint) 
    label $base.lch \
        -borderwidth 0 -text [intlmsg check]
    entry $base.ech \
        -background #fefefe -borderwidth 1 -textvariable PgAcVar(nt,check) 
    label $base.ll \
        -borderwidth 1 \
        -relief raised 
    checkbutton $base.pk \
        -borderwidth 1 \
        -offvalue { } -onvalue * -text [intlmsg {primary key}] -variable PgAcVar(nt,primarykey) 
    label $base.lpk \
        -borderwidth 1 \
        -relief raised -text K 
    place $base.etabn \
        -x 105 -y 5 -width 136 -height 20 -anchor nw -bordermode ignore 
    place $base.li \
        -x 245 -y 7 -height 16 -anchor nw -bordermode ignore 
    place $base.einh \
        -x 300 -y 5 -width 308 -height 20 -anchor nw -bordermode ignore 
    place $base.binh \
        -x 590 -y 7 -width 16 -height 16 -anchor nw -bordermode ignore 
    place $base.e2 \
        -x 105 -y 60 -width 136 -height 20 -anchor nw -bordermode ignore 
    place $base.e1 \
        -x 291 -y 60 -width 98 -height 20 -anchor nw -bordermode ignore 
    place $base.e3 \
        -x 470 -y 60 -width 46 -height 20 -anchor nw -bordermode ignore 
    place $base.e5 \
        -x 105 -y 82 -width 136 -height 20 -anchor nw -bordermode ignore 
    place $base.cb1 \
        -x 245 -y 83 -height 20 -anchor nw -bordermode ignore 
    place $base.lab1 \
        -x 247 -y 62 -height 16 -anchor nw -bordermode ignore 
    place $base.lab2 \
        -x 4 -y 62 -height 16 -anchor nw -bordermode ignore 
    place $base.lab3 \
        -x 400 -y 62 -height 16 -anchor nw -bordermode ignore 
    place $base.lab4 \
        -x 5 -y 84 -height 16 -anchor nw -bordermode ignore 
    place $base.addfld \
        -x 530 -y 58 -width 100 -height 26 -anchor nw -bordermode ignore 
    place $base.delfld \
        -x 530 -y 190 -width 100 -height 26 -anchor nw -bordermode ignore 
    place $base.emptb \
        -x 530 -y 220 -width 100 -height 26 -anchor nw -bordermode ignore 
    place $base.maketbl \
        -x 530 -y 365 -width 100 -height 26 -anchor nw -bordermode ignore 
    place $base.lb \
        -x 4 -y 121 -width 506 -height 269 -anchor nw -bordermode ignore 
    place $base.helpbtn \
        -x 530 -y 305 -width 100 -height 26 -anchor nw -bordermode ignore 
    place $base.exitbtn \
        -x 530 -y 335 -width 100 -height 26 -anchor nw -bordermode ignore 
    place $base.l1 \
        -x 18 -y 105 -width 195 -height 18 -anchor nw -bordermode ignore 
    place $base.l2 \
        -x 213 -y 105 -width 88 -height 18 -anchor nw -bordermode ignore 
    place $base.l3 \
        -x 301 -y 105 -width 225 -height 18 -anchor nw -bordermode ignore 
    place $base.sb \
        -x 509 -y 121 -width 18 -height 269 -anchor nw -bordermode ignore 
    place $base.l93 \
        -x 4 -y 7 -height 16 -anchor nw -bordermode ignore 
    place $base.mvup \
        -x 530 -y 120 -width 100 -height 26 -anchor nw -bordermode ignore 
    place $base.mvdn \
        -x 530 -y 150 -width 100 -height 26 -anchor nw -bordermode ignore 
    place $base.button17 \
        -x 371 -y 62 -width 16 -height 16 -anchor nw -bordermode ignore 
    place $base.lco \
        -x 5 -y 28 -width 58 -height 16 -anchor nw -bordermode ignore 
    place $base.eco \
        -x 105 -y 27 -width 136 -height 20 -anchor nw -bordermode ignore 
    place $base.lch \
        -x 245 -y 30 -anchor nw -bordermode ignore 
    place $base.ech \
        -x 300 -y 27 -width 308 -height 22 -anchor nw -bordermode ignore 
    place $base.ll \
        -x 5 -y 53 -width 603 -height 2 -anchor nw -bordermode ignore 
    place $base.pk \
        -x 450 -y 83 -height 20 -anchor nw -bordermode ignore 
    place $base.lpk \
        -x 4 -y 105 -width 14 -height 18 -anchor nw -bordermode ignore 
}

proc vTclWindow.pgaw:TableInfo {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:TableInfo
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel \
        -background #c7c3c7 
    wm focusmodel $base passive
#    wm geometry $base 500x400+152+135
    wm minsize $base 100 100
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Table information"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    bind $base <Key-F1> "Help::load view_table_structure"
    NoteBook $base.nb
    pack $base.nb -expand 1 -fill both
    foreach i {General Columns Indexes Permissions} {
        $base.nb insert end $i -text [intlmsg $i] -raisecmd "Tables::refreshInfo $i"
    }
    set page_general [$base.nb getframe General]
    set page_columns [$base.nb getframe Columns] 
    set page_indexes [$base.nb getframe Indexes]
    set page_permissions [$base.nb getframe Permissions]

    # general page
    TitleFrame $page_general.tf_id -text [intlmsg Identification] \
        -font $PgAcVar(pref,font_bold)
    pack $page_general.tf_id -side top -anchor nw

    set titleframe [$page_general.tf_id getframe]
    foreach {desc name} {
            {Table name} {tablename}
            {Table oid} {tableoid}
            {Owner} {owner}
            {Owner ID} {ownerid}
            {Has primary key?} {hasprimarykey}
            {Has rules?} {hasrules}
        } {
        label $titleframe.n$name -text [intlmsg $desc]
        label $titleframe.v$name -textvariable PgAcVar(tblinfo,$name) \
            -bd 1 \
            -background white \
            -justify left \
            -relief sunken \
            -width 30 \
            -anchor w
        grid $titleframe.n$name $titleframe.v$name -sticky e
    }

    TitleFrame $page_general.tf_stat -text [intlmsg Statistics] \
        -font $PgAcVar(pref,font_bold)
    pack $page_general.tf_stat -side top -anchor nw

    set titleframe [$page_general.tf_stat getframe]
    foreach {desc name} {
            {Number of tuples} {numtuples}
            {Number of pages} {numpages}
        } {
        label $titleframe.n$name -text [intlmsg $desc]
        label $titleframe.v$name -textvariable PgAcVar(tblinfo,$name) \
            -bd 1 \
            -background white \
            -justify left \
            -relief sunken \
            -width 16 \
            -anchor e

        grid $titleframe.n$name $titleframe.v$name -sticky e
    }
    
    # columns page
    scrollbar $page_columns.xscroll \
        -width 12 \
        -command [list $page_columns.cols xview] \
        -highlightthickness 0 \
        -orient horizontal \
        -background #DDDDDD \
        -takefocus 0
    scrollbar $page_columns.yscroll \
        -width 12 \
        -command [list $page_columns.cols yview] \
        -highlightthickness 0 \
        -background #DDDDDD \
        -takefocus 0
    set PgAcVar(tblinfo,cols) [tablelist::tablelist $page_columns.cols \
        -yscrollcommand [list $page_columns.yscroll set] \
        -xscrollcommand [list $page_columns.xscroll set] \
        -labelcommand tablelist::sortByColumn \
        -background #fefefe \
        -stripebg #e0e8f0 \
        -selectbackground #DDDDDD \
        -selectmode extended \
        -font $PgAcVar(pref,font_normal) \
        -labelfont $PgAcVar(pref,font_bold) \
        -stretch all \
        -columns [list \
            0 [intlmsg "field name"] left \
            0 [intlmsg "type"] left \
            0 [intlmsg "size"] left \
            0 [intlmsg "not null"] left] \
        -selectforeground #708090 \
        -labelbackground #DDDDDD \
        -labelforeground navy
    ]
    frame $page_columns.buttons
    button $page_columns.buttons.addcolbtn \
        -borderwidth 1 \
        -command {Window show .pgaw:AddField
            set PgAcVar(addfield,name) {}
            set PgAcVar(addfield,type) {}
            wm transient .pgaw:AddField .pgaw:TableInfo
            focus .pgaw:AddField.e1} \
         -padx 9 -pady 3 -text [intlmsg {Add new column}]
    button $page_columns.buttons.rencolbtn \
        -borderwidth 1 \
        -command {
            if {[set PgAcVar(tblinfo,col_id) [$PgAcVar(tblinfo,cols) curselection]]==""} then {
                bell
            } else {
                set PgAcVar(tblinfo,old_cn) [lindex [$PgAcVar(tblinfo,cols) get [$PgAcVar(tblinfo,cols) curselection]] 0]
                set PgAcVar(tblinfo,new_cn) $PgAcVar(tblinfo,old_cn)
                Window show .pgaw:RenameField
            }
        } \
        -padx 9 -pady 3 -text [intlmsg {Rename column}]
    button $page_columns.buttons.addidxbtn \
        -borderwidth 1 -command Tables::addNewIndex \
        -padx 9 -pady 3 -text [intlmsg {Add new index}]

    pack $page_columns.buttons -side bottom -fill x
    grid $page_columns.buttons.addcolbtn \
        -column 0 -row 0 -columnspan 1 -rowspan 1 
    grid $page_columns.buttons.rencolbtn \
        -column 1 -row 0 -columnspan 1 -rowspan 1 
    grid $page_columns.buttons.addidxbtn \
        -column 2 -row 0 -columnspan 1 -rowspan 1 
    pack $page_columns.xscroll -side bottom -fill x
    pack $page_columns.yscroll -side right -fill y
    pack $page_columns.cols -side right -anchor nw -expand 1 -fill both

    # indexes page
    scrollbar $page_indexes.xscroll \
        -width 12 \
        -command [list $page_indexes.indexes xview] \
        -highlightthickness 0 \
        -orient horizontal \
        -background #DDDDDD \
        -takefocus 0
    scrollbar $page_indexes.yscroll \
        -width 12 \
        -command [list $page_indexes.indexes yview] \
        -highlightthickness 0 \
        -background #DDDDDD \
        -takefocus 0
    set PgAcVar(tblinfo,indexes) [tablelist::tablelist $page_indexes.indexes \
        -yscrollcommand [list $page_indexes.yscroll set] \
        -xscrollcommand [list $page_indexes.xscroll set] \
        -labelcommand tablelist::sortByColumn \
        -background #fefefe \
        -stripebg #e0e8f0 \
        -selectbackground #DDDDDD \
        -selectmode single \
        -font $PgAcVar(pref,font_normal) \
        -labelfont $PgAcVar(pref,font_bold) \
        -stretch all \
        -columns [list \
            0 [intlmsg "indexes"] left \
            0 [intlmsg "index columns"] left \
            0 [intlmsg "is unique?"] left \
            0 [intlmsg "is clustered?"] left \
        ] \
        -selectforeground #708090 \
        -labelbackground #DDDDDD \
        -labelforeground navy
    ]
    frame $page_indexes.buttons
    button $page_indexes.buttons.delidxbtn \
        -borderwidth 1 -command Tables::deleteIndex \
        -padx 9 -pady 3 -text [intlmsg {Delete index}]
    button $page_indexes.buttons.clusterbtn \
        -borderwidth 1 -command Tables::clusterIndex \
         -padx 9 -pady 3 -text [intlmsg {Cluster index}]

    pack $page_indexes.buttons -side bottom -fill x
    grid $page_indexes.buttons.delidxbtn \
        -column 0 -row 0 -columnspan 1 -rowspan 1 
    grid $page_indexes.buttons.clusterbtn \
        -column 1 -row 0 -columnspan 1 -rowspan 1 
    pack $page_indexes.xscroll -side bottom -fill x
    pack $page_indexes.yscroll -side right -fill y
    pack $page_indexes.indexes -side right -anchor nw -expand 1 -fill both

    # indexes page
    scrollbar $page_permissions.xscroll \
        -width 12 \
        -command [list $page_permissions.permissions xview] \
        -highlightthickness 0 \
        -orient horizontal \
        -background #DDDDDD \
        -takefocus 0
    scrollbar $page_permissions.yscroll \
        -width 12 \
        -command [list $page_permissions.permissions yview] \
        -highlightthickness 0 \
        -background #DDDDDD \
        -takefocus 0
    set PgAcVar(tblinfo,perms) [tablelist::tablelist $page_permissions.permissions \
        -yscrollcommand [list $page_permissions.yscroll set] \
        -xscrollcommand [list $page_permissions.xscroll set] \
        -labelcommand tablelist::sortByColumn \
        -background #fefefe \
        -stripebg #e0e8f0 \
        -selectbackground #DDDDDD \
        -selectmode single \
        -font $PgAcVar(pref,font_normal) \
        -labelfont $PgAcVar(pref,font_bold) \
        -stretch all \
        -columns [list \
            0 [intlmsg "user name"] left \
            0 [intlmsg "select"] left \
            0 [intlmsg "update"] left \
            0 [intlmsg "insert"] left \
            0 [intlmsg "rule"] left \
        ] \
        -selectforeground #708090 \
        -labelbackground #DDDDDD \
        -labelforeground navy
    ]
    frame $page_permissions.buttons
    button $page_permissions.buttons.adduserbtn \
        -borderwidth 1 -command {
            PgAcVar:clean permission,*
            Window show .pgaw:Permissions
        } \
        -padx 9 -pady 3 -text [intlmsg {Add user}]
    button $page_permissions.buttons.chguserbtn \
        -command Tables::loadPermissions \
        -borderwidth 1 -padx 9 -pady 3 -text [intlmsg {Change permissions}]
    button $page_permissions.buttons.usergrpbtn \
        -command {
            ::Usergroups::designPerms [::Database::quoteObject $PgAcVar(tblinfo,tablename)] table
        } \
        -borderwidth 1 -padx 9 -pady 3 -text [intlmsg {User-Group manager}]

    pack $page_permissions.buttons -side bottom -fill x
    grid $page_permissions.buttons.adduserbtn \
        -column 0 -row 0 -columnspan 1 -rowspan 1 
    grid $page_permissions.buttons.chguserbtn \
        -column 1 -row 0 -columnspan 1 -rowspan 1 
    grid $page_permissions.buttons.usergrpbtn \
        -column 2 -row 0 -columnspan 1 -rowspan 1 
    pack $page_permissions.xscroll -side bottom -fill x
    pack $page_permissions.yscroll -side right -fill y
    pack $page_permissions.permissions -side right -anchor nw -expand 1 -fill both

    $base.nb raise [$base.nb pages 0]
}

proc vTclWindow.pgaw:AddField {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:AddField
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm deiconify $base
    wm title $base [intlmsg "Add new column"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    LabelEntry $base.e1 \
        -label [intlmsg {Field name}] \
        -labeljustify right \
        -labelfont $PgAcVar(pref,font_normal) \
        -font $PgAcVar(pref,font_normal) \
        -textvariable PgAcVar(addfield,name)

    LabelEntry $base.e2 \
        -label [intlmsg {Field type}] \
        -labeljustify right \
        -labelfont $PgAcVar(pref,font_normal) \
        -font $PgAcVar(pref,font_normal) \
        -textvariable PgAcVar(addfield,type) \
        -command Tables::addNewColumn

    frame $base.fb
    button $base.fb.b1 \
        -borderwidth 1 -command Tables::addNewColumn -text [intlmsg {Add field}]
    button $base.fb.b2 \
        -borderwidth 1 -command {Window destroy .pgaw:AddField} -text [intlmsg Cancel]

    pack $base.e1 $base.e2 -side top -anchor "e"
    pack $base.fb -side top
    grid $base.fb.b1 -column 0 -row 0
    grid $base.fb.b2 -column 1 -row 0
}

proc vTclWindow.pgaw:AddIndex {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:AddIndex
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 334x203+265+266
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm deiconify $base
    wm title $base [intlmsg "Add new index"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    frame $base.f \
        -borderwidth 2 -height 75 -relief groove -width 125 
    frame $base.f.fin \
        -height 75 -relief groove -width 125 
    label $base.f.fin.lin \
        -borderwidth 0 -relief raised -text [intlmsg {Index name}]
    entry $base.f.fin.ein \
        -background #fefefe -borderwidth 1 -width 28 -textvariable PgAcVar(addindex,indexname) 
    checkbutton $base.f.cbunique -borderwidth 1 \
        -offvalue { } -onvalue unique -text [intlmsg {Is unique ?}] -variable PgAcVar(addindex,unique)
    label $base.f.ls1 \
        -anchor w -background #dfdbdf -borderwidth 0 -foreground #000086 \
        -justify left -relief raised -textvariable PgAcVar(addindex,indexfields) \
        -wraplength 300 
    label $base.f.lif \
        -borderwidth 0 -relief raised -text "[intlmsg {Index fields}]:"
    label $base.f.ls2 \
        -borderwidth 0 -relief raised -text { } 
    label $base.f.ls3 \
        -borderwidth 0 -relief raised -text { } 
    frame $base.fb \
        -height 75 -relief groove -width 125 
    button $base.fb.btncreate -command Tables::createNewIndex \
        -padx 9 -pady 3 -text [intlmsg Create]
    button $base.fb.btncancel \
        -command {Window destroy .pgaw:AddIndex} -padx 9 -pady 3 -text [intlmsg Cancel]
    pack $base.f \
        -in .pgaw:AddIndex -anchor center -expand 1 -fill both -side top 
    grid $base.f.fin \
        -in .pgaw:AddIndex.f -column 0 -row 0 -columnspan 1 -rowspan 1 
    grid $base.f.fin.lin \
        -in .pgaw:AddIndex.f.fin -column 0 -row 0 -columnspan 1 -rowspan 1 
    grid $base.f.fin.ein \
        -in .pgaw:AddIndex.f.fin -column 1 -row 0 -columnspan 1 -rowspan 1 
    grid $base.f.cbunique \
        -in .pgaw:AddIndex.f -column 0 -row 5 -columnspan 1 -rowspan 1 
    grid $base.f.ls1 \
        -in .pgaw:AddIndex.f -column 0 -row 3 -columnspan 1 -rowspan 1 
    grid $base.f.lif \
        -in .pgaw:AddIndex.f -column 0 -row 2 -columnspan 1 -rowspan 1 -sticky w 
    grid $base.f.ls2 \
        -in .pgaw:AddIndex.f -column 0 -row 1 -columnspan 1 -rowspan 1 
    grid $base.f.ls3 \
        -in .pgaw:AddIndex.f -column 0 -row 4 -columnspan 1 -rowspan 1 
    pack $base.fb \
        -in .pgaw:AddIndex -anchor center -expand 0 -fill x -side bottom 
    grid $base.fb.btncreate \
        -in .pgaw:AddIndex.fb -column 0 -row 0 -columnspan 1 -rowspan 1 
    grid $base.fb.btncancel \
        -in .pgaw:AddIndex.fb -column 1 -row 0 -columnspan 1 -rowspan 1 
}

proc vTclWindow.pgaw:RenameField {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:RenameField
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 215x75+258+213
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm deiconify $base
    wm title $base [intlmsg "Rename column"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    label $base.l1 \
        -borderwidth 0 -text [intlmsg {New name}]
    entry $base.e1 \
        -background #fefefe -borderwidth 1 -textvariable PgAcVar(tblinfo,new_cn)
    focus $base.e1
    bind $base.e1 <Key-KP_Enter> "Tables::renameColumn"
    bind $base.e1 <Key-Return> "Tables::renameColumn"
    frame $base.f \
        -height 75 -relief groove -width 147 
    button $base.f.b1 \
        -borderwidth 1 -command Tables::renameColumn -text [intlmsg Rename]
    button $base.f.b2 \
        -borderwidth 1 -command {Window destroy .pgaw:RenameField} -text [intlmsg Cancel]
    label $base.l2 -borderwidth 0 
    grid $base.l1 \
        -in .pgaw:RenameField -column 0 -row 0 -columnspan 1 -rowspan 1 
    grid $base.e1 \
        -in .pgaw:RenameField -column 1 -row 0 -columnspan 1 -rowspan 1 
    grid $base.f \
        -in .pgaw:RenameField -column 0 -row 4 -columnspan 2 -rowspan 1 
    grid $base.f.b1 \
        -in .pgaw:RenameField.f -column 0 -row 0 -columnspan 1 -rowspan 1 
    grid $base.f.b2 \
        -in .pgaw:RenameField.f -column 1 -row 0 -columnspan 1 -rowspan 1 
    grid $base.l2 \
        -in .pgaw:RenameField -column 0 -row 3 -columnspan 1 -rowspan 1 
}

proc vTclWindow.pgaw:Permissions {base} {
    if {$base == ""} {
        set base .pgaw:Permissions
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 273x147+256+266
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm deiconify $base
    wm title $base [intlmsg "Permissions"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    frame $base.f1 \
        -height 103 -relief groove -width 125 
    label $base.f1.l \
        -borderwidth 0 -relief raised -text [intlmsg {User name}]
    entry $base.f1.ename -textvariable PgAcVar(permission,username) \
        -background #fefefe -borderwidth 1 
    label $base.f1.l2 \
        -borderwidth 0 -relief raised -text { } 
    label $base.f1.l3 \
        -borderwidth 0 -relief raised -text { } 
    frame $base.f2 \
        -height 75 -relief groove -borderwidth 2 -width 125 
    checkbutton $base.f2.cb1 -borderwidth 1 -padx 4 -pady 4 \
        -text [intlmsg select] -variable PgAcVar(permission,select) 
    checkbutton $base.f2.cb2 -borderwidth 1 -padx 4 -pady 4 \
        -text [intlmsg update] -variable PgAcVar(permission,update)
    checkbutton $base.f2.cb3 -borderwidth 1 -padx 4 -pady 4 \
        -text [intlmsg insert] -variable PgAcVar(permission,insert)
    checkbutton $base.f2.cb4 -borderwidth 1 -padx 4 -pady 4 \
        -text [intlmsg rule] -variable PgAcVar(permission,rule)
    frame $base.fb \
        -height 75 -relief groove -width 125 
    button $base.fb.btnsave -command Tables::savePermissions \
        -padx 9 -pady 3 -text [intlmsg Save]
    button $base.fb.btncancel -command {Window destroy .pgaw:Permissions} \
        -padx 9 -pady 3 -text [intlmsg Cancel]
    pack $base.f1 \
        -in .pgaw:Permissions -anchor center -expand 0 -fill none -side top 
    grid $base.f1.l \
        -in .pgaw:Permissions.f1 -column 0 -row 1 -columnspan 1 -rowspan 1 
    grid $base.f1.ename \
        -in .pgaw:Permissions.f1 -column 1 -row 1 -columnspan 1 -rowspan 1 -padx 2 
    grid $base.f1.l2 \
        -in .pgaw:Permissions.f1 -column 0 -row 0 -columnspan 1 -rowspan 1 
    grid $base.f1.l3 \
        -in .pgaw:Permissions.f1 -column 0 -row 2 -columnspan 1 -rowspan 1 
    pack $base.f2 \
        -in .pgaw:Permissions -anchor center -expand 0 -fill none -side top 
    grid $base.f2.cb1 \
        -in .pgaw:Permissions.f2 -column 0 -row 1 -columnspan 1 -rowspan 1 -sticky w 
    grid $base.f2.cb2 \
        -in .pgaw:Permissions.f2 -column 1 -row 1 -columnspan 1 -rowspan 1 -sticky w 
    grid $base.f2.cb3 \
        -in .pgaw:Permissions.f2 -column 0 -row 2 -columnspan 1 -rowspan 1 -sticky w 
    grid $base.f2.cb4 \
        -in .pgaw:Permissions.f2 -column 1 -row 2 -columnspan 1 -rowspan 1 -sticky w 
    pack $base.fb \
        -in .pgaw:Permissions -anchor center -expand 0 -fill none -pady 3 -side bottom 
    grid $base.fb.btnsave \
        -in .pgaw:Permissions.fb -column 0 -row 0 -columnspan 1 -rowspan 1 
    grid $base.fb.btncancel \
        -in .pgaw:Permissions.fb -column 1 -row 0 -columnspan 1 -rowspan 1 

    focus $base.f1.ename
}




