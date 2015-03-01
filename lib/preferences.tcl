#==========================================================
# Preferences --
#
#   user defined preferences and the dialog for changing them
#
#==========================================================
#
namespace eval Preferences {
    variable Win
}


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Preferences::load {} {

    global PgAcVar

    setDefaultFonts
    setGUIPreferences
    # Set some default values for preferences
    set PgAcVar(pref,erroremailserver) "localhost"
    set PgAcVar(pref,erroremailto) "support@pgaccess.org"
    set PgAcVar(pref,erroremailuse) 0
    set PgAcVar(pref,rows) 200
    set PgAcVar(pref,tvfont) clean
    set PgAcVar(pref,autoload) 1
    set PgAcVar(pref,systemtables) 0
    set PgAcVar(pref,pgaccesstables) 0
#    set PgAcVar(pref,lastdb) {}
#    set PgAcVar(pref,lasthost) localhost
#    set PgAcVar(pref,lastport) 5432
#    set PgAcVar(pref,username) {}
#    set PgAcVar(pref,password) {}
    set PgAcVar(pref,language) english
    set PgAcVar(pref,showtoolbar) 1
    #set retval [catch {set fid [open "~/.pgaccess/pgaccessrc" r]} errmsg]
    set file [file join $::env(HOME) .pgaccess pgaccessrc]
    set retval [catch {set fid [open "$file" r]} errmsg]
    if {! $retval} {
        #while {![eof $fid]} {
            #set pair [gets $fid]
            #set PgAcVar([lindex $pair 0]) [lindex $pair 1]
        #}
        array set PgAcVar [read $fid [file size $file]]
        close $fid
        setGUIPreferences
    }

    # The following preferences values will be ignored from the ~/.pgaccess/pgaccessrc file
    set PgAcVar(pref,typecolors) {black red brown #007e00 #004e00 blue orange yellow pink purple cyan  magenta lightblue lightgreen gray lightyellow}
    set PgAcVar(pref,typelist) {text bool bytea float8 float4 int4 char name int8 int2 int28 regproc oid tid xid cid}

    loadInternationalMessages

}; # end proc ::Preferences::load


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Preferences::save {} {

    global PgAcVar

    # check if we are saving passwords, if not, delete them
#    if {![info exists PgAcVar(pref,savepasswords)]} {
#        set PgAcVar(pref,savepasswords) 0
#    }
#    if {$PgAcVar(pref,savepasswords)==0} {
#        set PgAcVar(pref,lastpassword) {}
#    }

    catch {
        set fid [open "~/.pgaccess/pgaccessrc" w]
        foreach key [array names PgAcVar pref,*] { puts $fid "$key {$PgAcVar($key)}" }
        close $fid
    }
    if {$PgAcVar(activetab)=="Tables"} {
        Mainlib::tab_click Tables
    }

    ##
    ##  This is to globally affect the different connections
    ##  if the view system and view pgaccess tables flag
    ##  is turn on/off
    ##
    foreach C [::Connections::getIds] {
        if {[info exists ::Connections::Conn(viewsystem,$C)]} {
            set ::Connections::Conn(viewsystem,$C) $PgAcVar(pref,systemtables)
        }

        if {[info exists ::Connections::Conn(viewpgaccess,$C)]} {
            set ::Connections::Conn(viewpgaccess,$C) $PgAcVar(pref,pgaccesstables)
        }

    }
}; # end proc ::Preferences::save


#------------------------------------------------------------
# ::Preferences::initSave --
#
#    Does some checks before actually calling the save proc
#
# Arguments:
#    None
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc ::Preferences::initSave {} {

    global PgAcVar

    if {$PgAcVar(pref,rows)>200} {
        tk_messageBox \
        -title [intlmsg Warning] \
        -parent .pgaw:Preferences \
        -message [intlmsg "A big number of rows displayed in table view will take a lot of memory!"]

    }


    Preferences::changeLanguage
    Preferences::save
    Window destroy .pgaw:Preferences

    ::Mainlib::handleToolBar

    tk_messageBox \
    -title [intlmsg Warning] \
    -parent .pgaw:Main \
    -message [intlmsg "Changed fonts may appear in the next working session!"]

    return

}; # end proc initSave


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Preferences::configure {} {

    global PgAcVar
    variable Win

    Window show .pgaw:Preferences
    $Win(page,general).llb configure \
        -values [lsort $PgAcVar(AVAILABLE_LANGUAGES)]
    wm transient .pgaw:Preferences .pgaw:Main


    $Win(page,general).llb setvalue @[lsearch [lsort $PgAcVar(AVAILABLE_LANGUAGES)] $PgAcVar(pref,language)]

    return

}; # end proc ::Preferences::configure


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Preferences::loadInternationalMessages {} {

    global Messages PgAcVar

    set PgAcVar(AVAILABLE_LANGUAGES) {english}
    foreach filename [glob -nocomplain [file join $PgAcVar(PGACCESS_HOME) lib languages *]] {
        if {[file isfile $filename]} {
            lappend PgAcVar(AVAILABLE_LANGUAGES) [file tail $filename]
        }
    }
    catch { unset Messages }
    catch { source [file join $PgAcVar(PGACCESS_HOME) lib languages $PgAcVar(pref,language)] }

}; # end proc ::Preferences::loadInternationalMessages


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Preferences::changeLanguage {} {

    global PgAcVar
    variable Win

    set sel [$Win(page,general).llb getvalue]
    if {$sel==""} {return}
    set desired [lindex [lsort $PgAcVar(AVAILABLE_LANGUAGES)] $sel]
    if {($desired==$PgAcVar(pref,language)) || ($desired == "")} {return}
    set PgAcVar(pref,language) $desired
    loadInternationalMessages
    return
    foreach wid [winfo children .pgaw:Main] {
        set wtext {}
        catch { set wtext [$wid cget -text] }
        if {$wtext != ""} {
            $wid configure -text [intlmsg $wtext]
        }
    }
}; # end proc ::Preferences::changeLanguage


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Preferences::setDefaultFonts {} {

    global PgAcVar tcl_platform

    if {[string toupper $tcl_platform(platform)]=="WINDOWS"} {
        set PgAcVar(pref,font_normal) {"MS Sans Serif" 8}
        set PgAcVar(pref,font_bold) {"MS Sans Serif" 8 bold}
        set PgAcVar(pref,font_fix) {Terminal 8}
        set PgAcVar(pref,font_italic) {"MS Sans Serif" 8 italic}
    } else {
        set PgAcVar(pref,font_normal) {Helvetica 11}
        set PgAcVar(pref,font_bold) {Helvetica 11 bold}
        set PgAcVar(pref,font_italic) {Helvetica 11 italic}
        set PgAcVar(pref,font_fix) {Clean 11}
        #set PgAcVar(pref,font_normal) -Adobe-Helvetica-Medium-R-Normal-*-*-120-*-*-*-*-*
        #set PgAcVar(pref,font_bold) -Adobe-Helvetica-Bold-R-Normal-*-*-120-*-*-*-*-*
        #set PgAcVar(pref,font_italic) -Adobe-Helvetica-Medium-O-Normal-*-*-120-*-*-*-*-*
        #set PgAcVar(pref,font_fix) -*-Clean-Medium-R-Normal-*-*-130-*-*-*-*-*
    }

}; # end proc ::Preferences::setDefaultFonts


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Preferences::setGUIPreferences {} {

    global PgAcVar

    foreach wid {Label Text Button Listbox Checkbutton Radiobutton} {
        option add *$wid.font $PgAcVar(pref,font_normal)
    }
    option add *Entry.background #fefefe
    option add *Entry.foreground #000000
    option add *Entry.Font $PgAcVar(pref,font_normal)
    option add *Button.BorderWidth 1
}; # end proc ::Preferences::setGUIPreferences



################### END OF NAMESPACE PREFERENCES #################



#------------------------------------------------------------
# showFontDlg --
#
# Arguments:
#     win_        this is the button that invoke the dialog
#     fontvar_    the variable that holds the font
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc showFontDlg {win_ type_} {

    global PgAcVar

    if {[string match "" $PgAcVar(pref,font_$type_)]} {setDefaultFonts}
    set old $PgAcVar(pref,font_$type_)

    set font_ [SelectFont .fontdlg -font $PgAcVar(pref,font_$type_) -title "Select Font"]

    if {$font_ != ""} {
        $win_ configure -font $font_ -text $font_
        set PgAcVar(pref,font_$type_) $font_
    } else {
        $win_ configure -font $old -text $old
    }

    return $font_

}; # end proc showFontDlg



################### BEGIN VisualTcl CODE #################



#------------------------------------------------------------
# vTclWindow.pgaw:Preferences --
#
# Arguments:
#     base    the base window to build upon
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc vTclWindow.pgaw:Preferences {base {page general}} {

    if {$base == ""} {
        set base .pgaw:Preferences
    }
    if {[winfo exists $base]} {
        wm deiconify $base
        catch {$::Preferences::Win(notebook) raise $page}
        return
    }
    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 470x300+100+113
    wm maxsize $base 1009 738
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Preferences"]
    bind $base <Key-Escape> "Window destroy .pgaw:Preferences"

    set ::Preferences::Win(notebook) [NoteBook $base.nb]

    set ::Preferences::Win(page,general) \
        [$::Preferences::Win(notebook) insert end general -text [intlmsg General]]
    set ::Preferences::Win(page,lookfeel) \
        [$::Preferences::Win(notebook) insert end lookfeel -text [intlmsg "Look & Feel"]]
    #set ::Preferences::Win(page,misc) \
        [$::Preferences::Win(notebook) insert end misc -text [intlmsg "Misc"]]
    set ::Preferences::Win(page,errors) \
        [$::Preferences::Win(notebook) insert end errors -text [intlmsg "Error Handling"]]


    label $::Preferences::Win(page,general).l1 \
        -borderwidth 0 -relief raised \
        -text [intlmsg {Max rows displayed in table/query view}]

    SpinBox $::Preferences::Win(page,general).erows \
        -background #fefefe \
        -borderwidth 1 \
        -range [list 1 5000 1] \
        -textvariable PgAcVar(pref,rows) \
        -width 7

    ComboBox $::Preferences::Win(page,general).llb \
        -background #fefefe \
        -borderwidth 1

    label $::Preferences::Win(page,general).lprintcmd \
        -borderwidth 0 -relief raised -text [intlmsg {Default print command}]
    entry $::Preferences::Win(page,general).eprintcmd \
        -background #fefefe -borderwidth 1 -textvariable PgAcVar(pref,print_cmd) \
        -width 20 


    checkbutton $::Preferences::Win(page,general).tb \
        -borderwidth 1 \
        -text [intlmsg {Show Toolbar}] \
        -variable PgAcVar(pref,showtoolbar) \
        -anchor w

    checkbutton $::Preferences::Win(page,general).al \
        -borderwidth 1 \
        -text [intlmsg {Auto-load the last opened database(s) at startup}] \
        -variable PgAcVar(pref,autoload) \
        -anchor w

    checkbutton $::Preferences::Win(page,general).st \
            -borderwidth 1 \
            -text [intlmsg {View system tables}] \
            -variable PgAcVar(pref,systemtables) \
            -anchor w

        label $::Preferences::Win(page,general).warn1 \
        -text [intlmsg "NOTE: Affects All Connections"] \
            -foreground blue

        checkbutton $::Preferences::Win(page,general).pgat \
            -borderwidth 1 \
            -text [intlmsg {View PGAccess internal tables}] \
            -variable PgAcVar(pref,pgaccesstables) \
            -anchor w

        label $::Preferences::Win(page,general).warn2 \
        -text [intlmsg "NOTE: Affects All Connections"] \
            -foreground blue

    checkbutton $::Preferences::Win(page,general).sp \
        -borderwidth 1 \
        -text [intlmsg {Save passwords}] \
        -variable PgAcVar(pref,savepasswords) \
        -anchor w

    label $::Preferences::Win(page,general).warn3 \
        -text [intlmsg "WARNING!!! passwords are stored as plaintext"] \
        -foreground red

    label $::Preferences::Win(page,general).lt \
        -borderwidth 0 \
        -relief raised \
        -text [intlmsg {Preferred language}]


    label $::Preferences::Win(page,lookfeel).l \
        -borderwidth 0 -relief raised -text [intlmsg {Table viewer font}]
    label $::Preferences::Win(page,lookfeel).ls \
        -borderwidth 0 -relief raised -text {      } 
    radiobutton $::Preferences::Win(page,lookfeel).pgaw:rb1 \
        -borderwidth 1 -text [intlmsg {fixed width}] -value clean \
        -variable PgAcVar(pref,tvfont) 
    radiobutton $::Preferences::Win(page,lookfeel).pgaw:rb2 \
        -borderwidth 1 -text [intlmsg proportional] -value helv -variable PgAcVar(pref,tvfont) 


    set cnt 1
    foreach {F l} [list normal normal bold bold italic italic fixed fix] {
        label $::Preferences::Win(page,lookfeel).l$cnt \
            -borderwidth 0 \
            -relief raised \
            -text [intlmsg "Font $F"]
    
        button $::Preferences::Win(page,lookfeel).e$cnt \
            -command [list showFontDlg "$::Preferences::Win(page,lookfeel).e$cnt" $l] \
            -text $::PgAcVar(pref,font_$l)

        if {![string match "" $::PgAcVar(pref,font_$l)]} {
            $::Preferences::Win(page,lookfeel).e$cnt configure \
                -font $::PgAcVar(pref,font_$l)
        }

        incr cnt
    }

    button $base.btnsave \
        -command ::Preferences::initSave \
        -padx 9 \
        -pady 3 \
        -text [intlmsg Save]

    button $base.btncancel \
        -command {Window destroy .pgaw:Preferences} \
        -padx 9 \
        -pady 3 \
        -text [intlmsg Cancel]

        grid $::Preferences::Win(notebook) \
        -sticky news \
        -columnspan 2


    foreach {L E} [list l1 erows lt llb lprintcmd eprintcmd] {
        grid $::Preferences::Win(page,general).$L $::Preferences::Win(page,general).$E \
            -sticky w \
                -padx 2
    }

    foreach w [list tb al st warn1 pgat warn2  sp warn3] {
        grid $::Preferences::Win(page,general).$w \
            -sticky w \
            -columnspan 2
    }

    grid columnconfigure $base 0 -weight 1
    grid rowconfigure $base 0 -weight 1
    grid columnconfigure $base 1 -weight 1

    grid $::Preferences::Win(page,lookfeel).l $::Preferences::Win(page,lookfeel).pgaw:rb1 $::Preferences::Win(page,lookfeel).pgaw:rb2 \
        -sticky w

    grid $::Preferences::Win(page,lookfeel).l1 $::Preferences::Win(page,lookfeel).e1 \
        -sticky w
    grid $::Preferences::Win(page,lookfeel).l2 $::Preferences::Win(page,lookfeel).e2 \
        -sticky w
    grid $::Preferences::Win(page,lookfeel).l3 $::Preferences::Win(page,lookfeel).e3 \
        -sticky w
    grid $::Preferences::Win(page,lookfeel).l4 $::Preferences::Win(page,lookfeel).e4 \
        -sticky w

    foreach E {1 2 3 4} {
        grid configure $::Preferences::Win(page,lookfeel).e$E \
            -columnspan 2
    }

    checkbutton $::Preferences::Win(page,errors).cbemailuse \
        -borderwidth 1 \
        -text [intlmsg "Use email error reporting"] \
        -variable PgAcVar(pref,erroremailuse) \
        -anchor w
    LabelEntry $::Preferences::Win(page,errors).lemailto \
        -borderwidth 1 \
        -label [intlmsg "Email errors to:"] \
        -textvariable PgAcVar(pref,erroremailto)
    LabelEntry $::Preferences::Win(page,errors).lemailserver \
        -borderwidth 1 \
        -label [intlmsg "Email server:"] \
        -textvariable PgAcVar(pref,erroremailserver)

    foreach l {cbemailuse lemailto lemailserver} {
        grid configure $::Preferences::Win(page,errors).$l \
            -sticky w \
            -columnspan 2
    }

    grid $base.btnsave $base.btncancel \
        -sticky ew

    $::Preferences::Win(notebook) raise $page

    return

}; # end proc vTclWindow.pgaw:Preferences

