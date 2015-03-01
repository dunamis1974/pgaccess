#==========================================================
# Types --
#
#   handling of PostgreSQL types
#==========================================================
#
namespace eval Types {}


#----------------------------------------------------------
# ::Types::init --
#
#   clears out the namespace variables and opens the window
#   for Types
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Types::init {} {

    variable Win
    variable mode
    variable typename ""
    variable typetype "composite"
    variable inputfcn ""
    variable outputfcn ""
    variable recvfcn ""
    variable sendfcn ""
    variable internallength ""
    variable passedby ""
    variable alignment ""
    variable storage ""
    variable defaultval ""
    variable elementtypes ""
    variable delimiter ""

}; # end proc ::Types init


#----------------------------------------------------------
# ::Types::new --
#
#   sets up to create a new type
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Types::new {} {

    variable mode

    ::Types::init

    set mode "new"

    Window show .pgaw:Type

}; # end proc ::Types::new


#----------------------------------------------------------
# ::Types::open --
#
#   passes work to design proc for opening a Type
#
# Arguments:
#   typename_   name of type to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Types::open {typename_} {

    ::Types::design $typename_

}; # end proc ::Types::open


#----------------------------------------------------------
# ::Types::design --
#
#   opens a Type in design mode
#
# Arguments:
#   typename_   name of type to design
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Types::design {typename_} {

    variable Win
    variable mode
    variable typename
    variable typetype

    ::Types::init

    set mode "design"
    set typename $typename_
    set typetype [getTypeOfType $typename_]

    Window show .pgaw:Type

    switch $typetype {
        composite {
            foreach pair [getCompositePairsList $typename_] {
                $Win(page,composite).table insert end $pair
            }
        }
        base {
            loadBaseType $typename_
        }
        default {}
    }

}; # end proc ::Types::design


#----------------------------------------------------------
# ::Types::loadBaseType --
#
#   loads a base type for design mode
#
# Arguments:
#   typename_   name of type to load
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Types::loadBaseType {typename_} {

    global CurrentDB
    variable inputfcn
    variable outputfcn
    variable recvfcn
    variable sendfcn
    variable internallength
    variable passedby
    variable alignment
    variable storage
    variable defaultval
    variable elementtypes
    variable delimiter

    set sql ""

    # if we are schema qualified, strip out the schema name
    set schema [string range $typename_ 0 [expr {[string first . $typename_]-1}]]
    if { [string length $schema] > 0 } {
        set typename_ [string range $typename_ [expr {[string length $schema]+1}] end]
    }

    set V [::Database::getPgVersion $CurrentDB]

    if {$V < 7.3} {
        # dont really care about 7.2 anymore
        # upgrade your databases, people
        set sql ""
    } else {
        # mmm, big tasty sql...
        set sql "
            SELECT t.typlen,
                   CASE WHEN t.typlen=-1 THEN 'VARIABLE'
                        WHEN t.typlen=-2 THEN 'cstring'
                        ELSE t.typlen::text
                   END AS internallength,
                   t.typbyval,
                   CASE WHEN t.typbyval='t' THEN 'VALUE'
                        ELSE 'REFERENCE'
                   END AS passedby,
                   t.typalign,
                   CASE WHEN t.typalign='c' THEN 'char'
                        WHEN t.typalign='s' THEN 'short'
                        WHEN t.typalign='i' THEN 'int'
                        WHEN t.typalign='d' THEN 'double'
                        ELSE ''
                   END AS alignment,
                   t.typstorage,
                   CASE WHEN t.typstorage='p' THEN 'plain'
                        WHEN t.typstorage='e' THEN 'external'
                        WHEN t.typstorage='x' THEN 'extended'
                        WHEN t.typstorage='m' THEN 'main'
                        ELSE ''
                   END AS storage,
                   t.typdefault,
                   COALESCE(t.typdefault,'NULL') AS defaultval,
                   t.typdelim,
                   t.typdelim AS delimiter,
                   t.typelem,
                   (SELECT e.typname
                      FROM pg_catalog.pg_type e
                     WHERE e.oid=t.typelem) AS elementtypes,
                   t.typinput,
                   (SELECT s.nspname || '.' || p.proname
                      FROM pg_catalog.pg_proc p,
                           pg_catalog.pg_namespace s
                     WHERE p.oid=t.typinput
                       AND p.pronamespace=s.oid) AS inputfcn,
                   t.typoutput,
                   (SELECT s.nspname || '.' || p.proname
                      FROM pg_catalog.pg_proc p,
                           pg_catalog.pg_namespace s
                     WHERE p.oid=t.typoutput
                       AND p.pronamespace=s.oid) AS outputfcn,
                   t.typreceive,
                   (SELECT s.nspname || '.' || p.proname
                      FROM pg_catalog.pg_proc p,
                           pg_catalog.pg_namespace s
                     WHERE p.oid=t.typreceive
                       AND p.pronamespace=s.oid) AS recvfcn,
                   t.typsend,
                   (SELECT s.nspname || '.' || p.proname
                      FROM pg_catalog.pg_proc p,
                           pg_catalog.pg_namespace s
                     WHERE p.oid=t.typsend
                       AND p.pronamespace=s.oid) AS sendfcn
              FROM pg_catalog.pg_type t,
                   pg_catalog.pg_namespace n
             WHERE t.typname='$typename_'
               AND t.typnamespace=n.oid
               AND n.nspname='$schema'"
    }

    if {[catch {wpg_select $CurrentDB "$sql" rec {
            set internallength $rec(internallength)
            set passedby $rec(passedby)
            set storage $rec(storage)
            set alignment $rec(alignment)
            set defaultval $rec(defaultval)
            set delimiter $rec(delimiter)
            set elementtypes $rec(elementtypes)
            set inputfcn $rec(inputfcn)
            set outputfcn $rec(outputfcn)
            set recvfcn $rec(recvfcn)
            set sendfcn $rec(sendfcn)
        }
    } err]} {
        showError $err
    }

}; # end proc ::Types::loadBaseType


