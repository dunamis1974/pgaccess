#==========================================================
# Database --
#
#   provides a layer of abstraction for common DB operations
#
#==========================================================
#
namespace eval Database {

    variable Sql

    set Sql(schema,uniqueKeys) "
        SELECT I.indisprimary, I.indkey
	  FROM Pg_index I, Pg_class C, Pg_namespace N
	 WHERE I.indisunique='t' 
	   AND I.indrelid=C.oid 
           AND C.relname='%TABLE%'
           AND N.nspname='%NAMESPACE%'
           AND C.relnamespace=N.oid"

    set Sql(schema,hasoids) "
         SELECT relhasoids
           FROM Pg_class C, Pg_namespace N
          WHERE relname='%TABLE%'
            AND N.nspname='%NAMESPACE%'
            AND C.relnamespace=N.oid"

    set Sql(schema,attrname) "
        SELECT attname
          FROM Pg_attribute, Pg_class C, Pg_namespace N
         WHERE attnum IN (%ATTNUM%)
           AND attrelid=C.oid
           AND C.relname='%TABLE%'
           AND N.nspname='%NAMESPACE%'
           AND C.relnamespace=N.oid"

    set Sql(uniqueKeys) "
        SELECT I.indisprimary, I.indkey
	  FROM Pg_index I, Pg_class C
	 WHERE I.indisunique='t' 
	   AND I.indrelid=C.oid 
           AND C.relname='%TABLE%'"

    set Sql(hasoids) "
         SELECT relhasoids
           FROM Pg_class C
          WHERE relname='%TABLE%'"

    set Sql(attrname) "
        SELECT attname
          FROM Pg_attribute, Pg_class C
         WHERE attnum IN (%ATTNUM%)
           AND attrelid=C.oid
           AND C.relname='%TABLE%'"
}


#----------------------------------------------------------
# getPrefObjList --
#
#   returns objects with respect to user preferences
#
# Arguments:
#   obj_    an object, either from PG or PGA
#   dbh_    an optional database handle
#   full_   optional, 1 to return all columns not just name
#   schema_ optional, 1 to return dot separating schema name
#
# Returns:
#   olist   either a list of names, or a list of lists
#----------------------------------------------------------
#
proc ::Database::getPrefObjList {obj_ {dbh_ ""} {full_ 0} {schema_ 0}} {

    global PgAcVar
    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set pg $PgAcVar(pref,systemtables)
    set pga $PgAcVar(pref,pgaccesstables)

    return [::Database::getObjectsList $obj_ $dbh_ $full_ $schema_ $pg $pga]

}; # end proc ::Database::getPrefObjList


