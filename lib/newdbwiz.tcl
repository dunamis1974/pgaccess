#==========================================================
# NewDBWiz --
#
#    eases newbies through initial database creation
#==========================================================
#
namespace eval NewDBWiz {
    variable Win
    variable firsttime
    variable steps
    variable host
    variable pgport
    # might template1 be changed at PG compile time ???
    # if so, we need to change it here for PgAccess to know
    variable templatedb "template1"
    variable username
    variable password
    variable connstr ""
    variable newdbname
    variable newdbowner
    variable newdbautoconn
    variable newdblocation
    variable newdbencoding
    variable pgversion
}


#----------------------------------------------------------
# ::NewDBWiz::start --
#
#   displays, and, if necessary, creates the wizard
#
# Arguments:
#   none
#
# Returns:
#   nothing
#----------------------------------------------------------
#
proc ::NewDBWiz::start {} {

    variable Win
    variable firsttime
    variable steps

    # some initialization
    catch {unset firsttime}

    set Win(wiz) .pgaw:NewDatabaseWizard

    if {[winfo exists $Win(wiz)]} {
        destroy $Win(wiz)
    }

    # same layout as the import-export wizard
    # keep New as title since that was the menu option title
    tkwizard::tkwizard $Win(wiz) \
        -title [intlmsg "New"] \
        -geometry 500x400+100+80

    # determine next step based on user interaction
    bind $Win(wiz) <<WizNextStep>> {::NewDBWiz::nextStep}

    # set up the finish code
    bind $Win(wiz) <<WizFinish>> {::NewDBWiz::finish}

    # welcome step
    $Win(wiz) step {step_welcome} -layout advanced {
        lappend ::NewDBWiz::steps step_welcome
        set c [$this widget clientArea]
        $this stepconfigure \
            -title [intlmsg "Welcome to the New Database Wizard!"] \
            -subtitle [intlmsg "Beginner or Advanced"] \
            -pretext [intlmsg "This is a good place to start if you are new to PostgreSQL and PgAccess.  It can also be helpful if you just need to create a new database.  Please select your level:"]
        ::NewDBWiz::add_step_welcome $c
    }; # end step welcome

    # connections management step
    $Win(wiz) step {step_connections_management} -layout advanced {
        lappend ::NewDBWiz::steps step_connections_management
        set c [$this widget clientArea]
        $this stepconfigure \
            -title [intlmsg "Connections Management"] \
            -subtitle [intlmsg "Beginner"] \
            -pretext [intlmsg "This page will be about creating, modifying, and destroying PgAccess connections to multiple PostgreSQL clusters."]
        #::NewDBWiz::add_step_connections_management $c
    }; # end step connections management

    # create connection step
    $Win(wiz) step {step_create_connection} -layout advanced {
        lappend ::NewDBWiz::steps step_create_connection
        set c [$this widget clientArea]
        $this stepconfigure \
            -title [intlmsg "Create Connection"] \
            -subtitle [intlmsg "Advanced"] \
            -pretext [intlmsg "Choose parameters to connect with a PostgreSQL cluster.  The default 'template1' database will be used to make this connection, but it will not be modified in any way by the wizard.  The user specified must have superuser privileges to continue."] \
            -posttext {}
        ::NewDBWiz::add_step_create_connection $c
    }; # end step create connection

    # create database step
    $Win(wiz) step {step_create_database} -layout advanced {
        lappend ::NewDBWiz::steps step_create_connection
        set c [$this widget clientArea]
        $this stepconfigure \
            -title [intlmsg "Create Database"] \
            -subtitle [intlmsg "Advanced"] \
            -pretext [intlmsg "Now enter the name of the database to create and, optionally, the name of the owner if this database is for someone else.  This database connection will automatically come under PgAccess management, unless the -noauto command line option was specified at startup."] \
            -posttext {}
        ::NewDBWiz::add_step_create_database $c
    }; # end step create database

    $Win(wiz) show
    # disable the next button
    $Win(wiz) configure -nextstep {}

}; # end proc ::NewDBWiz::start


