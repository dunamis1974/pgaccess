##############################################################################
#
# Namespace for syntax highlight procedures.
#
# Currently supported highlight types:
# 	* tcl + pltcl
# 	* sql + plpgsql
#
# Usage: 
# 	Syntax::highlight text_widget type [start_position end_position]
#
# Bartus Levente (bartus.l at bitel.hu)
#
##############################################################################

namespace eval Syntax {

# procedure get_word
#
# returns 
#	the starting point
#	the end point
#	if new line occured	state
#	if white space occured state
#	if blank occured state
# for the first word from the "start"ing point.

proc get_word {t start} {
		set ws [$t search -forward -regexp {[^[:space:]]} $start "$start lineend"]
		if {$ws == ""} {
			set new_line_occured 1
			set ws [$t search -forward -regexp {[^[:space:]]} $start "end"]
		} else {
			set new_line_occured 0
		}
		if {$ws == ""} { return "end" }

		if {$ws > $start} {
			set white_space_occured 1
		} else {
			set white_space_occured 0
		}
		if {$white_space_occured && !$new_line_occured} {
			set blank_occured 1
		} else {
			set blank_occured 0
		}
		set we [$t index "$ws wordend"]
		set w [$t get $ws $we]
		return "{$ws} {$we} $new_line_occured $white_space_occured $blank_occured"
}

# procedure highlight_tcl
#
# sets the appropiate tags for tcl/pltcl highlight

proc {highlight_tcl} {t start stop} {
	set ws $start
	set we $ws
	set word_no 0
	# Stack for storing the actual state
	set Stack ""
	Stack::reset $Stack
	while {$ws != ""} {
		# get the next world
		set res [get_word $t $we]
		# terminate if $res=="end"
		if {$res == "end"} { 
			Stack::reset $Stack
			break
		}

		set we_old $we
		set ws [lindex $res 0]
		set we [lindex $res 1]
		set new_line_occured [lindex $res 2]
		set white_space_occured [lindex $res 3]
		set blank_occured [lindex $res 4]
		set w [$t get $ws $we]

		# if new_line_occured then the a command is next. The next processed word is 
		# the first in the command i.e. the command name itself
		if {$new_line_occured} {
			set word_no 0
		}
		incr word_no

		if {$w == "\\"} {
			# on char escape set escape tag both for the \ sign and for the next character
			set we [$t index "$ws + 2 chars"]
			$t tag add escape $ws $we
		} elseif {$w == "\;"} {
			# after ; a new command starts
			set word_no 0
			$t tag add escape $ws $we
		} elseif {$w == "\["} {
			# just tag as bracket
			Stack::push $Stack word_no
			set word_no 0
			Stack::push $Stack "\["
			$t tag add bracket $ws $we
		} elseif {$w == "\""} {
			# the string starts form the first " sign and ends at the matching " sign
			$t tag add string $ws $we
			set ts $ws
			while {1} {
				set res [get_word $t $we]
				if {$res == "end"} { 
					$t tag add string $ts end
					break
				}
				set we_old $we
				set ws [lindex $res 0]
				set we [lindex $res 1]
				set new_line_occured [lindex $res 2]
				set white_space_occured [lindex $res 3]
				set blank_occured [lindex $res 4]
				set w [$t get $ws $we]
				
				if {$w == "\\"} {
					set we [$t index "$ws + 2 chars"]
				}
				if {$w == "\""} {
					$t tag add string $ts $we
					break
				}				
			}
		} elseif {$w == "\#"} {
			# the # sign is the comment command 
			$t tag add comment $ws $we
			set ts $ws
			while {1} {
				set res [get_word $t $we]
				if {$res == "end"} { 
					$t tag add comment $ts end
					break
				}
				set we_old $we
				set ws [lindex $res 0]
				set we [lindex $res 1]
				set new_line_occured [lindex $res 2]
				set white_space_occured [lindex $res 3]
				set blank_occured [lindex $res 4]
				set w [$t get $ws $we]
				
				if {$new_line_occured} {
					$t tag add comment $ts $we_old
					set we $we_old
					break
				}				
			}
		} elseif {$w == "\]"} {
			if {[Stack::top $Stack] == "\["} {
			# if the command cycle ends with the closing bracket, the word_no defined before the cycle is restored
				Stack::pop $Stack
				$t tag add bracket $ws $we
				set word_no [Stack::pop $Stack]
			} else {
				# in case of an occasional closing bracket
				$t tag add none $ws $we
			}
		} elseif {$w == "\{"} {
			# opening brace
			$t tag add brace $ws $we
		} elseif {$w == "\}"} {
			# closing brace
			$t tag add brace $ws $we
		} elseif {$w == "\$"} {
			# a variable that ends with closing brace, closing bracket, colon, lineend
			$t tag add variable $ws $we
			set we [$t search -forward -regexp { |\]|\}|\;} $ws "$ws lineend"]
			if {$we == ""} {
				set we [$t index "$ws lineend"]
			}
			$t tag add variable $ws $we
		} elseif {$w == "\-"} {
			# parameter tag till the next white space
			if {$white_space_occured} {
			    set we [$t search -forward -regexp { } $ws "$ws lineend"]
			    if {$we == ""} {
				set we [$t index "$ws lineend"]
			    }
			    $t tag add switch $ws $we
			}
		} elseif {[string is double -strict $w]} {
			# tagging numbers
			$t tag add number $ws $we
		} elseif {$word_no == 1} {
			# tagging commands
			if {[info commands $w] == $w} {
				$t tag add command $ws $we
			} else {
				# the default tag is "none". You can set it to purple if you want :)
				$t tag add none $ws $we
			}
		}
	}
}

