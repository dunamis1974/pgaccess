# Copyright (c) 2001, Bryan Oakley
# All Rights Reservered
#
# Bryan Oakley
# oakley@bardo.clearlight.com
#
# tkwizard 1.0a1
#
# this code is freely distributable without restriction, and is 
# provided as-is with no warranty expressed or implied. 
#

package require Tk 8.0
package provide tkwizard 1.0

# create the package namespace, and do some basic initialization
namespace eval tkwizard {

    namespace export tkwizard
    
    set ns [namespace current]

    # define class bindings
    bind Wizard <<WizHelp>>     [list ${ns}::handleEvent %W <<WizHelp>>]
    bind Wizard <<WizNextStep>> [list ${ns}::handleEvent %W <<WizNextStep>>]
    bind Wizard <<WizPrevStep>> [list ${ns}::handleEvent %W <<WizPrevStep>>]
    bind Wizard <<WizCancel>>   [list ${ns}::handleEvent %W <<WizCancel>>]
    bind Wizard <<WizFinish>>   [list ${ns}::handleEvent %W <<WizFinish>>]

    # create a default image
    image create photo [namespace current]::feather -data {
       R0lGODlhIAAgALMAANnZ2QAAwAAA/wBAwAAAAICAgAAAgGBggKCgpMDAwP//
       /////////////////////yH5BAEAAAAALAAAAAAgACAAAAT/EMhJq60hhHDv
       pVCQYohAIJBzFgpKoSAEAYcUIRAI5JSFlkJBCGLAMYYIIRAI5ASFFiqDgENK
       EUIwBAI5ywRlyhAEHFKKEEIgEMgJyiwUBAGHnCKEEAyBQM4yy5RhCDikFDBI
       SSCQExRKwxBDjAGHgEFKQyCQk9YgxBBjDAGDnAQCOWkNQgwxxDgwyGkIBHJS
       GoQQYohRYJDTEAjkpDWIIYQQBQY5A4FATlqDEEIMgWCQMxgCgZy0BiikRDDI
       GQyBQE5aAxRSIhjkNIRAICetAQop04BBTgOBnLTKIIQQacAgZzAQyEkrCEII
       kQYMckoDgZy0giCESAMGOaWBQMoydeeUQYhUYJBTGgikLHNOGYRACQY5pYFA
       yjLnnEGgNGCQMxgAACgFAjnpFEUNGOQ0BgI5Z6FUFlVgkJNAICctlMqiyggB
       BkMIBHLOUiidSUEiJwRyzlIopbJQSilFURJUIJCTVntlKhhjCwsEctJqr0wF
       Y0xhBAA7
    }

    # Make a class binding to do some housekeeping
    bind Wizard <Destroy> [list ${ns}::wizard-destroy %W]
}

# usage: tkwizard ?-showhelp boolean? ?-title string? ?-geometry string?
proc tkwizard::tkwizard {name args} {

    set showHelp 0
    set body {}

    set i 0
    while {$i < [llength $args]} {
        set arg [lindex $args $i]
        switch -glob -- $arg {
            -showhelp {
                incr i
                set showHelp [lindex $args $i]
            }
            -title {
                incr i
                set title [lindex $args $i]
            }
            -geometry {
                incr i
                set geometry [lindex $args $i]
            }
            default {
                return -code error "unknown option \"$arg\" (!)"
            }
        }
        incr i
    }

    if {![info exists title]} {set title $name}

    if {![info exists geometry]} {set geometry "400x400+100+100"}

    init $name $showHelp $title $geometry

    return $name
}

##
# wizard-destroy
#
# does cleanup of the wizard when it is destroyed. Specifically,
# it destroys the associated namespace
# 
proc tkwizard::wizard-destroy {name} {

    upvar #0 [namespace current]::@$name-state wizState

    if {![info exists wizState]} {
        return -code error "unknown wizard \"$name\""
    }
    set w $wizState(window)
    interp alias {} $wizState(alias) {}
    catch {namespace delete $wizState(namespace)} message

    return ""
}


# intended for an end user to draw a step for the purpose
# of measuring it's size. Not fully realized yet; it seems to 
# put the wizard in a slightly weird state
proc tkwizard::wizProx-drawstep {name stepname} {

    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig
    upvar #0 [namespace current]::@$name-stepData wizStepData

    # First, build the appropriate layout...
    set layout $wizStepData($stepname,layout)
    buildLayout $name $layout

    # then build the step...
    set wizConfig(-step) $stepname
    buildStep $name $stepname
}