#----------------------------------------------------------
# ::Types::addCompositePair --
#
#   inserts an item into the table for an
#   attribute_name/type pair
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Types::addCompositePair {} {

    variable Win
    variable mode

    if {$mode == "design"} {
        set size [expr {[$Win(page,composite).table size]+1}]
        $Win(page,composite).table insert end [list $size "DEFAULT" "char"]
    } else {
        $Win(page,composite).table insert end [list "DEFAULT" "char"]
    }

}; # end proc ::Types::addCompositePair


#----------------------------------------------------------
# ::Types::removeCompositePair --
#
#   deletes an attribute_name/type pair from the list
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Types::removeCompositePair {} {

    variable Win

    set cursel [$Win(page,composite).table curselection]

    if {$cursel == ""} {return ""}

    $Win(page,composite).table delete $cursel

}; # end proc ::Types::addCompositePair


#----------------------------------------------------------
# ::Types::changeCompositeType --
#
#   alters the type of an attribute_name/type pair
#
# Arguments:
#   newtype_    the new type to assign to the pair
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Types::changeCompositeType {newtype_} {

    variable Win
    variable mode

    set cursel [$Win(page,composite).table curselection]

    if {$cursel == ""} {return ""}

    if {$mode == "design"} {
        append cursel ",2"
    } else {
        append cursel ",1"
    }

    $Win(page,composite).table cellconfigure $cursel \
        -text $newtype_

}; # end proc ::Types::changeCompositeType