#----------------------------------------------------------
# ::NewDBWiz::nextStep --
#
#   fires when the Next button is clicked
#
# Arguments:
#   none
#
# Returns:
#   nothing
#----------------------------------------------------------
#
proc ::NewDBWiz::nextStep {} {

    variable Win
    variable firsttime
    variable host
    variable pgport
    variable templatedb
    variable username
    variable password
    variable connstr
    variable pgversion

    set currentStep [$Win(wiz) cget -step]

    if {$currentStep == "step_welcome"} {
        if {$firsttime} {
            $Win(wiz) configure -nextstep "step_connections_management"
        } else {
            $Win(wiz) configure -nextstep "step_create_connection"
        }
    }

    if {$currentStep == "step_create_connection"} {
        set connstr ""
        if {$host!=""} {
            append connstr " host=$host"
        }
        if {$pgport!=""} {
            append connstr " port=$pgport"
        }
        if {$templatedb!=""} {
            append connstr " dbname=$templatedb"
        }
        if {$username!=""} {
            append connstr " user=$username"
        }
        if {$password!=""} {
            append connstr " password=$password"
        }
        setCursor CLOCK
        set connres [catch {set dbconn [pg_connect -conninfo $connstr]} msg]
        setCursor NORMAL
        if {$connres} {
            showError $msg open_database
            $Win(wiz) configure -nextstep "step_create_connection"
            return 0
        }
        set pgversion [::Database::getPgVersion $dbconn]
        pg_disconnect $dbconn
    }

}; # end proc ::NewDBWiz::nextStep


#----------------------------------------------------------
# ::NewDBWiz::finish --
#
#   fires when the Finish button is clicked
#
# Arguments:
#   none
#
# Returns:
#   nothing
#----------------------------------------------------------
#
proc ::NewDBWiz::finish {} {

    variable connstr
    variable templatedb
    variable newdbname
    variable newdbowner
    variable newdbautoconn
    variable newdblocation
    variable newdbencoding
    variable host
    variable pgport
    variable username
    variable password
    variable pgversion

    set sql "
        CREATE DATABASE $newdbname
          WITH TEMPLATE=[::Database::quoteObject $templatedb]
               ENCODING=$newdbencoding
    "

    if {$newdblocation!="DEFAULT"} {
        append sql " LOCATION='$newdblocation'"
    }

    if {$pgversion>=7.3} {
        append sql " OWNER $newdbowner"
    }

    setCursor CLOCK
    set connres [catch {set dbconn [pg_connect -conninfo $connstr]} msg]
    set pgres [wpg_exec $dbconn $sql]
    pg_disconnect $dbconn
    setCursor NORMAL

    if {$newdbautoconn} {
        ::Connections::openNewConn $host $pgport $newdbname $username $password
    }

}; # end proc ::NewDBWiz::nextStep


#----------------------------------------------------------
# ::NewDBWiz::add_step_welcome --
#
#   creates the welcome (1st) step for the wizard
#
# Arguments:
#   base_   canvas to draw the step on
#
# Returns:
#   nothing
#----------------------------------------------------------
#
proc ::NewDBWiz::add_step_welcome {base_} {

    variable Win

    set base $base_.fwel
    set Win(step_welcome) $base_

    frame $base
    pack $base \
        -pady 20 \
        -fill both \
        -expand 1

    radiobutton $base.rfirst \
        -text [intlmsg "This is my first time."] \
        -variable ::NewDBWiz::firsttime \
        -value 1 \
        -command {
            $::NewDBWiz::Win(wiz) eval {
                $::NewDBWiz::Win(wiz) configure \
                    -nextstep [lindex $::NewDBWiz::steps end]
                $::NewDBWiz::Win(wiz) stepconfigure \
                    -posttext [intlmsg "Click Next to continue."]
            }
        }
    radiobutton $base.rsecond \
        -text [intlmsg "I know what I'm doing, just let me start working."] \
        -variable ::NewDBWiz::firsttime \
        -value 0 \
        -command {
            $::NewDBWiz::Win(wiz) eval {
                $::NewDBWiz::Win(wiz) configure \
                    -nextstep [lindex $::NewDBWiz::steps end]
                $::NewDBWiz::Win(wiz) stepconfigure \
                    -posttext [intlmsg "Click Next to continue."]
            }
        }

    pack $base.rfirst \
        -anchor nw
    pack $base.rsecond \
        -anchor nw

}; # end proc ::NewDBWiz::add_step_welcome