#----------------------------------------------------------
# getObjectsList --
#
#   returns a list of names of items of a particular object
#   type, or a list of all the columns of each item
#
# Arguments:
#   obj_    an object, either from PG or PGA
#   dbh_    an optional database handle
#   full_   optional, 1 to return all columns not just name
#   schema_ optional, 1 to return dot separating schema name
#   pg_     optional, 1 to show PG system objects (tables,views)
#   pga_    optional, 1 to show PGA system objects (tables)
#
# Returns:
#   olist   either a list of names, or a list of lists
#----------------------------------------------------------
#
proc ::Database::getObjectsList {obj_ {dbh_ ""} {full_ 0} {schema_ 0} {pg_ 0} {pga_ 0}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set olist [list]

    if {$obj_ == "Tables"} {
        set olist [::Database::getTablesList $dbh_ $pg_ $pga_]
    } elseif {$obj_ == "Views"} {
        set olist [::Database::getViewsList $dbh_ $pg_]
    } elseif {$obj_ == "Functions"} {
        set olist [::Database::getFunctionsList $dbh_ $pg_]
    } elseif {$obj_ == "Sequences"} {
        set olist [::Database::getSequencesList $dbh_ $pg_]
    } elseif {$obj_ == "Databases"} {
        set olist [::Database::getDatabasesList $dbh_ $pg_]
    } elseif {$obj_ == "Schemas"} {
        set olist [::Database::getSchemasList $dbh_ $pg_]
    } elseif {$obj_ == "Languages"} {
        set olist [::Database::getLanguagesList $dbh_ $pg_]
    } elseif {$obj_ == "Types"} {
        set olist [::Database::getTypesList $dbh_ $pg_]
    } elseif {$obj_ == "Domains"} {
        set olist [::Database::getTypesList $dbh_ $pg_ 0 0 "d" 0]
    } elseif {$obj_ == "Triggers"} {
        set olist [::Database::getTriggersList $dbh_ $pg_]
    } elseif {$obj_ == "Indexes"} {
        set olist [::Database::getIndexesList $dbh_ $pg_]
    } elseif {$obj_ == "Rules"} {
        set olist [::Database::getRulesList $dbh_ $pg_]
    } elseif {$obj_ == "Aggregates"} {
        set olist [::Database::getAggregatesList $dbh_ $pg_]
    } elseif {$obj_ == "Conversions"} {
        set olist [::Database::getConversionsList $dbh_ $pg_]
    } elseif {$obj_ == "Casts"} {
        set olist [::Database::getCastsList $dbh_ $pg_]
    } elseif {$obj_ == "Operators"} {
        set olist [::Database::getOperatorsList $dbh_ $pg_]
    } elseif {$obj_ == "OperatorClasses"} {
        set olist [::Database::getOperatorClassesList $dbh_ $pg_]
    } else {
        set sql "
            SELECT *
              FROM pga_$obj_"
        wpg_select $dbh_ $sql rec {
            if {$full_} {
                set clist [list]
                foreach col $rec(.headers) {
                    lappend clist $rec($col)
                }
                lappend olist $clist
            } else {
                lappend olist $rec([lindex $rec(.headers) 0])
            }
        }
    }

    set nlist [list]

    if {$schema_} {
        set nlist $olist
    } else {
        foreach o $olist {
            set splito [split $o .]
            if {[llength $splito] > 1} {
                set n [lindex [lrange [split $o .] 1 end] 0]
                regsub -all {\"} $n {} on
                lappend nlist $on
            } else {
                lappend nlist $o
            }
        }
    }

    return $nlist

}; # end proc ::Database::getObjectsList


#----------------------------------------------------------
# ::Database::getPermissionsAsGrants --
#
#   retrieve the permissions on a PG object
#   as a series of GRANTs
#
# Arguments:
#   dbh_    an optional database handle
#   obj_    a PG object to return perms for
#   type_   the type of a PG object to return perms for
#
# Returns:
#   grants  a bunch of GRANT statements for the object
#----------------------------------------------------------
#
proc ::Database::getPermissionsAsGrants {{dbh_ ""} {obj_ ""} {type_ ""}} {

    set allabbrs [list "r" "w" "a" "d" "R" "x" "t" "X" "U" "T" "C"]
    set allperms [list "SELECT" "UPDATE" "INSERT" "DELETE" "RULE" "REFERENCES" "TRIGGER" "EXECUTE" "USAGE" "TEMPORARY" "CREATE"]

    set grants [list]

    foreach g [split [getPermissions $dbh_ $obj_ $type_] ','] {
        set usergroup [string trim [lindex [split $g '='] 0] \"]
        if {[string length $usergroup]==0} {
            set usergroup "PUBLIC"
        }
        set creator [lindex [split [lindex [split $g '='] 1] '/'] 1]
        if {![string match $creator $usergroup]} {
            set perms [lindex [split [lindex [split $g '='] 1] '/'] 0]
            foreach ap $allperms aa $allabbrs {
                set permpos [string first $aa $perms]
                if {$permpos != -1} {
                    set perm [lindex $allperms [lsearch $allabbrs $aa]]
                    set star [string index $perms [expr {$permpos+1}]]
                    if {[string match {\*} $star]} {
                        set opt "WITH GRANT OPTION"
                    } else {
                        set opt ""
                    }
                    lappend grants "GRANT $perm ON $obj_ TO $usergroup $opt;"
                }
            }
        }
    }

    return $grants

}; # end proc ::Database::getPermissionsAsGrants


#----------------------------------------------------------
# ::Database::getPermissions --
#
#   retrieve the acl list on a PG object
#
# Arguments:
#   dbh_    an optional database handle
#   obj_    a PG object to return perms for
#   type_   the type of a PG object to return perms for
#
# Returns:
#   acl     a string of permissions
#----------------------------------------------------------
#
proc ::Database::getPermissions {{dbh_ ""} {obj_ ""} {type_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    #set V  $::Connections::Conn(pgversion,$id)
    set V [getPgVersion $dbh_]

    set acl ""
    set sql ""

    if {$V < 7.3} {
        set sql "
            SELECT relacl
              FROM pg_class
             WHERE relname='[string trim $obj_ \"]'"
    } else {
        if { [string match $type_ "function"] } {
            set obj_ [string range $obj_ 0 [expr {[string first ( $obj_]-1}]]
            set schema [string range $obj_ 0 [expr {[string first . $obj_]-1}]]
            set funk [string range $obj_ [expr {[string length $schema]+1}] end]
            set sql "
                SELECT proacl
                  FROM pg_catalog.pg_namespace N, pg_catalog.pg_proc P
                 WHERE P.proname='$funk'
                   AND N.nspname='$schema'
                   AND P.pronamespace=N.oid"
        } elseif { [string match $type_ "database"] } {
            set sql "
                SELECT datacl
                  FROM pg_catalog.pg_database D
                 WHERE D.datname='$obj_'"
        } elseif { [string match $type_ "schema"] } {
            set sql "
                SELECT nspacl
                  FROM pg_catalog.pg_namespace N
                 WHERE N.nspname='$obj_'"
        } elseif { [string match $type_ "language"] } {
            set sql "
                SELECT lanacl
                  FROM pg_catalog.pg_language L
                 WHERE L.lanname='$obj_'"
        } else {
            set sql "
                SELECT relacl
                  FROM pg_catalog.pg_attribute A, pg_catalog.pg_class C
                 WHERE A.attrelid='$obj_'::regclass
                   AND A.attrelid=C.oid"
        }
    }

    set res [wpg_exec $dbh_ $sql]
    if {[pg_result $res -numTuples] > 0} {
        set acl [join [join [pg_result $res -getTuple 0]]]
    } else {
        # default the acl to nothing if there isnt one, just in case
        set acl "=,"
    }
    pg_result $res -clear

    return $acl

}; # ::Database::getPermissions


#----------------------------------------------------------
# getTableIndexes --
#
#   returns a list index names in a table
#
# Arguments:
#   table_  name of a view or table (required)
#   dbh_    the db handle (optional)
#
# Results:
#   list of names of the indexes on the table
#----------------------------------------------------------
#
proc ::Database::getTableIndexes {table_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    #set V  $::Connections::Conn(pgversion,$id)
    set V [getPgVersion $dbh_]

    if {$V < 7.3} {

        set sql "
            SELECT relname
              FROM pg_class
             WHERE oid IN (
            SELECT indexrelid
              FROM pg_index I, pg_class C
             WHERE (C.relname='$table_')
               AND (C.oid=I.indrelid))"

    } else {

        set sql "
            SELECT relname
              FROM pg_catalog.pg_class
             WHERE oid IN (
            SELECT indexrelid
              FROM pg_catalog.pg_attribute A, pg_catalog.pg_index I
             WHERE (A.attrelid='$table_'::regclass)
               AND (A.attrelid=I.indrelid))"

    }

    set tilist {}

    if {[catch {
        wpg_select $dbh_ $sql rec {
            lappend tilist [::Database::quoteObject $rec(relname)]
        }
    } gterrmsg]} {
        showError $gterrmsg
    }

    return $tilist

}; # end proc ::Database::getTableIndexes


#----------------------------------------------------------
# getTableInfo --
#
#   returns a list (from an array) of info on a table
#
# Arguments:
#   table_  name of a view or table (required)
#   dbh_    the db handle (optional)
#
# Results:
#   a list of name-value array pairs of table info columns
#----------------------------------------------------------
#
proc ::Database::getTableInfo {table_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    #set V  $::Connections::Conn(pgversion,$id)
    set V [getPgVersion $dbh_]

    if {$V < 7.3} {

        set sql "
            SELECT attnum,attname,typname,attlen,attnotnull,atttypmod,
                   usename,usesysid,C.oid,relpages,reltuples,
                   relhaspkey,relhasrules,relacl
              FROM pg_user U, pg_attribute A,
                   pg_type T, pg_class C
             WHERE (C.relname='$table_')
               AND (C.oid=A.attrelid)
               AND (C.relowner=U.usesysid)
               AND (A.atttypid=T.oid)
          ORDER BY A.attnum"

    } else {

        set sql "
            SELECT attnum,attname,typname,attlen,attnotnull,atttypmod,
                   usename,usesysid,C.oid,relpages,reltuples,
                   relhaspkey,relhasrules,relacl
              FROM pg_catalog.pg_user U, pg_catalog.pg_attribute A,
                   pg_catalog.pg_type T, pg_catalog.pg_class C
             WHERE (A.attrelid='$table_'::regclass)
               AND (A.atttypid=T.oid)
               AND (A.attrelid=C.oid)
               AND (C.relowner=U.usesysid)
          ORDER BY A.attnum"

    }

    set tlist {}

    if {[catch {
        wpg_select $dbh_ $sql rec {
            lappend tlist [array get rec]
        }
    } gterrmsg]} {
        showError $gterrmsg
    }

    return $tlist

}; # end proc ::Database::getTableInfo


#----------------------------------------------------------
# getColumnsTypesList --
#
#   returns a list of names of columns and their types
#   in a given view or table
#
# Arguments:
#   table_   name of a view or table (required)
#   dbh_    the db handle (optional)
#
# Results:
#   a list of pairs of column names and types
#----------------------------------------------------------
#
proc ::Database::getColumnsTypesList {table_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    #set V  $::Connections::Conn(pgversion,$id)
    set V [getPgVersion $dbh_]

    if {$V < 7.3} {

        set sql "
            SELECT A.attname, count(A.attname), T.typname
              FROM pg_class C, pg_attribute A, pg_type T
             WHERE (C.relname='[string trim $table_ \"]')
               AND (C.oid=A.attrelid)
               AND (A.attnum>0)
               AND (A.atttypid=T.oid)
          GROUP BY A.attname, A.attnum, T.typname
          ORDER BY A.attnum"

    } else {

        set sql "
            SELECT A.attname, count(A.attname), T.typname
              FROM pg_catalog.pg_attribute A, pg_catalog.pg_type T
             WHERE (A.attrelid='[string trim $table_ \"]'::regclass)
               AND (A.attnum>0)
               AND (A.atttypid=T.oid)
          GROUP BY A.attname, A.attnum, T.typname
          ORDER BY A.attnum"

    }

    set ctlist {}

    if {[catch {
        wpg_select $dbh_ $sql rec {
            if {[info exists rec(count)] && $rec(count)!=0} {
                lappend ctlist [list $rec(attname) $rec(typname)]
            }
        }
    } gterrmsg]} {
        showError $gterrmsg
    }

    return $ctlist

}; # end proc ::Database::getColumnsTypesList


#----------------------------------------------------------
# getColumnsList --
#
#   returns a list of names of columns in a given view or table
#
# Arguments:
#   table_   name of a view or table (required)
#   dbh_    the db handle (optional)
#
# Results:
#   a list of column names
#----------------------------------------------------------
#
proc ::Database::getColumnsList {table_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    #set V  $::Connections::Conn(pgversion,$id)
    set V [getPgVersion $dbh_]

    if {$V < 7.3} {

        set sql "
            SELECT A.attname, count(A.attname)
              FROM pg_class C, pg_attribute A
             WHERE (C.relname='[string trim $table_ \"]')
               AND (C.oid=A.attrelid)
               AND (A.attnum>0)
          GROUP BY A.attname, A.attnum
          ORDER BY A.attnum"

    } else {

        set sql "
            SELECT A.attname, count(A.attname)
              FROM pg_catalog.pg_attribute A
             WHERE (A.attrelid='$table_'::regclass)
               AND (A.attnum>0)
          GROUP BY A.attname, A.attnum
          ORDER BY A.attnum"

    }

    set clist {}

    if {[catch {
        wpg_select $dbh_ $sql rec {
            if {[info exists rec(count)] && $rec(count)!=0} {
                lappend clist $rec(attname)
            }
        }
    } gterrmsg]} {
        showError $gterrmsg
    }

    return $clist

}; # end proc ::Database::getColumnsList


#----------------------------------------------------------
# getViewsList --
#
#   returns a list of views in the currentdb
#
# Arguments:
#    dbh_    optionally supply the db handle
#    pg_     whether or not to show the PG internal views
#    mw_     whether to grab extra info for the main window
#    sqlout_ whether to return the SQL created to list the views
#
# Results:
#    a list of view names; unless $sqlout_ is 1, in which case the SQL
#    to return a list of view names will be returned instead
#----------------------------------------------------------
#
proc ::Database::getViewsList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    if {$V < 7.3} {

        if {$mw_} {
            set sql "
                SELECT c.relname, u.usename, c.relfilenode, c.relnatts
                  FROM [::Database::qualifySysTable pg_class $dbh_] c
             LEFT JOIN [::Database::qualifySysTable pg_user $dbh_] u
                    ON c.relowner = u.usesysid,
                       [::Database::qualifySysTable pg_rewrite $dbh_] r
                 WHERE (r.ev_class = c.oid)
                   AND (r.ev_type = '1')"
        } else {
            set sql "
                SELECT c.relname
                  FROM pg_class c, pg_rewrite r
                 WHERE (r.ev_class = c.oid)
                   AND (r.ev_type = '1')"
        }

        if {!$pg_} {
            append sql " AND relname !~ '^pg_'"
        }

        append sql " ORDER BY relname"

    } elseif {$V >= 7.3 && $V < 7.4} {

        if {$mw_} {
            set sql "
                SELECT v.schemaname || '.' || v.viewname AS relname,
                       v.schemaname, v.viewname,
                       v.viewowner AS usename, c.relfilenode, c.relnatts
                  FROM pg_catalog.pg_views v,
                       pg_catalog.pg_class c,
                       pg_catalog.pg_rewrite r,
                       pg_catalog.pg_namespace n
                 WHERE r.ev_class = c.oid
                   AND n.oid = c.relnamespace
                   AND c.relname = v.viewname
                   AND r.ev_type = '1'"
        } else {
            set sql "
                SELECT v.schemaname || '.' || v.viewname AS relname
                  FROM pg_catalog.pg_views v
                 WHERE viewname!=''"
        }

        if {!$pg_} {
            append sql " AND relname !~ '^pg_'"
        }

        append sql " ORDER BY relname"

    } else {

        if {$mw_} {
            set sql "
                SELECT v.schemaname || '.' || v.viewname AS relname,
                       v.schemaname, v.viewname,
                       v.viewowner AS usename, c.relfilenode, c.relnatts
                  FROM pg_catalog.pg_views v,
                       pg_catalog.pg_class c,
                       pg_catalog.pg_rewrite r,
                       pg_catalog.pg_namespace n
                 WHERE r.ev_class = c.oid
                   AND n.oid = c.relnamespace
                   AND c.relname = v.viewname
                   AND r.ev_type = '1'"
        } else {
            set sql "
                SELECT v.schemaname || '.' || v.viewname AS relname
                  FROM pg_catalog.pg_views v
                 WHERE viewname!=''"
        }

        if {!$pg_} {
            append sql " AND v.schemaname != 'pg_catalog'"
            append sql " AND v.schemaname != 'information_schema'"
        }

        append sql " ORDER BY relname"

    }

    if {$sqlout_} {return $sql}

    set vlist {}

    if {[catch {
        wpg_select $dbh_ $sql rec {
            if {[info exists rec(relname)]} {
                lappend vlist [::Database::quoteObject $rec(relname)]
            }
        }
    } gterrmsg]} {
        showError $gterrmsg
    }

    return $vlist

}; # end proc ::Database::getViewsList


#----------------------------------------------------------
# getSequencesList --
#
#   returns a list of sequences in the currentdb
#
# Argumens:
#   dbh_    optionally supply the db handle
#
# Returns:
#   a list of sequence names
#----------------------------------------------------------
#
proc ::Database::getSequencesList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global PgAcVar CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    if {$V<7.3} {
        if {$mw_} {
            set sql "
                SELECT c.relname, u.usename, c.relfilenode
                  FROM [::Database::qualifySysTable pg_class $dbh_] c
             LEFT JOIN pg_user u ON c.relowner = u.usesysid
                 WHERE (relkind ='S')"
        } else {
            set sql "
                SELECT c.relname
                  FROM [::Database::qualifySysTable pg_class $dbh_] c
             LEFT JOIN pg_user u ON c.relowner = u.usesysid
                 WHERE (relkind ='S')"
        }
    } else {
        if {$mw_} {
            set sql "
                SELECT n.nspname, c.relname, u.usename, c.relfilenode
                  FROM pg_catalog.pg_namespace n,
                       pg_catalog.pg_class c
             LEFT JOIN pg_user u ON c.relowner = u.usesysid
                 WHERE (relkind ='S')
                   AND n.oid=c.relnamespace"
        } else {
            set sql "
                SELECT n.nspname || '.' || c.relname AS relname
                  FROM pg_catalog.pg_namespace n,
                       pg_catalog.pg_class c
             LEFT JOIN pg_user u ON c.relowner = u.usesysid
                 WHERE (relkind ='S')
                   AND n.oid=c.relnamespace"
        }
    }

    if {$pg_} {
        append sql " AND (relname NOT LIKE 'pg_%')"
    }

    append sql " ORDER BY relname"

    if {$sqlout_} {return $sql}

    setCursor CLOCK

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(relname)]
            }

    } err]} {
        showError $err
    }

    setCursor DEFAULT

    return $tlist

}; # end proc ::Database::getSequencesList