##
# 
proc tkwizard::wizProc-cget {name args} {
    upvar #0 [namespace current]::@$name-config wizConfig

    if {[llength $args] != 1} {
        return -code error "wrong \# args: should be \"$name cget option\""
    }
    set option [lindex $args 0]
    if {[info exists wizConfig($option)]} {
        return $wizConfig($option)
    } 
    return -code error "unknown option \"$option\""
}

proc tkwizard::wizProc-configure {name args} {
    upvar #0 [namespace current]::@$name-config wizConfig

    if {[llength $args] == 0} {
        set result [list]
        foreach item [lsort [array names wizConfig]] {
            lappend result $item $wizConfig($item)
        }
        return $result

    } elseif {[llength $args] == 1} {
        uplevel $name cget [lindex $args 0]

    } else {
        foreach {option value} $args {
            if {![info exists wizConfig($option)]} {
                return -code error "unknown option \"$option\""
            }
            set wizConfig($option) $value
            switch -exact -- $option {
                -background {
                    $wizConfig(toplevel) configure -background $value
                    # in theory we should step through all widgets,
                    # changing their color as well. Maybe I generate
                    # a virtual event like <<WizConfigure>> so the
                    # programmer can reconfigure their steps appropriately
                }
                -title {
                    wm title $w $value
                }
            }
        }
    }
}

##
# wizProc
#
# this is the procedure that represents the wizard object; each
# wizard will be aliased to this proc; the wizard name will be
# provided as the first argument (this is transparent to the caller)

proc tkwizard::wizProc {name command args} {
    # define the state variable here; that way the worker procs
    # can do an uplevel to access the variable with a simple name
    variable @$name-state

    # call the worker proc
    eval wizProc-$command $name $args
}

##
# wizProc-hide
#
# usage: wizHandle hide
#
# hides the wizard without destroying it. Note that state is NOT
# guaranteed to be preserved, since a subsequent "show" will reset
# the state. 

proc tkwizard::wizProc-hide {name args} {
    upvar #0 [namespace current]::@$name-state wizState

    wm withdraw $wizState(window)
}

##
# wizProc-order
#
# usage: wizHandle order ?-nocomplain? ?step step ...?
#
# example: wizHandle order step1 step2 step3 finalStep
#
# unless -nocomplain is specified, will throw an error if
# a nonexistent step is given, or if a duplicate step is
# given.
#
# without any steps, will return the current order

proc tkwizard::wizProc-order {name args} {
    upvar #0 [namespace current]::@$name-state wizState

    set i [lsearch -exact $args "-nocomplain"]
    set complain 1

    if {$i >= 0} {
        set complain 0
        set args [lreplace $args $i $i]
    }

    if {$complain} {
        # make sure all of the steps are defined.  "defined" means
        # there is a initialize proc for that step. We also need to
        # make sure we don't have the same step represented twice.
        # This is inefficient, but speed isn't particularly critical
        # here
        array set found [list]
        foreach step $args {
            set tmp [info commands $wizState(namespace)::initialize-$step]
            if {[llength $tmp] != 1} {
                return -code error "unknown step \"$step\""
            }
            if {[info exists found($step)]} {
                return -code error "duplicate step \"$step\""
            }
            set found($step) 1
        }
    }

    if {[llength $args] == 0} {
        return $wizState(steps)
    } else {
        set wizState(steps) $args
    }
}

##
# wizProc-step
#
# implements the "step" method of the wizard object. The body
# argument is code that will be run when the step identified by
# 'stepName' is to be displayed in the wizard
#
# usage: wizHandle step stepName ?-layout layout? body
#

proc tkwizard::wizProc-step {name stepName args} {

    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-stepData wizStepData

    set body [lindex $args end]
    set args [lreplace $args end end]
#    set args [lrange $args 0 end-1]

    set layout "basic"
    set i [lsearch -exact $args {-layout}]
    if {$i >= 0} {
        set j [expr {$i + 1}]
        set layout [lindex $args $j]
        if {[llength [info commands [namespace current]::buildLayout-$layout]] == 0} {
            return -code error "unknown layout \"$layout\""
        }
        set args [lreplace $args $i $j]
    }
    set wizStepData($stepName,layout) $layout

    lappend wizState(steps) $stepName

    set procname "[namespace current]::${name}::initialize-$stepName"
    proc $procname {} "[list set this $name];\n$body"
}

