#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

# PgAccess versioning
set PgAcVar(MAIN_VERSION) "0.99.0"
set PgAcVar(LAST_BUILD) "20040219"

proc get_version {} {
	# on weekly/beta release
	return "$::PgAcVar(MAIN_VERSION).$::PgAcVar(LAST_BUILD)"
	
	# in devel cvs
	#return "$::PgAcVar(MAIN_VERSION)+.dev(cvs)"
}

image create bitmap dnarw -data  {
#define down_arrow_width 15
#define down_arrow_height 15
static char down_arrow_bits[] = {
	0x00,0x80,0x00,0x80,0x00,0x80,0x00,0x80,
	0x00,0x80,0xf8,0x8f,0xf0,0x87,0xe0,0x83,
	0xc0,0x81,0x80,0x80,0x00,0x80,0x00,0x80,
	0x00,0x80,0x00,0x80,0x00,0x80
	}
}

#----------------------------------------------------------
# registerPlugin --
#
#    Takes care of registering the plugin
#
# Arguments:
#    name_    the name to appear in the plugins menu
#    cmd_     the command to invoke the plugin
#
# Results:
#    none returned.
#----------------------------------------------------------
#
proc registerPlugin {name_ cmd_} {

    if {![info exists ::PgAcVar(plugin,list)]} {
        set ::PgAcVar(plugin,list) [list]
    }
   
    lappend ::PgAcVar(plugin,list) $name_
    set ::PgAcVar(plugin,$name_) $cmd_

    return
    
}; # end proc registerPlugin


#----------------------------------------------------------
# moreText --
#
#   Allows an elipsis (...) button, for example, to open a
#   new window with some text that possibly couldn't be
#   displayed all the way in a user GUI.
#
# Arguments:
#   text_   text to display in the window
#   edit_   1 if possible to save text, 0 if not
#   varn_   variable name to save output text as
#
# Results:
#   none
#----------------------------------------------------------
#
proc moreText {text_ edit_ varn_} {

    global PgAcVar

    set PgAcVar(moreTextSave) 0
    set PgAcVar(moreTextText) $text_
    set PgAcVar(moreTextVarn) $varn_
    set base .pgaw:moreText

    if {[winfo exists $base]} {
        wm deiconify $base
    } else {
        toplevel $base -class Toplevel
        wm focusmodel $base passive
        wm geometry $base 600x500+100+100
        wm overrideredirect $base 0
        wm resizable $base 1 1
        wm deiconify $base
        wm title $base [intlmsg "More Text"]
    }

    bind $base <Control-Key-w> {
        destroy .pgaw:moreText
    }
    if {$edit_} {
        bind $base <Control-Key-s> {
            global PgAcVar
            set PgAcVar(moreTextSave) 1
            set PgAcVar(moreTextText) \
                [string trim [.pgaw:moreText.txt get 1.0 end]]
            destroy .pgaw:moreText
        }
    }
    bind $base <Destroy> {
        global PgAcVar
        if {$PgAcVar(moreTextSave)} {
            set $PgAcVar(moreTextVarn) $PgAcVar(moreTextText)
        }
    }

    text $base.txt \
        -yscrollcommand "$base.yscroll set" \
        -xscrollcommand "$base.xscroll set" \
        -background #ffffff 
    scrollbar $base.yscroll \
        -command "$base.txt yview"
    scrollbar $base.xscroll \
        -orient horiz \
        -command "$base.txt xview"

    Button $base.save \
        -borderwidth 1 \
        -image ::icon::filesave-22 \
        -command {
            global PgAcVar
            set PgAcVar(moreTextSave) 1
            set PgAcVar(moreTextText) \
                [string trim [.pgaw:moreText.txt get 1.0 end]]
            destroy .pgaw:moreText
        }
    Button $base.exit \
        -borderwidth 1 \
        -image ::icon::exit-22 \
        -command {
            Window destroy .pgaw:moreText
        }

    grid $base.txt \
        -row 0 \
        -column 0 \
        -columnspan 2 \
        -sticky news
    grid $base.yscroll \
        -row 0 \
        -column 2 \
        -sticky swn
    grid $base.xscroll \
        -row 1 \
        -column 0 \
        -columnspan 2 \
        -sticky wen
    if {$edit_} {
        grid $base.save \
            -row 2 \
            -column 0 \
            -sticky e
    }
    grid $base.exit \
        -row 2 \
        -column 1 \
        -sticky w
    grid columnconfigure $base 0 \
        -weight 10
    grid columnconfigure $base 1 \
        -weight 10
    grid rowconfigure $base 0 \
        -weight 10

    Window show $base
    $base.txt delete 1.0 end
    $base.txt insert end $text_

}; # end proc moreText


proc say {msg} {
	tk_messageBox -message $msg
}

proc intlmsg {msg} {
global PgAcVar Messages
	if {$PgAcVar(pref,language)=="english"} { return $msg }
	if { ! [array exists Messages] } { return $msg }
	if { ! [info exists Messages($msg)] } {
		debug "Please translate: $msg"
		return $msg
	}
	return $Messages($msg)
}

proc PgAcVar:clean {prefix} {
global PgAcVar
	foreach key [array names PgAcVar $prefix] {
		set PgAcVar($key) {}
		unset PgAcVar($key)
	}
}