#----------------------------------------------------------
# getFunctionsList --
#
#   returns a list of functions in the currentdb
#
# Argumens:
#   dbh_    optionally supply the db handle
#   pg_     whether to show the PG system objects
#   mw_     whether to grab extra info for the main window
#   sqlout_ whether to return the SQL created to list the functions
#
# Returns:
#   a list of function names
#----------------------------------------------------------
#
proc ::Database::getFunctionsList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global PgAcVar CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set maxim 16384
    setCursor CLOCK
    set dbname $PgAcVar(opendb,dbname)

    set sql "
        SELECT datlastsysoid 
          FROM [::Database::qualifySysTable pg_database $dbh_]
         WHERE datname='$dbname'"

    set sql2 "
        SELECT oid 
          FROM [::Database::qualifySysTable pg_database $dbh_]
         WHERE datname='template1'"

    if [catch {wpg_select $dbh_ "$sql" rec {
        set maxim $rec(datlastsysoid)
    }
    }] {
    catch {
        wpg_select $dbh_ "$sql2" rec {
            set maxim $rec(oid)
        }
    }
    }

    if {$V < 7.3} {
        if {$mw_} {
            set sql3 "
                SELECT prorettype, u.usename, l.lanname,
                       (proname || '(' || oidvectortypes(proargtypes) || ')')
                       AS proname
                  FROM [::Database::qualifySysTable pg_proc $dbh_] p
             LEFT JOIN [::Database::qualifySysTable pg_user $dbh_] u
                    ON p.proowner = u.usesysid,
                       [::Database::qualifySysTable pg_language $dbh_] l
                 WHERE p.oid>$maxim
                   AND p.prolang = l.oid"
        } else {
            set sql3 "
                SELECT (proname || '(' || oidvectortypes(proargtypes) || ')')
                       AS proname
                  FROM [::Database::qualifySysTable pg_proc $dbh_] p
             LEFT JOIN [::Database::qualifySysTable pg_user $dbh_] u
                    ON p.proowner = u.usesysid,
                       [::Database::qualifySysTable pg_language $dbh_] l
                 WHERE p.oid>$maxim
                   AND p.prolang = l.oid"
        }
    } else {
        if {$mw_} {
            set sql3 "
                SELECT n.nspname, prorettype, u.usename, l.lanname,
                       (proname || '(' || oidvectortypes(proargtypes) || ')')
                       AS proname
                  FROM pg_catalog.pg_namespace n,
                       pg_catalog.pg_language l,
                       pg_catalog.pg_proc p
             LEFT JOIN pg_catalog.pg_user u
                    ON p.proowner = u.usesysid
                 WHERE p.oid>$maxim
                   AND p.prolang=l.oid
                   AND p.pronamespace=n.oid"
        } else {
            set sql3 "
                SELECT (n.nspname || '.' || proname || '(' || oidvectortypes(proargtypes) || ')')
                       AS proname
                  FROM pg_catalog.pg_namespace n,
                       pg_catalog.pg_language l,
                       pg_catalog.pg_proc p
             LEFT JOIN pg_catalog.pg_user u
                    ON p.proowner = u.usesysid
                 WHERE p.oid>$maxim
                   AND p.prolang=l.oid
                   AND p.pronamespace=n.oid"
        }
        if {!$pg_} {
            append sql3 "
                   AND n.nspname != 'pg_catalog'
                   AND n.nspname != 'information_schema'"
        }
    }
    append sql3 " ORDER BY proname"

    if {$sqlout_} {return $sql3}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql3" rec {
                lappend tlist [::Database::quoteObject $rec(proname)]
            }

    } err]} {
        showError $err
    }

    setCursor DEFAULT

    return $tlist

}; # end proc ::Database::getFunctionsList


