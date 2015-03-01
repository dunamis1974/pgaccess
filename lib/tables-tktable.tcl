#==========================================================
# Tables --
#
#   creation and management of database tables
#
#==========================================================
#

############################ PUT THESE IN PGACCESS #####################
set PgAcVar(tables,maxcolwidth) 20
############################ PUT THESE IN PGACCESS #####################

namespace eval Tables {
    variable Win
    variable fontmeasure
    variable oldvalue
}

######
###### TODO
# convert PgAcVar global to variable (Tables scope)

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
    if {$PgAcVar(mw,$wn_,isaquery) || !$PgAcVar(mw,$wn_,updatable)} {
        # if its a query or view then dont worry about the ctid column
        set sql "CREATE TEMP TABLE $tmptbl
                                AS $PgAcVar(mw,$wn_,query)"
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
        append insql "INSERT INTO $desttable_ ($colnames) VALUES ("
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
#<<<<<<< tables.tcl
#    set l [split $tablename .]
#    if {[llength $l] == 2} {
#        set s [lindex $l 0]
#        set t [lindex $l 1]
#        set PgAcVar(mw,$wn,query) "SELECT ctid,* FROM \"$s\".\"$t\""
#    } else {
#        set PgAcVar(mw,$wn,query) "select ctid,* from \"$tablename\""
#    }
        #set PgAcVar(mw,$wn,query) "SELECT ctid,* FROM [::Database::quoteObject $tablename]"

###    set PgAcVar(mw,$wn,ukey) [::Database::getUniqueKeys $::CurrentDB [::Database::quoteObject $tablename]]
###    set PgAcVar(mw,$wn,updatable) 1
###
###    if {[llength $PgAcVar(mw,$wn,ukey)] == 0} {
###        set PgAcVar(mw,$wn,updatable) 0
###    }
###    set PgAcVar(mw,$wn,query) "SELECT [join [linsert $PgAcVar(mw,$wn,ukey) end *] ,]
###                                 FROM [::Database::quoteObject $tablename]"
###
###    set PgAcVar(mw,$wn,isaquery) 0
###    initVariables $wn
###    refreshRecords $wn
###    catch {wm title $wn "$tablename"}
#=======
#>>>>>>> 1.36

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

    foreach T {junk select update insert rule} P [$PgAcVar(tblinfo,perms) get $sel] {
        set PgAcVar(permission,$T) [expr {"X"==$P}]
    }

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
    set tname [::Database::quoteObject $PgAcVar(tblinfo,tablename)]
    sql_exec noquiet "REVOKE all on $tname from $usrname"

    foreach T {select insert update rule} {
        if {$PgAcVar(permission,$T)} {
            sql_exec noquiet "GRANT $T on $tname to $usrname"
        }
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
                wpg_select $CurrentDB "SELECT pg_index.*, pg_class.oid
                                FROM [::Database::qualifySysTable pg_index],
					[::Database::qualifySysTable pg_class]
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
                            wpg_select $CurrentDB "SELECT attname FROM pg_attribute WHERE attrelid=$PgAcVar(tblinfo,tableoid) AND attnum=$field" rec1 {
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
            set temp [string map {\" ""} [lindex $PgAcVar(tblinfo,permissions) 0]]
            foreach token [split $temp ,] {
                set oli [split $token =]
                set uname [lindex $oli 0]
                set rights [lindex $oli 1]
                if {$uname == ""} {set uname PUBLIC}
                foreach P {r w a R} {
                    set r($P) ""
                    if {[string first $P $rights] != -1} {set r($P) X}
                }
                $PgAcVar(tblinfo,perms) insert end [list $uname $r(r) $r(w) $r(a) $r(R)]
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
    set PgAcVar(mw,$wn,number) $PgAcVar(mwcount)
    set PgAcVar(mw,$wn,tablename) $tablename
    createWindow
    loadLayout $wn $tablename

    foreach {a b} [split $order] break
    if {![info exists a]} {set a ""}
    if {![info exists b]} {set b ""}
    set PgAcVar(mw,$wn,sortfield) $a
    set PgAcVar(mw,$wn,sortdirection) $b
    set PgAcVar(mw,$wn,filter) $filter
    #set PgAcVar(mw,$wn,query) "select oid,\"$tablename\".* from \"$tablename\""

###    set l [split $tablename .]
###    if {[llength $l] == 2} {
###        set s [lindex $l 0]
###        set t [lindex $l 1]
###        set PgAcVar(mw,$wn,query) "select ctid,* from \"$s\".\"$t\""
###    } else {
###        set PgAcVar(mw,$wn,query) "select ctid,* from \"$tablename\""
###    }

    set qtab [::Database::quoteObject $tablename]
    set PgAcVar(mw,$wn,ukey) [::Database::getUniqueKeys $::CurrentDB $qtab]
    set PgAcVar(mw,$wn,updatable) [llength $PgAcVar(mw,$wn,ukey)]

    set PgAcVar(mw,$wn,query) "SELECT [join [linsert $PgAcVar(mw,$wn,ukey) end *] ,]
                                 FROM [::Database::quoteObject $tablename]"

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
        #$wn.c delete hili
    }

}; # end proc ::Tables::deleteRecord


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

    if {[string match "desc" $PgAcVar(mw,$wn_,$name_,sortdirection)]} {
        set PgAcVar(mw,$wn_,$name_,sortdirection) asc
    } else {
        set PgAcVar(mw,$wn_,$name_,sortdirection) desc
    }
    refreshRecords $wn_

    return

}; # end proc ::Tables::sortFromHeader


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::drawNewRecord {wn} {

    global PgAcVar

    if {$PgAcVar(pref,tvfont)=="helv"} {
        set tvfont $PgAcVar(pref,font_normal)
    } else {
        set tvfont $PgAcVar(pref,font_fix)
    }
    if {$PgAcVar(mw,$wn,updatable)} {
	#set rec [split [string repeat "*" $PgAcVar(mw,$wn,colcount)] ""]
	#lappend PgAcVar(mw,$wn,records) $rec
    }

    return

}; # end proc ::Tables::drawNewRecord


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::finishEdit {wn} {

    global PgAcVar CurrentDB

# User has edited the text ?
###if {!$PgAcVar(mw,$wn,dirtyrec)} {
###    # No, unfocus text
###    #$wn.c focus {}
###    # For restoring * to the new record position
###    if {$PgAcVar(mw,$wn,id_edited)!=""} {
###        if {[lsearch [$wn.c gettags $PgAcVar(mw,$wn,id_edited)] new]!=-1} {
###            $wn.c itemconfigure $PgAcVar(mw,$wn,id_edited) -text $PgAcVar(mw,$wn,text_initial_value)
###        }
###    }
###    set PgAcVar(mw,$wn,id_edited) {};set PgAcVar(mw,$wn,text_initial_value) {}
###    return 1
###}
# Trimming the spaces
#set fldval [string trim [$wn.c itemcget $PgAcVar(mw,$wn,id_edited) -text]]
#$wn.c itemconfigure $PgAcVar(mw,$wn,id_edited) -text $fldval
#if {[string compare $PgAcVar(mw,$wn,text_initial_value) $fldval]==0} {
    #set PgAcVar(mw,$wn,dirtyrec) 0
    #$wn.c focus {}
    #set PgAcVar(mw,$wn,id_edited) {};set PgAcVar(mw,$wn,text_initial_value) {}
    #return 1
#}
#setCursor CLOCK
#set ctid [lindex $PgAcVar(mw,$wn,keylist) $PgAcVar(mw,$wn,row_edited)]
#set fld [lindex $PgAcVar(mw,$wn,colnames) [get_tag_info $wn $PgAcVar(mw,$wn,id_edited) c]]
###set fillcolor black
###if {$PgAcVar(mw,$wn,row_edited)==$PgAcVar(mw,$wn,last_rownum)} {
###    set fillcolor red
###    set sfp [lsearch $PgAcVar(mw,$wn,newrec_fields) "\"$fld\""]
###    if {$sfp>-1} {
###        set PgAcVar(mw,$wn,newrec_fields) [lreplace $PgAcVar(mw,$wn,newrec_fields) $sfp $sfp]
###        set PgAcVar(mw,$wn,newrec_values) [lreplace $PgAcVar(mw,$wn,newrec_values) $sfp $sfp]
###    }
###    lappend PgAcVar(mw,$wn,newrec_fields) "\"$fld\""
###    lappend PgAcVar(mw,$wn,newrec_values) '$fldval'
###    # Remove the untouched tag from the object
###    #$wn.c dtag $PgAcVar(mw,$wn,id_edited) unt
###        #$wn.c itemconfigure $PgAcVar(mw,$wn,id_edited) -fill red
###    set retval 1
###} else {
###    set PgAcVar(mw,$wn,msg) "Updating record ..."
###    after 1000 "set PgAcVar(mw,$wn,msg) {}"
###    regsub -all ' $fldval  \\' sqlfldval
###
####FIXME rjr 4/29/1999 special case null so it can be entered into tables
####really need to write a tcl sqlquote proc which quotes the string only
####if necessary, so it can be used all over pgaccess, instead of explicit 's
###
###    if {$sqlfldval == "null"} {
###        set retval [sql_exec noquiet "
###            UPDATE [::Database::quoteObject $PgAcVar(mw,$wn,tablename)] \
###               SET \"$fld\"= null
###             WHERE ctid='$ctid'"]
###    } else {
###        set retval [sql_exec noquiet "
###            UPDATE [::Database::quoteObject $PgAcVar(mw,$wn,tablename)] \
###               SET \"$fld\"='$sqlfldval'
###             WHERE ctid='$ctid'"]
###    }
###}
###setCursor DEFAULT
###if {!$retval} {
###    set PgAcVar(mw,$wn,msg) ""
###    focus $wn.c
###    return 0
###}
###set PgAcVar(mw,$wn,dirtyrec) 0
####$wn.c focus {}
###set PgAcVar(mw,$wn,id_edited) {};set PgAcVar(mw,$wn,text_initial_value) {}
###return 1

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
    set pgres [wpg_exec $CurrentDB "SELECT *,oid 
                                      FROM pga_layout 
                                     WHERE tablename='$layoutname' 
                                  ORDER BY oid DESC"]

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
            showError "Multiple ($nrlay) layout info found\n\nPlease report the bug!"
            sql_exec quiet "DELETE FROM pga_layout WHERE (tablename='$PgAcVar(mw,$wn,tablename)') AND (oid<>$goodoid)"
        }
    }
    pg_result $pgres -clear

    return

}; # end proc ::Tables::loadLayout


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
###    set lrbb [$wn.c bbox new]
###    lappend PgAcVar(mw,$wn,rowy) [lindex $lrbb 3]
###    $wn.c itemconfigure new -fill black
###    $wn.c dtag q new
###    # Replace * from untouched new row elements with "  "
###    foreach item [$wn.c find withtag unt] {
###        $wn.c itemconfigure $item -text "  "
###    }
###    $wn.c dtag q unt
###    incr PgAcVar(mw,$wn,last_rownum)
###    incr PgAcVar(mw,$wn,nrecs)
###    drawNewRecord $wn
###    set PgAcVar(mw,$wn,newrec_fields) {}
###    set PgAcVar(mw,$wn,newrec_values) {}

    return 1

}; # end proc ::Tables::insertNewRecord


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

    upvar #0 cells$PgAcVar(mw,$wn,number) CELLS

#cells$PgAcVar(mwcount)
    variable Win

    if {![finishEdit $wn]} return;

    initVariables $wn
    set PgAcVar(mw,$wn,leftcol) 0
    set PgAcVar(mw,$wn,leftoffset) 0
    set PgAcVar(mw,$wn,crtrow) {}
    set PgAcVar(mw,$wn,msg) [intlmsg "Accessing data. Please wait ..."]

    catch {$wn.f1.b1 configure -state disabled}
    setCursor CLOCK
    set is_error 1
###    if {[sql_exec noquiet "BEGIN"]} {
###	if {[sql_exec noquiet "declare mycursor cursor for $sql"]} {
###	    set pgres [wpg_exec $CurrentDB "fetch $PgAcVar(pref,rows) in mycursor"]
###	    if {$PgAcVar(pgsql,status)=="PGRES_TUPLES_OK"} {
###		set is_error 0
###	    }
###	}
###    }
###    if {$is_error} {
###	sql_exec quiet "END"
###	set PgAcVar(mw,$wn,msg) {}
###	catch {$wn.f1.b1 configure -state normal}
###	setCursor DEFAULT
###	set PgAcVar(mw,$wn,msg) "Error executing : $sql"
###	return
###    }

    set shift 0
    if {$PgAcVar(mw,$wn,updatable)} {
	set shift [llength $PgAcVar(mw,$wn,ukey)]
        for {set i 0} {$i < $shift} {incr i} {
	    #$Win(tableview,$PgAcVar(mw,$wn,number)) columnconfigure $i -hide 1
        }
    }
###
###    #
###    # checking at least the numer of fields
###    set attrlist [pg_result $pgres -lAttributes]
###    if {$PgAcVar(mw,$wn,layout_found)} then {
###	if {  ($PgAcVar(mw,$wn,colcount) != [expr {[llength $attrlist]-$shift}]) ||
###          ($PgAcVar(mw,$wn,colcount) != [llength $PgAcVar(mw,$wn,colnames)]) ||
###          ($PgAcVar(mw,$wn,colcount) != [llength $PgAcVar(mw,$wn,colwidth)]) } then {
###	    # No. of columns don't match, something is wrong
###	    # tk_messageBox -title [intlmsg Information] -message "Layout info changed !\nRescanning..."
###	    set PgAcVar(mw,$wn,layout_found) 0
###	    sql_exec quiet "DELETE FROM pga_layout WHERE tablename='$PgAcVar(mw,$wn,layout_name)'"
###	}
###    }
###    # Always take the col. names from the result
###    set PgAcVar(mw,$wn,colcount) [llength $attrlist]
###    if {$PgAcVar(mw,$wn,updatable)} {
###	incr PgAcVar(mw,$wn,colcount) -1
###    }
###
###    set PgAcVar(mw,$wn,colnames) {}
###    # In defPgAcVar(mw,$wn,colwidth) prepare PgAcVar(mw,$wn,colwidth) (in case that not layout_found)
###    set defPgAcVar(mw,$wn,colwidth) {}


    set pgres [wpg_exec $CurrentDB "$sql"]

    set attrlist [pg_result $pgres -attributes]

    set wincols [list]

puts "ATTRLST: $attrlist"

    set PgAcVar(mw,$wn,colnames) $attrlist
    set PgAcVar(mw,$wn,colshown) [lrange $attrlist $shift end]
    #foreach A $attrlist {
	#set n [lindex $A 0]
	#lappend PgAcVar(mw,$wn,colnames) $n
	#lappend PgAcVar(mw,$wn,colnames) $A
	#lappend defPgAcVar(mw,$wn,colwidth) 150
	#lappend wincols 0 $n left
    #}

    set PgAcVar(mw,$wn,colcount) [expr {[llength $attrlist] - $shift}]

    #${wn}.c configure -columns $wincols
    ${wn}.c configure -cols [llength $PgAcVar(mw,$wn,colnames)]

    #set cnt 0
    #foreach {a b c} $wincols {
	#${wn}.c columnconfigure $cnt -editable $PgAcVar(mw,$wn,updatable)
	#incr cnt
    #}

    ##
    ##  We just populate the comobox widget
    ##
    $Win(sortfield)  configure \
        -values $PgAcVar(mw,$wn,colnames)


    #if {!$PgAcVar(mw,$wn,layout_found)} {
	#set PgAcVar(mw,$wn,colwidth) $defPgAcVar(mw,$wn,colwidth)
	#sql_exec quiet "INSERT INTO pga_layout VALUES ('$PgAcVar(mw,$wn,layout_name)',$PgAcVar(mw,$wn,colcount),'$PgAcVar(mw,$wn,colnames)','$PgAcVar(mw,$wn,colwidth)')"
	#set PgAcVar(mw,$wn,layout_found) 1
    #}

    set PgAcVar(mw,$wn,nrecs) [pg_result $pgres -numTuples]
    set rowtotal $PgAcVar(mw,$wn,nrecs)

    if {$PgAcVar(mw,$wn,nrecs)>$PgAcVar(pref,rows)} {

	set PgAcVar(mw,$wn,msg) "Only first $PgAcVar(pref,rows) records \n\
	from $PgAcVar(mw,$wn,nrecs) have been loaded"

	set PgAcVar(mw,$wn,nrecs) $PgAcVar(pref,rows)
    }

    #$Win(mw,$wn,progress) configure \
	#-maximum $PgAcVar(mw,$wn,nrecs)

    set increment [expr {$PgAcVar(mw,$wn,nrecs)/10}]

    set tagoid {}
    if {$PgAcVar(pref,tvfont)=="helv"} {
	set tvfont $PgAcVar(pref,font_normal)
    } else {
	set tvfont $PgAcVar(pref,font_fix)
    }

    set PgAcVar(mw,$wn,updatekey) oid
    set PgAcVar(mw,$wn,keylist) {}
    set PgAcVar(mw,$wn,rowy) {24}
    set PgAcVar(mw,$wn,msg) "Loading maximum $PgAcVar(pref,rows) records ..."
    set wupdatable $PgAcVar(mw,$wn,updatable)

    $Win(tableview,$PgAcVar(mw,$wn,number)) configure -rows $PgAcVar(pref,rows)

    #set PgAcVar(mw,$wn,records) [list]
    #unset PgAcVar(mw,$wn,records)


    ##
    ##  Set the column headers
    ##
#puts "COLNAMES: $PgAcVar(mw,$wn,colnames)"
    $Win(tableview,$PgAcVar(mw,$wn,number)) set row 0,1 $PgAcVar(mw,$wn,colshown)

#puts "TABLE WINDOW: $PgAcVar(mw,$wn,number)"

    ##
    ##	Loop over the records from the query, and update
    ##	tablelist variable
    ##
########### MAYBE USE pg_select here instead
    for {set i 0} {$i<$PgAcVar(mw,$wn,nrecs)} {incr i} {

	set curtup [pg_result $pgres -getTuple $i]
	if {$wupdatable} {
	    #lappend PgAcVar(mw,$wn,keylist) [lindex $curtup 0]
	    lappend PgAcVar(mw,$wn,keylist) [lrange $curtup 0 [expr {$shift - 1}]]
	}

	#lappend PgAcVar(mw,$wn,records) [lrange $curtup 0 end]
        set row [expr {$i + 1}]
        $Win(tableview,$PgAcVar(mw,$wn,number)) set row $row,0 $row
        #$Win(tableview,$PgAcVar(mw,$wn,number)) set row $row,1 [lrange $curtup $shift end]
        set col 1
        foreach att [lrange $curtup $shift end] {
        
            if {![info exists max($col)] || [string length $att] > $max($col)} {
                set max($col) [string length $att]
            }

            set CELLS($row,$col) $att
                        #puts "ROW: $row COL: $col VALUE: $att"
            incr col
        }
        

        set min [$Win(tableview,$PgAcVar(mw,$wn,number)) cget -colwidth]
        foreach C [array names max] {
            if {$max($C) < $min} {continue}

            if {$max($C) > $PgAcVar(tables,maxcolwidth)} {
                set wid $PgAcVar(tables,maxcolwidth)
            } else {
                set wid $max($C)
            }

            $Win(tableview,$PgAcVar(mw,$wn,number)) width $C $wid
        }
   
        if {$i == 100} {
            update idletasks
        }

    }

    after 500 [list resetStatus $wn $PgAcVar(mw,$wn,colcount) $PgAcVar(mw,$wn,nrecs) $rowtotal]
    set PgAcVar(mw,$wn,rowcnt) "$PgAcVar(mw,$wn,nrecs)"
    set PgAcVar(mw,$wn,colcnt) "$PgAcVar(mw,$wn,colcount)"
    set PgAcVar(mw,$wn,last_rownum) $i

    # Defining position for input data
    drawNewRecord $wn
    pg_result $pgres -clear
    sql_exec quiet "END"
    set PgAcVar(mw,$wn,toprec) 0

    if {$PgAcVar(mw,$wn,updatable)} {
	$Win(tableview,$PgAcVar(mw,$wn,number)) configure -state normal
    } else {
	$Win(tableview,$PgAcVar(mw,$wn,number)) configure -state disabled
    }
    set PgAcVar(mw,$wn,dirtyrec) 0

    catch {$wn.f1.b1 configure -state normal}
    setCursor DEFAULT

    return

}; # end proc ::Tables::selectRecords

