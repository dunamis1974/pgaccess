#==========================================================
# Usergroups -
#
#   manages PG users (and groups of users)
#
#==========================================================
#
namespace eval Usergroups {
    variable Win
    variable Perms
    variable Objs
}


#----------------------------------------------------------
# ::Usergroups::designPerms --
#
#   called from another namespace to display/modify permissions
#   on the selected object, usually from Design mode on the object
#
# Arguments:
#   obj_    object to display/modify permissions on
#   type_   type of the object (Table, View, etc.)
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::designPerms {obj_ type_} {

    variable Win
    variable Objs

    # make sure we can see all the PG/PGA objects
    set Objs(pg) 1
    set Objs(pga) 1

    if {[winfo exists .pgaw:User]} {
        Window show .pgaw:User
        tkwait visibility .pgaw:User
    } else {
        Window show .pgaw:User
        tkwait visibility .pgaw:User
        ::Usergroups::fillUsergroupsTree "user"
        ::Usergroups::fillUsergroupsTree "group"
        ::Usergroups::fillObjectTree
    }

    $Win(otree) opentree $type_
    $Win(otree) see "$type_-$obj_"
    $Win(otree) selection set "$type_-$obj_"

    $Win(ugtree) opentree "pg_group" 0
    $Win(ugtree) opentree "public"
    $Win(ugtree) see "public"
    $Win(ugtree) selection set "public"

    ::Usergroups::showObjectPerms 1 "$type_-$obj_"

}; # end proc ::Usergroups::designPerms


#----------------------------------------------------------
# ::Usergroups::new --
#
#   called from the main screen
#   builds the usergroup window, and opens the new user dialog
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::new {} {
    ::Usergroups::open ""
    ::Usergroups::newUser
}; # end proc ::Usergroups::new


#----------------------------------------------------------
# ::Usergroups::design --
#
#   called from the main screen
#   builds the usergroup window, and opens the user dialog
#
# Arguments:
#   username_   the name of the user to modify
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::design {username_} {
    ::Usergroups::open $username_
    ::Usergroups::designUser $username_
}; # end proc ::Usergroups::design


#----------------------------------------------------------
# ::Usergroups::open --
#
#   called from the main screen
#   builds the usergroup window
#
# Arguments:
#   username_   required but currently discarded
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::open {username_} {
    Window show .pgaw:User
    tkwait visibility .pgaw:User
    ::Usergroups::fillUsergroupsTree "user"
    ::Usergroups::fillUsergroupsTree "group"
    ::Usergroups::fillObjectTree
}; # end proc ::Usergroups::open