#----------------------------------------------------------
# ::Types::saveCompositeType --
#
#   create the type in the database
#
# Arguments:
#   saveas_     boolean indicating whether or not to save
#               this type separately or overwrite it
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Types::saveCompositeType {{saveas_ 0}} {

    global CurrentDB

    variable Win
    variable mode
    variable typename

    if { [string length $typename] == 0 } {
        showError [intlmsg "You must supply a name for the Type!"]
        return
    }

    if {$mode == "design"} {
        $Win(page,composite).table sortbycolumn 0
    }

    set sql "BEGIN TRANSACTION"
    sql_exec noquiet $sql

    if {!$saveas_ && $mode=="design"} {
        set sql "DROP TYPE $typename"
        sql_exec noquiet $sql
    }

    set sql "CREATE TYPE $typename AS "

    set pairlist [list]
    foreach pair [$Win(page,composite).table get 0 end] {
        if {$mode == "design"} {
            lappend pairlist [lrange $pair 1 end]
        } else {
            lappend pairlist $pair
        }
    }

    append sql "(" [join $pairlist ,] ")"

    if {[sql_exec noquiet $sql]} {
        set sql "COMMIT TRANSACTION"
        sql_exec noquiet $sql
    } else {
        set sql "ROLLBACK TRANSACTION"
        sql_exec noquiet $sql
    }

    if {[string length [string trim [join $pairlist]]]==0} {
        showError [intlmsg "You must supply more information!"]
        return
    }


}; # end proc ::Types::saveCompositeType


