# pgin.tcl - PostgreSQL Tcl Interface direct to protocol v2 backend
# $Id: pgin.tcl,v 1.27 2003-06-30 23:05:42+00 lbayuk Exp $
#
# Copyright 2003 by ljb (lbayuk@mindspring.com)
# May be freely distributed with or without modification; must retain this
# notice; provided with no warranties.
# See the file COPYING for complete information on usage and redistribution
# of this file, and for a disclaimer of all warranties.
#
# Also includes:
#    md5.tcl - Compute MD5 Checksum

namespace eval pgtcl {
  # Debug flag:
  variable debug 0

  # Internal version number:
  variable version 1.5.0

  # Counter for making uniquely named result structures:
  variable rn 0

  # Function OID cache, indexed by function name, self initializing:
  variable fnoids

  # Array of notification information, indexed on $conn,$relname:
  variable notify

  # Value to use for NULL results:
  variable nulls {}

  # Command to execute when a NOTICE message arrives.
  # The message text argument will be appended to the command.
  # Like libpq, we expect the message to already have a newline.
  variable notice {puts -nonewline stderr}
}

# Internal procedure to set a default value from the environment:
proc pgtcl::default {default args} {
  global env
  foreach a $args {
    if {[info exists env($a)]} {
      return $env($a)
    }
  }
  return $default
}

# Internal routine to read a null-terminated string from the PostgreSQL backend.
# String is stored in the 2nd argument if given, else it is returned.
# I wish there was a more efficient way to do this!
proc pgtcl::gets {sock {s_name ""}} {
  if {$s_name != ""} {
    upvar $s_name s
  }
  set s ""
  while {[set c [read $sock 1]] != "\000"} {
    append s $c
  }
  if {$s_name == ""} {
    return $s
  }
}

