#==========================================================
# Mainlib --
#
#    main procedures that build the main GUI
#
#==========================================================
#
namespace eval Mainlib {

    variable _base64
    variable Win
    variable boolean
	variable img

    array set boolean {t yes f no true yes false no T yes F no}
    
    set _base64(si_grid) {
    R0lGODlhDwAOAPcAAAAAAAAA/4QAAISEhKX/KcbGxv//////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    /////////////////////////////////yH5BAEAAAQALAAAAAAPAA4AAAhbAAkIHDgQAACC
    CAUaHDDgYEICCxk2TBiRoYECBhxCBBAggMUCAgRkVNjxowGRJ0cCMIlRQMuREA1clNlSJMaD
    K2nOnHlToU6eGTXmBGqQos6iD3MifahQY8KAAAA7
    }
    set _base64(si_drive4) {
    R0lGODlhDwAOAPcAAAAAAISEhMbGxv8pzv//AP//////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    /////////////////////////////////yH5BAEAAAMALAAAAAAPAA4AAAhhAAcIHACgoEEA
    AwcWFECAIYGHBRU2nOjQIUIAFCc+3EhgYUaNGw0yHMkRYsGOGEuiXBnSZEqUKQXILCAz5MmT
    AgrQbHjzZUeXIQk+lJmzJkSFGHPuFBAx4YAAAAJAbSowIAA7
    }
    set _base64(si_drive3) {
    R0lGODlhEAAJAPcAAAAAAAAInACEAADOAHNzc5SUlJycnLW1tcbGxtbW1t7e3v//////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    /////////////////////////////////yH5BAEAAAEALAAAAAAQAAkAAAhKAAMEIECwoMGC
    AgkcWMiw4UICAAgsmEix4kQDEAkkQMCxI4IDAwQcKJBRwQGPHxuSjKjg4MGRGRNYtAgzosub
    AAQC2MmzJ0+BAQEAOw==
    }
    
    set _base64(si_sql) {R0lGODlhEAAWAPcAAAAAAAgICBgYGDEhMTExMTk5OUJCQkoY/0pKSlJSUlpa
    WmNjY2tra3Nzc3t7e4SEhIyMjIyU3pSUlJycnKWlpa2trbW1tb29vcbGxs7O
    zt7e3ufn5+/v7/f39///////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    /////////////////////yH5BAEAAAcALAAAAAAQABYAAAiMAA8IHEiwoMGD
    CAEoXAjgoEIMESBGmKiQIICIGCVKbHjgIsSPE0NS7AhSo8gIDR9mPIkyZUuW
    L12GvNiSJsqONDHo9KBzpkuFET3wjAhUJkWKQEd2nKgTA0+JNwcCdToUQ0WD
    DwA8yHoVodeBVq+KLTjAosCUBsd2XOtwLQAMbKU+FBgAg4ADAvLeDQgAOw==}
    
    
    set _base64(online:rx) {R0lGODlhEAAPAPcAAAAAAAD//yEA1oSEhMbGxv8ICP//////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    /////////////////////yH5BAEAAAIALAAAAAAQAA8AAAhlAAUIHChggMGD
    AwgSHACgoUMCABQKZBjAwMOIExEatNgQ4kSHFy9+NBCgZACIIgsCIGkS4kGP
    Kk2WhEigJkyKMlGC/KiRpkECDAvaHApAY0SGIJM6LGhg6M+gCzUixEhQ6VKF
    AQEAOw==}

	set img(Tables) [image create photo -data $::Mainlib::_base64(si_grid)]
	set img(Queries) ::icon::misc-16
	set img(Views) ::icon::thumbnail-16
	set img(Sequences) ::icon::queue-16
	set img(Functions) ::icon::completion-16
	set img(Reports) ::icon::txt-16
	set img(Graphs) ::icon::editcut-16
	set img(Forms) ::icon::widget_doc-16
	set img(Images) ::icon::kpresenter-16
	set img(Scripts) ::icon::shellscript-16
	set img(Usergroups) ::icon::people-16
	set img(Diagrams) ::icon::desktop_flat-16
	set img(Types) ::icon::blockdevice-16
	set img(Domains) ::icon::kcmprocessor-16
	set img(Triggers) ::icon::package_games1-16
	set img(Aggregates) ::icon::view_sidetree-16
	set img(Casts) ::icon::remote-16
	set img(Conversions) ::icon::earth-16
	set img(Indexes) ::icon::info-16
	set img(Languages) ::icon::contents2-16
	set img(Operators) ::icon::kteatime-16
	set img(Operatorclasses) ::icon::source_java-16
	set img(Rules) ::icon::penguin-16

}; # end namespace Mainlib

#----------------------------------------------------------
# ::Mainlib::tab_click --
#
#    This is used to invoke a tab. This was changed for the
#    the interface to instead select a node in the tree
#
# Arguments:
#    tabname_    The name of the tab
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::tab_click {tabname_} {

    global PgAcVar CurrentDB
    variable Win

    set deslist $PgAcVar(tablist)

    #set w .pgaw:Main.tab$tabname
    if {$CurrentDB==""} return;
    set curtab $tabname_
    #if {$PgAcVar(activetab)==$curtab} return;
    set PgAcVar(activetab) $curtab

    # Tabs where button Design is enabled
    if {[lsearch $deslist $PgAcVar(activetab)]!=-1} {
        if {[string match "" $PgAcVar(currentdb,host)]} {
            #set PgAcVar(currentdb,host) sockets
            set PgAcVar(currentdb,host) ""
        }

        set node ${PgAcVar(currentdb,host)}-${PgAcVar(currentdb,dbname)}-${curtab}
        if {[$Win(tree) exists $node]} {
            $Win(tree) selection set $node
                  #.pgaw:Main.btndesign configure -state normal
            set PgAcVar(activetab) $tabname_
        }
    }
           	#.pgaw:Main.lb delete 0 end
	          #cmd_$curtab

    return
}; # end proc ::Mainlib::tab_click


#----------------------------------------------------------
# ::Mainlib::cmd_Delete --
#
#    Handles the Delete button when clicked
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Delete {} {
    global PgAcVar CurrentDB

    if {$CurrentDB==""} return;
    set objtodelete [get_dwlb_Selection]
    if {$objtodelete==""} {
        showError [intlmsg "Please select an object first!"]
        return;
    }

    if {[lsearch $PgAcVar(tablist) $PgAcVar(activetab)] == -1} {
        return
    }

    set delmsg [format [intlmsg "You are going to delete\n\n %s \n\nProceed?"] $objtodelete]

    if {[tk_messageBox \
             -title [intlmsg "FINAL WARNING"] \
             -parent . \
             -message $delmsg \
             -type yesno \
             -default no]=="no"} { return }

    switch $PgAcVar(activetab) {
		Tables {
			sql_exec noquiet "DROP TABLE [::Database::quoteObject $objtodelete]"
			sql_exec quiet "DELETE FROM pga_layout WHERE tablename='$objtodelete'"
			cmd_Tables
		}
		Diagrams {
			sql_exec quiet "DELETE FROM pga_diagrams WHERE diagramname='$objtodelete'"
			cmd_Diagrams
		}
		Views {
			sql_exec noquiet "DROP VIEW [::Database::quoteObject $objtodelete]"
			sql_exec quiet "DELETE FROM pga_layout WHERE tablename='$objtodelete'"
			cmd_Views
		}
		Queries {
			sql_exec quiet "DELETE FROM pga_queries WHERE queryname='$objtodelete'"
			sql_exec quiet "DELETE FROM pga_layout WHERE tablename='$objtodelete'"
			cmd_Queries
		}
		Scripts {
			sql_exec quiet "DELETE FROM pga_scripts WHERE scriptname='$objtodelete'"
			cmd_Scripts
		}
		Forms {
			sql_exec quiet "DELETE FROM pga_forms WHERE formname='$objtodelete'"
			cmd_Forms
		}
		Images {
			sql_exec quiet "DELETE FROM pga_images WHERE imagename='$objtodelete'"
			cmd_Images
		}
		Sequences {
			sql_exec quiet "DROP SEQUENCE [::Database::quoteObject $objtodelete]"
			cmd_Sequences
		}
		Functions {
			delete_function $objtodelete
			cmd_Functions
		}
		Reports {
			sql_exec noquiet "DELETE FROM pga_reports WHERE reportname='$objtodelete'"
			cmd_Reports
		}
		Graphs {
			sql_exec noquiet "DELETE FROM pga_graphs WHERE graphname='$objtodelete'"
			cmd_Graphs
		}
		Usergroups {
			sql_exec noquiet "DROP USER \"$objtodelete\""
			cmd_Usergroups
		}
		Types {
			sql_exec noquiet "DROP TYPE \"$objtodelete\""
			cmd_Types
		}
		Domains {
			sql_exec noquiet "DROP DOMAIN \"$objtodelete\""
			cmd_Domains
		}
		Triggers {
			sql_exec noquiet "DROP TRIGGER \"$objtodelete\""
			cmd_Triggers
		}
		Indexes {
			sql_exec noquiet "DROP INDEX \"$objtodelete\""
			cmd_Indexes
		}
		Rules {
			sql_exec noquiet "DROP RULE \"$objtodelete\""
			cmd_Rules
		}
		Languages {
			sql_exec noquiet "DROP LANGUAGE \"$objtodelete\""
			cmd_Languages
		}
		Casts {
			sql_exec noquiet "DROP CAST \"$objtodelete\""
			cmd_Casts
		}
		Operatorclasses {
			sql_exec noquiet "DROP OPERATOR CLASS \"$objtodelete\""
			cmd_Operatorclasses
		}
		Operators {
			sql_exec noquiet "DROP OPERATOR \"$objtodelete\""
			cmd_Operators
		}
		Aggregates {
			sql_exec noquiet "DROP AGGREGATE \"$objtodelete\""
			cmd_Aggregates
		}
		Conversions {
			sql_exec noquiet "DROP CONVERSION \"$objtodelete\""
			cmd_Conversions
		}
    }; # end switch
}

#------------------------------------------------------------
# ::Mainlib::cmd_Design --
#
#    Handles the Design tab when click
#
# Arguments:
#    none
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc ::Mainlib::cmd_Design {} {
    global PgAcVar CurrentDB
    variable Win

    #if {$CurrentDB==""} return;
    #if {[$Win(mclist) curselection]==""} return;
    set objname [get_dwlb_Selection]
    #set objname [$Win(mclist) get [$Win(mclist) curselection]]
    set tablename $objname

    if {$objname==""} {
        showError [intlmsg "Please select an object first!"]
        return;
    }

    $PgAcVar(activetab)::design $objname

}

#----------------------------------------------------------
# ::Mainlib::cmd_Forms --
#
#     Handles when the Forms section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Forms {} {

    global CurrentDB
    variable Win

    set sql "
        SELECT formname
          FROM Pga_forms
      ORDER BY formname"

    setCursor CLOCK

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns [list 0 [intlmsg Name] left]

    catch {
	wpg_select $CurrentDB "$sql" rec {
		$Win(mclist) insert end [list $rec(formname)]
	}
    }

    setCursor DEFAULT
    
    return
}


#----------------------------------------------------------
# ::Mainlib::cmd_Functions --
#
#     Handles when the Functions section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Functions {} {

    global PgAcVar CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(pgversion,$id)]} {
        set Connections::Conn(pgversion,$id) \
            [::Database::getPgVersion $CurrentDB]
    }

    if {[string match "" $VER]} {
        showError [intlmsg "Could not find PG Version of the database"]
        return
    }

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    setCursor CLOCK

    set sql [::Database::getFunctionsList $CurrentDB $pg 1 1]

    set cols [list]

    if {$VER>7.3} {
        lappend cols 0 [intlmsg Schema]
    }

    lappend cols 0 [intlmsg Name] left 0 [intlmsg Returns] left 0 [intlmsg Owner] left 0 [intlmsg Language] left

    $Win(mclist) configure \
        -columns $cols

    $Win(mclist) delete 0 end

    catch {
        if {$VER>7.3} {
            wpg_select $CurrentDB "$sql" rec {
                $Win(mclist) insert end [list $rec(nspname) $rec(proname) [Database::getPgType $rec(prorettype)] $rec(usename) $rec(lanname)]
            }
        } else {
            wpg_select $CurrentDB "$sql" rec {
                $Win(mclist) insert end [list $rec(proname) [Database::getPgType $rec(prorettype)] $rec(usename) $rec(lanname)]
            }
        }
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Functions



#	set PgAcVar(currentdb,host) $PgAcVar(opendb,host)
#	set PgAcVar(currentdb,pgport) $PgAcVar(opendb,pgport)
#	set PgAcVar(currentdb,dbname) $PgAcVar(opendb,dbname)
#	set PgAcVar(currentdb,username) $PgAcVar(opendb,username)
#	set PgAcVar(currentdb,password) $PgAcVar(opendb,password)
#	set PgAcVar(statusline,dbname) $PgAcVar(currentdb,dbname)


#----------------------------------------------------------
# ::Mainlib::cmd_Dump --
#
#     Handles the db dump function
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Dump {type} {

    global PgAcVar CurrentDB
	set host $PgAcVar(currentdb,host)
	if {$host == ""} {
		showError [intlmsg {No database selected}]
		return
	}
	set dbname $PgAcVar(currentdb,dbname)
	if {$dbname == ""} {
		showError [intlmsg {No database selected}]
		return
	}
	set pgport $PgAcVar(currentdb,pgport)
	set username $PgAcVar(currentdb,username)
	set password $PgAcVar(currentdb,password)

	if {$host == "sockets"} {
		set host "localhost"
	}

	switch $type {
		"text" {
			set defaultextension ".sql"
			set initialdir "~"
			set initialfile "dump.sql"
			set title [intlmsg {Dump database (text)}]
		}
		"binary" {
			set defaultextension ".bsql"
			set initialdir "~"
			set initialfile "dump.bsql"
			set title [intlmsg {Dump database (binary)}]
		}
	}

	set FileName [tk_getSaveFile \
		-defaultextension $defaultextension \
		-initialdir $initialdir \
		-initialfile $initialfile \
		-title  $title \
		-parent ".pgaw:Main" \
	]

    if {$FileName != ""} {

        # lets build the connection listing so we can ignore params not given
        set connlist "/usr/bin/pg_dump"
        lappend connlist "-f" $FileName
        if {$host!=""} {lappend connlist "-h" $host}
        if {$pgport!=""} {lappend connlist "-p" $pgport}
        if {$username!=""} {lappend connlist "-U" $username}

        switch $type {
            "text" {
                lappend connlist "-i" $dbname
            }
            "binary" {
                lappend connlist "-i" "-b" "-Fc" $dbname
            }
        }

        if {[catch {eval exec [split $connlist]}]} {
            showError [intlmsg "Dump failed, possible bad connection parameters.  If a password is required, you will have to dump from the command line."]
        }

    } else {
        showError [intlmsg "You must supply a file name for the dump."]
    }

    return

}; # end proc ::Mainlib::cmd_Dump

proc ::Mainlib::cmd_New {} {
global PgAcVar CurrentDB
if {$CurrentDB==""} return;

    $PgAcVar(activetab)::new

}


proc ::Mainlib::cmd_Open {} {
global PgAcVar CurrentDB

    variable Win

	if {$CurrentDB==""} return;

	set objname [get_dwlb_Selection]
    if {$objname==""} {
        showError [intlmsg "Please select an object first!"]
        return;
    }

    $PgAcVar(activetab)::open $objname

}



#----------------------------------------------------------
# ::Mainlib::cmd_Queries --
#
#     Handles when the Queries section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Queries {} {

    global CurrentDB
    variable Win

    set sql "
      SELECT queryname, querytype, querytables, querycomments
        FROM pga_queries
        ORDER BY queryname"

    set cols [list 0 [intlmsg Name] left 0 [intlmsg Type] left]
    lappend cols 0 [intlmsg Tables] left 0 [intlmsg Comments] left

    $Win(mclist) configure \
        -columns $cols

    $Win(mclist) delete 0 end

    wpg_select $CurrentDB "$sql" r {
        $Win(mclist) insert end \
        [list $r(queryname) $r(querytype) $r(querytables) $r(querycomments)]
    }

    return
}; # end proc ::Mainlib::cmd_Queries


