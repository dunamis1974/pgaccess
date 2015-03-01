#============================================================
#
#            Connections Namespace
#
#============================================================
#
namespace eval Connections {

    variable Conn
    variable Msg

    set Conn(last_id) 0

    variable smlogin 0

}; # end Connections namepace eval

#------------------------------------------------------------
# ::Connections::getIds --
#
#    Retrieves the known connection ids
#
# Arguments:
#    none
#
# Results
#    list of the attributes requested
#------------------------------------------------------------
#
proc ::Connections::getIds {{host_ *} {db_ *}} {

    variable Conn

    set host_ [string map {sockets ""} $host_]

    set res [list]
    foreach {k v} [array get Conn dbname,*] {
	foreach {t i} [split $k ,] {break}

        if {[string match "$host_" $Conn(host,$i)] && [string match "$db_" $Conn(dbname,$i)]} {
            lappend res $i
	}
    }

    if {[llength $res] != 1} {
        return $res
    } else {
        return [lindex $res 0]
    }

}; # end proc ::Connections::getIds

#------------------------------------------------------------
# ::Connections::getNextId --
#
#    Gets the next id in the id list
#
# Arguments:
#    none
#
# Results
#    The next available id
#------------------------------------------------------------
#
proc ::Connections::getNextId {} {

    variable Conn
    return [incr Conn(last_id)]

}; # end proc ::Connections::getNextId

#------------------------------------------------------------
# ::Connections::getDbs --
#
#    Retrieves the known connection dbnames
#
# Arguments:
#    none
#
# Results
#    list of the attributes requested
#------------------------------------------------------------
#
proc ::Connections::getDbs {{host_ "*"}} {

    variable Conn

    if {[string match "sockets" $host_]} {set host_ ""}

    set res [list]
    foreach i [getIds] {
        if {[string match "$host_" $Conn(host,$i)]} {
	    if {[lsearch $res $Conn(dbname,$i)] < 0} {

                lappend res $Conn(dbname,$i)
            }
        }
    }

    if {[llength $res] != 1} {
        return $res
    } else {
        return [lindex $res 0]
    }

}; # end proc ::Connections::getDbs

#------------------------------------------------------------
# ::Connections::getHosts --
#
#    Retrieves the known connection hosts
#
# Arguments:
#    none
#
# Results
#    list of hosts
#------------------------------------------------------------
#
proc ::Connections::getHosts {} {

    variable Conn

    set res [list]
    foreach i [getIds] {
        if {[lsearch $res $Conn(host,$i)] < 0} {
            lappend res $Conn(host,$i)
        }
    }

    if {[llength $res] != 1} {
        return $res
    } else {
        if {[string length [lindex $res 0]]==0} {
            return "sockets"
        } else {
            return [lindex $res 0]
        }
    }

}; # end proc ::Connections::getHosts


#------------------------------------------------------------
# ::Connections::getUsers --
#
#    Retrieves the known connection users
#
# Arguments:
#    none
#
# Results
#    list of the users
#------------------------------------------------------------
#
proc ::Connections::getUsers {{host_ "*"} {db_ *}} {

    variable Conn

    if {[string match "sockets" $host_]} {set host_ ""}

    set res [list]
    foreach i [getIds] {
        if {([string match "$host_" $Conn(host,$i)]) && ([string match "$db_" $Conn(dbname,$i)])} {
            if {[lsearch $res $Conn(username,$i)] < 0} {
                lappend res $Conn(username,$i)
            }
        }
    }

    if {[llength $res] != 1} {
        return $res
    } else {
        return [lindex $res 0]
    }

}; # end proc ::Connections::getUsers

#------------------------------------------------------------
# ::Connections::getHandles --
#
#    Retrieves the known db handles
#
# Arguments:
#    none
#
# Results
#    list of the handles
#------------------------------------------------------------
#
proc ::Connections::getHandles {{host_ "*"} {db_ *}} {

    variable Conn

    if {[string first ":" $host_] != -1 && [string match "\*" $db_]} {
        set db_ [lindex [split $host_ :] 1]
        set host_ [lindex [split $host_ :] 0]
    }

    if {[string match "sockets" $host_]} {set host_ ""}

    set res [list]
    foreach i [getIds] {
        if {([string match "$host_" $Conn(host,$i)]) && ([string match "$db_" $Conn(dbname,$i)])} {
            if {![info exists Conn(handle,$i)]} {
                continue
            }

            if {[lsearch $res $Conn(handle,$i)] < 0} {
                lappend res $Conn(handle,$i)
            }
        }
    }

    if {[llength $res] != 1} {
        return $res
    } else {
        return [lindex $res 0]
    }

}; # end proc ::Connections::getHandles


