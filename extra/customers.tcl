# customers.tcl
#
# last revised :.!date
# Fri Nov 22 10:34:13 EST 2002

# Started:
# Mon Oct 28 7:48:24 EST 2002

set Me customers
if {![info exists psicMenu]} {
	error "This script should be run from the \"psic.tcl\" menu."
	exit
} else {
	set w .$Me
	toplevel $w
	;# Caps for the first Character
	set t1 [string toupper [string index $Me 0]]; set t2 [string range $Me 1 end]
	wm title $w $t1$t2 
	positionWindow $w
}


load /usr/lib/libpgtcl.so
lappend ::auto_path ../lib/widgets
package require BWidget

#Using the BWidget ScrolledWindow:

proc nodeSelect {tree } {
# 1 If selected node exists...
	global w cid_range
    global custfirst custlast custadd1 custphone custpost custcity custstate custpcard custpeg
    foreach c {[list custfirst custlast custadd1 custphone custpost custcity custstate custpcard custpeg]} {
        set $c {}
    }
    set node [$tree selection get]
    if {[$tree exists $node]} {
        $tree selection set $node

        puts "Selected ->  $node"
        puts "cust ID [string range $node 6 end]"
        puts "node length [string length [$tree nodes $node]]"
        puts "at swtich node = $node"

        switch -regexp -- $node {
            puts "at swtich node = $node"
            {^[A-Z]} {catch {
                            set pgconn [pg_connect psic]
                            pg_select $pgconn "SELECT \"Customer ID\" as custid, upper(\"LName\") || ', ' || \"FName\" as whatusersees \
                                        FROM \"Customers\" \
                                        WHERE substr(upper(\"LName\"),1,1) ~*'$node' \
						 					AND \"Customer ID\" $cid_range \
                                        ORDER BY whatusersees " arr {
                                                $tree insert end $node level1$arr(custid) -text $arr(whatusersees)
                                        }
                          }
            }
          
           {^(level1)} {catch {puts "at level1"
                               set lnode [string length [$tree nodes $node]]
                               if {$lnode < 1} {
                                        set custid [string range $node 6 end]
                                        set pgconn [pg_connect psic]
					pg_select $pgconn "SELECT \"Address\" as adr, \"Phone\" as ph \
                                                FROM \"Customers\" \
                                                WHERE \"Customer ID\" = '$custid' " arr {
                                                   set ac [string range $arr(ph) 0 2]
                                                   set prefix [string range $arr(ph) 3 5]
                                                   set postfix [string range $arr(ph) 6 9]
                                                   $tree insert end $node level2$custid \
                                                        -text [format "%s ph# (%s) %s-%s" $arr(adr) $ac $prefix $postfix]
                                                }
                                      } else {
                                        set custid [string range $node 6 end]
                                        set pgconn [pg_connect psic]
                                        pg_select $pgconn "SELECT \"Customer ID\" as custid, \"LName\" || ', ' || \"FName\" as whatusersees \
                                                FROM \"Customers\" \
                                                WHERE \"Customer ID\" = '$custid' " \
                                                arr {
						                             $w.nb itemconfigure 2 -text "Edit: $arr(whatusersees)"
                                                }
                                      }
                                  }
                }
		
		default {puts "at default"
		
            set custid [string range $node 6 end]
                        set pgconn [pg_connect psic]
                        pg_select $pgconn "SELECT \"Customer ID\" as custid, \"LName\" || ', ' || \"FName\" as whatusersees \
                                           FROM \"Customers\" \
                                           WHERE \"Customer ID\" = '$custid' " \
                                           arr {
                                               $w.nb itemconfigure 2 -text "Edit: $arr(whatusersees)"
                                           }
		}
        }
    }
	catch {pg_disconnect $pgconn}
}
#--