#----------------------------------------------------------
# ::NewDBWiz::add_step_create_connection --
#
#   set up params for connecting to PostgreSQL
#
# Arguments:
#   base_   canvas to draw the step on
#
# Returns:
#   nothing
#----------------------------------------------------------
#
proc ::NewDBWiz::add_step_create_connection {base_} {

    variable Win

    set base $base_.fcc
    set Win(step_create_connection) $base_

    frame $base
    pack $base \
        -pady 20 \
        -fill both \
        -expand 1

    set wijits [list]

    Label $base.lhost \
        -text [intlmsg "Host"]
    Entry $base.ehost \
        -text "localhost" \
        -textvariable ::NewDBWiz::host
    lappend wijits [list lhost ehost]

    Label $base.lpgport \
        -text [intlmsg "Port"]
    SpinBox $base.sbpgport \
        -text "5432" \
        -textvariable ::NewDBWiz::pgport \
        -range [list 0 65535 1]
    lappend wijits [list lpgport sbpgport]

    Label $base.lusername \
        -text [intlmsg "Username"]
    Entry $base.eusername \
        -text "" \
        -textvariable ::NewDBWiz::username
    lappend wijits [list lusername eusername]

    Label $base.lpassword \
        -text [intlmsg "Password"]
    Entry $base.epassword \
        -text "" \
        -textvariable ::NewDBWiz::password \
        -show *
    lappend wijits [list lpassword epassword]

    set row 0
    foreach w $wijits {
        set w0 [lindex $w 0]
        set w1 [lindex $w 1]
        grid $base.$w0 \
            -column 0 \
            -row $row \
            -sticky e
        grid $base.$w1 \
            -column 1 \
            -row $row \
            -sticky news
        incr row
    }

}; # end proc ::NewDBWiz::add_step_create_connection


#----------------------------------------------------------
# ::NewDBWiz::add_step_create_database --
#
#   create a database on the connection to template1
#
# Arguments:
#   base_   canvas to draw the step on
#
# Returns:
#   nothing
#----------------------------------------------------------
#
proc ::NewDBWiz::add_step_create_database {base_} {

    global PgAcVar

    variable Win
    variable connstr
    variable pgversion
    variable templatedb
    variable username
    variable newdbname

    set base $base_.fcd
    set Win(step_create_database) $base_

    frame $base
    pack $base \
        -pady 20 \
        -fill both \
        -expand 1

    set wijits [list]

    Label $base.lnewdb \
        -text [intlmsg "New Database Name"]
    set Win(cbofdbs) $base.cbnewdb
    ComboBox $base.cbnewdb \
        -text "" \
        -textvariable ::NewDBWiz::newdbname
    lappend wijits [list lnewdb cbnewdb]

    # maybe they already type the new name into the old dialog
    if {[info exists PgAcVar(New_Database_Name)]} {
        set newdbname $PgAcVar(New_Database_Name)
    }

    # well we cant assign an owner before 7.3
    if {$pgversion>=7.3} {
        Label $base.lowner \
            -text [intlmsg "Owner"]
        set Win(cbofowners) $base.cbowner
        ComboBox $base.cbowner \
            -text $username \
            -textvariable ::NewDBWiz::newdbowner
        lappend wijits [list lowner cbowner]
    }

    Label $base.ltemplatedb \
        -text [intlmsg "Template"]
    set Win(cbofdbs2) $base.cbtemplatedb
    ComboBox $base.cbtemplatedb \
        -text $templatedb \
        -textvariable ::NewDBWiz::templatedb
    lappend wijits [list ltemplatedb cbtemplatedb]

    Label $base.lloc \
        -text [intlmsg "Location"]
    Entry $base.eloc \
        -text "DEFAULT" \
        -textvariable ::NewDBWiz::newdblocation
    lappend wijits [list lloc eloc]

    Label $base.lenc \
        -text [intlmsg "Encoding"]
    set Win(cbenc) $base.cbenc
    ComboBox $base.cbenc \
        -text "DEFAULT" \
        -textvariable ::NewDBWiz::newdbencoding
    lappend wijits [list lenc cbenc]

    Label $base.lspace1 \
        -text ""
    Label $base.lspace2 \
        -text ""
    lappend wijits [list lspace1 lspace2]

    Label $base.lconn \
        -text ""
    checkbutton $base.cbconn \
        -text [intlmsg "Connect immediately after creation."] \
        -variable ::NewDBWiz::newdbautoconn
    lappend wijits [list lconn cbconn]

    set row 0
    foreach w $wijits {
        set w0 [lindex $w 0]
        set w1 [lindex $w 1]
        grid $base.$w0 \
            -column 0 \
            -row $row \
            -sticky e
        grid $base.$w1 \
            -column 1 \
            -row $row \
            -sticky news
        incr row
    }

    # fill in the list of databases and users on the cluster
    setCursor CLOCK
    set connres [catch {set dbconn [pg_connect -conninfo $connstr]} msg]
    $Win(cbofdbs) configure -values \
        [::Database::getDatabasesList $dbconn 1]
    $Win(cbofdbs2) configure -values \
        [::Database::getDatabasesList $dbconn 1]
    # well we cant assign an owner before 7.3
    if {$pgversion>=7.3} {
        $Win(cbofowners) configure -values \
            [::Database::getUsersList $dbconn]
    }
    pg_disconnect $dbconn
    setCursor NORMAL

}; # end proc ::NewDBWiz::add_step_create_database