#------------------------------------------------------------
# getTablesList --
#
#    returns a list of tables in the currentdb
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show the PG system objects
#    pga_       whether to show the PGA system objects
#    mw_        whether to grab extra info for the main window
#    sqlout_    whether to return the SQL created to list the tables
#
# Results:
#    a list of table names; unless $sqlout_ is 1, in which case the SQL
#    to return a list of table names will be returned instead
#------------------------------------------------------------
#
proc ::Database::getTablesList {{dbh_ ""} {pg_ 0} {pga_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg_ $PgAcVar(pref,systemtables)

    if {![info exists ::Connections::Conn(viewpgaccess,$id)]} {
        set ::Connections::Conn(viewpgaccess,$id) $PgAcVar(pref,pgaccesstables)
    }
    set pga_ $PgAcVar(pref,pgaccesstables)

    if {$V < 7.3} {

        if {$mw_} {
            set sql "
                SELECT c.relname, u.usename, c.relfilenode, c.reltuples,
                       c.relnatts
                  FROM pg_class c
             LEFT JOIN pg_user u ON c.relowner = u.usesysid
                 WHERE c.relkind = 'r'"
        } else {
            set sql "
                SELECT c.relname AS table
                  FROM pg_class c
                 WHERE c.relkind = 'r'"
        }

        if {!$pg_} {
            append sql " AND c.relname !~ '^pg_'"
        }

        if {!$pga_} {
           append sql " AND c.relname !~ '^pga_'"
        }

    } elseif {$V >= 7.3 && $V < 7.4} {

        if {$mw_} {
            set sql "
                SELECT n.nspname, c.relname, u.usename, c.relfilenode,
                       c.reltuples, c.relnatts
                  FROM pg_catalog.pg_class c
             LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
             LEFT JOIN pg_catalog.pg_user u ON c.relowner = u.usesysid
                 WHERE c.relkind = 'r'"
        } else {
            set sql "
                SELECT n.nspname || '.' || c.relname AS table
                  FROM pg_catalog.pg_class c
             LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                 WHERE c.relkind = 'r'"
        }

        if {!$pg_} {
            append sql " AND c.relname !~ '^pg_'"
        }

        if {!$pga_} {
            append sql " AND c.relname !~ '^pga_'"
        }

    } else {

        if {$mw_} {
            set sql "
                SELECT n.nspname, c.relname, u.usename, c.relfilenode,
                       c.reltuples, c.relnatts
                  FROM pg_catalog.pg_class c
             LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
             LEFT JOIN pg_catalog.pg_user u ON c.relowner = u.usesysid
                 WHERE c.relkind = 'r'"
        } else {
            set sql "
                SELECT n.nspname || '.' || c.relname AS table
                  FROM pg_catalog.pg_class c
             LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                 WHERE c.relkind = 'r'"
        }

        if {!$pg_} {
            append sql " AND n.nspname != 'pg_catalog'"
            append sql " AND n.nspname != 'information_schema'"
        }

        if {!$pga_} {
            append sql " AND c.relname !~ '^pga_'"
        }

    }

    # lets order the results by table name
    append sql " ORDER BY c.relname"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(table)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc getTablesList


#----------------------------------------------------------
# ::Database::getDatabasesList --
#
#   returns a list of the databases in the cluster
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show the template0 and template1 databases
#    sqlout_    whether to return the SQL created to list the databases
#
# Results:
#    a list of database names; unless $sqlout_ is 1, in which case the SQL
#    to return a list of database names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getDatabasesList {{dbh_ ""} {pg_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    if {$V < 7.3} {
        set sql "
            SELECT datname
              FROM pg_database"
    } else {
        set sql "
            SELECT datname
              FROM pg_catalog.pg_database"
    }

    if {!$pg_} {
        append sql "
            WHERE datname!='template0'
              AND datname!='template1'"
    }

    append sql " ORDER BY datname"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(datname)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getDatabasesList


#----------------------------------------------------------
# ::Database::getSchemasList --
#
#   returns a list of the schemas in the cluster
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show the PG schemas
#    sqlout_    whether to return the SQL created to list the schemas
#
# Results:
#    a list of schema names; unless $sqlout_ is 1, in which case the SQL
#    to return a list of schema names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getSchemasList {{dbh_ ""} {pg_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set sql "
        SELECT nspname
          FROM pg_catalog.pg_namespace"

    if {!$pg_} {
        append sql "
            WHERE nspname!='information_schema'
              AND nspname NOT LIKE 'pg_%'"
    }

    append sql " ORDER BY nspname"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(nspname)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getSchemasList


#----------------------------------------------------------
# ::Database::getLanguagesList --
#
#   returns a list of the languages in the cluster
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show c and internal languages
#    mw_        whether or not to grab extra info for the
#               main window
#    sqlout_    whether to return the SQL created this type
#
# Results:
#    a list of language names; unless $sqlout_ is 1, in which case the SQL
#    to return a list of language names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getLanguagesList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    if {$V < 7.3} {
        if {$mw_} {
            set sql "
                SELECT l.lanname, l.lanpltrusted
                  FROM pg_language l"
        } else {
            set sql "
                SELECT l.lanname
                  FROM pg_language l"
        }
        if {!$pg_} {
            append sql "
                WHERE l.lanname!='c'
                  AND l.lanname!='internal'"
        }
    } else {
        if {$mw_} {
            set sql "
                SELECT l.lanname, l.lanpltrusted
                  FROM pg_catalog.pg_language l"
        } else {
            set sql "
                SELECT l.lanname
                  FROM pg_catalog.pg_language l"
        }
        if {!$pg_} {
            append sql "
                WHERE l.lanname!='c'
                  AND l.lanname!='internal'"
        }
    }

    append sql " ORDER BY l.lanname"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(lanname)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getLanguagesList