##
# wizProc-widget
#
# Returns the path to an internal widget, or executes the
# an internal widget command
#
# usage: wizHandle widget widgetName ?args?
#
# if [llength $args] > 0 it will run the widget command with
# the args. Otherwise it will return the widget path

proc tkwizard::wizProc-widget {name args} {
    upvar #0 [namespace current]::@$name-state wizState

    if {[llength $args] == 0} {
        # return a list of all widget names
        set result [list]
        foreach item [array names wizState widget,*] {
            regsub {widget,} $item {} item
            lappend result $item
        }
        return $result
    }

    set widgetname [lindex $args 0]
    set args [lrange $args 1 end]

    if {![info exists wizState(widget,$widgetname)]} {
        return -code error "unknown widget: \"$widgetname\""
    }

    if {[llength $args] == 0} {
        return $wizState(widget,$widgetname)
    }

    # execute the widget command
    eval [list $wizState(widget,$widgetname)] $args
}

##
# wizProc-info
#
# Returns the information in the state array
# 
# usage: wizHandle info

proc tkwizard::wizProc-info {name args} {

    if {[llength $args] > 0} {
        return -code error "wrong \# args: should be \"$name info\""
    } 
    upvar #0 [namespace current]::@$name-state wizState

    foreach item [lsort [array names wizState]] {
        puts "$item = $wizState($item)"
    }
}

# return the namespace of the wizard
proc tkwizard::wizProc-namespace {name} {
    set ns [namespace current]::${name}
    return $ns
}

# execute the code in the namespace of the wizard
proc tkwizard::wizProc-eval {name code} {
    set ns [namespace current]::${name}
    namespace eval $ns $code
}
    
##
# wizProc-show
# 
# Causes the wizard to be displayed in it's initial state
#
# usage: wizHandle show
#
# This is where all of the widgets are created, though eventually
# I'll probably move the widget drawing to a utility proc...

proc tkwizard::wizProc-show {name args} {

    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig

    # initialize the remainder of the wizard state
    set wizState(history)         [list]
    set wizConfig(-previousstep)  ""
    set wizConfig(-nextstep)      ""

    set steps $wizState(steps)
    if {[llength $steps] == 0} {
        # no steps? Just show it as-is.
        wm deiconify $name
        return
    }

    # set a trace on where we store the next state. The trace
    # will cause the next and previous buttons to become
    # enabled or disabled. Thus, within a step a programmer can
    # decide when to enable or disable the buttons by merely 
    # setting these variables.
    set code [namespace code "varTrace [list $name]"]
    set stateVar "[namespace current]::@$name-config"
    foreach item {-previousstep -nextstep -state -complete} {
        trace vdelete  ${stateVar}($item) wu $code
        trace variable ${stateVar}($item) wu $code
    }

    # show the first step
    set wizState(history) [lindex $steps 0]
    showStep $name 

    # make it so, Number One
    update idletasks
    wm deiconify $wizState(window)

    # This makes sure closing the window with the window manager control
    # Does The Right Thing (now if only I could figure out what the
    # Right Thing is...)
    wm protocol $name WM_DELETE_WINDOW \
        [namespace code [list wizProc-hide $name hide]]
#    wm protocol $w WM_DELETE_WINDOW \
#        [list $wizState(widget,cancelButton) invoke]

    return ""
}

# This gets called whenever certain parts of our state variable
# get set or unset (presently this only happens with -nextstep 
# and -previousstep)
proc tkwizard::varTrace {name varname index op} {
    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig

    catch {
        switch -- $index {
            -state {
                set state $wizConfig(-state)
                if {[string equal $state "normal"]} {
#                    $name configure -cursor {}
                    if {[string length $wizConfig(-previousstep)] == 0} {
                        $wizState(widget,backButton) configure -state disabled
                    } else {
                        $wizState(widget,backButton) configure -state normal
                    }
                    if {[string length $wizConfig(-nextstep)] == 0} {
                        $wizState(widget,nextButton) configure -state disabled
                    } else {
                        $wizState(widget,nextButton) configure -state normal
                    }
                    if {$wizConfig(-complete)} {
                        $wizState(widget,finishButton) configure -state normal
                    } else {
                        $wizState(widget,finishButton) configure -state disabled
                    }

                } else {
 #                    $name configure -cursor watch
                    $wizState(widget,cancelButton) configure -cursor left_ptr
                    $wizState(widget,nextButton)   configure -state disabled
                    $wizState(widget,backButton)   configure -state disabled
                    $wizState(widget,helpButton)   configure -state disabled
                    $wizState(widget,finishButton) configure -state disabled
                }
            }
            -complete {
                if {$wizConfig(-complete)} {
                    $wizState(widget,finishButton) configure -state normal
                } else {
                    $wizState(widget,finishButton) configure -state disabled
                }
            }

            -previousstep {
                set state normal
                if {[string length $wizConfig(-previousstep)] == 0} {
                    set state disabled
                }
                $wizState(widget,backButton) configure -state $state
            }
            -nextstep {
                set state normal
                if {[string length $wizConfig(-nextstep)] == 0} {
                    set state disabled
                }
                $wizState(widget,nextButton) configure -state $state
            }

            default {
                puts "bogus variable trace: name=$varname index=$index op=$op"
            }
        }
    }
}