proc set_defaults {} {
global PgAcVar CurrentDB
	debug "\nSetting the default values:"

	array set def_vars {
		PgAcVar(currentdb,host) ""
		PgAcVar(currentdb,pgport) 5432
		CurrentDB ""
		PgAcVar(tablist) {Tables Queries Views Sequences Functions Reports Graphs Forms Scripts Images Usergroups Diagrams Types Domains Triggers Indexes Rules Languages Casts Operators Operatorclasses Aggregates Conversions}
		PgAcVar(pgtablist) {Tables Indexes Views Rules Sequences Functions Triggers Aggregates Types Domains Usergroups Languages Conversions Casts Operators Operatorclasses}
		PgAcVar(pgatablist) {Queries Reports Graphs Forms Scripts Images Diagrams}
        PgAcVar(pgtypes) {char varchar text int2 int4 serial float4 float8 money abstime date datetime interval reltime time timespan timestamp boolean box circle line lseg path point polygon}
		PgAcVar(activetab) {}
		PgAcVar(query,tables) {}
		PgAcVar(query,links) {}
		PgAcVar(query,results) {}
		PgAcVar(mwcount) 0
		PgAcVar(PGACCESS_HIDDEN) 0
		PgAcVar(PGACCESS_LOGIN) 0
		PgAcVar(PGACCESS_SMLOGIN) 0
		PgAcVar(PGACCESS_NOAUTO) 0
		PgAcVar(PGACCESS_NOSCRIPT) 0
		PgAcVar(PGACCESS_CONNLOAD) 0
		PgAcVar(opendb,host) "localhost"
		PgAcVar(opendb,pgport) "5432"
		PgAcVar(opendb,dbname) ""
		PgAcVar(opendb,username) ""
		PgAcVar(opendb,password) ""
	}

	foreach i [array names def_vars] {
		if {![info exists $i]} {
			set $i $def_vars($i)
			debug "\t$i: $def_vars($i)"
		}
	}

	# the script's home dir
	if {![info exists PgAcVar(PGACCESS_HOME)]} {
        set tmphome [info script]
        if {[file type $tmphome] == "link"} {
            set home [file dirname [file readlink $tmphome]]
        } else {
            set home [file dirname [info script]]
        }
		switch [file pathtype $home] {
			absolute {set PgAcVar(PGACCESS_HOME) $home}
			relative {set PgAcVar(PGACCESS_HOME) [file join [pwd] $home]}
			volumerelative {
				set curdir [pwd]
				cd $home
				set PgAcVar(PGACCESS_HOME) [file join [pwd] [file dirname [file join [lrange [file split $home] 1 end]]]]
				cd $curdir
			}
		}
		debug "\tPGACCESS_HOME: $PgAcVar(PGACCESS_HOME)"
	}
	
	# The path to the libpgtcl shared object lib.
    # Windows XP is seen as NT, but the Windows directory is called 'windows' and not 'winnt' -
    # change the first switch according to the Windows version you run. (Iavor)
    # also make sure that we arent using PGINTCL

	if {![info exists PgAcVar(PGLIB)] && ![info exists PgAcVar(PGINTCL)]} {
		switch $::tcl_platform(platform) {
            windows {
                switch $::tcl_platform(os) {                    
                    "Windows NT" {
                        set PgAcVar(PGLIB) "c:/windows/system32/" 
                    }
                    "Windows 95" {
                        set PgAcVar(PGLIB) "c:/windows/system/"
                    }
                    default {
                        set PgAcVar(PGLIB) ""
                    }
                }
            }
			unix {
				set PgAcVar(PGLIB) "/usr/lib"
			}
			MacOS {
				# How is this on Macintosh platform?
				set PgAcVar(PGLIB) ""
			}
			default {
				# for all other cases
				set PgAcVar(PGLIB) ""
			}
		}
		debug "\tPGLIB: $PgAcVar(PGLIB)"
	}
}

proc load_conf_file {filename} {
global PgAcVar
	debug "\nLoading the $filename config file:"
	if {![file exists $filename]} {
		return 0
	}
	set fid [open $filename r]
	if {$fid == ""} {
		return 0
	}
	set line_no 0
	while {![eof $fid]} {
		incr line_no
		catch {
			set line [string trim [gets $fid]]
			if {![string equal -length 1 $line "#"] && ![string equal $line ""]} {
				if {[llength [split $line "="]] == 2} {
					set var [string trim [lindex [split $line "="] 0]]
					set value [string trim [lindex [split $line "="] 1]]
					if {$var != ""} {
						set PgAcVar($var) $value
						debug "\t$var: $value"
					} else {
						debug "\tSyntax error ($filename,$line_no): null variable name"
					}
				} else {
					debug "\tSyntax error ($filename,$line_no): too many tokens"
				}
			}
		}
	}
	close $fid
	return 1
}

proc load_env_vars {} {
global PgAcVar env
	debug "\nLoading the enviroment variables:"
	set var_list {PGACCESS_HOME PGLIB PGPORT}

	foreach i $var_list {
		if {![info exists PgAcVar($i)]} {
			if {[info exists env($i)]} {
				set PgAcVar($i) $env($i)
				debug "\t$i: $PgAcVar($i)"
			}
		}
	}
}