#----------------------------------------------------------
# ::Types::saveBaseType --
#
#   create the type in the database
#
# Arguments:
#   saveas_     boolean indicating whether or not to save
#               this type separately or overwrite it
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Types::saveBaseType {{saveas_ 0}} {

    global CurrentDB

    variable Win
    variable mode
    variable typename
    variable inputfcn
    variable outputfcn
    variable recvfcn
    variable sendfcn
    variable internallength
    variable passedby
    variable alignment
    variable storage
    variable defaultval
    variable elementtypes
    variable delimiter

    if { [string length $typename] == 0 } {
        showError [intlmsg "You must supply a name for the Type!"]
        return
    }

    if { [string length $inputfcn] == 0 } {
        showError [intlmsg "You must supply an input function for the Type!"]
        return
    }

    if { [string length $outputfcn] == 0 } {
        showError [intlmsg "You must supply an output function for the Type!"]
        return
    }

    set sql "BEGIN TRANSACTION"
    sql_exec noquiet $sql

    if {!$saveas_ && $mode=="design"} {
        set sql "DROP TYPE $typename"
        sql_exec noquiet $sql
    }

    set sql "CREATE TYPE $typename ("

    set p1 [string last ( $inputfcn]
    set p2 [string last ) $inputfcn]
    set ifcn [string replace $inputfcn $p1 $p2]
    append sql "INPUT=$ifcn,"

    set p1 [string last ( $outputfcn]
    set p2 [string last ) $outputfcn]
    set ofcn [string replace $outputfcn $p1 $p2]
    append sql "OUTPUT=$ofcn"

    if {[string length $recvfcn] > 0} {
        set p1 [string last ( $recvfcn]
        set p2 [string last ) $recvfcn]
        set rfcn [string replace $recvfcn $p1 $p2]
        append sql ", RECEIVE=$rfcn"
    }

    if {[string length $sendfcn] > 0} {
        set p1 [string last ( $sendfcn]
        set p2 [string last ) $sendfcn]
        set sfcn [string replace $sendfcn $p1 $p2]
        append sql ", SEND=$sfcn"
    }

    if {[string length $internallength] > 0} {
        append sql ", INTERNALLENGTH=$internallength"
    }

    if {$passedby==[intlmsg "VALUE"]} {
        append sql ", PASSEDBYVALUE"
    }

    if {[string length $alignment] > 0} {
        append sql ", ALIGNMENT=$alignment"
    }

    if {[string length $storage] > 0} {
        append sql ", STORAGE=$storage"
    }

    if {$defaultval!="NULL"} {
        append sql ", DEFAULT='$defaultval'"
    }

    if {[string length $elementtypes] > 0} {
        append sql ", ELEMENT=$elementtypes"
    }

    if {[string length $delimiter] > 0} {
        append sql ", DELIMITER='$delimiter'"
    }

    append sql ")"

    if {[sql_exec noquiet $sql]} {
        set sql "COMMIT TRANSACTION"
        sql_exec noquiet $sql
    } else {
        set sql "ROLLBACK TRANSACTION"
        sql_exec noquiet $sql
    }

}; # end proc ::Types::saveBaseType


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Types::getTypeOfType {typename_} {

    global CurrentDB

    set sql ""
    set typ ""

    # if we are schema qualified, strip out the schema name
    set schema [string range $typename_ 0 [expr {[string first . $typename_]-1}]]
    if { [string length $schema] > 0 } {
        set typename_ [string range $typename_ [expr {[string length $schema]+1}] end]
    }

    set V [::Database::getPgVersion $CurrentDB]

    if {$V < 7.3} {
        set sql "
            SELECT CASE WHEN t.typtype='b' THEN 'base'
                        WHEN t.typtype='c' THEN 'composite'
                        WHEN t.typtype='d' THEN 'domain'
                        WHEN t.typtype='p' THEN 'pseudo'
                        ELSE 'other'
                   END AS typtype
              FROM pg_type t
             WHERE t.typname='$typename_'"
    } else {
        set sql "
            SELECT CASE WHEN t.typtype='b' THEN 'base'
                        WHEN t.typtype='c' THEN 'composite'
                        WHEN t.typtype='d' THEN 'domain'
                        WHEN t.typtype='p' THEN 'pseudo'
                        ELSE 'other'
                   END AS typtype
              FROM pg_catalog.pg_type t,
                   pg_catalog.pg_namespace n
             WHERE t.typname='$typename_'
               AND t.typnamespace=n.oid
               AND n.nspname='$schema'"
    }

    if {[catch {wpg_select $CurrentDB "$sql" rec {
            set typ $rec(typtype)
        }
    } err]} {
        showError $err
    }

    return $typ

}; # end proc ::Types::getTypeOfType


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Types::getCompositePairsList {typename_} {

    global CurrentDB

    set sql ""

    # if we are schema qualified, strip out the schema name
    set schema [string range $typename_ 0 [expr {[string first . $typename_]-1}]]
    if { [string length $schema] > 0 } {
        set typename_ [string range $typename_ [expr {[string length $schema]+1}] end]
    }

    set V [::Database::getPgVersion $CurrentDB]

    if {$V < 7.3} {
        set sql ""
    } else {
        set sql "
            SELECT DISTINCT
                   a.attnum, a.attname,
                   (SELECT tt.typname
                      FROM pg_type tt
                     WHERE tt.oid=a.atttypid)
                   AS typtype
              FROM pg_attribute a,
                   pg_catalog.pg_type t,
                   pg_catalog.pg_namespace n
             WHERE t.typname='$typename_'
               AND a.attrelid=t.typrelid
               AND t.typnamespace=n.oid
               AND n.nspname='$schema'
          ORDER BY a.attnum"
    }

    set pairs [list]
    if {[catch {wpg_select $CurrentDB "$sql" rec {
            lappend pairs [list $rec(attnum) $rec(attname) $rec(typtype)]
        }
    } err]} {
        showError $err
    }

    return $pairs

}; # end proc ::Types::getCompositePairsList



### END TYPES NAMESPACE ###
### BEGIN VISUAL TCL CODE ###



