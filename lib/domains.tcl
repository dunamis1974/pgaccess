#==========================================================
# Domains --
#
#   handling of PostgreSQL domains
#==========================================================
#
namespace eval Domains {}


#----------------------------------------------------------
# ::Domains::init --
#
#   clears out the namespace variables
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Domains::init {} {

    variable Win
    variable mode
    variable name ""
    variable datatype ""
    variable defaultbool 0
    variable defaultexpr "NULL"
    variable constraintbool 0
    variable constraintname "PG ASSIGNED"
    variable constraintval "NULL"
    variable constraintexpr ""

}; # end proc ::Domains::init


#----------------------------------------------------------
# ::Domains::new --
#
#   sets up to create a new Domain
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Domains::new {} {

    variable mode

    ::Domains::init

    set mode "new"

    Window show .pgaw:Domain

}; # end proc ::Domains::new


#----------------------------------------------------------
# ::Domains::open --
#
#   passes work to design proc for opening a Domain
#
# Arguments:
#   domain_     name of Domain to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Domains::open {domain_} {

    design $domain_

}; # end proc ::Domains::new


#----------------------------------------------------------
# ::Domains::design --
#
#   opens window in design mode for selected Domain
#
# Arguments:
#   domain_     name of Domain to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Domains::design {domain_} {

    global CurrentDB

    variable Win
    variable mode
    variable name
    variable datatype
    variable defaultbool
    variable defaultexpr
    variable constraintbool
    variable constraintname
    variable constraintval
    variable constraintexpr

    ::Domains::init

    set mode "design"

    Window show .pgaw:Domain

    # if we are schema qualified, strip out the schema name
    set schema [string range $domain_ 0 [expr {[string first . $domain_]-1}]]
    if { [string length $schema] > 0 } {
        set domain_ [string range $domain_ [expr {[string length $schema]+1}] end]
    }

    set sql "
        SELECT n.nspname || '.' || t.typname
               AS dname,
                (SELECT t2.typname
                   FROM pg_catalog.pg_type t2
                  WHERE t2.oid=t.typbasetype)
               AS datatypename,
                (t.typtypmod -
                (SELECT CASE WHEN t2.typalign='i' THEN '4'
                             WHEN t2.typalign='s' THEN '2'
                             WHEN t2.typalign='c' THEN '0'
                             WHEN t2.typalign='d' THEN '8'
                             ELSE '0'
                        END AS datatypelen
                   FROM pg_catalog.pg_type t2
                  WHERE t2.oid=t.typbasetype)::int4)
               AS datatypelen,
               t.typdefault,
               t.typnotnull,
               (SELECT c.consrc
                  FROM pg_catalog.pg_constraint c
                 WHERE c.contypid=t.oid)
               AS consrc,
               (SELECT c2.conname
                  FROM pg_catalog.pg_constraint c2
                 WHERE c2.contypid=t.oid)
               AS conname
          FROM pg_catalog.pg_type t,
               pg_catalog.pg_namespace n
         WHERE t.typname='$domain_'
           AND t.typnamespace=n.oid
           AND n.nspname='$schema'"

    if {[catch {wpg_select $CurrentDB "$sql" rec {
            set name $rec(dname)
            # need to figure out how to determine this from
            # system catalogs since this is pretty lame
            if {$rec(datatypename)=="bpchar"} {
                set datatype "char"
            } else {
                set datatype $rec(datatypename)
            }; # end lame if statement
            if {$rec(datatypelen)>0} {
                append datatype "(" $rec(datatypelen) ")"
            }
            if {[string length $rec(typdefault)]>0} {
                set defaultbool 0
                $Win(base).cdefaultexpr invoke
                set defaultexpr $rec(typdefault)
            }
            if {[string length $rec(conname)]>0} {
                set constraintbool 0
                $Win(base).cconstraint invoke
                set constraintname $rec(conname)
            }
            if {$rec(typnotnull)=="t"} {
                set constraintbool 0
                set constraintname ""
                $Win(base).cconstraint invoke
                set constraintval "NOT NULL"
            }
            if {[string length $rec(consrc)]>0} {
                set constraintbool 0
                $Win(base).cconstraint invoke
                set constraintval "CHECK"
                $Win(base).rcheckconstraint invoke
                set constraintexpr $rec(consrc)
            }
        }
    } err]} {
        showError $err
    }

}; # end proc ::Domains::new