#______________
set once 0
proc exitMe {} {
# dialog2.tcl --
# This script creates a dialog box with a global grab.
#
    global w
    global once
    if {$once == 0} {
        set once 1

    after idle {
    .dialog2.msg configure -wraplength 4i
    }
    after 100 {
    grab -global .dialog2
    }
    set i [ \
	    tk_dialog .dialog2 "Quit Customers Now..." \
	    {Are you sure you want to QUIT Now}\
	    question 0 "Save & Quit" Cancel "Quit No Saves"\
      ]

    switch $i {
        0 {
	        puts "You pressed Save & Quit"
            global isOpen
	        set isOpen(customers) no
	        destroy $w
        }
        1 {
	        puts "You pressed Cancel"
        }
        2 {
            global isOpen
	        set isOpen(customers) no
	        destroy $w
        }
    }
    } else {
        #do nada for now
    }
}
#--

#___________
# Test to show some array, not used in this script now
    
proc parray {myarray} {
	puts "at parray = $myarray"
	upvar $myarray a
	foreach el [lsort [array names a]] {
	puts "$el = $a($el)"
	}
}

proc findIt {} {
	puts "at find it"
	global isOpen
	parray isOpen
}
#--


#_____________
proc newCustomer {} {
global custpeg
        puts "at newCustomer Peg ID $custpeg"
        $::page2.cb1 setvalue @$custpeg
}
#--

#______________
proc editCustomer {tree} {
	global w
    global custfirst custlast custadd1 custphone custpost custcity custstate custpcard custpeg
    # Select c."Postal Code", p."City", p."State"\
    # From ("PostalCodes" AS p \
    # RIGHT JOIN "Customers" AS c ON substr(c."Postal Code",1,5) = p."Postal Code");
    
    set node [$tree selection get]
	if {[string length $node] <= 1} {
	   puts "no Customer Selected"
	} else {
	  puts "F9: $tree"
	  set custid [string range $node 6 end]
          set pgconn [pg_connect psic]
                pg_select $pgconn "SELECT c.\"Customer ID\" as custid, c.\"LName\" || ', ' || c.\"FName\" as whatusersees, \
                                    c.\"LName\" as last, c.\"FName\" as first, c.\"Address\" as add1, c.\"Phone\" as phone, \
                                    c.\"Postal Code\" as post, \
                                    p.\"City\" as city, p.\"State\" as state, \
                                    c.pcard as pcard, c.\"Peg ID\" as peg \
                                   FROM (\"PostalCodes\" AS p RIGHT JOIN \"Customers\" AS c \
                                        ON substr(c.\"Postal Code\",1,5) = p.\"Postal Code\") \
                                   WHERE c.\"Customer ID\" = '$custid' " \
                                   arr {
                                       set custfirst $arr(first)
                                       set custlast $arr(last)
                                       set custadd1 $arr(add1)
                                       set custpost $arr(post)
                                       set custphone [format \
                                            "(%s)%s-%s"  \
                                            [string range $arr(phone) 0 2] \
                                            [string range $arr(phone) 3 5] \
                                            [string range $arr(phone) 6 end] \
                                                    ]
                                       set custid $arr(custid)
                                       if {[string length $arr(post)] > 5} {
                                       set custpost [format "%s-%s" [string range $arr(post) 0 4] [string range $arr(post) 5 end]]
                                        } else {
                                            set custpost $arr(post)
                                        }
                                        set custcity $arr(city)
                                        set custstate $arr(state)
                                        set custpcard $arr(pcard)
                                        set custpeg $arr(peg)
                                        puts "Peg ID $arr(peg)"
                                        catch {
                                            $::page2.cb1 setvalue @0 
                                            $::page2.cb1 setvalue @$arr(peg)
                                            }
                                        $::page2.l0 configure -text "Cust.ID: $arr(custid)"
                                        puts [format "Name %s" $custlast]
					                    $w.nb itemconfigure 2 -text "Edit: $arr(whatusersees)"
                                        }
	  $w.nb raise 2
    }
	catch {pg_disconnect $pgconn}
}
#--

