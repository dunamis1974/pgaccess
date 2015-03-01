#==========================================================
# calendar.tcl -- BWidget Calendar
#
#   a widget for playing with time
#   with an interface based on the iwidget calendar
#   written by Chris Maj cmaj_hat_freedomcorpse_hot_info
#   for the PgAccess project www.pgaccess.org
#==========================================================
# Index of commands:
#   Public commands
#       - Calendar::create
#   Private commands (internal helper procs)
#       - Calendar::_flip
#       - Calendar::_selectdate
#==========================================================
#
namespace eval Calendar {

    variable _dotw "sunday monday tuesday wednesday thursday friday saturday"
    variable _showdate
    variable _showmonth
    variable _showyear
    variable _showday
    variable _selectdates [list]
    variable _selectthickness
    variable _currentdatefont
    variable _datefont
    variable _dayfont
    variable _weekdaybackground
    variable _weekendbackground
    variable _startdayidx
    variable _background
    variable _titlefont
    variable _backwardimage
    variable _forwardimage
    variable _buttonforeground
    variable _multipleselection

    Dialog::use

    Widget::declare Calendar {
        {-title             String      "Calendar"  0}
        {-parent            String      ""          0}
        {-background        TkResource  ""          0 "label -background"}
        {-backwardimage     String      ""          0}
        {-buttonforeground  TkResource  ""          0 "label -foreground"}
        {-currentdatefont   TkResource  ""          0 "label -font"}
        {-datefont          TkResource  ""          0 "label -font"}
        {-dayfont           TkResource  ""          0 "label -font"}
        {-days              String      "Su Mo Tu We Th Fr Sa" 0}
        {-foreground        TkResource  ""          0 "label -foreground"}
        {-forwardimage      String      ""          0}
        {-height            Int         165         0 "%d >= 0"}
        {-multipleselection Int         1           0 "%d >= 0"}
        {-selectthickness   Int         3           0 "%d >= 0"}
        {-showdate          String      ""          0 "clock seconds"}
        {-startday          Enum        "sunday"    0 {sunday monday tuesday wednesday thursday friday saturday}}
        {-titlefont         TkResource  ""          0 "label -font"}
        {-weekdaybackground TkResource  ""          0 "label -background"}
        {-weekendbackground TkResource  ""          0 "label -background"}
        {-width             Int         200         0 "%d >= 0"}
    }

    proc ::Calendar { path args } {
        return [eval Calendar::create $path $args]
    }

}