#----------------------------------------------------------
# ::Database::getTypesList --
#
#   returns a list of the types in the database
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show internal types
#    mw_        whether or not to grab extra info for the
#               main window
#    sqlout_    whether to return the SQL created this type
#    type_      what type to show (multiple types as string)
#               b for a base type, c for a composite type (i.e., a
#               table's row type), d for a domain, or p for a
#               pseudo-type
#    uscore_    whether to include types with a "_" prefix
#
# Results:
#    a list of type names; unless $sqlout_ is 1, in which case the SQL
#    to return a list of type names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getTypesList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0} {type_ "bcp"} {uscore_ 1}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set sql ""

    set typelist [list]
    for {set i 0} {$i<[string length $type_]} {incr i} {
        lappend typelist [string index $type_ $i]
    }
    set types [join $typelist "','"]

    if {$V < 7.3 } {
        if {$mw_} {
            set sql "
                SELECT t.typname, u.usename,
                       CASE WHEN t.typtype='b' THEN 'base'
                            WHEN t.typtype='c' THEN 'composite'
                            WHEN t.typtype='d' THEN 'domain'
                            WHEN t.typtype='p' THEN 'pseudo'
                            ELSE 'other'
                       END AS typtype
                  FROM pg_type t,
                       pg_user u
                 WHERE t.typtype IN ('$types')
                   AND t.typowner=u.usesysid"
        } else {
            set sql "
                SELECT t.typname
                  FROM pg_type t
                 WHERE t.typtype IN ('$types')"
        }
        if {!$pg_} {
            append sql "
                   AND t.typname NOT LIKE 'pg_%'"
        }
        if {!$uscore_} {
            append sql "
                   AND t.typname!~'^_'"
        }
    } else {
        if {$mw_} {
            set sql "
                SELECT n.nspname, t.typname, u.usename,
                       CASE WHEN t.typtype='b' THEN 'base'
                            WHEN t.typtype='c' THEN 'composite'
                            WHEN t.typtype='d' THEN 'domain'
                            WHEN t.typtype='p' THEN 'pseudo'
                            ELSE 'other'
                       END AS typtype
                  FROM pg_catalog.pg_type t,
                       pg_catalog.pg_namespace n,
                       pg_catalog.pg_user u
                 WHERE t.typtype IN ('$types')
                   AND t.typnamespace=n.oid
                   AND t.typowner=u.usesysid"
        } else {
            set sql "
                SELECT t.typname
                  FROM pg_catalog.pg_type t,
                       pg_catalog.pg_namespace n
                 WHERE t.typtype IN ('$types')
                   AND t.typnamespace=n.oid"
        }
        if {!$pg_} {
            append sql "
                   AND n.nspname!='information_schema'
                   AND n.nspname NOT LIKE 'pg_%'"
        }
        if {!$uscore_} {
            append sql "
                   AND t.typname!~'^_'"
        }
    }

    append sql " ORDER BY t.typname"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(typname)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getTypesList


#----------------------------------------------------------
# ::Database::getIndexesList --
#
#   returns a list of the table indexes in the database
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show internal table indexes
#    mw_        whether or not to grab extra info for the
#               main window
#    sqlout_    whether to return the SQL, or execute it and
#               return the list
#
# Results:
#    a list of indexes; unless $sqlout_ is 1, in which case the SQL
#    to return a list of table index names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getIndexesList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set sql ""

    if {$V < 7.3 } {
        if {$mw_} {
            set sql "
                SELECT c1.relname AS tablename,
                       c2.relname AS indexname,
                       c2.relnatts AS indnatts
                  FROM pg_class c1,
                       pg_class c2,
                       pg_index i
                 WHERE c1.oid=i.indrelid
                   AND c2.oid=i.indexrelid"
        } else {
            set sql "
                SELECT c2.relname AS indexname
                  FROM pg_class c1,
                       pg_class c2,
                       pg_index i
                 WHERE c1.oid=i.indrelid
                   AND c2.oid=i.indexrelid"
        }
        if {!$pg_} {
            append sql "
                   AND c1.relname NOT LIKE 'pg_%'"
        }
    } else {
        if {$mw_} {
            set sql "
                SELECT n.nspname,
                       c1.relname AS tablename,
                       c2.relname AS indexname,
                       i.indnatts
                  FROM pg_catalog.pg_class c1,
                       pg_catalog.pg_class c2,
                       pg_catalog.pg_index i,
                       pg_catalog.pg_namespace n
                 WHERE c1.oid=i.indrelid
                   AND c2.oid=i.indexrelid
                   AND n.oid=c1.relnamespace"
        } else {
            set sql "
                SELECT c2.relname AS indexname
                  FROM pg_catalog.pg_class c1,
                       pg_catalog.pg_class c2,
                       pg_catalog.pg_index i,
                       pg_catalog.pg_namespace n
                 WHERE c1.oid=i.indrelid
                   AND c2.oid=i.indexrelid
                   AND n.oid=c1.relnamespace"
        }
        if {!$pg_} {
            append sql "
                   AND n.nspname!='information_schema'
                   AND n.nspname NOT LIKE 'pg_%'"
        }
    }

    append sql " ORDER BY c2.relname"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(indexname)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getIndexesList

#----------------------------------------------------------
# ::Database::getRulesList --
#
#   returns a list of the table rules in the database
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show internal table/view rules
#    mw_        whether or not to grab extra info for the
#               main window
#    sqlout_    whether to return the SQL, or execute it and
#               return the list
#
# Results:
#    a list of rules; unless $sqlout_ is 1, in which case the SQL
#    to return a list of table/view rule names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getRulesList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set sql ""

    if {$V < 7.3 } {
        if {$mw_} {
            set sql "
                SELECT c.relname,
                       r.rulename,
                       CASE WHEN r.ev_type='1' THEN 'SELECT'
                            WHEN r.ev_type='2' THEN 'UPDATE'
                            WHEN r.ev_type='3' THEN 'INSERT'
                            WHEN r.ev_type='3' THEN 'DELETE'
                            ELSE 'other'
                       END AS ev_type
                  FROM pg_class c,
                       pg_rewrite r
                 WHERE c.oid=r.ev_class"
        } else {
            set sql "
                SELECT r.rulename
                  FROM pg_class c,
                       pg_rewrite r
                 WHERE c.oid=r.ev_class"
        }
        if {!$pg_} {
            append sql "
                   AND c.relname NOT LIKE 'pg_%'"
        }
    } else {
        if {$mw_} {
            set sql "
                SELECT n.nspname,
                       c.relname,
                       r.rulename,
                       CASE WHEN r.ev_type='1' THEN 'SELECT'
                            WHEN r.ev_type='2' THEN 'UPDATE'
                            WHEN r.ev_type='3' THEN 'INSERT'
                            WHEN r.ev_type='3' THEN 'DELETE'
                            ELSE 'other'
                       END AS ev_type
                  FROM pg_catalog.pg_class c,
                       pg_catalog.pg_rewrite r,
                       pg_catalog.pg_namespace n
                 WHERE c.oid=r.ev_class
                   AND n.oid=c.relnamespace"
        } else {
            set sql "
                SELECT r.rulename
                  FROM pg_catalog.pg_class c,
                       pg_catalog.pg_rewrite r,
                       pg_catalog.pg_namespace n
                 WHERE c.oid=r.ev_class
                   AND n.oid=c.relnamespace"
        }
        if {!$pg_} {
            append sql "
                   AND n.nspname!='information_schema'
                   AND n.nspname NOT LIKE 'pg_%'"
        }
    }

    append sql " ORDER BY r.rulename"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(rulename)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getRulesList