proc debug {msg} {
global PgAcVar
	if {![info exists PgAcVar(DEBUG)]} {
		set PgAcVar(DEBUG) false
	}
	if {![info exists PgAcVar(DEBUG_STR)]} {
		set PgAcVar(DEBUG_STR) ""
	}
	if {$PgAcVar(DEBUG_STR) == ""} {
		set PgAcVar(DEBUG_STR) "$msg"
	} else {
		set PgAcVar(DEBUG_STR) "$PgAcVar(DEBUG_STR)\n$msg"
	}
	if {$PgAcVar(DEBUG)} {
        if {[winfo exists .pgaw:Splash]} {
            foreach ln [split $PgAcVar(DEBUG_STR) "\n"] {
                after 50
                if {![string match "\t*" $ln] && ( ![info exists PgAcVar(PGACCESS_NOSPLASH)] ) } {
                    splash_puts [string range [string trim [string trim $ln] ":"] 0 30]
                }
            }
        }
        puts $PgAcVar(DEBUG_STR)
		set PgAcVar(DEBUG_STR) ""
	}
}

proc parse_cmd_line {} {
global PgAcVar argv
    debug "\nParsing the command line parameters:"
    if {[catch {package require cmdline} msg]} {
        debug "\tCouldn't find cmdline package elsewhere on your machine."
        debug "\tNow trying to load the cmdline package from PgAccess."
        debug "\tBut first I need to load some default values to find it..."
        set_defaults
        if {[info exists PgAcVar(PGACCESS_HOME)]} {
            lappend ::auto_path [file join $PgAcVar(PGACCESS_HOME) lib] [file join $PgAcVar(PGACCESS_HOME) lib widgets]
            if {[catch [
                debug ""
                debug "\tcmdline: [package require cmdline]"
                debug "\tGot cmdline package supplied by PgAccess !"
                debug ""
            ] msg]} {
		if {[lsearch argv "-debug"] != -1} {
			set PgAcVar(debug) true
		}
                debug "\tFAILED"
                puts "Error: $msg"
                puts "Please install the tcllib package (http:://www.sourceforge.net/projects/tcllib)"
                exit
            }
        }
	}

	array set cmdline_args {
                dir {.arg "Path to configuration file directory" {
                        set PgAcVar(PGACCESS_DIR) $val
                        debug "\tPGACCESS_DIR: $PgAcVar(PGACCESS_DIR)"
                      }
                }
		pglib {.arg "Path to libpgtcl shared object (dll/so) file" {
					set PgAcVar(PGLIB) $val
					debug "\tPGLIB: $PgAcVar(PGLIB)"
				}
			}
		home {.arg "PGACCESS_HOME" {
					set PgAcVar(PGACCESS_HOME) $val
					debug "\tPGACCESS_HOME: $PgAcVar(PGACCESS_HOME)"
				}
			}
		version {"" "Show version information" {
					puts "\tPGACCESS_VERSION: $PgAcVar(VERSION)"
					exit 0
				}
			}
		debug {"" "Show debug information" {
					set PgAcVar(DEBUG) true
					debug "\tdebug: $PgAcVar(DEBUG)"
				}
			}
		hide {"" "Hide main window (will also disable the splash screen)" {
					set PgAcVar(PGACCESS_HIDDEN) $val
					debug "\tPGACCESS_HIDDEN: $PgAcVar(PGACCESS_HIDDEN)"
					# disable the splash screen too
					set PgAcVar(PGACCESS_NOSPLASH) $val
					debug "\tPGACCESS_NOSPLASH: $PgAcVar(PGACCESS_NOSPLASH)"
				}
			}
		nosplash {"" "Disable splash screen" {
					set PgAcVar(PGACCESS_NOSPLASH) $val
					debug "\tPGACCESS_NOSPLASH: $PgAcVar(PGACCESS_NOSPLASH)"
				}
			}
        noauto {"" "Disables automatic load of connections at startup" {
                    set PgAcVar(PGACCESS_NOAUTO) $val
                    debug "\tPGACCESS_NOAUTO: $PgAcVar(PGACCESS_NOAUTO)"
                }
            }
        noscript {"" "Disables execution of the 'autoexec' script" {
                    set PgAcVar(PGACCESS_NOSCRIPT) $val
                    debug "\tPGACCESS_NOSCRIPT: $PgAcVar(PGACCESS_NOSCRIPT)"
                }
            }
        conn {"" "Automatically loads the connection specified on the command line" {
                    set PgAcVar(PGACCESS_CONNLOAD) $val
                    debug "\tPGACCESS_CONNLOAD: $PgAcVar(PGACCESS_CONNLOAD)"
                }
            }
        login {"" "Displays login dialog at startup" {
                    set PgAcVar(PGACCESS_LOGIN) $val
                    debug "\tPGACCESS_LOGIN: $PgAcVar(PGACCESS_LOGIN)"
                }
            }
        host {.arg "Database host" {
                    set PgAcVar(opendb,host) $val
                    debug "\topendb,host: $PgAcVar(opendb,host)"
                }
            }
        pgport {.arg "Database port" {
                    set PgAcVar(opendb,pgport) $val
                    debug "\topendb,pgport: $PgAcVar(opendb,pgport)"
                }
            }
        dbname {.arg "Database name" {
                    set PgAcVar(opendb,dbname) $val
                    debug "\topendb,dbname: $PgAcVar(opendb,dbname)"
                }
            }
        username {.arg "Database user" {
                    set PgAcVar(opendb,username) $val
                    debug "\topendb,username: $PgAcVar(opendb,username)"
                }
            }
        password {.arg "Database password" {
                    set PgAcVar(opendb,password) $val
                    debug "\topendb,password: $PgAcVar(opendb,password)"
                }
            }
        pgintcl {"" "Uses pgin.tcl frontend/backend protocol v2 (for 6.4<=PG<=7.3), a pure Tcl-PG interface, instead of a dll/so (overrides PGLIB)" {
                    set PgAcVar(PGINTCL) $val
                    debug "\tPGINTCL: $PgAcVar(PGINTCL)"
                }
            }
        pgintcl3 {"" "Uses pgin.tcl frontend/backend protocol v3 (for PG>=7.4), a pure Tcl-PG interface, instead of a dll/so (overrides PGLIB)" {
                    set PgAcVar(PGINTCL) $val
                    set PgAcVar(PGINTCL3) $val
                    debug "\tPGINTCL3: $PgAcVar(PGINTCL3)"
                }
            }
        temp {"" "Creates only TEMPorary PgAccess tables so your database doesn't get cluttered by them." {
                    set PgAcVar(PGACCESS_TEMP) $val
                    debug "\tPGACCESS_TEMP: $PgAcVar(PGACCESS_TEMP)"
                }
            }
        smlogin {"" "Shrinks the login window to ask for only items not specified on the command line" {
                    set PgAcVar(PGACCESS_SMLOGIN) $val
                    set PgAcVar(PGACCESS_LOGIN) $val
                    debug "\tPGACCESS_SMLOGIN: $PgAcVar(PGACCESS_SMLOGIN)"
                    debug "\tPGACCESS_LOGIN: $PgAcVar(PGACCESS_LOGIN)"
                }
            }
        printcmd {.arg "Print command to set as default." {
                    set PgAcVar(PGACCESS_PRINTCMD) $val
                    set PgAcVar(pref,print_cmd) $val
                    debug "\tPGACCESS_PRINTCMD: $PgAcVar(PGACCESS_PRINTCMD)"
                }
            }
        nicepreview {"" "Makes the print preview window for reports nicer." {
                    set PgAcVar(PGACCESS_NICEREPORTPREVIEW) $val
                    debug "\tPGACCESS_NICEREPORTPREVIEW: $PgAcVar(PGACCESS_NICEREPORTPREVIEW)"
                }
            }

	}

	foreach i [lsort [array names cmdline_args]] {
		lappend getopt_list "$i[lindex $cmdline_args($i) 0]"
	}

	while {[set ok [cmdline::getopt argv $getopt_list opt val]] > 0} {
		if {[catch {eval [lindex $cmdline_args($opt) 2]} msg]} {
			puts "Error: $msg ..."
		}
	}

	if {$ok < 0} {
		puts "Error: wrong option"
		foreach i [lsort [array names cmdline_args]] {
			lappend usage_list "$i \{[lindex $cmdline_args($i) 1]\}"
		}
		puts [cmdline::usage $usage_list]
		exit -1
	}
	return 1
}