#----------------------------------------------------------
# ::Domains::save --
#
#   saves currently opened/designed Domain
#
# Arguments:
#   saveas_     1 to save a copy, defaults to 0 (overwrite)
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Domains::save {{saveas_ 0}} {

    variable mode
    variable name
    variable datatype
    variable defaultbool
    variable defaultexpr
    variable constraintbool
    variable constraintname
    variable constraintval
    variable constraintexpr

    set sql "BEGIN TRANSACTION"
    sql_exec noquiet $sql

    if {!$saveas_ && $mode=="design"} {
        set sql "DROP DOMAIN $name"
        if {![sql_exec quiet $sql]} {
            set sql "ROLLBACK TRANSACTION"
            sql_exec noquiet $sql
            set sql "BEGIN TRANSACTION"
            sql_exec noquiet $sql
        }
    }

    set sql "CREATE DOMAIN $name AS $datatype "

    if {$defaultbool} {
        append sql "DEFAULT $defaultexpr "
    }

    if {$constraintbool} {
        if {[string length [string trim $constraintname]] > 0 \
          && $constraintname!="PG ASSIGNED"} {
            append sql "CONSTRAINT $constraintname "
        }
        append sql "$constraintval "
        if {$constraintval=="CHECK" \
          && [string length [string trim $constraintexpr]] > 0} {
            append sql "($constraintexpr)"
        }
    }

    if {[sql_exec noquiet $sql]} {
        set sql "COMMIT TRANSACTION"
        sql_exec noquiet $sql
    } else {
        set sql "ROLLBACK TRANSACTION"
        sql_exec noquiet $sql
    }

}; # end proc ::Domains::save



### END DOMAINS NAMESPACE ###
### BEGIN VISUAL TCL CODE ###