#----------------------------------------------------------
# Calendar::create --
#
#   creates the calendar widget
#
# Arguments:
#   path    path to the calendar widget
#   args    args supplied to create the widget
#
# Results:
#   returns a sorted list of all selected dates
#----------------------------------------------------------
#
proc Calendar::create { path args } {

    variable _dotw
    variable _showdate
    variable _showmonth
    variable _showyear
    variable _showday
    variable _selectdates [list]
    variable _selectthickness
    variable _currentdatefont
    variable _datefont
    variable _dayfont
    variable _weekdaybackground
    variable _weekendbackground
    variable _startdayidx
    variable _background
    variable _titlefont
    variable _backwardimage
    variable _forwardimage
    variable _buttonforeground
    variable _multipleselection

    Widget::init Calendar "$path#Calendar" $args

    eval Dialog::create $path \
        -title [Widget::cget "$path#Calendar" -title] \
        -parent [Widget::cget "$path#Calendar" -parent]

    set fr [Dialog::getframe $path]
    $fr configure -width [Widget::cget "$path#Calendar" -width]
    $fr configure -height [Widget::cget "$path#Calendar" -height]
    $fr configure -background [Widget::cget "$path#Calendar" -background]
    $fr configure -relief flat

    # make it easier to know what month/year we are on
    set _showdate [Widget::cget "$path#Calendar" -showdate]
    set _showmonth [clock format [clock scan $_showdate] -format %B]
    set _showyear [clock format [clock scan $_showdate] -format %Y]
    set _showday [clock format [clock scan $_showdate] -format %d]

    set _selectthickness [Widget::cget "$path#Calendar" -selectthickness]
    set _currentdatefont [Widget::cget "$path#Calendar" -currentdatefont]
    set _datefont [Widget::cget "$path#Calendar" -datefont]
    set _dayfont [Widget::cget "$path#Calendar" -dayfont]
    set _weekdaybackground [Widget::cget "$path#Calendar" -weekdaybackground]
    set _weekendbackground [Widget::cget "$path#Calendar" -weekendbackground]
    set _background [Widget::cget "$path#Calendar" -background]
    set _titlefont [Widget::cget "$path#Calendar" -titlefont]
    set _backwardimage [Widget::cget "$path#Calendar" -backwardimage]
    set _forwardimage [Widget::cget "$path#Calendar" -forwardimage]
    set _buttonforeground [Widget::cget "$path#Calendar" -buttonforeground]
    set _multipleselection [Widget::cget "$path#Calendar" -multipleselection]

    # two buttons to move up/down a month
    Button $fr.leftbtn \
        -text "<" \
        -font $_titlefont \
        -command "Calendar::_flip $path -1"
    Button $fr.rightbtn \
        -text ">" \
        -font $_titlefont \
        -command "Calendar::_flip $path 1"
    if {[string length $_backwardimage] > 0} {
        $fr.leftbtn configure \
            -image $_backwardimage
    }
    if {[string length $_forwardimage] > 0} {
        $fr.rightbtn configure \
            -image $_forwardimage
    }

    set months [list]
    for {set i 1} {$i <= 12} {incr i} {
        set mo [clock format [clock scan "2003-$i-1"] -format %B]
        lappend months $mo
    }
    # lets us pick the month
    ComboBox $fr.monthcombo \
        -font $_titlefont \
        -text $_showmonth \
        -textvariable Calendar::_showmonth \
        -editable 1 \
        -width 16 \
        -values $months \
        -modifycmd "
            set flipday \"1-\$Calendar::_showmonth-\$Calendar::_showyear\"
            Calendar::_flip $path \$flipday
        "
    # lets us pick the year
    SpinBox $fr.yearspin \
        -font $_titlefont \
        -text $_showyear \
        -textvariable Calendar::_showyear \
        -editable 1 \
        -width 8 \
        -range [list 1492 2525 1] \
        -modifycmd "
            set flipday \"1-\$Calendar::_showmonth-\$Calendar::_showyear\"
            Calendar::_flip $path \$flipday
        "
    grid $fr.leftbtn \
        -row 0 \
        -column 0 \
        -padx 10 \
        -pady 10 \
        -sticky news
    grid $fr.monthcombo \
        -row 0 \
        -column 1 \
        -padx 10 \
        -pady 10 \
        -columnspan 3
    grid $fr.yearspin \
        -row 0 \
        -column 4 \
        -padx 10 \
        -pady 10 \
        -columnspan 2
    grid $fr.rightbtn \
        -row 0 \
        -column 6 \
        -padx 10 \
        -pady 10 \
        -sticky news

    # list the days of the week in the format/order supplied
    set startday [Widget::cget "$path#Calendar" -startday]
    set _startdayidx [lsearch $_dotw $startday]
    set days [split [Widget::cget "$path#Calendar" -days]]
    for {set i $_startdayidx} {$i < [expr {$_startdayidx + 7}]} {incr i} {
        set day [lindex $days [expr {$i % 7}]]
        set someday "_"
        append someday $day "_1-" $i
        Label $fr.$someday \
            -font $_dayfont \
            -text $day
        grid $fr.$someday \
            -row 1 \
            -column [expr {$i - $_startdayidx}] \
            -sticky s
    }

    # draw all the buttons we will use for days of the month
    for {set j 2} {$j < 8} {incr j} {
        for {set i 0} {$i < 7} {incr i} {
            set btn "_"
            append btn $i "x" $j
            Button $fr.$btn \
                -relief flat \
                -borderwidth $_selectthickness \
                -foreground $_buttonforeground
            grid $fr.$btn \
                -row $j \
                -column $i \
                -sticky news
        }
    }

    # space the columns evenly
    # modified from comp.lang.tcl posting by Donald Arseneau
    grid columnconfigure $fr {0 1 2 3 4 5 6} -weight 1 -uniform $fr

    Calendar::_flip $path $_showdate
    set res [Dialog::draw $path]
    set res [lsort -dictionary $_selectdates]
    destroy $path
    return $res

}; # end proc Calendar::create