#----------------------------------------------------------
# ::Database::getAggregatesList --
#
#   returns a list of the aggregates in the database
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show internal aggregates
#    mw_        whether or not to grab extra info for the
#               main window
#    sqlout_    whether to return the SQL, or execute it and
#               return the list
#
# Results:
#    a list of aggregates; unless $sqlout_ is 1, in which case the SQL
#    to return a list of aggregate names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getAggregatesList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set sql ""

    if {$V < 7.3 } {
        if {$mw_} {
            set sql "
                SELECT a.aggname AS proname,
                       u.usename
                  FROM pg_aggregate a,
                       pg_user u
                 WHERE a.aggowner=u.usesysid"
        } else {
            set sql "
                SELECT a.aggname AS proname
                  FROM pg_aggregate a,
                       pg_user u
                 WHERE a.aggowner=u.usesysid"
        }
        if {!$pg_} {
            append sql "
                   AND a.aggname NOT LIKE 'pg_%'"
        }
    } else {
        if {$mw_} {
            set sql "
                SELECT n.nspname,
                       p.proname,
                       u.usename
                  FROM pg_catalog.pg_aggregate a,
                       pg_catalog.pg_proc p,
                       pg_catalog.pg_user u,
                       pg_catalog.pg_namespace n
                 WHERE a.aggfnoid=p.oid
                   AND u.usesysid=p.proowner
                   AND n.oid=p.pronamespace"
        } else {
            set sql "
                SELECT p.proname
                  FROM pg_catalog.pg_aggregate a,
                       pg_catalog.pg_proc p,
                       pg_catalog.pg_user u,
                       pg_catalog.pg_namespace n
                 WHERE a.aggfnoid=p.oid
                   AND u.usesysid=p.proowner
                   AND n.oid=p.pronamespace"
        }
        if {!$pg_} {
            append sql "
                   AND n.nspname!='information_schema'
                   AND n.nspname NOT LIKE 'pg_%'"
        }
    }

    append sql " ORDER BY proname"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(proname)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getAggregatesList


#----------------------------------------------------------
# ::Database::getConversionsList --
#
#   returns a list of the conversions in the database
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show internal conversions
#    mw_        whether or not to grab extra info for the
#               main window
#    sqlout_    whether to return the SQL, or execute it and
#               return the list
#
# Results:
#    a list of conversions; unless $sqlout_ is 1, in which case the SQL
#    to return a list of conversion names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getConversionsList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set sql ""

    if {$V < 7.3 } {
        # no coversions before PG 7.3 ???
    } else {
        if {$mw_} {
            set sql "
                SELECT n.nspname,
                       c.conname,
                       c.conforencoding,
                       c.contoencoding,
                       p.proname,
                       u.usename
                  FROM pg_catalog.pg_conversion c,
                       pg_catalog.pg_proc p,
                       pg_catalog.pg_user u,
                       pg_catalog.pg_namespace n
                 WHERE p.oid=c.conproc
                   AND u.usesysid=c.conowner
                   AND n.oid=c.connamespace"
        } else {
            set sql "
                SELECT c.conname
                  FROM pg_catalog.pg_conversion c,
                       pg_catalog.pg_proc p,
                       pg_catalog.pg_user u,
                       pg_catalog.pg_namespace n
                 WHERE p.oid=c.conproc
                   AND u.usesysid=c.conowner
                   AND n.oid=c.connamespace"
        }
        if {!$pg_} {
            append sql "
                   AND n.nspname!='information_schema'
                   AND n.nspname NOT LIKE 'pg_%'"
        }
    }

    append sql " ORDER BY c.conname"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(conname)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getConversionsList


#----------------------------------------------------------
# ::Database::getCastsList --
#
#   returns a list of the casts in the database
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show internal casts
#    mw_        whether or not to grab extra info for the
#               main window
#    sqlout_    whether to return the SQL, or execute it and
#               return the list
#
# Results:
#    a list of casts; unless $sqlout_ is 1, in which case the SQL
#    to return a list of cast names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getCastsList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set sql ""

    if {$V < 7.3 } {
        # no cast before PG 7.3 ???
    } else {
        if {$mw_} {
            set sql "
                SELECT t1.typname AS sourcetype,
                       t2.typname AS targettype,
                       p.proname
                  FROM pg_catalog.pg_type t1,
                       pg_catalog.pg_type t2,
                       pg_catalog.pg_cast c,
                       pg_catalog.pg_proc p
                 WHERE t1.oid=c.castsource
                   AND t2.oid=c.casttarget
                   AND p.oid=c.castfunc"
        } else {
            set sql "
                SELECT t1.typname AS sourcetype,
                       t2.typname AS targettype
                  FROM pg_catalog.pg_type t1,
                       pg_catalog.pg_type t2,
                       pg_catalog.pg_cast c,
                       pg_catalog.pg_proc p
                 WHERE t1.oid=c.castsource
                   AND t2.oid=c.casttarget"
        }
        if {!$pg_} {
            append sql "
                   AND n.nspname!='information_schema'
                   AND n.nspname NOT LIKE 'pg_%'"
        }
    }

    append sql " ORDER BY sourcetype"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject "$rec(sourcetype) AS $rec(targettype)"]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getCastsList


#----------------------------------------------------------
# ::Database::getOperatorsList --
#
#   returns a list of the operators in the database
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show internal operators
#    mw_        whether or not to grab extra info for the
#               main window
#    sqlout_    whether to return the SQL, or execute it and
#               return the list
#
# Results:
#    a list of operators; unless $sqlout_ is 1, in which case the SQL
#    to return a list of operator names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getOperatorsList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set sql ""

    if {$V < 7.3 } {
        if {$mw_} {
            set sql "
                SELECT o.oprname,
                       p.proname,
                       u.usename
                  FROM pg_operator o,
                       pg_proc p,
                       pg_user u
                 WHERE p.oid=o.oprcode
                   AND u.usesysid=o.oprowner"
        } else {
            set sql "
                SELECT o.oprname
                  FROM pg_operator o,
                       pg_proc p,
                       pg_user u
                 WHERE p.oid=o.oprcode
                   AND u.usesysid=o.oprowner"
        }
        if {!$pg_} {
            append sql "
                   AND o.oprname NOT LIKE 'pg_%'"
        }
    } else {
        if {$mw_} {
            set sql "
                SELECT n.nspname,
                       o.oprname,
                       p.proname,
                       u.usename
                  FROM pg_catalog.pg_operator o,
                       pg_catalog.pg_proc p,
                       pg_catalog.pg_user u,
                       pg_catalog.pg_namespace n
                 WHERE p.oid=o.oprcode
                   AND u.usesysid=o.oprowner
                   AND n.oid=o.oprnamespace"
        } else {
            set sql "
                SELECT o.oprname
                  FROM pg_catalog.pg_operator o,
                       pg_catalog.pg_proc p,
                       pg_catalog.pg_user u,
                       pg_catalog.pg_namespace n
                 WHERE p.oid=o.oprcode
                   AND u.usesysid=o.oprowner
                   AND n.oid=o.oprnamespace"
        }
        if {!$pg_} {
            append sql "
                   AND n.nspname!='information_schema'
                   AND n.nspname NOT LIKE 'pg_%'"
        }
    }

    append sql " ORDER BY o.oprname"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(oprname)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getOperatorsList