#------------------------------------------------------------
# ::Connections::load --
#
#    Loads the connection information from the connections
#    resource file, and calls open_data for each one
#
# Arguments:
#    none
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc ::Connections::load {} {

    global PgAcVar

    variable Conn

    if {$PgAcVar(PGACCESS_NOAUTO)} {
        return
    }

	set file $PgAcVar(PGACCESS_CONN)
###	set retval [catch {set fid [open "$file" r]} errmsg]
###
###	if {! $retval} {
###		array set Conn [read $fid [file size $file]]
###		close $fid
###	}

        if {[catch {set fid [open "$file" r]} errmsg]} {
             set Conn(last_id) 0
             return
        }

        array set Conn [read $fid [file size $file]]
        close $fid

        ##
	##  Get the last id number
	##
	set num 0
	foreach {k v} [array get Conn dbname,*] {

	   set i [lindex [split $k ,] 1]

           ##
           ##   We get rid of any entries
           ##   that don't have a dbname
           ##   also
           ##
           if {[string match "" $v]} {
             foreach {k v} [array get Conn *,$i] {
                unset Conn($k)
             }
           }

	   if {$i > $num} {set num $i}
	}
	set Conn(last_id) $num

    return

}; # end proc ::Connections::load


#------------------------------------------------------------
# ::Connections::save --
#
#    Saves the connection info to the file
#
# Arguments:
#    none
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc ::Connections::save {} {

    global PgAcVar

    variable Conn

	# if NOAUTO flag is set, skip saving the connection info
	if {$PgAcVar(PGACCESS_NOAUTO)} {return}

	set file $PgAcVar(PGACCESS_CONN)
	set retval [catch {set fid [open "$file" w]} errmsg]

	if {! $retval} {
            # dont save passwords if we are not told to do so
            if {![info exists PgAcVar(pref,savepasswords)]} {
                set PgAcVar(pref,savepasswords) 0
            }

            foreach id [getIds] {
                if {![info exists Conn(savepasswords,$id)]} {
                    set Conn(savepasswords,$id) $PgAcVar(pref,savepasswords)
                }

                if {$Conn(savepasswords,$id) == 0} {
                    set Conn(password,$id) ""
                }
            }

	    puts $fid [array get Conn]
	    close $fid
	}

	return
    
}; # end proc ::Connections::save

#------------------------------------------------------------
# ::Connections::check --
#
#    Checks the open/current db info to see if there
#    is an entry in the Conn array. This is for backwards
#    compatibility
#
# Arguments:
#    none
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc ::Connections::check {} {

    global PgAcVar CurrentDB
    variable Conn

    set create 0
    if {[lsearch [getDbs $PgAcVar(opendb,host)] $PgAcVar(opendb,dbname)] < 0} {
	   set id [getNextId]
	   set Conn(dbname,$id) $PgAcVar(opendb,dbname)
	   set Conn(host,$id) $PgAcVar(opendb,host)
	   set Conn(username,$id) $PgAcVar(opendb,username)
	   set Conn(password,$id) $PgAcVar(opendb,password)
	   set Conn(pgport,$id) $PgAcVar(opendb,pgport)
	   set Conn(handle,$id) $CurrentDB
    }

	return
}; # end proc ::Connections::check


#------------------------------------------------------------
# ::Connections::deleteInfo --
#
#    Deletes info about a connection, indexed by the id
#
# Arguments:
#    id_    the id for that connection
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc ::Connections::deleteInfo {id_} {

    variable Conn

    foreach {k v} [array get Conn *,${id_}] {
	    unset Conn($k)
    }

    return
}; # end proc ::Connections::deleteInfo

#------------------------------------------------------------
# ::Connections::getIdFromHandle --
#
#    This retrieves the connection id based on the
#    db handle, which should be unique
#
# Arguments:
#    dbh_    The db handle for the connection info. Defaults
#            to $CurrentDB if empty
#
# Results:
#    returns the id of the db handle
#------------------------------------------------------------
#
proc ::Connections::getIdFromHandle {{dbh_ ""}} {

    global CurrentDB
	variable Conn

    if {[string match "" $dbh_]} {
	    if {[string match "" $CurrentDB]} {
		    return ""
		} else {
		    set dbh_ $CurrentDB
		}
	}

    foreach {k v} [array get Conn handle,*] {
       if {[string match "$v" "$dbh_"]} {
	       return [lindex [split $k ,] 1]
	   }
	}
   
    return ""

}; # end proc ::Connections::getIdFromHandle