#___________________
proc toOrders {tree} {
	set node [$tree selection get]
	set custid [string range $node 6 end]
	puts "Open Orders for ID: $custid"
}
#--

# Setup NoteBook And Tree

set nb [NoteBook $w.nb]

set tab1 [$nb insert end 1 -text "All Customers"]
set tab2 [$nb insert end 2 -text "Edit Customer"]


# Scrolled-window arround tree, with auto scrollbars
set sw [ScrolledWindow $tab1.sw]

# tree
set tree [Tree $sw.tree -bg #dedbde -width 30 -height 30]

$sw setwidget $tree

#
# Insert Buttons
#
frame $w.t
button $w.t.b0 -text Quit -underline 0 -command exitMe
button $w.t.b1 -text Find -underline 0 -command findIt
button $w.t.b2 -text New -underline 0 -command [list newCustomer]
button $w.t.b3 -text "F9\nEdit" -underline 3 -command [list editCustomer $tree]
button $w.t.b4 -text "F12 to \nOrders" -underline 8 -command [list toOrders $tree]


# Bind the buttons
bind MyBindings <Destroy> exitMe
bind MyBindings <Key-q> exitMe
bind MyBindings <Key-f> findIt
bind MyBindings <Key-n> [list newCustomer]
bind MyBindings <Key-e> [list editCustomer $tree]
bind MyBindings <Key-o> [list toOrders $tree]

# add the bindtags to all child widgets of the tree,
# and add an appropriate binding to the bindtag

bind MyBindings <Key-F12> [list toOrders $tree]
bind MyBindings <ButtonPress-1> [list nodeSelect $tree]
bind MyBindings <Key-F9> [list editCustomer $tree]

foreach child [winfo children $tree] {
        bindtags $child [concat MyBindings [bindtags $child]]
}

frame $w.t2
set cmd {puts $tree select setnodes root] {$tree delete $r"}}

 radiobutton $w.t2.rb1 -text "Show ID's > 10" -variable cid_range -value ">10"  -command "deleteNodes"
 radiobutton $w.t2.rb2 -text "Show ID's < 10" -variable cid_range -value "<10" -command "deleteNodes"

proc deleteNodes {} {
	global tree ;# OR can use $::tree
    $tree delete [$tree nodes root]
    # test OK! set x [$::tree delete [$::tree nodes root]]
	loadTreeRoot
 }

proc fill.cb1 {cb1 }  {
    $cb1 configure -values [list "none set" one two three four five six seven eight nine ten eleven twelve]
}

		
pack $w.t -fill x
pack $w.t.b0 $w.t.b1 $w.t.b2 $w.t.b3 $w.t.b4 -side left -ipadx 2m -ipady 1m -expand 1 -fill both
pack $w.t2 -fill x
pack $w.t2.rb1 $w.t2.rb2 -side left -expand 1 -fill both
pack $nb -fill both -expand true
pack $sw -fill both -expand true
pack $tree -fill both -expand true
$nb raise 1

#-----------
#--- Scrolled Frame -----

set sw2 [ ScrolledWindow $tab2.sw ]
pack $sw2 -fill both -expand true

set sf [ ScrollableFrame $sw2.sf -bg #dedbde]
$sw2 setwidget $sf
set page2 [ $sf getframe ]

#------------
# sample of how to use grid to place objects on a grid
#The traversal order is determined by the stacking order - i do
#  raise .first .second .third ...
# at the end of dialogue creation to set the traversal order.



 label $page2.l -text "Enter Name:" 
 label $page2.2 -text "Enter Upto, 2 Address Lines"

 label $page2.l0 -text "CustomerID:" -relief groove -width 25 -anchor w
 label $page2.l1 -text "First & Inital:" -width 14 -anchor e 
 label $page2.l2 -text "Last:" -width 14 -anchor e 
 label $page2.l3 -text "Address:" -width 14 -anchor e
 label $page2.l4 -text "2nd. Address:" -width 14 -anchor e
 label $page2.l4p -text "Phone:" -width 14 -anchor e
 label $page2.l5 -text "Postal Code:" -width 14 -anchor e
 label $page2.l6 -text "AutoFind City:" -width 14 -anchor e
 label $page2.l7 -text "... and State:" -width 14 -anchor e
 label $page2.l8 -text "Personal\nEvaluation\nGrade:" -width 14 -justify right -anchor e
 label $page2.l9 -text "P. Card #:" -width 14 -anchor e
 
 entry $page2.e1 -width 20 -textvariable custfirst ;# 1st name
 entry $page2.e2 -width 15 -textvariable custlast  ;# last name
 entry $page2.e3 -width 25 -textvariable custadd1   ;# address 1
 entry $page2.e4 -width 25  ;# address 2
 entry $page2.e4p -width 25 -textvariable custphone   ;# phone 1
 entry $page2.e5 -width 15 -textvariable custpost ;# postal code
 entry $page2.e6 -width 25 -textvariable custcity -bg #dedbda  ;# City
 entry $page2.e7 -width 3 -textvariable custstate -bg #dedbda ;# State
 entry $page2.e8 -width 15 -textvariable custpcard 
 
 ComboBox $page2.cb1  -width 15  
 fill.cb1 $page2.cb1

 button $page2.b1 -text "Save All\nChanges"
 button $page2.b2 -text "Edit\nPoatal Codes"
 button $page2.b3 -text "Edit\nPEG"

# First Row
 grid $page2.l0 -row 1 -column 1
# 2nd Row 
 grid $page2.l -row 2 -columnspan 3
# 3rd Row
 grid $page2.l1 -row 3 -column 0
 grid $page2.e1 -row 3 -column 1 -sticky w
 grid $page2.b1 -row 3 -column 2 -rowspan 2
# 4th Row
 grid $page2.l2 -row 4 -column 0
 grid $page2.e2 -row 4 -column 1 -sticky w
# 5th Row
 grid $page2.2 -columnspan 3
# 6th Row 
 grid $page2.l3 -row 6 -column 0
 grid $page2.e3 -row 6 -column 1 -sticky w
# 7th Row
 grid $page2.l4 -row 7 -column 0
 grid $page2.e4 -row 7 -column 1 -sticky w
# 8th Row
 grid $page2.l4p -row 8 -column 0
 grid $page2.e4p -row 8 -column 1 -sticky w
# 9th Row 
 grid $page2.l5 -row 9 -column 0
 grid $page2.e5 -row 9 -column 1 -sticky w
# 10th Row
 grid $page2.l6 -row 10 -column 0
 grid $page2.e6 -row 10 -column 1 -sticky w
 grid $page2.b2 -row 10 -column 2 -rowspan 2

# 11th Row 
 grid $page2.l7 -row 11 -column 0
 grid $page2.e7 -row 11 -column 1 -sticky w
 
# 12th 
 grid $page2.l9 -row 12 -column 0
 grid $page2.e8 -row 12 -column 1 -sticky w 

# 13th
 grid $page2.l8 -row 13 -column 0
 grid $page2.cb1 -row 13 -column 1 -sticky w
 grid $page2.b3 -row 13 -column 1 -sticky e -rowspan 2


#----------
# Load Tree Root Level...
proc loadTreeRoot {} {
		global cid_range 
		global tree
set pgconn [pg_connect psic]

pg_select $pgconn "SELECT DISTINCT substr(upper(\"LName\"),1,1) as cid \
                         FROM \"Customers\" \
						 WHERE \"Customer ID\" $cid_range \
                         ORDER BY cid " arr {
                        $tree insert end root $arr(cid) -text $arr(cid)
                        }
	catch {pg_disconnect $pgconn}
}

#----- set defaults

set cid_range 1  ;# do not show 1 to 10 special 
set cid_range ">10"  ;# do not show 1 to 10 special 

loadTreeRoot	

#	puts "FINSHED LOADING"
#--- end 

