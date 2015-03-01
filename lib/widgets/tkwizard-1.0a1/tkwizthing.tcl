#package require tkwizard
source tkwizard.tcl

# we don't need the main window for this app...
wm withdraw .

# build the wizard
tkwizard::tkwizard .wizthing -title "TkWizthing" 

# initialize some data structures for my own use
.wizthing eval {
    variable wizData

    # default values
    catch {unset wizData}

    # this will contain the list of custom steps
    set wizData(steps) {}

    # this contains the wizard title
    set wizData(title) "Wizard"

}

# this sets up the final task of saving the wizard to 
# a file. 
bind .wizthing <<WizFinish>> {[%W namespace]::finalize}

# I want this to work, but it won't. The problem is when the
# finalize proc does "return -code break". I wish I could figure
# out how to make "%W eval finalize" synonymous with 
# "[%W namespace]::finalize" when that happens... 
#
#bind .wizthing <<WizFinish>> {[%W eval finalize]}

# this sets up a binding so we can programatically decide
# what the next step will be at runtime...
bind .wizthing <<WizNextStep>> {[%W namespace]::nextStep %W}

.wizthing step init  -layout advanced {
    variable wizData

    set c [$this widget clientArea]

    $this stepconfigure \
        -title "Welcome to the Wizard Builder" \
        -subtitle "This wizard will step you though the process\
                   of creating a wizard." \
        -pretext "" \
        -posttext "Click Next to continue."
}

.wizthing step step1 -layout basic {
    variable wizData

    set c [$this widget clientArea]

    $this stepconfigure \
        -title "Wizard Name" \
        -subtitle "The wizard name will appear on the window titlebar" \
        -pretext "Enter the string you would like to appear in the window titlebar." \
        -posttext ""

    label $c.titleLabel -text "Title:" -anchor w
    entry $c.titleEntry -textvariable [namespace current]::wizData(title) \
        -width 32
    
    pack $c.titleLabel $c.titleLabel $c.titleEntry -side top  -anchor w
}


.wizthing step step2 -layout basic {
    variable wizData

    set c [$this widget clientArea]

    # testing stepconfigure...
    $this stepconfigure \
        -title "Wizard Steps" \
        -subtitle "Identify the number and order of steps for this wizard."  \
        -pretext "Enter a name for each step and press Add. You can\
                  change the order of steps with the provided buttons.\
                  The names you use will only appear in the generated\
                  wizard code; they will not show to the end user." \
        -posttext ""

    scrollbar $c.vsb -command [list $c.lb yview]
    listbox $c.lb \
        -yscrollcommand [list $c.vsb set] \
        -selectmode single \
        -width 32 \
        -background white \
        -height 5

    eval $c.lb insert end $wizData(steps)
    label $c.newStepLabel -text "Step Name:"
    entry $c.newStepEntry -width 32 \
        -textvariable [namespace current]::newStepName

    # this trace will fire whenever the value in the entry changes. 
    # We do this so we can enable/disabled the add button appropriately.
    trace variable [namespace current]::newStepName w "
        if {\[string length \[$c.newStepEntry get\]\] == 0} {
           $c.addButton configure -state disabled
        } else {
           $c.addButton configure -state normal
        }
    "

    bind $c.newStepEntry <Return> \
        [namespace code [list manage add $this $c.newStepEntry $c.lb]]
    button $c.upButton   -text "Move Up"   -width 10 \
        -command [namespace code "manage up $this $c.newStepEntry $c.lb"] \
        -state disabled
    button $c.downButton -text "Move Down" -width 10 \
        -command [namespace code "manage down $this $c.newStepEntry $c.lb"] \
        -state disabled
    button $c.delButton  -text "Remove"    -width 10 \
        -command [namespace code  "manage del $this $c.newStepEntry $c.lb"] \
        -state disabled
    button $c.addButton  -text "Add"       -width 10 \
        -command [namespace code  "manage add $this $c.newStepEntry $c.lb"] \
        -state disabled

    grid $c.lb  -in $c -row 0 -column 0 -sticky nsew   -rowspan 5
    grid $c.vsb -in $c -row 0 -column 1 -sticky nsw   -rowspan 5

    grid $c.newStepLabel  -row 6 -column 0 -sticky w
    grid $c.newStepEntry  -row 7 -column 0 -sticky ew

    grid $c.upButton      -row 1 -column 2 -sticky ew -padx 10
    grid $c.downButton    -row 2 -column 2 -sticky ew -padx 10
    grid $c.delButton     -row 3 -column 2 -sticky ew -padx 10 -pady 4
    grid $c.addButton     -row 7 -column 2 -sticky ew -padx 10

    grid columnconfigure $c 0 -weight 1
    grid columnconfigure $c 1 -weight 0
    grid columnconfigure $c 2 -weight 0

    grid rowconfigure $c 0 -weight 1
    grid rowconfigure $c 1 -weight 0
    grid rowconfigure $c 2 -weight 0
    grid rowconfigure $c 3 -weight 0
    grid rowconfigure $c 4 -weight 1
    grid rowconfigure $c 5 -weight 0 -minsize 20
    grid rowconfigure $c 6 -weight 0
    grid rowconfigure $c 7 -weight 0

    # I want to know when the selection changes in the listbox. 
    # With tk 8.2 and beyond I could bind to <<ListboxSelect>>,
    # but I want this code to work with 8.0. So, I'll write a
    # simple wrapper around the listbox widget
    set body {
        set result [uplevel LISTBOX_ $args]
        [WIZARD namespace]::manageListbox WIZARD
        return $result
    }
    regsub -all LISTBOX $body [list ::$c.lb] body
    regsub -all WIZARD  $body [list $this]  body
    catch {rename $c.lb_ {}}
    rename $c.lb ::$c.lb_
    proc ::$c.lb {args} $body

}