#----------------------------------------------------------
#----------------------------------------------------------
#
proc init_load_namespaces {{reload_ 0}} {

    global PgAcVar

    # Loading all defined namespaces
    # -- or those we are told explicitly to load
    if {$reload_} {
        debug "\nRe-Loading namespaces:"
        Connections::save
    } else {
        debug "\nLoading namespaces:"
    }
    foreach module {mainlib stack syntax database debug tables queries visualqb forms views functions reports scripts usergroups sequences diagrams help preferences printer importexport connections graphs pgackages images types domains triggers indexes rules languages casts operators operatorclasses aggregates conversions newdbwiz} {
        if {$reload_} {
            if {$module!="mainlib"} {
                foreach ns [namespace children ::] {
                    if {[string match -nocase "??$module" $ns]} {
                        namespace delete $ns
                        debug "\t$module"
                        if {[catch {source [file join $PgAcVar(PGACCESS_HOME) lib $module.tcl]} msg]} {
                            puts "\nERROR: $msg"
                            puts "Please check your installation or set the PGACCESS_HOME ($PgAcVar(PGACCESS_HOME)) variable properly!" 
                            exit -1
                        }
                    }
                }
            }
        } else {
            debug "\t$module"
            if {[catch {source [file join $PgAcVar(PGACCESS_HOME) lib $module.tcl]} msg]} {
                puts "\nERROR: $msg"
                puts "Please check your installation or set the PGACCESS_HOME ($PgAcVar(PGACCESS_HOME)) variable properly!" 
                exit -1
            }
        }
    }

    if {$reload_} {
        Connections::load
    }

}; # end proc init_load_namespaces


#----------------------------------------------------------
#----------------------------------------------------------
#
proc init_load_plugins {} {

    global PgAcVar

	##  Loadin plugins
	debug "\nLoading plugins:"
	foreach plugin [glob -nocomplain [file join $PgAcVar(PGACCESS_HOME) lib plugins *.tcl]] {
        set plug [file rootname [file tail $plugin]]
        # special check for pgin.tcl
        # extra special check for frontend/backend protocol
        if { [string match "pgin*" $plug] } {
            if { [info exists PgAcVar(PGINTCL)] } {
                if { [info exists PgAcVar(PGINTCL3)] } {
                    if { [string match "pgin3" $plug] } { 
                        debug "\t$plug"
                        source $plugin
                    }
                } else {
                    if { [string match "pgin2" $plug] } {
                        debug "\t$plug"
                        source $plugin
                    }
                }
            }
        } else {
            debug "\t$plug"
            source $plugin
        }

	}

}; # end proc init_load_plugins