#----------------------------------------------------------
# ::Database::getOperatorClassesList --
#
#   returns a list of the operator classes in the database
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show internal operator classes
#    mw_        whether or not to grab extra info for the
#               main window
#    sqlout_    whether to return the SQL, or execute it and
#               return the list
#
# Results:
#    a list of operator classes; unless $sqlout_ is 1, in which case the SQL
#    to return a list of operator class names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getOperatorClassesList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set sql ""

    if {$V < 7.3 } {
        if {$mw_} {
            # slightly modified from PG 7.2 docs for CREATE INDEX
            set sql "
                SELECT am.amname AS amname,
                       opc.opcname AS opcname,
                       u.usename
                  FROM pg_am am,
                       pg_opclass opc,
                       pg_amop amop,
                       pg_operator opr,
                       pg_user u
                 WHERE opc.opcamid = am.oid
                   AND amop.amopclaid = opc.oid
                   AND amop.amopopr = opr.oid
                   AND u.usesysid=opr.oprowner"
        } else {
            set sql "
                SELECT opc.opcname AS opcname
                  FROM pg_am am,
                       pg_opclass opc,
                       pg_amop amop,
                       pg_operator opr,
                       pg_user u
                 WHERE opc.opcamid = am.oid
                   AND amop.amopclaid = opc.oid
                   AND amop.amopopr = opr.oid
                   AND u.usesysid=opr.oprowner"
        }
        if {!$pg_} {
            append sql "
                   AND opc.opcname NOT LIKE 'pg_%'"
        }
    } else {
        if {$mw_} {
            set sql "
                SELECT n.nspname,
                       o.opcname,
                       a.amname,
                       u.usename
                  FROM pg_catalog.pg_opclass o,
                       pg_catalog.pg_am a,
                       pg_catalog.pg_user u,
                       pg_catalog.pg_namespace n
                 WHERE a.oid=o.opcamid
                   AND u.usesysid=o.opcowner
                   AND n.oid=o.opcnamespace"
        } else {
            set sql "
                SELECT o.opcname
                  FROM pg_catalog.pg_opclass o,
                       pg_catalog.pg_am a,
                       pg_catalog.pg_user u,
                       pg_catalog.pg_namespace n
                 WHERE a.oid=o.opcamid
                   AND u.usesysid=o.opcowner
                   AND n.oid=o.opcnamespace"
        }
        if {!$pg_} {
            append sql "
                   AND n.nspname!='information_schema'
                   AND n.nspname NOT LIKE 'pg_%'"
        }
    }

    append sql " ORDER BY opcname"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(opcname)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getOperatorClassesList


#----------------------------------------------------------
# ::Database::getUsersList --
#
#   returns a list of the users in the database
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show superusers
#    mw_        whether or not to grab extra info for the
#               main window
#    sqlout_    whether to return the SQL, or execute it and
#               return the list
#
# Results:
#    a list of users; unless $sqlout_ is 1, in which case the SQL
#    to return a list of usernames will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getUsersList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set sql "
        SELECT usename
          FROM [::Database::qualifySysTable pg_user $dbh_]
      ORDER BY usename"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(usename)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getUsersList


#----------------------------------------------------------
# ::Database::getTriggersList --
#
#   returns a list of the triggers in the database
#
# Arguments:
#    dbh_       optionally supply the db handle
#    pg_        whether to show internal triggers
#    mw_        whether or not to grab extra info for the
#               main window
#    sqlout_    whether to return the SQL, or execute it and
#               return the list
#
# Results:
#    a list of triggers; unless $sqlout_ is 1, in which case the SQL
#    to return a list of trigger names will be returned instead
#
#----------------------------------------------------------
#
proc ::Database::getTriggersList {{dbh_ ""} {pg_ 0} {mw_ 0} {sqlout_ 0}} {

    global CurrentDB PgAcVar

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set sql ""

    if {$V < 7.3 } {
        if {$mw_} {
            set sql "
                SELECT c.relname, t.tgname, p.proname
                  FROM pg_trigger t,
                       pg_proc p,
                       pg_class c
                 WHERE t.tgrelid=c.oid
                   AND t.tgfoid=p.oid"
        } else {
            set sql "
                SELECT t.tgname
                  FROM pg_trigger t,
                       pg_catalog.pg_proc p,
                       pg_catalog.pg_class c
                 WHERE t.tgrelid=c.oid
                   AND t.tgfoid=p.oid"
        }
        if {!$pg_} {
            append sql "
                   AND t.tgname NOT LIKE 'pg_%'"
        }
    } else {
        if {$mw_} {
            set sql "
                SELECT n.nspname, c.relname, t.tgname, p.proname
                  FROM pg_catalog.pg_trigger t,
                       pg_catalog.pg_namespace n,
                       pg_catalog.pg_proc p,
                       pg_catalog.pg_class c
                 WHERE t.tgrelid=c.oid
                   AND t.tgfoid=p.oid
                   AND c.relnamespace=n.oid"
        } else {
            set sql "
                SELECT t.tgname
                  FROM pg_catalog.pg_trigger t,
                       pg_catalog.pg_namespace n,
                       pg_catalog.pg_proc p,
                       pg_catalog.pg_class c
                 WHERE t.tgrelid=c.oid
                   AND t.tgfoid=p.oid
                   AND c.relnamespace=n.oid"
        }
        if {!$pg_} {
            append sql "
                   AND n.nspname!='information_schema'
                   AND n.nspname NOT LIKE 'pg_%'"
        }
    }

    append sql " ORDER BY t.tgname"

    if {$sqlout_} {return $sql}

    set tlist [list]
    if {[catch {wpg_select $dbh_ "$sql" rec {
                lappend tlist [::Database::quoteObject $rec(tgname)]
            }

    } err]} {
        showError $err
    }

    return $tlist

}; # end proc ::Database::getTriggersList


#------------------------------------------------------------
# isTable --
#
#    checks if arg is a table
#
# Arguments:
#    tbl_       a possible table
#    dbh_       optionally supply the db handle
#
# Results:
#    1 if arg is a table
#    0 if arg is not a table
#------------------------------------------------------------
#
proc ::Database::isTable {tbl_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[string match "" $dbh_]} {return [list]}

    set id [::Connections::getIdFromHandle $dbh_]
    set V [getPgVersion $dbh_]

    set tbl_ [quoteObject $tbl_]
    set tlist [getTablesList]
    set isthisatable 0

    if {$V < 7.3} {
        if { [lsearch $tlist $tbl_] != -1 } {
            set isthisatable 1
        }
    } else {
        if { [lsearch $tlist $tbl_] != -1 } {
            set isthisatable 1
        # if they didn't specifiy a schema don't worry about it
        } elseif { [lsearch -glob $tlist "*.*$tbl_*"] != -1 } {
            set isthisatable 1
        }
    }

    return $isthisatable

}; # end proc ::Database::isTable


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Database::vacuum {} {
global PgAcVar CurrentDB
    if {$CurrentDB==""} return;
    set PgAcVar(statusline,dbname) [format [intlmsg "vacuuming database %s ..."] $PgAcVar(currentdb,dbname)]
    setCursor CLOCK
    set pgres [wpg_exec $CurrentDB "vacuum;"]
    catch {pg_result $pgres -clear}
    setCursor DEFAULT
    set PgAcVar(statusline,dbname) $PgAcVar(currentdb,dbname)
}; # end proc ::Database::vacuum


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Database::getPgType {oid {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set ret "unknown"

    set sql "SELECT typname
               FROM pg_type
              WHERE oid=$oid"

    wpg_select $dbh_ $sql rec {
        set ret $rec(typname)
    }

    return $ret

}; # end proc ::Database::getPgType


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Database::executeUpdate {sql_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    return [sql_exec noquiet $sql_ $dbh_]

}; # end proc ::Database::executeUpdate


#----------------------------------------------------------
# ::Database::getPgVersion --
#
#    Gets the version of the PG database
#
# Arguments:
#    db_    This is the db handle of the DB. If it is
#           not supplied, then CurrentDB is assumed
#
# Results:
#    pgversion
#----------------------------------------------------------
#
proc ::Database::getPgVersion {{db_ ""}} {

    global CurrentDB

    if { [string length $CurrentDB]==0
      && [string length $db_]==0 } {
        showError [intlmsg "Could not find a good db handle"]
        return
    }

    if {[string match "" $db_]} {set db_ $::CurrentDB}

    if {[catch {wpg_select $db_ "
        SELECT version()" rec {
        set res $rec(version)
    }} err]} {

        return ""
    }

    regexp {PostgreSQL ([.\w]+)} $res m ver

    return $ver

}; # end proc ::Database::getPgVersion