# proc highlight_plpgsql
#
# for sql/plpgsql syntax highlight

proc {highlight_plpgsql} {t start stop} {
	set ws $start
	set we $ws
	while {$ws != ""} {
		set res [get_word $t $we]
		if {$res == "end"} { 
			break
		}

		set we_old $we
		set ws [lindex $res 0]
		set we [lindex $res 1]
		set new_line_occured [lindex $res 2]
		set white_space_occured [lindex $res 3]
		set blank_occured [lindex $res 4]
		set w [$t get $ws $we]

		# quite simple string matching highlight
		if {![string compare -nocase $w "declare"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "begin"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "end"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "if"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "then"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "else"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "elsif"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "select"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "into"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "perform"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "execute"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "alias"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "for"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "loop"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "get"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "diagnostics"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "return"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "while"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "exit"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "cursor"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "open"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "fetch"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "close"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "raise"]} {
			$t tag add command $ws $we
		# for sql highlight
		} elseif {![string compare -nocase $w "abort"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "alter"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "group"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "table"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "user"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "analyze"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "checkpoint"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "cluster"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "comment"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "commit"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "copy"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "to"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "create"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "aggregate"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "constraint"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "trigger"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "database"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "function"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "group"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "index"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "language"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "operator"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "rule"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "sequence"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "table"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "trigger"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "type"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "view"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "declare"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "delete"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "drop"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "explain"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "fetch"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "grant"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "insert"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "listen"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "load"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "lock"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "move"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "notify"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "reindex"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "reset"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "revoke"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "rollback"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "set"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "constrains"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "session"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "authorization"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "transaction"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "show"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "truncate"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "unlisten"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "update"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "vacuum"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "from"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "where"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "group"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "by"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "having"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "order"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "limit"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "offset"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "add"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "drop"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "as"]} {
			$t tag add command $ws $we
		} elseif {![string compare -nocase $w "and"]} {
			$t tag add command $ws $we

		} elseif {$w == "\""} {
			# tagging strings
			$t tag add string $ws $we
			set ts $ws
			while {1} {
				set res [get_word $t $we]
				if {$res == "end"} { 
					$t tag add string $ts end
					break
				}
				set we_old $we
				set ws [lindex $res 0]
				set we [lindex $res 1]
				set new_line_occured [lindex $res 2]
				set white_space_occured [lindex $res 3]
				set blank_occured [lindex $res 4]
				set w [$t get $ws $we]
				
				if {$new_line_occured} {
					$t tag add string $ts $we_old
					break
				}				
				if {$w == "\""} {
					$t tag add string $ts $we
					break
				}				
			}
		} elseif {$w == "\'"} {
			# another string tagging
			$t tag add string $ws $we
			set ts $ws
			while {1} {
				set res [get_word $t $we]
				if {$res == "end"} { 
					$t tag add string $ts end
					break
				}
				set we_old $we
				set ws [lindex $res 0]
				set we [lindex $res 1]
				set new_line_occured [lindex $res 2]
				set white_space_occured [lindex $res 3]
				set blank_occured [lindex $res 4]
				set w [$t get $ws $we]
				
				if {$w == "\'"} {
					$t tag add string $ts $we
					break
				}				
			}
		} elseif {$w == "\/"} {
			# comment tagging
			if {[$t get $ws "$ws + 2 chars"] == "\/\*"} {
				# comments starts with // sign
				set ts $ws
				while {1} {
					set res [get_word $t $we]
					if {$res == "end"} { 
						$t tag add comment $ts end
						break
					}
					set we_old $we
					set ws [lindex $res 0]
					set we [lindex $res 1]
					set new_line_occured [lindex $res 2]
					set white_space_occured [lindex $res 3]
					set blank_occured [lindex $res 4]
					set w [$t get $ws $we]
					
					if {$w == "\*"} {
						if {[$t get $ws "$ws + 2 chars"] == "\*\/"} {
							set we [$t index "$ws + 2 chars"] 
							$t tag add comment $ts $we
							break
						}
					}				
				}
			}
		} elseif {$w == "\-"} {
			# another comment tagging
			if {[$t get $ws "$ws + 2 chars"] == "--"} {
				set we [$t index "$ws lineend"] 
				$t tag add comment $ws $we
			}
		} elseif {$w == "\;"} {
			# command end in sql
			$t tag add escape $ws $we
		} elseif {$w == "\$"} {
			# variable tag
			$t tag add variable $ws $we
			set we [$t search -forward -regexp { |\)|\;} $ws "$ws lineend"]
			if {$we == ""} {
				set we [$t index "$ws lineend"]
			}
			$t tag add variable $ws $we
		} elseif {$w == "\:"} {
			# just for :=
			if {[$t get $ws "$ws + 2 chars"] == ":="} {
				set we [$t index "$ws + 2 chars"] 
				$t tag add escape $ws $we
			}
		} elseif {[string is double -strict $w]} {
			# tagging a number
			$t tag add number $ws $we
		}
	}
}

# procedure highlight
#
# It is the main procedure in this namespace.

proc {highlight} {t type {start 1.0} {stop ""} args} {
	# configuring the tags
	$t tag configure none -foreground black
	$t tag configure command -foreground DarkBlue
	$t tag configure number -foreground DarkGreen
	$t tag configure comment -foreground gray
	$t tag configure variable -foreground red
	$t tag configure string -foreground purple
	$t tag configure escape -foreground brown
	$t tag configure brace -foreground black
	$t tag configure bracket -foreground black
	$t tag configure switch -foreground DarkGreen

	if {$stop == ""} {
		set stop [$t index end]
	}
	
	# removing all tags
	foreach tag {none command number comment variable string escape brace bracket switch} {
		$t tag remove $tag $start $stop
	}

	# calling the appropiate syntax highlight procedure
	if {$type == "tcl"} {
		highlight_tcl $t $start $stop
	} elseif {$type == "pltcl"} {
		highlight_tcl $t $start $stop
	} elseif {$type == "plpgsql"} {
		highlight_plpgsql $t $start $stop
	} elseif {$type == "sql"} {
		highlight_plpgsql $t $start $stop
	}
}

}; # end namespace