#----------------------------------------------------------
# ::Connections::openNewConn --
#
#   allows opening a connection with actual connection
#   string like params, for then wrapping around openConn
#
# Arguments:
#   host_       hostname of the cluster (localhost is default)
#   pgport_     port to connect on (5432 is default)
#   dbname_     name of database to connect to
#   username_   name of connecting user
#   password_   password of connecting user
#
# Returns:
#   nothing
#
# Results:
#   opens database
#----------------------------------------------------------
#
proc ::Connections::openNewConn {{host_ "localhost"} {pgport_ 5432} {dbname_ ""} {username_ ""} {password_ ""}} {

    global PgAcVar

    set PgAcVar(opendb,host) $host_
    set PgAcVar(opendb,pgport) $pgport_
    set PgAcVar(opendb,dbname) $dbname_
    set PgAcVar(opendb,username) $username_
    set PgAcVar(opendb,password) $password_

    openConn

}; # end proc ::Connections::openNewConn


#------------------------------------------------------------
# ::Connections::openConn --
#
#   Opens an existing db connection stored in the
#   connections file
#
# Arguments:
#   id_     The id of the connection
#   win_    optional, if 1 then show DB conn window
#   sm_     optional, if 1 then only show conn window
#           with items that were missing from command line
#   clr_    optional, if 1 then clear out the window items
# Results:
#   opens database
#------------------------------------------------------------
#
proc ::Connections::openConn {{id_ 0} {win_ 0} {sm_ 0} {clr_ 0}} {

    global PgAcVar CurrentDB
    variable Msg
    variable Conn
    variable smlogin

    set smlogin $sm_

    ::Preferences::load

    # hopefully this connection isnt bogus
    if { ![info exists Conn(host,$id_)] } {
        ::Connections::deleteInfo $id_
        set id_ 0
    }

    # if id_ is 0, its a new connection
    if {$id_==0} {
        set id_ [::Connections::getNextId]
        # there might not be cmd line params supplied so check here
        # probably only on pretty rare occasions, but just to be sure
        if {![info exists PgAcVar(opendb,host)] || $clr_} {
            set PgAcVar(opendb,host) "localhost"
        }
        if {![info exists PgAcVar(opendb,pgport)] || $clr_} {
            set PgAcVar(opendb,pgport) "5432"
        }
        if {![info exists PgAcVar(opendb,dbname)] || $clr_} {
            set PgAcVar(opendb,dbname) ""
        }
        if {![info exists PgAcVar(opendb,username)] || $clr_} {
            set PgAcVar(opendb,username) ""
        }
        if {![info exists PgAcVar(opendb,password)] || $clr_} {
            set PgAcVar(opendb,password) ""
        }

        # now lets see if this connection already has an id
        # if it does, we will clear it out before making a new one
        foreach H [::Connections::getHosts] {
            if {[string length $H]==0} {set H sockets}
            foreach D [::Connections::getDbs $H] {
                if {$H==$PgAcVar(opendb,host) && $D==$PgAcVar(opendb,dbname)} {
                    set ids [::Connections::getIds $H $D]
                    set id_ [lindex $ids 0]
                    if { [llength $ids] > 1 } {
                        foreach didi [lrange $ids 1 end] {
                            ::Connections::deleteInfo $didi
                        }
                    }
                    ::Connections::save
                    #::Connections::load
                }
            }
        }

        if {[string length $PgAcVar(opendb,dbname)]>0 && !$win_} {
            #set id_ [::Connections::getNextId]
            ::Connections::save
            #::Connections::load
        }

        set Conn(host,$id_) $PgAcVar(opendb,host)
        set Conn(pgport,$id_) $PgAcVar(opendb,pgport)
        set Conn(dbname,$id_) $PgAcVar(opendb,dbname)
        set Conn(username,$id_) $PgAcVar(opendb,username)
        set Conn(password,$id_) $PgAcVar(opendb,password)
    }

    # show window and wait for it to close
    if {$win_} {
        Window show .pgaw:OpenDB
        tkwait visibility .pgaw:OpenDB
        set PgAcVar(opendb,host) $Conn(host,$id_)
        set PgAcVar(opendb,pgport) $Conn(pgport,$id_)
        set PgAcVar(opendb,dbname) $Conn(dbname,$id_)
        set PgAcVar(opendb,username) $Conn(username,$id_)
        set PgAcVar(opendb,password) $Conn(password,$id_)
        if {[string match "sockets" $PgAcVar(opendb,host)]} {
            set PgAcVar(opendb,host) ""
        }
        wm transient .pgaw:OpenDB
        tkwait window .pgaw:OpenDB
        set Conn(host,$id_) $PgAcVar(opendb,host)
        set Conn(pgport,$id_) $PgAcVar(opendb,pgport)
        set Conn(dbname,$id_) $PgAcVar(opendb,dbname)
        set Conn(username,$id_) $PgAcVar(opendb,username)
        set Conn(password,$id_) $PgAcVar(opendb,password)
        return 1
    }

    setCursor CLOCK

    set Msg($id_) ""

    ##
    ##  If no dbname, then clear that connection, and 
    ##  return 0
    ##
    if {(![info exists Conn(dbname,$id_)]) || ([string match "" $Conn(dbname,$id_)])} {

        deleteInfo $id_
        set Msg($id_) "DB name is empty"
        return 0
    }

    set connstr ""

    if {$Conn(host,$id_)!=""} {
        append connstr " host=$Conn(host,$id_)"
    }
    if {$Conn(pgport,$id_)!=""} {
        append connstr " port=$Conn(pgport,$id_)"
    }
    if {$Conn(dbname,$id_)!=""} {
        append connstr " dbname=$Conn(dbname,$id_)"
    }
    if {$Conn(username,$id_)!=""} {
        append connstr " user=$Conn(username,$id_)"
    }
    if {$Conn(password,$id_)!=""} {
        append connstr " password=$Conn(password,$id_)"
    }

    set connres [catch {set newdbc [pg_connect -conninfo $connstr]} msg]


    ##
    ##  If connres, then something went wrong...
    ##
    if {$connres} {

        setCursor DEFAULT
        set m [intlmsg "Error trying to connect to database '$Conn(dbname,$id_)' \n\
            on host $Conn(host,$id_) \n\nPostgreSQL error message: $msg"]

        showError $m open_database

        set Msg($id_) "$m"
#        deleteInfo $id_

        return 0
    }

    $::Mainlib::Win(statuslabel) configure \
        -text "Loading $Conn(dbname,$id_) ..."
    set Conn(handle,$id_) $newdbc

    setCursor DEFAULT

    ##
    ##  This is to satisfy any autoexec scripts
    ##  that rely on these vars
    ##
    set CurrentDB $newdbc
    set PgAcVar(currentdb,host) $Conn(host,$id_)
    set PgAcVar(currentdb,dbname) $Conn(dbname,$id_)
    set PgAcVar(currentdb,pgport) $Conn(pgport,$id_)
    set PgAcVar(currentdb,username) $Conn(username,$id_)
    set PgAcVar(currentdb,password) $Conn(password,$id_)

    catch {Window destroy .pgaw:OpenDB}

    # create the PGA tables if necessary
    ::Mainlib::init_pga_tables $CurrentDB


    ##
    ##  Look for autoexec script, and check to see if we should run it
    ##
    if {![::Connections::autoexec $CurrentDB]} {
        return 0
    }

    ::Mainlib::addDbNode $PgAcVar(currentdb,host) $PgAcVar(currentdb,dbname)

    ::Connections::save

    $::Mainlib::Win(statuslabel) configure \
        -text ""

    # now open up the db and select the table node
    set honode "__host__-$PgAcVar(currentdb,host)"
    set dbnode "__db__-$PgAcVar(currentdb,host)-$PgAcVar(currentdb,dbname)"
    if {[$::Mainlib::Win(tree) exists $honode]} {
        $::Mainlib::Win(tree) opentree $honode 0
    }
    if {[$::Mainlib::Win(tree) exists $dbnode]} {
        $::Mainlib::Win(tree) opentree $dbnode 0
    }
    ::Mainlib::select 1 "$Conn(host,$id_)-$Conn(dbname,$id_)-Tables"

    return 1

}; # end ::Connections::openConn