#----------------------------------------------------------
# ::Usergroups::changePerms --
#
#   changes an object's permission status
#
# Arguments:
#   perm_   name of the permission
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::changePerms {perm_} {

    global CurrentDB
    variable Perms
    variable Win

    set V [::Database::getPgVersion $CurrentDB]

    set usrgrp [lindex [$Win(ugtree) selection get] 0]
    set obj [$Win(otree) selection get]

    if {[$Win(ugtree) parent [lindex $usrgrp 0]] == "root"} {return}
    if {[$Win(otree) parent [lindex $obj 0]] == "root"} {return}

    # only allow WITH GRANT OPTION for PG 7.4 and up
    # but you cant give groups that option
    set grpchk [lindex [split $usrgrp '-'] 0]
    if { ($Perms($perm_)==2 && $V>=7.4) \
      || ($Perms($perm_)==1 && $V<7.4) \
      || ($Perms($perm_)==1 && $V>=7.4 \
         && ([string match -nocase $grpchk "pg_group"] \
            || [string match -nocase $grpchk "public"])) } {

        setCursor CLOCK

        foreach o $obj {

            set sql "
                REVOKE $perm_
                   ON "

            set objtype [lindex [split $o '-'] 0]
            set objname [string map {: { }} [lindex [split $o '-'] 1]]

            # this is probably a bug in PG, at least v7.2
            # SEQUENCES dont allow the qualifier 'sequence'
            # in GRANT/REVOKE statements
            # ...and wuzzup with views in 7.3
            if {[lsearch [list "sequence"] $objtype] == -1
              && [lsearch [list "view"] $objtype] == -1} {
                append sql $objtype
            }
            append sql " "
            # dont quote functions
            if { [lsearch [list "function"] $objtype] == -1} {
                append sql [::Database::quoteObject $objname]
            } else {
                append sql [string map {\" {}} $objname]
            }
            append sql " FROM "

            if {[lindex [split $usrgrp '-'] 0] == "pg_group"} {
                append sql " GROUP " [lindex [split $usrgrp '-'] 1]
            } elseif {[lindex [split $usrgrp '-'] 0] == "public"} {
                append sql " PUBLIC "
            } else {
                append sql [lindex [split $usrgrp '-'] 1]
            }

            sql_exec noquiet $sql

        }

        setCursor NORMAL

        set Perms($perm_) 0

    } else {

        setCursor CLOCK

        foreach o $obj {

            set sql "
                GRANT $perm_
                   ON "

            set objtype [lindex [split $o '-'] 0]
            set objname [string map {: { }} [lindex [split $o '-'] 1]]

            # this is probably a bug in PG, at least v7.2
            # SEQUENCES dont allow the qualifier 'sequence'
            # in GRANT/REVOKE statements
            # ...and wuzzup with views in 7.3
            if {[lsearch [list "sequence"] $objtype] == -1
              && [lsearch [list "view"] $objtype] == -1} {
                append sql $objtype
            }
            append sql " "
            # dont quote functions
            if { [lsearch [list "function"] $objtype] == -1} {
                append sql [::Database::quoteObject $objname]
            } else {
                append sql [string map {\" {}} $objname]
            }
            append sql " TO "

            if {[lindex [split $usrgrp '-'] 0] == "pg_group"} {
                append sql " GROUP " [lindex [split $usrgrp '-'] 1]
            } elseif {[lindex [split $usrgrp '-'] 0] == "public"} {
                append sql " PUBLIC "
            } else {
                append sql [lindex [split $usrgrp '-'] 1]
            }

            if {$Perms($perm_)==1 && $V>=7.4} {
                append sql " WITH GRANT OPTION"
            }

            sql_exec noquiet $sql

        }

        setCursor NORMAL

        if {$V>=7.4} {
            incr Perms($perm_)
        } else {
            set Perms($perm_) 1
        }

    }

    ::Usergroups::showObjectPerms 3 [lindex $obj 0]
    ::Usergroups::showAllObjectPerms

}; # end proc ::Usergroups::changePerms


#----------------------------------------------------------
# ::Usergroups::lightPermButtons --
#
#   switches on and off the permission buttons on the right
#
# Arguments:
#   perm_   name of permission button to turn off or on
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::lightPermButtons {perm_} {

    variable Perms
    variable Win

    switch $Perms($perm_) {
        0 {
            # no permission
            $Win(perms-$perm_) configure \
                -foreground #fefefe \
                -background #000000
        }
        1 {
            # has permission
            $Win(perms-$perm_) configure \
                -foreground #000000 \
                -background #fefefe
        }
        2 {
            # has permission with option to give it to others
            $Win(perms-$perm_) configure \
                -foreground #000000 \
                -background #808080
        }
    }

}; # end proc ::Usergroups::lightPermButtons


#----------------------------------------------------------
# ::Usergroups::showObjectPerms --
#
#   lights up buttons for selected object's permissions
#
# Arguments:
#   num_    the number of the button click
#           1 single click
#           2 double click
#           3 single click w/ctrl
#           4 single click w/shift
#   node_   the name of the node clicked
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::showObjectPerms {num_ node_} {

    global CurrentDB
    variable Win
    variable Perms

    # clear selection if it is a single or double click with no shift/control
    if {$num_ == 2 || $num_ == 1} {
        $Win(otree) selection clear
    }
    # shift we need them all in between
    if {$num_ == 4} {
        foreach selected [$Win(otree) selection get] {
            set snode [$Win(otree) index $selected]
            set turnons [$Win(otree) nodes [$Win(otree) parent $node_] $snode [$Win(otree) index $node_]]
            foreach to $turnons {
                $Win(otree) selection add $to
            }
            set turnons [$Win(otree) nodes [$Win(otree) parent $node_] [$Win(otree) index $node_] $snode]
            foreach to $turnons {
                $Win(otree) selection add $to
            }
        }
    }

    $Win(otree) selection add $node_

    # disable all permission buttons
    set allabbrs [list "r" "w" "a" "d" "R" "x" "t" "X" "U" "T" "C" "A"]
    set allperms [list "SELECT" "UPDATE" "INSERT" "DELETE" "RULE" "REFERENCES" "TRIGGER" "EXECUTE" "USAGE" "TEMPORARY" "CREATE" "ALL"]
    foreach p $allperms {
        set Perms($p) 0
        ::Usergroups::lightPermButtons $p
        $Win(perms-$p) configure \
            -state disabled
    }

    # if no user group selected then no perms can be given on the object
    if { [llength [$Win(ugtree) selection get]] == 0 } {return}
    if {[$Win(ugtree) parent [$Win(ugtree) selection get]] == "root"} {return}
    if {[$Win(otree) parent $node_] == "root"} {return}

    set shownperms [list]

    set oclass [lindex [split $node_ "-"] 0]
    set oname [string map {: { }} [lindex [split $node_ "-"] 1]]

    # determine which permissions can be modified on this object
    switch $oclass {

        table {
            lappend shownperms "SELECT" "UPDATE" "INSERT" "DELETE" "RULE" "REFERENCES" "TRIGGER" "ALL"
        }

        database {
            lappend shownperms "CREATE" "TEMPORARY" "ALL"
        }

        function {
            lappend shownperms "EXECUTE" "ALL"
        }

        language {
            lappend shownperms "USAGE" "ALL"
        }

        schema {
            lappend shownperms "CREATE" "USAGE" "ALL"
        }

        view {
            lappend shownperms "SELECT" "UPDATE" "INSERT" "DELETE" "RULE" "REFERENCES" "TRIGGER" "ALL"
        }

        sequence {
            lappend shownperms "SELECT" "UPDATE" "INSERT" "DELETE" "RULE" "REFERENCES" "TRIGGER" "ALL"
        }

    }; # end switch

    foreach p $shownperms {
        $Win(perms-$p) configure \
            -state normal
    }

    # find the specific permissions already set for the object
    # moved to database namespace cuz its 7.3 picky
    set acl [::Database::getPermissions $CurrentDB $oname $oclass]

    set ugnode [$Win(ugtree) selection get]
    set ugtype [string trim [lindex [split $ugnode '-'] 0]]
    set ugname [string trim [lindex [split $ugnode '-'] 1]]
    set acllist [split $acl ',']

    if {[string match -nocase "pg_group" $ugtype]} {
        set fnd [subst [lsearch -regex $acllist "^\"group $ugname"]]
    } elseif {[string match -nocase "public" $ugtype]} {
        set fnd [lsearch -regex $acllist "^="]
    } else {
        set fnd [subst [lsearch -regex $acllist "^$ugname"]]
    }

    if {$fnd != -1} {
        set ugoperms [lindex [split [lindex $acllist $fnd] '='] 1]
        set ugoperms [string trimright $ugoperms '\}']
        set ugoperms [string trimright $ugoperms '\"']
        if {[string first / $ugoperms] != -1 } {
            set ugoperms [string range $ugoperms 0 [string first / $ugoperms]]
        }
        foreach ap $allperms aa $allabbrs {
            set permpos [string first $aa $ugoperms]
            if {$permpos != -1} {
                # look if the object has GRANT WITH GRANT OPTION
                set star [string index $ugoperms [expr {$permpos+1}]]
                if {[string match {\*} $star]} {
                    set Perms($ap) 2
                } else {
                    set Perms($ap) 1
                }
            } else {
                set Perms($ap) 0
            }
            ::Usergroups::lightPermButtons $ap
        }
    }

}; # end proc ::Usergroups::showObjectPerms


#----------------------------------------------------------
# ::Usergroups::showAllObjectPerms --
#
#   lites up a little image for each object that has at
#   least _some_ permissions set for the selected user/group
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::showAllObjectPerms {} {

    global CurrentDB
    variable Win
    set V [::Database::getPgVersion $CurrentDB]

    set ugnode [$Win(ugtree) selection get]
    set ugtype [string trim [lindex [split $ugnode '-'] 0]]
    set ugname [string trim [lindex [split $ugnode '-'] 1]]

    if {[$Win(ugtree) parent $ugnode] == "root"} {return}

    foreach obignode [$Win(otree) nodes root] {
        foreach olilnode [$Win(otree) nodes $obignode] {
            set oclass [lindex [split $olilnode "-"] 0]
            set oname [string map {: { }} [lindex [split $olilnode "-"] 1]]
            set acl [::Database::getPermissions $CurrentDB $oname $oclass]
            set acllist [split $acl ',']
            if {[string match -nocase "pg_group" $ugtype]} {
                set fnd [subst [lsearch -regex $acllist "^\"group $ugname"]]
            } elseif {[string match -nocase "public" $ugtype]} {
                if {$V >= 7.3} {
                    set fnd [subst [lsearch -regex $acllist "^="]]
                } else {
                    set fnd [expr {[string length [lindex $acllist 0]]-2}]
                }
            } else {
                set fnd [subst [lsearch -regex $acllist "^$ugname"]]
            }
            if {$fnd != -1} {
                $Win(otree) itemconfigure $olilnode \
                    -image ::icon::news-16
            } else {
                $Win(otree) itemconfigure $olilnode \
                    -image {}
            }
        }
    }

}; # end proc ::Usergroups::showAllObjectPerms


#----------------------------------------------------------
# ::Usergroups::fillObjectTree --
#
#   fills the second pane, all the PG objects w/perms
#
# Arguments:
#   refill_     optional, will destroy the tree first if 1
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::fillObjectTree {{refill_ 0}} {

    global CurrentDB

    variable Win
    variable Objs

    foreach low [list "table" "view" "database" "function" "sequence" "schema" "language"] upp [list "Tables" "Views" "Databases" "Functions" "Sequences" "Schemas" "Languages"] {
        if {[$Win(otree) exists $low]} {
            if {$refill_} {
                $Win(otree) delete [$Win(otree) nodes $low]
            }
            set lst [::Database::getObjectsList $upp $CurrentDB 0 1 $Objs(pg) $Objs(pga)]
            foreach o $lst {
                if {$low=="function"} {
                    set o [string map {{ } : \" {}} $o]
                } else {
                    set o [string map {\" {}} $o]
                }
                $Win(otree) insert end $low "$low-$o" \
                    -text $o
            }
        }
    }

}; # end proc ::Usergroups::fillObjectTree


#----------------------------------------------------------
# ::Usergroups::fillUsergroupsTree --
#
#   builds the initial users and groups tree nodes
#
# Arguments:
#   node_   either user or group branches
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::fillUsergroupsTree {node_} {

    global CurrentDB
    variable Win

    switch $node_ {

        user {

            # if the users branch is open, clean and close it
            if {[$Win(ugtree) itemcget $node_ -open]} {
                $Win(ugtree) closetree $node_
                $Win(ugtree) delete [$Win(ugtree) nodes $node_]
            # now open the branch with fresh data
            }
            set sql "
                SELECT *
                  FROM [::Database::qualifySysTable pg_user]
              ORDER BY usename"
            setCursor CLOCK
            catch {
                wpg_select $CurrentDB $sql r {
                    $Win(ugtree) insert end $node_ "user-$r(usename)" \
                        -text $r(usename)
                }
            }
            setCursor DEFAULT

        }

        group {

            # its actually pg_group
            set node_ "pg_group"

            # if the groups branch is open, clean and close it
            if {[$Win(ugtree) itemcget $node_ -open]} {
                $Win(ugtree) closetree $node_
                $Win(ugtree) delete [$Win(ugtree) nodes $node_]
            # now open the branch with fresh data
            }

            # the PUBLIC group includes all users
            $Win(ugtree) insert end $node_ public \
                -text PUBLIC
            set sql "
                SELECT *
                  FROM [::Database::qualifySysTable pg_user]
              ORDER BY usename"
            setCursor CLOCK
            catch {
                wpg_select $CurrentDB $sql r {
                    $Win(ugtree) insert end public \
                        "public-$r(usename)" \
                        -text $r(usename)
                }
            }
            setCursor DEFAULT

            # get the rest of the groups for display
            set sql "
                SELECT *
                  FROM [::Database::qualifySysTable pg_group]
              ORDER BY groname"
            setCursor CLOCK
            wpg_select $CurrentDB $sql r {
                $Win(ugtree) insert end pg_group "pg_group-$r(groname)" \
                    -text $r(groname)

                # now it gets a little sloppy
                # but it used to be sloppier
                # we just need to get the grolist and split it up
                # so then we can look at each user id

                set sql "
                    SELECT grolist
                      FROM [::Database::qualifySysTable pg_group]
                     WHERE groname='$r(groname)'"
                set res [wpg_exec $CurrentDB $sql]
                set userids [string trim [pg_result $res -getTuple 0] "{}"]
                pg_result $res -clear

                # well there might not be any people in the group yet
                if {[string length $userids] > 0} {
                    # now we get the usernames since we have userids
                    set sql2 "
                        SELECT *
                          FROM [::Database::qualifySysTable pg_user]
                         WHERE usesysid
                            IN ($userids)
                          ORDER BY usename"
                    wpg_select $CurrentDB $sql2 rr {
                        $Win(ugtree) insert end "pg_group-$r(groname)" \
                            "pg_group-$r(groname)-$rr(usename)" \
                            -text $rr(usename)
                    }
                }

            }

        }

        default {}

    }; # end switch

    setCursor DEFAULT

}; # end proc ::Usergroups::fillUsergroupsTree


#----------------------------------------------------------
# ::Usergroups::selectUsergroups --
#
#   called when a node is clicked in the ugtree
#   doubleclick doesnt do anything fancy anymore
#
# Arguments:
#   num_    the number of the button click, 1 or 2 for doubleclick
#   node_   the name of the node clicked
#   open_   whether to leave the tree open or not
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::selectUsergroups {num_ node_ {open_ 1}} {

    variable Win

    if {$num_ != 1} {
        return
    }

    $Win(ugtree) opentree $node_ $open_

    $Win(ugtree) selection clear
    $Win(ugtree) selection add $node_

    set nds [list]
    foreach nd [$Win(otree) selection get] {
        ::Usergroups::showObjectPerms 1 $nd
        lappend nds $nd
    }

    ::Usergroups::showAllObjectPerms

    foreach nd $nds {
        $Win(otree) selection add $nd
    }

}; # end proc ::Usergroups::selectUsergroups


#----------------------------------------------------------
# ::Usergroups::add --
#
#   creates either a new user or a new group or a user in a group
#   depends on the current selection in the ugtree
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::add {} {

    variable Win

    set node [$Win(ugtree) selection get]

    if {[string length $node] == 0} {
        showError [intlmsg "Select either Users or Groups nodes first."]
    }

    if {[string match "user" $node] \
        || [string match "user" [$Win(ugtree) parent $node]]} {
            ::Usergroups::newUser
    }

    if {[string match "pg_group" $node]} {
        ::Usergroups::newGroup
    }

    if {[string match "pg_group" [$Win(ugtree) parent $node]] \
        || [string match "pg_group" [$Win(ugtree) parent \
        [$Win(ugtree) parent $node]]]} {
            ::Usergroups::newUserInGroup $node
    }

}; # end proc ::Usergroups::add


#----------------------------------------------------------
# ::Usergroups::modify --
#
#   changes the user properties, does nothing for groups
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::modify {} {

    variable Win

    set node [$Win(ugtree) selection get]

    if {[string match "user" [$Win(ugtree) parent $node]]} {
        ::Usergroups::designUser [lrange [split $node "-"] 1 end]
    } else {
        showError [intlmsg "You can only modify individual users."]
    }

}; # end proc ::Usergroups::modify


#----------------------------------------------------------
# ::Usergroups::remove --
#
#   deletes a selected user, a selected group, or a user in a group
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::remove {} {

    variable Win

    set node [$Win(ugtree) selection get]

    if {[string match "user" [$Win(ugtree) parent $node]]} {
        ::Usergroups::deleteUser [join [lrange [split $node "-"] 1 end] "-"]
        return
    }

    if {[string match "pg_group" [$Win(ugtree) parent $node]]} {
        ::Usergroups::deleteGroup [join [lrange [split $node "-"] 1 end] "-"]
        return
    }

    if {[string match "pg_group" [$Win(ugtree) parent \
        [$Win(ugtree) parent $node]]]} {
            set n [split $node "-"]
            set grp [lindex $n 1]
            set usr [lindex $n 2]
            ::Usergroups::deleteUserFromGroup $usr $grp
            return
    }

}; # end proc ::Usergroups::remove


#----------------------------------------------------------
# ::Usergroups::newUserInGroup --
#
#   adds a new user to a group
#
# Arguments:
#   node_   the node that was clicked
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::newUserInGroup {node_} {

    set n [split $node_ '-']
    set grp [lindex $n 0]
    if {$grp == "pg_group"} {
        set grp [lindex $n 1]
    }

    set usr [parameter [format [intlmsg "Enter new user for group %s:"] $grp]]

    if {[string length [string trim $usr]] == 0} {return}

    set sql "
        ALTER GROUP $grp
          ADD USER $usr"

    sql_exec noquiet $sql

    ::Usergroups::refreshUsergroups "pg_group-$grp"

}; # end proc ::Usergroups::newUserInGroup


#----------------------------------------------------------
# ::Usergroups::deleteUserFromGroup --
#
#   deletes a user from a group
#
# Arguments:
#   usr_    username to modify
#   grp_    group to remove user from
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::deleteUserFromGroup {usr_ grp_} {

    set delmsg [format [intlmsg "You are going to remove\n\n user %s\n\nfrom\n\n group %s \n\nProceed?"] $usr_ $grp_]

    if {[tk_messageBox \
            -title [intlmsg "FINAL WARNING"] \
            -parent .pgaw:User \
            -message $delmsg \
            -type yesno \
            -default no]=="no"} {return}

    set sql "
        ALTER GROUP $grp_
          DROP USER $usr_"

    sql_exec noquiet $sql

    ::Usergroups::refreshUsergroups "pg_group-$grp_"

}; # end proc ::Usergroups::deleteUserFromGroup


#----------------------------------------------------------
# ::Usergroups::newGroup --
#
#   displays a prompt for a new group name and creates it
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::newGroup {} {

    set newgrp [parameter [intlmsg "Enter new group name:"]]

    if {[string length [string trim $newgrp]] == 0} {return}

    sql_exec noquiet "CREATE GROUP \"$newgrp\""

    ::Usergroups::refreshUsergroups "pg_group-$newgrp"

}; # end proc ::Usergroups::newGroup


#----------------------------------------------------------
# ::Usergroups::deleteGroup --
#
#   deletes the given group
#
# Arguments:
#   groupname_  name of the group to remove
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::deleteGroup {groupname_} {

    set delmsg [format [intlmsg "You are going to delete\n\n group %s \n\nProceed?"] $groupname_]

    if {[tk_messageBox \
            -title [intlmsg "FINAL WARNING"] \
            -parent .pgaw:User \
            -message $delmsg \
            -type yesno \
            -default no]=="no"} {return}

    sql_exec noquiet "DROP GROUP \"$groupname_\""

    ::Usergroups::refreshUsergroups "pg_group"

}; # end proc ::Usergroups::deleteGroup


#----------------------------------------------------------
# ::Usergroups::deleteUser --
#
#   deletes the given user
#
# Arguments:
#   username_   name of the user to remove
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::deleteUser {username_} {

    set delmsg [format [intlmsg "You are going to delete\n\n user %s \n\nProceed?"] $username_]

    if {[tk_messageBox \
            -title [intlmsg "FINAL WARNING"] \
            -parent .pgaw:User \
            -message $delmsg \
            -type yesno \
            -default no]=="no"} {return}

    sql_exec noquiet "DROP USER \"$username_\""

    ::Usergroups::refreshUsergroups "user"

}; # end proc ::Usergroups::deleteUser


#----------------------------------------------------------
# ::Usergroups::newUser --
#
#   creates a new user with the old dialog
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::newUser {} {

    global PgAcVar

    Window show .pgaw:UserEdit
    wm transient .pgaw:UserEdit .pgaw:User

    set PgAcVar(user,action) "CREATE"
    set PgAcVar(user,name) {}
    set PgAcVar(user,password) {}
    set PgAcVar(user,createdb) NOCREATEDB
    set PgAcVar(user,createuser) NOCREATEUSER
    set PgAcVar(user,verifypassword) {}
    set PgAcVar(user,validuntil) {}

    focus .pgaw:UserEdit.eusername

}; # end proc ::Usergroups::newUser


#----------------------------------------------------------
# ::Usergroups::designUser --
#
#   opens old dialog for modifying a user
#
# Arguments:
#   username    name of the user to modify
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::designUser {username} {

    global PgAcVar CurrentDB

    Window show .pgaw:UserEdit
    tkwait visibility .pgaw:UserEdit
    wm transient .pgaw:UserEdit .pgaw:User
    wm title .pgaw:UserEdit [intlmsg "Change user"]

    set PgAcVar(user,action) "ALTER"
    set PgAcVar(user,name) $username
    set PgAcVar(user,password) {} ; set PgAcVar(user,verifypassword) {}

    pg_select $CurrentDB "SELECT *, date(valuntil) AS valdata
                            FROM [::Database::qualifySysTable pg_user]
                           WHERE usename='$username'" tup {
        if {$tup(usesuper)=="t"} {
            set PgAcVar(user,createuser) CREATEUSER
        } else {
            set PgAcVar(user,createuser) NOCREATEUSER
        }
        if {$tup(usecreatedb)=="t"} {
            set PgAcVar(user,createdb) CREATEDB
        } else {
            set PgAcVar(user,createdb) NOCREATEDB
        }
        if {$tup(valuntil)!=""} {
            set PgAcVar(user,validuntil) $tup(valdata)
        } else {
            set PgAcVar(user,validuntil) {}
        }
    }

    .pgaw:UserEdit.eusername configure -state disabled
    .pgaw:UserEdit.bcreate configure -text [intlmsg "Save"]

    focus .pgaw:UserEdit.epassword

}; # end proc ::Usergroups::designUser


#----------------------------------------------------------
# ::Usergroups::saveUser --
#
#   saves the new or modified user from the old dialog
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::saveUser {} {

    global PgAcVar CurrentDB
    variable Win

    set PgAcVar(user,name) [string trim $PgAcVar(user,name)]
    set PgAcVar(user,password) [string trim $PgAcVar(user,password)]
    set PgAcVar(user,verifypassword) [string trim $PgAcVar(user,verifypassword)]

    if {$PgAcVar(user,name)==""} {
        showError [intlmsg "User without name?"]
        focus .pgaw:UserEdit.eusername
        return
    }

    if {$PgAcVar(user,password)!=$PgAcVar(user,verifypassword)} {
        showError [intlmsg "Passwords do not match!"]
        set PgAcVar(user,password) {} ; set PgAcVar(user,verifypassword) {}
        focus .pgaw:UserEdit.epassword
        return
    }

    set cmd "$PgAcVar(user,action) user \"$PgAcVar(user,name)\""

    if {$PgAcVar(user,password)!=""} {
        set cmd "$cmd WITH PASSWORD '$PgAcVar(user,password)' "
    }

    set cmd "$cmd $PgAcVar(user,createdb) $PgAcVar(user,createuser)"

    if {$PgAcVar(user,validuntil)!=""} {
        set cmd "$cmd VALID UNTIL '$PgAcVar(user,validuntil)'"
    }

    if {[sql_exec noquiet $cmd]} {
        Window destroy .pgaw:UserEdit
        ::Usergroups::refreshUsergroups "user-$PgAcVar(user,name)"
    }

}; # end proc ::Usergroups::saveUser


#----------------------------------------------------------
# ::Usergroups::refreshUsergroups --
#
#   closes and re-fills the tree to keep user/group current
#
# Arguments:
#   node_   an optional node to highlight when done
#           defaults to the currently selected node
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Usergroups::refreshUsergroups {{node_ ""}} {

    variable Win

    if {[string length $node_]==0} {
        set node_ [$Win(ugtree) selection get]
    }

    if {![$Win(ugtree) exists $node_]
      || [$Win(ugtree) parent $node_] != "pg_group"} {
        $Win(ugtree) delete [$Win(ugtree) nodes "user"]
        ::Usergroups::fillUsergroupsTree "user"
    }
    $Win(ugtree) delete [$Win(ugtree) nodes "pg_group"]
    ::Usergroups::fillUsergroupsTree "group"

    if {[$Win(ugtree) parent $node_] != "root"} {
        $Win(ugtree) opentree [$Win(ugtree) parent $node_] 0
    }
    if {[$Win(ugtree) exists $node_]} {
        $Win(ugtree) opentree $node_
        $Win(ugtree) see $node_
        $Win(ugtree) selection set $node_
    }

}; # end proc ::Usergroups::refreshUsergroups


#==========================================================
# end Users namespace, begin Visual Tcl code
#==========================================================


proc vTclWindow.pgaw:User {base} {

    if {$base == ""} {
        set base .pgaw:User
    }

    if {[winfo exists $base]} {
        wm deiconify $base
        return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 550x450+200+100
    wm maxsize $base 1009 738
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "User Group Manager"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    # Users/Groups tree frame
    frame $base.fug \
        -borderwidth 2 \
        -width 100
    frame $base.fug.ftree
    set ::Usergroups::Win(ugframe) $base.fug.ftree

    set ::Usergroups::Win(ugtree) [Tree $base.fug.ftree.tree \
        -deltay 22 \
        -yscrollcommand [list $::Usergroups::Win(ugframe).yscroll set] \
        -xscrollcommand [list $::Usergroups::Win(ugframe).xscroll set] \
        -background #fefefe]
    $base.fug.ftree.tree insert end root user \
        -image ::icon::user-16 \
        -text [intlmsg "Users"]
    $base.fug.ftree.tree insert end root pg_group \
        -image ::icon::people-16 \
        -open 0 \
        -text [intlmsg "Groups"]
    $::Usergroups::Win(ugtree) bindText \
        <ButtonPress-1> "::Usergroups::selectUsergroups 1"
    $::Usergroups::Win(ugtree) bindImage \
        <ButtonPress-1> "::Usergroups::selectUsergroups 1"
    $::Usergroups::Win(ugtree) bindText \
        <Control-ButtonPress-1> "::Usergroups::selectUsergroups 1"
    $::Usergroups::Win(ugtree) bindImage \
        <Control-ButtonPress-1> "::Usergroups::selectUsergroups 1"

    scrollbar $base.fug.ftree.xscroll \
        -width 12 \
        -command [list $::Usergroups::Win(ugtree) xview] \
        -highlightthickness 0 \
        -orient horizontal \
        -background #DDDDDD \
        -takefocus 0
    scrollbar $base.fug.ftree.yscroll \
        -width 12 \
        -command [list $::Usergroups::Win(ugtree) yview] \
        -highlightthickness 0 \
        -background #DDDDDD \
        -takefocus 0

    frame $base.fug.fbtns \
        -borderwidth 5
    ButtonBox $base.fug.fbtns.btns \
        -orient horizontal \
        -homogeneous 1
    $base.fug.fbtns.btns add \
        -image ::icon::filenew-22 \
        -helptext [intlmsg "Add"] \
        -command ::Usergroups::add
    $base.fug.fbtns.btns add \
        -image ::icon::edit-22 \
        -helptext [intlmsg "Modify"] \
        -command ::Usergroups::modify
    $base.fug.fbtns.btns add \
        -image ::icon::edittrash-22 \
        -helptext [intlmsg "Remove"] \
        -command ::Usergroups::remove

    pack $base.fug \
        -in $base \
        -fill both \
        -expand 1 \
        -side left
    pack $base.fug.ftree \
        -in $base.fug \
        -anchor n \
        -expand 1 \
        -fill both

    grid $base.fug.ftree.yscroll \
        -row 0 \
        -column 1 \
        -sticky swn
    grid $base.fug.ftree.xscroll \
        -row 1 \
        -column 0 \
        -sticky wen
    grid $base.fug.ftree.tree \
        -row 0 \
        -column 0 \
        -sticky news

    grid columnconfigure $base.fug.ftree 0 \
        -weight 10
    grid rowconfigure $base.fug.ftree 0 \
        -weight 10

    pack $base.fug.fbtns \
        -in $base.fug \
        -anchor n \
        -fill both
    pack $base.fug.fbtns.btns \
        -in $base.fug.fbtns \
        -anchor n \
        -fill both

    # PG permission changeable objects frame
    frame $base.fobj \
        -borderwidth 2 \
        -width 250
    frame $base.fobj.ftree
    set ::Usergroups::Win(oframe) $base.fobj.ftree
    set ::Usergroups::Win(otree) [Tree $base.fobj.ftree.tree \
        -deltay 22 \
        -yscrollcommand [list $::Usergroups::Win(oframe).yscroll set] \
        -xscrollcommand [list $::Usergroups::Win(oframe).xscroll set] \
        -background #fefefe]

    # only show perms for what can be changed in this version of PG
    set V [string range [::Database::getPgVersion] 0 2]
    if {$V >= 7.3} {
        $base.fobj.ftree.tree insert end root database \
            -image [image create photo -data $::Mainlib::_base64(si_sql)] \
            -text [intlmsg "Databases"]
    }
    if {$V >= 7.3} {
        $base.fobj.ftree.tree insert end root schema \
            -image ::icon::krayon-16 \
            -text [intlmsg "Schemas"]
    }
    $base.fobj.ftree.tree insert end root table \
        -image $::Mainlib::img(Tables) \
        -text [intlmsg "Tables"]
    $base.fobj.ftree.tree insert end root view \
        -image $::Mainlib::img(Views) \
        -text [intlmsg "Views"]
    $base.fobj.ftree.tree insert end root sequence \
        -image $::Mainlib::img(Sequences) \
        -text [intlmsg "Sequences"]
    if {$V >= 7.3} {
        $base.fobj.ftree.tree insert end root function \
            -image $::Mainlib::img(Functions) \
            -text [intlmsg "Functions"]
    }
    if {$V >= 7.3} {
        $base.fobj.ftree.tree insert end root language \
            -image ::icon::contents2-16 \
            -text [intlmsg "Languages"]
    }
    $::Usergroups::Win(otree) bindText \
        <ButtonPress-1> "::Usergroups::showObjectPerms 1"
    $::Usergroups::Win(otree) bindImage \
        <ButtonPress-1> "::Usergroups::showObjectPerms 1"
    $::Usergroups::Win(otree) bindText \
        <Double-ButtonPress-1> "::Usergroups::showObjectPerms 2"
    $::Usergroups::Win(otree) bindImage \
        <Double-ButtonPress-1> "::Usergroups::showObjectPerms 2"
    $::Usergroups::Win(otree) bindText \
        <Control-ButtonPress-1> "::Usergroups::showObjectPerms 3"
    $::Usergroups::Win(otree) bindImage \
        <Control-ButtonPress-1> "::Usergroups::showObjectPerms 3"
    $::Usergroups::Win(otree) bindText \
        <Shift-ButtonPress-1> "::Usergroups::showObjectPerms 4"
    $::Usergroups::Win(otree) bindImage \
        <Shift-ButtonPress-1> "::Usergroups::showObjectPerms 4"

    scrollbar $base.fobj.ftree.xscroll \
        -width 12 \
        -command [list $::Usergroups::Win(otree) xview] \
        -highlightthickness 0 \
        -orient horizontal \
        -background #DDDDDD \
        -takefocus 0
    scrollbar $base.fobj.ftree.yscroll \
        -width 12 \
        -command [list $::Usergroups::Win(otree) yview] \
        -highlightthickness 0 \
        -background #DDDDDD \
        -takefocus 0

    frame $base.fobj.fchex \
        -borderwidth 5
    checkbutton $base.fobj.fchex.cbpg \
        -borderwidth 1 \
        -anchor w \
        -text [intlmsg "View PostgreSQL system objects"] \
        -variable ::Usergroups::Objs(pg) \
        -command {::Usergroups::fillObjectTree 1}
    checkbutton $base.fobj.fchex.cbpga \
        -borderwidth 1 \
        -anchor w \
        -text [intlmsg "View PgAccess internal tables"] \
        -variable ::Usergroups::Objs(pga) \
        -command {::Usergroups::fillObjectTree 1}

    pack $base.fobj \
        -in $base \
        -fill both \
        -expand 1 \
        -side left
    pack $base.fobj.ftree \
        -in $base.fobj \
        -fill both \
        -anchor n \
        -expand 1

    grid $base.fobj.ftree.yscroll \
        -row 0 \
        -column 1 \
        -sticky swn
    grid $base.fobj.ftree.xscroll \
        -row 1 \
        -column 0 \
        -sticky wen
    grid $base.fobj.ftree.tree \
        -row 0 \
        -column 0 \
        -sticky news

    grid columnconfigure $base.fobj.ftree 0 \
        -weight 10
    grid rowconfigure $base.fobj.ftree 0 \
        -weight 10

    pack $base.fobj.fchex \
        -in $base.fobj \
        -anchor n \
        -fill both
    pack $base.fobj.fchex.cbpg \
        -in $base.fobj.fchex \
        -anchor n \
        -fill both
    pack $base.fobj.fchex.cbpga \
        -in $base.fobj.fchex \
        -anchor n \
        -fill both

    # permission checkbuttons
    frame $base.fperm \
        -borderwidth 2 \
        -width 90

    ButtonBox $base.fperm.bbox \
        -spacing 1 \
        -pady 10 \
        -orient vertical

    set labels [list]
    set abbrevs [list]
    lappend labels "ALL"
    lappend abbrevs "A"
    lappend labels "SELECT"
    lappend abbrevs "r"
    lappend labels "UPDATE"
    lappend abbrevs "w"
    lappend labels "INSERT"
    lappend abbrevs "a"
    lappend labels "DELETE"
    lappend abbrevs "d"
    lappend labels "RULE"
    lappend abbrevs "R"
    lappend labels "REFERENCES"
    lappend abbrevs "x"
    lappend labels "TRIGGER"
    lappend abbrevs "t"
    lappend labels "EXECUTE"
    lappend abbrevs "X"
    lappend labels "USAGE"
    lappend abbrevs "U"
    lappend labels "CREATE"
    lappend abbrevs "C"
    lappend labels "TEMPORARY"
    lappend abbrevs "T"

    set row 0
    foreach lbl $labels abbr $abbrevs {
        set ::Usergroups::Win(perms-$lbl) [$base.fperm.bbox add \
            -name $abbr \
            -foreground #fefefe \
            -background #000000 \
            -activebackground yellow \
            -disabledforeground #4ccd4ccd4ccd \
            -state disabled \
            -borderwidth 0 \
            -underline 0 \
            -text "$abbr - $lbl" \
            -command [subst {
                ::Usergroups::changePerms $lbl
            }]]
        set ::Usergroups::Perms($lbl) 0
        incr row
    }

    pack $base.fperm \
        -in $base \
        -expand 1 \
        -fill both
    pack $base.fperm.bbox \
        -in $base.fperm \
        -expand 1 \
        -fill both

}

proc vTclWindow.pgaw:UserEdit {base} {
    if {$base == ""} {
        set base .pgaw:UserEdit
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 263x240+233+165
    wm maxsize $base 1009 738
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Define new user"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    Label $base.lusername \
        -borderwidth 0 \
        -text [intlmsg "User name"]
    Entry $base.eusername \
        -background #fefefe \
        -borderwidth 1 \
        -textvariable PgAcVar(user,name) 
    bind $base.eusername <Key-Return> "focus .pgaw:UserEdit.epassword"
    bind $base.eusername <Key-KP_Enter> "focus .pgaw:UserEdit.epassword"

    Label $base.lpassword \
        -borderwidth 0 \
        -text [intlmsg "Password"]
    Entry $base.epassword \
        -background #fefefe \
        -borderwidth 1 \
        -show * \
        -textvariable PgAcVar(user,password)
    bind $base.epassword <Key-Return> "focus .pgaw:UserEdit.everifypassword"
    bind $base.epassword <Key-KP_Enter> "focus .pgaw:UserEdit.everifypassword"

    Label $base.lverifypassword \
        -borderwidth 0 \
        -text [intlmsg "Verify password"]
    Entry $base.everifypassword \
        -background #fefefe \
        -borderwidth 1 \
        -show * \
        -textvariable PgAcVar(user,verifypassword)
    bind $base.everifypassword <Key-Return> "focus .pgaw:UserEdit.cbcreatedb"
    bind $base.everifypassword <Key-KP_Enter> "focus .pgaw:UserEdit.cbcreatedb"

    checkbutton $base.cbcreatedb \
        -borderwidth 1 \
        -offvalue NOCREATEDB \
        -onvalue CREATEDB \
        -text [intlmsg "Allow user to create databases"] \
        -variable PgAcVar(user,createdb)
    checkbutton $base.cbcreateuser \
        -borderwidth 1 \
        -offvalue NOCREATEUSER \
        -onvalue CREATEUSER \
        -text [intlmsg "Allow user to create other users"] \
        -variable PgAcVar(user,createuser)

    Button $base.bvaliduntil \
        -text [intlmsg "Valid until (date)"] \
        -command "
            set PgAcVar(user,validuntil) \
                \[lindex \[Calendar $base.cal \
                    -parent $base \
                    -multipleselection 0\] 0\]
        "
    Entry $base.evaliduntil \
        -textvariable PgAcVar(user,validuntil)
    bind $base.evaliduntil <Key-Return> "focus .pgaw:UserEdit.bcreate"
    bind $base.evaliduntil <Key-KP_Enter> "focus .pgaw:UserEdit.bcreate"

    Button $base.bcreate \
        -command {Usergroups::saveUser} \
        -text [intlmsg "Create"]
    Button $base.bcancel \
        -command {Window destroy .pgaw:UserEdit} \
        -text [intlmsg "Cancel"]

    grid $base.lusername \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 0 \
        -column 0 \
        -sticky e
    grid $base.eusername \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 0 \
        -column 1 \
        -sticky ew
    grid $base.lpassword \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 1 \
        -column 0 \
        -sticky e
    grid $base.epassword \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 1 \
        -column 1 \
        -sticky ew
    grid $base.lverifypassword \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 2 \
        -column 0 \
        -sticky e
    grid $base.everifypassword \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 2 \
        -column 1 \
        -sticky ew
    grid $base.cbcreatedb \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 3 \
        -column 0 \
        -columnspan 2 \
        -sticky w
    grid $base.cbcreateuser \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 4 \
        -column 0 \
        -columnspan 2 \
        -sticky w
    grid $base.bvaliduntil \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 5 \
        -column 0 \
        -sticky e
    grid $base.evaliduntil \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 5 \
        -column 1 \
        -sticky ew
    grid $base.bcreate \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 6 \
        -column 0 \
        -sticky news
    grid $base.bcancel \
        -padx 3 \
        -pady 3 \
        -ipadx 3 \
        -ipady 3 \
        -row 6 \
        -column 1 \
        -sticky news

    grid columnconfigure $base 1 \
        -weight 10
    grid rowconfigure $base 6 \
        -weight 10

}