#------------------------------------------------------------
# ::Database::qualifySysTable --
#
#    This just qualifies a system table; checking the PG
#    version number, and it >= 7.3, it will prepend
#    the Pg_catalog schema that is used for the 
#    system tables
#
# Arguments:
#    table_   the table name that needs qualified
#    dbh_    the db handle of the database to use. It defaults
#             to the current db handle (CurrentDB)
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc ::Database::qualifySysTable {table_ {dbh_ ""}} {

    if {[string match "" $dbh_]} {
        set dbh_ $::CurrentDB
    }

    set V [string range [getPgVersion $dbh_] 0 2]

    if {$V >= 7.3} {
	set table_ "pg_catalog.${table_}"
    }

    return [quoteObject $table_]

}; # end proc ::Database::qualifySysTable

#------------------------------------------------------------
# ::Database::quoteObject --
#
#    This makes sure that an object is quoted properly,
#    especially if it is schema qualified.
#
# Arguments:
#    obj_     name of the object to quote
#
# Results:
#    returns the properly quoted object
#------------------------------------------------------------
#
proc ::Database::quoteObject {obj_} {
    return \"[string map [list \" "" . \".\"] $obj_]\"
}; # end proc ::Database::quoteTable


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Database::quoteSQL {sql_} {

    set retval ""

    regsub -all {\\} $sql_ {\\\\} retval
    set sql_ $retval
    regsub -all {\"} $sql_ {\\"} retval
    set sql_ $retval
    regsub -all {\'} $sql_ {\\'} retval
#    set sql_ $retval
#    regsub -all {\$} $sql_ {\\$} retval
#    set sql_ $retval
#    regsub -all {\*} $sql_ {\\*} retval

    return $retval

}; # end proc ::Database::quoteSQL


#----------------------------------------------------------
# convenience proc to return available column types
#----------------------------------------------------------
#
proc ::Database::getAllColumnTypes {} {

    return [list char varchar text int2 int4 serial float4 float8 money abstime date datetime interval reltime time timespan timestamp boolean box circle line lseg path point polygon]

}; # end proc ::Database::getAllColumnTypes


#------------------------------------------------------------
#
#   Returns the results as ones list
#------------------------------------------------------------
#
proc ::Database::getList {sql_ {dbh_ ""}} {

    if {[string match "" $dbh_]} {
	set dbh_ $::CurrentDB
    }

    set res [list]
    wpg_select $dbh_ "$sql_" tuple {
	foreach A $tuple(.headers) {
	    lappend res $tuple($A)
	}
    }

    return $res
};  # end proc ::Database::getList


#------------------------------------------------------------
#
#   Returns the results as a list of lists, where each
#   embedded list is a tuple (row) in the results
#------------------------------------------------------------
#
proc ::Database::getListOfList {sql_ {dbh_ ""}} {

    if {[string match "" $dbh_]} {
	set dbh_ $::CurrentDB
    }

    set res [list]
    wpg_select $dbh_ "$sql_" tuple {
	set subl [list]
	foreach A $tuple(.headers) {
	    lappend subl $tuple($A)
	}

	lappend res $subl
    }

    return $res
};  # end proc ::Database::getList

#------------------------------------------------------------
# ::Database::substSql --
#
#    This substitutes a string (usually sql statement)
#    with values that need to be substituted in
#
# Arguments:
#    sql_	the sql statement that has placeholders
#		for values to be substituted in
#    sublist_	This has the list of placeholders and
#		the corresponding value to substitute
#
# Example:
#    set sql "SELECT * FROM %TABLE%"
#    set sl  [list %TABLE% mytable]
#    ::Database::substSql "$sql" $sl
#
# Results:
#    returns the sql_ with the values substituted in
#------------------------------------------------------------
#
proc ::Database::substSql {sql_ sublist_} {

	return [string map "$sublist_" "$sql_"]
}; # end proc substSql


#------------------------------------------------------------
# ::Database::getUniqueKeys --
#    This finds a unique key from the given table. This is
#    in order to allow updates on a row in the table view,
#    since we need a unique key to reference the update.
#    It tries to find the unique in this order:
#        if it has OIDs
#        if it has a primary key
#        if it has a unique id (with 1 key)
#        if it has a unique id (with multi keys)
#        default, sends empty string == can not update table
#
# Arguments:
#   dbh_    database handle
#   table_  which table to get the unique key from
#           can be the fully qualified table name
#
# Results:
#    returns the name(s) of the unique column, if exists.
#    otherwise returns the empty string
#
# Side effects:
#   if it finds nothing, then it will return the empty string
#   which means that the table can not be updates. In theory
#   we could use all of the rows in the update statement,
#   but there is no guarentee of this either...we would
#   have to check how many rows exist first, so that we
#   wouldn't update multiple rows
#------------------------------------------------------------
#
proc ::Database::getUniqueKeys {dbh_ table_} {

    variable Sql

    set table_ [string map {\" ""} $table_]
    foreach {s t} [split $table_ .] {}
    if {[string length $t] == 0} {
        set t $s
        set s public
    }
    set V [getPgVersion $dbh_]
    if {$V < 7.3} {
        set sql [substSql $Sql(hasoids) [list %TABLE% $t]]
    } else {
        set sql [substSql $Sql(schema,hasoids) [list %TABLE% $t %NAMESPACE% $s]]
    }

    ##
    ##  If the table has OIDs, then
    ##  we use that for the unique key
    ##
    if {[getListOfList $sql $dbh_]} {
        return "oid"
    }

    if {$V < 7.3} {
        set sql [substSql $Sql(uniqueKeys) [list %TABLE% $t]]
    } else {
        set sql [substSql $Sql(schema,uniqueKeys) [list %TABLE% $t %NAMESPACE% $s]]
    }
    set lst [getListOfList $sql $dbh_]

    ##
    ##  If there are no unique keys in
    ##  the table, then we return an
    ##  empty string, which will
    ##  signify that this table can
    ##  not be updated properly
    ##
    if {[llength $lst] == 0} {return ""}


    ##
    ##  Otherwise we look at the unique keys
    ##  and preferably choose a primary key
    ##  that has only one attribute available
    ##  Otherwise, we choose a unique key
    ##  with one attribute, if it exists
    ##  then last choice is an unique key
    ##  with multiple attributes
    ##
    set unq [list]
    foreach R $lst {
        foreach {pri key} $R {
            if {$pri} {
                #puts "ATT: [getAttrName $dbh_ $table_ $key]"
                return [getAttrName $dbh_ $table_ $key]
            }
            if {[llength $key] > 1} {
                lappend unq2 $key
            } else {
                lappend unq $key
            }
        }
    }

    ##
    ##  No primary key...check for unique
    ##
    if {[llength $unq] != 0} {
        return [getAttrName $dbh_ $table_ [lindex $unq 0]]
    }

    if {[llength $unq2] != 0} {
        return [getAttrName $dbh_ $table_ [lindex $unq2 0]]
    }
   
    return ""

}; # end proc ::Database::getUniqueKeys



#------------------------------------------------------------
# ::Database::getAttrName --
#    returns the attribute name given the table name
#    and the attnum for that attribute
#
# Arguments:
#    dbh_    database handle
#    table_  table where the attribute lives 
#            (can be fully qualified)
#    attnum_ attnum(s) of the attribute
#
# Results:
#    the attribute name(s) for the attnum(s) passed in
#------------------------------------------------------------
#
proc ::Database::getAttrName {dbh_ table_ attnum_} {
    variable Sql

    set table_ [string map {\" ""} $table_]
    foreach {s t} [split $table_ .] {}
    if {[string length $t] == 0} {
        set t $s
        set s public
    }

    set V [getPgVersion $dbh_]
    set attnum_ [join $attnum_ ,]
 
    if {$V < 7.3} {
        set sql [substSql "$Sql(attrname)" [list %TABLE% $t %ATTNUM% $attnum_]]
    } else {
        set sql [substSql "$Sql(schema,attrname)" [list %TABLE% $t %NAMESPACE% $s %ATTNUM% $attnum_]]
    }

    return [getList "$sql" $dbh_]
    
}; #end proc ::Database::getAttrName