#------------------------------------------------------------
#------------------------------------------------------------
#
proc resetStatus {wn cols_ rows_ {realrows_}} {
    
    global PgAcVar

    set PgAcVar(mw,$wn,progress) -1
    set PgAcVar(mw,$wn,msg) "attributes: $cols_"
    append PgAcVar(mw,$wn,msg) " tuples: $rows_"

    if {$rows_ != $realrows_} {
	append PgAcVar(mw,$wn,msg) " ($realrows_)"
    }

    return
}; # end proc resetStatus

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::refreshRecords {wn} {

    global PgAcVar

    if {[info exists PgAcVar(mw,$wn,$PgAcVar(mw,$wn,sortfield),sortdirection)]} {
        set sdir $PgAcVar(mw,$wn,$PgAcVar(mw,$wn,sortfield),sortdirection)
    } else {
        set sdir "desc"
    }

    set nq $PgAcVar(mw,$wn,query)
    if {($PgAcVar(mw,$wn,isaquery)) && ("$PgAcVar(mw,$wn,filter)$PgAcVar(mw,$wn,sortfield)"!="")} {
        showError [intlmsg "Sorting and Filtering not (yet) available from queries!\n\nPlease enter them in the query definition!"]
        set PgAcVar(mw,$wn,sortfield) {}
        set PgAcVar(mw,$wn,filter) {}
    } else {
        if {$PgAcVar(mw,$wn,filter)!=""} {
            set nq "$PgAcVar(mw,$wn,query) where ($PgAcVar(mw,$wn,filter))"
        } else {
            set nq $PgAcVar(mw,$wn,query)
        }
        if {$PgAcVar(mw,$wn,sortfield)!=""} {
            set nq "$nq order by \"$PgAcVar(mw,$wn,sortfield)\" "
            append nq "$sdir"
        }
    }
    if {[insertNewRecord $wn]} {selectRecords $wn $nq}

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
    #$wn.c focus $id
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

    #$wn.c insert $PgAcVar(mw,$wn,id_edited) insert [selection get]
    set PgAcVar(mw,$wn,dirtyrec) 1

}; # end proc ::Tables::canvasPaste


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Tables::getNewWindowName {} {

    global PgAcVar

    return .pgaw:[incr PgAcVar(mwcount)]

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

    global PgAcVar
    variable Win

    if {[Tables::insertNewRecord $wn]} {
        #$wn.c delete rows
        #$wn.c delete header
        #Window destroy $wn
	set c $PgAcVar(mw,$wn,number)
	#$Win(tableview,$c) delete 0 end
        #unset ::cells$c
        #unset PgAcVar(mw,$wn,records)
	wm withdraw $wn
        PgAcVar:clean mw,$wn,*
    }

    return

}; # end proc ::Tables::closeWin