.wizthing step finish -layout advanced {
    variable wizData

    set c [$this widget clientArea]

    $this stepconfigure \
        -title "Finish" \
        -subtitle "" \
        -pretext "There is now enough information to create the wizard;\n\
                  you may now view the generated code or preview the wizard." \
        -posttext "When you are ready to save the code to disk, click\n\
                   on Finish." \

    button $c.show -text "Show Wizard Code" \
        -width 18 \
        -command [namespace code  "generateWizard"] 

    button $c.preview -text "Preview Wizard" \
        -width 18 \
        -command [namespace code "previewWizard"]

    pack $c.show $c.preview -side top  -pady 4 -anchor w
}

.wizthing eval {

    # this is called when the user clicks on the Finish button
    proc finalize {} {
        set filetypes {
            {{TCL Scripts} {.tcl}}
            {{All Files}   *}
        }

        set filename [tk_getSaveFile \
                          -defaultextension .tcl \
                          -filetypes $filetypes \
                          -title "Save Wizard" \
                          -parent .wizthing ]

        if {[string length $filename] ==0} {
            return -code break 
        }

        set fh [open $filename w]
        puts $fh [.wizthing eval {generateCode .wizard}]
        close $fh
    }

    # this is used by the various buttons on step 2
    proc manageListbox {this} {
        variable wizData

        set c [$this widget clientArea]

        set wizData(steps) [$c.lb_ get 0 end]

        set sel [$c.lb_ curselection]
        set size [$c.lb_ size]

        # if nothing is selected, nothing is enabled...
        if {[llength $sel] == 0} {
            $c.upButton   configure -state disabled
            $c.downButton configure -state disabled
            $c.delButton  configure -state disabled
            return

        } 

        # if there's something selected, the delete button will always
        # be enabled
        $c.delButton configure -state normal

        if {$size == 1} {
            # if there's only one item in the list, the up and down
            # buttons are disabled
            $c.upButton configure -state disabled
            $c.downButton configure -state disabled

        } else {
            set last [incr size -1]
            set i [lindex $sel 0]
            # if there's more than one in the list and the selected item
            # is not the first item, enable the up button
            if {$i > 0} {
                $c.upButton configure -state normal
            } else {
                $c.upButton configure -state disabled
            }

            # if there's more than one in the list and the selected item
            # is not the last, enable the down button
            if {$i < $last} {
                $c.downButton configure -state normal
            } else {
                $c.downButton configure -state disabled
            }
        }
    }
    proc manage {command wiz e lb} {
        variable wizData

        switch $command {
            "add" {
                # get the text of the step
                set text [$e get]
                if {[string length $text] == 0} {
                    bell
                    return
                }
                # check for duplicates
                set i [lsearch -exact [$lb get 0 end] $text]
                if {$i >= 0} {
                    tk_messageBox \
                        -icon "info" \
                        -type "ok" \
                        -parent $wiz \
                        -message "The name '$text' has already been\
                              used for a step. Step names must be unique."
                } else {
                    $lb insert end $text
                    $lb see end
                    $e delete 0 end
                }
            }
            "del" {
                set index [$lb curselection]
                if {[llength $index] > 0} {
                    set i [lindex $index 0]
                    $lb delete $i

                    # we want to make a new selection. This will
                    # be the same index if it exists, or the one prior
                    # if it exists... Interesting fact: this is the 
                    # first time in several years of tcl programming
                    # that I learned [$lb index end] returns the number
                    # of items in the listbox rather than the index of
                    # the last item. Feh. 
                    set last [expr {[$lb index end] -1}]
                    if {$i > $last} {
                        incr i -1
                    }
                    $lb selection anchor $i
                    $lb selection set $i
                }
            }
            "up" {
                set y1 [lindex [$lb curselection] 0]
                set y2 [expr {$y1 -1}]
                set item [$lb get $y1]
                $lb delete $y1
                $lb insert $y2 $item
                $lb selection anchor $y2
                $lb selection set $y2
            }
            "down" {
                set y1 [lindex [$lb curselection] 0]
                set y2 [expr {$y1 +1}]
                set item [$lb get $y1]
                $lb delete $y1
                $lb insert $y2 $item
                $lb selection anchor $y2
                $lb selection set $y2
            }
        }

        set wizData(steps) [$lb get 0 end]
    }

    proc nextStep {this} {

        variable wizData

        set currentStep [$this cget -step]

        # if the current step is step2, we need to reconfigure
        # the wizard to have a new step for each step of the 
        # wizard being created
        if {$currentStep == "step2"} {

            set order [list init step1 step2]
            for {set i 0} "\$i < [llength $wizData(steps)]" {incr i} {
                $this step newStep-$i -layout basic [list stepConfig $this $i]
                lappend order newStep-$i
            }
            lappend order finish
            eval $this order $order
            $this configure -nextstep [lindex $order 3]
        }
    }

    proc stepConfig {this index} {
        variable wizData

        set stepName [lindex $wizData(steps) $index]

        set c [$this widget clientArea]

        $this stepconfigure \
            -title "Step Configuration: $stepName" \
            -subtitle "Use this form to configure step-specific information."  \
            -pretext "" \
            -posttext ""

        label $c.layoutLabel -text "Layout:" -anchor w
        tk_optionMenu $c.layout [namespace current]::wizData(layout,$index) Basic Advanced
        $c.layout configure -width 8

        label $c.titleLabel -text "Title:" -anchor w
        entry $c.titleEntry \
            -width 32 \
            -textvariable [namespace current]::wizData(title,$index)
        label $c.subtitleLabel -text "SubTitle:" -anchor w
        entry $c.subtitleEntry \
            -width 32 \
            -textvariable [namespace current]::wizData(subtitle,$index)

        grid $c.layoutLabel   -row 0 -column 0               -sticky w
        grid $c.layout        -row 0 -column 1               -sticky w
        grid $c.titleLabel    -row 2 -column 0 -columnspan 2 -sticky w
        grid $c.titleEntry    -row 3 -column 0 -columnspan 2 -sticky w
        grid $c.subtitleLabel -row 5 -column 0 -columnspan 2 -sticky w
        grid $c.subtitleEntry -row 6 -column 0 -columnspan 2 -sticky w

        grid columnconfigure $c 0 -weight 0
        grid columnconfigure $c 1 -weight 1

        grid rowconfigure $c 0 -weight 0
        grid rowconfigure $c 1 -weight 0 -minsize 4
        grid rowconfigure $c 2 -weight 0
        grid rowconfigure $c 3 -weight 0
        grid rowconfigure $c 4 -weight 0 -minsize 4
        grid rowconfigure $c 5 -weight 0
        grid rowconfigure $c 6 -weight 0
        grid rowconfigure $c 7 -weight 1
    }

    proc previewWizard {} {
        set wizardCode [generateCode .wizard]

        catch {destroy .wizard}
        eval $wizardCode
        wm geometry .wizard 350x200
        if {[catch {.wizard show} error]} {
            tk_messageBox -icon info \
                -message "There was a problem displaying the wizard: $error" \
                -parent .wizthing
        }
    }

    proc generateWizard {} {
        variable wizData

        catch {destroy .wizshower}
        toplevel .wizshower
        text .wizshower.t -yscrollcommand {.wizshower.vsb set} \
            -font {-family Courier -size 10}
        scrollbar .wizshower.vsb -command {.wizshower.t yview}
        pack .wizshower.vsb -side right -fill y
        pack .wizshower.t -side left -fill both -expand y

        .wizshower.t insert end [generateCode .wizard]
    }

    proc generateCode {w} {
        variable wizData

        set wizard "tkwizard::tkwizard $w -title [list $wizData(title)]

$w eval {
    variable wizData

    # default values
    catch {unset wizData}
}
"
        
        # add each step
        for {set i 0} {$i < [llength $wizData(steps)]} {incr i} {
            set step [lindex $wizData(steps) $i]
            append wizard "
.wizard step {[list $step]} -layout [string tolower $wizData(layout,$i)] {
    variable wizData

    set c \[\$this widget clientArea\]

    \$this stepconfigure \\
        -title [list $wizData(title,$i)] \\
        -subtitle [list $wizData(subtitle,$i)] \\
        -pretext {} \\
        -posttext {}
}
            "
        }
        return $wizard
    }
}


#wm geometry .wizthing 450x350
wm minsize .wizthing 450 350

# set the initial order of the steps for this wizard. Not strictly
# necessary, but it helps document my intent
.wizthing order init step1 step2 finish

.wizthing show