#----------------------------------------------------------
#----------------------------------------------------------
#
proc init_load_required_packages {} {

    global PgAcVar

	#  Loading the required packages
	debug "\nLoading the required packages:"
	lappend ::auto_path [file join $PgAcVar(PGACCESS_HOME) lib] [file join $PgAcVar(PGACCESS_HOME) lib widgets]
	if {[catch [
		debug "\ttablelist: [package require tablelist 3.3]"
		debug "\tBWidget: [package require BWidget 1.6.0]"
		debug "\ticons: [package require icons]"
		debug "\tbase64: [package require base64]"
		debug "\tcsv: [package require csv]"
		debug "\tfileutil: [package require fileutil]"
		debug "\ttkwizard: [package require tkwizard]"
		debug "\tBarcode: [package require Barcode]"
	] msg]} {
		puts "\nERROR: $msg"
		puts "\n[intlmsg {Please install the required packages:}]\n"
		puts "\ttablelist: http:://www.nemethi.de"
		puts "\ttcllib: http:://www.sourceforge.net/projects/tcllib"
		puts "\tBWidget: http:://www.sourceforge.net/projects/tcllib"
		puts "\ttkwizard: http://www2.clearlight.com/~oakley/tcl/tkwizard/"
		exit -1
	}

}; # end proc init_load_required_packages


proc init {argc argv} {
global PgAcVar CurrentDB env
	set PgAcVar(VERSION) [get_version]
	if {[info exists env(HOME)]} {
		set PgAcVar(HOME) $env(HOME)
	} else {
		set PgAcVar(HOME) ""
	}

	parse_cmd_line
	load_env_vars

	if {![info exists PgAcVar(PGACCESS_DIR)]} {
		# PGACCESS_DIR - the directory for the conf files
		set PgAcVar(PGACCESS_DIR) [file join $PgAcVar(HOME) .pgaccess]
		if {![file exists $PgAcVar(PGACCESS_DIR)]} {
			debug "Creating $PgAcVar(PGACCESS_DIR) ..."
			if {[catch [file mkdir $PgAcVar(PGACCESS_DIR)] msg]} {
				debug "\tWarning: the $PgAcVar(PGACCESS_DIR) directory for storing the config stuff cannot be created ($msg)."
			}
		}
	}

	if {![info exists PgAcVar(PGACCESS_CFG)]} {
		# PGACCESS_CFG - the main config file
		set PgAcVar(PGACCESS_CFG) [file join $PgAcVar(PGACCESS_DIR) pgaccess.cfg]
		if {![file exists $PgAcVar(PGACCESS_CFG)]} {
			debug "Creating $PgAcVar(PGACCESS_CFG) ..."
			if {[catch {
				set fid [open $PgAcVar(PGACCESS_CFG) w]
				puts $fid "# PgAccess main config file"
				puts $fid ""
				puts $fid "# path to libpgtcl"
				if {[info exists PgAcVar(PGLIB)]} {
					puts $fid "# PGLIB = $PgAcVar(PGLIB)"
				} else {
					puts $fid "# PGLIB = /usr/lib"
				}
				puts $fid ""
				puts $fid "# script path"
				if {[info exists PgAcVar(PGACCESS_HOME)]} {
					puts $fid "# PGACCESS_HOME = $PgAcVar(PGACCESS_HOME)"
				} else {
					puts $fid "# PGACCESS_HOME = /usr/lib/pgaccess"
				}
				puts $fid ""
				close $fid
			} msg]} {
				debug "\tWarning: the $PgAcVar(PGACCESS_CFG) config file cannot be created ($msg)."
			}
		}
	}

	if {![info exists PgAcVar(PGACCESS_RC)]} {
		# PGACCESS_RC - the rc file
		set PgAcVar(PGACCESS_RC) [file join $PgAcVar(PGACCESS_DIR) pgaccessrc]
		if {![file exists $PgAcVar(PGACCESS_RC)]} {
			debug "Creating $PgAcVar(PGACCESS_RC) ..."
			if {[catch {
				set fid [open $PgAcVar(PGACCESS_RC) w]
				puts $fid ""
				close $fid
			} msg]} {
				debug "\tWarning: the $PgAcVar(PGACCESS_RC) file cannot be created ($msg)."
			}
		}
	}

	if {![info exists PgAcVar(PGACCESS_CONN)]} {
		# PGACCESS_CONN - th connections file
		set PgAcVar(PGACCESS_CONN) [file join $PgAcVar(PGACCESS_DIR) connections]
		if {![file exists $PgAcVar(PGACCESS_CONN)]} {
			debug "Creating $PgAcVar(PGACCESS_CONN) ..."
			if {[catch {
				set fid [open $PgAcVar(PGACCESS_CONN) w]
				puts $fid ""
				close $fid
			} msg]} {
				debug "\tWarning: the $PgAcVar(PGACCESS_CONN) file cannot be created ($msg)."
			}
		}
	}

	if {![load_conf_file $PgAcVar(PGACCESS_CFG)]} {
		debug "Main config file [file join $PgAcVar(PGACCESS_DIR) $PgAcVar(PGACCESS_CFG)] not found falling back to default settings."
	}

	set_defaults

	# since the splash needs to know where PGACCESS_HOME is, wait to display
	# it until after set_defaults is called
	if {![info exists PgAcVar(PGACCESS_NOSPLASH)]} {
		Window show .pgaw:Splash
		update
	}

    debug "\nLoading the Tcl-PostgreSQL interface:"
    # only load PGLIB if PGINTCL not specified on command line
    if { ![info exists PgAcVar(PGINTCL)] } {
        debug "\tCouldn't use pgin.tcl, the pure Tcl interface."
        # now that pgtcl is a proper tcl package, try it
        if {[catch {package require Pgtcl} msg]} {
            debug "\tCouldn't use the new Pgtcl package."
			set shlib [file join $PgAcVar(PGLIB) libpgtcl][info sharedlibextension]
			if {![file exists $shlib]} {
				debug "\nError: Shared library file: '$shlib' does not exist. \n\
					Check this file, or check PGLIB variable (in pgaccess.cfg)\n"
                debug "====> Using pgin.tcl instead\n"
                set PgAcVar(PGINTCL) 1
			}
    
			if {[catch {load $shlib} err]} {
				debug "Error: can not load $shlib shared library."
				debug "You need to make sure that the library exists and"
				debug "the environment variable PGLIB points to the directory"
				debug "where it is located.\n"
				debug "If you use Windows, be sure that the needed libpgtcl.dll"
				debug "and libpq.dll files are copied in the Windows/System"
				debug "directory"
				debug "\nERROR MESSAGE: $err\n"
                debug "====> Using pgin.tcl instead\n"
                set PgAcVar(PGINTCL) 1
			} else {
                debug "\tLoaded the old libpgtcl shared library."
            }
        } else {
            debug "\tLoaded the new Pgtcl package."
        }; # end check of package require pgtcl
    } else {
        debug "\tWill try loading the pgin.tcl plugin soon."
    }

    splash_percent 10
    init_load_namespaces

    splash_percent 50
    init_load_plugins

    splash_percent 60
	Preferences::load

    splash_percent 70
	Connections::load

    splash_percent 80
    init_load_required_packages

    splash_percent 90
	# Creating icons
	debug "\nCreating icons:"
	::icons::icons create \
		-file [file join $PgAcVar(PGACCESS_HOME) lib widgets icons1.0 tkIcons-sample.slick] \
		{filenew-22 fileopen-22 edit-22 back-22 forward-22 reload-22 fileclose-22 editcopy-22 edittrash-22 move-22 connect_creating-22 filter1-22 cancel-22 down-22 up-22 configure-22 decrypted-22 encrypted-22 connect_no-22 exit-22 people-16 system-16 network_local-16 misc-16 thumbnail-16 txt-16 desktop_flat-16 widget_doc-16 shellscript-16 queue-16 completion-16 edit-16 1rightarrow-22 1leftarrow-22 fileprint-22 wizard-22 run-22 rever-22 filesave-22 colorize-16 view_tree-16 font_truetype-16 view_icon-16 view_text-16 xapp-16 news-16 go-16 spellcheck-16 stop-16 2rightarrow-22 2leftarrow-22 editcut-16 hotlistadd-16 hotlistdel-16 filesaveas-22 imagegallery-22 editdelete-22 start-22 finish-22 player_stop-22 player_eject-22 kpresenter-16 package_toys-16 user-16 krayon-16 contents2-16 help-22 key_bindings-16 blockdevice-16 view_sidetree-16 kcmprocessor-16 package_games1-16 view_sidetree-16 remote-16 earth-16 info-16 contents2-16 kteatime-16 source_java-16 penguin-16 contents-16}

}; # end proc init