#----------------------------------------------------------
# ::Tables::createWindow --
#
#    Creates a new table view window to show the contents
#    of a table or the results of a query
# 
# Arguments
#  base    the base widget path (optional)
#
# Result
#  Returns the widget base path
#
#----------------------------------------------------------
#
proc ::Tables::createWindow {{base ""}} {

    global PgAcVar

    variable Win
    variable fontmeasure

                      #set PgAcVar(mw,$wn,dirtyrec) 0
                      #set PgAcVar(mw,$wn,id_edited) {}
    set included 1
    if {$base == ""} {
        set base .pgaw:$PgAcVar(mwcount)
        set included 0

        if {[winfo exists $base]} {
            wm deiconify $base; return
        }
        toplevel $base -class TableView
          ### default is passive
                  #wm focusmodel $base passive
        wm geometry $base 650x400
                    #wm maxsize $base 1280 1024
                     #wm minsize $base 650 400
          ### default is 0
                    #wm overrideredirect $base 0
        wm deiconify $base
        wm title $base [intlmsg "Table $PgAcVar(mw,$base,tablename)"]
    }
    set wn $base
    set PgAcVar(mw,$wn,filter) {}
    set PgAcVar(mw,$wn,sortfield) {}
    set PgAcVar(mw,$wn,sortdirection) desc
    bind $base <Key-Delete> "::Tables::deleteRecord $wn"
    bind $base <Key-F1> "Help::load tables"
 
    if {! $included} {
        frame $base.f1  \
            -borderwidth 1

        label $base.f1.l1  -borderwidth 0 -text [intlmsg {Sort field}]

        set Win(sortfield) [ComboBox $base.f1.e1 \
            -editable 0 \
            -borderwidth 1 \
            -width 14  \
            -modifycmd [list Tables::refreshRecords $wn] \
            -textvariable PgAcVar(mw,$wn,sortfield)]

        $base.f1.e1 bind <Key-Return>   [list Tables::refreshRecords $wn]
        $base.f1.e1 bind <Key-KP_Enter> [list Tables::refreshRecords $wn]
        label $base.f1.l2  \
            -text [intlmsg {Filter conditions}]
        entry $base.f1.e2  \
            -textvariable PgAcVar(mw,$wn,filter)

        bind $base.f1.e2 <Key-Return> "Tables::refreshRecords $wn"    
        bind $base.f1.e2 <Key-KP_Enter> "Tables::refreshRecords $wn"    

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
    frame $base.bottomfm  -borderwidth 1 -height 75

    Button $base.bottomfm.01  \
        -borderwidth 1 \
        -image ::icon::back-22 \
        -relief link \
        -helptext "Prev Page" \
        -command "Tables::panRight $wn"

    label $base.bottomfm.02  \
	-anchor w \
	-borderwidth 1 \
	-height 1  \
	-relief flat \
	-foreground #225588 \
	-text {} \
	-textvariable PgAcVar(mw,$wn,msg) 

    label $base.bottomfm.04  \
	-anchor w \
	-width 6 \
	-borderwidth 1 \
	-height 1  \
	-relief flat \
	-textvariable PgAcVar(mw,$wn,rowcnt) 

    label $base.bottomfm.06  \
	-anchor w \
	-width 6 \
	-borderwidth 1 \
	-height 1  \
	-relief flat \
	-textvariable PgAcVar(mw,$wn,colcnt) 

    set Win(mw,$wn,progress) [label $base.bottomfm.05 \
        -font {Helvetica 12 bold} \
        -anchor w \
        -highlightthickness 0 \
        -text "" \
        -background [shade  [. cget -background] #444444 .5] \
        -foreground blue \
        -relief sunken \
        -width 25 \
        -bd 1]
       

    bind $Win(mw,$wn,progress) <Enter> {break}
    bind $Win(mw,$wn,progress) <Leave> {break}
    bind $Win(mw,$wn,progress) <Motion> {break}
    bind $Win(mw,$wn,progress) <1> {break}
    bind $Win(mw,$wn,progress) <ButtonRelease-1> {break}

    Button $base.bottomfm.03 \
            -borderwidth 1 \
            -image ::icon::forward-22 \
            -relief link \
            -helptext "Next Page" \
            -command "Tables::panLeft $wn"

    if {$PgAcVar(pref,tvfont)=="helv"} {
	set tvfont $PgAcVar(pref,font_normal)
    } else {
	set tvfont $PgAcVar(pref,font_fix)
    }

    set Win(tableview,$PgAcVar(mwcount)) [table $base.c \
        -usecommand 1 \
        -bd 0 \
	-padx 2 \
	-pady 2 \
	-wrap 0 \
	-font {Helvetica 11} \
	-multiline 1 \
        -height 1 \
        -drawmode compatible \
        -rows 30 \
        -colorigin 0 \
        -roworigin 0 \
	-highlightthickness 0 \
	-colstretchmode unset \
	-background white \
	-borderwidth 1 \
        -rowtagcommand colorize \
        -coltagcommand colConfig \
        -titlerows 1 \
        -titlecols 1 \
        -insertofftime 0 \
        -yscrollcommand [list $base.vsb set] \
        -xscrollcommand [list $base.hsb set] \
        -variable cells$PgAcVar(mwcount) \
        -browsecommand [list ::Tables::updateRecord $wn %W %i %s %S]
    ]


    ##  %c = column of new cell
    ##  %C = %r,%c
    ##  %i = cursor position
    ##  %r = row of new cell
    ##  %s = index of last active cell
    ##  %S = index of new active cell
    ##  %W = window path

puts "HEIGHT: [$Win(tableview,$PgAcVar(mwcount)) cget -height]"
    ## drawmode????

    bindtags $Win(tableview,$PgAcVar(mwcount)) [linsert [bindtags $Win(tableview,$PgAcVar(mwcount))] end PostTable]
    #bind PostTable <1> [list embedWindow $tab_ $Win(mclist,$tab_) %W]
    #bind PostTable <Return> [list ::Tables::updateRecord $wn %W %S %c %r %C %i %s %S %W]
    bind PostTable <Return> [list ::Tables::updateRecord $wn %W %i %s %S]

    $Win(tableview,$PgAcVar(mwcount)) width 0 5

    set cellvar cells$PgAcVar(mwcount)

    set baseclr [$base cget -background]
    $Win(tableview,$PgAcVar(mwcount)) tag config colored \
        -bg [shade $baseclr #FFFFFF .7]
    $Win(tableview,$PgAcVar(mwcount)) tag config title \
        -font $PgAcVar(pref,font_normal) -bg $baseclr -bd 1 -relief raised -fg black
    $Win(tableview,$PgAcVar(mwcount)) tag config left -anchor w
    $Win(tableview,$PgAcVar(mwcount)) tag config right -anchor e
    $Win(tableview,$PgAcVar(mwcount)) tag config negative -fg red
    $Win(tableview,$PgAcVar(mwcount)) tag config active -borderwidth 2 -relief ridge

    scrollbar $base.vsb  \
	-orient vert \
	-command [list $Win(tableview,$PgAcVar(mwcount)) yview]

    scrollbar $base.hsb  \
	-orient horizontal \
	-command [list $Win(tableview,$PgAcVar(mwcount)) xview]

    set row 0
    if {! $included} {
        incr row

        grid $base.f1 \
            -sticky ew \
            -columnspan 2

        pack $base.f1.l1 -side left -padx 4
        pack $base.f1.e1 -side left -padx 4
        pack $base.f1.l2 -side left -padx 4
        pack $base.f1.e2 -side left -padx 4
        pack $base.f1.b3 -side right
        pack $base.f1.b1 -side right
        pack $base.f1.b2 -side right
    }

    grid $base.c \
        -sticky news \
        -row $row \
        -column 0

    grid $base.vsb \
        -sticky ns \
        -row $row \
        -column 1

    grid $base.hsb \
        -sticky ew \
        -column 0 \
        -row [expr {$row + 1}]

    grid $base.bottomfm \
        -sticky ew \
        -columnspan 2 \
        -row [expr {$row + 2}]

    grid columnconfigure $base 0 -weight 1
    grid rowconfigure $base 1 -weight 1

    pack $base.bottomfm.01  -side left -padx 4
    pack $base.bottomfm.02  -expand 1 -fill x -side left -padx 4
    pack $base.bottomfm.03  -side right -padx 4

    return $wn

}; # end proc ::Tables::createWindow

##
##
##
proc colorize {num} {
    #if {$num == 1} {return totals}
    if {$num>0 && ($num%2 != 1)} { return colored }
}


##
##
##
proc colConfig {num} {

    if {$num >= 2} {return right}

    return right
}; # end proc colConfig



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
          FROM pg_index,pg_class
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
    if {($i!="")&&($i<[expr {[.pgaw:NewTable.lb size]-1]})} {
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

        entry $titleframe.v$name \
            -textvariable PgAcVar(tblinfo,$name) \
            -bd 1 \
            -justify left \
            -state disabled \
            -width 30

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

        entry $titleframe.v$name \
            -textvariable PgAcVar(tblinfo,$name) \
            -bd 1 \
            -justify left \
            -state disabled \
            -width 30

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
        -padx 9 -pady 3 -text [intlmsg Close]
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




                 #proc ::Tables::updateRecord {id_ wn_ row_ col_ newval_} 
#----------------------------------------------------------
##  %c = column of new cell
##  %C = %r,%c
##  %i = cursor position
##  %r = row of new cell
##  %s = index of last active cell
##  %S = index of new active cell
##  %W = window path
#----------------------------------------------------------
#
                             #$wn %W   %c %r %C %i %s %S
proc ::Tables::updateRecord {id_ win_ cursor_ last_idx_ new_idx_} {

    variable oldvalue

    ##
    ##  We need to remember the value of the cell that was
    ##  previously active. Then when we move to a new cell
    ##  we check the old value with what is there now for
    ##  the previous cell. If it is different, than we know
    ##  that we need to update that record. Regardless,
    ##  whenever a new cell is active, we remember that
    ##  value for the subsequent calls to this proc
    ##
    ##  So, if oldvalue for last_idx_ exists, then we know
    ##  that there was a previous active cell that may have
    ##  been modified. We then get the value of the *last*
    ##  cell as it is now (newvalue). We compare what is 
    ##  there now, from when the previous cell was first
    ##  entered. If different, then update.
    ##
    if {[info exists oldvalue($id_,$last_idx_)]} {
        set newvalue [$win_ get $last_idx_]

        puts "OLD: $oldvalue($id_,$last_idx_) NEW: $newvalue"

        if {![string equal "$newvalue" $oldvalue($id_,$last_idx_)]} {

        foreach {row col} [split $last_idx_ ,] break
    
        set ncols [llength $::PgAcVar(mw,$id_,colnames)]

        set where [list]
puts "KEYLIST: $::PgAcVar(mw,$id_,keylist)"
        set keyvalues [lindex $::PgAcVar(mw,$id_,keylist) [expr {$row - 1}]]
        foreach K $::PgAcVar(mw,$id_,ukey) V $keyvalues {
            lappend where $K='$V'
        }
    
        #set newval [$win_ get $last_idx_]
        set attr [lindex $::PgAcVar(mw,$id_,colshown) [expr {$col - 1}]]
        puts "UPDATE [::Database::quoteObject $::PgAcVar(mw,$id_,tablename)] 
             SET $attr = '$newvalue' 
           WHERE [join $where " AND "]"
        }

        unset oldvalue($id_,$last_idx_)
    }
    
    ##
    ##  We remember this for when the next cell is entered
    ##  so we can check to see if it changed between now,
    ##  and when the next cell is active (see above)
    ##
    set oldvalue($id_,$new_idx_) [$win_ get $new_idx_]
    

foreach V {id_ win_ cursor_ last_idx_ new_idx_} {
   puts "[string toupper $V]: [set $V]"
}
if {[info exists oldvalue($id_,$last_idx_)]} {
puts "OLdVALUE LAST: $oldvalue($id_,$last_idx_)"
}
puts "OLdVALUE NEW: $oldvalue($id_,$new_idx_)"
if {[info exists newvalue]} {
    puts "NEWVALUE: $newvalue"
}

                               #puts "$id_ $win_ $cell_"

###    foreach {row col} [split $new_idx_ ,] break
###
###    set ncols [llength $::PgAcVar(mw,$id_,colnames)]
###
###   #puts "CURRV: [$win_ curvalue $cell_]"
###   puts "VAL: [$win_ get $new_idx_ $row,$ncols]"
###
###    #set colvalues [$wn_ get $row_]
###    #set colvalues [$wn_ get $row_]
###
###    #set attr [lindex [$wn_ cget -columns] [expr {$col_ * 3 + 1}]]
###    set newval [$win_ get $new_idx_]
###    set attr [lindex $::PgAcVar(mw,$id_,colshown) [expr {$col - 1}]]
###    puts "UPDATE [::Database::quoteObject $::PgAcVar(mw,$id_,tablename)] 
###         SET $attr = '$newval' 
###       WHERE $::PgAcVar(mw,$id_,ukey) = '[lindex $::PgAcVar(mw,$id_,keylist) $row]'"

    return
}