# Causes a step to be built by clearing out the current contents of
# the client window and then executing the initialization code for
# the given step

proc tkwizard::buildStep {name step}  {
    upvar #0 [namespace current]::@$name-state wizState

    # reset the state of the windows in the wizard
    eval destroy [winfo children $wizState(widget,clientArea)]
#    wizProc-stepconfigure $name -title "" -subtitle "" -pretext "" -posttext ""

    namespace eval $wizState(namespace) initialize-$step 

}


# This block of code is common to all wizard actions. 
# (ie: it is the target of the -command option for wizard buttons)
proc tkwizard::cmd {command name} {

    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig

    switch $command {
        Help       {event generate $name <<WizHelp>>}
        Next       {event generate $name <<WizNextStep>>}
        Previous   {event generate $name <<WizPrevStep>>}
        Finish     {event generate $name <<WizFinish>>}
        Cancel     {event generate $name <<WizCancel>>}

        default {
            puts "'$command' not implemented yet"
        }
    }
}

proc tkwizard::handleEvent {name event} {

    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig
    upvar #0 [namespace current]::@$name-stepData wizStepData

    switch $event {
        <<WizHelp>> {
            # not implemented yet
        }

        <<WizNextStep>> {
            set thisStep [lindex $wizState(history) end]
            lappend wizState(history) $wizConfig(-nextstep)
            showStep $name 
        }

        <<WizPrevStep>> {

            # pop an item off of the history
            set p [expr {[llength $wizState(history)] -2}]
            set wizState(history) [lrange $wizState(history) 0 $p]
            showStep $name 
        }

        <<WizFinish>> {

            set thisStep [lindex $wizState(history) end]
            wizProc-hide $name
        }

        <<WizCancel>> {

            wizProc-hide $name
        }

        default {
            puts "'$event' not implemented yet"
        }
    }
}

proc tkwizard::showStep {name} {

    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig
    upvar #0 [namespace current]::@$name-stepData wizStepData

    # the step is whatever is at the tail end of our 
    # history
    set step [lindex $wizState(history) end]
    set proc "initialize-$step"
    set wizConfig(-step) $step

    set layout $wizStepData($step,layout)

    # First, build the appropriate layout...
    buildLayout $name $layout

    # then build the step...
    set steps $wizState(steps)
    set lastStep [expr {[llength $steps] -1}]
    set stepIndex [lsearch $steps $step]
    set prevIndex [expr {$stepIndex -1}]
    set nextIndex [expr {$stepIndex + 1}]

    # initialize the next, previous and current step configuration
    # options; this will set the state of the next/previous buttons.
    # note that the user can retrieve these values with the normal
    # 'cget' and 'configure' methods
    set p [expr {[llength $wizState(history)] -2}]
    set wizConfig(-previousstep) [lindex $wizState(history) $p]
    set wizConfig(-nextstep) [lindex $steps $nextIndex]

    if {$stepIndex == ([llength $steps]-1)} {
        set wizConfig(-complete) 1
    } else {
        set wizConfig(-complete) 0
    }

    buildStep $name $step

}