proc wpg_exec {db cmd} {
global PgAcVar
	set PgAcVar(pgsql,cmd) "never executed"
	set PgAcVar(pgsql,status) "no status yet"
	set PgAcVar(pgsql,errmsg) "no error message yet"
	if {[catch {
		Mainlib::sqlw_display "-----BEGIN----------------------------------------"
		Mainlib::sqlw_display $cmd
		set PgAcVar(pgsql,cmd) $cmd
		set PgAcVar(pgsql,res) [pg_exec $db $cmd]
		set PgAcVar(pgsql,status) [pg_result $PgAcVar(pgsql,res) -status]
		set PgAcVar(pgsql,errmsg) [pg_result $PgAcVar(pgsql,res) -error]
	} tclerrmsg]} {
		showError [format [intlmsg "Tcl error executing pg_exec %s\n\n%s"] $cmd $tclerrmsg]
		return 0
	}
	Mainlib::sqlw_display $PgAcVar(pgsql,res)
	Mainlib::sqlw_display "-----END-----------------------------------------"
	return $PgAcVar(pgsql,res)
}


proc wpg_select {args} {
	Mainlib::sqlw_display "-----BEGIN----------------------------------------"
	Mainlib::sqlw_display "[lindex $args 1]"
	Mainlib::sqlw_display "-----END-----------------------------------------"
	uplevel pg_select $args
}


proc create_drop_down {base x y w} {
global PgAcVar
	if {[winfo exists $base.ddf]} return;
	frame $base.ddf -borderwidth 1 -height 75 -relief raised -width 55
	listbox $base.ddf.lb -background #fefefe -foreground #000000 -selectbackground #c3c3c3 -borderwidth 1  -font $PgAcVar(pref,font_normal)  -highlightthickness 0 -selectborderwidth 0 -yscrollcommand [subst {$base.ddf.sb set}]
	scrollbar $base.ddf.sb -borderwidth 1 -command [subst {$base.ddf.lb yview}] -highlightthickness 0 -orient vert
	place $base.ddf -x $x -y $y -width $w -height 185 -anchor nw -bordermode ignore
	place $base.ddf.lb -x 1 -y 1 -width [expr $w-18] -height 182 -anchor nw -bordermode ignore
	place $base.ddf.sb -x [expr $w-15] -y 1 -width 14 -height 183 -anchor nw -bordermode ignore
}


