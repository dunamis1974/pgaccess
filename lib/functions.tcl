#==========================================================
# Functions --
#
#   procedures for manipulating PostgreSQL Functions
#
#==========================================================
#
namespace eval Functions {
    variable Win
    variable name
    variable nametodrop
    variable parameterstodrop
    variable returns
    variable returnstodrop
    variable language
}


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Functions::new {} {

    global PgAcVar
    variable Win

    Window show .pgaw:Function

    set PgAcVar(function,name) {}
    set PgAcVar(function,nametodrop) {}
    set PgAcVar(function,parameters) {}
    set PgAcVar(function,parameterstodrop) {}
    set PgAcVar(function,returns) {}
    set PgAcVar(function,returnstodrop) {}
    set PgAcVar(function,language) {}

    $Win(fnctxt) delete 1.0 end
    focus $Win(base).ename

}; # end proc ::Functions::new


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Functions::open {functionname_} {

    ::Functions::design $functionname_

}; # end proc ::Functions::open


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Functions::design {functionname_} {

    global PgAcVar CurrentDB
    variable Win

    # if we are schema qualified, strip out the schema name
    set schema [string range $functionname_ 0 [expr {[string first . $functionname_]-1}]]
    if { [string length $schema] > 0 } {
        set functionname_ [string range $functionname_ [expr {[string length $schema]+1}] end]
    }

    Window show .pgaw:Function
    $Win(fnctxt) delete 1.0 end

    if { [string length $schema] > 0 } {
        set sql "SELECT p.*, n.nspname || '.' || p.proname
                     AS proname
                   FROM pg_catalog.pg_proc p,
                        pg_catalog.pg_namespace n
                  WHERE
                        p.pronamespace=n.oid
                    AND
                    (SELECT SUBSTRING('$functionname_'
                       FROM 1
                        FOR POSITION('(' IN '$functionname_')-1)=proname)
                    AND
                    (SELECT SUBSTRING('$functionname_'
                       FROM POSITION('(' IN '$functionname_')+1
                            FOR LENGTH('$functionname_')-POSITION('(' IN '$functionname_')-1)=OIDVECTORTYPES(proargtypes))"
    } else {
        set sql "SELECT *
                   FROM [::Database::qualifySysTable pg_proc]
                  WHERE
                    (SELECT SUBSTRING('$functionname_'
                       FROM 1
                        FOR POSITION('(' IN '$functionname_')-1)=proname)
                    AND
                    (SELECT SUBSTRING('$functionname_'
                       FROM POSITION('(' IN '$functionname_')+1
                            FOR LENGTH('$functionname_')-POSITION('(' IN '$functionname_')-1)=OIDVECTORTYPES(proargtypes))"
    }

    wpg_select $CurrentDB $sql rec {
        set PgAcVar(function,name) $rec(proname)
        set temppar $rec(proargtypes)
        set PgAcVar(function,returns) [::Database::getPgType $rec(prorettype)]
        if {$PgAcVar(function,returns) == "unknown"} {set PgAcVar(function,returns) "opaque"}
        set PgAcVar(function,returnstodrop) $PgAcVar(function,returns)
        set funcnrp $rec(pronargs)
        set prolanguage $rec(prolang)
        $Win(fnctxt) insert end $rec(prosrc)
    }

    set sql "SELECT lanname 
	      FROM [::Database::qualifySysTable pg_language] 
	     WHERE oid=$prolanguage"

    wpg_select $CurrentDB "$sql" rec {
        set PgAcVar(function,language) $rec(lanname)
    }
    if { $PgAcVar(function,language)=="C" || $PgAcVar(function,language)=="c" } {

	set sql "SELECT probin 
		   FROM [::Database::qualifySysTable pg_proc]
		  WHERE proname='$functionname_'"

        wpg_select $CurrentDB "$sql" rec {
            $Win(fnctxt) delete 1.0 end
            $Win(fnctxt) insert end $rec(probin)
        }
    }
    set PgAcVar(function,parameters) {}
    for {set i 0} {$i<$funcnrp} {incr i} {
        lappend PgAcVar(function,parameters) [Database::getPgType [lindex $temppar $i]]
    }
    set PgAcVar(function,parameters) [join $PgAcVar(function,parameters) ,]
    set PgAcVar(function,nametodrop) $PgAcVar(function,name)
    set PgAcVar(function,parameterstodrop) $PgAcVar(function,parameters)

    Syntax::highlight $Win(fnctxt) $PgAcVar(function,language)

}; # end proc ::Functions::design


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Functions::save {} {

    global PgAcVar
    variable Win

    if {$PgAcVar(function,name)==""} {
        focus .pgaw:Function.fp.e1
        showError [intlmsg "You must supply a name for this function!"]
    } elseif {$PgAcVar(function,returns)==""} {
        focus .pgaw:Function.fp.e3
        showError [intlmsg "You must supply a return type!"]
    } elseif {$PgAcVar(function,language)==""} {
        focus .pgaw:Function.fp.e4
        showError [intlmsg "You must supply the function language!"]
    } else {
        set funcbody [string trim [$Win(fnctxt) get 1.0 end]]
        # regsub -all "\n" $funcbody " " funcbody
        regsub -all {'} $funcbody {''} funcbody
        regsub -all {\\} $funcbody {\\\\} funcbody

        set OK "no"

        if {$PgAcVar(function,nametodrop)==$PgAcVar(function,name) &&
                $PgAcVar(function,returnstodrop)==$PgAcVar(function,returns) &&
                $PgAcVar(function,parameterstodrop)==$PgAcVar(function,parameters)} {
            set sql "CREATE OR REPLACE
                   FUNCTION $PgAcVar(function,name)
                            ($PgAcVar(function,parameters))
                    RETURNS $PgAcVar(function,returns) AS '$funcbody'
                   LANGUAGE '$PgAcVar(function,language)'"
            if {[sql_exec noquiet $sql]} {
                set OK "yes"
            }

        } else {

            set change [tk_messageBox -default no -type yesno -title [intlmsg "Continue ?"] -parent .pgaw:Main -message [intlmsg "You are to change name, return type or parameters type of function.\nSaving will change function OID."]]

            if {[string match $change "yes"]} {

                sql_exec noquiet "BEGIN TRANSACTION"

                if {$PgAcVar(function,nametodrop) != ""} {
                    set sql "DROP
                         FUNCTION $PgAcVar(function,nametodrop)
                                  ($PgAcVar(function,parameterstodrop))"
                    if {! [sql_exec noquiet $sql]} {
                        # return
                    }
                }

                set sql "CREATE
                       FUNCTION $PgAcVar(function,name)
                                ($PgAcVar(function,parameters))
                        RETURNS $PgAcVar(function,returns) AS '$funcbody'
                       LANGUAGE  '$PgAcVar(function,language)'"
                if {[sql_exec noquiet $sql]} {
                    sql_exec noquiet "COMMIT TRANSACTION"
                    set OK "yes"
                    set PgAcVar(function,returnstodrop) $PgAcVar(function,returns)
                    set PgAcVar(function,parameterstodrop) $PgAcVar(function,parameters)
                    set PgAcVar(function,nametodrop) $PgAcVar(function,name)
                } else {
                    sql_exec noquiet "ROLLBACK TRANSACTION"
                }
            }
        }

        if {[string match $OK "yes"]} {
#            Window destroy .pgaw:Function
#            tk_messageBox -title PostgreSQL -parent .pgaw:Main -message [intlmsg "Function saved!"]
            Mainlib::tab_click Functions
        }

        Syntax::highlight $Win(fnctxt) $PgAcVar(function,language)
    }

}; # ::Functions::save


proc ::Functions::save_as {} {

    global PgAcVar
    variable Win

    if {$PgAcVar(function,name)==""} {
        focus .pgaw:Function.fp.e1
        showError [intlmsg "You must supply a name for this function!"]
    } elseif {$PgAcVar(function,returns)==""} {
        focus .pgaw:Function.fp.e3
        showError [intlmsg "You must supply a return type!"]
    } elseif {$PgAcVar(function,language)==""} {
        focus .pgaw:Function.fp.e4
        showError [intlmsg "You must supply the function language!"]
    } else {
        set funcbody [string trim [$Win(fnctxt) get 1.0 end]]
        # regsub -all "\n" $funcbody " " funcbody
        regsub -all {'} $funcbody {''} funcbody
        regsub -all {\\} $funcbody {\\\\} funcbody

        set sql "CREATE
               FUNCTION $PgAcVar(function,name)
                        ($PgAcVar(function,parameters))
                RETURNS $PgAcVar(function,returns) AS '$funcbody'
               LANGUAGE '$PgAcVar(function,language)'"
        if {[sql_exec noquiet $sql]} {
#            Window destroy .pgaw:Function
#            tk_messageBox -title PostgreSQL -parent .pgaw:Main -message [intlmsg "Function saved!"]
            Mainlib::tab_click Functions
            Syntax::highlight $Win(fnctxt) $PgAcVar(function,language)
        }
    }

}; # ::Functions::save_as


#----------------------------------------------------------
# ::Functions::introspect --
#
#   Given a functionname, returns the SQL needed to recreate it
#
# Arguments:
#   functionname_   name of a function to introspect
#   dbh_            an optional database handle
#
# Returns:
#   insql      the CREATE statement to make this function
#----------------------------------------------------------
#
proc ::Functions::introspect {functionname_ {dbh_ ""}} {

    set insql [::Functions::clone $functionname_ $functionname_ $dbh_]

    return $insql

}; # end proc ::Functions::introspect


#----------------------------------------------------------
# ::Functions::clone --
#
#   Like introspect, only changes the functionname
#
# Arguments:
#   srcfunction_    the original function
#   destfunction_   the clone function
#   dbh_            an optional database handle
#
# Returns:
#   insql       the CREATE statement to clone this function
#----------------------------------------------------------
#
proc ::Functions::clone {srcfunction_ destfunction_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set insql ""

    set srcfunction_ [string map {\" {}} $srcfunction_]
    set destfunction_ [string map {\" {}} $destfunction_]

    set sql "SELECT *
               FROM pg_proc
              WHERE
                (SELECT SUBSTRING('$srcfunction_'
                   FROM 1
                    FOR POSITION('(' IN '$srcfunction_')-1)=proname)
                AND
                (SELECT SUBSTRING('$srcfunction_'
                   FROM POSITION('(' IN '$srcfunction_')+1
                        FOR LENGTH('$srcfunction_')-POSITION('(' IN '$srcfunction_')-1)=OIDVECTORTYPES(proargtypes))"

    wpg_select $dbh_ $sql rec {
        set insql "CREATE
                 FUNCTION [lindex [split $destfunction_ (] 0]([::Functions::getParameters $rec(proargtypes) $rec(pronargs) $dbh_]) RETURNS [::Functions::getPgType $rec(prorettype) $dbh_]
                       AS '[::Database::quoteSQL [::Functions::getBody $rec(proname) $rec(prolang) $rec(prosrc) $dbh_]]'
                 LANGUAGE '[::Functions::getLanguage $rec(prolang) $dbh_]';"
    }

    return $insql

}; # end proc ::Functions::clone


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Functions::getPgType {oid_ {dbh_ ""}} {

    set ret [::Database::getPgType $oid_ $dbh_]

    if {[string match $ret "unknown"]} {
        set ret "opaque"
    }

    return $ret

}; # end proc ::Functions::getPgType


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Functions::getLanguage {oid_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set lang ""

    set sql "SELECT lanname
               FROM pg_language
              WHERE oid=$oid_"

    wpg_select $dbh_ $sql rec {
        set lang $rec(lanname)
    }

    return $lang

}; # end proc ::Functions::getLanguage


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Functions::getBody {func_ lang_ src_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set body ""

    if {$lang_=="C" || $lang_=="c"} {
        set sql "SELECT probin
                   FROM [::Database::qualifySysTable pg_proc]
                  WHERE proname='$func_'"
        wpg_select $dbh_ $sql rec {
            set body $rec(probin)
        }
    } else {
        set body $src_
    }

    return $body

}; # end proc ::Functions::getBody


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Functions::getParameters {argtypes_ argcount_ {dbh_}} {

    set params {}

    for {set i 0} {$i<$argcount_} {incr i} {
        lappend params [::Database::getPgType [lindex $argtypes_ $i]]
    }

    set params [join $params ,]

    return $params

}; # end proc ::Functions::getParameters



#==========================================================
#==========================================================



proc vTclWindow.pgaw:Function {base} {

    global PgAcVar

    if {$base == ""} {
        set base .pgaw:Function
    }

    if {[winfo exists $base]} {
        wm deiconify $base; return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 680x400+98+212
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Function"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    bind $base <Key-F1> "Help::load functions"
    bind $base <Escape> {Window destroy .pgaw:Function}

    set ::Functions::Win(base) $base

    Label $::Functions::Win(base).lname \
        -text [intlmsg "Name"]
    Entry $::Functions::Win(base).ename \
        -textvariable PgAcVar(function,name)

    Label $::Functions::Win(base).lparams \
        -text [intlmsg "Parameters"]
    Entry $::Functions::Win(base).eparams \
        -textvariable PgAcVar(function,parameters)

    Label $::Functions::Win(base).lreturns \
        -text [intlmsg "Returns"]
    Entry $::Functions::Win(base).ereturns \
        -textvariable PgAcVar(function,returns)

    Label $::Functions::Win(base).llang \
        -text [intlmsg "Language"]
    ComboBox $::Functions::Win(base).cblang \
        -textvariable PgAcVar(function,language) \
        -values [join [::Database::getLanguagesList]] \
        -editable true

    set ::Functions::Win(fnctxt) $::Functions::Win(base).text
    text $::Functions::Win(fnctxt) \
        -background #fefefe \
        -foreground #000000 \
        -borderwidth 1 \
        -font $PgAcVar(pref,font_fix) \
        -height 16 \
        -tabs {20 40 60 80 100 120} \
        -width 43 \
        -wrap none \
        -yscrollcommand \
            [list $::Functions::Win(base).vscroll set] \
        -xscrollcommand \
            [list $::Functions::Win(base).hscroll set]
    bind $::Functions::Win(fnctxt) <Control-Key-s> {
        Functions::save
    }

    # add Ctrl-x|c|v for cut, copy, paste
    bind $::Functions::Win(fnctxt) <Control-Key-x> {
        set PgAcVar(shared,curseltext) [%W get sel.first sel.last]
        %W delete sel.first sel.last
    }
    bind $::Functions::Win(fnctxt) <Control-Key-c> {
        set PgAcVar(shared,curseltext) [%W get sel.first sel.last]
    }
    bind $::Functions::Win(fnctxt) <Control-Key-v> {
        if {[info exists PgAcVar(shared,curseltext)]} {
            catch {%W delete sel.first sel.last}
            %W insert insert $PgAcVar(shared,curseltext)
            %W see current
        }
    }

    scrollbar $::Functions::Win(base).vscroll \
        -command "$::Functions::Win(fnctxt) yview" \
        -orient vert
    scrollbar $::Functions::Win(base).hscroll \
        -command "$::Functions::Win(fnctxt) xview" \
        -orient horiz

    ButtonBox $::Functions::Win(base).bboxmenu \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $::Functions::Win(base).bboxmenu add \
        -relief link \
        -image ::icon::fileopen-22 \
        -helptext [intlmsg "Browse"] \
        -borderwidth 1 \
        -command {
            set types {
                {{Compiled Functions}   {.so}}
                {{All Files}            *}
            }
            catch {tk_getOpenFile \
                -parent $::Functions::Win(base) \
                -filetypes $types \
                -title [intlmsg "Browse for Compiled Functions"] \
            } filename
            $::Functions::Win(fnctxt) delete 1.0 end
            $::Functions::Win(fnctxt) insert end $filename
        }
    $::Functions::Win(base).bboxmenu add \
        -relief link \
        -image ::icon::filesave-22 \
        -helptext [intlmsg "Save"] \
        -borderwidth 1 \
        -command {::Functions::save}
    $::Functions::Win(base).bboxmenu add \
        -relief link \
        -image ::icon::filesaveas-22 \
        -helptext [intlmsg "Save As"] \
        -borderwidth 1 \
        -command {::Functions::save_as}
    $::Functions::Win(base).bboxmenu add \
        -relief link \
        -image ::icon::help-22 \
        -helptext [intlmsg "Help"] \
        -borderwidth 1 \
        -command {::Help::load functions}
    $::Functions::Win(base).bboxmenu add \
        -relief link \
        -image ::icon::exit-22 \
        -helptext [intlmsg "Close"] \
        -borderwidth 1 \
        -command {
            catch {Window destroy .pgaw:Function}
        }

    grid $::Functions::Win(base).lname \
        -row 0 \
        -column 0 \
        -pady 2 \
        -padx 5 \
        -sticky e
    grid $::Functions::Win(base).ename \
        -row 0 \
        -column 1 \
        -sticky we
    grid $::Functions::Win(base).lparams \
        -row 1 \
        -column 0 \
        -pady 2 \
        -padx 5 \
        -sticky e
    grid $::Functions::Win(base).eparams \
        -row 1 \
        -column 1 \
        -sticky we
    grid $::Functions::Win(base).lreturns \
        -row 0 \
        -column 2 \
        -sticky e
    grid $::Functions::Win(base).ereturns \
        -row 0 \
        -column 3 \
        -sticky we
    grid $::Functions::Win(base).llang \
        -row 1 \
        -column 2 \
        -sticky e
    grid $::Functions::Win(base).cblang \
        -row 1 \
        -column 3 \
        -sticky we

    grid $::Functions::Win(base).bboxmenu \
        -row 0 \
        -column 4 \
        -columnspan 2 \
        -rowspan 2 \
        -sticky e

    grid $::Functions::Win(fnctxt) \
        -row 2 \
        -column 0 \
        -columnspan 5 \
        -sticky news
    grid $::Functions::Win(base).hscroll \
        -row 3 \
        -column 0 \
        -columnspan 5 \
        -sticky new
    grid $::Functions::Win(base).vscroll \
        -row 2 \
        -column 5 \
        -sticky nws

    grid columnconfigure $::Functions::Win(base) 1 \
        -weight 5
    grid columnconfigure $::Functions::Win(base) 3 \
        -weight 5
    grid columnconfigure $::Functions::Win(base) 4 \
        -weight 10
    grid rowconfigure $::Functions::Win(base) 2 \
        -weight 10

}