proc tkwizard::init {name showHelp title geometry} {

    # name should be a widget path
    set w $name

    # create variables in this namespace to keep track
    # of the state of this wizard. We do this here to 
    # avoid polluting the namespace of the widget. We'll
    # create local aliases for the variables to make the
    # code easier to read and write

    # this variable contains state information about the 
    # wizard, such as the wizard title, the name of the 
    # window and namespace associated with the wizard, the
    # list of steps, and so on.
    variable "@$name-state"
    upvar \#0 [namespace current]::@$name-state wizState

    # this variable contains all of the parameters associated
    # with the wizard and settable with the "configure" method
    variable "@name-config"
    upvar \#0 [namespace current]::@$name-config wizConfig

    # this is an experimental array containing data of known
    # step types. Presently not being used.
    variable "@name-stepTypes"
    upvar \#0 [namespace current]::@$name-stepTypes wizStepTypes

    # this contains step-specific data, such as the step title
    # and subtitle, icon, etc. All elements are unset prior to
    # rendering a given step. It is each step's responsibility
    # to set it appropriately, and it is each step type's 
    # responsibility to use the data.
    variable "@name-stepData"
    upvar \#0 [namespace current]::@$name-stepData  wizStepData

    # do some state initialization; more will come later when
    # the wizard is actually built
    set wizConfig(-complete)      0
    set wizConfig(-state)         normal
    set wizConfig(-title)         $title
    set wizConfig(-geometry)      $geometry
    set wizConfig(-nextstep)      ""
    set wizConfig(-previousstep)  ""
    set wizConfig(-step)          ""
    set wizConfig(-showhelp)      $showHelp

    set wizState(title)        $title
    set wizState(geometry)     $geometry
    set wizState(window)       $w
    set wizState(steps)        [list]
    set wizState(namespace)    [namespace current]::$name
    set wizState(name)         $name
    set wizState(toplevel)     {}

    # create the wizard (except for the step pages...)
    buildDialog $name

    # this establishes a namespace for this wizard; this namespace
    # will contain wizard-specific data managed by the creator of
    # the wizard
    namespace eval $name {}

    # this creates the instance command by first renaming the widget
    # command associated with our toplevel, then making an alias 
    # to our own command
    set wizState(toplevel) $wizState(namespace)::originalWidgetCommand
    rename $w $wizState(toplevel)
    interp alias {} ::$w {} [namespace current]::wizProc $name
    set wizState(alias) ::$w

    # set some useful configuration values
    set wizConfig(-background) \
        [$wizState(namespace)::originalWidgetCommand cget -background]
}

proc tkwizard::buildDialog {name} {
    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig

    set prefix [string trimright $wizState(window) .]

    set wizState(widget,topframe)     $prefix.topframe
    set wizState(widget,sep1)         $prefix.sep1
    set wizState(widget,sep2)         $prefix.sep2
    set wizState(widget,buttonFrame)  $prefix.buttonFrame
    set wizState(widget,helpButton)   $prefix.buttonFrame.helpButton
    set wizState(widget,nextButton)   $prefix.buttonFrame.nextButton
    set wizState(widget,backButton)   $prefix.buttonFrame.backButton
    set wizState(widget,cancelButton) $prefix.buttonFrame.cancelButton
    set wizState(widget,finishButton) $prefix.buttonFrame.finishButton
    set wizState(widget,layoutFrame)  $prefix.layoutFrame

    # create the toplevel window
    set w $wizState(window)
    toplevel $w -class Wizard -bd 2 -relief groove
    wm title $w $wizConfig(-title)
    wm geometry $w $wizConfig(-geometry)
    wm withdraw $w

    # the dialog is composed of two areas: the row of buttons and the
    # area with the dynamic content. To make it look the way we want it to
    # we'll use another frame for a visual separator
    frame $wizState(widget,buttonFrame) -bd 0 
    frame $wizState(widget,layoutFrame) -bd 0
    frame $wizState(widget,sep1) -class WizSeparator -height 2 -bd 2 -relief groove

    pack $wizState(widget,buttonFrame) -side bottom -fill x
    pack $wizState(widget,sep1)  -side bottom -fill x
    pack $wizState(widget,layoutFrame) -side top -fill both -expand y

    # make all of the buttons
    button $wizState(widget,helpButton) \
        -text "What's This?" \
        -default normal \
        -bd 1 \
        -relief raised \
        -command [namespace code "cmd Help [list $name]"]

    button $wizState(widget,backButton) \
        -text "< Back" \
        -default normal \
        -width 8 \
        -bd 1 \
        -relief raised \
        -command [namespace code "cmd Previous [list $name]"]

    button $wizState(widget,nextButton) \
        -text "Next >" \
        -default normal \
        -width 8 \
        -bd 1 \
        -relief raised \
        -command [namespace code "cmd Next [list $name]"]

    button $wizState(widget,finishButton) \
        -text "Finish" \
        -default normal \
        -width 8 \
        -bd 1 \
        -relief raised \
        -command [namespace code "cmd Finish [list $name]"]

    button $wizState(widget,cancelButton) \
        -text Cancel   \
        -default normal \
        -width 8 \
        -bd 1  \
        -relief raised \
        -command [namespace code "cmd Cancel [list $name]"]

    # pack the buttons
    if {$wizConfig(-showhelp)} {
        pack $wizState(widget,helpButton) -side left -padx 4 -pady 8
    }
    pack $wizState(widget,cancelButton) -side right -padx 4 -pady 8
    pack $wizState(widget,finishButton) -side right -pady 8 -padx 4
    pack $wizState(widget,nextButton) -side right -pady 8
    pack $wizState(widget,backButton) -side right -pady 8

    # return the name of the toplevel, for lack of a better idea...
    return $wizState(window)
}

