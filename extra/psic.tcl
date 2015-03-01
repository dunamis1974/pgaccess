#! /bin/sh
#restarts using wish \
exec wish "$0" "$@"

# Vim mode line follows \
/* vim:tabstop=4:shiftwidth=4:expandtab:syntax on:runtime ~/.vim/tcl.vim: */ 
# Started 30Oct02 13:00
# Last Change:
# Fri Nov 15 10:51:45 EST 2002
#This file: psic.tcl
#  Is the main menu for all PSIC forms
#  Containing code to generate the main window for the
#  PSIC application, which invokes individual *.tcl files
#  stored in this directory, which are "sourced" by 
#  the "proc invoke"  as needed

eval destroy [winfo child .]
set mx 600x040
wm title . "PSIC Single Store Main Menu"
wm geometry . $mx+100+1

# The follow code is placed in each
# psic*.tcl file and uses Marker variable "psicMenu"
# to be tested by the child see if psic.tcl is loaded:
# e.g.
# if {![info exists psicMenu]} {
#    error "This script should be run from the \"psic.tcl\" menu."
# }

set psicMenu 1

# to prevent cover up of a loaded window
set lastposition 100

# new window.
#
# Arguments:
# w -     The name of the window to position.

proc positionWindow {w} {
    global lastposition
    wm geometry $w +$lastposition+100
    if {$lastposition < 800} {
        set lastposition [expr $lastposition + 100]
    } else {
        set lastposition 100
    }
}

#
# invoke
# This procedure is called when the user clicks on a demo description.
# It is responsible for invoking the demonstration.
#
# Arguments:
# index -       The index of the character that the user clicked on.
proc invoke {index} {
    if [catch {wm state .$index} ] {
        uplevel [list source $index.tcl]
        update
    } else {
        focus .$index
    } 
}

# aboutBox --
#
#       Pops up a message box with an "about" message
#
proc aboutBox {} {
    tk_messageBox -icon info -type ok -title "About PSIC" \
    -message \
"Point of Sale Inventory Control\n\
          (PSIC)\n\
Copyright (c) 1994-2003\n\
  JCI Inc.\n
John Turner\n\
(304) 776-3675\n
JLT@wvInter.net"
}

#--end aboutBox

bind . <F1> aboutBox


set font {Helvetica 14}
menu .menu -tearoff 0
.menu add cascade -menu .menu.file -label "About & Quit" -underline 0
set m .menu.file
menu $m -tearoff 0

# On the Mac use the specia .apple menu for the about item
if {$tcl_platform(platform) == "macintosh"} {
    .menu add cascade -menu .menu.apple
    menu .menu.apple -tearoff 0
    .menu.apple add command -label "About..." -command "aboutBox"
} else {
    $m add command -label "About..." -command "aboutBox" \
        -underline 0 -accelerator "<F1>"
    $m add sep
}

$m add command -label "Quit" -command "exit" -underline 0 -accelerator "Meta-Q"



#  next menu

set m .menu.file2
.menu add cascade -menu $m -label "File" -menu $m -underline 0
menu $m -tearoff 0
$m add command -label "Open..." -command {error "this is just a demo: no action has been defined for the \"Open...\" entry"}
$m add command -label "New" -command {error "this is just a demo: no action has been defined for the \"New\" entry"}
$m add command -label "Save" -command {error "this is just a demo: no action has been defined for the \"Save\" entry"}
$m add command -label "Save As..." -command {error "this is just a demo: no action has been defined for the \"Save As...\" entry"}
$m add separator
$m add command -label "Print Setup..." -command {error "this is just a demo: no action has been defined for the \"Print Setup...\" entry"}
$m add command -label "Print..." -command {error "this is just a demo: no action has been defined for the \"Print...\" entry"}

# next menu

set m .menu.psicSetup
.menu add cascade -label "PSICSetup" -menu $m -underline 7
menu $m -tearoff 0
$m add command -label "About PSIC" -command "aboutBox"
foreach i {{General Information} {Maintentance} {End of Month/Year}} {
        $m add command -label $i -command [list puts "You invoked \"$i\""]
}

# next menu
set m .menu.dataIN
.menu add cascade -label "Data In" -menu $m -underline 5
menu $m -tearoff 0
$m add command -label "test current_test.tcl" -command [list invoke current_test]
$m add command -label "Customers source" -command [list invoke customers]

# next menu
set m .menu.dataOut
.menu add cascade -label "Data Out" -menu $m -underline 5
menu $m -tearoff 0
$m add command -label "About PSIC" -command "aboutBox"

# next menu
set m .menu.endDay
.menu add cascade -label "End of Day" -menu $m -underline 7
menu $m -tearoff 0
$m add command -label "About PSIC" -command "aboutBox"

# next menu
set m .menu.endMonth
.menu add cascade -label "End of Month" -menu $m -underline 7
menu $m -tearoff 0
$m add command -label "About PSIC" -command "test"
proc test {} {
    if [catch {wm state .customers} ] {
            tk_messageBox -icon info -type ok -message "Customers CLOSED"
    } else {
            tk_messageBox -icon info -type ok -message "Customers OPEN"
    }
}
. configure -menu .menu

label .msg -wraplength 4i -justify center
    .msg configure -text "PSIC Single Store Main Starting Point.\nYou may select from the above menu, the jobs to be done."
pack .msg -side top