#----------------------------------------------------------
# ::Mainlib::cmd_Rename --
#
#     Handles when the Rename section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Rename {} {

    global PgAcVar CurrentDB

	if {$CurrentDB==""} return;

	if {[lsearch {Tables Queries Views Functions Sequences Reports Graphs Forms Images Scripts Diagrams} $PgAcVar(activetab)]==-1} {
            return
        }

	set temp [get_dwlb_Selection]
	if {$temp==""} {
        showError [intlmsg "Please select an object first!"]
		return;
	}
	set PgAcVar(Old_Object_Name) $temp
    set PgAcVar(New_Object_Name) $PgAcVar(Old_Object_Name)
	Window show .pgaw:RenameObject
	wm transient .pgaw:RenameObject

    return

}; # end proc ::Mainlib::cmd_Rename


# allows for copying certain items
proc ::Mainlib::cmd_Copy {} {
global PgAcVar CurrentDB
	if {$CurrentDB==""} return;
	if {[lsearch {Queries Reports Graphs Forms Images Scripts Diagrams Functions Tables Sequences Views} $PgAcVar(activetab)]==-1} {
		showError [intlmsg "You can't copy $PgAcVar(activetab) yet."]
		return;
	}
	set temp [get_dwlb_Selection]
	if {$temp==""} {
		showError [intlmsg "Please select an object first!"]
		return;
	}
	set PgAcVar(Old_Object_Name) $temp
    set PgAcVar(New_Object_Name) $PgAcVar(Old_Object_Name)

    set PgAcVar(Connections_List) [list]
    foreach H [::Connections::getHosts] {
        if {[string match "" $H]} {set H sockets}
        foreach D [::Connections::getDbs $H] {
            lappend PgAcVar(Connections_List) "$H:$D"
        }
    }

    if {![info exists PgAcVar(Copy_To_Connection)]} {
        set PgAcVar(Copy_To_Connection) [lindex $PgAcVar(Connections_List) 0]
    }

    Window show .pgaw:CopyObject
    wm transient .pgaw:CopyObject .pgaw:Main
}