proc tkwizard::buildLayout {name layoutName} {
    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig

    set w $wizState(window)
    set lf $wizState(widget,layoutFrame)

    # initialize the layout variables
    initLayout-$layoutName $name

    # if the layout hasn't actually been built yet, build it
    # nope, destory the layout then rebuild it every time
    if {[winfo exists $lf.$layoutName]} {
        eval destroy $lf.$layoutName
    }
    buildLayout-$layoutName $name

    eval pack forget [winfo children $lf]
    pack $lf.$layoutName -side top -fill both -expand y

}

# this is a user-callable interface to configureLayout-<layout>
proc tkwizard::wizProc-stepconfigure {name args} {
    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig
    upvar #0 [namespace current]::@$name-stepData wizStepData

    set step $wizConfig(-step)
    set layout $wizStepData($step,layout)
    eval configureLayout-$layout $name $args
}


# this defines the widget paths. Will be called each time we
# switch layouts
proc tkwizard::initLayout-basic {name} {
    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig

    set layout $wizState(widget,layoutFrame).basic

    set wizState(widget,clientAreaWin)   $layout.clientAreaWin
    # set wizState(widget,clientArea)   $layout.clientArea
    set wizState(widget,icon)         $layout.icon
    set wizState(widget,title)        $layout.title
    set wizState(widget,subtitle)     $layout.subtitle
    set wizState(widget,pretext)      $layout.pretext
    set wizState(widget,posttext)     $layout.posttext
}