proc setCursor {{type NORMAL}} {
	if {[lsearch -exact "CLOCK WAIT WATCH" [string toupper $type]] != -1} {
		set type watch
	} else {
		set type left_ptr
	}
	foreach wn [winfo children .] {
		catch {$wn configure -cursor $type}
	}
	update ; update idletasks 
}


proc parameter {msg} {
global PgAcVar
	Window show .pgaw:GetParameter
	focus .pgaw:GetParameter.e1
	set PgAcVar(getqueryparam,var) ""
	set PgAcVar(getqueryparam,flag) 0
	set PgAcVar(getqueryparam,msg) $msg
	bind .pgaw:GetParameter <Destroy> "set PgAcVar(getqueryparam,flag) 1"
	grab .pgaw:GetParameter
	tkwait variable PgAcVar(getqueryparam,flag)
	if {$PgAcVar(getqueryparam,result)} {
		return $PgAcVar(getqueryparam,var)
	} else {
		return ""
	}
}


# show the error
# provide a link to help if one was specified
proc showError {emsg {helptopic {}}} {
global PgAcVar
    set blist [list "OK" "Help"]
    bell ;
    debug $emsg
    if {$PgAcVar(pref,erroremailuse)} {
        lappend blist "Report"
    }
    set res [MessageDlg .pgacErrorDlg \
        -title [intlmsg "Error"] \
        -icon error \
        -message $emsg \
        -type user \
        -buttons $blist]
    switch $res {
        0 {
            # they hit ok
        }
        1 {
            # they need help
            if {[string length $helptopic]>0} {
                Help::load $helptopic
            } else {
                Help::load index
            }
        }
        2 {
            # they want to report the error
            tk_messageBox -message "Soon you might be able to email bug reports.\nBut not yet."
        }
        default {
            # what did they hit
            debug "You should never see this."
        }
    }; # end switch
}


#----------------------------------------------------------
# executes a line of sql
#----------------------------------------------------------
#
proc sql_exec {how cmd {dbh_ ""}} {

    global PgAcVar CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    if {[set pgr [wpg_exec $dbh_ $cmd]]==0} {
        return 0
    }

    if {($PgAcVar(pgsql,status)=="PGRES_COMMAND_OK") || ($PgAcVar(pgsql,status)=="PGRES_TUPLES_OK")} {
        pg_result $pgr -clear
        return 1
    }

    if {$how != "quiet"} {
        showError [format [intlmsg "Error executing query\n\n%s\n\nPostgreSQL error message:\n%s\nPostgreSQL status:%s"] $cmd $PgAcVar(pgsql,errmsg) $PgAcVar(pgsql,status)]
    }

    pg_result $pgr -clear

    return 0

}



proc main {argc argv} {

    global PgAcVar CurrentDB tcl_platform env

    Window show .pgaw:Main

    set tdb ""
    set thost ""

    if {[info exists PgAcVar(pref,lastdb)] \
        && [info exists PgAcVar(pref,lasthost)]} {
        set tdb $PgAcVar(pref,lastdb)
        set thost $PgAcVar(pref,lasthost)
    }

    # dont squash the commandline args if they were provided
    if {![info exists PgAcVar(opendb,host)]} {
        set PgAcVar(opendb,host) {}
    }
    if {![info exists PgAcVar(opendb,dbname)]} {
        set PgAcVar(opendb,dbname) {}
    }
    if {![info exists PgAcVar(opendb,pgport)]} {
        set PgAcVar(opendb,pgport) 5432
    }
    if {![info exists PgAcVar(opendb,username)]} {
        set PgAcVar(opendb,username) {}
    }
    set PgAcVar(opendb,password) {}

    ##
    ## Check to see if connections should be opened automagically
    ##
    if {$PgAcVar(pref,autoload) && !$PgAcVar(PGACCESS_NOAUTO)} {
        ##
        ##  Load all dbs that are in the connections file
        ##
        foreach H [::Connections::getHosts] {

            foreach d [::Connections::getDbs $H] {

                set i [::Connections::getIds $H $d]

                if {[llength $i] != 1} {
                    puts stderr "\nERROR: There seems to be a problem with your connections file."
                    puts stderr "A host/db combination should be unique and the db should not be empty string"
                    puts stderr "Check host/db:  $H/$d with ids: $i"
                    puts stderr "Try removing the ~/.pgaccess/connections file"
                    puts stderr "Skipping this host/db combination\n"
                    continue
                }

                if {![info exists ::Connections::Conn(autoload,$i)]} {
                    set ::Connections::Conn(autoload,$i) 1
                }

                if {$::Connections::Conn(autoload,$i) == 0} {
                     continue
                }

                if {![::Connections::openConn $i]} {
                    debug "$::Connections::Msg($i)"
                    # display the open conn window
                    if {![::Connections::openConn $i 1]} {
                        continue
                    }
                }

                ::Mainlib::addDbNode $H $d

            }; # end foreach DB

        }; # end foreach host

        #Connections::check

       ##
       ##  Open up the tree node for the last db
       ##
       if {[string match "" $thost]} {set thost sockets}

       if {(![string match "" $tdb]) && ([$::Mainlib::Win(tree) exists __db__-${thost}-${tdb}])} {

            if {[$::Mainlib::Win(tree) exists __host__-$thost]} {
                $::Mainlib::Win(tree) opentree __host__-$thost 0
            }
            if {[$::Mainlib::Win(tree) exists __db__-${thost}-$tdb]} {
                $::Mainlib::Win(tree) opentree __db__-${thost}-$tdb
                ::Mainlib::select 1 __db__-${thost}-$tdb
            }
       }

    }; # end if autoload (or if NO_AUTO doesnt exist)

    wm protocol . WM_DELETE_WINDOW {
        ::Mainlib::Exit
    }

    return
}