# Internal procedure to parse a connection info string.
# This has to handle quoting and escaping. See the PostgreSQL Programmer's
# Guide, Client Interfaces, Libpq, Database Connection Functions.
# The definitive reference is the PostgreSQL source code in:
#          interface/libpq/fe-connect.c:conninfo_parse()
# One quirk to note: backslash escapes work in quoted values, and also in
# unquoted values, but you cannot use backslash-space in an unquoted value,
# because the space ends the value regardless of the backslash.
#
# Stores the results in an array $result(paramname)=value. It will not
# create a new index in the array; if paramname does not already exist,
# it means a bad parameter was given (one not defined by pg_conndefaults).
# Returns an error message on error, else an empty string if OK.
proc pgtcl::parse_conninfo {conninfo result_name} {
  upvar $result_name result
  while {[regexp {^ *([^=]*)= *(.+)} $conninfo unused name conninfo]} {
    set name [string trim $name]
    if {[regexp {^'(.*)} $conninfo unused conninfo]} {
      set value ""
      set n [string length $conninfo]
      for {set i 0} {$i < $n} {incr i} {
        if {[set c [string index $conninfo $i]] == "\\"} {
          set c [string index $conninfo [incr i]]
        } elseif {$c == "'"} break
        append value $c
      }
      if {$i >= $n} {
        return "unterminated quoted string in connection info string"
      }
      set conninfo [string range $conninfo [incr i] end]
    } else {
      regexp {^([^ ]*)(.*)} $conninfo unused value conninfo
      regsub -all {\\(.)} $value {\1} value
    }
    if {$pgtcl::debug} { puts "+parse_conninfo name=$name value=$value" }
    if {![info exists result($name)]} {
      return "invalid connection option \"$name\""
    }
    set result($name) $value
  }
  if {[string trim $conninfo] != ""} {
    return "syntax error in connection info string '...$conninfo'"
  }
  return ""
}

# Internal procedure to check for valid result handle. This returns
# the fully qualified name of the result array.
# Usage:  upvar #0 [pgtcl::checkres $res] result
proc pgtcl::checkres {res} {
  if {![info exists pgtcl::result$res]} {
    error "Invalid result handle\n$res is not a valid query result"
  }
  return "pgtcl::result$res"
}

# Return connection defaults as {optname label dispchar dispsize value}...
proc pg_conndefaults {} {
  set user [pgtcl::default user PGUSER USER LOGNAME USERNAME]
  set result [list \
    [list user     Database-User    {} 20 $user] \
    [list password Database-Password *  20 [pgtcl::default {} PGPASSWORD]] \
    [list host     Database-Host    {} 40 [pgtcl::default localhost PGHOST]] \
         {hostaddr Database-Host-IPv4-Address {} 15 {}} \
    [list port     Database-Port    {}  6 [pgtcl::default 5432 PGPORT]] \
    [list dbname   Database-Name    {} 20 [pgtcl::default $user PGDATABASE]] \
    [list tty      Backend-Debug-TTY  D 40 [pgtcl::default {} PGTTY]] \
    [list options  Backend-Debug-Options D 40 [pgtcl::default {} PGOPTIONS]] \
  ]
  if {$pgtcl::debug} { puts "+pg_conndefaults: $result" }
  return $result
}

# Connect to database. Only the new form, with -conninfo, is recognized.
# We speak backend protocol v2, and only handle clear-text password and
# MD5 authentication (messages R 3, and R 5).
proc pg_connect {args} {

  if {[llength $args] != 2 || [lindex $args 0] != "-conninfo"} {
    error "Connection to database failed\nMust use pg_connect -conninfo form"
  }

  # Get connection defaults into an array opt(), then merge caller params:
  foreach o [pg_conndefaults] {
    set opt([lindex $o 0]) [lindex $o 4]
  }
  if {[set msg [pgtcl::parse_conninfo [lindex $args 1] opt]] != ""} {
    error "Connection to database failed\n$msg"
  }

  # Hostaddr overrides host, per documentation, and we need host below.
  if {$opt(hostaddr) != ""} {
    set opt(host) $opt(hostaddr)
  }

  if {$pgtcl::debug} {
    puts "+pg_connect to $opt(dbname)@$opt(host):$opt(port) as $opt(user)"
  }

  if {[catch {socket $opt(host) $opt(port)} sock]} {
    error "Connection to database failed\n$sock"
  }
  fconfigure $sock -buffering none -translation binary
  puts -nonewline $sock [binary format "I S S a64 a32 a64 x64 a64" \
        296 2 0 $opt(dbname) $opt(user) $opt(options) $opt(tty)]

  set msg {}
  while {[set c [read $sock 1]] != "Z"} {
    switch $c {
      E {
        pgtcl::gets $sock msg
        break
      }
      R {
        set n -1
        binary scan [read $sock 4] I n
        if {$n == 3} {
          set n [expr "5 + [string length $opt(password)]"]
          puts -nonewline $sock [binary format "I a* x" $n $opt(password)]
        } elseif {$n == 5} {
          set salt [read $sock 4]
          # This is from PostgreSQL source backend/libpq/crypt.c:
          set md5_response \
            "md5[md5::digest [md5::digest $opt(password)$opt(user)]$salt]"
          if {$pgtcl::debug} { puts "+pg_connect MD5 sending: $md5_response" }
          puts -nonewline $sock [binary format "I a* x" 40 $md5_response]

        } elseif {$n != 0} {
          set msg "Unknown database authentication request($n)"
          break
        }
      }
      K {
        binary scan [read $sock 8] II pid key
        if {$pgtcl::debug} { puts "+server pid=$pid key=$key" }
      }
      default {
        set msg "Unexpected reply from database: $c"
        break
      }
    }
  }
  if {$msg != ""} {
    close $sock
    error "Connection to database failed\n$msg"
  }
  return $sock
}

# Disconnect from the database. Free all result structures and notify
# functions for this connection.
proc pg_disconnect {db} {
  if {$pgtcl::debug} { puts "+Disconnecting $db from database" }
  puts -nonewline $db X
  catch {close $db}
  foreach v [info vars pgtcl::result*] {
    upvar #0 $v result
    if {$result(conn) == $db} {
      if {$pgtcl::debug} { puts "+Freeing left-over result structure $v" }
      unset result
    }
  }
  if {[array exists pgtcl::notify]} {
    foreach v [array names pgtcl::notify $db,*] {
      if {$pgtcl::debug} { puts "+Forgetting notify callback $v" }
      unset pgtcl::notify($v)
    }
  }
}

# Internal procedure to read a tuple (row) from the backend, ASCII or Binary.
proc pgtcl::gettuple {db result_name is_binary} {
  upvar $result_name result

  if {$result(nattr) == 0} {
    unset result
    error "Protocol error, data before descriptor"
  }
  if {$is_binary} {
    set size_includes_size 0
  } else {
    set size_includes_size -4
  }
  set irow $result(ntuple)
  # Read the Null Mask Bytes and make a string of [10]* in $nulls:
  binary scan [read $db $result(nmb)] "B$result(nattr)" nulls

  set nattr $result(nattr)
  for {set icol 0} {$icol < $nattr} {incr icol} {
    if {[string index $nulls $icol]} {
      binary scan [read $db 4] I nbytes
      incr nbytes $size_includes_size
      set result($irow,$icol) [read $db $nbytes]
    } else {
      set result($irow,$icol) $pgtcl::nulls
    }
  }
  incr result(ntuple)
}

# Handle a notification ('A') message.
# The notifying backend pid is read but ignored.
proc pgtcl::gotnotify {db} {
  read $db 4
  pgtcl::gets $db notify_rel
  if {$pgtcl::debug} { puts "+pgtcl got notify: $notify_rel" }
  if {[info exists pgtcl::notify($db,$notify_rel)]} {
    after idle $pgtcl::notify($db,$notify_rel)
  }
}

# Internal procedure to handle common backend utility message types:
#    C : Completion status        E : Error
#    N : Notice message           A : Notification
# This can be given any message type. If it handles the message,
# it returns 1. If it doesn't handle the message, it returns 0.
#
proc pgtcl::common_message {msgchar db result_name} {
  upvar $result_name result
  if {$msgchar == "C"} {
    pgtcl::gets $db result(complete)
  } elseif {$msgchar == "E"} {
    set result(status) PGRES_FATAL_ERROR
    pgtcl::gets $db result(error)
  } elseif {$msgchar == "N"} {
    eval $pgtcl::notice {[pgtcl::gets $db]}
  } elseif {$msgchar == "A"} {
    pgtcl::gotnotify $db
  } else {
    return 0
  }
  return 1
}

# Execute SQL and return a result handle. See the documentation for a
# description of the innards of a result structure. This proc implements
# most of the backend response protocol. The important reply codes are:
#  T : RowDescriptor describes the attributes (columns) of each data row.
#      Followed by descriptor for each attribute: name, type, size, modifier
#      Also compute result(nmb), number of bytes in the NULL-value maps.
#  D : AsciiRow has data for 1 tuple.
#  B : BinaryRow has data for 1 tuple, result of a Binary Cursor.
#  Z : Operation complete
#  H : Ready for Copy Out
#  G : Ready for Copy In
# Plus the C E N A codes handled by pgtcl::common_message.
#
proc pg_exec {db query} {
  if {$pgtcl::debug} { puts "+pg_exec $query" }
  puts -nonewline $db [binary format "a* x" Q$query]

  upvar #0 pgtcl::result[incr pgtcl::rn] result
  set result(conn) $db
  set result(nattr) 0
  set result(attrs) {}
  set result(types) {}
  set result(sizes) {}
  set result(modifs) {}
  set result(ntuple) 0
  set result(error) {}
  set result(complete) {}
  set result(status) PGRES_COMMAND_OK

  while {[set c [read $db 1]] != "Z"} {
    switch $c {
      D {
        pgtcl::gettuple $db result 0
      }
      B {
        pgtcl::gettuple $db result 1
      }
      T {
        if {$result(nattr) != 0} {
          unset result
          error "Protocol failure, multiple descriptors"
        }
        set result(status) PGRES_TUPLES_OK
        binary scan [read $db 2] S nattr
        set result(nattr) $nattr
        for {set icol 0} {$icol < $nattr} {incr icol} {
          lappend result(attrs) [pgtcl::gets $db]
          binary scan [read $db 10] ISI type size modif
          lappend result(types) $type
          lappend result(sizes) $size
          lappend result(modifs) $modif
        }
        set result(nmb) [expr {($nattr+7)/8}]
      }
      I {
        pgtcl::gets $db
        set result(status) PGRES_EMPTY_QUERY
      }
      P {
        pgtcl::gets $db
      }
      H {
        set result(status) PGRES_COPY_OUT
        fconfigure $db -buffering line -translation lf
        if {$pgtcl::debug} { puts "+pg_exec begin copy out" }
        break
      }
      G {
        set result(status) PGRES_COPY_IN
        if {$pgtcl::debug} { puts "+pg_exec begin copy in" }
        break
      }
      default {
        if {![pgtcl::common_message $c $db result]} {
          unset result
          error "Unexpected reply from database: $c"
        }
      }
    }
  }
  return $pgtcl::rn
}

# I/O routines to support COPY. These are not yet needed, because you can read
# and write directly to the I/O channel, but will be needed with PostgreSQL
# protocol v3. They are included here to help transition to a future version
# of pgin.tcl.
# These do not currently check that COPY is actually in progress.

# Read line from COPY TO. Returns the line read if OK, else "" at the end.
proc pg_copy_read {res} {
  upvar #0 [pgtcl::checkres $res] result
  if {[gets $result(conn) line] < 0} {
    error "Unexpected end of data during COPY OUT"
  }
  if {$line == "\\."} {
    return ""
  }
  incr result(ntuple)
  return $line
}

# Write line for COPY FROM. Do not call with "\\." - just call pg_endcopy.
proc pg_copy_write {res line} {
  upvar #0 [pgtcl::checkres $res] result
  puts $result(conn) $line
  incr result(ntuple)
}

# End a Copy In/Out. This is needed because Tcl cannot do channel magic in
# Tcl like it can from C code.
# Call this after writing "\\." on Copy In, or after reading "\\." on Copy Out.
# Or, call this after reading "" from pg_copy_read, or when done with
# pg_copy_write. (This knows if pg_copy_write was used because ntuples will
# be > 0, in which case the ending "\\." needs to be written.)
# When it returns, the result structure (res) will be updated.
proc pg_endcopy {res} {
  upvar #0 [pgtcl::checkres $res] result
  set db $result(conn)
  if {$pgtcl::debug} { puts "+pg_endcopy end $result(status)" }

  if {$result(status) == "PGRES_COPY_OUT"} {
    fconfigure $db -buffering none -translation binary
  } elseif {$result(status) != "PGRES_COPY_IN"} {
    error "pg_endcopy called but connection is not doing a COPY"
  } elseif {$result(ntuple) > 0} {
    puts $db "\\."
  }

  # We're looking for C COPY and Z here, but other things can happen.
  set result(status) PGRES_COMMAND_OK
  while {[set c [read $db 1]] != "Z"} {
    if {![pgtcl::common_message $c $db result]} {
      error "Unexpected reply from database: $c"
    }
  }
}

# Extract data from a pg_exec result structure.
# -cmdTuples, -list, and -llist are extensions to the baseline libpgtcl which
# have appeared or will appear in beta or future versions.

proc pg_result {res option args} {
  upvar #0 [pgtcl::checkres $res] result
  set argc [llength $args]
  set ntuple $result(ntuple)
  set nattr $result(nattr)
  switch -- $option {
    -status { return $result(status) }
    -error  { return $result(error) }
    -conn   { return $result(conn) }
    -oid {
      if {[regexp {^INSERT +([0-9]*)} $result(complete) unused oid]} {
        return $oid
      }
      return 0
    }
    -cmdTuples {
      if {[regexp {^INSERT +[0-9]* +([0-9]*)} $result(complete) x num] \
       || [regexp {^(UPDATE|DELETE) +([0-9]*)} $result(complete) x y num]} {
        return $num
      }
      return ""
    }
    -numTuples { return $ntuple }
    -numAttrs  { return $nattr }
    -assign {
      if {$argc != 1} {
        error "-assign option must be followed by a variable name"
      }
      upvar $args a
      set icol 0
      foreach attr $result(attrs) {
        for {set irow 0} {$irow < $ntuple} {incr irow} {
          set a($irow,$attr) $result($irow,$icol)
        }
        incr icol
      }
    }
    -assignbyidx {
      if {$argc != 1 && $argc != 2} {
        error "-assignbyidxoption requires an array name and optionally an\
          append string"
      }
      upvar [lindex $args 0] a
      if {$argc == 2} {
        set suffix [lindex $args 1]
      } else {
        set suffix {}
      }
      set attr_first [lindex $result(attrs) 0]
      set attr_rest [lrange $result(attrs) 1 end]
      for {set irow 0} {$irow < $ntuple} {incr irow} {
        set val_first $result($irow,0)
        set icol 1
        foreach attr $attr_rest {
          set a($val_first,$attr$suffix) $result($irow,$icol)
          incr icol
        }
      }
    }
    -getTuple {
      if {$argc != 1} {
        error "-getTuple option must be followed by a tuple number"
      }
      set irow $args
      if {$irow < 0 || $irow >= $ntuple} {
        error "argument to getTuple cannot exceed number of tuples - 1"
      }
      set list {}
      for {set icol 0} {$icol < $nattr} {incr icol} {
        lappend list $result($irow,$icol)
      }
      return $list
    }
    -tupleArray {
      if {$argc != 2} {
        error "-tupleArray option must be followed by a tuple number and\
           array name"
      }
      set irow [lindex $args 0]
      if {$irow < 0 || $irow >= $ntuple} {
        error "argument to tupleArray cannot exceed number of tuples - 1"
      }
      upvar [lindex $args 1] a
      set icol 0
      foreach attr $result(attrs) {
        set a($attr) $result($irow,$icol)
        incr icol
      }
    }
    -list {
      set list {}
      for {set irow 0} {$irow < $ntuple} {incr irow} {
        for {set icol 0} {$icol < $nattr} {incr icol} {
          lappend list $result($irow,$icol)
        }
      }
      return $list
    }
    -llist {
      set list {}
      for {set irow 0} {$irow < $ntuple} {incr irow} {
        set sublist {}
        for {set icol 0} {$icol < $nattr} {incr icol} {
          lappend sublist $result($irow,$icol)
        }
        lappend list $sublist
      }
      return $list
    }
    -attributes {
       return $result(attrs)
    }
    -lAttributes {
      set list {}
      foreach attr $result(attrs) type $result(types) size $result(sizes) {
        lappend list [list $attr $type $size]
      }
      return $list
    }
    -clear {
      unset result
    }
    default { error "Invalid option to pg_result: $option" }
  }
}

# Run a select query and iterate over the results. Uses pg_exec to run the
# query and build the result structure, but we cheat and directly use the
# result array rather than calling pg_result.
# Each returned tuple is stored into the caller's array, then the caller's
# proc is called. 
# If the caller's proc does "break", "return", or gets an error, get out
# of the processing loop. Tcl codes: 0=OK 1=error 2=return 3=break 4=continue
proc pg_select {db query var_name proc} {
  upvar $var_name var
  global errorCode errorInfo

  set res [pg_exec $db $query]
  upvar #0 pgtcl::result$res result
  if {$result(status) != "PGRES_TUPLES_OK"} {
    set msg $result(error)
    unset result
    error $msg
  }
  set code 0
  set var(.headers) $result(attrs)
  set var(.numcols) $result(nattr)
  set ntuple $result(ntuple)
  for {set irow 0} {$irow < $ntuple} {incr irow} {
    set var(.tupno) $irow
    set icol 0
    foreach attr $result(attrs) {
      set var($attr) $result($irow,$icol)
      incr icol
    }
    set code [catch {uplevel 1 $proc} s]
    if {$code != 0 && $code != 4} break
  }
  unset result var
  if {$code == 1} {
    return -code error -errorinfo $errorInfo -errorcode $errorCode $s
  } elseif {$code == 2 || $code > 4} {
    return -code $code $s
  }
}

# Register a listener for backend notification, or cancel a listener.
proc pg_listen {db name {proc ""}} {
  if {$proc != ""} {
    set pgtcl::notify($db,$name) $proc
    set r [pg_exec $db "listen $name"]
    pg_result $r -clear
  } elseif {[info exists pgtcl::notify($db,$name)]} {
    unset pgtcl::notify($db,$name)
    set r [pg_exec $db "unlisten $name"]
    pg_result $r -clear
  }
}

# pg_execute: Execute a query, optionally iterating over the results.
#
# Returns the number of tuples selected or affected by the query.
# Usage: pg_execute ?options? connection query ?proc?
#   Options:  -array ArrayVar
#             -oid OidVar
# If -array is not given with a SELECT, the data is put in variables
# named by the fields. This is generally a bad idea and could be dangerous.
#
# If there is no proc body and the query return 1 or more rows, the first
# row is stored in the array or variables and we return (as does libpgtcl).
#
# Notes: Handles proc return codes of:
#    0(OK) 1(error) 2(return) 3(break) 4(continue)
#   Uses pg_exec and pg_result, but also makes direct access to the
# structures used by them.

proc pg_execute {args} {
  global errorCode errorInfo

  set usage "pg_execute ?-array arrayname?\
     ?-oid varname? connection queryString ?loop_body?"

  # Set defaults and parse command arguments:
  set use_array 0
  set set_oid 0
  set do_proc 0
  set last_option_arg {}
  set n_nonswitch_args 0
  set conn {}
  set query {}
  set proc {}
  foreach arg $args {
    if {$last_option_arg != ""} {
      if {$last_option_arg == "-array"} {
        set use_array 1
        upvar $arg data
      } elseif {$last_option_arg == "-oid"} {
        set set_oid 1
        upvar $arg oid
      } else {
        error "Unknown option $last_option_arg\n$usage"
      }
      set last_option_arg {}
    } elseif {[regexp ^- $arg]} {
      set last_option_arg $arg
    } else {
      if {[incr n_nonswitch_args] == 1} {
        set conn $arg
      } elseif {$n_nonswitch_args == 2} {
        set query $arg
      } elseif {$n_nonswitch_args == 3} {
        set do_proc 1
        set proc $arg
      } else {
        error "Wrong # of arguments\n$usage"
      }
    }
  }
  if {$last_option_arg != "" || $n_nonswitch_args < 2} {
    error "Bad arguments\n$usage"
  }

  set res [pg_exec $conn $query]
  upvar #0 pgtcl::result$res result

  # For non-SELECT query, just process oid and return value.
  # Let pg_result do the decoding.
  if {[regexp {^PGRES_(COMMAND_OK|COPY|EMPTY_QUERY)} $result(status)]} {
    if {$set_oid} {
      set oid [pg_result $res -oid]
    }
    set ntuple [pg_result $res -cmdTuples]
    pg_result $res -clear
    return $ntuple
  }

  if {$result(status) != "PGRES_TUPLES_OK"} {
    set status [list $result(status) $result(error)]
    pg_result $res -clear
    error $status
  }

  # Handle a SELECT query. This is like pg_select, except the proc is optional,
  # and the fields can go in an array or variables.
  # With no proc, store the first row only.
  set code 0
  if {!$use_array} {
    foreach attr $result(attrs) {
      upvar $attr data_$attr
    }
  }
  set ntuple $result(ntuple)
  for {set irow 0} {$irow < $ntuple} {incr irow} {
    set icol 0
    if {$use_array} {
      foreach attr $result(attrs) {
        set data($attr) $result($irow,$icol)
        incr icol
      }
    } else {
      foreach attr $result(attrs) {
        set data_$attr $result($irow,$icol)
        incr icol
      }
    }
    if {!$do_proc} break
    set code [catch {uplevel 1 $proc} s]
    if {$code != 0 && $code != 4} break
  }
  pg_result $res -clear
  if {$code == 1} {
    return -code error -errorInfo $errorInfo -errorCode $s
  } elseif {$code == 2 || $code > 4} {
    return -code $code $s
  }
  return $ntuple
}

# pg_configure: Configure options for PostgreSQL connections
# This is an extension and not available in libpgtcl.
# Usage: pg_configure connection option ?value?
#   connection   Which connection the option applies to.
#                This is currently ignored, as all options are global.
#   option       One of the following options.
#      nulls       Set the string to be returned for NULL values
#                  Default is ""
#      notice      A command to execute when a NOTICE message comes in.
#                  Default is a procedure which prints to stderr.
#   value        If supplied, the new value of the option.
#                If not supplied, return the current value.
# Returns the previous value of the option.

proc pg_configure {db option args} {
  if {[set nargs [llength $args]] == 0} {
    set modify 0
  } elseif {$nargs == 1} {
    set modify 1
    set newvalue [lindex $args 0]
  } else {
    error "Wrong # args: should be \"pg_configure connection option ?value?\""
  }

  set options {nulls notice debug}
  if {[lsearch -exact $options $option] < 0} {
    error "Bad option \"$option\": must be one of [join $options {, }]"
  }
  eval set return_value \$pgtcl::$option
  if {$modify} {
   eval set pgtcl::$option {$newvalue}
  }
  return $return_value
}

# pg_escape_string: Escape a string for use as a quoted SQL string
# Returns the escaped string. This was added to PostgreSQL after 7.3.2
# and to libpgtcl after 1.4b3.
# Note: string map requires Tcl >= 8.1 but is faster than regsub here.
proc pg_escape_string {s} {
  return [string map {' '' \\ \\\\} $s]
}

# ===== Large Object Interface ====

# Internal procedure to lookup, cache, and return a PostgreSQL function OID.
# This assumes all connections have the same function OIDs, which might not be
# true if you connect to servers running different versions of PostgreSQL.
# Throws an error if the OID is not found by PostgreSQL.
# To call overloaded functions, argument types must be specified in parentheses
# after the function name, in the the exact same format as psql "\df".
# This is a list of types separated by a comma and one space.
# For example: fname="like(text, text)".
# The return type cannot be specified. I don't think there are any functions
# distinguished only by return type.
proc pgtcl::getfnoid {db fname} {
  variable fnoids

  if {![info exists fnoids($fname)]} {

    # Separate the function name from the (arg type list):
    if {[regexp {^([^(]*)\(([^)]*)\)$} $fname unused fcn arglist]} {
      set amatch " and oidvectortypes(proargtypes)='$arglist'"
    } else {
      set fcn $fname
      set amatch ""
    }
    pg_select $db "select oid from pg_proc where proname='$fcn' $amatch" d {
      set fnoids($fname) $d(oid)
    }
    if {![info exists fnoids($fname)]} {
      error "Unable to get OID of database function $fname"
    }
  }
  return $fnoids($fname)
}

# Internal procedure to implement PostgreSQL "fast-path" function calls.
# $fn_oid is the OID of the PostgreSQL function. See pgtcl::getfnoid.
# $result_name is the name of the variable to store the backend function
#   result into.
# $arginfo is a list of argument descriptors, each is I or S or a number.
#   I means the argument is an integer32.
#   S means the argument is a string, and its actual length is used.
#   A number means send exactly that many bytes (null-pad if needed) from
# the argument.
# $arglist  is a list of arguments to the PostgreSQL function. (This
#    is actually a pass-through argument 'args' from the wrappers.)
# Throws Tcl error on error, otherwise returns size of the result
# stored into the $result_name variable.

proc pgtcl::callfn {db fn_oid result_name arginfo arglist} {
  upvar $result_name result

  set nargs [llength $arginfo]
  if {$pgtcl::debug} {
    puts "+callfn oid=$fn_oid nargs=$nargs info=$arginfo args=$arglist"
  }

  # Function call: F " " oid argcount {arglen arg}...
  set out [binary format a2xII {F } $fn_oid $nargs]
  foreach k $arginfo arg $arglist {
    if {$k == "I"} {
      append out [binary format II 4 $arg]
    } elseif {$k == "S"} {
      append out [binary format I [string length $arg]] $arg
    } else {
      append out [binary format Ia$k $k $arg]
    }
  }
  puts -nonewline $db $out

  set result {}
  set result_size 0
  # Fake up a partial result structure for pgtcl::common_message :
  set res(error) ""

  # Function response: VG...0 (OK, data); V0 (OK, null) or E or ...
  # Also handles common messages (notify, notice).
  while {[set c [read $db 1]] != "Z"} {
    if {$c == "V"} {
      set c2 [read $db 1]
      if {$c2 == "G"} {
        binary scan [read $db 4] I result_size
        set result [read $db $result_size]
        set c2 [read $db 1]
      }
      if {$c2 != "0"} {
        error "Unexpected reply from database: V$c2"
      }
    } elseif {![pgtcl::common_message $c $db res]} {
      error "Unexpected reply from database: $c"
    }
  }
  if {$res(error) != ""} {
    error $res(error)
  }
  return $result_size
}

# Public interface to pgtcl::callfn.
proc pg_callfn {db fname result_name arginfo args} {
  upvar $result_name result
  return [pgtcl::callfn $db [pgtcl::getfnoid $db $fname] result $arginfo $args]
}

# Public, simplified interface to pgtcl::callfn when an int32 return value is
# expected. Returns the backend function return value.
proc pg_callfn_int {db fname arginfo args} {
  set n [pgtcl::callfn $db [pgtcl::getfnoid $db $fname] result $arginfo $args]
  if {$n != 4} { 
    error "Unexpected response size ($result_size) to pg function call $fname"
  }
  binary scan $result I val
  return $val
}

# Convert a LO mode string into the value of the constants used by libpq.
# Note: libpgtcl uses a mode like INV_READ|INV_WRITE for lo_creat, but
# r, w, or rw for lo_open (which it translates to INV_READ|INV_WRITE).
# This seems like a mistake. The code here accepts either form for either.
proc pgtcl::lomode {mode} {
  set imode 0
  if {[string match -nocase *INV_* $mode]} {
    if {[string match -nocase *INV_READ* $mode]} {
      set imode 0x40000
    }
    if {[string match -nocase *INV_WRITE* $mode]} {
      set imode [expr {$imode + 0x20000}]
    }
  } else {
    if {[string match -nocase *r* $mode]} {
      set imode 0x40000
    }
    if {[string match -nocase *w* $mode]} {
      set imode [expr {$imode + 0x20000}]
    }
  }
  if {$imode == 0} {
    error "pgtcl: Invalid large object mode $mode"
  }
  return $imode
}

# Create large object and return OID.
# See note regarding mode above at pgtcl::lomode.
proc pg_lo_creat {db mode} {
  return [pg_callfn_int $db lo_creat I [pgtcl::lomode $mode]]
}

# Open large object and return large object file descriptor.
# See note regarding mode above at pgtcl::lomode.
proc pg_lo_open {db loid mode} {
  return [pg_callfn_int $db lo_open "I I" $loid [pgtcl::lomode $mode]]
}

# Close large object file descriptor.
proc pg_lo_close {db lofd} {
  return [pg_callfn_int $db lo_close I $lofd]
}

# Delete large object:
proc pg_lo_unlink {db loid} {
  return [pg_callfn_int $db lo_unlink I $loid]
}

# Read from large object.
proc pg_lo_read {db lofd buf_name maxlen} {
  upvar $buf_name buf
  return [pg_callfn $db loread buf "I I" $lofd $maxlen]
}

# Write to large object. At most $len bytes are written.
proc pg_lo_write {db lofd buf len} {
  if {[set buflen [string length $buf]] < $len} {
    set len $buflen
  }
  return [pg_callfn_int $db lowrite "I $len" $lofd $buf]
}

# Seek to offset inside large object:
proc pg_lo_lseek {db lofd offset whence} {
  switch $whence {
    SEEK_SET { set iwhence 0 }
    SEEK_CUR { set iwhence 1 }
    SEEK_END { set iwhence 2 }
    default { error "Invalid whence argument ($whence) in pg_lo_lseek" }
  }
  return [pg_callfn_int $db lo_lseek "I I I" $lofd $offset $iwhence]
}

# Return location of file offset in large object:
proc pg_lo_tell {db lofd} {
  return [pg_callfn_int $db lo_tell I $lofd]
}

# Import large object. Wrapper for lo_creat, lo_open, lo_write.
# Returns Large Object OID, which should be stored in a table somewhere.
proc pg_lo_import {db filename} {
  set f [open $filename]
  fconfigure $f -translation binary
  set loid [pg_lo_creat $db INV_READ|INV_WRITE]
  set lofd [pg_lo_open $db $loid w]
  while {1} {
    set buf [read $f 32768]
    if {[set len [string length $buf]] == 0} break
    if {[pg_lo_write $db $lofd $buf $len] != $len} {
      error "pg_lo_import failed to write $len bytes"
    }
  }
  pg_lo_close $db $lofd
  close $f
  return $loid
}

# Export large object. Wrapper for lo_open, lo_read.
proc pg_lo_export {db loid filename} {
  set f [open $filename w]
  fconfigure $f -translation binary
  set lofd [pg_lo_open $db $loid r]
  while {[set len [pg_lo_read $db $lofd buf 32768]] > 0} {
    puts -nonewline $f $buf
  }
  pg_lo_close $db $lofd
  close $f
}

# ===== MD5 Checksum ====

# Coded in Tcl by ljb <lbayuk@mindspring.com>, using these sources:
#  RFC1321
#  PostgreSQL: src/backend/libpq/md5.c
# If you want a better/faster MD5 implementation, see tcllib.

namespace eval md5 { }

# Round 1 helper, e.g.:
#   a = b + ROT_LEFT((a + F(b, c, d) + X[0] + 0xd76aa478), 7)
#       p1            p2    p1 p3 p4   p5        p6        p7
# Where F(x,y,z) = (x & y) | (~x & z)
#
proc md5::round1 {p1 p2 p3 p4 p5 p6 p7} {
  set r [expr {$p2 + ($p1 & $p3 | ~$p1 & $p4) + $p5 + $p6}]
  return [expr {$p1 + ($r << $p7 | (($r >> (32 - $p7)) & ((1 << $p7) - 1)))}]
}

# Round 2 helper, e.g.:
#   a = b + ROT_LEFT((a + G(b, c, d) + X[1] + 0xf61e2562), 5)
#       p1            p2    p1 p3 p4   p5        p6        p7
# Where G(x,y,z) = (x & z) | (y & ~z)
#
proc md5::round2 {p1 p2 p3 p4 p5 p6 p7} {
  set r [expr {$p2 + ($p1 & $p4 | $p3 & ~$p4) + $p5 + $p6}]
  return [expr {$p1 + ($r << $p7 | (($r >> (32 - $p7)) & ((1 << $p7) - 1)))}]
}

# Round 3 helper, e.g.:
#   a = b + ROT_LEFT((a + H(b, c, d) + X[5] + 0xfffa3942), 4)
#       p1            p2    p1 p3 p4   p5     p6           p7
# Where H(x, y, z) = x ^ y ^ z
#
proc md5::round3 {p1 p2 p3 p4 p5 p6 p7} {
  set r [expr {$p2 + ($p1 ^ $p3 ^ $p4) + $p5 + $p6}]
  return [expr {$p1 + ($r << $p7 | (($r >> (32 - $p7)) & ((1 << $p7) - 1)))}]
}

# Round 4 helper, e.g.:
#   a = b + ROT_LEFT((a + I(b, c, d) + X[0] + 0xf4292244), 6)
#       p1            p2    p1 p3 p4   p5     p6           p7
# Where I(x, y, z) = y ^ (x | ~z)
#
proc md5::round4 {p1 p2 p3 p4 p5 p6 p7} {
  set r [expr {$p2 + ($p3 ^ ($p1 | ~$p4)) + $p5 + $p6}]
  return [expr {$p1 + ($r << $p7 | (($r >> (32 - $p7)) & ((1 << $p7) - 1)))}]
}

# Do one set of rounds. Updates $state(0:3) with results from $x(0:16).
proc md5::round {x_name state_name} {
  upvar $x_name x $state_name state
  set a $state(0)
  set b $state(1)
  set c $state(2)
  set d $state(3)

  # Round 1, steps 1-16
  set a [round1 $b $a $c $d $x(0)  0xd76aa478  7]
  set d [round1 $a $d $b $c $x(1)  0xe8c7b756 12]
  set c [round1 $d $c $a $b $x(2)  0x242070db 17]
  set b [round1 $c $b $d $a $x(3)  0xc1bdceee 22]
  set a [round1 $b $a $c $d $x(4)  0xf57c0faf  7]
  set d [round1 $a $d $b $c $x(5)  0x4787c62a 12]
  set c [round1 $d $c $a $b $x(6)  0xa8304613 17]
  set b [round1 $c $b $d $a $x(7)  0xfd469501 22]
  set a [round1 $b $a $c $d $x(8)  0x698098d8  7]
  set d [round1 $a $d $b $c $x(9)  0x8b44f7af 12]
  set c [round1 $d $c $a $b $x(10) 0xffff5bb1 17]
  set b [round1 $c $b $d $a $x(11) 0x895cd7be 22]
  set a [round1 $b $a $c $d $x(12) 0x6b901122  7]
  set d [round1 $a $d $b $c $x(13) 0xfd987193 12]
  set c [round1 $d $c $a $b $x(14) 0xa679438e 17]
  set b [round1 $c $b $d $a $x(15) 0x49b40821 22]

  # Round 2, steps 17-32
  set a [round2 $b $a $c $d $x(1)  0xf61e2562  5]
  set d [round2 $a $d $b $c $x(6)  0xc040b340  9]
  set c [round2 $d $c $a $b $x(11) 0x265e5a51 14]
  set b [round2 $c $b $d $a $x(0)  0xe9b6c7aa 20]
  set a [round2 $b $a $c $d $x(5)  0xd62f105d  5]
  set d [round2 $a $d $b $c $x(10) 0x02441453  9]
  set c [round2 $d $c $a $b $x(15) 0xd8a1e681 14]
  set b [round2 $c $b $d $a $x(4)  0xe7d3fbc8 20]
  set a [round2 $b $a $c $d $x(9)  0x21e1cde6  5]
  set d [round2 $a $d $b $c $x(14) 0xc33707d6  9]
  set c [round2 $d $c $a $b $x(3)  0xf4d50d87 14]
  set b [round2 $c $b $d $a $x(8)  0x455a14ed 20]
  set a [round2 $b $a $c $d $x(13) 0xa9e3e905  5]
  set d [round2 $a $d $b $c $x(2)  0xfcefa3f8  9]
  set c [round2 $d $c $a $b $x(7)  0x676f02d9 14]
  set b [round2 $c $b $d $a $x(12) 0x8d2a4c8a 20]

  # Round 3, steps 33-48
  set a [round3 $b $a $c $d $x(5)  0xfffa3942  4]
  set d [round3 $a $d $b $c $x(8)  0x8771f681 11]
  set c [round3 $d $c $a $b $x(11) 0x6d9d6122 16]
  set b [round3 $c $b $d $a $x(14) 0xfde5380c 23]
  set a [round3 $b $a $c $d $x(1)  0xa4beea44  4]
  set d [round3 $a $d $b $c $x(4)  0x4bdecfa9 11]
  set c [round3 $d $c $a $b $x(7)  0xf6bb4b60 16]
  set b [round3 $c $b $d $a $x(10) 0xbebfbc70 23]
  set a [round3 $b $a $c $d $x(13) 0x289b7ec6  4]
  set d [round3 $a $d $b $c $x(0)  0xeaa127fa 11]
  set c [round3 $d $c $a $b $x(3)  0xd4ef3085 16]
  set b [round3 $c $b $d $a $x(6)  0x04881d05 23]
  set a [round3 $b $a $c $d $x(9)  0xd9d4d039  4]
  set d [round3 $a $d $b $c $x(12) 0xe6db99e5 11]
  set c [round3 $d $c $a $b $x(15) 0x1fa27cf8 16]
  set b [round3 $c $b $d $a $x(2)  0xc4ac5665 23]

  # Round 4, steps 49-64
  set a [round4 $b $a $c $d $x(0)  0xf4292244  6]
  set d [round4 $a $d $b $c $x(7)  0x432aff97 10]
  set c [round4 $d $c $a $b $x(14) 0xab9423a7 15]
  set b [round4 $c $b $d $a $x(5)  0xfc93a039 21]
  set a [round4 $b $a $c $d $x(12) 0x655b59c3  6]
  set d [round4 $a $d $b $c $x(3)  0x8f0ccc92 10]
  set c [round4 $d $c $a $b $x(10) 0xffeff47d 15]
  set b [round4 $c $b $d $a $x(1)  0x85845dd1 21]
  set a [round4 $b $a $c $d $x(8)  0x6fa87e4f  6]
  set d [round4 $a $d $b $c $x(15) 0xfe2ce6e0 10]
  set c [round4 $d $c $a $b $x(6)  0xa3014314 15]
  set b [round4 $c $b $d $a $x(13) 0x4e0811a1 21]
  set a [round4 $b $a $c $d $x(4)  0xf7537e82  6]
  set d [round4 $a $d $b $c $x(11) 0xbd3af235 10]
  set c [round4 $d $c $a $b $x(2)  0x2ad7d2bb 15]
  set b [round4 $c $b $d $a $x(9)  0xeb86d391 21]

  incr state(0) $a
  incr state(1) $b
  incr state(2) $c
  incr state(3) $d
}

# Pad out buffer per MD5 spec:
proc md5::pad {buf_name} {
  upvar $buf_name buf

  # Length in bytes:
  set len [string length $buf]
  # Length in bits as 2 32 bit words:
  set len64hi [expr {$len >> 29 & 7}]
  set len64lo [expr {$len << 3}]

  # Append 1 special byte, then append 0 or more 0 bytes until
  # (length in bytes % 64) == 56
  set pad [expr {64 - ($len + 8) % 64}]
  append buf [binary format a$pad "\x80"]

  # Append the length in bits as a 64 bit value, low bytes first.
  append buf [binary format i1i1 $len64lo $len64hi]

}

# Calculate MD5 Digest over a string, return as 32 hex digit string.
proc md5::digest {buf} {
  # This is 0123456789abcdeffedcba9876543210 in byte-swapped order:
  set state(0) 0x67452301
  set state(1) 0xEFCDAB89
  set state(2) 0x98BADCFE
  set state(3) 0x10325476

  # Pad buffer per RFC to exact multiple of 64 bytes.
  pad buf

  # Calculate digest in 64 byte chunks:
  set nwords 0
  set nbytes 0
  set word 0
  binary scan $buf c* bytes
  # Unclear, but the data seems to get byte swapped here.
  foreach c $bytes {
    set word [expr {$c << 24 | ($word >> 8 & 0xffffff) }]
    if {[incr nbytes] == 4} {
      set nbytes 0
      set x($nwords) $word
      set word 0
      if {[incr nwords] == 16} {
        round x state
        set nwords 0
      }
    }
  }

  # Result is state(0:3), but each word is taken low byte first.
  set result {}
  for {set i 0} {$i <= 3} {incr i} {
    set w $state($i)
    append result [format %02x%02x%02x%02x \
             [expr {$w & 255}] \
             [expr {$w >> 8 & 255}] \
             [expr {$w >> 16 & 255}] \
             [expr {$w >> 24 & 255}]]
  }
  return $result
}
