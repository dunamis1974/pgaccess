#############################################################################
# Visual Tcl v1.11p1 Project
#

#################################
# GLOBAL VARIABLES
#
#global awk; 
#global debug; 
#global no_global_query_symbol;
#global pg_ctl_su;
#global pg_ctl_nowait;
#global post_label;
#global ps; 
#global ps_args; 
#global ps_cmd_col; 
#global ps_heading; 
#global ps_heading_split; 
#global ps_pid_arg; 
#global ps_pid_param; 
#global ps_pre_cmd_params; 
#global super_user; 
#global ps_user_arg; 
#global ps_user_end; 
#global refresh_id; 
#global refresh_interval;
#global show_all; 
#global sort_order; 
#global sort_param; 
#global sort_type; 
#global user;
#global widget; 

#registerPlugin PGMonitor ::Pgmonitor::openWin

namespace eval Pgmonitor {

    variable Win
    variable PgAcVar

    ##
    ##    Initialize the array
    ##
    array set PgAcVar {
        debug 0
        awk "" 
        no_global_query_symbol ""
        pg_ctl_su ""
        pg_ctl_nowait ""
        post_label ""
        ps "" 
        ps_args "" 
        ps_cmd_col "" 
        ps_heading "" 
        ps_heading_split "" 
        ps_pid_arg "" 
        ps_pid_param "" 
        ps_pre_cmd_params "" 
        super_user "" 
        ps_user_arg "" 
        ps_user_end "" 
        refresh_id "" 
        refresh_interval ""
        show_all "" 
        sort_order "" 
        sort_param "" 
        sort_type "" 
        user ""
        widget "" 
        standalone 0
    }
}

#----------------------------------------------------------
# ::Pgmonitor::openWin --
#
#    Opens PG Monitor window, but checks first to see if
#    PGAccess is running locally
#
# Arguments:
#    none
#
# Results:
#    none
# 
#----------------------------------------------------------
#
proc ::Pgmonitor::openWin {} {

    variable Win
    variable PgAcVar

    if {![info exists PgAcVar(initialized)]} {
        set PgAcVar(initialized) 0
    }
    
    ##
    ##  Check to see if it is localhost, blank, or the
    ##  name of the host
    ##
##    if {![regexp "localhost|^$|$::env(HOSTNAME)" $::PgAcVar(opendb,host)]} {
##       showError \
##       "[intlmsg {You must run PGAccess from the local host to use PG Monitor}]"
##
##       return
##    }

    vTclWindow.pgaw:Pgmonitor ""

    if {![winfo exists .query_popup]} {
        vTclWindow.query_popup .query_popup
        Window hide .query_popup
    }
   


    #Window show .pgaw:Pgmonitor
    #Window hide .query_popup

    if {$PgAcVar(initialized) == 0} {
        ::Pgmonitor::widget_init "" "" .pgaw:Pgmonitor
    }
    
    return
    
}; # end proc ::Pgmonitor::openWin