#----------------------------------------------------------
# ::Connections::autoexec --
#
#   Handles running of the 'autoexec' Script upon
#   a successful database connection.
#
# Arguments:
#   dbh_    an optional database handle
#
# Results:
#    0    if there were errors
#    1    if there were no errors
#----------------------------------------------------------
#
proc ::Connections::autoexec {{dbh_ ""}} {

    global PgAcVar CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {$PgAcVar(PGACCESS_NOSCRIPT)} {
        return 1
    }

    set pgres [wpg_exec $dbh_ "
        SELECT relname
          FROM [::Database::qualifySysTable pg_class]
         WHERE relname='pga_scripts'"]
    if {[pg_result $pgres -numTuples]!=0} {
        if {[catch {
            wpg_select $dbh_ "
                SELECT *
                  FROM Pga_scripts
                 WHERE scriptname ~* '^autoexec$'" rec {
                eval $rec(scriptsource)
            }
        } gterrmsg]} {
            #deleteInfo [getIdFromHandle $id_]
            showError [intlmsg "There is a problem with this connection."]
            return 0
        }
    }
    catch {pg_result $pgres -clear}

    return 1

}; # end proc ::Connections::autoexec


#------------------------------------------------------------
# ::Connections::consistCheck --
#
#    This checks the Conn array, and makes sure the
#    data is consistant. If not, then it removes
#    it from the array
#
# Arguments:
#    none
#
# Results:
#    0    if there were errors
#    1    if there were no errors
#------------------------------------------------------------
#
proc ::Connections::consistCheck {} {
}; # end proc ::Connections::consistCheck