proc vTclWindow.pgaw:Domain {base} {

    global PgAcVar

    if { [string length $base] == 0 } {
        set base .pgaw:Domain
    }

    if {[winfo exists $base]} {
        wm deiconify $base
        return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 500x250+200+200
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Domain"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Key-F1> "Help::load domains"

    set ::Domains::Win(base) $base

    Label $::Domains::Win(base).lname \
        -text [intlmsg "Name"]
    Entry $::Domains::Win(base).ename \
        -textvariable ::Domains::name

    Label $::Domains::Win(base).ldatatype \
        -text [intlmsg "Data Type"]
    ComboBox $::Domains::Win(base).cbdatatype \
        -textvariable ::Domains::datatype \
        -values [join [::Database::getTypesList {} 1 0 0 "b" 0]] \
        -editable true

    checkbutton $::Domains::Win(base).cdefaultexpr \
        -text [intlmsg "Default"] \
        -variable ::Domains::defaultbool \
        -command {
            if {$::Domains::defaultbool} {
                set ::Domains::defaultexpr ""
                $::Domains::Win(base).edefaultexpr configure \
                    -state normal
                $::Domains::Win(base).bdefaultexpr configure \
                    -state normal
                focus $::Domains::Win(base).edefaultexpr
            } else {
                set ::Domains::defaultexpr "NULL"
                $::Domains::Win(base).edefaultexpr configure \
                    -state disabled
                $::Domains::Win(base).bdefaultexpr configure \
                    -state disabled
            }
        }
    Entry $::Domains::Win(base).edefaultexpr \
        -text "NULL" \
        -textvariable ::Domains::defaultexpr \
        -state disabled
    Button $::Domains::Win(base).bdefaultexpr \
        -text "..." \
        -state disabled \
        -command {
            moreText $::Domains::defaultexpr 1 ::Domains::defaultexpr
        }

    checkbutton $::Domains::Win(base).cconstraint \
        -text [intlmsg "Constraint"] \
        -variable ::Domains::constraintbool \
        -command {
            set wlist [list econstraint rnotnullconstraint \
                rnullconstraint rcheckconstraint]
            if {$::Domains::constraintbool} {
                foreach w $wlist {
                    $::Domains::Win(base).$w configure \
                        -state normal
                }
                focus $::Domains::Win(base).econstraint
            } else {
                set ::Domains::constraintname "PG ASSIGNED"
                set ::Domains::constraintexpr ""
                foreach w $wlist {
                    $::Domains::Win(base).$w configure \
                        -state disabled
                }
            }
        }
    Entry $::Domains::Win(base).econstraint \
        -text "PG ASSIGNED" \
        -textvariable ::Domains::constraintname \
        -state disabled
    radiobutton $::Domains::Win(base).rnullconstraint \
        -text [intlmsg "NULL"] \
        -value "NULL" \
        -state disabled \
        -variable ::Domains::constraintval
    radiobutton $::Domains::Win(base).rnotnullconstraint \
        -text [intlmsg "NOT NULL"] \
        -value "NOT NULL" \
        -state disabled \
        -variable ::Domains::constraintval
    radiobutton $::Domains::Win(base).rcheckconstraint \
        -text [intlmsg "CHECK"] \
        -value "CHECK" \
        -state disabled \
        -command {
            set wlist [list echeckconstraint bcheckconstraint]
            if {$::Domains::constraintval=="CHECK"} {
                foreach w $wlist {
                    $::Domains::Win(base).$w configure \
                        -state normal
                }
                focus $::Domains::Win(base).econstraint
            } else {
                set ::Domains::constraintexpr ""
                foreach w $wlist {
                    $::Domains::Win(base).$w configure \
                        -state disabled
                }
            }
        } \
        -variable ::Domains::constraintval
    Entry $::Domains::Win(base).echeckconstraint \
        -textvariable ::Domains::constraintexpr \
        -state disabled
    Button $::Domains::Win(base).bcheckconstraint \
        -text "..." \
        -state disabled \
        -command {
            moreText $::Domains::constraintexpr 1 ::Domains::constraintexpr
        }


    # some buttons to save and whatnot

    ButtonBox $::Domains::Win(base).bboxmenu \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $::Domains::Win(base).bboxmenu add \
        -relief link \
        -image ::icon::filesave-22 \
        -helptext [intlmsg "Save"] \
        -borderwidth 1 \
        -command {::Domains::save 0}
    $::Domains::Win(base).bboxmenu add \
        -relief link \
        -image ::icon::filesaveas-22 \
        -helptext [intlmsg "Save As"] \
        -borderwidth 1 \
        -command {::Domains::save 1}
    $::Domains::Win(base).bboxmenu add \
        -relief link \
        -image ::icon::help-22 \
        -helptext [intlmsg "Help"] \
        -borderwidth 1 \
        -command {::Help::load domains}
    $::Domains::Win(base).bboxmenu add \
        -relief link \
        -image ::icon::exit-22 \
        -helptext [intlmsg "Close"] \
        -borderwidth 1 \
        -command {
            catch {Window destroy .pgaw:Domain}
        }

    grid $::Domains::Win(base).lname \
        -row 0 \
        -column 0 \
        -pady 5 \
        -sticky e
    grid $::Domains::Win(base).ename \
        -row 0 \
        -column 1 \
        -columnspan 2 \
        -sticky we
    grid $::Domains::Win(base).bboxmenu \
        -row 0 \
        -column 4 \
        -pady 5 \
        -sticky e
    grid $::Domains::Win(base).ldatatype \
        -row 1 \
        -column 0 \
        -pady 5 \
        -sticky e
    grid $::Domains::Win(base).cbdatatype \
        -row 1 \
        -column 1 \
        -columnspan 2 \
        -sticky we
    grid $::Domains::Win(base).cdefaultexpr \
        -row 2 \
        -column 0 \
        -pady 5 \
        -sticky e
    grid $::Domains::Win(base).edefaultexpr \
        -row 2 \
        -column 1 \
        -columnspan 2 \
        -sticky we
    grid $::Domains::Win(base).bdefaultexpr \
        -row 2 \
        -column 3
    grid $::Domains::Win(base).cconstraint \
        -row 3 \
        -column 0 \
        -pady 5 \
        -sticky e
    grid $::Domains::Win(base).econstraint \
        -row 3 \
        -column 1 \
        -columnspan 2 \
        -sticky we
    grid $::Domains::Win(base).rnullconstraint \
        -row 4 \
        -column 1 \
        -pady 5 \
        -columnspan 2 \
        -sticky w
    grid $::Domains::Win(base).rnotnullconstraint \
        -row 5 \
        -column 1 \
        -pady 5 \
        -columnspan 2 \
        -sticky w
    grid $::Domains::Win(base).rcheckconstraint \
        -row 6 \
        -column 1 \
        -pady 5 \
        -sticky w
    grid $::Domains::Win(base).echeckconstraint \
        -row 6 \
        -column 2 \
        -sticky we
    grid $::Domains::Win(base).bcheckconstraint \
        -row 6 \
        -column 3


    grid columnconfigure $::Domains::Win(base) 2 \
        -weight 10
    grid rowconfigure $::Domains::Win(base) 7 \
        -weight 10

}