#----------------------------------------------------------
# ::Pgmonitor::close --
#
#    Closes the Pgmonitor window. If it is standalone,
#    then it exits the program. Else, if it is invoked
#    from Pgaccess, then it just closes the window.
#
# Arguments:
#    none
#
# Results:
#    none
# 
#----------------------------------------------------------
#
proc ::Pgmonitor::close {} {

    variable PgAcVar
    variable Win

    if {$PgAcVar(standalone)} {
        exit
    }

    Window hide $Win(base)

    return

}; # end proc ::Pgmonitor::close

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::set_defaults {} {
    #global PgAcVar
    variable PgAcVar
#global debug;
#global show_all;
#global ps;

	# set this to 1 to output debug messages
	set PgAcVar(debug) 0

	# set this to 1 to show all processes, including postmaster
	set PgAcVar(show_all) 0

	# see set_ps_args for customizing ps arguments
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::help {} {
tk_messageBox -type ok -message "pgmonitor
version 0.56

Right-click on an item for help.";
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::adjust_refresh_setting {click_direction} {
    variable PgAcVar
#global refresh_id;
#global refresh_interval;

	if {$PgAcVar(refresh_interval) >= 1 || $click_direction < 1} {
		set PgAcVar(refresh_interval) [expr {$PgAcVar(refresh_interval) - $click_direction}]
	}

	# cancel any previous timeout
	catch {after cancel $PgAcVar(refresh_id)}

	set PgAcVar(refresh_id) [after 500 ::Pgmonitor::show_backends .pgaw:Pgmonitor]
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::save_preferences {} {
    variable PgAcVar
    #global PgAcVar
#global debug;
#global env;
#global refresh_interval;
#global sort_order;
#global sort_param;
#global sort_type;

	# load defaults from user's home directory .pgmonitor file
	if {![catch {open "$env(HOME)/.pgmonitor" w} options_fid]} {
		puts $options_fid 1			;# config file version
		puts $options_fid $PgAcVar(refresh_interval)
		puts $options_fid $PgAcVar(sort_param)
		puts $options_fid $PgAcVar(sort_order)
		puts $options_fid $PgAcVar(sort_type)
		close $options_fid
		if {$PgAcVar(debug)} {puts stdout "Options saved"}
	} else {
		if {$PgAcVar(debug)} {puts stdout "Option save failed:  $options_fid"}
	}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::load_preferences {} {
    variable PgAcVar
    #global PgAcVar
#global debug;
#global env;
#global ps_pid_param;
#global refresh_interval;
#global sort_order;
#global sort_param;
#global sort_type;

	set PgAcVar(sort_param) $PgAcVar(ps_pid_param)
	set PgAcVar(sort_order) ""
	set PgAcVar(sort_type) "n"

	# load defaults from user's home directory .pgmonitor file
	if {![catch {open "$env(HOME)/.pgmonitor" r} options_fid]} {
		if {![catch {gets $options_fid} pgmonitor_version]} {
			if {$pgmonitor_version == 1} {
				if {![eof $options_fid]} {gets $options_fid PgAcVar(refresh_interval)}
				if {![eof $options_fid]} {gets $options_fid PgAcVar(sort_param)}
				if {![eof $options_fid]} {gets $options_fid PgAcVar(sort_order)}
				if {![eof $options_fid]} {gets $options_fid PgAcVar(sort_type)}
				if {$PgAcVar(debug)} {puts stdout "Options loaded"}
			} else {
				if {$PgAcVar(debug)} {puts stdout "Unknown options version"}
			}
		} else {
			if {$PgAcVar(debug)} {puts stdout "Options gets failed with:  $options_fid"}
		}
		close $options_fid
	} else {
		if {$PgAcVar(debug)} {puts stdout "Options file open failed with:  $options_fid"}
	}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::update_post_label {base} {
    variable PgAcVar
    #global PgAcVar
#global debug;
#global pg_ctl_su;
#global pg_ctl_nowait;
#global post_label;

	# if disabled, return immediately
	if {$PgAcVar(pg_ctl_su) == ""} {
		return
	}

	# initialize
	if [catch {set PgAcVar(post_label)}] {
		set PgAcVar(post_label) ""
	}

	catch {eval exec $PgAcVar(pg_ctl_su) -c {"pg_ctl $PgAcVar(pg_ctl_nowait) status | head -1"}} pg_ctl_out
	if {$PgAcVar(debug)} {puts stdout "pg_ctl output:  $pg_ctl_out"}
	
	if [string match "*is running*" $pg_ctl_out] {
		# postmaster is running
		if {$PgAcVar(post_label) == "" ||
		    [string match "Start*" $PgAcVar(post_label)]} {
			set PgAcVar(post_label) "Shutdown"
		}
	} elseif [string match "*not running*" $pg_ctl_out] {
		# postmaster is not running
		if {$PgAcVar(post_label) == "" ||
		    ![string match "Start*"  $PgAcVar(post_label)]} {
			set PgAcVar(post_label) "Startup"
		}
	} else {
                
                if {[winfo ismapped .pgaw:Pgmonitor]} {
 		    tk_messageBox -type ok -message "Unknown response returned by 'pg_ctl status':\n\
                $pg_ctl_out"
                }
		return
	}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::update_post_label_frequently {base} {
    variable PgAcVar

#global post_label;
	
	update_post_label $base
	if {$PgAcVar(post_label) != "Startup" ||
	    $PgAcVar(post_label) != "Shutdown"} {
		# schedule another update
		after 500 ::Pgmonitor::update_post_label_frequently $base
	}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::load_sort_buttons {} {
    variable PgAcVar
#global ps_heading_split;
#global sort_param;

	set i 0
	foreach col $PgAcVar(ps_heading_split) {
		radiobutton .sort_options.column.col_$i  -background #ecf0a4 -highlightthickness 0  -text $col -value $i -variable ::Pgmonitor::PgAcVar(sort_param)
		pack .sort_options.column.col_$i  -in .sort_options.column  -anchor w -expand 0 -fill none  -side top
		incr i
	}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::show_sort_options {popup} {

	if [winfo exists $popup] {
		wm deiconify $popup
	} else {
		Window show $popup
		load_sort_buttons
	}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::start_stop_postmaster {base} {
    variable PgAcVar
    #global PgAcVar
#global debug;
#global pg_ctl_su;
#global pg_ctl_nowait;
#global post_label;
#global super_user;

	if {$PgAcVar(pg_ctl_su) == ""} {
 		tk_messageBox -type ok -message "This can be used only by the PostgreSQL super user or root."
		return
	}

	if [string match "*..." $PgAcVar(post_label)] {
 		tk_messageBox -type ok -message "Change of status already in progress."
		return
	}

        ##
        ## Close down the database before shutting
        ## down postmaster. Ideally, we would use notifies
        ## so that the backend would notify PGAccess of this
        ## going down, but this is not implemented yet.
        ##
        catch {::Mainlib::Database:Close}
	if {$PgAcVar(post_label) == "Startup"} {
		eval exec $PgAcVar(pg_ctl_su) -c {"pg_ctl $PgAcVar(pg_ctl_nowait) start"} >& /dev/null
		set PgAcVar(post_label) "Starting up..."
	} elseif {$PgAcVar(post_label) == "Shutdown"} {
		eval exec $PgAcVar(pg_ctl_su) -c {"pg_ctl $PgAcVar(pg_ctl_nowait) stop"} >& /dev/null
		set PgAcVar(post_label) "Shutdown (force)"
	} elseif {$PgAcVar(post_label) == "Shutdown (force)"} {
		eval exec $PgAcVar(pg_ctl_su) -c {"pg_ctl $PgAcVar(pg_ctl_nowait) -m fast stop"} >& /dev/null
		set PgAcVar(post_label) "Forcing Shutdown..."
	}
	# update label frequently until complete
	after 500 ::Pgmonitor::update_post_label_frequently $base
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::send_signal {base signal} {
    variable PgAcVar
    #global PgAcVar
#global debug;
#global ps;
#global ps_pid_param;
#global refresh_id;

	# find selected process id
	if [catch {$base.list get [$base.list curselection]} cur_selection] {
		tk_messageBox -type ok -message "No process selected."
		return
	}
	#regsub -all "   *" [string trim $cur_selection] " " cur_selection
	#set selection_pid [lindex [split $cur_selection " "] $PgAcVar(ps_pid_param)]
	set selection_pid [lindex $cur_selection $PgAcVar(ps_pid_param)]
	if {$PgAcVar(debug)} {puts stdout "Selected PID:  $selection_pid"}

        if {$signal != 2} {

            ##
            ## Close down the database before shutting
            ## down postmaster. Ideally, we would use notifies
            ## so that the backend would notify PGAccess of this
            ## going down, but this is not implemented yet.
            ##
            catch {::Mainlib::Database:Close}

        }

	# send the signal
	if [catch {exec kill -$signal $selection_pid} err] {
		if [string match "*permit*" $err] {
			tk_messageBox -type ok -message "No permission."
			return
		} elseif [string match "*No such process*" $err] {
			tk_messageBox -type ok -message "Process no longer exists."
			return
		} else {
			tk_messageBox -type ok -message $err
			return
		}
	}
	# cancel any previous timeout
	catch {after cancel $PgAcVar(refresh_id)}

	# update display promptly
	set PgAcVar(refresh_id) [after 500 ::Pgmonitor::show_backends $base]
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::show_query {base popup} {
    variable PgAcVar
    #global PgAcVar
#global debug;
#global no_global_query_symbol;
#global ps;
#global ps_pid_param;
#global super_user;
#global user;

	# find selected process id
	if [catch {$base.list get [$base.list curselection]} cur_selection] {
		tk_messageBox -type ok -message "No process selected."
		return
	}
	regsub -all "   *" [string trim $cur_selection] " " cur_selection
	set selection_pid [lindex [split $cur_selection " "] $PgAcVar(ps_pid_param)]
	if {$PgAcVar(debug)} {puts stdout "Selected PID:  $selection_pid"}

	# clear old contents
	$popup.listboxscroll.border.list delete 0 [expr {[$popup.listboxscroll.border.list size] - 1}]

	# do we have kill() permission.  Easy way to check if we are the proper user.
	if [catch {exec kill -0 $selection_pid} err] {
		if [string match "*permit*" $err] {
			tk_messageBox -type ok -message "No permission."
			return
		} elseif [string match "*No such process*" $err] {
			tk_messageBox -type ok -message "Process no longer exists."
			return
		} else {
			tk_messageBox -type ok -message $err
			return
		}
	}
	if {$PgAcVar(debug)} {puts stdout "Permission check OK for $selection_pid"}

	# connect via gdb and get query string
	if {$PgAcVar(no_global_query_symbol) != "Y"} {
		set gdb_out [exec echo "set print elements 0\nprint (char *)debug_query_string\nquit\n" | sh -c "gdb -q -x /dev/stdin postgres $selection_pid 2>&1;exit 0"]
		if {$PgAcVar(debug)} {puts stdout "gdb output using global symbol is:  $gdb_out"}
		if [string match "*No symbol table*" $gdb_out] {
			tk_messageBox -type ok -message "Postgres pre-7.1.1 executables must have a patch applied or be compiled with debug symbols to use this feature."
			return
		}
		if [string match "*No symbol \"*" $gdb_out] {
			# we set this now and for later show_query calls
			set PgAcVar(no_global_query_symbol) "Y"
		}
	}
	if {$PgAcVar(no_global_query_symbol) == "Y"} {
		set gdb_out [exec echo "set print elements 0\nprint pg_exec_query_string::query_string\nquit\n" | sh -c "gdb -q -x /dev/stdin postgres $selection_pid 2>&1;exit 0"]
		if {$PgAcVar(debug)} {puts stdout "gdb output using function paramater is:  $gdb_out"}
	}

	# interpret gdb output
	# check permit first
	if [string match "* permit*" $gdb_out] {
		if {$PgAcVar(user) == "root"} {
			tk_messageBox -type ok -message "No permission."
			return
		} elseif {$PgAcVar(user) != $PgAcVar(super_user)} {
			tk_messageBox -type ok -message "No permission.  Try running as $PgAcVar(super_user)."
			return
		} else {
			tk_messageBox -type ok -message "No permission.  Try running as root."
			return
		}
	} elseif {[string match "*\$1 = 0x0*" $gdb_out] ||
	    	  [string match "*No frame*" $gdb_out]} {
		tk_messageBox -type ok -message "No query being executed."
		return
	} else {
		# success, popup query window
		if [winfo exists $popup] {
			wm deiconify $popup
		} else {
			Window show $popup
		}
		set query [exec echo "$gdb_out" | grep "\\\$1" |  sed "s/^\[^\"\]*\"//" |  sed "s/\"\$//" | sed "s/\\\\n/\\\n/g"]
		eval {$popup.listboxscroll.border.list insert 0} [split $query "\n"]
	}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::show_backends {base} {
    variable PgAcVar
    #global PgAcVar
#global awk;
#global debug;
#global ps;
#global ps_args;
#global ps_cmd_col;
#global ps_pid_param;
#global ps_pre_cmd_params;
#global super_user;
#global ps_user_arg;
#global ps_user_end;
#global refresh_id;
#global refresh_interval;
#global show_all;
#global sort_order;
#global sort_param;
#global sort_type;

	set ps_out ""

	if {$PgAcVar(debug)} {
		puts stdout "\nps output before awk/sort/cut is:  \n"
		puts stdout [exec $PgAcVar(ps) $PgAcVar(ps_args) $PgAcVar(ps_user_arg) $PgAcVar(super_user) | cut -c$PgAcVar(ps_user_end)-255 | sed -n "2,\$p"]
	}

	# ps, remove user column, non-backend lines, and sort
	if [catch {split [exec $PgAcVar(ps) $PgAcVar(ps_args) $PgAcVar(ps_user_arg) $PgAcVar(super_user) |	cut -c$PgAcVar(ps_user_end)-255 |  sed -n "2,\$p" |  $PgAcVar(awk) "
	{
		cmd=substr(\$0,$PgAcVar(ps_cmd_col));		# get just pgsql-generated status part of line
		gsub(\"\\\\(\[^\\\\)\]*\\\\)\",\"\",cmd); # remove entries around parens, (), *BSD
		gsub(\"^\[^:\]*:\",\"\",cmd);		# remove command with colon, cmd:, Linux
		split(cmd,cmd_split);			# split up db-supplied info
		# <7.1 had bug where fields were swapped on some platforms, correct them
		if (cmd_split\[2\] ~ /^\[0-9\]\[0-9\]*\\.\[0-9\]\[0-9\]*\\.\[0-9\]|^\\\[local\\\]\$|^localhost\$/)
		{
			tmp = cmd_split\[2\];
			cmd_split\[2\] = cmd_split\[3\];
			cmd_split\[3\] = tmp;
		}
		# we try to find only backend processes based on the pgsql status display format;
		# must have at least four params and connect info that is IP address or local
		# localhost in 7.0.X, \[local\] in >=7.1
		if ($PgAcVar(show_all) ||
		    (cmd_split\[4\] != \"\" &&
		     cmd_split\[3\] ~ /^\[0-9\]\[0-9\]*\\.\[0-9\]\[0-9\]*\\.\[0-9\]|^\\\[local\\\]\$|^localhost\$/))
		{
			# prefix line with sorted field
			if ($PgAcVar(sort_param) < $PgAcVar(ps_pre_cmd_params))
				printf \"%s^\", \$[expr {$PgAcVar(sort_param) + 1}];
			else	printf \"%s^\", cmd_split\[[expr {$PgAcVar(sort_param) + 1 - $PgAcVar(ps_pre_cmd_params)}]\];

			# print full process detail line in padded format
			printf \"%s %-10.10s%-10.10s%-17s %-s %-s %-s\\n\",
				substr(\$0,1,[expr {$PgAcVar(ps_cmd_col) - 1}]),
				cmd_split\[1\],cmd_split\[2\],cmd_split\[3\],
				cmd_split\[4\],cmd_split\[5\],cmd_split\[6\];
		}
		# sort by sorted column, then strip it off
	}" | sort -t "^" -$PgAcVar(sort_order)$PgAcVar(sort_type) | cut -d "^" -f2] "\n"} ps_out] {
		showError [intlmsg "ps failed:  $ps_out\nIs PostgreSQL running on this machine?"]
                return 0
	}
	
	# store active selection
	if {![catch {$base.list get [$base.list curselection]} cur_selection]} {
		# get pid of current selection
		regsub -all "   *" [string trim $cur_selection] " " cur_selection
		set selection_pid [lindex [split $cur_selection " "] $PgAcVar(ps_pid_param)]
	} else {
		set selection_pid 0
	}

	#load up the listbox
	$base.list delete 0 [expr {[$base.list size] - 1}]
	eval {$base.list insert 0} $ps_out

	# restore pid selection
	if {$selection_pid != 0} {
		set i 0
		foreach ps_line $ps_out {
			regsub -all "   *" [string trim $ps_line] " " ps_line
			set cur_pid [lindex [split $ps_line " "] $PgAcVar(ps_pid_param)]
			if {$selection_pid == $cur_pid} {
				$base.list selection set $i
				break
			}
			incr i
		}
	}

	update_post_label $base

	# reschedule ourselves
	if {$PgAcVar(refresh_interval) >= 1} {
		set i [expr {$PgAcVar(refresh_interval) * 1000}]
	} else	{
		set i 100
	}

	# if we were called by the Refresh button, cancel old timeout
	catch {after cancel $::Pgmonitor::PgAcVar(refresh_id)}

	set PgAcVar(refresh_id) [after $i ::Pgmonitor::show_backends $base]
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::try_ps_args {argc argv} {
    variable PgAcVar
    #global PgAcVar
#global awk;
#global debug;
#global ps;
#global ps_args;
#global ps_cmd_col;
#global ps_heading;
#global ps_pid_arg;
#global ps_pid_param;
#global super_user;
#global ps_user_arg;
#global ps_user_end;

	# This proc either validates the ps_args, ps_user_arg,
	# ps_pid_arg values, or throws an error.  If successful, derived
	# information is stored into ps_pid_param and other globals.

	# get USER column parameter number
	set ps_heading_user [split [string trim [exec $PgAcVar(ps) $PgAcVar(ps_args) $PgAcVar(ps_pid_arg) 1 2>/dev/null |  sed -n "1p" |  sed "s/  */ /g"]] " "]
	if {$PgAcVar(debug)} {puts stdout "ps_heading_user:  $ps_heading_user"}
	set ps_user_param -1
	set i 0
	foreach col $ps_heading_user {
		if {[lindex $ps_heading_user $i] == "USER" ||
			[lindex $ps_heading_user $i] == "UID"} {
			set ps_user_param $i
			break
		}
		incr i
	}
	if {$ps_user_param == -1} {
		error "Can't find USER/UID column heading"
	}
	if {$PgAcVar(debug)} {puts stdout "ps_user_param:  $ps_user_param"}

	# check other columns before we test for postmaster and
	# and process arg columns
	if {![string match "*PID*" $ps_heading_user]} {
		error "Can't find PID column heading"
	}
	if {![string match "*COMMAND*" $ps_heading_user] &&
	    ![string match "*CMD*" $ps_heading_user]} {
		error "Can't find COMMAND/CMD column heading"
	}
	if {$PgAcVar(debug)} {puts stdout "Found PID and COMMAND/CMD columns"}

	if {$PgAcVar(debug)} {puts stdout "ps command used will be:  $PgAcVar(ps) $PgAcVar(ps_args) $PgAcVar(ps_user_arg) $PgAcVar(super_user)"}

	# get end of user column so it can be clipped off
	if {$ps_user_param == 0} {
		set PgAcVar(ps_user_end) [expr {[string length $PgAcVar(super_user)] + 1}]
	} else {
		set PgAcVar(ps_user_end) 1
	}
	if {$PgAcVar(debug)} {puts stdout "ps_user_end:  $PgAcVar(ps_user_end)"}

	# get PID column parameter number
	set ps_heading_nouser [split [string trim [exec $PgAcVar(ps) $PgAcVar(ps_args) $PgAcVar(ps_pid_arg) 1 | sed -n "1p" | cut -c$PgAcVar(ps_user_end)-255 | sed "s/  */ /g"]] " "]
	if {$PgAcVar(debug)} {puts stdout "ps_heading_nouser:  $ps_heading_nouser"}
	set PgAcVar(ps_pid_param) -1
	set i 0
	foreach col $ps_heading_nouser {
		if {[lindex $ps_heading_nouser $i] == "PID"} {
			set PgAcVar(ps_pid_param) $i
			break
		}
		incr i
	}
	if {$PgAcVar(ps_pid_param) == -1} {
		#puts stderr "Can't find PID column heading"

                if {[winfo ismapped .pgaw:Pgmonitor]} {
                    showError [intlmsg "Can't find PID column heading"]
                }
                return
		#exit 1
	}
	if {$PgAcVar(debug)} {puts stdout "ps_pid_param:  $PgAcVar(ps_pid_param)"}

	# get a new heading without the user column
	set PgAcVar(ps_heading) [exec $PgAcVar(ps) $PgAcVar(ps_args) $PgAcVar(ps_user_arg) $PgAcVar(super_user) | sed -n "1p" | cut -c$PgAcVar(ps_user_end)-255]
	if {$PgAcVar(debug)} {puts stdout "ps_heading:  $PgAcVar(ps_heading)"}

	# find the column of the COMMAND/CMD
	if {[string first "COMMAND" $PgAcVar(ps_heading)] != -1} {
		set PgAcVar(ps_cmd_col) [string first "COMMAND" $PgAcVar(ps_heading)]
	} elseif {[string first "CMD" $PgAcVar(ps_heading)] != -1} {
		set PgAcVar(ps_cmd_col) [string first "CMD" $PgAcVar(ps_heading)]
	} else {
                if {[winfo ismapped .pgaw:Pgmonitor]} {
                    showError [intlmsg "Can't find COMMAND/CMD column heading"]
                }
                return
		#puts stderr "Can't find COMMAND/CMD column heading"
		#exit 1
	}
	if {$PgAcVar(debug)} {puts stdout "ps_cmd_col:  $PgAcVar(ps_cmd_col)"}

	# adjust heading to be the way we want it
	set PgAcVar(ps_heading) [exec echo "$PgAcVar(ps_heading)" |  $PgAcVar(awk) "\{
		printf \"%s %-10.10s%-10.10s%-17s %-s\\n\",
		substr(\$0,1,[expr {$PgAcVar(ps_cmd_col) - 1}]),
		\"USER\", \"DATABASE\", \"CONNECTION\", \"QUERY\"
	\}"]
	if {$PgAcVar(debug)} {puts stdout "ps_heading:  $PgAcVar(ps_heading)"}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::set_ps_args {argc argv} {
    variable PgAcVar
    #global PgAcVar
#global debug;
#global ps;
#global ps_args;
#global ps_pid_arg;
#global ps_user_arg;

	set failure 1

	# If customizing ps columns, the USER should be first,
	# the PID should be second, and COMMAND/CMD last

	#
	# BSD-style ps arguments mean:
	#
	#	x show processes with no controlling terminal
	#	w 132 column display
	#	w another 'w' means display as wide as needed, no limit
	#	o specify list of columns
	#
	#	This option would be nice, but Linux treats it differently
	#	r sort by cpu usage
	#
	# On Linux, args with no dash are BSD args, else SysV
	#
	# set this to customize your ps command
	set PgAcVar(ps) "ps"

	set PgAcVar(ps_args) "xwwouser,pid,start,%mem,vsz,inblk,oublk,state,%cpu,time,command"

	#	U show only certain user's processes
	set PgAcVar(ps_user_arg) "-U"

	#	p show pid
	set PgAcVar(ps_pid_arg) "-p"

	if {$PgAcVar(debug)} {puts stdout "Trying BSD-style ps args"}
	
	if {$failure && 
	    [set failure [catch {try_ps_args $argc $argv} msg]]} {
		if {$PgAcVar(debug)} {puts stdout "Solaris custom ps args failed with:  $msg\nTrying BSD-style -u on Solaris"}
		#	u display user information
		#	x show processes with no controlling terminal
		#	w 132 column display
		#	w another 'w' means display as wide as needed, no limit
		set PgAcVar(ps_args) "uxww"
		# Try Solaris first because this is the one that displays arg changes
		set PgAcVar(ps) "/usr/ucb/ps"
	}

	if {$failure && 
	    [set failure [catch {try_ps_args $argc $argv} msg]]} {
		if {$PgAcVar(debug)} {puts stdout "BSD-style Solaris custom ps args failed with:  $msg\nTrying non-Solaris"}
		# Try ordinary ps
		set PgAcVar(ps) "ps"
	}

 	if {$failure &&
	    [set failure [catch {try_ps_args $argc $argv} msg]] == 1} {
		if {$PgAcVar(debug)} {puts stdout "BSD-style -u ps args failed with:  $msg\nTrying SysV-style"}
		#
		# try SysV-style ps flags:
		#
		#	f display full listing, needs dash
		#	e display all processes
		set PgAcVar(ps_args) "-ef"

		#	u show only certain user's processes
		set PgAcVar(ps_user_arg) "-u"
	}

	if {$failure &&
	    [set failure [catch {try_ps_args $argc $argv} msg]] == 1} {
		error "Can't run 'ps'\nPlease send in a patch.\nSee the README for more information on debugging."
	}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::set_heading {base} {
    variable PgAcVar
    #global PgAcVar
#global debug;
#global ps_heading;
#global ps_heading_split;
#global ps_pre_cmd_params;

	# load the heading
	#$base.listboxscroll.border.heading insert 0  $PgAcVar(ps_heading)

        if {[llength $PgAcVar(ps_heading)] == 0} {return 0}
       
        set Head [list]
        foreach H $PgAcVar(ps_heading) {
            lappend Head 0 [string tolower $H] left
        }
	$base.list configure \
            -columns $Head
	if {$PgAcVar(debug)} {puts stdout "ps_heading is:  $PgAcVar(ps_heading)"}

	# load ps heading values
	regsub -all "   *" [string trim $PgAcVar(ps_heading)] " " PgAcVar(ps_heading_split)
	set PgAcVar(ps_heading_split) [split $PgAcVar(ps_heading_split) " "]
	set PgAcVar(ps_pre_cmd_params) [expr {[llength $PgAcVar(ps_heading_split)] - 4}]
	if {$PgAcVar(debug)} {puts stdout "ps_pre_cmd_params:  $PgAcVar(ps_pre_cmd_params)"}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::set_awk {} {
    variable PgAcVar
    #global PgAcVar
#global awk;
#global debug;

	# find awk version that supports gsub()
	if {![catch {exec echo | awk "{gsub(\".\",\"\")}"}]} {
		set PgAcVar(awk) "awk"
	} elseif {![catch {exec echo | nawk "{gsub(\".\",\"\")}"}]} {
		set PgAcVar(awk) "nawk"
	} elseif {![catch {exec echo | gawk "{gsub(\".\",\"\")}"}]} {
		set PgAcVar(awk) "gawk"
	} else {
		error "Can't find awk version that supports gsub()"
	}
	if {$PgAcVar(debug)} {puts stdout "awk version selected:  $PgAcVar(awk)"}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::set_user {} {
    variable PgAcVar
    #global PgAcVar
#global debug;
#global user;

	if [catch {exec id | cut -d "(" -f2 | cut -d ")" -f1} PgAcVar(user)] {
		tk_messageBox -type ok -message "Can not determine your user name."
		error "'id' command returns: $PgAcVar(user)"
		return
	}
	if {$PgAcVar(debug)} {puts stdout "Username is:  $PgAcVar(user)"}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::set_super_user {argc argv} {
    variable PgAcVar
    #global PgAcVar
#global awk;
#global debug;
#global super_user;
#global env;

	if {[catch {set port "$env(PGPORT)"}]} {
		set port 5432
	}

	# get pg username, either from command line or postmaster process owner
	if {$argc>0} {
		set PgAcVar(super_user) [lindex $argv 0]
	# try PGDATA directory ownership
	} elseif {![catch {exec ls -ld "$env(PGDATA)" | $PgAcVar(awk) "{print \$3}"} PgAcVar(super_user)]} {
	# try user name for postmaster from lock file
	} elseif {![catch {exec ls -l "/tmp/.s.PGSQL.$port.lock" | $PgAcVar(awk) "{print \$3}"} PgAcVar(super_user)]} {
	# try user name for postmaster from socket
	} elseif {![catch {exec ls -l "/tmp/.s.PGSQL.$port" | $PgAcVar(awk) "{print \$3}"} PgAcVar(super_user)]} {
	} else {
                if {[winfo ismapped .pgaw:Pgmonitor]} {
                showError [intlmsg "Can't find Can't find the username of the PostgreSQL server.\
                          Either start the post master, define PGDATA or PGPORT, or\
                          supply the username on the command line."]
                }
                return
		#puts stderr "Can't find the username of the PostgreSQL server.\nEither start the postmaster, define PGDATA or PGPORT, or\nsupply the username on the command line."
		#exit 1
	}
	if {$PgAcVar(debug)} {puts stdout "super_user:  $PgAcVar(super_user)"}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::set_pg_ctl_su {user super_user} {
    variable PgAcVar
#global debug;
#global pg_ctl_su;

	# set pg_ctl_su properly
	if {$super_user == $user} {
		set PgAcVar(pg_ctl_su) "sh"
	} elseif {$user == "root"} {
		# Linux needs -m to preserve environment/PATH
		set PgAcVar(pg_ctl_su) "su -m $super_user"
	} else {
		set PgAcVar(pg_ctl_su) ""
	}
	if {$PgAcVar(debug)} {puts stdout "pg_ctl_su:  $PgAcVar(pg_ctl_su)"}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::set_pg_ctl_nowait {} {
    variable PgAcVar
    #global PgAcVar
#global debug;
#global pg_ctl_nowait;
#global pg_ctl_su;

	# determine no-wait pg_ctl parameter
	if {$PgAcVar(pg_ctl_su) != ""} {
		if [catch {eval exec $PgAcVar(pg_ctl_su) -c {"pg_ctl -W -h"}}] {
			set PgAcVar(pg_ctl_nowait) ""
		} else {
			set PgAcVar(pg_ctl_nowait) "-W"
		}
		if {$PgAcVar(debug)} {puts stdout "pg_ctl_nowait:  $PgAcVar(pg_ctl_nowait)"}
	}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::set_buttons {base user super_user} {
    variable PgAcVar
    #global PgAcVar
#global debug;
#global pg_ctl_su;

	if {$user != "root" && $user != $super_user} {
   		puts stderr "Not running as PostgreSQL super user or root.  Inappropriate buttons removed."
		destroy $base.button.query
		destroy $base.button.cancel
		destroy $base.button.terminate
		destroy $base.button.start_stop
	} else {
		# Is postgres in our path?  If not, remove query button		
		if {[catch {eval exec postgres --help} postgres_out]} {
			puts stderr "Can not find postgres executable.  Query button removed."
			if {$PgAcVar(debug)} {puts stdout "postgres output:  $postgres_out"}
			catch {destroy $base.button.query}
		}
	}

	# Is pg_ctl in our path?  If not, remove postmaster button		
	if {$PgAcVar(pg_ctl_su) != "" &&
	    [catch {eval exec $PgAcVar(pg_ctl_su) -c {"pg_ctl --help"}} pg_ctl_out]} {
		puts stderr "Can not find pg_ctl executable or \$PGDATA not set.  Postmaster status button removed."
		if {$PgAcVar(debug) && $PgAcVar(pg_ctl_su) != ""} {puts stdout "pg_ctl output:  $pg_ctl_out"}
		catch {destroy $base.button.start_stop}
		set PgAcVar(pg_ctl_su) ""
	}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::widget_init {argc argv base} {
    variable PgAcVar
    variable Win
    #global PgAcVar
#global debug;
#global no_#global_query_symbol;
#global super_user;
#global refresh_id;
#global refresh_interval;
#global user;

	if {$base == ""} {
		set base .
	}

	set_defaults
	set_awk;
	set_user;
	set_super_user $argc $argv
	set_pg_ctl_su $PgAcVar(user) $PgAcVar(super_user)
	set_pg_ctl_nowait

	set_ps_args $argc $argv
	set_heading $base
	load_preferences

	set PgAcVar(no_global_query_symbol) "N"

	set_buttons $base $PgAcVar(user) $PgAcVar(super_user)

	show_backends $base

	focus $base.list

	# keyboard defaults
	bind all <Control-c> {destroy .pgaw:Pgmonitor}
	bind .pgaw:Pgmonitor <Destroy> {save_preferences; catch {after cancel $::Pgmonitor::PgAcVar(refresh_id)}}

	# not sure why this is needed, but hangs without it
	# vtcl has trouble with this, not sure why
	bind .pgaw:Pgmonitor <Destroy> {destroy .pgaw:Pgmonitor}
	# vtcl has trouble with this because it is dynamically loaded
	#load_sort_buttons

	wm withdraw .query_popup
	#wm withdraw .sort_options

        set PgAcVar(initialized) 1
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::main {argc argv} {

    variable Win

    widget_init $argc $argv $Win(base)

    return
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Pgmonitor::Window {args} {
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

#################################
# VTCL GENERATED GUI PROCEDURES
#

#proc vTclWindow. {base} {
#    if {$base == ""} {
#        set base .
#    }
#    ###################
#    # CREATING WIDGETS
#    ###################
#    wm focusmodel $base active
#    wm geometry $base 200x200
#    wm maxsize $base 1009 738
#    wm minsize $base 1 1
#    wm overrideredirect $base 0
#    wm resizable $base 1 1
#    wm withdraw $base
#    wm title $base "vt.tcl"
#    ###################
#    # SETTING GEOMETRY
#    ###################
#}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc vTclWindow.query_popup {base} {
    if {$base == ""} {
        set base .query_popup
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    ###################
    # CREATING WIDGETS
    ###################
    toplevel $base -class Toplevel \
        -background #c4eeec -borderwidth 2 
    wm focusmodel $base passive
    wm geometry $base 647x298
    wm maxsize $base 1009 738
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base "Query String"
    frame $base.listboxscroll \
        -background #c4eeec -highlightbackground #c4eeec 
    scrollbar $base.listboxscroll.xscroll \
        -activebackground #ecf0a4 -background #ecf0a4 \
        -command {.query_popup.listboxscroll.border.list xview} \
        -highlightbackground #c4eeec -highlightthickness 0 -orient horizontal \
        -takefocus 0 -troughcolor #c4eeec 
    scrollbar $base.listboxscroll.yscroll \
        -activebackground #ecf0a4 -background #ecf0a4 \
        -command {.query_popup.listboxscroll.border.list yview} \
        -highlightbackground #c4eeec -highlightthickness 0 -takefocus 0 \
        -troughcolor #c4eeec 
    frame $base.listboxscroll.border \
        -background #ecf0a4 -borderwidth 4 -highlightbackground #c4eeec \
        -relief sunken 
    listbox $base.listboxscroll.border.list \
        -background #ecf0a4 -borderwidth 0 -font {Fixed -12 bold} -height 1 \
        -highlightbackground #e8dc4c -highlightthickness 0 -relief flat \
        -selectbackground #dade4a -takefocus 1 -width 1 \
        -xscrollcommand {.query_popup.listboxscroll.xscroll set} \
        -yscrollcommand {.query_popup.listboxscroll.yscroll set} 
    button $base.exit \
        -activebackground #fe4020 -activeforeground #ecf0a4 \
        -background #be4020 -command {wm withdraw .query_popup} \
        -foreground #ecf0a4 -padx 9 -pady 3 -takefocus 1 -text Close 
    ###################
    # SETTING GEOMETRY
    ###################
    pack $base.listboxscroll \
        -in .query_popup -anchor center -expand 1 -fill both -side top
    pack $base.listboxscroll.xscroll \
        -in .query_popup.listboxscroll -anchor center -expand 0 -fill x \
        -side bottom 
    pack $base.listboxscroll.yscroll \
        -in .query_popup.listboxscroll -anchor center -expand 0 -fill y \
        -side right 
    pack $base.listboxscroll.border \
        -in .query_popup.listboxscroll -anchor center -expand 1 -fill both \
        -padx 6 -pady 6 -side top 
    pack $base.listboxscroll.border.list \
        -in .query_popup.listboxscroll.border -anchor center -expand 1 \
        -fill both -padx 5 -pady 6 -side bottom 
    pack $base.exit \
        -in .query_popup -anchor e -expand 0 -fill x -padx 5 -pady 5 \
        -side bottom 
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc vTclWindow.sort_options {base} {
    if {$base == ""} {
        set base .sort_options
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    ###################
    # CREATING WIDGETS
    ###################
    toplevel $base -class Toplevel \
        -background #c4eeec -borderwidth 2 
    wm focusmodel $base passive
    wm geometry $base 244x513
    wm maxsize $base 1009 738
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base "Sort Options"
    label $base.sort_column \
        -background #c4eeec -text Column 
    frame $base.column \
        -background #ecf0a4 -borderwidth 2 -relief sunken 
    label $base.sort_order \
        -background #c4eeec -text Order 
    frame $base.order \
        -background #ecf0a4 -borderwidth 2 -relief sunken 
    radiobutton $base.order.ascending \
        -background #ecf0a4 -highlightthickness 0 -text Ascending \
        -variable ::Pgmonitor::PgAcVar(sort_order) 
    radiobutton $base.order.descending \
        -background #ecf0a4 -highlightthickness 0 -text Descending -value r \
        -variable ::Pgmonitor::PgAcVar(sort_order) 
    label $base.sort_type \
        -background #c4eeec -text Type 
    frame $base.type \
        -background #ecf0a4 -borderwidth 2 -relief sunken 
    radiobutton $base.type.numeric \
        -background #ecf0a4 -highlightthickness 0 -text Numeric -value n \
        -variable ::Pgmonitor::PgAcVar(sort_type) 
    radiobutton $base.type.alphabetic \
        -background #ecf0a4 -highlightthickness 0 -text Alphabetic \
        -variable ::Pgmonitor::PgAcVar(sort_type) 
    button $base.exit \
        -activebackground #fe4020 -activeforeground #ecf0a4 \
        -background #be4020 -command {wm withdraw .sort_options} \
        -foreground #ecf0a4 -padx 9 -pady 3 -takefocus 1 -text Close 
    ###################
    # SETTING GEOMETRY
    ###################
    pack $base.sort_column \
        -in .sort_options -anchor w -expand 1 -fill both -side top 
    pack $base.column \
        -in .sort_options -anchor w -expand 1 -fill x -side top 
    pack $base.sort_order \
        -in .sort_options -anchor w -expand 1 -fill both -side top 
    pack $base.order \
        -in .sort_options -anchor w -expand 1 -fill x -side top 
    pack $base.order.ascending \
        -in .sort_options.order -anchor w -expand 0 -fill none -side top 
    pack $base.order.descending \
        -in .sort_options.order -anchor w -expand 0 -fill none -side top 
    pack $base.sort_type \
        -in .sort_options -anchor w -expand 1 -fill both -side top 
    pack $base.type \
        -in .sort_options -anchor w -expand 1 -fill x -side top 
    pack $base.type.numeric \
        -in .sort_options.type -anchor w -expand 0 -fill none -side top 
    pack $base.type.alphabetic \
        -in .sort_options.type -anchor w -expand 0 -fill none -side top 
    pack $base.exit \
        -in .sort_options -anchor e -expand 0 -fill x -padx 5 -pady 5 \
        -side bottom 
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc vTclWindow.pgaw:Pgmonitor {base} {

    if {$base == ""} {
        set base .pgaw:Pgmonitor
    }

    set ::Pgmonitor::Win(base) $base

    if {[winfo exists $base]} {
        wm deiconify $base; return
    }

    ###################
    # CREATING WIDGETS
    ###################
    toplevel $base -class Pgmonitor \
        -borderwidth 2 
    wm focusmodel $base passive
    wm geometry $base 725x350
    wm maxsize $base 1009 738
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base

    if {([info exists ::env(HOSTNAME)]) && (![string match "" $::env(HOSTNAME)])} {
        wm title $base "pgmonitor - HOST: $::env(HOSTNAME)"

        set Pgmonitor::PgAcVar(status) "HOST: $::env(HOSTNAME)"
    } else {
        wm title $base "pgmonitor"
    }
#    frame $base.listboxscroll \
#        -background #c4eeec -highlightbackground #c4eeec 
    scrollbar $base.xscroll \
        -command {.pgaw:Pgmonitor.list xview} \
        -highlightthickness 0 -orient horizontal \
        -takefocus 0
    scrollbar $base.yscroll \
        -command {.pgaw:Pgmonitor.list yview} \
        -highlightthickness 0 -takefocus 0
#    frame $base.listboxscroll.border \
#        -background #ecf0a4 -borderwidth 4 -highlightbackground #c4eeec \
#        -relief sunken 
#    listbox $base.listboxscroll.border.heading \
#        -background #ecf0a4 -font {Fixed -12 bold} -height 1 \
#        -highlightbackground #e8dc4c -highlightthickness 0 -relief raised \
#        -selectbackground #dade4a -takefocus 0 -width 1 \
#        -xscrollcommand {.pgaw:Pgmonitor.listboxscroll.xscroll set} 
#    listbox $base.listboxscroll.border.list \
#        -background #ecf0a4 -borderwidth 0 -font {Fixed -12 bold} -height 1 \
#        -highlightbackground #e8dc4c -highlightthickness 0 -relief flat \
#        -selectbackground #dade4a -takefocus 1 -width 1 \
#        -xscrollcommand {.pgaw:Pgmonitor.listboxscroll.xscroll set} \
#        -yscrollcommand {.pgaw:Pgmonitor.listboxscroll.yscroll set} 

    set Win(mclist) [tablelist::tablelist $base.list \
        -yscrollcommand {.pgaw:Pgmonitor.yscroll set} \
        -xscrollcommand {.pgaw:Pgmonitor.xscroll set} \
        -labelcommand tablelist::sortByColumn \
        -background #fefefe \
        -stripebg #e0e8f0 \
        -selectbackground #DDDDDD \
        -font {Helvetica 10} \
        -labelfont {Helvetica 11 bold} \
        -stretch all \
        -selectforeground #708090 \
        -labelbackground #DDDDDD \
        -labelforeground navy
        ]

    set body [$Win(mclist) bodypath]
    bind $body <Double-Button-1> [bind TablelistBody <Double-Button-1>]
    bind $body <Double-Button-1> +[list ::Pgmonitor::show_query .pgaw:Pgmonitor .query_popup]
    #bind $base.listboxscroll.border.list <Double-Button-1> {
        #::Pgmonitor::show_query .pgaw:Pgmonitor .query_popup
    #}
    #bind $base.listboxscroll.border.list <Key-Return> {
        #::Pgmonitor::show_query {$base .query_popup}
    #}
    frame $base.button
    button $base.button.refresh \
        -command {after idle {::Pgmonitor::show_backends .pgaw:Pgmonitor}} \
        -padx 9 -pady 3 -takefocus 1 -text Refresh 
    bind $base.button.refresh <Button-3> {
        tk_messageBox -type ok -message "Refreshes the process listing."
    }
    #scrollbar $base.button.refresh_scroll \
        #-command {::Pgmonitor::adjust_refresh_setting} -orient vert \
        #-width 7 
    SpinBox $base.button.refresh_scroll \
        -range {1 500 1} \
        -textvariable ::Pgmonitor::PgAcVar(refresh_interval) \
        -width 5

    set ::Pgmonitor::PgAcVar(refresh_interval) 10

    #label $base.button.refresh_setting \
        #-anchor e -padx 0 -pady 0 -text 1 \
        #-textvariable ::Pgmonitor::PgAcVar(refresh_interval) -width 3 
    label $base.button.seconds \
        -anchor w -padx 0 -pady 3 -text seconds -width 7 
    #button $base.button.sort \
        #-command {::Pgmonitor::show_sort_options .sort_options} \
        #-padx 9 -pady 3 -takefocus 1 -text Sort 
    #bind $base.button.sort <Button-3> {
        #tk_messageBox -type ok -message "Allows sorting of processes."
    #}
    button $base.button.query \
        -command {::Pgmonitor::show_query .pgaw:Pgmonitor .query_popup} \
        -padx 9 -pady 3 -takefocus 1 -text Query 
    bind $base.button.query <Button-3> {
        tk_messageBox -type ok -message "Shows query currently executing by a process.\nDouble-clicking on a process does the same thing."
    }
    button $base.button.cancel \
        -command {::Pgmonitor::send_signal .pgaw:Pgmonitor 2} \
        -padx 9 -pady 3 -takefocus 1 -text Cancel 
    bind $base.button.cancel <Button-3> {
        tk_messageBox -type ok -message "Cancels the currently running query."
    }
    button $base.button.terminate \
        -command {::Pgmonitor::send_signal .pgaw:Pgmonitor 15} \
        -padx 9 -pady 3 -takefocus 1 -text Terminate 
    bind $base.button.terminate <Button-3> {
        tk_messageBox -type ok -message "Terminates the process."
    }
    button $base.button.start_stop \
        -command {::Pgmonitor::start_stop_postmaster .pgaw:Pgmonitor} \
        -padx 9 -pady 3 -takefocus 1 -textvariable ::Pgmonitor::PgAcVar(post_label)
    bind $base.button.start_stop <Button-3> {
        tk_messageBox -type ok -message "Starts up and shuts down the postmaster.  Shutdown waits for all clients to exit.  Shutdown (force) terminates all clients immediately."
    }
    button $base.button.exit \
        -command {::Pgmonitor::close} -padx 9 \
        -pady 3 -takefocus 1 -text Close

    if {$::Pgmonitor::PgAcVar(standalone)} {
        $base.button.exit configure -text Exit
    }
    bind $base.button.exit <Button-3> {
        tk_messageBox -type ok -message "Exits the application."
    }
    button $base.button.help \
        -command ::Pgmonitor::help -padx 9 \
        -pady 3 -takefocus 1 -text Help 
    bind $base.button.help <Button-3> {
        tk_messageBox -type ok -message "You want help about 'help'?"
    }

    frame $base.label
    
    label $base.label.hostname \
        -textvariable ::Pgmonitor::PgAcVar(status) \
        -relief groove \
        -font [list Helvetica 12 bold] \
        -foreground navy
    
    ###################
    # SETTING GEOMETRY
    ###################
    #pack $base.listboxscroll \
        #-in .top -anchor center -expand 1 -fill both -side top 

    pack $base.label \
        -side bottom \
        -anchor w

    pack $base.label.hostname \
        -side left \
        -expand 1 \
        -ipadx 4

    pack $base.button \
        -in .pgaw:Pgmonitor -anchor center -expand 0 -fill x -side bottom 
    pack $base.xscroll \
        -in .pgaw:Pgmonitor -anchor center -expand 0 -fill x -side bottom
    pack $base.yscroll \
        -in .pgaw:Pgmonitor -anchor center -expand 0 -fill y -side right 
    #pack $base.listboxscroll.border \
        #-in .pgaw:Pgmonitor.listboxscroll -anchor center -expand 1 -fill both -padx 6 \
        #-pady 6 -side top 
    #pack $base.listboxscroll.border.heading \
        #-in .pgaw:Pgmonitor.listboxscroll.border -anchor center -expand 0 -fill x \
        #-padx 5 -pady 6 -side top 
    pack $base.list \
        -in .pgaw:Pgmonitor -anchor center -expand 1 -fill both \
        -padx 5 -pady 6 -side top
    pack $base.button.refresh \
        -in .pgaw:Pgmonitor.button -anchor e -expand 0 -fill none -padx 5 -pady 5 \
        -side left 
    pack $base.button.refresh_scroll \
        -in .pgaw:Pgmonitor.button -anchor center -expand 0 -fill none -side left 
    #pack $base.button.refresh_setting \
        #-in .pgaw:Pgmonitor.button -anchor e -expand 0 -fill none -side left 
    pack $base.button.seconds \
        -in .pgaw:Pgmonitor.button -anchor center -expand 0 -fill none -side left 
    #pack $base.button.sort \
        #-in .pgaw:Pgmonitor.button -anchor e -expand 0 -fill none -padx 5 -pady 5 \
        #-side left 
    pack $base.button.query \
        -in .pgaw:Pgmonitor.button -anchor e -expand 1 -fill none -padx 5 -pady 5 \
        -side left 
    pack $base.button.cancel \
        -in .pgaw:Pgmonitor.button -anchor e -expand 0 -fill none -padx 5 -pady 5 \
        -side left 
    pack $base.button.terminate \
        -in .pgaw:Pgmonitor.button -anchor e -expand 0 -fill none -padx 5 -pady 5 \
        -side left 
    pack $base.button.start_stop \
        -in .pgaw:Pgmonitor.button -anchor e -expand 0 -fill none -padx 5 -pady 5 \
        -side left 
    pack $base.button.exit \
        -in .pgaw:Pgmonitor.button -anchor e -expand 0 -fill none -padx 5 -pady 5 \
        -side right 
    pack $base.button.help \
        -in .pgaw:Pgmonitor.button -anchor e -expand 1 -fill none -padx 5 -pady 5 \
        -side right 

}

#Window show .
#Window show .query_popup
#Window show .sort_options
#Window show .top

#main $argc $argv

#puts "PS: $PgAcVar(ps) ARGS: $PgAcVar(ps_args) USER: $PgAcVar(ps_user_arg) SUPER: $PgAcVar(super_user) END: $PgAcVar(ps_user_end)"

##
##  This lets pgmonitor.tcl to startup standalone. Note
##  that at this time, SpinBox and tablelist are required
##
if {([info exists argv0]) && ([string match "pgmonitor.tcl" $argv0])} {
    package require tablelist
    package require BWidget

    Pgmonitor::openWin

    wm withdraw .
    
	.pgaw:Pgmonitor.button.exit configure \
	    -command exit \
		-text exit
}