#----------------------------------------------------------
# Calendar::_flip --
#
#   handles display of new month/year; places days of the
#   month in the proper places
#
# Arguments:
#   path        path of the calendar
#   flipday_    what date we are flipping to
#               OR if 1, go forward a month
#                 if -1, go back a month
#
# Results:
#   none returned
#
# Modifies:
#   current days of the month to reflect the newly selected
#   date
#----------------------------------------------------------
#
proc Calendar::_flip { path flipday_ } {

    variable _showmonth
    variable _showyear
    variable _currentdatefont
    variable _datefont
    variable _startdayidx
    variable _weekendbackground
    variable _weekdaybackground
    variable _background
    variable _dotw

    set fr [Dialog::getframe $path]

    if {$flipday_ == -1} {
        set flipday_ "1-$_showmonth-$_showyear"
        set flipday_ [clock format [clock scan "last month" \
            -base [clock scan $flipday_]] -format "%D"]
    }

    if {$flipday_ == 1} {
        set flipday_ "1-$_showmonth-$_showyear"
        set flipday_ [clock format [clock scan "next month" \
            -base [clock scan $flipday_]] -format "%D"]
    }

    # crunching on some dates to make placement easier below
    set firstday [clock format [clock scan $flipday_] -format "%m/1/%y"]
    set firstdayow [expr {([clock format [clock scan $firstday] -format "%w"]-$_startdayidx) % 7}]
    set lastday [clock format [clock scan "yesterday" -base [clock scan [clock format [clock scan "next month" -base [clock scan $firstday]] -format "%m/1/%y"]]] -format "%D"]
    set lastdayom [clock format [clock scan $lastday] -format "%e"]
    set _showmonth [clock format [clock scan $firstday] -format "%B"]
    set _showyear [clock format [clock scan $firstday] -format "%Y"]
    set placeday 0
    set todayis [clock format [clock seconds] -format "%e-%B-%Y"]

    for {set j 2} {$j < 8} {incr j} {
        for {set i 0} {$i < 7} {incr i} {
            set btn "_"
            append btn $i "x" $j
            if {!$placeday && $firstdayow == $i} {
                set placeday 1
            }
            if {$placeday && $placeday <= $lastdayom} {
                set curday "$placeday-$_showmonth-$_showyear"
                # if this is today, use the right font
                if {[string trim $curday] == [string trim $todayis]} {
                    $fr.$btn configure \
                        -font $_currentdatefont
                } else {
                    $fr.$btn configure \
                        -font $_datefont
                }
                # different backgrounds for weekdays and weekends
                if {[lindex $_dotw [expr {($_startdayidx + $i) % 7}]] \
                    == "saturday"
                 || [lindex $_dotw [expr {($_startdayidx + $i) % 7}]] \
                    == "sunday"} {
                    $fr.$btn configure \
                        -background $_weekendbackground
                } else {
                    $fr.$btn configure \
                        -background $_weekdaybackground
                }
                $fr.$btn configure \
                    -text $placeday \
                    -command "Calendar::_selectdate $fr.$btn $curday 0"
                # check to see if the date we just drew was
                # previously selected, maybe they went back
                # and forth a month or two a couple of times
                Calendar::_selectdate $fr.$btn $curday 1
                incr placeday
            } elseif {!$placeday} {
                # click on day from previous month goes there
                $fr.$btn configure \
                    -text "" \
                    -relief flat \
                    -background $_background \
                    -command "Calendar::_flip $path -1"
            } else {
                # click on day from next month goes there
                $fr.$btn configure \
                    -text "" \
                    -relief flat \
                    -background $_background \
                    -command "Calendar::_flip $path 1"
            }
        }
    }

}; # end proc Calendar::_flip


#----------------------------------------------------------
# Calendar::_selectdate --
#
#   handles selection and display of dates, by both
#   adding/deleting them from the list of selectdates and/or
#   updating the visual display
#
# Arguments:
#   btnpath     path of the calendar widget button
#   clkd_       what date was selected
#   refresh_    whether to add/delete or just update the
#               display, 1 if just updating the display
#
# Results:
#   none returned
#
# Modifies:
#   the highlight of selected dates for the current month,
#   and the _selectdates list if not refreshing them
#----------------------------------------------------------
#
proc Calendar::_selectdate { btnpath clkd_ refresh_ } {

    variable _selectdates
    variable _multipleselection

    # this format is good for sorting
    set clkd_ [clock format [clock scan $clkd_] -format "%Y-%m-%d"]

    set clkpos [lsearch $_selectdates $clkd_]
    if {$clkpos == -1} {
        if {!$refresh_} {
            if {$_multipleselection} {
                # just keep adding dates
                $btnpath configure \
                    -relief sunken
                lappend _selectdates $clkd_
            } else {
                # ooh make sure that we only have one date
                # selected at a time so turn off the others
                set _selectdates [list]
                lappend _selectdates $clkd_
                # this makes things a little sluggish
                # another list (or an array) to hold the
                # button paths we need to change would speed
                # it up, but it works so wtf
                Calendar::_flip [winfo toplevel $btnpath] $clkd_
            }
        } else {
            # just a refresh, no biggie, we weren't selected
            $btnpath configure \
                -relief flat
        }
    } else {
        if {!$refresh_} {
            # we deselected a date
            $btnpath configure \
                -relief flat
            set _selectdates [lreplace $_selectdates $clkpos $clkpos]
        } else {
            # refreshing a previously selected date
            $btnpath configure \
                -relief sunken
        }
    }

}; # end proc Calendar::_selectdate