proc vTclWindow.pgaw:Type {base} {

    global PgAcVar

    if { [string length $base] == 0 } {
        set base .pgaw:Type
    }

    if {[winfo exists $base]} {
        wm deiconify $base
        catch {$::Types::Win(notebook) raise $::Types::typetype}
        return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 500x400+100+40
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Type"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Key-F1> "Help::load types"

    set ::Types::Win(notebook) [NoteBook $base.nb]
    pack $::Types::Win(notebook) \
        -expand 1 \
        -fill both

    set ::Types::Win(page,composite) \
        [$::Types::Win(notebook) insert end composite \
            -text [intlmsg "Composite"]]

    set ::Types::Win(page,base) \
        [$::Types::Win(notebook) insert end base \
            -text [intlmsg "Base"]]

    set ::Types::Win(page,pseudo) \
        [$::Types::Win(notebook) insert end pseudo \
            -text [intlmsg "Pseudo"]]

    #
    # composite page
    #

    LabelEntry $::Types::Win(page,composite).lename \
        -label [intlmsg "Name"] \
        -textvariable ::Types::typename

    scrollbar $::Types::Win(page,composite).xscroll \
        -width 12 \
        -command [list $::Types::Win(page,composite).table xview] \
        -highlightthickness 0 \
        -orient horizontal \
        -background #DDDDDD \
        -takefocus 0

    scrollbar $::Types::Win(page,composite).yscroll \
        -width 12 \
        -command [list $::Types::Win(page,composite).table yview] \
        -highlightthickness 0 \
        -background #DDDDDD \
        -takefocus 0

    tablelist::tablelist $::Types::Win(page,composite).table \
        -yscrollcommand \
            [list $::Types::Win(page,composite).yscroll set] \
        -xscrollcommand \
            [list $::Types::Win(page,composite).xscroll set] \
        -labelcommand tablelist::sortByColumn \
        -background #fefefe \
        -stripebg #e0e8f0 \
        -selectbackground #DDDDDD \
        -selectmode extended \
        -font $PgAcVar(pref,font_normal) \
        -labelfont $PgAcVar(pref,font_bold) \
        -stretch all \
        -selectforeground #708090 \
        -labelbackground #DDDDDD \
        -labelforeground navy

    set compcols [list]
    if {$::Types::mode == "design"} {
        lappend compcols 0 [intlmsg "order"] left
    }
    lappend compcols \
        0 [intlmsg "attribute name"] left \
        0 [intlmsg "data type"] left

    $::Types::Win(page,composite).table configure \
        -columns $compcols

    # dictionary sort is the best of ascii and integer

    for {set i 0} {$i < [expr {[llength $compcols]/3}]} {incr i} {
        $::Types::Win(page,composite).table columnconfigure $i \
            -sortmode dictionary
    }
    for {set i 0} {$i < [expr {[llength $compcols]/3-1}]} {incr i} {
        $::Types::Win(page,composite).table columnconfigure $i \
            -editable 1
    }

    # buttons to add/remove a composite attribute/type pair

    ButtonBox $::Types::Win(page,composite).bboxtable \
        -orient vertical \
        -homogeneous 1 \
        -spacing 2
    $::Types::Win(page,composite).bboxtable add \
        -image ::icon::hotlistadd-16 \
        -helptext [intlmsg "Add"] \
        -borderwidth 1 \
        -command {::Types::addCompositePair}
    $::Types::Win(page,composite).bboxtable add \
        -image ::icon::hotlistdel-16 \
        -helptext [intlmsg "Remove"] \
        -borderwidth 1 \
        -command {::Types::removeCompositePair}

    # a popup for the different base types

    menu $::Types::Win(page,composite).table.typepopup
    set newcol 0
    foreach basetype [join [::Database::getTypesList {} 1 0 0 "b" 0]] {
        $::Types::Win(page,composite).table.typepopup add command \
            -label $basetype \
            -command "::Types::changeCompositeType $basetype" \
            -columnbreak [expr {floor((($newcol%20)+1)/20)}]
        incr newcol
    }
    set body [$::Types::Win(page,composite).table bodypath]
    bind $body <ButtonRelease-3> {
        tk_popup $::Types::Win(page,composite).table.typepopup %X %Y 0
    }

    # some buttons to save and whatnot

    ButtonBox $::Types::Win(page,composite).bboxmenu \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $::Types::Win(page,composite).bboxmenu add \
        -relief link \
        -image ::icon::filesave-22 \
        -helptext [intlmsg "Save"] \
        -borderwidth 1 \
        -command {::Types::saveCompositeType 0}
    $::Types::Win(page,composite).bboxmenu add \
        -relief link \
        -image ::icon::filesaveas-22 \
        -helptext [intlmsg "Save As"] \
        -borderwidth 1 \
        -command {::Types::saveCompositeType 1}
    $::Types::Win(page,composite).bboxmenu add \
        -relief link \
        -image ::icon::help-22 \
        -helptext [intlmsg "Help"] \
        -borderwidth 1 \
        -command {::Help::load types}
    $::Types::Win(page,composite).bboxmenu add \
        -relief link \
        -image ::icon::exit-22 \
        -helptext [intlmsg "Close"] \
        -borderwidth 1 \
        -command {
            catch {Window destroy .pgaw:Type}
        }

    grid $::Types::Win(page,composite).lename \
        -row 0 \
        -column 0 \
        -columnspan 2 \
        -sticky we
    grid $::Types::Win(page,composite).bboxmenu \
        -row 0 \
        -column 2 \
        -columnspan 3 \
        -sticky e
    grid $::Types::Win(page,composite).table \
        -row 1 \
        -column 0 \
        -rowspan 2 \
        -columnspan 3 \
        -sticky news
    grid $::Types::Win(page,composite).yscroll \
        -row 2 \
        -column 3 \
        -sticky swn
    grid $::Types::Win(page,composite).xscroll \
        -row 3 \
        -column 0 \
        -columnspan 3 \
        -sticky wen
    grid $::Types::Win(page,composite).bboxtable \
        -padx 5 \
        -ipadx 5 \
        -pady 20 \
        -ipady 20 \
        -row 2 \
        -column 4 \
        -sticky n

    grid columnconfigure $::Types::Win(page,composite) 1 \
        -weight 10
    grid columnconfigure $::Types::Win(page,composite) 2 \
        -weight 10
    grid rowconfigure $::Types::Win(page,composite) 2 \
        -weight 10


    #
    # basic page
    #

    Label $::Types::Win(page,base).lname \
        -text [intlmsg "Name (*)"]
    Entry $::Types::Win(page,base).ename \
        -textvariable ::Types::typename

    set bpitems [list]

    lappend bpitems [list linputfcn cbinputfcn]
    Label $::Types::Win(page,base).linputfcn \
        -text [intlmsg "Input Function (*)"]
    ComboBox $::Types::Win(page,base).cbinputfcn \
        -textvariable ::Types::inputfcn \
        -values [::Database::getFunctionsList] \
        -editable false

    lappend bpitems [list loutputfcn cboutputfcn]
    Label $::Types::Win(page,base).loutputfcn \
        -text [intlmsg "Output Function (*)"]
    ComboBox $::Types::Win(page,base).cboutputfcn \
        -textvariable ::Types::outputfcn \
        -values [::Database::getFunctionsList] \
        -editable false

    lappend bpitems [list lrecvfcn cbrecvfcn]
    Label $::Types::Win(page,base).lrecvfcn \
        -text [intlmsg "Receive Function"]
    ComboBox $::Types::Win(page,base).cbrecvfcn \
        -textvariable ::Types::recvfcn \
        -values [::Database::getFunctionsList] \
        -editable true

    lappend bpitems [list lsendfcn cbsendfcn]
    Label $::Types::Win(page,base).lsendfcn \
        -text [intlmsg "Send Function"]
    ComboBox $::Types::Win(page,base).cbsendfcn \
        -textvariable ::Types::sendfcn \
        -values [::Database::getFunctionsList] \
        -editable true

    lappend bpitems [list linternallength cbinternallength]
    Label $::Types::Win(page,base).linternallength \
        -text [intlmsg "Internal Length"]
    ComboBox $::Types::Win(page,base).cbinternallength \
        -textvariable ::Types::internallength \
        -text [intlmsg "VARIABLE"] \
        -values [list [intlmsg "VARIABLE"] 1 2 3 4 5 6 7 8 9 ...] \
        -editable true

    lappend bpitems [list lpassedby cbpassedby]
    Label $::Types::Win(page,base).lpassedby \
        -text [intlmsg "Passed By"]
    ComboBox $::Types::Win(page,base).cbpassedby \
        -textvariable ::Types::passedby \
        -text [intlmsg "REFERENCE"] \
        -values [list [intlmsg "VALUE"] [intlmsg "REFERENCE"]] \
        -editable false

    lappend bpitems [list lalignment cbalignment]
    Label $::Types::Win(page,base).lalignment \
        -text [intlmsg "Alignment"]
    ComboBox $::Types::Win(page,base).cbalignment \
        -textvariable ::Types::alignment \
        -text int4 \
        -values [list char int2 int4 double] \
        -editable false

    lappend bpitems [list lstorage cbstorage]
    Label $::Types::Win(page,base).lstorage \
        -text [intlmsg "Storage"]
    ComboBox $::Types::Win(page,base).cbstorage \
        -textvariable ::Types::storage \
        -text plain \
        -values [list plain external extended main] \
        -editable false

    lappend bpitems [list ldefaultval edefaultval]
    Label $::Types::Win(page,base).ldefaultval \
        -text [intlmsg "Default"]
    Entry $::Types::Win(page,base).edefaultval \
        -text NULL \
        -textvariable ::Types::defaultval

    lappend bpitems [list lelement eelement]
    Label $::Types::Win(page,base).lelement \
        -text [intlmsg "Element Types (if an array)"]
    Entry $::Types::Win(page,base).eelement \
        -textvariable ::Types::elementtypes

    lappend bpitems [list ldelim edelim]
    Label $::Types::Win(page,base).ldelim \
        -text [intlmsg "Delimiter"]
    Entry $::Types::Win(page,base).edelim \
        -text , \
        -textvariable ::Types::delimiter

    # some buttons to save and whatnot

    ButtonBox $::Types::Win(page,base).bboxmenu \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $::Types::Win(page,base).bboxmenu add \
        -relief link \
        -image ::icon::filesave-22 \
        -helptext [intlmsg "Save"] \
        -borderwidth 1 \
        -command {::Types::saveBaseType 0}
    $::Types::Win(page,base).bboxmenu add \
        -relief link \
        -image ::icon::filesaveas-22 \
        -helptext [intlmsg "Save As"] \
        -borderwidth 1 \
        -command {::Types::saveBaseType 1}
    $::Types::Win(page,base).bboxmenu add \
        -relief link \
        -image ::icon::help-22 \
        -helptext [intlmsg "Help"] \
        -borderwidth 1 \
        -command {::Help::load types}
    $::Types::Win(page,base).bboxmenu add \
        -relief link \
        -image ::icon::exit-22 \
        -helptext [intlmsg "Close"] \
        -borderwidth 1 \
        -command {
            catch {Window destroy .pgaw:Type}
        }

    grid $::Types::Win(page,base).lname \
        -row 0 \
        -column 0 \
        -columnspan 1 \
        -sticky e
    grid $::Types::Win(page,base).ename \
        -row 0 \
        -column 1 \
        -columnspan 1 \
        -sticky we
    grid $::Types::Win(page,base).bboxmenu \
        -row 0 \
        -column 2 \
        -columnspan 3 \
        -sticky e

    # i am so lazy
    set row 1
    foreach item $bpitems {
        set litem [lindex $item 0]
        set ritem [lindex $item 1]
        grid $::Types::Win(page,base).$litem \
            -row $row \
            -column 0 \
            -columnspan 1 \
            -sticky e \
            -pady 5
        grid $::Types::Win(page,base).$ritem \
            -row $row \
            -column 1 \
            -columnspan 1 \
            -sticky ew
        incr row
    }

    grid columnconfigure $::Types::Win(page,base) 1 \
        -weight 10
    grid columnconfigure $::Types::Win(page,base) 2 \
        -weight 10
    grid rowconfigure $::Types::Win(page,base) $row \
        -weight 10

    #
    # pseudo page
    #
    label $::Types::Win(page,pseudo).lbl \
        -text [intlmsg "Not yet implemented!  Should it be?  Hmmm."]
    pack $::Types::Win(page,pseudo).lbl

    # dont just show a blank screen
    $::Types::Win(notebook) raise $::Types::typetype

}; # end proc vTclWindow.pgaw:Type