proc Window {args} {
global vTcl
	set cmd [lindex $args 0]
	set name [lindex $args 1]
	set newname [lindex $args 2]
	set rest [lrange $args 3 end]
	if {$name == "" || $cmd == ""} {return}
	if {$newname == ""} {
		set newname $name
	}
	set exists [winfo exists $newname]
	switch $cmd {
		show {
			if {$exists == "1" && $name != "."} {wm deiconify $name; return}
			if {[info procs vTclWindow(pre)$name] != ""} {
				eval "vTclWindow(pre)$name $newname $rest"
			}
			if {[info procs vTclWindow$name] != ""} {
				eval "vTclWindow$name $newname $rest"
			}
			if {[info procs vTclWindow(post)$name] != ""} {
				eval "vTclWindow(post)$name $newname $rest"
			}
		}
		hide    { if $exists {wm withdraw $newname; return} }
		iconify { if $exists {wm iconify $newname; return} }
		destroy { if $exists {destroy $newname; return} }
	}
}

proc vTclWindow. {base} {
	if {$base == ""} {
		set base .
	}
	wm focusmodel $base passive
	wm geometry $base 1x1+0+0
	wm maxsize $base 1009 738
	wm minsize $base 1 1
	wm overrideredirect $base 0
	wm resizable $base 1 1
	wm withdraw $base
	wm title $base "vt.tcl"
}

proc vTclWindow.pgaw:Splash {base} {
global PgAcVar
	if {$base == ""} {
		set base .pgaw:Splash
	}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	toplevel $base

	wm resizable $base 0 0
	wm overrideredirect $base 1
	wm protocol $base WM_DELETE_WINDOW {#don't allow people to close this window}

	image create photo $base.logo -file [file join $PgAcVar(PGACCESS_HOME) images logo.gif]
	label $base.logocont -image $base.logo -relief raised
	pack $base.logocont  -padx 10 -pady 10

	frame $base.frame
	pack $base.frame

	label $base.message1 -text "pgaccess.org"
	pack $base.message1 

	label $base.message2 
	pack $base.message2 

	canvas $base.bar -bg darkblue -width 0 -height 20 -relief raised -bd 4
	pack $base.bar -side left -padx 4 -pady 10

	update idletasks

	set left [expr {[winfo screenwidth $base] / 2 - [winfo width $base] / 2}]
	set top [expr {[winfo screenheight $base] / 2 - [winfo height $base] / 2}]
	wm geometry $base +$left+$top

}

proc splash_puts {data {mainevent 0}} {
	if {$mainevent} {
		.pgaw:Splash.message1 config -text $data
		.pgaw:Splash.message2 config -text ""
	} else {
		.pgaw:Splash.message2 config -text $data
	}
	update
}

proc splash_percent {percent} {
global PgAcVar
	# short circuit if splash is disabled
	if {![info exists PgAcVar(PGACCESS_NOSPLASH)]} {
		.pgaw:Splash.bar config -width [expr {($percent / 100.0) * 
			([winfo height .pgaw:Splash] - 30)}]
		update idletasks
	}
}

Window hide .
if {![info exists PgAcVar(PGACCESS_NOSPLASH)]} {
	set splash_clock [clock seconds]
}

init $argc $argv

debug [intlmsg "\nOpening the main window..."]
update
splash_percent 99

main $argc $argv

if {![info exists PgAcVar(PGACCESS_NOSPLASH)]} {
	while {[expr {[clock seconds] - $splash_clock}] < 2} {
	    after 100
	}
	wm withdraw .pgaw:Splash
}

if {$PgAcVar(PGACCESS_HIDDEN)} {
	Window hide .
	# wm iconify .
} else {
	wm deiconify .
}

# checking if we should connect based on the given command line parameters
# this looks a little gross, but some modules rely on the GUI a bit too much
if {$PgAcVar(PGACCESS_CONNLOAD) || $PgAcVar(PGACCESS_LOGIN)} {
    if {[::Connections::openConn 0 $PgAcVar(PGACCESS_LOGIN) $PgAcVar(PGACCESS_SMLOGIN)]} {
        set H $PgAcVar(opendb,host)
        set d $PgAcVar(opendb,dbname)
        if {![$::Mainlib::Win(tree) exists __db__-${H}-${d}]} {
            ::Mainlib::addDbNode $H $d
        }
        if {[$::Mainlib::Win(tree) exists __host__-$H]} {
            $::Mainlib::Win(tree) opentree __host__-$H 0
        }
        if {[$::Mainlib::Win(tree) exists __db__-${H}-$d]} {
            $::Mainlib::Win(tree) opentree __db__-${H}-$d
        }
        if {[$::Mainlib::Win(tree) exists __host__-$H]} {
            ::Mainlib::select 1 __host__-$H
        }
        if {[$::Mainlib::Win(tree) exists __db__-${H}-$d]} {
            ::Mainlib::select 1 __db__-${H}-$d
        }
        # ::Mainlib::cmd_Tables
    } else {
        showError [intlmsg "Cannot login, possible bad connection parameters"]
    }
}