#----------------------------------------------------------
# ::Connections::getConnectionsList --
#
#   Create a colon separated, host:database pair of connections.
#   And stick them in a local variable.
#
# Arguments:
#   none
#
# Results:
#   a list of connections
#----------------------------------------------------------
#
proc ::Connections::getConnectionsList {} {

    variable connlist

    foreach H [::Connections::getHosts] {
        if {[string match "" $H]} {set H sockets}
        foreach D [::Connections::getDbs $H] {
            lappend connlist "$H:$D"
        }
    }

    return $connlist

}; # end proc ::Connections::getConnectionsList


#------------------------------------------------------------
# vTclWindow.pgaw:OpenDB --
#
#    Window that prompts to open a database connection
#
# Arguments:
#    base     the base window
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc vTclWindow.pgaw:OpenDB {base} {
global PgAcVar
variable ::Connections::smlogin

	if {$base == ""} {
		set base .pgaw:OpenDB
	}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	toplevel $base -class Toplevel
	wm focusmodel $base passive
	wm overrideredirect $base 0
	wm resizable $base 0 0
	wm deiconify $base
	wm title $base [intlmsg "Open database"]

	frame $base.f1 \
		-borderwidth 2

	label $base.f1.l1 \
             -font $PgAcVar(pref,font_normal) \
		-borderwidth 0 \
		-relief raised \
		-text "[intlmsg Host]: "

    set Win(hostname) [ComboBox $base.f1.e1 \
             -font $PgAcVar(pref,font_normal) \
	    -background #fefefe \
		-borderwidth 1 \
		-width 40]

    $Win(hostname) configure \
	    -textvariable PgAcVar(opendb,host) \
	    -values [::Connections::getHosts]

    $base.f1.e1 bind <Key-KP_Enter> {focus .pgaw:OpenDB.f1.e2}
    $base.f1.e1 bind <Key-Return> {focus .pgaw:OpenDB.f1.e2}

	label $base.f1.l2 \
             -font $PgAcVar(pref,font_normal) \
		-borderwidth 0 -relief raised -text "[intlmsg Port]: "

	SpinBox $base.f1.e2 \
             -font $PgAcVar(pref,font_normal) \
	    -background #fefefe \
		-borderwidth 1 \
		-textvariable PgAcVar(opendb,pgport) \
		-range [list 0 65535 1] \
		-width 40

    $base.f1.e2 bind <Key-Return> {focus .pgaw:OpenDB.f1.e3}

	label $base.f1.l3 \
             -font $PgAcVar(pref,font_normal) \
		-borderwidth 0 -relief raised -text "[intlmsg Database]: "
    ComboBox $base.f1.e3 \
             -font $PgAcVar(pref,font_normal) \
            -background #fefefe \
            -borderwidth 1 \
            -textvariable PgAcVar(opendb,dbname) \
            -width 40 \
            -values [join [::Database::getDatabasesList]]
	bind $base.f1.e3 <Key-Return> {
		focus .pgaw:OpenDB.f1.e4
	}
	label $base.f1.l4 \
             -font $PgAcVar(pref,font_normal) \
		-borderwidth 0 -relief raised -text "[intlmsg Username]: "
	entry $base.f1.e4 \
             -font $PgAcVar(pref,font_normal) \
		-background #fefefe -borderwidth 1 -textvariable PgAcVar(opendb,username) \
		-width 40 
	bind $base.f1.e4 <Key-Return> {
		focus .pgaw:OpenDB.f1.e5
	}
	label $base.f1.l5 \
		-borderwidth 0 -relief raised -text "[intlmsg Password]: " \
             -font $PgAcVar(pref,font_normal)
	entry $base.f1.e5 \
		-background #fefefe -borderwidth 1 -show * -textvariable PgAcVar(opendb,password) \
             -font $PgAcVar(pref,font_normal) \
		-width 40 

	bind $base.f1.e5 <Key-Return> {
		focus .pgaw:OpenDB.fb.btnopen
	}
	frame $base.fb \
		-relief groove
	button $base.fb.btnopen \
        -borderwidth 1 \
        -command {::Connections::openConn 0 0 0} \
        -padx 9 \
        -pady 3 -text [intlmsg Open]
	button $base.fb.btnhelp \
		-borderwidth 1 -command {Help::load open_database} \
		-padx 9 -pady 3 -text [intlmsg Help]
	button $base.fb.btncancel \
		-borderwidth 1 -command {
            # if they cancel and the main window is open, we need to exit
            if {$PgAcVar(PGACCESS_HIDDEN)} {
                exit 0
            } else {
                Window hide .pgaw:OpenDB
            }
         } \
		-padx 9 -pady 3 -text [intlmsg Cancel]

	pack $base.fb \
		-side bottom
	grid $base.fb.btnopen \
		-in .pgaw:OpenDB.fb -column 0 -row 0 -padx 2 
	grid $base.fb.btnhelp \
		-in .pgaw:OpenDB.fb -column 1 -row 0 -padx 2 
	grid $base.fb.btncancel \
		-in .pgaw:OpenDB.fb -column 2 -row 0 -padx 2 

	pack $base.f1 \
		-side top	-fill both -expand 1 

    set focuson ""

    if {!$smlogin || $PgAcVar(opendb,host)==""} {
        if {[string length $focuson]==0} {
            set focuson $base.f1.e1
        }
		grid $base.f1.l1 \
			-in .pgaw:OpenDB.f1 -column 0 -row 0 -sticky e
		grid $base.f1.e1 \
			-in .pgaw:OpenDB.f1 -column 1 -row 0 -pady 2 -sticky w
    }
    if {!$smlogin || $PgAcVar(opendb,pgport)==""} {
        if {[string length $focuson]==0} {
            set focuson $base.f1.e2
        }
		grid $base.f1.l2 \
			-in .pgaw:OpenDB.f1 -column 0 -row 1 -sticky e 
		grid $base.f1.e2 \
			-in .pgaw:OpenDB.f1 -column 1 -row 1 -pady 2 -sticky w 
    }
    if {!$smlogin || $PgAcVar(opendb,dbname)==""} {
        if {[string length $focuson]==0} {
            set focuson $base.f1.e3
        }
		grid $base.f1.l3 \
			-in .pgaw:OpenDB.f1 -column 0 -row 2 -sticky e 
		grid $base.f1.e3 \
			-in .pgaw:OpenDB.f1 -column 1 -row 2 -pady 2 -sticky w
    }
    if {!$smlogin || $PgAcVar(opendb,username)==""} {
        if {[string length $focuson]==0} {
            set focuson $base.f1.e4
        }
		grid $base.f1.l4 \
			-in .pgaw:OpenDB.f1 -column 0 -row 3 -sticky e 
		grid $base.f1.e4 \
			-in .pgaw:OpenDB.f1 -column 1 -row 3 -pady 2 -sticky w
    }
    if {!$smlogin || $PgAcVar(opendb,password)==""} {
        if {[string length $focuson]==0} {
            set focuson $base.f1.e5
        }
		grid $base.f1.l5 \
			-in .pgaw:OpenDB.f1 -column 0 -row 4 -sticky e
		grid $base.f1.e5 \
			-in .pgaw:OpenDB.f1 -column 1 -row 4 -pady 2 -sticky w
    }

    if {$smlogin && [string length $focuson]>0} {
        focus $focuson
    }

}