proc tkwizard::buildLayout-basic {name} {
    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig

    set layout $wizState(widget,layoutFrame).basic
    frame $layout -class WizLayoutBasic

    # using the option database saves me from hard-coding it for
    # every widget. I guess I'm just lazy.
    option add *WizLayoutBasic*Label.justify             left interactive
    option add *WizLayoutBasic*Label.anchor              nw   interactive
    option add *WizLayoutBasic*Label.highlightThickness  0    interactive
    option add *WizLayoutBasic*Label.borderWidth         0    interactive
    option add *WizLayoutBasic*Label.padX                5    interactive

    # Client area. This is where the caller places its widgets.
    # frame $wizState(widget,clientArea) -bd 8 -relief flat
    ScrolledWindow $wizState(widget,clientAreaWin) \
        -auto both \
        -scrollbar both
    ScrollableFrame $wizState(widget,clientAreaWin).sf
    $wizState(widget,clientAreaWin) setwidget $wizState(widget,clientAreaWin).sf
    set wizState(widget,clientArea) [$wizState(widget,clientAreaWin).sf getframe]

    frame $layout.sep1 -class WizSeparator -height 2 -bd 2 -relief groove

    # title and subtitle and icon
    frame $layout.titleframe -bd 4 -relief flat -background white
    label $wizState(widget,title) -background white -width 40
    label $wizState(widget,subtitle) -height 2 -background white -padx 15   -width 40
    label $wizState(widget,icon) \
        -borderwidth 0 \
        -image [namespace current]::feather \
        -background white \
        -anchor c
    set labelfont [font actual [$wizState(widget,title) cget -font]]
    $wizState(widget,title) configure -font [concat $labelfont -weight bold]

    # put the title, subtitle and icon inside the frame we've
    # built for them
    set tf $layout.titleframe
    grid $wizState(widget,title)    -in $tf -row 0 -column 0 -sticky nsew
    grid $wizState(widget,subtitle) -in $tf -row 1 -column 0 -sticky nsew
    grid $wizState(widget,icon)     -in $tf -row 0 -column 1 -rowspan 2 -padx 8
    grid columnconfigure $tf 0 -weight 1
    grid columnconfigure $tf 1 -weight 0

    # pre and post text. We'll pick rough estimates on the size of these
    # areas. I noticed that if I didn't give it a width and height and a
    # step defined a really, really long string, the label would try to
    # accomodate the longest string possible, making the widget unnaturally
    # wide.

    label $wizState(widget,pretext)  -width 40 
    label $wizState(widget,posttext) -width 40

    # when our label widgets change size we want to reset the
    # wraplength to that same size.
    foreach widget {title subtitle pretext posttext} {
        bind $wizState(widget,$widget) <Configure> {
            # yeah, I know this looks weird having two after idle's, but
            # it helps prevent the geometry manager getting into a tight
            # loop under certain circumstances
            #
            # note that subtracting 10 is just a somewhat arbitrary number
            # to provide a little padding...
            after idle {after idle {%W configure -wraplength [expr {%w -10}]}}
        }
    }

    grid $layout.titleframe            -row 0 -column 0 -sticky nsew -padx 0
#    grid $wizState(widget,title)      -row 0 -column 0 -sticky nsew -padx 0
#    grid $wizState(widget,subtitle)   -row 1 -column 0 -sticky nsew -padx 0
#    grid $wizState(widget,icon)       -row 0 -column 1 -rowspan 2 -sticky nsew -ipadx 10 -ipady 4
    grid $layout.sep1                 -row 1 -sticky ew 
    grid $wizState(widget,pretext)    -row 2 -sticky nsew -pady 8 -padx 8
    grid $wizState(widget,clientAreaWin) -row 3 -sticky nsew -padx 8 -pady 8
    grid $wizState(widget,posttext)   -row 4 -sticky nsew -pady 8 -pady 8

    grid columnconfigure $layout 0 -weight 1
    grid rowconfigure $layout 0 -weight 0
    grid rowconfigure $layout 1 -weight 0
    grid rowconfigure $layout 2 -weight 0
    grid rowconfigure $layout 3 -weight 1
    grid rowconfigure $layout 4 -weight 0

    # the pre and post text will initially not be visible. They will pop into
    # existence if they are configured to have a value
    grid remove $wizState(widget,pretext) $wizState(widget,posttext)

}

# usage: configureLayout-basic ?-title string? ?-subtitle string? ?-icon image?
proc tkwizard::configureLayout-basic {name args} {
    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig

    if {[llength $args]%2 == 1} {
        return -code error "wrong number of args..."
    }

    foreach {option value} $args {
        switch -- $option {
            -title {
                $wizState(widget,title) configure -text "$value"
            }

            -subtitle {
                $wizState(widget,subtitle) configure -text $value
            }

            -icon {
                $wizState(widget,icon) configure -image $icon
            }

            -pretext {
                $wizState(widget,pretext) configure -text $value
                if {[string length $value] > 0} {
                    grid $wizState(widget,pretext)

                } else {
                    grid remove $wizState(widget,pretext)
                }
            }

            -posttext {
                $wizState(widget,posttext) configure -text $value
                if {[string length $value] > 0} {
                    grid $wizState(widget,posttext)
                } else {
                    grid remove $wizState(widget,posttext)
                }
            }

            default {
                return -code error "unknown option \"$option\""
            }
        }
    }
}

######
# "Advanced" layout. Nothing really advanced about it, but that's what
# microsoft seems to call wizards that look like this. Go figure.
######

proc tkwizard::initLayout-advanced {name} {
    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig

    set layout $wizState(widget,layoutFrame).advanced

    set wizState(widget,clientAreaWin)   $layout.clientAreaWin
    # set wizState(widget,clientArea)   $layout.clientArea
    set wizState(widget,icon)         $layout.icon
    set wizState(widget,title)        $layout.title
    set wizState(widget,subtitle)     $layout.subtitle
    set wizState(widget,pretext)      $layout.pretext
    set wizState(widget,posttext)     $layout.posttext
}