#----------------------------------------------------------
# ::Mainlib::cmd_Reports --
#
#     Handles when the Reports section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Reports {} {

    global CurrentDB
    variable Win

    set sql "
        SELECT reportname,reportsource
          FROM Pga_reports
      ORDER BY reportname"

    setCursor CLOCK

    set cols [list 0 [intlmsg Name] left 0 [intlmsg Source] left]

    $Win(mclist) configure \
        -columns $cols

    $Win(mclist) delete 0 end

    catch {
	wpg_select $CurrentDB "$sql" rec {
	    $Win(mclist) insert end [list $rec(reportname) $rec(reportsource)]
	}
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Reports


#----------------------------------------------------------
# ::Mainlib::cmd_Graphs --
#
#     Handles when the Graphs section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Graphs {} {

    global CurrentDB
    variable Win

    set sql "
        SELECT graphname,graphsource
          FROM Pga_graphs
      ORDER BY graphname"

    setCursor CLOCK

    set cols [list 0 [intlmsg Name] left 0 [intlmsg Source] left]

    $Win(mclist) configure \
        -columns $cols

    $Win(mclist) delete 0 end

    catch {
	wpg_select $CurrentDB "$sql" rec {
	    $Win(mclist) insert end [list $rec(graphname) $rec(graphsource)]
	}
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Graphs


#----------------------------------------------------------
# ::Mainlib::cmd_Usergroups --
#
#     Handles when the Usergroups section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Usergroups {} {

    global CurrentDB
    variable Win
    variable boolean

    set cols [list 0 [intlmsg Name] left 0 [intlmsg Id] left 0 [intlmsg "Create DB?"] left 0 [intlmsg "Super?"] left]

    set sql "
        SELECT usename,usesysid,usecreatedb,usesuper
          FROM [::Database::qualifySysTable pg_user]
      ORDER BY usename"

    setCursor CLOCK

    $Win(mclist) configure \
        -columns $cols

    $Win(mclist) delete 0 end

    catch {
        wpg_select $CurrentDB "$sql" r {
            $Win(mclist) insert end [list $r(usename) $r(usesysid) $boolean($r(usecreatedb)) $boolean($r(usesuper))]
        }
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Usergroups


#----------------------------------------------------------
# ::Mainlib::cmd_Scripts --
#
#     Handles when the Scripts section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Scripts {} {

    global CurrentDB
    variable Win

    set sql "
        SELECT scriptname 
          FROM Pga_scripts 
      ORDER BY scriptname"

    setCursor CLOCK

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns [list 0 [intlmsg Name] left]


    catch {
	wpg_select $CurrentDB "$sql" rec {
            $Win(mclist) insert end [list $rec(scriptname)]
	}
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Scripts

#----------------------------------------------------------
# ::Mainlib::cmd_Images --
#
#     Handles when the Images section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Images {} {

    global CurrentDB
    variable Win

    set sql "
        SELECT imagename 
          FROM Pga_images 
      ORDER BY imagename"

    setCursor CLOCK

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns [list 0 [intlmsg Name] left]


    catch {
	wpg_select $CurrentDB "$sql" rec {
            $Win(mclist) insert end [list $rec(imagename)]
	}
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Images


#----------------------------------------------------------
# ::Mainlib::cmd_Sequences --
#
#     Handles when the Sequences section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Sequences {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(pgversion,$id)]} {
        set Connections::Conn(pgversion,$id) \
            [::Database::getPgVersion $CurrentDB]
    }

    if {[string match "" $VER]} {
        showError [intlmsg "Could not find PG Version of the database"]
        return
    }

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set sql [::Database::getSequencesList $CurrentDB $pg 1 1]

    setCursor CLOCK

    set cols [list]
    if {$VER>=7.3} {
        lappend cols 0 [intlmsg Schema] left
    }
    lappend cols 0 [intlmsg Name] left 0 [intlmsg Owner] left 0 [intlmsg OID] left

    $Win(mclist) configure \
        -columns $cols

    $Win(mclist) columnconfigure 2 -sortmode dictionary

    $Win(mclist) delete 0 end

    wpg_select $CurrentDB "$sql" r {
        if {$VER>=7.3} {
            $Win(mclist) insert end \
                [list $r(nspname) $r(relname) $r(usename) $r(relfilenode)]
        } else {
            $Win(mclist) insert end \
                [list $r(relname) $r(usename) $r(relfilenode)]
        }
    }

    setCursor DEFAULT

    return
}; # end proc ::Mainlib::cmd_Sequences


#----------------------------------------------------------
# ::Mainlib::cmd_Types --
#
#   Handles when the Types section is selected
#
# Arguments:
#   none
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Types {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set cols [list]
    if { $VER >= 7.3 } {
        set cols [list 0 [intlmsg Schema] left]
    }
    lappend cols 0 [intlmsg Name] left 0 [intlmsg Owner] left 0 [intlmsg Type] left

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns $cols

    setCursor CLOCK

    set sql [::Database::getTypesList $CurrentDB $pg 1 1]

    wpg_select $CurrentDB "$sql" r {
        if { $VER >= 7.3 } {
            set L [list $r(nspname) $r(typname) $r(usename) $r(typtype)]
        } else {
            set L [list $r(typname) $r(usename) $r(typtype)]
        }
        $Win(mclist) insert end $L
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Types


#----------------------------------------------------------
# ::Mainlib::cmd_Domains --
#
#   Handles when the Domains section is selected
#
# Arguments:
#   none
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Domains {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set cols [list]
    if { $VER >= 7.3 } {
        set cols [list 0 [intlmsg Schema] left]
    } else {
        lappend cols 0 [intlmsg Unavailable] left
        $Win(mclist) delete 0 end
        $Win(mclist) configure \
            -columns $cols
        # no DOMAINS before 7.3
        showError [intlmsg "You must upgrade to PostgreSQL 7.3 or later to use this feature."]
        return
    }
    lappend cols 0 [intlmsg Name] left 0 [intlmsg Owner] left

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns $cols

    setCursor CLOCK

    set sql [::Database::getTypesList $CurrentDB $pg 1 1 "d"]

    wpg_select $CurrentDB "$sql" r {
        set L [list $r(nspname) $r(typname) $r(usename)]
        $Win(mclist) insert end $L
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Domains


#----------------------------------------------------------
# ::Mainlib::cmd_Triggers --
#
#   Handles when the Triggers section is selected
#
# Arguments:
#   none
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Triggers {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set cols [list]
    if { $VER >= 7.3 } {
        set cols [list 0 [intlmsg Schema] left]
    }
    lappend cols 0 [intlmsg Table] left 0 [intlmsg Name] left 0 [intlmsg Function] left

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns $cols

    setCursor CLOCK

    set sql [::Database::getTriggersList $CurrentDB $pg 1 1]

    wpg_select $CurrentDB "$sql" r {
        if {$VER >= 7.3} {
            set L [list $r(nspname) $r(relname) $r(tgname) $r(proname)]
        } else {
            set L [list $r(relname) $r(tgname) $r(proname)]
        }
        $Win(mclist) insert end $L
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Triggers


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Indexes {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set cols [list]
    if { $VER >= 7.3 } {
        set cols [list 0 [intlmsg Schema] left]
    }
    lappend cols 0 [intlmsg Table] left 0 [intlmsg Name] left 0 [intlmsg Columns] left

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns $cols

    setCursor CLOCK

    set sql [::Database::getIndexesList $CurrentDB $pg 1 1]

    wpg_select $CurrentDB "$sql" r {
        if {$VER >= 7.3} {
            set L [list $r(nspname) $r(tablename) $r(indexname) $r(indnatts)]
        } else {
            set L [list $r(tablename) $r(indexname) $r(indnatts)]
        }
        $Win(mclist) insert end $L
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Indexes


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Rules {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set cols [list]
    if { $VER >= 7.3 } {
        set cols [list 0 [intlmsg Schema] left]
    }
    lappend cols 0 [intlmsg Table] left 0 [intlmsg Name] left 0 [intlmsg Event] left

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns $cols

    setCursor CLOCK

    set sql [::Database::getRulesList $CurrentDB $pg 1 1]

    wpg_select $CurrentDB "$sql" r {
        if {$VER >= 7.3} {
            set L [list $r(nspname) $r(relname) $r(rulename) $r(ev_type)]
        } else {
            set L [list $r(relname) $r(rulename) $r(ev_type)]
        }
        $Win(mclist) insert end $L
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Rules


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Languages {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set cols [list]
    lappend cols 0 [intlmsg Name] left 0 [intlmsg Trusted] left

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns $cols

    setCursor CLOCK

    set sql [::Database::getLanguagesList $CurrentDB $pg 1 1]

    wpg_select $CurrentDB "$sql" r {
        set L [list $r(lanname) $r(lanpltrusted)]
        $Win(mclist) insert end $L
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Languages


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Casts {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set cols [list]
    lappend cols 0 [intlmsg Source] left 0 [intlmsg Target] left 0 [intlmsg Function] left

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns $cols

    setCursor CLOCK

    set sql [::Database::getCastsList $CurrentDB $pg 1 1]

    wpg_select $CurrentDB "$sql" r {
        set L [list $r(sourcetype) $r(targettype) $r(proname)]
        $Win(mclist) insert end $L
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Casts


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Operators {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set cols [list]
    if { $VER >= 7.3 } {
        set cols [list 0 [intlmsg Schema] left]
    }
    lappend cols 0 [intlmsg Name] left 0 [intlmsg Function] left 0 [intlmsg Owner] left

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns $cols

    setCursor CLOCK

    set sql [::Database::getOperatorsList $CurrentDB $pg 1 1]

    wpg_select $CurrentDB "$sql" r {
        if {$VER >= 7.3} {
            set L [list $r(nspname) $r(oprname) $r(proname) $r(usename)]
        } else {
            set L [list $r(oprname) $r(proname) $r(usename)]
        }
        $Win(mclist) insert end $L
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Operators


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Operatorclasses {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set cols [list]
    if { $VER >= 7.3 } {
        set cols [list 0 [intlmsg Schema] left]
    }
    lappend cols 0 [intlmsg Name] left 0 [intlmsg Method] left 0 [intlmsg Owner] left

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns $cols

    setCursor CLOCK

    set sql [::Database::getOperatorClassesList $CurrentDB $pg 1 1]

    wpg_select $CurrentDB "$sql" r {
        if {$VER >= 7.3} {
            set L [list $r(nspname) $r(opcname) $r(amname) $r(usename)]
        } else {
            set L [list $r(opcname) $r(amname) $r(usename)]
        }
        $Win(mclist) insert end $L
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Operatorclasses


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Aggregates {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set cols [list]
    if { $VER >= 7.3 } {
        set cols [list 0 [intlmsg Schema] left]
    }
    lappend cols 0 [intlmsg Name] left 0 [intlmsg Owner] left

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns $cols

    setCursor CLOCK

    set sql [::Database::getAggregatesList $CurrentDB $pg 1 1]

    wpg_select $CurrentDB "$sql" r {
        if {$VER >= 7.3} {
            set L [list $r(nspname) $r(proname) $r(usename)]
        } else {
            set L [list $r(proname) $r(usename)]
        }
        $Win(mclist) insert end $L
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Aggregates


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Conversions {} {

    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set cols [list]
    if { $VER >= 7.3 } {
        set cols [list 0 [intlmsg Schema] left]
    }
    lappend cols 0 [intlmsg Name] left 0 [intlmsg Source] left 0 [intlmsg Destination] left 0 [intlmsg Function] left 0 [intlmsg Owner] left

    $Win(mclist) delete 0 end

    $Win(mclist) configure \
        -columns $cols

    setCursor CLOCK

    set sql [::Database::getConversionsList $CurrentDB $pg 1 1]

    wpg_select $CurrentDB "$sql" r {
        if {$VER >= 7.3} {
            set L [list $r(nspname) $r(conname) $r(conforencoding) $r(contoencoding) $r(proname) $r(usename)]
        } else {
            # do conversions even exist before 7.4 ? hmm
            set L [list $r(conname) $r(conforencoding) $r(contoencoding) $r(proname) $r(usename)]
        }
        $Win(mclist) insert end $L
    }

    setCursor DEFAULT

    return
}; # end proc ::Mainlib::cmd_Conversions


#----------------------------------------------------------
# ::Mainlib::cmd_Tables --
#
#     Handles when the Tables section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Tables {} {

    global CurrentDB PgAcVar
    variable Win
    variable boolean

    set cols [list 0 [intlmsg Name] left 0 [intlmsg Owner] left 0 [intlmsg OID] left]
    lappend cols 0 [intlmsg Tuples] left 0 [intlmsg Attributes] left

	
	set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(pgversion,$id)]} {
	set Connections::Conn(pgversion,$id) [::Database::getPgVersion $CurrentDB]
    }

    #set VER $::Connections::Conn(pgversion,$id)

    if {[string match "" $VER]} {
	showError [intlmsg "Could not find PG Version of the database"]
	return
    }

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    if {![info exists ::Connections::Conn(viewpgaccess,$id)]} {
        set ::Connections::Conn(viewpgaccess,$id) $PgAcVar(pref,pgaccesstables)
    }
    set pga $::Connections::Conn(viewpgaccess,$id)

    set sql [::Database::getTablesList $CurrentDB $pg $pga 1 1]

    if {$VER < 7.3} {
        set cols [list]
        set int [list 0 1 2 3 4]
    } else {
        set cols [list 0 [intlmsg Schema] left]
        set int [list 0 1 2 3 4 5]
    }

    lappend cols 0 [intlmsg Name] left 0 [intlmsg Owner] left 0 [intlmsg OID] left
    lappend cols 0 [intlmsg Tuples] left 0 [intlmsg Attributes] left

    $Win(mclist) configure \
        -columns $cols

    foreach C $int {
	    $Win(mclist) columnconfigure $C -sortmode dictionary
	}

    $Win(mclist) delete 0 end

    setCursor CLOCK
    wpg_select $CurrentDB "$sql" r {
		if {$VER >= 7.3} {
		    set L [list $r(nspname) $r(relname) $r(usename) $r(relfilenode) $r(reltuples) $r(relnatts)]
		} else {
		    set L [list $r(relname) $r(usename) $r(relfilenode) $r(reltuples) $r(relnatts)]
		}
        $Win(mclist) insert end $L
	     
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Tables

#----------------------------------------------------------
# ::Mainlib::cmd_Diagrams --
#
#     Handles when the Diagrams section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Diagrams {} {
    global CurrentDB
    variable Win

    set sql "
        SELECT diagramname 
          FROM Pga_diagrams 
      ORDER BY diagramname"

    $Win(mclist) configure \
        -columns [list 0 [intlmsg Name] left]

    $Win(mclist) delete 0 end

    setCursor CLOCK
    catch {
	wpg_select $CurrentDB "$sql" rec {
		$Win(mclist) insert end [list $rec(diagramname)]
	}
    }
    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Diagrams

#----------------------------------------------------------
# ::Mainlib::cmd_Views --
#
#     Handles when the Views section is selected
#
# Arguments:
#  none
#
# Results:
#  none returned
#----------------------------------------------------------
#
proc ::Mainlib::cmd_Views {} {

    global PgAcVar
    global CurrentDB
    variable Win

    set VER [::Database::getPgVersion $CurrentDB]
    set id [::Connections::getIdFromHandle $CurrentDB]

    if {![info exists ::Connections::Conn(pgversion,$id)]} {
        set Connections::Conn(pgversion,$id) \
            [::Database::getPgVersion $CurrentDB]
    }

    #set VER $::Connections::Conn(pgversion,$id)

    if {[string match "" $VER]} {
        showError [intlmsg "Could not find PG Version of the database"]
        return
    }

    if {![info exists ::Connections::Conn(viewsystem,$id)]} {
        set ::Connections::Conn(viewsystem,$id) $PgAcVar(pref,systemtables)
    }
    set pg $::Connections::Conn(viewsystem,$id)

    set sql [::Database::getViewsList $CurrentDB $pg 1 1]

    setCursor CLOCK

    if {$VER < 7.3} {
        set cols [list]
        set int [list 0 1 2 3]
    } else {
        set cols [list 0 [intlmsg Schema] left]
        set int [list 0 1 2 3 4]
    }

    lappend cols 0 [intlmsg Name] left 0 [intlmsg Owner] left
    lappend cols 0 [intlmsg OID] left 0 [intlmsg Attributes] left

    $Win(mclist) configure \
        -columns $cols

    foreach C $int {
        $Win(mclist) columnconfigure $C -sortmode dictionary
    }

    $Win(mclist) delete 0 end

    wpg_select $CurrentDB "$sql" r {
        if {$VER < 7.3} {
            $Win(mclist) insert end \
                [list $r(relname) $r(usename) $r(relfilenode) $r(relnatts)]
        } else {
            $Win(mclist) insert end \
                [list $r(schemaname) $r(viewname) $r(usename) $r(relfilenode) $r(relnatts)]
        }
    }

    setCursor DEFAULT

    return

}; # end proc ::Mainlib::cmd_Views


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Mainlib::delete_function {objname} {

    sql_exec noquiet "DROP FUNCTION $objname"

}; # end proc ::Mainlib::delete_function


#------------------------------------------------------------
# ::Mainlib::get_dwlb_Selection --
#
#    This just returns the selection in the mclistbox.
#    If There is a "Schema" column, then we return
#    "Schema.Table" if "Tables" is selected,
#    "Schema.View" if "Views" is selected,
#    likewise for Functions and Sequences
#
# Arguments:
#    none
#
# Results:
#    returns the first item in the mclistbox that is
#    selected.
#------------------------------------------------------------
#
proc ::Mainlib::get_dwlb_Selection {} {

    global PgAcVar
    variable Win

    set temp [$Win(tree) selection get]
    if {$temp==""} return "";
    set PgAcVar(activetab) [lindex [split $temp -] 2]

    set temp [$Win(mclist) curselection]

    if {$temp == ""} {return ""}


    set first [lindex [$Win(mclist) cget -columns] 1]

    if {[string match [intlmsg "Schema"] $first]} {
        return [join [lrange [$Win(mclist) get $temp] 0 1] .]
    }

    return [lindex [$Win(mclist) get $temp] 0]


}; # end proc ::Mainlib::get_dwlb_Selection




proc ::Mainlib::sqlw_display {msg} {
	if {![winfo exists .pgaw:SQLWindow]} {return}
	.pgaw:SQLWindow.f.t insert end "$msg\n\n"
	.pgaw:SQLWindow.f.t see end
	set nrlines [lindex [split [.pgaw:SQLWindow.f.t index end] .] 0]
	if {$nrlines>500} {
		.pgaw:SQLWindow.f.t delete 1.0 3.0
	}
}


#----------------------------------------------------------
# ::Mainlib::init_pga_tables --
#
#   Creates PGA tables in database
#
# Arguments:
#   dbh_    an optional database handle
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::Mainlib::init_pga_tables {{dbh_ ""}} {

    global PgAcVar CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set pga_tabs(pga_queries) [list]
    append pga_tabs(pga_queries) "queryname VARCHAR(64) PRIMARY KEY,"
    append pga_tabs(pga_queries) "querytype CHAR(1),"
    append pga_tabs(pga_queries) "querycommand TEXT,"
    append pga_tabs(pga_queries) "querytables TEXT,"
    append pga_tabs(pga_queries) "querylinks TEXT,"
    append pga_tabs(pga_queries) "queryresults TEXT,"
    append pga_tabs(pga_queries) "querycomments TEXT"

    set pga_tabs(pga_forms) [list]
    append pga_tabs(pga_forms) "formname VARCHAR(64) PRIMARY KEY,"
    append pga_tabs(pga_forms) "formsource TEXT"

    set pga_tabs(pga_scripts) [list]
    append pga_tabs(pga_scripts) "scriptname VARCHAR(64) PRIMARY KEY,"
    append pga_tabs(pga_scripts) "scriptsource TEXT"

    set pga_tabs(pga_images) [list]
    append pga_tabs(pga_images) "imagename VARCHAR(64) PRIMARY KEY,"
    append pga_tabs(pga_images) "imagesource TEXT"

    set pga_tabs(pga_reports) [list]
    append pga_tabs(pga_reports) "reportname VARCHAR(64) PRIMARY KEY,"
    append pga_tabs(pga_reports) "reportsource TEXT,"
    append pga_tabs(pga_reports) "reportbody TEXT,"
    append pga_tabs(pga_reports) "reportprocs TEXT,"
    append pga_tabs(pga_reports) "reportoptions TEXT"

    set pga_tabs(pga_diagrams) [list]
    append pga_tabs(pga_diagrams) "diagramname VARCHAR(64) PRIMARY KEY,"
    append pga_tabs(pga_diagrams) "diagramtables TEXT,"
    append pga_tabs(pga_diagrams) "diagramlinks TEXT"

    set pga_tabs(pga_graphs) [list]
    append pga_tabs(pga_graphs) "graphname VARCHAR(64) PRIMARY KEY,"
    append pga_tabs(pga_graphs) "graphsource TEXT,"
    append pga_tabs(pga_graphs) "graphcode TEXT"

    set pga_tabs(pga_layout) [list]
    append pga_tabs(pga_layout) "tablename VARCHAR(64) PRIMARY KEY,"
    append pga_tabs(pga_layout) "nrcols INT2,"
    append pga_tabs(pga_layout) "colnames TEXT,"
    append pga_tabs(pga_layout) "colwidth TEXT"

    # Check for pga_ tables
    foreach {table structure} [array get pga_tabs] {

        set pgres [wpg_exec $dbh_ "
            SELECT relname
              FROM [::Database::qualifySysTable pg_class]
             WHERE relname='$table'"]

        if {$PgAcVar(pgsql,status)!="PGRES_TUPLES_OK"} {
            showError "[intlmsg {FATAL ERROR searching for PgAccess system tables}] : $PgAcVar(pgsql,errmsg)\nStatus:$PgAcVar(pgsql,status)"
            catch {pg_disconnect $dbh_}
            $Win(statuslabel) configure \
                -text ""
            exit
        } elseif {[pg_result $pgres -numTuples]==0} {
            pg_result $pgres -clear

            # if they don't want persistent pga_ tables, just make em TEMPs
            set tempsql "CREATE"
            if {[info exists PgAcVar(PGACCESS_TEMP)] && $PgAcVar(PGACCESS_TEMP)==1} {
                append tempsql " TEMP"
            }
            append tempsql " TABLE $table ($structure) WITH OIDS"
            sql_exec quiet $tempsql

            # the following is kind of a security breach
            #sql_exec quiet "
            #    GRANT ALL ON $table
            #       TO PUBLIC"

            #
            # backwards compatibility with pga_schema
            # now its pga_diagrams
            # should rip this out in the distant future
            #
            if {$table=="pga_diagrams"} {
                set pgres [wpg_exec $dbh_ "
                    SELECT relname
                      FROM [::Database::qualifySysTable pg_class]
                     WHERE relname='pga_schema'"]
                if {[pg_result $pgres -numTuples]!=0} {
                    sql_exec quiet "
                        INSERT INTO pga_diagrams
                             SELECT *
                               FROM pga_schema"
                    sql_exec quiet "
                        DROP TABLE pga_schema"
                }
                pg_result $pgres -clear
            }; # end backwards schema/diagram compatibility

        } else {
            foreach fieldspec [split $structure ,] {
                set field [lindex [split $fieldspec] 0]
                pg_result $pgres -clear
                set sql "
                    SELECT \"$field\"
                      FROM [::Database::quoteObject $table]"
                set pgres [wpg_exec $dbh_ $sql]
                if {$PgAcVar(pgsql,status)!="PGRES_TUPLES_OK"} {
                    if {![regexp "attribute '$field' not found" $PgAcVar(pgsql,errmsg)]} {
                        showError "[intlmsg {FATAL ERROR upgrading PgAccess table}] $table: $PgAcVar(pgsql,errmsg)\nStatus:$PgAcVar(pgsql,status)"
                        catch {pg_disconnect $dbh_}
                        $Win(statuslabel) configure \
                            -text ""
                        exit
                    } else {
                         pg_result $pgres -clear
                         sql_exec quiet "
                            ALTER TABLE [::Database::quoteObject $table]
                             ADD COLUMN $fieldspec"
                    }
                }
            }; # end foreach fieldspec
        }

        catch {pg_result $pgres -clear}

    }; # end foreach table structure

}; # end proc ::Mainlib::init_pga_tables


#----------------------------------------------------------
# ::Mainlib::open_database --
#
#    Opens current database
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::OLD_AND_DEFUNCT_open_database {} {

    global PgAcVar CurrentDB
    variable Win

    setCursor CLOCK

    set connstr ""

    if {[info exists PgAcVar(opendb,host)] \
      && $PgAcVar(opendb,host)!=""} {
        append connstr " host=$PgAcVar(opendb,host)"
    }
    if {[info exists PgAcVar(opendb,pgport)] \
      && $PgAcVar(opendb,pgport)!=""} {
        append connstr " port=$PgAcVar(opendb,pgport)"
    }
    if {[info exists PgAcVar(opendb,dbname)] \
      && $PgAcVar(opendb,dbname)!=""} {
        append connstr " dbname=$PgAcVar(opendb,dbname)"
    }
    if {[info exists PgAcVar(opendb,username)] \
      && $PgAcVar(opendb,username)!=""} {
        append connstr " user=$PgAcVar(opendb,username)"
    }
    if {[info exists PgAcVar(opendb,password)] \
      && $PgAcVar(opendb,password)!=""} {
        append connstr " password=$PgAcVar(opendb,password)"
    }

    set connres [catch {set newdbc [pg_connect -conninfo $connstr]} msg]

    if {$connres} {
	    setCursor DEFAULT
	    showError [format [intlmsg "Error trying to connect to database '%s' on host %s \n\nPostgreSQL error message: %s"] $PgAcVar(opendb,dbname) $PgAcVar(opendb,host) $msg"] "open_database"
        return $msg
    } else {
		$Win(statuslabel) configure \
		    -text "Loading $PgAcVar(opendb,dbname) ..."

	    #catch {pg_disconnect $CurrentDB}
	    set CurrentDB $newdbc
	    Preferences::load
	    set PgAcVar(currentdb,host) $PgAcVar(opendb,host)
	    set PgAcVar(currentdb,pgport) $PgAcVar(opendb,pgport)
	    set PgAcVar(currentdb,dbname) $PgAcVar(opendb,dbname)
	    set PgAcVar(currentdb,username) $PgAcVar(opendb,username)
	    set PgAcVar(currentdb,password) $PgAcVar(opendb,password)
	    set PgAcVar(statusline,dbname) $PgAcVar(currentdb,dbname)
	    #set PgAcVar(pref,lastdb) $PgAcVar(currentdb,dbname)
	    #set PgAcVar(pref,lasthost) $PgAcVar(currentdb,host)
		#if {[string match "sockets" $PgAcVar(pref,lasthost)]} {
		#    set PgAcVar(pref,lasthost) ""
		#}
	    # set PgAcVar(pref,lastport) $PgAcVar(currentdb,pgport)
	    # set PgAcVar(pref,lastusername) $PgAcVar(currentdb,username)

	    # check if we are saving passwords
	    #if {[info exists PgAcVar(pref,savepasswords)] && $PgAcVar(pref,savepasswords)==1} {
		#    set PgAcVar(pref,lastpassword) $PgAcVar(currentdb,password)
	    #} else {
		#    set PgAcVar(pref,lastpassword) {}
	    #}
		
        # dont save prefs here anymore with multiple connections
        # Preferences::save
	    #catch {setCursor DEFAULT ; Window hide .pgaw:OpenDB}
        setCursor DEFAULT
        catch {Window destroy .pgaw:OpenDB}

        # create the PGA tables if necessary
        ::Mainlib::init_pga_tables $CurrentDB
	
	    # searching for autoexec script
        ::Connections::autoexec $CurrentDB

    }

	#::Connections::check
    #if {![$Win(tree) visible root]} {
            #$Win(tree) delete [$Win(tree) nodes root]
            #fillTree

	    
    #}

	#if {[lsearch [getHosts] $PgAcVar(currentdb,host)] < 0} {

        #addHost

        #$::Mainlib::Win(tree) insert end root __host__-$M \
            #-text "$M" \
         	#-image [image create photo -data $::Mainlib::_base64(online:rx)]
	#}

	addDbNode $PgAcVar(currentdb,host) $PgAcVar(currentdb,dbname)

	::Connections::save

	$Win(statuslabel) configure \
	  -text ""
    
	return

}; # end proc ::Mainlib::open_datase



#----------------------------------------------------------
# ::Mainlib::fillTree --
#
#    Fills the tree widget with the DB information
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::fillTree {} {

    global PgAcVar Win CurrentDB
    variable Win

    ##
    ##  Once we go to multiple connections, this will
    ##  a real list of computers. Now it defaults to 
    ##  the currentdb host
    ##
    #set complist [list $PgAcVar(currentdb,host)]
    set complist [::Connections::getHosts]
    foreach M $complist {
        #if {[string match "" $M]} {set M localhost}

        #$::Mainlib::Win(tree) insert end root __host__-$M \
            #-text "$M" \
      	#-image [image create photo -data $::Mainlib::_base64(online:rx)]

	    addHostNode $M
    
        ##
        ##  Right now we just handle the currentdb
        ##
        #set dblist($M) [list $PgAcVar(currentdb,dbname)]
        set dblist($M) [::Connections::getDbs $M]
        foreach N $dblist($M) {
        
            addDbNode $M $N

###          $::Mainlib::Win(tree) insert end __host__-$M db-${M}-${N} \
###                -text "$N" \
###        		-image [image create photo -data $::Mainlib::_base64(si_drive4)]
###        
###            foreach I $PgAcVar(tablist) {
###               $::Mainlib::Win(tree) insert end db-${M}-${N} ${M}-${N}-${I} \
###                   -text "[string totitle $I]" \
###                   -image [image create photo -data $::Mainlib::_base64(si_grid)]
###            }   

        }

    }

    ##
    ##  This just opens up the tree to the "current DB"
    ##  assuming that the user wants to start there
    ##
    if {[string match "" $PgAcVar(currentdb,host)]} {
        if {[$Win(tree) exists __host__-sockets]} {
            $Win(tree) opentree __host__-sockets 0
        }
        if {[$Win(tree) exists __db__-sockets-$PgAcVar(currentdb,dbname)]} {
            $Win(tree) opentree __db__-sockets-$PgAcVar(currentdb,dbname)
        }
    } else {
        if {[$Win(tree) exists __host__-$PgAcVar(currentdb,host)]} {
            $Win(tree) opentree __host__-$PgAcVar(currentdb,host) 0
        }
        if {[$Win(tree) exists __db__-${PgAcVar(currentdb,host)}-$PgAcVar(currentdb,dbname)]} {
            $Win(tree) opentree __db__-${PgAcVar(currentdb,host)}-$PgAcVar(currentdb,dbname)
        }
    }

    ##
    ## This is if there is an autoexec script in the scripts db
    ##
    if {([info exists PgAcVar(activetab)]) && (![string match "" $PgAcVar(activetab)])} {
        set node ${PgAcVar(currentdb,host)}-${PgAcVar(currentdb,dbname)}-$PgAcVar(activetab)
        #$Win(tree) selection set $node
        #$Win(tree) selection see $node
        select 1 $node
    }

    return
    
}; # end proc ::Mainlib::fillTree 

#------------------------------------------------------------
# ::Mainlib::addHostNode --
#
#    This adds a host node to the tree list
#
# Arguments:
#    host_    then hostname to use for the tree node
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc ::Mainlib::addHostNode {host_} {

    variable Win

	set txt $host_
	set img ::icon::network_local-16

    if {[string match "" $host_]} {
	    set host_ sockets
		set txt "local (sockets)"
	    set img ::icon::system-16
	}

	if {[$Win(tree) exists __host__-$host_]} {return}

    $::Mainlib::Win(tree) insert end root __host__-$host_ \
        -text "$txt" \
      	-image $img
      	#-image [image create photo -data $::Mainlib::_base64(online:rx)]

    return

}; # end proc ::Mainlib::addHostNode

#------------------------------------------------------------
# ::Mainlib::addDbNode --
#
#    This adds a database node to the tree list
#
# Arguments:
#    host_    then hostname for this db
#    db_      the db name to use for the db node
#
# Results:
#    none returned
#------------------------------------------------------------
#
proc ::Mainlib::addDbNode {host_ db_} {

    global CurrentDB
    variable Win
    variable img

    set dbh ""

    if {[string match "" $dbh]} {
        set dbh $CurrentDB
    }

    set id [::Connections::getIdFromHandle $dbh]
    set V [::Database::getPgVersion $dbh]

	set i [image create photo -data $::Mainlib::_base64(si_grid)]

    if {[string match "" $host_]} {set host_ sockets}

    if {[$Win(tree) exists __db__-${host_}-${db_}]} {return}

    if {![$Win(tree) exists __host__-$host_]} {
	if {[string match "sockets" $host_]} {
	    addHostNode ""
        } else {

            addHostNode $host_
        }
    }

    $::Mainlib::Win(tree) insert end __host__-$host_ __db__-${host_}-${db_} \
        -text "$db_" \
        -image [image create photo -data $::Mainlib::_base64(si_sql)]

    foreach I $::PgAcVar(pgtablist) {
        if {!($V < 7.3 \
          && [lsearch [list "Domains" "Casts" "Conversions"] $I]!=-1)} {
            $::Mainlib::Win(tree) insert end \
               __db__-${host_}-${db_} ${host_}-${db_}-${I} \
               -text [intlmsg $I] \
               -image $img($I) \
               -fill blue
        }
    }

    foreach I $::PgAcVar(pgatablist) {
        $::Mainlib::Win(tree) insert end \
           __db__-${host_}-${db_} ${host_}-${db_}-${I} \
           -text [intlmsg $I] \
           -image $img($I) \
           -fill red
    }

    return

}; # end proc ::Mailib::addDbNode

#----------------------------------------------------------
# ::Mainlib::nodeOpen --
#
#
# Arguments:
#    node    This gets passed from the bind on the node
#            in the tree. It is the node that was selected
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::nodeOpen {node} {

    variable Win

    foreach {junk host db} [split $node -] break

    if {(![string match "__db__" $junk]) && (![string match "__host__" $junk])} {
	set db $host
        set host $junk
    }

    if {[string match "sockets" "$host"]} {
	$Win(hostlabel) configure \
            -text "local (sockets)"
    } else {
        $Win(hostlabel) configure \
            -text "${host}"
    }

    $Win(dblabel) configure \
        -text "${db}"

    set nhost [string map {sockets ""} $host]

    set id [::Connections::getIds $nhost $db]
    if {[string match "" $id]} {
	   set v ""
    } else {
	if {![info exists ::Connections::Conn(pgversion,$id)]} {
	    set dbh [::Connections::getHandles $host $db]
	    set Connections::Conn(pgversion,$id) [::Database::getPgVersion $dbh]
	}
	set v $::Connections::Conn(pgversion,$id)
    }
    
    $Win(verlabel) configure \
        -text "PG: $v"
            #-text "PG: [::Database::getPgVersion]"

    return

} ; # end proc ::Mainlib::nodeOpen

#----------------------------------------------------------
# ::Mainlib::select --
#
#
# Arguments:
#    num_    Which button was pressed (1 or 2)
#    node_   This is passed in by the Tree widget. It is
#            the node that is selected.
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::select {num_ node_} {

    global PgAcVar CurrentDB
    variable Win
    variable boolean

    ##
    ##	This is to guard against when someone
    ##	double clicks...it displays the contains
    ##	twice...so this just makes sure that doesn't
    ##	happen
    ##
    if {$num_ == 2} return

    $Win(tree) selection set $node_

    foreach {comp db entry} [split $node_ -] {break}

    switch -glob -- $node_ {

        __host__-* {
            set host $db
            set db ""
            set entry ""

            set cols [list 0 [intlmsg Name] left 0 [intlmsg DBs] left]

            $Win(mclist) configure \
                -columns $cols

            $Win(mclist) delete 0 end

            setCursor CLOCK

            $Win(mclist) insert end \
            [list $host [llength [$Win(tree) nodes $node_]]]

            setCursor DEFAULT
        }

        __db__-* {
            set host $db
            set db $entry
            set entry ""

            set id [::Connections::getIds $host $db]
            if {[info exists ::Connections::Conn(handle,$id)]} {
                set CurrentDB $::Connections::Conn(handle,$id)
            }

            set sql "
                SELECT U.usename,D.*
                  FROM [::Database::qualifySysTable pg_database] D,
                       [::Database::qualifySysTable pg_user] U
                 WHERE datname = '$db'
                   AND U.usesysid = D.datdba"

            set id [::Connections::getIds $host $db]
            if {[info exists ::Connections::Conn(handle,$id)]} {
                set CurrentDB $::Connections::Conn(handle,$id)
                set ::PgAcVar(currentdb,pgport) $::Connections::Conn(pgport,$id)
                set ::PgAcVar(currentdb,username) $::Connections::Conn(username,$id)
                set ::PgAcVar(currentdb,password) $::Connections::Conn(password,$id)
            }

            set cols [list 0 [intlmsg Owner] left 0 [intlmsg Encoding] left]
            lappend cols 0 [intlmsg Template?] left 0 [intlmsg Connection?] left
            lappend cols 0 [intlmsg Sysoid] left

            $Win(mclist) configure \
                -columns $cols

            $Win(mclist) delete 0 end

            setCursor CLOCK

            if {[catch {wpg_select $CurrentDB "$sql" r {
                $Win(mclist) insert end \
                    [list $r(usename) $r(encoding) $boolean($r(datistemplate)) $boolean($r(datallowconn)) $r(datlastsysoid)]
            }}]} {
                ::Mainlib::Database:Close
            }

            setCursor DEFAULT

        }

        default {
            set host $comp

            set id [lrange [::Connections::getIds $host $db] end end]
            if {[info exists ::Connections::Conn(handle,$id)]} {
                set CurrentDB $::Connections::Conn(handle,$id)
                set ::PgAcVar(currentdb,pgport) $::Connections::Conn(pgport,$id)
                set ::PgAcVar(currentdb,username) $::Connections::Conn(username,$id)
            }

            if {[lsearch $PgAcVar(tablist) $entry] >= 0} {
                if {[catch {cmd_$entry}]} {
                    showError [intlmsg "Could not open $entry node"]
                }
            }
        }

    }; # end switch

    set ::PgAcVar(currentdb,host) $host
    set ::PgAcVar(currentdb,dbname) $db
    set ::PgAcVar(pref,lasthost) $host
    set ::PgAcVar(pref,lastdb) $db

    set PgAcVar(activetab) $entry

    nodeOpen $node_

    return

}; # end proc select

#----------------------------------------------------------
# ::Mainlib::DatabaseCmd --
#
#    Selects the command for the correct menu item
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::DatabaseCmd {item_} {

    switch -- $item_ {
        Vacuum       {::Database::vacuum}
        Import_table {::ImportExport::setup 1}
        Export_table {::ImportExport::setup 0}
        PgAckage_save {::PgAckages::init save}
        PgAckage_load {::PgAckages::init load}
        PgAccess_init {::Mainlib::init_pga_tables}
        Preferences  {::Preferences::configure}
        Exit         {::Mainlib::Exit}
        Open         {::Connections::openConn 0 1 0 1}
        Debug        {::Debug::open}
        default      {::Mainlib::Database:$item_}
    }; # end switch

    return

}; # end proc ::Mainlib::DatabaseCmd

#----------------------------------------------------------
# ::Mainlib::Database:New --
#
#    Opens the new db dialog window
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::Database:New {} {

    Window show .pgaw:NewDatabase
    wm transient .pgaw:NewDatabase

    return

}; # end proc ::Mainlib::Database:New

#----------------------------------------------------------
# ::Mainlib::Database:Manage --
#
#    Window to manages the connections info
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::Database:Manage {} {

    global PgAcVar
  
    if {[winfo exists .manage]} {
        deiconify .manage
    } else {
        toplevel .manage
    }

    wm title .manage "Manage Connections"

    set fm [frame .manage.fm \
        -relief raised \
        -bd 1]

    set c 0
    foreach t [list [intlmsg "host"] [intlmsg "dbname"] [intlmsg "autoload"] [intlmsg "show system tables"] [intlmsg "show pgaccess tables"] [intlmsg "save passwords"] [intlmsg "open"] [intlmsg "delete"]] {
        label $fm.lab$c \
            -text "$t" \
            -font $PgAcVar(pref,font_bold) \
            -relief groove \
            -foreground navy \
            -background #EEEEEE

        grid $fm.lab$c \
            -row 0 \
            -column $c \
            -sticky we

        incr c
    }

    foreach H [::Connections::getHosts] {
        if {[string match "" $H]} {set H sockets}

        foreach D [::Connections::getDbs $H] {
            if {[string length $D]>0 && [string length $H]>0} {
                set i [lindex [::Connections::getIds $H $D] 0]
                label $fm.h$i \
                    -text "$H"
                label $fm.d$i \
                    -text "$D"

                checkbutton $fm.al$i \
                    -variable ::Connections::Conn(autoload,$i)

                checkbutton $fm.vs$i \
                    -variable ::Connections::Conn(viewsystem,$i)

                checkbutton $fm.va$i \
                    -variable ::Connections::Conn(viewpgaccess,$i)

                checkbutton $fm.sp$i \
                    -variable ::Connections::Conn(savepasswords,$i)

                button $fm.open$i \
                    -text [intlmsg "Open"] \
                    -command "::Connections::openConn [lrange $i end end] 1 0 0"

                button $fm.del$i \
                    -text [intlmsg "Delete"] \
                    -command "
                        foreach didi $i {
                            ::Connections::deleteInfo \$didi
                        }
                        $fm.h$i configure -state disabled
                        $fm.d$i configure -state disabled
                        $fm.al$i configure -state disabled
                        $fm.vs$i configure -state disabled
                        $fm.va$i configure -state disabled
                        $fm.sp$i configure -state disabled
                        $fm.open$i configure -state disabled
                        $fm.del$i configure -state disabled
                    "

                grid $fm.h$i $fm.d$i $fm.al$i $fm.vs$i $fm.va$i $fm.sp$i $fm.open$i $fm.del$i \
                    -sticky w \
                    -padx 4
            }
        }
    }

    grid $fm \
        -sticky news

###    button .manage.btnsave \
###        -command ::Connections::initSave \
###        -padx 9 \
###        -pady 3 \
###        -text [intlmsg Save]

    button .manage.btncancel \
        -command {::Connections::save; Window destroy .manage} \
        -padx 9 \
        -pady 3 \
        -text [intlmsg Close]
    

    grid .manage.btncancel \
        -sticky ew

    return

}; # end proc ::Mainlib::Database:Manage


#----------------------------------------------------------
# ::Mainlib::Database:Close --
#
#    Closes the database connection to the current DB
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::Database:Close {} {

    variable Win

    set node [$Win(tree) selection get]
    if {([string match "" $node]) || ([string match "__host__-*" $node])} {return}


    foreach {H D E} [split $node -] break

	if {[string match "__db__-*" $node]} {
		set H $D
	    set D $E
	}

    #catch {pg_disconnect $::CurrentDB}

    catch {pg_disconnect [::Connections::getHandles $H $D]}
    $Win(tree) delete [$Win(tree) nodes __db__-${H}-${D}]
    $Win(tree) delete __db__-${H}-${D}

    $Win(mclist) delete 0 end
	$Win(mclist) configure \
	    -columns [list 0 "" left]

    if {[llength [$Win(tree) nodes __host__-${H}]] == 0} {
	   $Win(tree) delete __host__-${H}
	   set h [$Win(tree) nodes root]
	   if {[llength $h] != 0} {
	       select 1 [lindex $h 0]
		   select 1 [lindex [$Win(tree) nodes $h] 0]
	   }
	} else {
	    select 1 [lindex [$Win(tree) nodes __host__-${H}] 0]
	}

	#set i [::Connections::getIds $H $D]
    #::Connections::deleteInfo $i

    set ::CurrentDB {}
    set ::PgAcVar(currentdb,dbname) {}
    #set ::PgAcVar(statusline,dbname) {}

    foreach L {host db ver} {
	    $Win(${L}label) configure \
		    -text ""
	}


    ::Connections::save

    return
}; # end proc ::Mainlib::Database:Close

#----------------------------------------------------------
# ::Mainlib::Database:SQL_window --
#
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::Database:SQL_window {} {

    Window show .pgaw:SQLWindow

    return

}; # end proc ::Mainlib::Database:SQL_window

#----------------------------------------------------------
# ::Mainlib::Exit --
#
#    Exits PGAccess
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::Exit {} {

    global PgAcVar CurrentDB

    # if theres no current db vars, just quit
    #if {![info exists PgAcVar(currentdb,dbname)]
    #    || ![info exists PgAcVar(currentdb,username)]
    #    || ![info exists PgAcVar(currentdb,pgport)]} {
    #    catch {pg_disconnect $CurrentDB}
    #    exit
    #}

	#set PgAcVar(pref,lastdb) $::PgAcVar(currentdb,dbname)
	#set PgAcVar(pref,lasthost) $::PgAcVar(currentdb,host)

	#if {[string match "sockets" $PgAcVar(pref,lasthost)]} {
	#    set PgAcVar(pref,lasthost) ""
	#}

	#set PgAcVar(pref,lastport) $PgAcVar(currentdb,pgport)
	#set PgAcVar(pref,lastusername) $PgAcVar(currentdb,username)

	# check if we are saving passwords
	#if {[info exists PgAcVar(pref,savepasswords)] && $PgAcVar(pref,savepasswords)==1} {
	#    set PgAcVar(pref,lastpassword) $PgAcVar(currentdb,password)
    #    foreach {k v} [array get ::Connections::Conn password,*] {
    #        set ::Connections::Conn($k) ""
    #    }
	#} else {
	#    set PgAcVar(pref,lastpassword) {}
	#}
    set PgAcVar(activetab) {}
    set PgAcVar(pref,geometry) [winfo geometry .]
    Preferences::save
    Connections::save

    foreach C [::Connections::getHandles] {
        catch {pg_disconnect $C}
    }

    exit
}; # end proc ::Mainlib::Exit


#----------------------------------------------------------
# ::Mainlib::ObjectCmd --
#
#    Selects the command for the correct menu item
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::ObjectCmd {item_} {

    cmd_$item_

    return

}; # end proc ::Mainlib::ObjectCmd

#----------------------------------------------------------
# ::Mainlib::ServerCmd --
#
#    Selects the command for the correct menu item
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::ServerCmd {item_} {

    switch -- $item_ {
        Dump_database {::Mainlib::cmd_Dump text}
        PgMonitor     {::::Pgmonitor::openWin}
        HotSyncPGA    {init_load_namespaces 1}
        default       {::Mainlib::cmd_Dump binary}
    }; # end switch

    return

}; # end proc ::Mainlib::ServerCmd

#----------------------------------------------------------
# ::Mainlib::HelpCmd --
#
#    Selects the command for the correct menu item
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::HelpCmd {item_} {

    switch -- $item_ {
        Contents   {::Help::load index}
        PostgreSQL {::Help::load postgresql}
        About      {Window show .pgaw:About}
    }; # end switch

    return

}; # end proc ::Mainlib::HelpCmd

#----------------------------------------------------------
# ::Mainlib::handleToolBar --
#
#    Checks to see if the toolbar needs to be hidden or
#    shown
#
# Arguments:
#    none
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc ::Mainlib::handleToolBar {} {

	global PgAcVar
    variable Win

    if {![info exists PgAcVar(pref,showtoolbar)]} {set PgAcVar(pref,showtoolbar) 1}

	if {$PgAcVar(pref,showtoolbar)} {

	    pack $Win(toolframe) \
	    	-before $Win(csmframe) \
	        -fill x

	} else {

	    pack forget $Win(toolframe)
	}

    return

}; # end proc ::Mainlib::HelpCmd


#------------------------------------------------------------
#------------------------------------------------------------
#
proc ::Mainlib::notEmpty {var_} {

    upvar $var_ V

    if {([info exists V]) && (![string match "" $V])} {
        return 1
    }

    return 0
}; # end proc ::Mainlib::notEmpty



#----------------------------------------------------------
# vTclWindow.pgaw:Main --
#
#    Builds the main GUI
#
# Arguments:
#    base    this is the base window
#
# Results:
#    none returned
#----------------------------------------------------------
#
proc vTclWindow.pgaw:Main {base} {

    global PgAcVar Win CurrentDB

    if {$base == ""} {
	set base .pgaw:Main
    }
    if {[winfo exists $base]} {
	#wm deiconify $base; return
    }
	#toplevel $base -class Toplevel \
	    #-background #efefef -cursor left_ptr


    ##
    ##  This is a total hack!
    ##  This is to get around the fact that
    ##  alot of other procs reference this window
    ##  which was replaced with the new interface
    ##  Will tear this out when we take care of the
    ##  references from other procs
    ##
    frame .pgaw:Main


    wm geometry . 600x400
	if {([info exists PgAcVar(pref,geometry)]) && (![string match "" $PgAcVar(pref,geometry)])} {
	    wm geometry . $PgAcVar(pref,geometry)
	}
    wm title . "PostgreSQL Access"
	#wm maxsize $base 1280 1024
	#wm minsize $base 1 1
	#wm overrideredirect $base 0
	#wm resizable $base 0 0
	#wm deiconify $base

    set base ""
    set ::Mainlib::Win(menuframe) $base.mf
    set ::Mainlib::Win(toolframe) [frame $base.tbf]
    set ::Mainlib::Win(csmframe) [frame $base.mainf]
    set ::Mainlib::Win(labelframe) [frame $base.labf]

    option add *Menu.borderWidth 1                   widgetDefault
    option add *Menu.font $PgAcVar(pref,font_normal) widgetDefault
    option add *Menu.tearOff 0                       widgetDefault
    option add *ButtonBox.borderWidth  1             widgetDefault
    option add *ButtonBox.takeFocus  0               widgetDefault
    option add *ButtonBox.highLightThickness  0      widgetDefault

    ##
    ##  This is the new style of creating menus
    ##
    menu $::Mainlib::Win(menuframe)
    . configure -menu $::Mainlib::Win(menuframe)

    set mn(Database) [list New Open Manage Close Vacuum]
    lappend mn(Database) sep Import_table Export_table
    lappend mn(Database) sep PgAckage_save PgAckage_load
    lappend mn(Database) sep PgAccess_init
    lappend mn(Database) sep Preferences SQL_window Debug sep Exit
    set mn(Object) [list New Open Design Copy Rename Delete]
    set mn(Server) [list Dump_database Dump_database_(binary) sep PgMonitor sep HotSyncPGA]
    set mn(Help) [list Contents PostgreSQL sep About]

    ##
    ##  This is just a convenience...we loop through
    ##  the different meny items for each main menu
    ##  we assume there is a proc with the same name
    ##  as the label
    ##
    foreach MM {Database Object Server Help} {

        set x [string tolower $MM]

        $::Mainlib::Win(menuframe) add cascade \
            -label [intlmsg $MM] \
            -menu $::Mainlib::Win(menuframe).$x
  
        menu $::Mainlib::Win(menuframe).$x

        foreach M $mn($MM) {

            regsub -all {_} $M { } txt

            if {[string match sep $M]} {
                $::Mainlib::Win(menuframe).$x add separator
            } else {
               $::Mainlib::Win(menuframe).$x add command \
                    -label [intlmsg $txt] \
                    -command "::Mainlib::${MM}Cmd $M"
           }
        }; # end foreach sub menu

    }; # end foreach main menu


    ##
    ##  TOOL BAR
    ##
    set ::Mainlib::Win(bbox1) [ButtonBox $::Mainlib::Win(toolframe).bbox -spacing 2]

    DynamicHelp::configure -font {Helvetica 10}

        $::Mainlib::Win(bbox1) add -image ::icon::connect_creating-22 \
            -padx 1 \
            -pady 1 \
            -relief link \
            -command [list ::Mainlib::DatabaseCmd Open] \
            -helptext [intlmsg "Connect to DB"]

        $::Mainlib::Win(bbox1) add -image ::icon::connect_no-22 \
            -padx 1 \
            -pady 1 \
            -relief link \
            -command [list ::Mainlib::DatabaseCmd Close] \
            -helptext [intlmsg "Close current connection"]

        $::Mainlib::Win(bbox1) add -image ::icon::filter1-22 \
            -padx 1 \
            -pady 1 \
            -relief link \
            -command [list ::Mainlib::DatabaseCmd Vacuum] \
            -helptext [intlmsg "Vacuum current DB"]
        
        $::Mainlib::Win(bbox1) add -image ::icon::down-22 \
            -padx 1 \
            -pady 1 \
            -relief link \
            -command [list ::Mainlib::DatabaseCmd Import_table] \
            -helptext [intlmsg "Import Table"]

        $::Mainlib::Win(bbox1) add -image ::icon::up-22 \
            -padx 1 \
            -pady 1 \
            -relief link \
            -command [list ::Mainlib::DatabaseCmd Export_table] \
            -helptext [intlmsg "Export Table"]

        $::Mainlib::Win(bbox1) add -image ::icon::start-22 \
            -padx 1 \
            -pady 1 \
            -relief link \
            -command [list ::Mainlib::DatabaseCmd PgAckage_save] \
            -helptext [intlmsg "Save PgAckage"]

        $::Mainlib::Win(bbox1) add -image ::icon::finish-22 \
            -padx 1 \
            -pady 1 \
            -relief link \
            -command [list ::Mainlib::DatabaseCmd PgAckage_load] \
            -helptext [intlmsg "Load PgAckage"]

        $::Mainlib::Win(bbox1) add -image ::icon::configure-22 \
            -padx 1 \
            -pady 1 \
            -relief link \
            -command [list ::Mainlib::DatabaseCmd Preferences] \
            -helptext [intlmsg "Preferences"]

    Separator $::Mainlib::Win(toolframe).sep  -orient vertical

    set ::Mainlib::Win(bbox2) [ButtonBox $::Mainlib::Win(toolframe).bbox2 -spacing 2]


        $::Mainlib::Win(bbox2) add -image ::icon::filenew-22 \
            -padx 1 \
            -pady 1 \
            -relief link \
            -command ::Mainlib::cmd_New \
            -helptext [intlmsg "New Object"]

        $::Mainlib::Win(bbox2) add -image ::icon::fileopen-22 \
            -relief link \
            -padx 1 \
            -pady 1 \
            -command ::Mainlib::cmd_Open \
            -helptext [intlmsg "Open Selected Object"]

        $::Mainlib::Win(bbox2) add -image ::icon::edit-22 \
            -relief link \
            -padx 1 \
            -pady 1 \
            -command ::Mainlib::cmd_Design \
            -helptext [intlmsg "Design Selected Object"]

        $::Mainlib::Win(bbox2) add -image ::icon::editcopy-22 \
            -relief link \
            -padx 1 \
            -pady 1 \
            -command ::Mainlib::cmd_Copy \
            -helptext [intlmsg "Copy Selected Object"]

        $::Mainlib::Win(bbox2) add -image ::icon::move-22 \
            -relief link \
            -padx 1 \
            -pady 1 \
            -command ::Mainlib::cmd_Rename \
            -helptext [intlmsg "Rename Selected Object"]

        $::Mainlib::Win(bbox2) add -image ::icon::edittrash-22 \
            -relief link \
            -padx 1 \
            -pady 1 \
            -command ::Mainlib::cmd_Delete \
            -helptext [intlmsg "Delete Selected Object"]

    ##
    ##   PANED WINDOW
    ##
    set ::Mainlib::Win(panew) [PanedWindow $::Mainlib::Win(csmframe).pane \
        -side bottom \
        -weights available]

    set ::Mainlib::Win(pane1) [$::Mainlib::Win(panew) add -weight 1]
    set ::Mainlib::Win(pane2) [$::Mainlib::Win(panew) add -weight 3]
    
    #set ::Mainlib::Win(bbox2) [ButtonBox $::Mainlib::Win(csmframe).bbox2 \
        #-spacing 0 \
    	#-padx 1 \
    	#-pady 1\
        #-orient vertical \
    	#-background #336699 \
    	#-homogeneous 1]
    
    ##
    ##  TREE WINDOW
    ##
	frame $::Mainlib::Win(pane1).tfm
	pack $::Mainlib::Win(pane1).tfm \
	    -expand 1 \
		-fill both

    scrollbar $::Mainlib::Win(pane1).tfm.xscroll \
        -width 12 \
        -command [list $::Mainlib::Win(pane1).tfm.tree xview] \
        -highlightthickness 0 \
		-orient horizontal \
		-background #DDDDDD \
        -takefocus 0

    scrollbar $::Mainlib::Win(pane1).tfm.yscroll \
        -width 12 \
        -command [list $::Mainlib::Win(pane1).tfm.tree yview] \
        -highlightthickness 0 \
		-background #DDDDDD \
		-takefocus 0

    

    set ::Mainlib::Win(tree) [Tree $::Mainlib::Win(pane1).tfm.tree \
		-width 500 \
		-deltay 22 \
        -dropenabled 1 \
    	-dragenabled 1 \
    	-dragevent 3 \
    	-opencmd   "::Mainlib::nodeOpen" \
    	-droptypes {
    	    TREE_NODE    {copy {} move {} link {}}
    	     LISTBOX_ITEM {copy {} move {} link {}}
    	} \
        -yscrollcommand [list $::Mainlib::Win(pane1).tfm.yscroll set] \
        -xscrollcommand [list $::Mainlib::Win(pane1).tfm.xscroll set] \
    	-background #fefefe]
    
    $::Mainlib::Win(tree) bindText  <ButtonPress-1>        "::Mainlib::select 1"
    $::Mainlib::Win(tree) bindImage  <ButtonPress-1>        "::Mainlib::select 1"
    $::Mainlib::Win(tree) bindText  <Double-ButtonPress-1> "::Mainlib::select 2"
    $::Mainlib::Win(tree) bindImage  <Double-ButtonPress-1> "::Mainlib::select 2"
    
    frame $::Mainlib::Win(pane2).lbfm
    pack $::Mainlib::Win(pane2).lbfm \
        -expand 1 \
        -fill both

    scrollbar $::Mainlib::Win(pane2).lbfm.xscroll \
        -width 12 \
        -command [list $::Mainlib::Win(pane2).lbfm.list xview] \
        -highlightthickness 0 \
		-orient horizontal \
		-background #DDDDDD \
        -takefocus 0

    scrollbar $::Mainlib::Win(pane2).lbfm.yscroll \
        -width 12 \
        -command [list $::Mainlib::Win(pane2).lbfm.list yview] \
        -highlightthickness 0 \
		-background #DDDDDD \
		-takefocus 0

    set ::Mainlib::Win(mclist) [tablelist::tablelist \
        $::Mainlib::Win(pane2).lbfm.list \
        -yscrollcommand [list $::Mainlib::Win(pane2).lbfm.yscroll set] \
        -xscrollcommand [list $::Mainlib::Win(pane2).lbfm.xscroll set] \
        -labelcommand tablelist::sortByColumn \
        -background #fefefe \
        -stripebg #e0e8f0 \
        -selectbackground #DDDDDD \
        -font $::PgAcVar(pref,font_normal) \
        -labelfont {Helvetica 11 bold} \
        -stretch all \
        -columns [list 0 "" left] \
        -selectforeground #708090 \
        -labelbackground #DDDDDD \
        -labelforeground navy
        ]

    set body [$::Mainlib::Win(mclist) bodypath]
    bind $body <Double-Button-1> [bind TablelistBody <Double-Button-1>]
    bind $body <Double-Button-1> +[list ::Mainlib::cmd_Open]

	menu $::Mainlib::Win(mclist).popup
	$::Mainlib::Win(mclist).popup add command -label [intlmsg "New"] -command ::Mainlib::cmd_New
	$::Mainlib::Win(mclist).popup add command -label [intlmsg "Open"] -command ::Mainlib::cmd_Open
	$::Mainlib::Win(mclist).popup add command -label [intlmsg "Design"] -command ::Mainlib::cmd_Design
	$::Mainlib::Win(mclist).popup add command -label [intlmsg "Copy"] -command ::Mainlib::cmd_Copy
	$::Mainlib::Win(mclist).popup add command -label [intlmsg "Rename"] -command ::Mainlib::cmd_Rename
	$::Mainlib::Win(mclist).popup add command -label [intlmsg "Delete"] -command ::Mainlib::cmd_Delete

	bind $body <ButtonRelease-3> {
		tk_popup $::Mainlib::Win(mclist).popup %X %Y 0
	}

    set mainwin .
    # bindings for some common keyboard shortcuts
    bind $mainwin <Control-Key-q> {
        exit
    }

    # these commands also availabe from upper right icons and right-click
    bind $mainwin <Control-Key-n> {
        ::Mainlib::cmd_New
    }
    bind $mainwin <Control-Key-c> {
        ::Mainlib::cmd_Copy
    }
    bind $mainwin <Control-Key-r> {
        ::Mainlib::cmd_Rename
    }
    bind $mainwin <Control-Key-x> {
        ::Mainlib::cmd_Delete
    }
    bind $mainwin <Control-Key-d> {
        ::Mainlib::cmd_Design
    }
    bind $mainwin <Control-Key-o> {
        ::Mainlib::cmd_Open
    }


    set ::Mainlib::Win(hostlabel) [label $::Mainlib::Win(labelframe).lshost \
        -background #EEEEEE \
	    -anchor w \
        -relief groove \
        -text localhost \
        -foreground navy \
        -font $PgAcVar(pref,font_bold) \
        -width 20]

    set ::Mainlib::Win(dblabel) [label $::Mainlib::Win(labelframe).lsdbname \
        -background #EEEEEE \
	    -anchor w \
        -foreground navy \
        -font $PgAcVar(pref,font_bold) \
	    -relief groove \
        -width 20]

    set ::Mainlib::Win(verlabel) [label $::Mainlib::Win(labelframe).lsversion \
        -background #EEEEEE \
	-anchor w \
        -foreground navy \
        -font $PgAcVar(pref,font_bold) \
	-relief groove \
        -width 15]

    set ::Mainlib::Win(statuslabel) [label $::Mainlib::Win(labelframe).lsstatus \
	-anchor w \
        -foreground navy \
        -font $PgAcVar(pref,font_bold) \
        -width 20]

    set ::Mainlib::Win(secure) [label $::Mainlib::Win(labelframe).secure \
	    -image ::icon::decrypted-22 \
	    -anchor w]

    # pane 1

    grid $::Mainlib::Win(tree) \
        -row 0 \
        -column 0 \
        -sticky news

    grid $::Mainlib::Win(pane1).tfm.xscroll \
        -row 1 \
        -column 0 \
        -sticky ew

    grid $::Mainlib::Win(pane1).tfm.yscroll \
        -row 0 \
        -column 1 \
        -sticky ns

    grid columnconfigure $::Mainlib::Win(pane1).tfm 0 \
        -weight 10
    grid rowconfigure $::Mainlib::Win(pane1).tfm 0 \
        -weight 10

    # pane 2

    grid $::Mainlib::Win(mclist) \
        -row 0 \
        -column 0 \
        -rowspan 2 \
        -sticky news

    grid $::Mainlib::Win(pane2).lbfm.xscroll \
        -row 2 \
        -column 0 \
        -sticky ew

    grid $::Mainlib::Win(pane2).lbfm.yscroll \
        -row 1 \
        -column 1 \
        -sticky ns

    grid columnconfigure $::Mainlib::Win(pane2).lbfm 0 \
        -weight 10
    grid rowconfigure $::Mainlib::Win(pane2).lbfm 1 \
        -weight 10

    # not pane 1 or pane 2

    pack $::Mainlib::Win(csmframe).pane \
        -expand 1 \
        -fill both

    pack $::Mainlib::Win(bbox1) $::Mainlib::Win(toolframe).sep \
	    -fill y \
		-side left \
		-padx 4 \
		-pady 2 \
        -anchor c

    pack $::Mainlib::Win(bbox2) \
		-padx 4 \
		-pady 2 \
	    -side right

    pack $::Mainlib::Win(hostlabel) $::Mainlib::Win(dblabel) $::Mainlib::Win(verlabel) $::Mainlib::Win(statuslabel)\
        -side left \
        -padx 2
        
    pack $::Mainlib::Win(secure) \
        -side right \
        -padx 2

    pack $::Mainlib::Win(toolframe) \
        -fill x

    pack $::Mainlib::Win(csmframe) \
        -fill both \
    	-expand 1

    pack $::Mainlib::Win(labelframe) \
        -pady 2 \
        -side top \
        -fill x

    ::Mainlib::handleToolBar

    return $base

}; # end proc vTclWindow.pgaw:Main




proc vTclWindow.pgaw:CopyObject {base} {
global PgAcVar

    if {$base == ""} {
        set base .pgaw:CopyObject
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 200x150+294+262
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm title $base [intlmsg "Copy"]

    frame $base.fconn \
        -borderwidth 2 \
        -height 50 \
        -width 200
    Label $base.fconn.lconn \
        -borderwidth 0 \
        -text [intlmsg {Connection}]
    ComboBox $base.fconn.comboconn \
        -textvariable PgAcVar(Copy_To_Connection) \
        -background #fefefe \
        -borderwidth 1 \
        -width 200 \
        -values $PgAcVar(Connections_List) \
        -editable false

    frame $base.fname \
        -borderwidth 2 \
        -height 50 \
        -width 200
    Label $base.fname.lname \
        -borderwidth 0 \
        -text [intlmsg {Name}]
    Entry $base.fname.ename \
        -background #fefefe \
        -borderwidth 1 \
        -textvariable PgAcVar(New_Object_Name)

    frame $base.fbtn \
        -borderwidth 2 \
        -height 50 \
        -width 200
    Button $base.fbtn.bcopy \
        -text [intlmsg "Copy"] \
        -borderwidth 1 \
        -command {

            # get the right destination connection
            set H [lindex [split $PgAcVar(Copy_To_Connection) ":"] 0]
            set D [lindex [split $PgAcVar(Copy_To_Connection) ":"] 1]
            set PgAcVar(Copy_To_Connection_Handle) [::Connections::getHandles $H $D]

            if {$PgAcVar(New_Object_Name)==""} {
                showError [intlmsg "You must give object a new name!"]

            # copying Queries
            } elseif {$PgAcVar(activetab)=="Queries"} {
                set sql "
                    SELECT *
                      FROM pga_queries
                     WHERE queryname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $PgAcVar(Copy_To_Connection_Handle) $sql]
                if {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Query '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql [::Queries::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name) $CurrentDB]
                    if {![sql_exec noquiet $sql $PgAcVar(Copy_To_Connection_Handle)]} {
                        showError [format [intlmsg "Query '%s' could not be copied!"] $PgAcVar(New_Object_Name)]
                    }
                    ::Mainlib::cmd_Queries
                    Window destroy .pgaw:CopyObject
                }
                catch {pg_result $pgres -clear}

            # copying Reports
            } elseif {$PgAcVar(activetab)=="Reports"} {
                set sql "
                    SELECT *
                      FROM pga_reports
                     WHERE reportname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $PgAcVar(Copy_To_Connection_Handle) $sql]
                if {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Report '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql [::Reports::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name) $CurrentDB]
                    if {![sql_exec noquiet $sql $PgAcVar(Copy_To_Connection_Handle)]} {
                        showError [format [intlmsg "Report '%s' could not be copied!"] $PgAcVar(New_Object_Name)]
                    }
                    Mainlib::cmd_Reports
                    Window destroy .pgaw:CopyObject
                }
                catch {pg_result $pgres -clear}

            # copying Graphs
            } elseif {$PgAcVar(activetab)=="Graphs"} {
                set sql "
                    SELECT *
                      FROM pga_graphs
                     WHERE graphname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $PgAcVar(Copy_To_Connection_Handle) $sql]
                if {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Graph '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql [::Graphs::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name) $CurrentDB]
                    if {![sql_exec noquiet $sql $PgAcVar(Copy_To_Connection_Handle)]} {
                        showError [format [intlmsg "Graph '%s' could not be copied!"] $PgAcVar(New_Object_Name)]
                    }
                    Mainlib::cmd_Graphs
                    Window destroy .pgaw:CopyObject
                }
                catch {pg_result $pgres -clear}

            # copying Forms
            } elseif {$PgAcVar(activetab)=="Forms"} {
                set sql "
                    SELECT *
                      FROM pga_forms
                     WHERE formname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $PgAcVar(Copy_To_Connection_Handle) $sql]
                if {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Form '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql [::Forms::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name) $CurrentDB]
                    if {![sql_exec noquiet $sql $PgAcVar(Copy_To_Connection_Handle)]} {
                        showError [format [intlmsg "Form '%s' could not be copied!"] $PgAcVar(New_Object_Name)]
                    }
                    Mainlib::cmd_Forms
                    Window destroy .pgaw:CopyObject
                }
                catch {pg_result $pgres -clear}

            # copying Scripts
            } elseif {$PgAcVar(activetab)=="Scripts"} {
                set sql "
                    SELECT *
                      FROM pga_scripts
                     WHERE scriptname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $PgAcVar(Copy_To_Connection_Handle) $sql]
                if {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Script '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql [::Scripts::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name) $CurrentDB]
                    if {![sql_exec noquiet $sql $PgAcVar(Copy_To_Connection_Handle)]} {
                        showError [format [intlmsg "Script '%s' could not be copied!"] $PgAcVar(New_Object_Name)]
                    }
                    Mainlib::cmd_Scripts
                    Window destroy .pgaw:CopyObject
                }
                catch {pg_result $pgres -clear}

            # copying Diagrams
            } elseif {$PgAcVar(activetab)=="Diagrams"} {
                set sql "
                    SELECT *
                      FROM pga_diagrams
                     WHERE diagramname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $PgAcVar(Copy_To_Connection_Handle) $sql]
                if {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Diagram '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql [::Diagrams::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name) $CurrentDB]
                    if {![sql_exec noquiet $sql $PgAcVar(Copy_To_Connection_Handle)]} {
                        showError [format [intlmsg "Diagram '%s' could not be copied!"] $PgAcVar(New_Object_Name)]
                    }
                    Mainlib::cmd_Diagrams
                    Window destroy .pgaw:CopyObject
                }
                catch {pg_result $pgres -clear}

            # copying Images
            } elseif {$PgAcVar(activetab)=="Images"} {
                set sql "
                    SELECT *
                      FROM pga_images
                     WHERE imagename='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $PgAcVar(Copy_To_Connection_Handle) $sql]
                if {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Image '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql [::Images::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name) $CurrentDB]
                    if {![sql_exec noquiet $sql $PgAcVar(Copy_To_Connection_Handle)]} {
                        showError [format [intlmsg "Image '%s' could not be copied!"] $PgAcVar(New_Object_Name)]
                    }
                    Mainlib::cmd_Images
                    Window destroy .pgaw:CopyObject
                }
                catch {pg_result $pgres -clear}

            # copying Tables
            } elseif {$PgAcVar(activetab)=="Tables"} {
                if {[lsearch -exact [::Database::getTablesList $PgAcVar(Copy_To_Connection_Handle)] $PgAcVar(New_Object_Name)] > -1} {
                    showError [format [intlmsg "Table '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql [::Tables::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name) $CurrentDB]
                    if {![sql_exec noquiet $sql $PgAcVar(Copy_To_Connection_Handle)]} {
                        showError [format [intlmsg "Table '%s' could not be copied!"] $PgAcVar(New_Object_Name)]
                    }
                    Mainlib::cmd_Tables
                    Window destroy .pgaw:CopyObject
                }
                catch {pg_result $pgres -clear}

            # copying Functions
            } elseif {$PgAcVar(activetab)=="Functions"} {
                if {[lsearch -exact [::Database::getFunctionsList $PgAcVar(Copy_To_Connection_Handle)] $PgAcVar(New_Object_Name)] > -1} {
                    showError [format [intlmsg "Function '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql [::Functions::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name) $CurrentDB]
                    if {![sql_exec noquiet $sql $PgAcVar(Copy_To_Connection_Handle)]} {
                        showError [format [intlmsg "Function '%s' could not be copied!"] $PgAcVar(New_Object_Name)]
                    }
                    Mainlib::cmd_Functions
                    Window destroy .pgaw:CopyObject
                }
                catch {pg_result $pgres -clear}

            # copying Sequences
            } elseif {$PgAcVar(activetab)=="Sequences"} {
                if {[lsearch -exact [::Database::getSequencesList $PgAcVar(Copy_To_Connection_Handle)] $PgAcVar(New_Object_Name)] > -1} {
                    showError [format [intlmsg "Sequence '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql [::Sequences::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name) $CurrentDB]
                    if {![sql_exec noquiet $sql $PgAcVar(Copy_To_Connection_Handle)]} {
                        showError [format [intlmsg "Sequence '%s' could not be copied!"] $PgAcVar(New_Object_Name)]
                    }
                    Mainlib::cmd_Sequences
                    Window destroy .pgaw:CopyObject
                }
                catch {pg_result $pgres -clear}

            # copying Views
            } elseif {$PgAcVar(activetab)=="Views"} {
                if {[lsearch -exact [::Database::getViewsList $PgAcVar(Copy_To_Connection_Handle)] $PgAcVar(New_Object_Name)] > -1} {
                    showError [format [intlmsg "View '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql [::Views::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name) $CurrentDB]
                    if {![sql_exec noquiet $sql $PgAcVar(Copy_To_Connection_Handle)]} {
                        showError [format [intlmsg "View '%s' could not be copied!"] $PgAcVar(New_Object_Name)]
                    }
                    Mainlib::cmd_Views
                    Window destroy .pgaw:CopyObject
                }
                catch {pg_result $pgres -clear}

            }
        }

    Button $base.fbtn.bcancel \
        -text [intlmsg "Cancel"] \
        -borderwidth 1 \
        -command {
            Window destroy .pgaw:CopyObject
        }

    pack $base.fconn \
        -in $base \
        -expand 1 \
        -fill both \
        -anchor center \
        -side top
    pack $base.fname \
        -in $base \
        -expand 1 \
        -fill both \
        -anchor center \
        -side top
    pack $base.fbtn \
        -in $base \
        -expand 1 \
        -fill both \
        -anchor center \
        -side top

    pack $base.fconn.lconn \
        -in $base.fconn \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left
    pack $base.fconn.comboconn \
        -in $base.fconn \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left

    pack $base.fname.lname \
        -in $base.fname \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left
    pack $base.fname.ename \
        -in $base.fname \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left

    pack $base.fbtn.bcopy \
        -in $base.fbtn \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left
    pack $base.fbtn.bcancel \
        -in $base.fbtn \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left

}

proc vTclWindow.pgaw:RenameObject {base} {
global PgAcVar

    if {$base == ""} {
        set base .pgaw:RenameObject
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 200x150+294+262
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm title $base [intlmsg "Rename"]

    frame $base.fold \
        -borderwidth 2 \
        -height 50 \
        -width 200
    Label $base.fold.lname \
        -borderwidth 0 \
        -text [intlmsg "Old Name"]
    Entry $base.fold.ename \
        -background #fefefe \
        -borderwidth 1 \
        -textvariable PgAcVar(Old_Object_Name) \
        -state disabled

    frame $base.fnew \
        -borderwidth 2 \
        -height 50 \
        -width 200
    Label $base.fnew.lname \
        -borderwidth 0 \
        -text [intlmsg "New Name"]
    Entry $base.fnew.ename \
        -background #fefefe \
        -borderwidth 1 \
        -textvariable PgAcVar(New_Object_Name)

    frame $base.fbtn \
        -borderwidth 2 \
        -height 50 \
        -width 200
    Button $base.fbtn.brename \
        -text [intlmsg "Rename"] \
        -borderwidth 1 \
        -command {

            if {$PgAcVar(New_Object_Name)==""} {
                showError [intlmsg "You must give object a new name!"]

            } elseif {$PgAcVar(activetab)=="Tables"} {
                set sql "
                    ALTER TABLE \"$PgAcVar(Old_Object_Name)\"
                      RENAME TO \"$PgAcVar(New_Object_Name)\""
                set retval [sql_exec noquiet $sql]
                ::Diagrams::tbl_rename $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name)
                if {$retval} {
                    set sql "
                        UPDATE pga_layout
                           SET tablename='$PgAcVar(New_Object_Name)'
                         WHERE tablename='$PgAcVar(Old_Object_Name)'"
                    sql_exec quiet $sql
                    ::Mainlib::cmd_Tables
                    Window destroy .pgaw:RenameObject
                }

            } elseif {$PgAcVar(activetab)=="Views"} {
                set sql "
                    ALTER TABLE \"$PgAcVar(Old_Object_Name)\"
                      RENAME TO \"$PgAcVar(New_Object_Name)\""
                set retval [sql_exec noquiet $sql]
                ::Diagrams::tbl_rename $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name)
                if {$retval} {
                    set sql "
                        UPDATE pga_layout
                           SET tablename='$PgAcVar(New_Object_Name)'
                         WHERE tablename='$PgAcVar(Old_Object_Name)'"
                    sql_exec quiet $sql
                    ::Mainlib::cmd_Views
                    Window destroy .pgaw:RenameObject
                }

            } elseif {$PgAcVar(activetab)=="Functions"} {
                set sql [::Functions::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name)]
                set retval [sql_exec noquiet $sql]
                if {$retval} {
                    set sql "DROP FUNCTION $PgAcVar(Old_Object_Name)"
                    sql_exec quiet $sql
                    ::Mainlib::cmd_Functions
                    Window destroy .pgaw:RenameObject
                }

            } elseif {$PgAcVar(activetab)=="Sequences"} {
                set sql [::Sequences::clone $PgAcVar(Old_Object_Name) $PgAcVar(New_Object_Name)]
                set retval [sql_exec noquiet $sql]
                if {$retval} {
                    set sql "DROP SEQUENCE $PgAcVar(Old_Object_Name)"
                    sql_exec quiet $sql
                    ::Mainlib::cmd_Sequences
                    Window destroy .pgaw:RenameObject
                }

            } elseif {$PgAcVar(activetab)=="Queries"} {
                set sql "
                    SELECT *
                      FROM pga_queries
                     WHERE queryname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $CurrentDB $sql]
                if {$PgAcVar(pgsql,status)!="PGRES_TUPLES_OK"} {
                    showError "[intlmsg {Error retrieving from}] pga_queries\n$PgAcVar(pgsql,errmsg)\n$PgAcVar(pgsql,status)"
                } elseif {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Query '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql "
                        UPDATE pga_queries
                           SET queryname='$PgAcVar(New_Object_Name)'
                         WHERE queryname='$PgAcVar(Old_Object_Name)'"
                    sql_exec noquiet $sql
                    set sql "
                        UPDATE pga_layout
                           SET tablename='$PgAcVar(New_Object_Name)'
                         WHERE tablename='$PgAcVar(Old_Object_Name)'"
                    sql_exec noquiet $sql
                    ::Mainlib::cmd_Queries
                    Window destroy .pgaw:RenameObject
                }
                catch {pg_result $pgres -clear}

            } elseif {$PgAcVar(activetab)=="Reports"} {
                set sql "
                    SELECT *
                      FROM pga_reports
                     WHERE reportname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $CurrentDB $sql]
                if {$PgAcVar(pgsql,status)!="PGRES_TUPLES_OK"} {
                    showError "[intlmsg {Error retrieving from}] pga_reports\n$PgAcVar(pgsql,errmsg)\n$PgAcVar(pgsql,status)"
                } elseif {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Report '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql "
                        UPDATE pga_reports
                           SET reportname='$PgAcVar(New_Object_Name)'
                         WHERE reportname='$PgAcVar(Old_Object_Name)'"
                    sql_exec noquiet $sql
                    ::Mainlib::cmd_Reports
                    Window destroy .pgaw:RenameObject
                }
                catch {pg_result $pgres -clear}

            } elseif {$PgAcVar(activetab)=="Graphs"} {
                set sql "
                    SELECT *
                      FROM pga_graphs
                     WHERE graphname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $CurrentDB $sql]
                if {$PgAcVar(pgsql,status)!="PGRES_TUPLES_OK"} {
                    showError "[intlmsg {Error retrieving from}] pga_graphs\n$PgAcVar(pgsql,errmsg)\n$PgAcVar(pgsql,status)"
                } elseif {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Graph '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql "
                        UPDATE pga_graphs
                           SET graphname='$PgAcVar(New_Object_Name)'
                         WHERE graphname='$PgAcVar(Old_Object_Name)'"
                    sql_exec noquiet $sql
                    ::Mainlib::cmd_Graphs
                    Window destroy .pgaw:RenameObject
                }
                catch {pg_result $pgres -clear}

            } elseif {$PgAcVar(activetab)=="Forms"} {
                set sql "
                    SELECT *
                      FROM pga_forms
                     WHERE formname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $CurrentDB $sql]
                if {$PgAcVar(pgsql,status)!="PGRES_TUPLES_OK"} {
                    showError "[intlmsg {Error retrieving from}] pga_forms\n$PgAcVar(pgsql,errmsg)\n$PgAcVar(pgsql,status)"
                } elseif {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Form '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql "
                        UPDATE pga_forms
                           SET formname='$PgAcVar(New_Object_Name)'
                         WHERE formname='$PgAcVar(Old_Object_Name)'"
                    sql_exec noquiet $sql
                    ::Mainlib::cmd_Forms
                    Window destroy .pgaw:RenameObject
                }
                catch {pg_result $pgres -clear}

            } elseif {$PgAcVar(activetab)=="Scripts"} {
                set sql "
                    SELECT *
                      FROM pga_scripts
                     WHERE scriptname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $CurrentDB $sql]
                if {$PgAcVar(pgsql,status)!="PGRES_TUPLES_OK"} {
                    showError "[intlmsg {Error retrieving from}] pga_scripts\n$PgAcVar(pgsql,errmsg)\n$PgAcVar(pgsql,status)"
                } elseif {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Script '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql "
                        UPDATE pga_scripts
                           SET scriptname='$PgAcVar(New_Object_Name)'
                         WHERE scriptname='$PgAcVar(Old_Object_Name)'"
                    sql_exec noquiet $sql
                    ::Mainlib::cmd_Scripts
                    Window destroy .pgaw:RenameObject
                }
                catch {pg_result $pgres -clear}

            } elseif {$PgAcVar(activetab)=="Diagrams"} {
                set sql "
                    SELECT *
                      FROM pga_diagrams
                     WHERE diagramname='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $CurrentDB $sql]
                if {$PgAcVar(pgsql,status)!="PGRES_TUPLES_OK"} {
                    showError "[intlmsg {Error retrieving from}] pga_diagrams\n$PgAcVar(pgsql,errmsg)\n$PgAcVar(pgsql,status)"
                } elseif {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Diagram '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql "
                        UPDATE pga_diagrams
                           SET diagramname='$PgAcVar(New_Object_Name)'
                         WHERE diagramname='$PgAcVar(Old_Object_Name)'"
                    sql_exec noquiet $sql
                    ::Mainlib::cmd_Diagrams
                    Window destroy .pgaw:RenameObject
                }
                catch {pg_result $pgres -clear}

            } elseif {$PgAcVar(activetab)=="Images"} {
                set sql "
                    SELECT *
                      FROM pga_images
                     WHERE imagename='$PgAcVar(New_Object_Name)'"
                set pgres [wpg_exec $CurrentDB $sql]
                if {$PgAcVar(pgsql,status)!="PGRES_TUPLES_OK"} {
                    showError "[intlmsg {Error retrieving from}] pga_images\n$PgAcVar(pgsql,errmsg)\n$PgAcVar(pgsql,status)"
                } elseif {[pg_result $pgres -numTuples]>0} {
                    showError [format [intlmsg "Image '%s' already exists!"] $PgAcVar(New_Object_Name)]
                } else {
                    set sql "
                        UPDATE pga_images
                           SET imagename='$PgAcVar(New_Object_Name)'
                         WHERE imagename='$PgAcVar(Old_Object_Name)'"
                    sql_exec noquiet $sql
                    ::Mainlib::cmd_Images
                    Window destroy .pgaw:RenameObject
                }
                catch {pg_result $pgres -clear}
            }
        }

    Button $base.fbtn.bcancel \
        -text [intlmsg "Cancel"] \
        -borderwidth 1 \
        -command {
            Window destroy .pgaw:RenameObject
        }

    pack $base.fold \
        -in $base \
        -expand 1 \
        -fill both \
        -anchor center \
        -side top
    pack $base.fnew \
        -in $base \
        -expand 1 \
        -fill both \
        -anchor center \
        -side top
    pack $base.fbtn \
        -in $base \
        -expand 1 \
        -fill both \
        -anchor center \
        -side top

    pack $base.fold.lname \
        -in $base.fold \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left
    pack $base.fold.ename \
        -in $base.fold \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left

    pack $base.fnew.lname \
        -in $base.fnew \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left
    pack $base.fnew.ename \
        -in $base.fnew \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left

    pack $base.fbtn.brename \
        -in $base.fbtn \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left
    pack $base.fbtn.bcancel \
        -in $base.fbtn \
        -expand 1 \
        -fill x \
        -anchor center \
        -side left

}


proc vTclWindow.pgaw:NewDatabase {base} {
	if {$base == ""} {
		set base .pgaw:NewDatabase
	}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	toplevel $base -class Toplevel
	wm focusmodel $base passive
	wm geometry $base 352x105+294+262
	wm maxsize $base 1280 1024
	wm minsize $base 1 1
	wm overrideredirect $base 0
	wm resizable $base 0 0
	wm title $base [intlmsg "New"]
	label $base.l1  -borderwidth 0 -text [intlmsg {Name}]
	entry $base.e1  -background #fefefe -borderwidth 1 -textvariable PgAcVar(New_Database_Name) 
	button $base.b1  -borderwidth 1  -command {
		set retval [sql_exec noquiet "CREATE DATABASE $PgAcVar(New_Database_Name)"]
        if {$retval} {
            Window destroy .pgaw:NewDatabase
        } else {
            showError [intlmsg "Oops!  Might want to try the wizard button!"]
        }
	} -text [intlmsg Create]
	button $base.b2  -borderwidth 1 -command {Window destroy .pgaw:NewDatabase} -text [intlmsg Cancel]

    Button $base.wizbtn \
        -helptext [intlmsg {Wizard}] \
        -image ::icon::wizard-22 \
        -borderwidth 2 \
        -command {
            setCursor CLOCK
            Window destroy .pgaw:NewDatabase
            ::NewDBWiz::start
            setCursor NORMAL
        }

	place $base.l1  -x 15 -y 28 -anchor nw -bordermode ignore 
	place $base.e1  -x 100 -y 25 -anchor nw -bordermode ignore 
	place $base.b1  -x 55 -y 65 -width 80 -anchor nw -bordermode ignore 
	place $base.b2  -x 155 -y 65 -width 80 -anchor nw -bordermode ignore
    place $base.wizbtn -x 260 -y 20 -height 60 -width 60

}


proc vTclWindow.pgaw:GetParameter {base} {
	if {$base == ""} {
		set base .pgaw:GetParameter
	}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	toplevel $base -class Toplevel
	wm focusmodel $base passive
	set sw [winfo screenwidth .]
	set sh [winfo screenheight .]
	set x [expr ($sw - 297)/2]
	set y [expr ($sh - 98)/2]
	wm geometry $base 297x98+$x+$y
	wm maxsize $base 1280 1024
	wm minsize $base 1 1
	wm overrideredirect $base 0
	wm resizable $base 0 0
	wm deiconify $base
	wm title $base [intlmsg "Input parameter"]
	label $base.l1 \
		-anchor nw -borderwidth 1 \
		-justify left -relief sunken -textvariable PgAcVar(getqueryparam,msg) -wraplength 200 
	entry $base.e1 \
		-background #fefefe -borderwidth 1 -highlightthickness 0 \
		-textvariable PgAcVar(getqueryparam,var) 
	bind $base.e1 <Key-KP_Enter> {
		set PgAcVar(getqueryparam,result) 1
destroy .pgaw:GetParameter
	}
	bind $base.e1 <Key-Return> {
		set PgAcVar(getqueryparam,result) 1
destroy .pgaw:GetParameter
	}
	button $base.bok \
		-borderwidth 1 -command {set PgAcVar(getqueryparam,result) 1
destroy .pgaw:GetParameter} -text Ok 
	button $base.bcanc \
		-borderwidth 1 -command {set PgAcVar(getqueryparam,result) 0
destroy .pgaw:GetParameter} -text [intlmsg Cancel]
	place $base.l1 \
		-x 10 -y 5 -width 201 -height 53 -anchor nw -bordermode ignore 
	place $base.e1 \
		-x 10 -y 65 -width 200 -height 24 -anchor nw -bordermode ignore 
	place $base.bok \
		-x 225 -y 5 -width 61 -height 26 -anchor nw -bordermode ignore 
	place $base.bcanc \
		-x 225 -y 35 -width 61 -height 26 -anchor nw -bordermode ignore 
}


proc vTclWindow.pgaw:SQLWindow {base} {
	if {$base == ""} {
		set base .pgaw:SQLWindow
	}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	toplevel $base -class Toplevel
	wm focusmodel $base passive
	wm geometry $base 551x408+192+169
	wm maxsize $base 1280 1024
	wm minsize $base 1 1
	wm overrideredirect $base 0
	wm resizable $base 1 1
	wm deiconify $base
	wm title $base [intlmsg "SQL window"]
	frame $base.f \
		-borderwidth 1 -height 392 -relief raised -width 396 
	scrollbar $base.f.01 \
		-borderwidth 1 -command {.pgaw:SQLWindow.f.t xview} -orient horiz \
		-width 10 
	scrollbar $base.f.02 \
		-borderwidth 1 -command {.pgaw:SQLWindow.f.t yview} -orient vert -width 10 
	text $base.f.t \
		-borderwidth 1 \
		-height 200 -width 200 -wrap word \
		-xscrollcommand {.pgaw:SQLWindow.f.01 set} \
		-yscrollcommand {.pgaw:SQLWindow.f.02 set} 
	button $base.b1 \
		-borderwidth 1 -command {.pgaw:SQLWindow.f.t delete 1.0 end} -text [intlmsg Clean]
	button $base.b2 \
		-borderwidth 1 -command {destroy .pgaw:SQLWindow} -text [intlmsg Close] 
	grid columnconf $base 0 -weight 1
	grid columnconf $base 1 -weight 1
	grid rowconf $base 0 -weight 1
	grid $base.f \
		-in .pgaw:SQLWindow -column 0 -row 0 -columnspan 2 -rowspan 1 
	grid columnconf $base.f 0 -weight 1
	grid rowconf $base.f 0 -weight 1
	grid $base.f.01 \
		-in .pgaw:SQLWindow.f -column 0 -row 1 -columnspan 1 -rowspan 1 -sticky ew 
	grid $base.f.02 \
		-in .pgaw:SQLWindow.f -column 1 -row 0 -columnspan 1 -rowspan 1 -sticky ns 
	grid $base.f.t \
		-in .pgaw:SQLWindow.f -column 0 -row 0 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.b1 \
        -in .pgaw:SQLWindow \
        -column 0 \
        -row 1 \
        -columnspan 1 \
        -rowspan 1
    grid $base.b2 \
        -in .pgaw:SQLWindow \
        -column 1 \
        -row 1 \
        -columnspan 1 \
        -rowspan 1
}


proc vTclWindow.pgaw:About {base} {

    if {$base == ""} {
        set base .pgaw:About
    }

    if {[winfo exists $base]} {
        wm deiconify $base
        return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base "500x200+150+250"
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm title $base [intlmsg "About"]

    image create photo $base.ilogo \
        -file [file join $::PgAcVar(PGACCESS_HOME) images logo.gif]
    Label $base.llogo \
        -image $base.ilogo \
        -relief raised
    grid $base.llogo \
        -row 0 \
        -column 0 \
        -rowspan 3

    set maintext [intlmsg "PgAccess
A Tcl/Tk interface to
PostgreSQL
by Constantin Teodorescu
v $::PgAcVar(VERSION)
You will always get the latest version at:
http://www.pgaccess.org
Suggestions at:
developers@pgaccess.org
"]
    Label $base.lmain \
        -text $maintext
    grid $base.lmain \
        -row 0 \
        -column 1


    Label $base.lthnx \
        -text [intlmsg "Thanks to the following:"]
    grid $base.lthnx \
        -row 1 \
        -column 1

    set ::PgAcVar(ABOUT_BYLINES) ""
    Label $base.lbylines \
        -textvariable ::PgAcVar(ABOUT_BYLINES)
    grid $base.lbylines \
        -row 2 \
        -column 1 \
        -sticky n

    grid columnconfigure $base 0 \
        -weight 10
    grid columnconfigure $base 1 \
        -weight 5
    grid rowconfigure $base 0 \
        -weight 10
    grid rowconfigure $base 1 \
        -weight 3
    grid rowconfigure $base 2 \
        -weight 3

    set bylines [list]
    lappend bylines "Bartus Levente - [intlmsg {developer}]"
    lappend bylines "Brett Schwartz - [intlmsg {developer}]"
    lappend bylines "Chris Maj - [intlmsg {developer}]"
    lappend bylines "Iavor Raytchev - [intlmsg {infrastructure}]"
    lappend bylines "Adam Witney & Tony Grant - OSX"
    lappend bylines "Adam Leko - [intlmsg {splash screen}]"
    lappend bylines "Brett Green - graphs"
    lappend bylines "L.J. Bayuk - pgin.tcl"
    lappend bylines "Adrian Davis - ICONS"
    lappend bylines "Bryan Oakley - tkwizard"
    lappend bylines "Csaba Nemethi - Tablelist"
    lappend bylines "Jeff Hobbs - BWidgets & tcllib"
    lappend bylines "F. Voloch - Barcode"
    lappend bylines "Robert Heller - StripPSComments"
    lappend bylines [intlmsg "All who translate intlmsg stuff!"]
    lappend bylines [intlmsg "Everyone who sends patches!"]
    lappend bylines [intlmsg "Our wonderful bug reporters!"]
    lappend bylines [intlmsg "INSERT YOUR NAME HERE"]

    set tymer 0
    foreach by $bylines {
        incr tymer
        set aftr [expr {$tymer*5000}]
        set line ""
        for {set i 0} {$i<[string length $by]} {incr i} {
            append line [string index $by $i]
            set aftr [expr {$aftr+75}]
            after $aftr [subst {set ::PgAcVar(ABOUT_BYLINES) "$line"}]
        }
    }

}