proc tkwizard::buildLayout-advanced {name} {
    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig

    set layout $wizState(widget,layoutFrame).advanced
    frame $layout -class WizLayoutAdvanced

    # using the option database saves me from hard-coding it for
    # every widget. I guess I'm just lazy.
    option add *WizLayoutAdvanced*Label.justify             left interactive
    option add *WizLayoutAdvanced*Label.anchor              nw   interactive
    option add *WizLayoutAdvanced*Label.highlightThickness  0    interactive
    option add *WizLayoutAdvanced*Label.borderWidth         0    interactive
    option add *WizLayoutAdvanced*Label.padX                5    interactive

    # Client area. This is where the caller places its widgets.
    # frame $wizState(widget,clientArea) -bd 8 -relief flat
    ScrolledWindow $wizState(widget,clientAreaWin) \
        -auto both \
        -scrollbar both
    ScrollableFrame $wizState(widget,clientAreaWin).sf
    $wizState(widget,clientAreaWin) setwidget $wizState(widget,clientAreaWin).sf
    set wizState(widget,clientArea) [$wizState(widget,clientAreaWin).sf getframe]

    frame $layout.sep1 -class WizSeparator -height 2 -bd 2 -relief groove

    # title and subtitle
    label $wizState(widget,title)
    label $wizState(widget,subtitle) -height 2
    array set labelfont [font actual [$wizState(widget,title) cget -font]]
    set labelfont(-weight) bold
    incr labelfont(-size) 6
    $wizState(widget,title) configure -font [array get labelfont]

    # pre and post text. 
    label $wizState(widget,pretext)
    label $wizState(widget,posttext)

    # when our label widgets change size we want to reset the
    # wraplength to that same size.
    foreach widget {title subtitle pretext posttext} {
        bind $wizState(widget,$widget) <Configure> {
            # yeah, I know this looks weird having two after idle's, but
            # it helps prevent the geometry manager getting into a tight
            # loop under certain circumstances
            #
            # note that subtracting 10 is just a somewhat arbitrary number
            # to provide a little padding...
            after idle {after idle {%W configure -wraplength [expr {%w -10}]}}
        }
    }

    # icon
    label $wizState(widget,icon) \
        -borderwidth 1 \
        -relief sunken \
        -image [namespace current]::feather \
        -background white \
        -anchor c \
        -width 96

    grid $wizState(widget,icon)       -row 0 -column 0 -rowspan 5 -sticky nsew -pady 8 -padx 8
    grid $wizState(widget,title)      -row 0 -column 1 -sticky ew -pady 8  -padx 8
    grid $wizState(widget,subtitle)   -row 1 -column 1 -sticky ew -pady 8 -padx 8
    grid $wizState(widget,pretext)    -row 2 -column 1 -sticky ew -padx 8
    grid $wizState(widget,clientAreaWin) -row 3 -column 1 -sticky nsew -padx 8
    grid $wizState(widget,posttext)   -row 4 -column 1 -sticky ew -padx 8 -pady 24

    grid columnconfigure $layout 0 -weight 0
    grid columnconfigure $layout 1 -weight 1

    grid rowconfigure $layout 0 -weight 0
    grid rowconfigure $layout 1 -weight 0
    grid rowconfigure $layout 2 -weight 0
    grid rowconfigure $layout 3 -weight 1
    grid rowconfigure $layout 4 -weight 0

    # the pre and post text will initially not be visible. They will pop into
    # existence if they are configured to have a value
    grid remove $wizState(widget,pretext) $wizState(widget,posttext)
}

proc tkwizard::configureLayout-advanced {name args} {
    upvar #0 [namespace current]::@$name-state wizState
    upvar #0 [namespace current]::@$name-config wizConfig

    if {[llength $args]%2 == 1} {
        return -code error "wrong number of args..."
    }

    foreach {option value} $args {
        switch -- $option {
            -title {
                $wizState(widget,title) configure -text $value
            }

            -subtitle {
                $wizState(widget,subtitle) configure -text $value
            }

            -icon {
                $wizState(widget,icon) configure -image $icon
            }

            -pretext {
                $wizState(widget,pretext) configure -text $value
                if {[string length $value] > 0} {
                    grid $wizState(widget,pretext)
                } else {
                    grid remove $wizState(widget,pretext)
                }
            }

            -posttext {
                $wizState(widget,posttext) configure -text $value
                if {[string length $value] > 0} {
                    grid $wizState(widget,posttext)
                } else {
                    grid remove $wizState(widget,posttext)
                }
            }

            default {
                return -code error "unknown option \"$option\""
            }
        }
    }
}

