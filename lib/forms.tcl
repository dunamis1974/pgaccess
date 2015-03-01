#==========================================================
# Forms --
#
#     procedures for developing and running small apps
#
# note to self: when adding new widgets, searching for "does
# it have" and "is it a" comment lines is very helpful
#==========================================================
#
namespace eval Forms {
    variable Win
    variable allwidprops {class name coord command label variable value relief fcolor bcolor borderwidth font just anch curse plusbind pages}
}

#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::new {} {
global PgAcVar
    set PgAcVar(fcnt) 1
    Window show .pgaw:FormDesign:menu
    tkwait visibility .pgaw:FormDesign:menu
    Window show .pgaw:FormDesign:toolbar
    tkwait visibility .pgaw:FormDesign:toolbar
    Window show .pgaw:FormDesign:attributes
    tkwait visibility .pgaw:FormDesign:attributes
    Window show .pgaw:FormDesign:draft
    tkwait visibility .pgaw:FormDesign:draft
    design:init
    design:draw_grid
}; # end proc ::Forms::new


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::open {formname_ {parent_ ""}} {
global PgAcVar
    if {[info exists PgAcVar(fcnt)]} {
        incr PgAcVar(fcnt)
    } else {
        set PgAcVar(fcnt) 1
    }
    forms:load $formname_ run
    return [design:run $parent_]
}; # end proc ::Forms::open


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design {formname_} {
global PgAcVar
    set PgAcVar(fcnt) 1
    forms:load $formname_ design
}; # end proc ::Forms::design


#----------------------------------------------------------
# ::Forms::isloaded --
#
#    This tells whether or not the form is currently loaded.
#     It could be loaded in either 'open' or 'design' modes.
#
# Arguments:
#     formname_    The name of the form
# 
# Results:
#     1 if formname_ is currently loaded, 0 otherwise    
#----------------------------------------------------------
#
proc ::Forms::isloaded {formname_} {
global PgAcVar
    if {[info exists PgAcVar(floaded)] \
        && [lsearch $PgAcVar(floaded) $formname_] != -1} {
        return 1
    } else {
        return 0
    }
}; # end proc ::Forms::isloaded


#----------------------------------------------------------
# ::Forms::introspect --
#
#   Given a formname, returns the SQL needed to recreate it
#
# Arguments:
#   formname_  name of a form to introspect
#   dbh_       an optional database handle
#
# Returns:
#   insql      the INSERT statement to make this form
#----------------------------------------------------------
#
proc ::Forms::introspect {formname_ {dbh_ ""}} {

    set insql [::Forms::clone $formname_ $formname_ $dbh_]

    return $insql

}; # end proc ::Forms::introspect


#----------------------------------------------------------
# ::Forms::clone --
#
#   Like introspect, only changes the formname
#
# Arguments:
#   srcform_    the original form
#   destform_   the clone form
#   dbh_        an optional database handle
#
# Returns:
#   insql       the INSERT statement to clone this form
#----------------------------------------------------------
#
proc ::Forms::clone {srcform_ destform_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set insql ""

    set sql "SELECT formsource
               FROM pga_forms
              WHERE formname='$srcform_'"

    wpg_select $dbh_ $sql rec {
        set insql "
            INSERT INTO pga_forms (formname, formsource)
                 VALUES ('[::Database::quoteSQL $destform_]','[::Database::quoteSQL $rec(formsource)]');"
    }

    return $insql

}; # end proc ::Forms::clone


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:change_coords {} {
global PgAcVar
    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
    set i $PgAcVar(fdvar,$PgAcVar(fcnt),attributeFrame)
    if {$i == 0} {
        # it's the form
        set errmsg ""
        if {[catch {wm geometry .pgaw:FormDesign:draft $PgAcVar(fdvar,$PgAcVar(fcnt),c_width)x$PgAcVar(fdvar,$PgAcVar(fcnt),c_height)+$PgAcVar(fdvar,$PgAcVar(fcnt),c_left)+$PgAcVar(fdvar,$PgAcVar(fcnt),c_top)} errmsg] != 0} {
            showError $errmsg
        }
        return
    }        
    set c [list $PgAcVar(fdvar,$PgAcVar(fcnt),c_left) $PgAcVar(fdvar,$PgAcVar(fcnt),c_top) [expr {$PgAcVar(fdvar,$PgAcVar(fcnt),c_left)+$PgAcVar(fdvar,$PgAcVar(fcnt),c_width)}] [expr {$PgAcVar(fdvar,$PgAcVar(fcnt),c_top)+$PgAcVar(fdvar,$PgAcVar(fcnt),c_height)}]]
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,coord) $c
    .pgaw:FormDesign:draft.c delete o$i
    design:draw_object $i
    design:draw_hookers $i
}; # end proc ::Forms::design:change_coords


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:delete_object {} {
global PgAcVar
    set i $PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj)
    .pgaw:FormDesign:draft.c delete o$i
    .pgaw:FormDesign:draft.c delete hook
    set j [lsearch $PgAcVar(fdvar,$PgAcVar(fcnt),objlist) $i]
    set PgAcVar(fdvar,$PgAcVar(fcnt),objlist) [lreplace $PgAcVar(fdvar,$PgAcVar(fcnt),objlist) $j $j]
    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
}; # end proc ::Forms::design:delete_object


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:cut_object {} {
global PgAcVar
    design:copy_object
    design:delete_object
}; # end proc ::Forms::design:cut_object


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:copy_object {} {
global PgAcVar
    set PgAcVar(fdvar,$PgAcVar(fcnt),copyitemobj) $PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj)
}; # end proc ::Forms::design:copy_object


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:paste_object {} {
global PgAcVar
    set i [incr PgAcVar(fdvar,$PgAcVar(fcnt),objnum)]
    lappend PgAcVar(fdvar,$PgAcVar(fcnt),objlist) $i
    set gs $PgAcVar(fdvar,$PgAcVar(fcnt),gridsize)

    ##
    ##  If an object is not selected, then
    ##  we will return instead of trying to
    ##  paste "nothing"
    ##
    #if {[string match "" $d]} {return}
    if {![info exists PgAcVar(fdvar,$PgAcVar(fcnt),copyitemobj)]} {return}
    set d $PgAcVar(fdvar,$PgAcVar(fcnt),copyitemobj)

    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,class) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,class)

    foreach {x1 y1 x2 y2} $PgAcVar(fdobj,$PgAcVar(fcnt),$d,coord) {
        set PgAcVar(fdobj,$PgAcVar(fcnt),$i,coord) \
        [list [incr x1 $gs] [incr y1 $gs] [incr x2 $gs] [incr y2 $gs]]
    }

    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,name) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,class)${i}
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,label) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,class)${i}

    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,command) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,command)
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,variable) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,variable)
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,value) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,value)
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,borderwidth) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,borderwidth)
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,relief)
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,fcolor)
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,bcolor)
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,font) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,font)
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,anch) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$d,anch)
    
    design:draw_object $i
    design:show_attributes $i
    set PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj) $i
    design:draw_hookers $i
    set PgAcVar(fdvar,$PgAcVar(fcnt),tool) point
    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
}; # end proc ::Forms::design:paste_object


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:draw_hook {x y} {
    .pgaw:FormDesign:draft.c create rectangle [expr {$x-3}] [expr {$y-3}] [expr {$x+3}] [expr {$y+3}] -fill black -tags hook
}; # end proc ::Forms::design:draw_hook


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:draw_hookers {i} {
global PgAcVar
    foreach {x1 y1 x2 y2} $PgAcVar(fdobj,$PgAcVar(fcnt),$i,coord) {}
    .pgaw:FormDesign:draft.c delete hook
    design:draw_hook $x1 $y1
    design:draw_hook $x1 $y2
    design:draw_hook $x2 $y1
    design:draw_hook $x2 $y2
    .pgaw:FormDesign:draft.c raise hook
    # give the item a hooked tag, and delete any previous hooked item tags
    .pgaw:FormDesign:draft.c dtag hooked
    # can't just do addtag hooked withtag $i cause $i isn't a tag or id
    .pgaw:FormDesign:draft.c addtag hooked \
        enclosed [expr {$x1-1}] [expr {$y1-1}] [expr {$x2+1}] [expr {$y2+1}]
    # make sure we didn't get the grid by accident
    .pgaw:FormDesign:draft.c dtag grid hooked
}; # end proc ::Forms::design:draw_hookers


#----------------------------------------------------------
#----------------------------------------------------------
#
# we look for the closest line on the grid to the given point
proc ::Forms::design:snap_point {p} {
global PgAcVar
    if {$PgAcVar(fdvar,$PgAcVar(fcnt),gridsnap)==0} {
        return $p
    }
    set s $PgAcVar(fdvar,$PgAcVar(fcnt),gridsize)
    set t [expr {round($s/2)}]
    set r [expr {$p%$s}]
    if {$r<=$t} {
        set q [expr {$p-$r}]
    } else {
        set q [expr {$p+($s-$r)}]
    }
    return $q
}; # end proc ::Forms::design:snap_point


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:draw_grid {} {
global PgAcVar
    .pgaw:FormDesign:draft.c delete grid
    set s $PgAcVar(fdvar,$PgAcVar(fcnt),gridsize)
    for {set i 0} {$i<200} {incr i} {
        .pgaw:FormDesign:draft.c create line \
            0 [expr {$i*$s}] 1000 [expr {$i*$s}] -fill #afafaf -tags grid
        .pgaw:FormDesign:draft.c create line \
            [expr {$i*$s}] 0 [expr {$i*$s}] 1000 -fill #afafaf -tags grid
    }
    .pgaw:FormDesign:draft.c lower grid
}; # end proc ::Forms::design:draw_grid


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:draw_object {i} {
global PgAcVar
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,class)]} return;
if {$PgAcVar(fdobj,$PgAcVar(fcnt),$i,class)=="form"} return;
set c $PgAcVar(fdobj,$PgAcVar(fcnt),$i,coord)
foreach {x1 y1 x2 y2} $c {}
.pgaw:FormDesign:draft.c delete o$i
set wfont $PgAcVar(fdobj,$PgAcVar(fcnt),$i,font)
switch $wfont {
    {} {
        set wfont $PgAcVar(pref,font_normal)
        set PgAcVar(fdobj,$PgAcVar(fcnt),$i,font) normal
    }
    normal  {set wfont $PgAcVar(pref,font_normal)}
    bold  {set wfont $PgAcVar(pref,font_bold)}
    italic  {set wfont $PgAcVar(pref,font_italic)}
    fixed  {set wfont $PgAcVar(pref,font_fix)}
}

# set up anchor and justification
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,anch)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),$i,anch)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,anch) center
}
set wanch $PgAcVar(fdobj,$PgAcVar(fcnt),$i,anch)
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,just)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),$i,just)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,just) left
}
set wjust $PgAcVar(fdobj,$PgAcVar(fcnt),$i,just)

switch $PgAcVar(fdobj,$PgAcVar(fcnt),$i,class) {
    button {
        design:draw_rectangle $x1 $y1 $x2 $y2 \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) o$i
        .pgaw:FormDesign:draft.c create text \
        [expr {($x1+$x2)/2}] [expr {($y1+$y2)/2}] \
        -fill $PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) \
        -text $PgAcVar(fdobj,$PgAcVar(fcnt),$i,label) \
        -anchor $wanch -justify $wjust -font $wfont -tags o$i
    }
    text {
        design:draw_rectangle $x1 $y1 $x2 $y2 \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) o$i
    }
    entry {
        design:draw_rectangle $x1 $y1 $x2 $y2 \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) o$i
    }
    label {
        set temp $PgAcVar(fdobj,$PgAcVar(fcnt),$i,label)
        if {$temp==""} {set temp "____"}
        design:draw_rectangle $x1 $y1 $x2 $y2 \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) o$i
        .pgaw:FormDesign:draft.c create text \
        [expr {($x1+$x2)/2}] [expr {($y1+$y2)/2}] \
        -text $temp -fill $PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) \
        -font $wfont -tags o$i
    }
    checkbox {
        design:draw_rectangle \
        [expr {$x1+2}] [expr {$y1+5}] [expr {$x1+12}] [expr {$y1+15}] \
        raised #a0a0a0 o$i
        .pgaw:FormDesign:draft.c create text \
        [expr {$x1+47}] [expr {$y1+15}] \
        -text $PgAcVar(fdobj,$PgAcVar(fcnt),$i,label) \
        -fill $PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) \
        -font $wfont -tags o$i
    }
    radio {
        .pgaw:FormDesign:draft.c create oval \
        [expr {$x1+4}] [expr {$y1+5}] [expr {$x1+14}] [expr {$y1+15}] \
        -fill white -tags o$i
        .pgaw:FormDesign:draft.c create text \
        [expr {$x1+44}] [expr {$y1+13}] \
        -text $PgAcVar(fdobj,$PgAcVar(fcnt),$i,label) \
        -fill $PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) \
        -font $wfont -tags o$i
    }
    query {
        .pgaw:FormDesign:draft.c create oval $x1 $y1 \
        [expr {$x1+20}] [expr {$y1+20}] -fill white -tags o$i
        .pgaw:FormDesign:draft.c create text \
        [expr {$x1+5}] [expr {$y1+4}] -text Q \
        -anchor nw -font $PgAcVar(pref,font_normal) -tags o$i
    }
    table {
        .pgaw:FormDesign:draft.c create rectangle $x1 $y1 \
        [expr {$x1+20}] [expr {$y1+20}] -fill white -tags o$i
        .pgaw:FormDesign:draft.c create text \
        [expr {$x1+5}] [expr {$y1+4}] -text T \
        -anchor nw -font $PgAcVar(pref,font_normal) -tags o$i
    }
    listbox {
        design:draw_rectangle $x1 $y1 [expr {$x2-12}] $y2 \
        sunken $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) o$i
        design:draw_rectangle [expr {$x2-11}] $y1 $x2 $y2 sunken gray o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-5}] $y1 $x2 [expr {$y1+10}] -fill #808080 -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-10}] [expr {$y1+9}] $x2 [expr {$y1+9}] \
        -fill #808080 -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-10}] [expr {$y1+9}] [expr {$x2-5}] $y1 -fill white -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-5}] $y2 $x2 [expr {$y2-10}] -fill #808080 -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-10}] [expr {$y2-9}] $x2 [expr {$y2-9}] -fill white -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-10}] [expr {$y2-9}] [expr {$x2-5}] $y2 -fill white -tags o$i
    }
    spinbox {
        design:draw_rectangle $x1 $y1 [expr {$x2-12}] $y2 \
        sunken $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) o$i
        design:draw_rectangle [expr {$x2-11}] $y1 $x2 $y2 sunken gray o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-5}] $y1 $x2 [expr {$y1+10}] -fill #808080 -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-10}] [expr {$y1+9}] $x2 [expr {$y1+9}] \
        -fill #808080 -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-10}] [expr {$y1+9}] [expr {$x2-5}] $y1 -fill white -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-5}] $y2 $x2 [expr {$y2-10}] -fill #808080 -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-10}] [expr {$y2-9}] $x2 [expr {$y2-9}] -fill white -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-10}] [expr {$y2-9}] [expr {$x2-5}] $y2 -fill white -tags o$i
    }
    combobox {
        design:draw_rectangle $x1 $y1 [expr {$x2-12}] $y2 \
        sunken $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) o$i
        design:draw_rectangle [expr {$x2-11}] $y1 $x2 $y2 sunken gray o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-8}] [expr {$y1+2}] [expr {$x2-2}] [expr {$y1+2}] \
        -fill #000000 -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-8}] [expr {$y1+2}] [expr {$x2-5}] [expr {$y1+8}] \
        -fill #000000 -tags o$i
        .pgaw:FormDesign:draft.c create line \
        [expr {$x2-2}] [expr {$y1+2}] [expr {$x2-5}] [expr {$y1+8}] \
        -fill #000000 -tags o$i
    }
    tree {
        design:draw_rectangle $x1 $y1 $x2 $y2 \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) o$i
        .pgaw:FormDesign:draft.c create line \
            [expr {$x1+5}] [expr {$y1+5}] [expr {$x1+5}] [expr {$y2-5}] \
            -fill #000000 -tags o$i
        # draw a bunch of tree limbs
        for {set c 10} {$c<[expr {$y2-$y1-5}]} {incr c 10} {
            .pgaw:FormDesign:draft.c create line \
                [expr {$x1+5}] [expr {$y1+$c}] [expr {$x2-5}] [expr {$y1+$c}] \
                -fill #000000 -tags o$i
        }
    }
    subform {
        design:draw_rectangle $x1 $y1 $x2 $y2 \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) o$i
    }
    image {
        design:draw_rectangle $x1 $y1 $x2 $y2 \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) o$i
    }
    notebook {
        design:draw_rectangle $x1 $y1 $x2 $y2 \
            $PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) \
            $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) o$i
        # draw some tabs
        .pgaw:FormDesign:draft.c create line \
            [expr {$x1+11}] [expr {$y1+3}] [expr {$x1+1}] [expr {$y1+15}] \
            -fill #000000 \
            -tags o$i
        .pgaw:FormDesign:draft.c create line \
            [expr {$x1+65}] [expr {$y1+3}] [expr {$x1+75}] [expr {$y1+15}] \
            -fill #000000 \
            -tags o$i
        .pgaw:FormDesign:draft.c create line \
            [expr {$x1+11}] [expr {$y1+3}] [expr {$x1+65}] [expr {$y1+3}] \
            -fill #000000 \
            -tags o$i
        .pgaw:FormDesign:draft.c create line \
            [expr {$x1+75}] [expr {$y1+15}] [expr {$x2}] [expr {$y1+15}] \
            -fill #000000 \
            -tags o$i
    }
}
.pgaw:FormDesign:draft.c raise hook
}; # end proc ::Forms::design:draw_object


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:draw_rectangle {x1 y1 x2 y2 relief color tag} {
    if {$relief=="raised"} {
        set c1 white
        set c2 #606060
    }
    if {$relief=="sunken"} {
        set c1 #606060
        set c2 white
    }
    if {$relief=="ridge"} {
        design:draw_rectangle $x1 $y1 $x2 $y2 raised none $tag
        design:draw_rectangle [expr {$x1+1}] [expr {$y1+1}] \
            [expr {$x2+1}] [expr {$y2+1}] sunken none $tag
        design:draw_rectangle [expr {$x1+2}] [expr {$y1+2}] \
            $x2 $y2 flat $color $tag
        return
    }
    if {$relief=="groove"} {
        design:draw_rectangle $x1 $y1 $x2 $y2 sunken none $tag
        design:draw_rectangle [expr {$x1+1}] [expr {$y1+1}] \
            [expr {$x2+1}] [expr {$y2+1}] raised none $tag
        design:draw_rectangle [expr {$x1+2}] [expr {$y1+2}] \
            $x2 $y2 flat $color $tag
        return
    }
    if {$color != "none"} {
        .pgaw:FormDesign:draft.c create rectangle $x1 $y1 $x2 $y2 \
        -outline "" -fill $color -tags $tag
    }
    if {$relief=="flat"} {
        return
    }
    .pgaw:FormDesign:draft.c create line $x1 $y1 $x2 $y1 -fill $c1 -tags $tag
    .pgaw:FormDesign:draft.c create line $x1 $y1 $x1 $y2 -fill $c1 -tags $tag
    .pgaw:FormDesign:draft.c create line $x1 $y2 $x2 $y2 -fill $c2 -tags $tag
    .pgaw:FormDesign:draft.c create line $x2 $y1 $x2 [expr {1+$y2}] \
    -fill $c2 -tags $tag
}; # end proc ::Forms::design:draw_rectangle


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:init {} {
global PgAcVar
    PgAcVar:clean fdvar,$PgAcVar(fcnt),*
    PgAcVar:clean fdobj,$PgAcVar(fcnt),*
    catch {.pgaw:FormDesign:draft.c delete all}
    set PgAcVar(fdobj,$PgAcVar(fcnt),0,name) {f1}
    set PgAcVar(fdobj,$PgAcVar(fcnt),0,class) form
    set PgAcVar(fdobj,$PgAcVar(fcnt),0,command) {}
    set PgAcVar(fdobj,$PgAcVar(fcnt),0,bcolor) #999999
    set PgAcVar(fdobj,$PgAcVar(fcnt),0,curse) left_ptr
    if {$PgAcVar(fcnt)==1} {
        set PgAcVar(fdvar,testform) [intlmsg "Test form"]
    }
    set PgAcVar(fdvar,$PgAcVar(fcnt),formtitle) [intlmsg "New form"]
    set PgAcVar(fdvar,$PgAcVar(fcnt),gridsize) 10
    set PgAcVar(fdvar,$PgAcVar(fcnt),gridsnap) 1
    set PgAcVar(fdvar,$PgAcVar(fcnt),objnum) 0
    set PgAcVar(fdvar,$PgAcVar(fcnt),objlist) {}
    set PgAcVar(fdvar,$PgAcVar(fcnt),oper) none
    set PgAcVar(fdvar,$PgAcVar(fcnt),tool) point
    set PgAcVar(fdvar,$PgAcVar(fcnt),resizable) 1
    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 0
}; # end proc ::Forms::design:init


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:item_click {x y} {
global PgAcVar
    set PgAcVar(fdvar,$PgAcVar(fcnt),oper) none
    set PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj) {}
    # need to be able to resize even if hooker isn't on the grid
    if {$PgAcVar(fdvar,$PgAcVar(fcnt),gridsnap)==0} {
        set item [.pgaw:FormDesign:draft.c find closest $x $y]
    } else {
        # make the halo small enough to let little widgets be movable
        set item [.pgaw:FormDesign:draft.c find closest $x $y \
            [expr {$PgAcVar(fdvar,$PgAcVar(fcnt),gridsize)/2}]]
    }
    set tl [.pgaw:FormDesign:draft.c gettags $item]
    # see if a hooker was grabbed and decide which corner it was
    if {[lsearch $tl hook] != -1} {
        # we want the hooked item not the hookers
        set hookeditem [lindex [.pgaw:FormDesign:draft.c find withtag hooked] 0]
        foreach {x1 y1 x2 y2} [.pgaw:FormDesign:draft.c coords $hookeditem] {}
        if {![info exists x1]
         || ![info exists x2]
         || ![info exists x]} {
            return
        }
        if {[expr {abs($x-$x1)}] < [expr {abs($x-$x2)}]} {
            set sx $x1
            set ax $x2
        } else {
            set sx $x2
            set ax $x1
        }
        if {[expr {abs($y-$y1)}] < [expr {abs($y-$y2)}]} {
            set sy $y1
            set ay $y2
        } else {
            set sy $y2
            set ay $y1
        }
        set PgAcVar(fdvar,$PgAcVar(fcnt),xstart) $sx
        set PgAcVar(fdvar,$PgAcVar(fcnt),ystart) $sy
        set PgAcVar(fdvar,$PgAcVar(fcnt),xanch) $ax
        set PgAcVar(fdvar,$PgAcVar(fcnt),yanch) $ay
        set PgAcVar(fdvar,$PgAcVar(fcnt),oper) resize
        set PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj) $hookeditem
    }
    # send clicks on the grid to the canvas
    if {[lsearch $tl grid] != -1} {
        .pgaw:FormDesign:draft.c delete hook
        design:show_attributes 0
        return
    }
    set i [lsearch -glob $tl o*]
    if {$i == -1} return
    set objnum [string range [lindex $tl $i] 1 end]
    set PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj) $objnum
    set PgAcVar(fdvar,$PgAcVar(fcnt),moveitemx) [design:snap_point $x]
    set PgAcVar(fdvar,$PgAcVar(fcnt),moveitemy) [design:snap_point $y]
    set PgAcVar(fdvar,$PgAcVar(fcnt),oper) move
    .pgaw:FormDesign:draft.c move $item \
        [expr {$PgAcVar(fdvar,$PgAcVar(fcnt),moveitemx)-$x}] \
        [expr {$PgAcVar(fdvar,$PgAcVar(fcnt),moveitemy)-$y}]
    design:show_attributes $objnum
    design:draw_hookers $objnum
}; # end proc ::Forms::design:item_click


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::forms:load {name mode} {
global PgAcVar CurrentDB
    
    if {![info exists PgAcVar(floaded)]} {
        set PgAcVar(floaded) {$name}
    } else {
        lappend PgAcVar(floaded) $name
    }

    design:init
    set PgAcVar(fdvar,$PgAcVar(fcnt),formtitle) $name
    if {$mode=="design"} {
        Window show .pgaw:FormDesign:draft
        Window show .pgaw:FormDesign:menu
        Window show .pgaw:FormDesign:attributes
        Window show .pgaw:FormDesign:toolbar
        design:draw_grid
    }

    set res [wpg_exec $CurrentDB "
        SELECT oid,*
          FROM pga_forms
         WHERE formname='$PgAcVar(fdvar,$PgAcVar(fcnt),formtitle)'
         "]

    # cant load a non-existent form
    if {[pg_result $res -numTuples]==0} {return}

    set PgAcVar(fdvar,$PgAcVar(fcnt),oid) [lindex [pg_result $res -getTuple 0] 0]

    set info [lindex [pg_result $res -getTuple 0] 2]
    pg_result $res -clear

    # starting with 0.98.8p4, form header info is a list
    # check for backwards compatibility
    if {[llength [lindex $info 0]]>1} {
        set head [lindex $info 0]
        set PgAcVar(fdobj,$PgAcVar(fcnt),0,name) [lindex $head 0]
        set PgAcVar(fdvar,$PgAcVar(fcnt),objnum) [lindex $head 1]
        set PgAcVar(fdobj,$PgAcVar(fcnt),0,command) [lindex $head 2]
        set PgAcVar(fdvar,$PgAcVar(fcnt),geometry) [lindex $head 3]
        set PgAcVar(fdobj,$PgAcVar(fcnt),0,bcolor) [lindex $head 4]
        set PgAcVar(fdobj,$PgAcVar(fcnt),0,curse) [lindex $head 5]
        set PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) [lindex $head 6]
        set PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs) [lindex $head 7]
        set PgAcVar(fdobj,$PgAcVar(fcnt),0,class) "form" 
        set start_widgets 1
    } else {
        set PgAcVar(fdobj,$PgAcVar(fcnt),0,name) [lindex $info 0]
        set PgAcVar(fdvar,$PgAcVar(fcnt),objnum) [lindex $info 1]
        # check for old format , prior to 0.97 that
        # save here the objlist (deprecated)
        set temp [lindex $info 2]
        if {[lindex $temp 0] == "FS"} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),0,command) [lindex $temp 1]
        } else {
            set PgAcVar(fdobj,$PgAcVar(fcnt),0,command) {}
        }
        set PgAcVar(fdvar,$PgAcVar(fcnt),geometry) [lindex $info 3]
        set start_widgets 4
    }
    set PgAcVar(fdvar,$PgAcVar(fcnt),objlist) {}
    set i 1
    foreach objinfo [lrange $info $start_widgets end] {
        lappend PgAcVar(fdvar,$PgAcVar(fcnt),objlist) $i
        set PgAcVar(fdobj,$PgAcVar(fcnt),$i,class)    [lindex $objinfo 0]
        set PgAcVar(fdobj,$PgAcVar(fcnt),$i,name)     [lindex $objinfo 1]
        set PgAcVar(fdobj,$PgAcVar(fcnt),$i,coord)    [lindex $objinfo 2]
        set PgAcVar(fdobj,$PgAcVar(fcnt),$i,command)  [lindex $objinfo 3]
        set PgAcVar(fdobj,$PgAcVar(fcnt),$i,label)    [lindex $objinfo 4]
        set PgAcVar(fdobj,$PgAcVar(fcnt),$i,variable) [lindex $objinfo 5]
        design:setDefaultReliefAndColor $i
        set PgAcVar(fdobj,$PgAcVar(fcnt),$i,value) \
            $PgAcVar(fdobj,$PgAcVar(fcnt),$i,name)
        if {[llength $objinfo] >  6 } {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,value)       [lindex $objinfo 6]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief)      [lindex $objinfo 7]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor)      [lindex $objinfo 8]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor)      [lindex $objinfo 9]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,borderwidth) \
                [lindex $objinfo 10]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,font)       [lindex $objinfo 11]
            # for space saving purposes we have saved onbly the first letter
            switch $PgAcVar(fdobj,$PgAcVar(fcnt),$i,font) {
                n {set PgAcVar(fdobj,$PgAcVar(fcnt),$i,font) normal}
                i {set PgAcVar(fdobj,$PgAcVar(fcnt),$i,font) italic}
                b {set PgAcVar(fdobj,$PgAcVar(fcnt),$i,font) bold}
                f {set PgAcVar(fdobj,$PgAcVar(fcnt),$i,font) fixed}
            }
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,anch)       [lindex $objinfo 12]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,just)       [lindex $objinfo 13]
            # for space saving purposes we have saved onbly the first letter
            switch $PgAcVar(fdobj,$PgAcVar(fcnt),$i,just) {
                l {set PgAcVar(fdobj,$PgAcVar(fcnt),$i,just) left}
                r {set PgAcVar(fdobj,$PgAcVar(fcnt),$i,just) right}
                c {set PgAcVar(fdobj,$PgAcVar(fcnt),$i,just) center}
            }
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,curse) [lindex $objinfo 14]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,editable) [lindex $objinfo 15]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,validate) [lindex $objinfo 16]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,validatecmd) \
                [lindex $objinfo 17]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,invalidcmd) [lindex $objinfo 18]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,plusbind) [lindex $objinfo 19]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,pages) [lindex $objinfo 20]
        }
        if {$mode=="design"} {design:draw_object $i}
        incr i
    }
    if {$mode=="design"} {
        wm geometry .pgaw:FormDesign:draft \
            $PgAcVar(fdvar,$PgAcVar(fcnt),geometry)
    }
}; # end proc ::Forms::forms:load


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:mouse_down {x y} {
global PgAcVar
    set x [design:snap_point [expr {3*int($x/3)}]]
    set y [design:snap_point [expr {3*int($y/3)}]]
    set PgAcVar(fdvar,$PgAcVar(fcnt),xstart) $x
    set PgAcVar(fdvar,$PgAcVar(fcnt),ystart) $y
    if {$PgAcVar(fdvar,$PgAcVar(fcnt),tool)=="point"} {
        design:item_click $x $y
        return
    }
    set PgAcVar(fdvar,$PgAcVar(fcnt),oper) draw
}; # end proc ::Forms::design:mouse_down


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:mouse_move {x y} {
global PgAcVar
    #set PgAcVar(fdvar,$PgAcVar(fcnt),msg) "x=$x y=$y"
    set x [design:snap_point [expr {3*int($x/3)}]]
    set y [design:snap_point [expr {3*int($y/3)}]]
    set oper ""
    catch {set oper $PgAcVar(fdvar,$PgAcVar(fcnt),oper)}
    if {$oper=="draw"} {
        catch {.pgaw:FormDesign:draft.c delete curdraw}
        .pgaw:FormDesign:draft.c create rectangle \
            $PgAcVar(fdvar,$PgAcVar(fcnt),xstart) \
            $PgAcVar(fdvar,$PgAcVar(fcnt),ystart) $x $y -tags curdraw
    } elseif {$oper=="move"} {
        set dx [expr {$x-$PgAcVar(fdvar,$PgAcVar(fcnt),moveitemx)}]
        set dy [expr {$y-$PgAcVar(fdvar,$PgAcVar(fcnt),moveitemy)}]
        .pgaw:FormDesign:draft.c move \
            o$PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj) $dx $dy
        .pgaw:FormDesign:draft.c move hook $dx $dy
        set PgAcVar(fdvar,$PgAcVar(fcnt),moveitemx) $x
        set PgAcVar(fdvar,$PgAcVar(fcnt),moveitemy) $y
        set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
    } elseif {$oper=="resize"} {
        catch {.pgaw:FormDesign:draft.c delete curdraw}
        .pgaw:FormDesign:draft.c create rectangle \
            $PgAcVar(fdvar,$PgAcVar(fcnt),xanch) \
            $PgAcVar(fdvar,$PgAcVar(fcnt),yanch) $x $y -tags curdraw
    }
}; # end proc ::Forms::design:mouse_move


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:setDefaultReliefAndColor {i} {
global PgAcVar
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,borderwidth) 1
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) flat
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) {}
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) {}
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,font) normal
    switch $PgAcVar(fdobj,$PgAcVar(fcnt),$i,class) {
        button {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #d9d9d9
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) raised
        }
        text {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #fefefe
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) sunken
        }
        entry {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #fefefe
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) sunken
        }
        label {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #d9d9d9
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) flat
        }
        checkbox {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #d9d9d9
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) flat
        }
        radio {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #d9d9d9
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) flat
        }
        listbox {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #fefefe
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) sunken
        }
        spinbox {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #fefefe
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) sunken
        }
        combobox {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #fefefe
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) sunken
        }
        tree {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #fefefe
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) sunken
        }
        subform {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #d9d9d9
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) sunken
        }
        image {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #d9d9d9
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) sunken
        }
        notebook {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) #000000
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) #d9d9d9
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) sunken
        }
    }
}; # end proc ::Forms::design:setDefaultReliefAndColor


#----------------------------------------------------------
# ::Forms::design:mouse_up
#
#   besides handling the mouse movement, adds an object if
#   it was drawn properly (big enough, on the canvas, etc.)
#   BUT this should probably be extracted into another proc
#
# Arguments:
#   x   x_coord of mouse pointer after release
#   y   y_coord of mouse pointer after release
#
# Returns:
#   none
#
# Modifies:
#   number of objects on the form, if a good object draw
#----------------------------------------------------------
#
proc ::Forms::design:mouse_up {x y} {

    global PgAcVar
    variable allwidprops

    set x [design:snap_point [expr {3*int($x/3)}]]
    set y [design:snap_point [expr {3*int($y/3)}]]
    if {$PgAcVar(fdvar,$PgAcVar(fcnt),oper)=="move"} {
        set PgAcVar(fdvar,$PgAcVar(fcnt),moveitem) {}
        set PgAcVar(fdvar,$PgAcVar(fcnt),oper) none
        set oc $PgAcVar(fdobj,$PgAcVar(fcnt),$PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj),coord)
        set dx [expr {$x-$PgAcVar(fdvar,$PgAcVar(fcnt),xstart)}]
        set dy [expr {$y-$PgAcVar(fdvar,$PgAcVar(fcnt),ystart)}]
        set newcoord [list \
            [expr {$dx+[lindex $oc 0]}] \
            [expr {$dy+[lindex $oc 1]}] \
            [expr {$dx+[lindex $oc 2]}] \
            [expr {$dy+[lindex $oc 3]}]]
        set PgAcVar(fdobj,$PgAcVar(fcnt),$PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj),coord) $newcoord
        design:show_attributes $PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj)
        design:draw_hookers $PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj)
        return
    }
    if {$PgAcVar(fdvar,$PgAcVar(fcnt),oper)=="resize"} {
        set PgAcVar(fdvar,$PgAcVar(fcnt),oper) none
        .pgaw:FormDesign:draft.c delete curdraw
        set xa $PgAcVar(fdvar,$PgAcVar(fcnt),xanch)
        set ya $PgAcVar(fdvar,$PgAcVar(fcnt),yanch)
        if {$xa>$x} {
            set x1 $x
            set x2 $xa
        } else {
            set x1 $xa
            set x2 $x
        }
        if {$ya>$y} {
            set y1 $y
            set y2 $ya
        } else {
            set y1 $ya
            set y2 $y
        }
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_left) [expr {int($x1)}]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_top) [expr {int($y1)}]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_width) [expr {int($x2-$x1)}]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_height) [expr {int($y2-$y1)}]
        design:change_coords    
        return
    }
    if {$PgAcVar(fdvar,$PgAcVar(fcnt),oper)!="draw"} return
    set PgAcVar(fdvar,$PgAcVar(fcnt),oper) none
    .pgaw:FormDesign:draft.c delete curdraw
    # Check for x2<x1 or y2<y1
    if {$x<$PgAcVar(fdvar,$PgAcVar(fcnt),xstart)} {
        set temp $x
        set x $PgAcVar(fdvar,$PgAcVar(fcnt),xstart)
        set PgAcVar(fdvar,$PgAcVar(fcnt),xstart) $temp
    }
    if {$y<$PgAcVar(fdvar,$PgAcVar(fcnt),ystart)} {
        set temp $y
        set y $PgAcVar(fdvar,$PgAcVar(fcnt),ystart)
        set PgAcVar(fdvar,$PgAcVar(fcnt),ystart) $temp
    }
    # Check for too small sizes
    set gs $PgAcVar(fdvar,$PgAcVar(fcnt),gridsize)
    if {[expr {$x-$PgAcVar(fdvar,$PgAcVar(fcnt),xstart)}] < [expr {2*$gs}]} {
        set x [expr {$PgAcVar(fdvar,$PgAcVar(fcnt),xstart) + (2*$gs)}]
    }
    if {[expr {$y-$PgAcVar(fdvar,$PgAcVar(fcnt),ystart)}] < [expr {2*$gs}]} {
        set y [expr {$PgAcVar(fdvar,$PgAcVar(fcnt),ystart) + (2*$gs)}]
    }
    incr PgAcVar(fdvar,$PgAcVar(fcnt),objnum)
    set i $PgAcVar(fdvar,$PgAcVar(fcnt),objnum)
    lappend PgAcVar(fdvar,$PgAcVar(fcnt),objlist) $i

    # set empty defaults for every possible widget property
    foreach prop $allwidprops {
        set PgAcVar(fdobj,$PgAcVar(fcnt),$i,$prop) {}
    }

    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,class) \
        $PgAcVar(fdvar,$PgAcVar(fcnt),tool)
    set newcoord [list $PgAcVar(fdvar,$PgAcVar(fcnt),xstart) \
        $PgAcVar(fdvar,$PgAcVar(fcnt),ystart) $x $y]
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,coord) $newcoord
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,name) \
        $PgAcVar(fdvar,$PgAcVar(fcnt),tool)$i
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,label) \
        $PgAcVar(fdvar,$PgAcVar(fcnt),tool)$i
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,pages) [list]

    design:setDefaultReliefAndColor $i
    
    design:draw_object $i
    design:show_attributes $i
    set PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj) $i
    design:draw_hookers $i
    set PgAcVar(fdvar,$PgAcVar(fcnt),tool) point
    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
}; # end proc ::Forms::design:mouse_up


#----------------------------------------------------------
# ::Forms::design:save --
#
#   Allows saving of forms (or saving a copy).
#
# Arguments:
#   copy_    1 to save a copy, 0 to save (default)
#
# Results:
#   0 on error, otherwise 1
#----------------------------------------------------------
#
proc ::Forms::design:save {{copy_ 0}} {
global PgAcVar CurrentDB

    if {[string length $PgAcVar(fdobj,$PgAcVar(fcnt),0,name)]==0} {
        showError \
            [intlmsg "Forms need an internal name, only literals, low case"]
        return 0
    }

    if {[string length $PgAcVar(fdvar,$PgAcVar(fcnt),formtitle)]==0} {
        showError [intlmsg "Form must have a name"]
        return 0
    }

    # there might not be any dataset vars, lets make an empty one if we have to
    if {![info exists PgAcVar(fdvar,$PgAcVar(fcnt),dsvars)]} {
        set PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) {}
    }

    # maybe there arent any data control procs
    if {![info exists PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs)]} {
        set PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs) {}
    }

    set info [list [list $PgAcVar(fdobj,$PgAcVar(fcnt),0,name) $PgAcVar(fdvar,$PgAcVar(fcnt),objnum) $PgAcVar(fdobj,$PgAcVar(fcnt),0,command) [wm geometry .pgaw:FormDesign:draft] $PgAcVar(fdobj,$PgAcVar(fcnt),0,bcolor) $PgAcVar(fdobj,$PgAcVar(fcnt),0,curse) $PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) $PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs)]]

    foreach i $PgAcVar(fdvar,$PgAcVar(fcnt),objlist) {

        # font style
        set wfont $PgAcVar(fdobj,$PgAcVar(fcnt),$i,font)
        if {[lsearch {normal bold italic fixed} $wfont] != -1} {
            set wfont [string range $wfont 0 0]
        }

        # anchor
        if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,anch)]} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,anch) center
        }
        set wanch $PgAcVar(fdobj,$PgAcVar(fcnt),$i,anch)

        # justification
        if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,just)]} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,just) left
        }
        set wjust $PgAcVar(fdobj,$PgAcVar(fcnt),$i,just)
        if {[lsearch {left right center} $wjust] != -1} {
            set wjust [string range $wjust 0 0]
        }

        # cursor
        if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,curse)] \
            ||$PgAcVar(fdobj,$PgAcVar(fcnt),$i,curse)==""} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,curse) left_ptr
        }
        set wcurse $PgAcVar(fdobj,$PgAcVar(fcnt),$i,curse)

        # editable
        if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,editable)]} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,editable) false
        }
        set weditable $PgAcVar(fdobj,$PgAcVar(fcnt),$i,editable)

        # validate
        if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,validate)]} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,validate) none
        }
        set wvalidate $PgAcVar(fdobj,$PgAcVar(fcnt),$i,validate)

        # validatecmd
        if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,validatecmd)]} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,validatecmd) {}
        }
        set wvalidatecmd $PgAcVar(fdobj,$PgAcVar(fcnt),$i,validatecmd)

        # invalidcmd
        if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,invalidcmd)]} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,invalidcmd) {}
        }
        set winvalidcmd $PgAcVar(fdobj,$PgAcVar(fcnt),$i,invalidcmd)

        # extra bindings
        if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,plusbind)]} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,plusbind) {}
        }
        set wplusbind $PgAcVar(fdobj,$PgAcVar(fcnt),$i,plusbind)

        # notebook pages
        if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,pages)]} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,pages) {}
        }
        set wpages $PgAcVar(fdobj,$PgAcVar(fcnt),$i,pages)

        lappend info [list $PgAcVar(fdobj,$PgAcVar(fcnt),$i,class) $PgAcVar(fdobj,$PgAcVar(fcnt),$i,name) $PgAcVar(fdobj,$PgAcVar(fcnt),$i,coord) [string map {\\ \\\\} $PgAcVar(fdobj,$PgAcVar(fcnt),$i,command)] $PgAcVar(fdobj,$PgAcVar(fcnt),$i,label) $PgAcVar(fdobj,$PgAcVar(fcnt),$i,variable) $PgAcVar(fdobj,$PgAcVar(fcnt),$i,value) $PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) $PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) $PgAcVar(fdobj,$PgAcVar(fcnt),$i,borderwidth) $wfont $wanch $wjust $wcurse $weditable $wvalidate $wvalidatecmd $winvalidcmd $wplusbind $wpages]

    }

    # lets do this in a transaction
    sql_exec noquiet "BEGIN TRANSACTION"

    # delete the old form if it is being saved over
    if {$copy_ == 0 && [info exists PgAcVar(fdvar,$PgAcVar(fcnt),oid)]} {
        set sql "
            DELETE
              FROM pga_forms
             WHERE oid=$PgAcVar(fdvar,$PgAcVar(fcnt),oid)"
        sql_exec noquiet $sql
    }

    regsub -all "'" $info "''" info

    # add the form as a row in the table
    set sql "
        INSERT INTO pga_forms
             VALUES ('$PgAcVar(fdvar,$PgAcVar(fcnt),formtitle)','$info')"
    if {[sql_exec noquiet $sql]} {
        sql_exec noquiet "COMMIT TRANSACTION"
    } else {
        sql_exec noquiet "ROLLBACK TRANSACTION"
    }

    # refresh the OID for the row the form is in
    set sql "
        SELECT oid
          FROM pga_forms
         WHERE formname='$PgAcVar(fdvar,$PgAcVar(fcnt),formtitle)'"
    set res [wpg_exec $CurrentDB $sql]
    set PgAcVar(fdvar,$PgAcVar(fcnt),oid) \
        [lindex [pg_result $res -getTuple 0] 0]
    pg_result $res -clear

    ::Mainlib::cmd_Forms

    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 0

    return 1

}; # end proc ::Forms::design:save


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:set_name {} {
global PgAcVar
    set i $PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj)
    foreach k $PgAcVar(fdvar,$PgAcVar(fcnt),objlist) {
        if {[info exists PgAcVar(fdobj,$PgAcVar(fcnt),$k,name)]} {
            if {($PgAcVar(fdobj,$PgAcVar(fcnt),$k,name) \
                == $PgAcVar(fdvar,$PgAcVar(fcnt),c_name)) && ($i!=$k)} {
                tk_messageBox -title [intlmsg Warning] \
                    -message [format [intlmsg "There is another object (a %s) with the same name.\nPlease change it!"] \
                    $PgAcVar(fdobj,$PgAcVar(fcnt),$k,class)]
                return
            } elseif {[string is upper \
                [string range $PgAcVar(fdvar,$PgAcVar(fcnt),c_name) 0 0]]} {
                tk_messageBox -title [intlmsg Warning] \
                -message [format [intlmsg "The first letter of the name must be Lower Case.\nPlease change the first letter!"] \
                $PgAcVar(fdobj,$PgAcVar(fcnt),$k,class)]
                return
            }
        }
    }
    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,name) \
        $PgAcVar(fdvar,$PgAcVar(fcnt),c_name)
    design:show_attributes $i
    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
}; # end proc ::Forms::design:set_name


#----------------------------------------------------------
# change the class of the object
#----------------------------------------------------------
#
proc ::Forms::design:set_class {} {
global PgAcVar
    set i $PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj)
    if {$PgAcVar(fdvar,$PgAcVar(fcnt),c_class)=="form"} {
        showError [intlmsg "You can't change the class to a form."]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_class) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$i,class)
    } elseif {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,class)]} {
        showError [intlmsg "It's a form.  You can't change it to another class."]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_class) form
    } elseif {[lsearch \
        {entry label listbox spinbox combobox button text radio checkbox query tree subform image table notebook} \
        $PgAcVar(fdvar,$PgAcVar(fcnt),c_class)] != -1} {
        set PgAcVar(fdobj,$PgAcVar(fcnt),$i,class) \
            $PgAcVar(fdvar,$PgAcVar(fcnt),c_class)
        design:draw_object $i
        set PgAcVar(fdvar,$PgAcVar(fcnt),attributeFrame) ""
        design:show_attributes $i
        set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
    } else {
        showError [intlmsg "That is not a valid object class.\nLook at the Toolbar."]
    }    
}; # end proc ::Forms::design:set_class


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:set_text {} {
global PgAcVar
    design:draw_object $PgAcVar(fdvar,$PgAcVar(fcnt),moveitemobj)
    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
}


#----------------------------------------------------------
# ::Functions::design:change_tab_order --
#
#   modifies tab order, for drag-and-drop
#
# Arguments:
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Forms::design:change_tab_order {lbpath_ srcpath_ wherel_ oper_ datatype_ data_} {

    global PgAcVar
    variable allwidprops

    set W $lbpath_
    # what is moving
    set orig [$W selection get]
    set opos [$W index $orig]
    # where it is moving to
    set dest 0
    set dpos [lindex $wherel_ end]

    # no sense doing any work if there isnt any movement
    if {$orig!="" && $dpos!=$opos} {
        # actually set the destination position
        if {$dpos<$opos} {
            set dest [$W items $dpos]
        } else {
            set dest [$W items [expr {$dpos-1}]]
        }
        set sel_curr $orig
        set sel_all [$W items]
        set sel_to $dest
        $W delete [$W items]
        set sa [lsearch $sel_all $sel_curr]
        set sc 0
        set sn 0
        # we find the items to move by name since they are unique names
        foreach i $PgAcVar(fdvar,$PgAcVar(fcnt),objlist) {
            if {[string match $sel_curr \
            $PgAcVar(fdobj,$PgAcVar(fcnt),$i,name)] == 1} {
                set sc $i
            } elseif {[string match $sel_to \
                $PgAcVar(fdobj,$PgAcVar(fcnt),$i,name)] == 1} {
                set sn $i
            }
        }
        # keep re-arranging items until they are in the right places
        while {$sc!=$sn} {
            if {[info exists PgAcVar(fdobj,$PgAcVar(fcnt),$sn,class)] \
            && [info exists PgAcVar(fdobj,$PgAcVar(fcnt),$sc,class)] \
            && [lsearch \
            {button checkbox radio listbox spinbox combobox entry tree subform image notebook} \
            $PgAcVar(fdobj,$PgAcVar(fcnt),$sn,class)] > -1} { 
                foreach prop $allwidprops {
                    # swap the items here
                    set t ""
                    if {[info exists PgAcVar(fdobj,$PgAcVar(fcnt),$sc,$prop)]} {
                        set t $PgAcVar(fdobj,$PgAcVar(fcnt),$sc,$prop)
                    } else {
                        showError [intlmsg "There is a problem with the structural integrity of the form."]
                        puts $PgAcVar(fdobj,$PgAcVar(fcnt),$sc,$prop)
                        return
                    }
                    if {[info exists PgAcVar(fdobj,$PgAcVar(fcnt),$sn,$prop)]} {
                        set PgAcVar(fdobj,$PgAcVar(fcnt),$sc,$prop) \
                            $PgAcVar(fdobj,$PgAcVar(fcnt),$sn,$prop)
                    } else {
                        showError [intlmsg "There is a problem with the structural integrity of the form."]
                        puts $PgAcVar(fdobj,$PgAcVar(fcnt),$sn,$prop)
                        return
                    }
                    set PgAcVar(fdobj,$PgAcVar(fcnt),$sn,$prop) $t
                }
            }
            # make sure we either keep moving stuff up OR down
            if {$sn<$sc} {
                incr sn
            } else {
                incr sn -1
            }
        }
        # finally refresh and redraw the items
        $W delete [$W items]
        foreach j $PgAcVar(fdvar,$PgAcVar(fcnt),objlist) {
            if {[lsearch {button checkbox radio listbox spinbox combobox entry tree subform image notebook} $PgAcVar(fdobj,$PgAcVar(fcnt),$j,class)] > -1} { 
                $W insert end $PgAcVar(fdobj,$PgAcVar(fcnt),$j,name) \
                    -text $PgAcVar(fdobj,$PgAcVar(fcnt),$j,name) \
                    -image [::Forms::design:getIcon $PgAcVar(fdobj,$PgAcVar(fcnt),$j,class)]
                design:draw_object $j
            }
        }
        set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
    }
}; # end proc ::Forms::design:change_tab_order


#----------------------------------------------------------
# ::Forms::design:getIcon --
#
#   retrieves the icon for a widget, based on its class name
#
# Arguments:
#   class_  class name of a widget (entry, button, etc.)
#
# Returns:
#   the data for the icon
#----------------------------------------------------------
#
proc ::Forms::design:getIcon {class_} {

    global PgAcVar

    set _icon ""

    if {[lsearch {subform image notebook radio checkbox} $class_]==-1} {
        set _icon [image create photo "icon_$class_" \
            -file [file join $PgAcVar(PGACCESS_HOME) images icon_$class_.gif]]
    }

    # there are lots of exceptions :(

    if {$class_=="radio"} {
        set _icon [image create photo "icon_radiobutton" \
            -file [file join $PgAcVar(PGACCESS_HOME) images icon_radiobutton.gif]]
    }

    if {$class_=="checkbox"} {
        set _icon [image create photo "icon_checkbutton" \
            -file [file join $PgAcVar(PGACCESS_HOME) images icon_checkbutton.gif]]
    }

    if {$class_=="subform"} {
        set _icon $::Mainlib::img(Forms)
    }

    if {$class_=="image"} {
        set _icon $::Mainlib::img(Images)
    }

    if {$class_=="notebook"} {
        set _icon ::icon::contents-16
    }

    return $_icon

}; # end proc ::Forms::design:getIcon


#----------------------------------------------------------
# ::Forms::design:change_notebookpage --
#
#   actually handles all aspects of
#   adding/deleting/modifying a page in the notebook
#   (everything except ordering)
#
# Arguments:
#   item_   for which item to add the page
#   oper_   what operation (add 1, delete -1, nothing 0)
#
# Returns:
#   nonee
#----------------------------------------------------------
#
proc ::Forms::design:change_notebookpage {item_ oper_ {xtra_ ""}} {

    global PgAcVar
    variable Win

    if {$oper_==0} {
        set curpage [$Win(notebookpages) selection get]
        set PgAcVar(fdobj,$PgAcVar(fcnt),$item_,curpagetit) \
            [$Win(notebookpages) itemcget $curpage -text]
        set PgAcVar(fdobj,$PgAcVar(fcnt),$item_,curpagefrm) \
            [$Win(notebookpages) itemcget $curpage -data]
    } else {
        set curpagetit $PgAcVar(fdobj,$PgAcVar(fcnt),$item_,curpagetit)
        set curpagefrm $PgAcVar(fdobj,$PgAcVar(fcnt),$item_,curpagefrm)
        set curpage [list $curpagetit $curpagefrm]
        if {$oper_==1} {
            $Win(notebookpages) insert end $curpagetit \
                -text $curpagetit \
                -data $curpagefrm \
                -image [::Forms::design:getIcon notebook]
            lappend PgAcVar(fdobj,$PgAcVar(fcnt),$item_,pages) $curpage
        } else {
            $Win(notebookpages) delete [list $curpagetit]
            set lst $PgAcVar(fdobj,$PgAcVar(fcnt),$item_,pages)
            set idx 0
            foreach i $lst {
                set tit [lindex $i 0]
                if {$tit==$curpagetit} {
                    break
                }
                incr idx
            }
            set lst [lreplace $lst $idx $idx]
            set PgAcVar(fdobj,$PgAcVar(fcnt),$item_,pages) $lst
            set PgAcVar(fdobj,$PgAcVar(fcnt),$item_,curpagetit) ""
            set PgAcVar(fdobj,$PgAcVar(fcnt),$item_,curpagefrm) ""
        }
    }

    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1

}; # end proc ::Forms::design:change_notebookpage


#----------------------------------------------------------
# ::Functions::design:change_notebookpage_order --
#
#   modifies order of pages in the notebook form widget
#   for drag-and-drop
#
# Arguments:
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Forms::design:change_notebookpage_order {lbpath_ srcpath_ wherel_ oper_ datatype_ data_} {

}; # end proc ::Forms::design:change_notebookpage_order


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:createAttributesFrame {i} {

    global PgAcVar
    variable Win

    # Check if attributes frame is already created for that item
    
    if {[info exists PgAcVar(fdvar,$PgAcVar(fcnt),attributeFrame)]} {
        if {$PgAcVar(fdvar,$PgAcVar(fcnt),attributeFrame) == $i} return
    }
    set PgAcVar(fdvar,$PgAcVar(fcnt),attributeFrame) $i
    
    # Delete old widgets from the frame
    foreach wid [winfo children .pgaw:FormDesign:attributes.f] {
        destroy $wid
    }

    set row 0
    set base .pgaw:FormDesign:attributes.f
    grid columnconf $base 1 -weight 1

    set objclass $PgAcVar(fdobj,$PgAcVar(fcnt),$i,class)

    # does it have a startup script ?
    if {[lsearch {form} $objclass] > -1} {
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg {Startup script}]
        entry $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,command) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200
        Button $base.b$row \
            -helptext [intlmsg {Edit Startup Script}] \
            -image ::icon::go-16 \
            -borderwidth 1 -padx 1 -pady 0 -command "
                Window show .pgaw:FormDesign:commands
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandFor) $i
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandType) command
                .pgaw:FormDesign:commands.f.txt delete 1.0 end
                .pgaw:FormDesign:commands.f.txt insert end \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,command)
                Syntax::highlight .pgaw:FormDesign:commands.f.txt tcl"
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -padx 2
        grid $base.b$row \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1
        incr row
    }

    # can its tab order be changed ?
    if {[lsearch {form} $objclass] > -1} {
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg {Tab order}]
        label $base.ll$row \
            -borderwidth 0 \
            -text [intlmsg {Drag N Drop}]
        ListBox $base.lb$row \
            -dragenabled 1 \
            -dropenabled 1 \
            -dropovermode p \
            -droptypes {LISTBOX_ITEM {move}} \
            -dropcmd ::Forms::design:change_tab_order \
            -bg #fefefe \
            -borderwidth 1 \
            -height 9 \
            -yscrollcommand [subst {$base.sb$row set}] \
            -selectmode single
        scrollbar $base.sb$row \
            -borderwidth 1 \
            -orient vert \
            -highlightthickness 0 \
            -command [subst {$base.lb$row yview}]
        grid $base.l$row \
            -in $base \
            -column 0 \
            -row $row \
            -sticky s
        grid $base.ll$row \
            -in $base \
            -column 0 \
            -row [expr {$row+1}] \
            -sticky n
        grid $base.lb$row \
            -in $base \
            -column 1 \
            -row $row \
            -columnspan 2 \
            -rowspan 2 \
            -padx 2 \
            -sticky news
        grid $base.sb$row \
            -in $base \
            -column 3 \
            -row $row \
            -sticky ns \
            -rowspan 2
        $base.lb$row delete 0 end
        foreach j $PgAcVar(fdvar,$PgAcVar(fcnt),objlist) {
            if {[lsearch {button checkbox radio listbox spinbox combobox entry tree subform image notebook} $PgAcVar(fdobj,$PgAcVar(fcnt),$j,class)] > -1} { 
                $base.lb$row insert end $PgAcVar(fdobj,$PgAcVar(fcnt),$j,name) \
                    -text $PgAcVar(fdobj,$PgAcVar(fcnt),$j,name) \
                    -image [::Forms::design:getIcon $PgAcVar(fdobj,$PgAcVar(fcnt),$j,class)]
            }
        }
        incr row 2
    }

    # is it a notebook ?
    if {$objclass=="notebook"} {
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg "Page title"]
        entry $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,curpagetit) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200
        Button $base.b$row \
            -helptext [intlmsg "Add Page"] \
            -image ::icon::hotlistadd-16 \
            -borderwidth 1 \
            -command "::Forms::design:change_notebookpage $i 1"
        grid $base.l$row \
            -column 0 \
            -row $row
        grid $base.e$row \
            -column 1 \
            -row $row \
            -columnspan 2 \
            -padx 2
        grid $base.b$row \
            -column 3 \
            -row $row
        incr row
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg "Page form"]
        ComboBox $base.cb$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,curpagefrm) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200 \
            -values [::Database::getObjectsList forms] \
            -editable false \
            -modifycmd {set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1}
        Button $base.b$row \
            -helptext [intlmsg "Delete Page"] \
            -image ::icon::hotlistdel-16 \
            -borderwidth 1 \
            -command "::Forms::design:change_notebookpage $i -1"
        grid $base.l$row \
            -column 0 \
            -row $row
        grid $base.cb$row \
            -column 1 \
            -row $row \
            -columnspan 2 \
            -padx 2
        grid $base.b$row \
            -column 3 \
            -row $row
        incr row
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg "Page order"]
        label $base.ll$row \
            -borderwidth 0 \
            -text [intlmsg ""]
        set Win(notebookpages) $base.lb$row
        ListBox $base.lb$row \
            -bg #fefefe \
            -borderwidth 1 \
            -height 9 \
            -yscrollcommand [subst {$base.sb$row set}] \
            -selectmode single
        scrollbar $base.sb$row \
            -borderwidth 1 \
            -orient vert \
            -highlightthickness 0 \
            -command [subst {$base.lb$row yview}]
        grid $base.l$row \
            -in $base \
            -column 0 \
            -row $row \
            -sticky s
        grid $base.ll$row \
            -in $base \
            -column 0 \
            -row [expr {$row+1}] \
            -sticky n
        grid $base.lb$row \
            -in $base \
            -column 1 \
            -row $row \
            -columnspan 2 \
            -rowspan 2 \
            -padx 2 \
            -sticky news
        grid $base.sb$row \
            -in $base \
            -column 3 \
            -row $row \
            -sticky ns \
            -rowspan 2
        $base.lb$row delete 0 end
        foreach j $PgAcVar(fdobj,$PgAcVar(fcnt),$i,pages) {
            $base.lb$row insert end [lindex $j 0] \
                -text [lindex $j 0] \
                -data [lindex $j 1] \
                -image [::Forms::design:getIcon notebook]
        }
        $base.lb$row bindText \
            <ButtonRelease-1> "::Forms::design:change_notebookpage $i 0"
        incr row 2
    }

    # is it a subform ?
    if {$objclass == "subform"} {
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg "Form"]
        ComboBox $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,command) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200 \
            -values [::Database::getObjectsList forms] \
            -editable false \
            -modifycmd {set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1}
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -padx 2
        incr row
    }

    # does it have a text attribute ?
    if {[lsearch {button label radio checkbox image} $objclass] > -1} {
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg Text]
        entry $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,label) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200
        bind $base.e$row <Key-Return> "Forms::design:set_text"
        Button $base.b$row \
            -helptext [intlmsg {Edit Text}] \
            -image ::icon::edit-16 \
            -borderwidth 1 \
            -padx 1 \
            -pady 0 \
            -command "
                Window show .pgaw:FormDesign:commands
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandFor) $i
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandType) label
                .pgaw:FormDesign:commands.f.txt delete 1.0 end
                .pgaw:FormDesign:commands.f.txt insert end \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,label)"
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -padx 2
        grid $base.b$row \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1 
        incr row
    }

    # does it have a variable attribute that can be updated ?
    if {[lsearch {radio checkbox entry listbox combobox spinbox} $objclass] > -1} {
        # allow for easy selection of dataset vars
        # they come from pseudo-widgets
        set dsvars {}
        catch {set dsvars $PgAcVar(fdvar,$PgAcVar(fcnt),dsvars)}
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg Variable]
        ComboBox $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,variable) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200 \
            -values $dsvars \
            -editable true \
            -modifycmd "::Forms::tableBindingMagic $PgAcVar(fcnt) $i"
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -padx 2
        incr row
    }

    # does it have a variable attribute that is immutable ?
    if {[lsearch {button label image} $objclass] > -1} {
        # allow for easy selection of dataset vars
        # they come from pseudo-widgets
        set dsvars {}
        catch {set dsvars $PgAcVar(fdvar,$PgAcVar(fcnt),dsvars)}
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg Variable]
        ComboBox $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,variable) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200 \
            -values $dsvars \
            -editable true \
            -modifycmd {set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1}
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -padx 2
        incr row
    }

    # does it have a Command attribute ?
    if {[lsearch {button checkbox combobox spinbox radio tree} $objclass] > -1} {
        set dcprocs {}
        catch {set dcprocs $PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs)}
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg Command]
        ComboBox $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,command) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200 \
            -values $dcprocs \
            -editable true \
            -modifycmd {set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1}
        Button $base.b$row \
            -helptext [intlmsg {Edit Command}] \
            -image ::icon::go-16 \
            -borderwidth 1 \
            -padx 1 \
            -pady 0 \
            -command "
                Window show .pgaw:FormDesign:commands
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandFor) $i
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandType) command
                .pgaw:FormDesign:commands.f.txt delete 1.0 end
                .pgaw:FormDesign:commands.f.txt insert end \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,command)
                Syntax::highlight .pgaw:FormDesign:commands.f.txt tcl"
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -padx 2
        grid $base.b$row \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1 
        incr row
    }

    # does it have a value attribute ?
    if {[lsearch {radio checkbox} $objclass] > -1} {
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg Value]
        entry $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,value) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -padx 2
        incr row
    }

    # can its default editability be changed ?
    # for the combobox, this allows dropbox functionality
    # spinbox not really sure
    if {[lsearch {combobox spinbox} $objclass] > -1} {
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg Editable]
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        entry $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,editable) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 \
            -padx 2
        menubutton $base.mbed \
            -borderwidth 1 \
            -menu $base.mbed.m \
            -padx 2 \
            -pady 0 \
            -image ::icon::news-16
        menu $base.mbed.m \
            -borderwidth 1 \
            -cursor {} \
            -tearoff 0 \
            -font $PgAcVar(pref,font_normal)
        foreach tf {true false} {
            $base.mbed.m add command \
                -label $tf \
                -command "
                    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,editable) $tf
                    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
                "
        }
        grid $base.mbed \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1 \
            -pady 2 -padx 2
        incr row
    }

    # does it have extra bindings we need to worry about ?
    # this helps make automagic updates with the pseudo-table widget
    if {[lsearch {button entry listbox spinbox combobox text checkbox radio tree} $objclass] > -1} {
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg "Plus Bind"]
        ComboBox $base.cb$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,plusbindcombo) \
            -background #fefefe \
            -borderwidth 1 \
            -values {Activate ButtonPress ButtonRelease Circulate Colormap Configure Deactivate Destroy Enter Expose FocusIn FocusOut Gravity KeyPress KeyRelease Leave Map Motion MouseWheel Property Reparent Unmap Visibility} \
            -editable false \
            -modifycmd {set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1}
        Entry $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,plusbind) \
            -background #fefefe \
            -borderwidth 1
        Button $base.b$row \
            -helptext [intlmsg {Edit Bind Commands}] \
            -image ::icon::key_bindings-16 \
            -borderwidth 1 \
            -padx 1 \
            -pady 0 \
            -command "
                Window show .pgaw:FormDesign:commands
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandFor) $i
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandType) plusbind
                .pgaw:FormDesign:commands.f.txt delete 1.0 end
                .pgaw:FormDesign:commands.f.txt insert end \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,plusbind)
                .pgaw:FormDesign:commands.f.txt tag delete fndbind
                set fnd \[.pgaw:FormDesign:commands.f.txt search \
                    \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,plusbindcombo) 1.0\]
                if {\[string length \$fnd\]==0} {
                    .pgaw:FormDesign:commands.f.txt insert end \"

# \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,plusbindcombo)
bind .\$PgAcVar(fdobj,$PgAcVar(fcnt),0,name).\$PgAcVar(fdobj,$PgAcVar(fcnt),$i,name) <\$PgAcVar(fdobj,$PgAcVar(fcnt),$i,plusbindcombo)> {

}\"
                    set fnd \[.pgaw:FormDesign:commands.f.txt search \
                        \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,plusbindcombo) 1.0\]
                }
                set fnd2 \[.pgaw:FormDesign:commands.f.txt search \"\}\" \$fnd\]
                if {\[string length \$fnd2\]>0} {
                    set fnd2 \[expr {0.1+\$fnd2}\]
                    .pgaw:FormDesign:commands.f.txt tag add fndbind \$fnd \$fnd2
                    .pgaw:FormDesign:commands.f.txt tag configure fndbind \
                        -background #ffff00
                    .pgaw:FormDesign:commands.f.txt see \$fnd
                }
                Syntax::highlight .pgaw:FormDesign:commands.f.txt tcl"
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 1 -rowspan 1 \
            -padx 2
        grid $base.cb$row \
            -in $base -column 2 -row $row -columnspan 1 -rowspan 1 \
            -padx 2
        grid $base.b$row \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1 \
            -pady 2 -padx 2
        incr row
    }

    # does it have a validate command ?
    if {[lsearch {entry} $objclass] > -1} {
        # when should validity be checked...
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg Validation]
        ComboBox $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,validate) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200 \
            -values {none focus focusin focusout key all} \
            -editable false \
            -modifycmd {set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1}
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 \
            -padx 2
        incr row
        # the validation command itself
        # heres some pre-made ones
        set valcmds {}
        lappend valcmds {string is integer %S}
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg "Validate Cmd"]
        ComboBox $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,validatecmd) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200 \
            -values $valcmds \
            -editable true \
            -modifycmd {set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1}
        Button $base.b$row \
            -helptext [intlmsg {Edit Validate Command}] \
            -image ::icon::spellcheck-16 \
            -borderwidth 1 \
            -padx 1 \
            -pady 0 \
            -command "
                Window show .pgaw:FormDesign:commands
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandFor) $i
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandType) command
                .pgaw:FormDesign:commands.f.txt delete 1.0 end
                .pgaw:FormDesign:commands.f.txt insert end \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,validatecmd)
                Syntax::highlight .pgaw:FormDesign:commands.f.txt tcl"
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 \
            -padx 2
        grid $base.b$row \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1 
        incr row
        # command to run on invalid entry
        # pre-made popup
        set invalcmds {}
        lappend invalcmds {tk_messageBox -title Oops -icon error -message "That value is invalid."}
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg "Invalid Cmd"]
        ComboBox $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,invalidcmd) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200 \
            -values $invalcmds \
            -editable true \
            -modifycmd {set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1}
        Button $base.b$row \
            -helptext [intlmsg {Edit Invalid Command}] \
            -image ::icon::stop-16 \
            -borderwidth 1 \
            -padx 1 \
            -pady 0 \
            -command "
                Window show .pgaw:FormDesign:commands
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandFor) $i
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandType) command
                .pgaw:FormDesign:commands.f.txt delete 1.0 end
                .pgaw:FormDesign:commands.f.txt insert end \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,invalidcmd)
                Syntax::highlight .pgaw:FormDesign:commands.f.txt tcl"
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 \
            -padx 2
        grid $base.b$row \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1 
        incr row
    }

    # does it have fonts ?
    if {[lsearch {label button entry listbox spinbox combobox text checkbox radio tree image notebook} $objclass] > -1} {
        label $base.lfont \
            -borderwidth 0 \
            -text [intlmsg Font]
        grid $base.lfont \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1 \
            -pady 2
        entry $base.efont \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,font) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200
        bind $base.efont <Key-Return> "Forms::design:draw_object $i ; set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1"
        grid $base.efont \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 \
            -padx 2
        Button $base.bf \
            -borderwidth 1 \
            -padx 1 \
            -pady 0 \
            -helptext [intlmsg {Select Font}] \
            -image ::icon::font_truetype-16 \
            -command "
                set new_font \[SelectFont .formfontdlg -parent .pgaw:FormDesign:attributes.f -font \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,font) -title \"Select Font\"\]
                if {\[string length \$new_font\]!=0} {
                    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,font) \$new_font
                    Forms::design:draw_object $i
                    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
                }"
        grid $base.bf \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1 \
            -pady 2 -padx 2
        incr row
    }

    # does it have anchors ?
    if {[lsearch {label button checkbox radio image} $objclass] > -1} {
        label $base.lanch \
            -borderwidth 0 \
            -text [intlmsg Anchor]
        grid $base.lanch \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1 \
            -pady 2
        entry $base.eanch \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,anch) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200
        bind $base.eanch <Key-Return> "Forms::design:draw_object $i ; set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1"
        grid $base.eanch \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -padx 2
        menubutton $base.mba \
            -borderwidth 1 \
            -menu $base.mba.m \
            -padx 2 \
            -pady 0 \
            -image ::icon::view_icon-16
        menu $base.mba.m \
            -borderwidth 1 \
            -cursor {} \
            -tearoff 0 \
            -font $PgAcVar(pref,font_normal)
        foreach anch {center nw w sw s se e ne n} {
            $base.mba.m add command \
                -label $anch \
                -command "
                    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,anch) $anch
                    Forms::design:draw_object $i
                    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
                "
        }
        grid $base.mba \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1 -pady 2 -padx 2
        incr row
    }
    
    # does it have justification ?
    if {[lsearch {label text button checkbox radio entry combobox spinbox image} $objclass] > -1} {
        label $base.ljust \
            -borderwidth 0 \
            -text [intlmsg Justify]
        grid $base.ljust \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1 \
            -pady 2
        entry $base.ejust \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,just) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200
        bind $base.ejust <Key-Return> "Forms::design:draw_object $i ; set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1"
        grid $base.ejust \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 \
            -padx 2
        menubutton $base.mbj \
            -borderwidth 1 \
            -menu $base.mbj.m \
            -padx 2 \
            -pady 0 \
            -image ::icon::view_text-16
        menu $base.mbj.m \
            -borderwidth 1 \
            -cursor {} \
            -tearoff 0 \
            -font $PgAcVar(pref,font_normal)
        foreach just {left right center} {
            $base.mbj.m add command \
                -label $just \
                -command "
                    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,just) $just
                    Forms::design:draw_object $i
                    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
                "
        }
        grid $base.mbj \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1 \
            -pady 2 -padx 2
        incr row
    }

    # does it have foreground colors ?
    if {[lsearch {label button radio checkbox entry listbox spinbox combobox text tree} $objclass] > -1} {
        # set a default if no color
        if {$PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor)==""} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) "#d9d9d9"
        }
        label $base.lcf \
            -borderwidth 0 \
            -text [intlmsg Foreground]
        label $base.scf \
            -background $PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) \
            -borderwidth 1 \
            -relief sunken
        Entry $base.ecf \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) \
            -background #fefefe \
            -borderwidth 1 \
            -command "
                    $base.scf configure -background \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor)
                    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
                    Forms::design:draw_object $i"
        Button $base.bcf \
            -command "set tempcolor \[SelectColor .colordlg -color $PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) -title \[intlmsg {Select Foreground Color}\] -parent .pgaw:FormDesign:attributes\]
                if {\$tempcolor != {}} {
                    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor) \$tempcolor
                    $base.scf configure -background \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,fcolor)
                    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
                    Forms::design:draw_object $i
                }" \
            -image ::icon::colorize-16 \
            -helptext [intlmsg {Select Foreground Color}] \
            -borderwidth 1 \
            -padx 1 \
            -pady 0
        grid $base.lcf \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.scf \
            -in $base -column 1 -row $row -columnspan 1 -rowspan 1 -padx 2 \
            -sticky news
        grid $base.ecf \
            -in $base -column 2 -row $row -columnspan 1 -rowspan 1
        grid $base.bcf \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1 
        incr row
    }

    # does it have background colors ?
    if {[lsearch {label button radio checkbox entry listbox spinbox combobox text form tree notebook image} $objclass] > -1} {
        # set a default if no color
        if {$PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor)==""} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) "#d9d9d9"
        }
        label $base.lcb \
            -borderwidth 0 \
            -text [intlmsg "Background"]
        label $base.scb \
            -background $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) \
            -borderwidth 1 \
            -relief sunken
        Entry $base.ecb \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) \
            -background #fefefe \
            -borderwidth 1 \
            -command "
                    $base.scb configure \
                        -background \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor)
                    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
                    Forms::design:draw_object $i"
        Button $base.bcb \
            -command "
                set tempcolor \[SelectColor .colordlg \
                    -color $PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) \
                    -title \[intlmsg {Select Background Color}\] \
                    -parent .pgaw:FormDesign:attributes\]
                if {\$tempcolor != {}} {
                    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor) \$tempcolor
                    $base.scb configure \
                        -background \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,bcolor)
                    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
                    Forms::design:draw_object $i
                }" \
            -image ::icon::colorize-16 \
            -helptext [intlmsg {Select Background Color}] \
            -borderwidth 1 \
            -padx 1 \
            -pady 0
        grid $base.lcb \
            -in $base \
            -column 0 \
            -row $row
        grid $base.scb \
            -in $base \
            -column 1 \
            -row $row \
            -padx 2 \
            -sticky news
        grid $base.ecb \
            -in $base \
            -column 2 \
            -row $row \
            -sticky news
        grid $base.bcb \
            -in $base \
            -column 3 \
            -row $row \
            -columnspan 1 \
            -rowspan 1
        grid columnconfigure $base 1 \
            -weight 10
        grid columnconfigure $base 2 \
            -weight 10
        incr row
    }

    # does it have border types ?
    if {[lsearch {label button entry listbox spinbox combobox text tree subform image} $objclass] > -1} {
        label $base.lrelief \
            -borderwidth 0 \
            -text [intlmsg Relief]
        grid $base.lrelief \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1 \
            -pady 2
        menubutton $base.mb \
            -borderwidth 2 \
            -menu $base.mb.m \
            -padx 4 \
            -pady 3 \
            -width 100 \
            -relief $PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) \
            -text groove \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) \
            -font $PgAcVar(pref,font_normal)
        menu $base.mb.m \
            -borderwidth 1 \
            -cursor {} \
            -tearoff 0 \
            -font $PgAcVar(pref,font_normal)
        foreach brdtype {raised sunken ridge groove flat} {
            $base.mb.m add command \
                -label $brdtype \
                -command "
                    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief) $brdtype
                    $base.mb configure -relief \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,relief)
                    Forms::design:draw_object $i
                "
        }
        grid $base.mb \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 \
            -pady 2 -padx 2
        incr row

    }

    # is it a DataControl, of the table variety ?
    if {$objclass == "table"} {
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg "Table"]
        ComboBox $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,command) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200 \
            -values [::Database::getTablesList] \
            -editable true \
            -modifycmd {set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1}
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -padx 2
        incr row
        button $base.b$row \
            -borderwidth 1 \
            -padx 2 \
            -pady 2 \
            -text [intlmsg "Update DataSet Variables"] \
            -command "
                set PgAcVar(fdobj,$PgAcVar(fcnt),$i,dsvars) {}
                set qryname \"DataSet(.$PgAcVar(fdobj,$PgAcVar(fcnt),0,name).\$PgAcVar(fdobj,$PgAcVar(fcnt),$i,name)\"
                set newds \$PgAcVar(fdvar,$PgAcVar(fcnt),dsvars)
                for {set c 0} {\$c<\[llength \$newds\]} {incr c} {
                    set pos \[lsearch -glob \$newds \$qryname*\]
                    if {\$pos!=-1} {
                        set PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) \[lreplace \$newds \$pos \$pos\]
                    }
                }
                foreach fld \[::Database::getColumnsList \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,command)\] {
                    set nextds \"\$qryname,\$fld)\"
                    if {\[lsearch \$PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) \$nextds\] == -1 } {
                        lappend PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) \$nextds
                    }
                    lappend PgAcVar(fdobj,$PgAcVar(fcnt),$i,dsvars) \$nextds
                }
                if {!\[info exists PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs)\]} {
                    set PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs) \[list\]
                }
                foreach prok {moveFirst moveLast moveNext movePrevious updateDataSet clearDataSet open close} {
                    set prokk \"::DataControl(.$PgAcVar(fdobj,$PgAcVar(fcnt),0,name).\$PgAcVar(fdobj,$PgAcVar(fcnt),$i,name))::\$prok\"
                    set prokkk \"::DataControl(.$PgAcVar(fdobj,$PgAcVar(fcnt),0,name).\$PgAcVar(fdobj,$PgAcVar(fcnt),$i,name))::updateDataSet\"
                    if {\[lsearch \$PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs) \$prokk\] == -1 } {
                        lappend PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs) \"\$prokk\;\$prokkk\"
                    }
                }"
        grid $base.b$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -sticky nsew
        incr row
    }

    # is it a DataControl, of the query variety ?
    if {$objclass == "query"} {
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg SQL]
        ComboBox $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,command) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200 \
            -values [Queries::getQueriesList S] \
            -editable true \
            -modifycmd {set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1}
        Button $base.b$row \
            -helptext [intlmsg {Edit SQL}] \
            -image ::icon::edit-16 \
            -borderwidth 1 \
            -padx 1 \
            -pady 0 \
            -command "
                Window show .pgaw:FormDesign:commands
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandFor) $i
                set PgAcVar(fdvar,$PgAcVar(fcnt),commandType) command
                .pgaw:FormDesign:commands.f.txt delete 1.0 end
                .pgaw:FormDesign:commands.f.txt insert end \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,command)
                Syntax::highlight .pgaw:FormDesign:commands.f.txt sql"
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -padx 2
        grid $base.b$row \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1
        incr row
        # allow for variable drop downs in other widgets to be filled
            #    if {![info exists PgAcVar(fdvar,$PgAcVar(fcnt),dsvars)]} {
            #        set PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) {}
            #    }
        button $base.b$row \
            -borderwidth 1 \
            -padx 2 \
            -pady 2 \
            -text [intlmsg "Update DataSet Variables"] \
            -command "
                set PgAcVar(fdobj,$PgAcVar(fcnt),$i,dsvars) {}
                set qryname \"DataSet(.$PgAcVar(fdobj,$PgAcVar(fcnt),0,name).\$PgAcVar(fdobj,$PgAcVar(fcnt),$i,name)\"
                set newds \$PgAcVar(fdvar,$PgAcVar(fcnt),dsvars)
                for {set c 0} {\$c<\[llength \$newds\]} {incr c} {
                    set pos \[lsearch -glob \$newds \$qryname*\]
                    if {\$pos!=-1} {
                        set PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) \[lreplace \$newds \$pos \$pos\]
                    }
                }
                foreach fld \[Queries::getFieldList \$PgAcVar(fdobj,$PgAcVar(fcnt),$i,command)\] {
                    set nextds \"\$qryname,\$fld)\"
                    if {\[lsearch \$PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) \$nextds\] == -1 } {
                        lappend PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) \$nextds
                    }
                    lappend PgAcVar(fdobj,$PgAcVar(fcnt),$i,dsvars) \$nextds
                }
                if {!\[info exists PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs)\]} {
                    set PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs) \[list\]
                }
                foreach prok {moveFirst moveLast moveNext movePrevious updateDataSet clearDataSet open close} {
                    set prokk \"::DataControl(.$PgAcVar(fdobj,$PgAcVar(fcnt),0,name).\$PgAcVar(fdobj,$PgAcVar(fcnt),$i,name))::\$prok\"
                    if {\[lsearch \$PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs) \$prokk\] == -1 } {
                        lappend PgAcVar(fdvar,$PgAcVar(fcnt),dcprocs) \$prokk
                    }
                }"
        grid $base.b$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -sticky nsew
        incr row
    }

    # items common to DataControl widgets
    if {$objclass == "query" || $objclass == "table"} {
        # show all the data set vars available
        # soon we will allow drag-n-drop
        listbox $base.lb$row \
            -bg #fefefe \
            -borderwidth 1 \
            -width 15 \
            -height 9 \
            -yscrollcommand [subst {$base.sb$row set}] \
            -selectmode single \
            -listvar PgAcVar(fdobj,$PgAcVar(fcnt),$i,dsvars)
        scrollbar $base.sb$row \
            -borderwidth 1 \
            -orient vert \
            -highlightthickness 0 \
            -width 10 \
            -command [subst {$base.lb$row yview}]
        grid $base.lb$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 2 \
            -padx 2 -sticky nsew
        grid $base.sb$row \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 2 -sticky nsew
        # make sure we can see the dataset vars for this table
        if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$i,dsvars)]||[llength $PgAcVar(fdobj,$PgAcVar(fcnt),$i,dsvars)]==0} {
            set PgAcVar(fdobj,$PgAcVar(fcnt),$i,dsvars) {}
            set qryname "DataSet(.$PgAcVar(fdobj,$PgAcVar(fcnt),0,name).$PgAcVar(fdobj,$PgAcVar(fcnt),$i,name)"
            # make sure we can see the dataset vars for the whole form
            if {![info exists PgAcVar(fdvar,$PgAcVar(fcnt),dsvars)]} {
                set PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) {}
            }
            for {set c 0} {$c<[llength $PgAcVar(fdvar,$PgAcVar(fcnt),dsvars)]} {incr c} {
                if {[string match $qryname* [lindex $PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) $c]]} {
                    lappend PgAcVar(fdobj,$PgAcVar(fcnt),$i,dsvars) [lindex $PgAcVar(fdvar,$PgAcVar(fcnt),dsvars) $c]
                }
            }
        }
        incr row 2
    }

    # does it have a borderwidth attribute ?
    if {[lsearch {button label radio checkbox entry listbox spinbox combobox text tree subform image notebook} $objclass] > -1} {
        label $base.l$row \
            -borderwidth 0 \
            -text [intlmsg {Border width}]
        entry $base.e$row \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,borderwidth) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200
        grid $base.l$row \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.e$row \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 -padx 2
        incr row
    }

    # does it have a cursor ?
    if {[lsearch {button label radio checkbox entry listbox text form image} $objclass] > -1} {
        label $base.lcurse \
            -borderwidth 0 \
            -text [intlmsg Cursor]
        grid $base.lcurse \
            -in $base -column 0 -row $row -columnspan 1 -rowspan 1 \
            -pady 2
        entry $base.ecurse \
            -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),$i,curse) \
            -background #fefefe \
            -borderwidth 1 \
            -width 200
        bind $base.ecurse <Key-Return> "set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1"
        grid $base.ecurse \
            -in $base -column 1 -row $row -columnspan 2 -rowspan 1 \
            -padx 2
        menubutton $base.mbcurse \
            -borderwidth 1 \
            -menu $base.mbcurse.m \
            -padx 2 \
            -pady 0 \
            -image ::icon::xapp-16
        menu $base.mbcurse.m \
            -borderwidth 1 \
            -cursor {} \
            -tearoff 0 \
            -font $PgAcVar(pref,font_normal)
        set newcol 0    
        foreach curser {X_cursor arrow based_arrow_down based_arrow_up boat bogosity bottom_left_corner bottom_right_corner bottom_side bottom_tee box_spiral center_ptr circle clock coffee_mug cross cross_reverse crosshair diamond_cross dot dotbox double_arrow draft_large draft_small draped_box exchange fleur gobbler gumby hand1 hand2 heart icon iron_cross left_ptr left_side left_tee leftbutton ll_angle lr_angle man middlebutton mouse pencil pirate plus question_arrow right_ptr right_side right_tee rightbutton rtl_logo sailboat sb_down_arrow sb_h_double_arrow sb_left_arrow sb_right_arrow sb_up_arrow sb_v_double_arrow shuttle sizing spider spraycan star target tcross top_left_arrow top_left_corner top_right_corner top_side top_tee trek ul_angle umbrella ur_angle watch xterm} {
            $base.mbcurse.m add command \
                -command "
                    set PgAcVar(fdobj,$PgAcVar(fcnt),$i,curse) $curser
                    Forms::design:draw_object $i
                    set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
                " -label $curser \
                -columnbreak [expr {floor((($newcol%20)+1)/20)}]
            incr newcol
        }
        grid $base.mbcurse \
            -in $base -column 3 -row $row -columnspan 1 -rowspan 1 \
            -pady 2 -padx 2
        incr row
    }

    # The last dummy label
    
    label $base.ldummy -text {} -borderwidth 0
    grid $base.ldummy -in $base -column 0 -row 100

    grid columnconfigure $base 1 \
        -weight 10
    grid columnconfigure $base 2 \
        -weight 10
    grid rowconf $base 100 -weight 1

}; # end proc ::Forms::design:createAttributesFrame


#----------------------------------------------------------
# show_attributes --
#
#   configures the identification and attributes frames
#   for a given object item
#
# Arguments:
#   item_   number of the object to work for
#
# Results:
#   none
#----------------------------------------------------------
#
proc ::Forms::design:show_attributes {item_} {
global PgAcVar

    if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$item_,class)]} {
        # non-existent item
        return
    }

    set objclass $PgAcVar(fdobj,$PgAcVar(fcnt),$item_,class)
    set PgAcVar(fdvar,$PgAcVar(fcnt),c_class) $objclass

    design:createAttributesFrame $item_

    set PgAcVar(fdvar,$PgAcVar(fcnt),c_name) \
        $PgAcVar(fdobj,$PgAcVar(fcnt),$item_,name)

    if {$item_ == 0} {

        # Object 0 is the form

        # it cant be changed to another object type so disable the combobox
        .pgaw:FormDesign:attributes.fi.comboclass configure -state disabled

        set c [split [winfo geometry .pgaw:FormDesign:draft] x+]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_top) [lindex $c 3]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_left) [lindex $c 2]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_width) [lindex $c 0]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_height) [lindex $c 1]

    } else {

        # the class of all objects except forms can be changed with a combobox
        .pgaw:FormDesign:attributes.fi.comboclass configure -state normal

        set c $PgAcVar(fdobj,$PgAcVar(fcnt),$item_,coord)
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_top) [lindex $c 1]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_left) [lindex $c 0]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_width) \
            [expr {[lindex $c 2]-[lindex $c 0]}]
        set PgAcVar(fdvar,$PgAcVar(fcnt),c_height) \
            [expr {[lindex $c 3]-[lindex $c 1]}]
    }

}; # end proc ::Forms::design:show_attributes


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:run {{parent_ ""}} {
global PgAcVar CurrentDB DataControlVar

# cant run a non-existent form (one without geometry)
if {![info exists PgAcVar(fdvar,$PgAcVar(fcnt),geometry)]} {return}

set base [string trim $parent_.$PgAcVar(fdobj,$PgAcVar(fcnt),0,name)]
set basevars ".$PgAcVar(fdobj,$PgAcVar(fcnt),0,name)"

set c [split $PgAcVar(fdvar,$PgAcVar(fcnt),geometry) x+]
set c_width [lindex $c 0]
set c_height [lindex $c 1]

# if we are a subform then we cannot be a toplevel so make us a frame instead
if {$parent_!=""} {
    ScrollableFrame $base \
        -areaheight $c_height \
        -areawidth $c_width \
        -background [$parent_ cget -background]
    pack $base \
        -expand 1 \
        -fill both
    $parent_ setwidget $base
    set base [$base getframe]
} else {
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm geometry $base $PgAcVar(fdvar,$PgAcVar(fcnt),geometry)
    wm maxsize $base 785 570
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base $PgAcVar(fdvar,$PgAcVar(fcnt),formtitle)
}

# setup the background canvas
# first make sure we have a background color for backwards compatibility
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),0,bcolor)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),0,bcolor)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),0,bcolor) #999999
}
canvas $base.c \
    -background $PgAcVar(fdobj,$PgAcVar(fcnt),0,bcolor) \
    -height $c_height \
    -width $c_width \
    -highlightthickness 0 \
    -relief ridge \
    -selectborderwidth 0
pack $base.c \
    -expand 1 \
    -fill both

# then check what the cursor is supposed to be
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),0,curse)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),0,curse)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),0,curse) left_ptr
}
$base.c configure -cursor $PgAcVar(fdobj,$PgAcVar(fcnt),0,curse) 

# now place each widget
foreach item $PgAcVar(fdvar,$PgAcVar(fcnt),objlist) {
set coord $PgAcVar(fdobj,$PgAcVar(fcnt),$item,coord)
set name $PgAcVar(fdobj,$PgAcVar(fcnt),$item,name)
set wh "-width [expr {3+[lindex $coord 2]-[lindex $coord 0]}] -height [expr {3+[lindex $coord 3]-[lindex $coord 1]}]"
set visual 1

set wfont $PgAcVar(fdobj,$PgAcVar(fcnt),$item,font)
switch $wfont {
    {} {set wfont $PgAcVar(pref,font_normal)}
    normal  {set wfont $PgAcVar(pref,font_normal)}
    bold  {set wfont $PgAcVar(pref,font_bold)}
    italic  {set wfont $PgAcVar(pref,font_italic)}
    fixed  {set wfont $PgAcVar(pref,font_fix)}
}

# this is just to catch if something was not saved correctly
if {[string match "" $wfont]} {::Preferences::setDefaultFonts}

# anchor and justification attribute check
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$item,anch)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),$item,anch)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$item,anch) center
}
set wanch $PgAcVar(fdobj,$PgAcVar(fcnt),$item,anch)

if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$item,just)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),$item,just)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$item,just) left
}
set wjust $PgAcVar(fdobj,$PgAcVar(fcnt),$item,just)

# cursor check
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$item,curse)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),$item,curse)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$item,curse) left_ptr
}
set wcurse $PgAcVar(fdobj,$PgAcVar(fcnt),$item,curse)

# editability check
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$item,editable)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),$item,editable)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$item,editable) false
}
set weditable $PgAcVar(fdobj,$PgAcVar(fcnt),$item,editable)

# validation checks
# validate type
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$item,validate)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),$item,validate)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$item,validate) none
}
set wvalidate $PgAcVar(fdobj,$PgAcVar(fcnt),$item,validate)
# validate command
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$item,validatecmd)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),$item,validatecmd)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$item,validatecmd) {}
}
set wvalidatecmd $PgAcVar(fdobj,$PgAcVar(fcnt),$item,validatecmd)
# invalid command
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$item,invalidcmd)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),$item,invalidcmd)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$item,invalidcmd) {} 
}
set winvalidcmd $PgAcVar(fdobj,$PgAcVar(fcnt),$item,invalidcmd)

# extra bindings
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$item,plusbind)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),$item,plusbind)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$item,plusbind) {} 
}
set wplusbind $PgAcVar(fdobj,$PgAcVar(fcnt),$item,plusbind)
# just add the bindings to the end of the form startup command
append PgAcVar(fdobj,$PgAcVar(fcnt),0,command) $wplusbind

# notebook pages
if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),$item,pages)] \
    || $PgAcVar(fdobj,$PgAcVar(fcnt),$item,pages)==""} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$item,pages) {} 
}
set wpages $PgAcVar(fdobj,$PgAcVar(fcnt),$item,pages)

namespace forget ::DataControl($base.$name)
namespace forget ::DataControl($basevars.$name)

# Checking if relief ridge or groove has borderwidth 2
if {[lsearch {ridge groove} $PgAcVar(fdobj,$PgAcVar(fcnt),$item,relief)] != -1} {
    if {$PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) < 2} {
        set PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) 2
    }
}

# Checking if borderwidth is okay
if {[lsearch {0 1 2 3 4 5} \
    $PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth)] == -1} {
    set PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) 1
}

set cmd {}
catch {set cmd $PgAcVar(fdobj,$PgAcVar(fcnt),$item,command)}

# this will keep track of whether or not the widget is actually inside a frame
set framed 0

# this is because the pseudo widgets, query and table, are so similar
set classy $PgAcVar(fdobj,$PgAcVar(fcnt),$item,class)
if {$classy=="query"||$classy=="table"} {
    set classy "pseudo"
}

switch $classy {
    button {
        Button $base.$name \
        -anchor $wanch \
        -justify $wjust \
        -borderwidth 1 \
        -padx 0 \
        -pady 0 \
        -text "$PgAcVar(fdobj,$PgAcVar(fcnt),$item,label)" \
        -fg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,fcolor) \
        -bg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor) \
        -borderwidth $PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) \
        -relief $PgAcVar(fdobj,$PgAcVar(fcnt),$item,relief) \
        -font $wfont \
        -command [subst {$cmd}] \
        -cursor $wcurse
        if {$PgAcVar(fdobj,$PgAcVar(fcnt),$item,variable) != ""} {
            $base.$name configure \
                -textvariable $PgAcVar(fdobj,$PgAcVar(fcnt),$item,variable)
        }
    }
    checkbox {
        checkbutton $base.$name \
        -anchor $wanch \
        -justify $wjust \
        -onvalue t \
        -offvalue f \
        -font $wfont \
        -fg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,fcolor) \
        -bg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor) \
        -borderwidth $PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) \
        -command [subst {$cmd}] \
        -text "$PgAcVar(fdobj,$PgAcVar(fcnt),$item,label)" \
        -variable "$PgAcVar(fdobj,$PgAcVar(fcnt),$item,variable)" \
        -borderwidth 1 \
        -cursor $wcurse
        set wh {}
    }
    pseudo {
        set visual 0
        if {$PgAcVar(fdobj,$PgAcVar(fcnt),$item,class)=="query"} {
            set DataControlVar($basevars.$name,sql) \
                $PgAcVar(fdobj,$PgAcVar(fcnt),$item,command)
        } else {
            set DataControlVar($basevars.$name,sql) \
                "SELECT oid,* FROM $PgAcVar(fdobj,$PgAcVar(fcnt),$item,command)"
        }
        namespace eval ::DataControl($basevars.$name) "proc open {} {
            global CurrentDB DataControlVar
            variable tuples
            catch {unset tuples}
            # see if its a stored query
            set qry \[Queries::getSQL \$DataControlVar($basevars.$name,sql)\]
            if {\[string length \$qry\]!=0} {set DataControlVar($basevars.$name,sql) \$qry}
            # continue
            set wn \[focus\] ; setCursor CLOCK
            set res \[wpg_exec \$CurrentDB \
                \"\$DataControlVar($basevars.$name,sql)\"\]
            pg_result \$res -assign tuples
            set fl {}
            foreach fd \[pg_result \$res -lAttributes\] {
                lappend fl \[lindex \$fd 0\]
            }
            set DataControlVar($basevars.$name,fields) \$fl
            set DataControlVar($basevars.$name,recno) 0
            set DataControlVar($basevars.$name,nrecs) \[pg_result \$res -numTuples\]
            setCursor NORMAL
            pg_result \$res -clear
        }"
        namespace eval ::DataControl($basevars.$name) "proc setSQL {sqlcmd} {
            global DataControlVar
            # see if its a stored query
            set qry \[Queries::getSQL \$sqlcmd\]
            if {\[string length \$qry\]!=0} {set sqlcmd \$qry}
            set DataControlVar($basevars.$name,sql) \$sqlcmd
        }"
        namespace eval ::DataControl($basevars.$name) "proc getSQL {} {
            global DataControlVar
            return \$DataControlVar($basevars.$name,sql)
        }"
        # this setVars command may change drastically
        namespace eval ::DataControl($basevars.$name) "proc setVars {pairs} {
            global DataControlVar
            foreach nameval \$pairs {
                set \[lindex \$nameval 0\] \[lindex \$nameval 1\]
            }
            set DataControlVar($basevars.$name,sql) \
                \[subst \$DataControlVar($basevars.$name,sql)\]
        }"
        namespace eval ::DataControl($basevars.$name) "proc getRowCount {} {
            global DataControlVar
            return \$DataControlVar($basevars.$name,nrecs)
        }"
        namespace eval ::DataControl($basevars.$name)  "proc getRowIndex {} {
            global DataControlVar
            return \$DataControlVar($basevars.$name,recno)
        }"
        namespace eval ::DataControl($basevars.$name)  "proc moveTo {newrecno} {
            global DataControlVar
            set DataControlVar($basevars.$name,recno) \$newrecno
        }"
        namespace eval ::DataControl($basevars.$name) "proc close {} {
            variable tuples
            catch {unset tuples}
        }"
        namespace eval ::DataControl($basevars.$name)  "proc getFieldList {} {
            global DataControlVar
            return \$DataControlVar($basevars.$name,fields)
        }"
        namespace eval ::DataControl($basevars.$name)  "proc drain {args} {
            set lb_ \[lindex \$args 0\]
            set node_ \[lindex \$args 1\]
            \$lb_ delete \[\$lb_ nodes \$node_\]
        }"
        namespace eval ::DataControl($basevars.$name)  "proc fill {args} {
            global DataControlVar
            variable tuples
            variable fields {}
            # parse the args list
            set lb_ \[lindex \$args 0\]
            set fld_ \[lindex \$args 1\]
            set text_ \[lindex \$args 1\]
            set node_ \"\"
            # if we got 3 args, then its a tree so we set the node name to fill
            if {\[llength \$args\]>2} {
                set node_ \[lindex \$args 2\]
            }
            # if we got 4 args, then it's the column name where the text is
            if {\[llength \$args\]>3} {
                set text_ \[lindex \$args 3\]
            }
            # first we clear out the stuff already in these widgets
            if {\[string length \$node_\]>0} {
                # BWidget Tree
                # should do something here
            } elseif {\[catch {\$lb_ cget -values}\]} { 
                # BWidget ListBox
                \$lb_ delete 0 end
            } else {
                # BWidget ComboBox and SpinBox
                \$lb_ configure -values {}
            }
            # then we fill them back up
            for {set i 0} {\$i<\$DataControlVar($basevars.$name,nrecs)} {incr i} {
                if {\[string length \$node_\]>0} {
                    # BWidget Tree
                    # the new node is named after the parent
                    catch {\$lb_ insert end \$node_ \"\$node_-\$tuples\(\$i,\$fld_\)\" \
                        -text \$tuples\(\$i,\$text_\)}
                } elseif {\[catch {\$lb_ cget -values}\]} {
                    # BWidget ListBox
                    \$lb_ insert end \$tuples\(\$i,\$fld_\)
                } else {
                    # BWidget ComboBox and SpinBox
                    lappend fields \$tuples\(\$i,\$fld_\)
                }
            }
            if {\[catch {\$lb_ cget -listvar}\] && \[string length \$node_\]==0} {
                # BWidget ComboBox and SpinBox
                \$lb_ configure -values \$fields
                \$lb_ setvalue first
            }
        }"
        namespace eval ::DataControl($basevars.$name)  "proc moveFirst {} {
            global DataControlVar
            set DataControlVar($basevars.$name,recno) 0
        }"
        namespace eval ::DataControl($basevars.$name)  "proc moveNext {} {
            global DataControlVar
            incr DataControlVar($basevars.$name,recno)
            if {\$DataControlVar($basevars.$name,recno)==\[getRowCount\]} {
                moveLast
            }
        }"
        namespace eval ::DataControl($basevars.$name)  "proc movePrevious {} {
            global DataControlVar
            incr DataControlVar($basevars.$name,recno) -1
            if {\$DataControlVar($basevars.$name,recno)==-1} {
                moveFirst
            }
        }"
        namespace eval ::DataControl($basevars.$name)  "proc moveLast {} {
            global DataControlVar
            set DataControlVar($basevars.$name,recno) \[expr \[getRowCount\] -1\]
        }"
        namespace eval ::DataControl($basevars.$name)  "proc updateDataSet {} {
            global DataControlVar
            global DataSet
            variable tuples
            set i \$DataControlVar($basevars.$name,recno)
            foreach fld \$DataControlVar($basevars.$name,fields) {
                catch {
                    upvar DataSet\($basevars.$name,\$fld\) dbvar
                    set dbvar \$tuples\(\$i,\$fld\)
                }
            }
        }"
        namespace eval ::DataControl($basevars.$name)  "proc clearDataSet {} {
            global DataControlVar
            global DataSet
            catch {
                foreach fld \$DataControlVar($basevars.$name,fields) {
                    catch {
                        upvar DataSet\($basevars.$name,\$fld\) dbvar
                        set dbvar {}
                    }
                }
            }
        }"
    }
    radio {
        radiobutton $base.$name \
        -justify $wjust \
        -anchor $wanch \
        -font $wfont \
        -text "$PgAcVar(fdobj,$PgAcVar(fcnt),$item,label)" \
        -fg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,fcolor) \
        -bg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor) \
        -variable $PgAcVar(fdobj,$PgAcVar(fcnt),$item,variable) \
        -value $PgAcVar(fdobj,$PgAcVar(fcnt),$item,value) \
        -borderwidth 1 \
        -cursor $wcurse
        set wh {}
    }
    entry {
        entry $base.$name \
        -justify $wjust \
        -bg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor) \
        -fg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,fcolor) \
        -borderwidth $PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) \
        -font $wfont \
        -relief $PgAcVar(fdobj,$PgAcVar(fcnt),$item,relief) \
        -selectborderwidth 0 \
        -highlightthickness 0 \
        -cursor $wcurse \
        -validate $wvalidate
        set vcmd {}
        catch {set vcmd [subst {$wvalidatecmd}]}
        $base.$name configure -validatecommand $vcmd
        set invcmd {}
        catch {set invcmd [subst {$winvalidcmd}]}
        $base.$name configure -invalidcommand $invcmd
        set var {}
        catch {set var $PgAcVar(fdobj,$PgAcVar(fcnt),$item,variable)}
        if {$var!=""} {$base.$name configure -textvar $var}
    }
    text {
        text $base.$name \
        -fg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,fcolor) \
        -bg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor) \
        -relief $PgAcVar(fdobj,$PgAcVar(fcnt),$item,relief) \
        -borderwidth $PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) \
        -font $wfont \
        -cursor $wcurse
    }
    label {
        # set wh {}
        Label $base.$name \
        -anchor $wanch \
        -justify $wjust \
        -font $wfont \
        -padx 0 \
        -pady 0 \
        -text $PgAcVar(fdobj,$PgAcVar(fcnt),$item,label) \
        -borderwidth $PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) \
        -relief $PgAcVar(fdobj,$PgAcVar(fcnt),$item,relief) \
        -fg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,fcolor) \
        -bg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor) \
        -cursor $wcurse
        set var {}
        catch {set var $PgAcVar(fdobj,$PgAcVar(fcnt),$item,variable)}
        if {$var!=""} {$base.$name configure -textvariable $var}
    }
    listbox {
        listbox $base.$name -bg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor) \
        -highlightthickness 0 -selectborderwidth 0 \
        -borderwidth $PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) \
        -relief $PgAcVar(fdobj,$PgAcVar(fcnt),$item,relief) \
        -fg $PgAcVar(fdobj,$PgAcVar(fcnt),$item,fcolor) \
        -font $wfont -yscrollcommand [subst {$base.sb$name set}] \
        -cursor $wcurse
        scrollbar $base.sb$name -borderwidth 1 \
        -command [subst {$base.$name yview}] -orient vert \
        -highlightthickness 0 -cursor $wcurse
        eval [subst "place $base.sb$name -x [expr {[lindex $coord 2]-14}] -y [expr {[lindex $coord 1]-1}] -width 16 -height [expr {3+[lindex $coord 3]-[lindex $coord 1]}] -anchor nw -bordermode ignore"]
    }
    spinbox {
        # from the BWidgets
        SpinBox $base.$name -justify $wjust \
        -background $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor) \
        -highlightthickness 0 \
        -selectborderwidth 0 \
        -borderwidth $PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) \
        -relief $PgAcVar(fdobj,$PgAcVar(fcnt),$item,relief) \
        -foreground $PgAcVar(fdobj,$PgAcVar(fcnt),$item,fcolor) \
        -font $wfont \
        -editable $weditable
        if {$cmd!=""} {$base.$name configure -modifycmd $cmd}
        set var {}
        catch {set var $PgAcVar(fdobj,$PgAcVar(fcnt),$item,variable)}
        if {$var!=""} {$base.$name configure -textvariable $var}
    }
    combobox {
        # from the BWidgets
        ComboBox $base.$name -justify $wjust \
        -background $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor) \
        -highlightthickness 0 \
        -selectborderwidth 0 \
        -borderwidth $PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) \
        -relief $PgAcVar(fdobj,$PgAcVar(fcnt),$item,relief) \
        -foreground $PgAcVar(fdobj,$PgAcVar(fcnt),$item,fcolor) \
        -font $wfont \
        -editable $weditable
        if {$cmd!=""} {$base.$name configure -modifycmd $cmd}
        set var {}
        catch {set var $PgAcVar(fdobj,$PgAcVar(fcnt),$item,variable)}
        if {$var!=""} {$base.$name configure -textvariable $var}
    }
    tree {
        # from the BWidgets
        set framed 1
        ScrolledWindow $base.__frame__$name \
            -borderwidth 0 \
            -auto both \
            -scrollbar both
        Tree $base.__frame__$name.$name \
            -background $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor) \
            -highlightthickness 0 \
            -borderwidth $PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) \
            -relief $PgAcVar(fdobj,$PgAcVar(fcnt),$item,relief) \
            -selectbackground $PgAcVar(fdobj,$PgAcVar(fcnt),$item,fcolor)
            # we arent passing args to user commands
            # but the Tree widget wants to do so
            # thus we need to ignore them
            if {$cmd!=""} {
                namespace eval :: "proc ::$base.__frame__$name.$name.selcmd {args} {
                    eval {$cmd}
                }"
                $base.__frame__$name.$name configure \
                    -selectcommand ::$base.__frame__$name.$name.selcmd
            }
        $base.__frame__$name setwidget $base.__frame__$name.$name
        # we need to make sure procs on the widget get passed to it
        namespace eval :: "proc ::$base.$name {args} {
            eval ::$base.__frame__$name.$name \[join \$args\]
        }"
    }
    subform {
        # another pga form
        set framed 1
        ScrolledWindow $base.__frame__$name \
            -borderwidth 0 \
            -auto both \
            -scrollbar both
        # keep track of our form number
        set fcnt $PgAcVar(fcnt)
        set openedsubform [::Forms::open $cmd $base.__frame__$name]
        set PgAcVar(fcnt) $fcnt
        namespace eval :: "proc $base.$name {args} {
            eval ::$openedsubform \[join \$args\]
        }"
    }
    image {
        # the pga image
        set framed 1
        set sw [ScrolledWindow $base.__frame__$name \
            -borderwidth 0 \
            -auto both \
            -scrollbar both]
        set sf [ScrollableFrame $sw.sf \
            -background $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor)]
        pack $sf \
            -expand 1 \
            -fill both
        $sw setwidget $sf
        set f [$sf getframe]
        Label $f.lbl \
            -background $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor)
        pack $f.lbl \
            -expand 1 \
            -fill both
        # use either picture data or name of pga image
        # (so we could specify any column with picture data
        # as the variable)
        namespace eval :: "proc $base.__trace__$name {args} {
            set photovar \$::$PgAcVar(fdobj,$PgAcVar(fcnt),$item,variable)
            set photoimg \[::Images::get \$photovar\]
            if {\[string length \$photoimg\]==0} {
                $f.lbl configure \
                    -image \[image create photo \
                    -data \$photovar\]
            } else {
                $f.lbl configure \
                    -image \[image create photo \
                    -data \$photoimg\]
            }
        }"
        trace variable ::$PgAcVar(fdobj,$PgAcVar(fcnt),$item,variable) w ::$base.__trace__$name
        namespace eval :: "proc $base.$name {args} {
            eval ::$f.lbl \[join \$args\]
        }"
    }
    notebook {
        # from the BWidgets
        set framed 1
        set book [NoteBook $base.__frame__$name \
            -borderwidth $PgAcVar(fdobj,$PgAcVar(fcnt),$item,borderwidth) \
            -background $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor)]
        # keep track of our form number
        set fcnt $PgAcVar(fcnt)
        # go through each of the pages
        set ofrml [list]
        foreach page $PgAcVar(fdobj,$PgAcVar(fcnt),$item,pages) {
            set pagetit [lindex $page 0]
            set pagefrm [lindex $page 1]
            set curpage [$book insert end $pagetit \
                -text $pagetit]
            set sw [ScrolledWindow $curpage.sw \
                -borderwidth 0 \
                -auto both \
                -scrollbar both \
                -background $PgAcVar(fdobj,$PgAcVar(fcnt),$item,bcolor)]
            pack $curpage.sw \
                -expand 1 \
                -fill both
            set openedsubform [::Forms::open $pagefrm $sw]
            append ofrml $openedsubform
        }
        set PgAcVar(fcnt) $fcnt
        namespace eval :: "proc $base.$name {args} {
            foreach of $ofrml {
                eval ::\$of \[join \$args\]
            }
        }"
    }
}

# if the widget is in a frame, we need to place the frame and not the widget
if {$framed} {
    set name "__frame__$name"
}

# if this form is being used as a subform, allow subform widget procs to work
if {$parent_!=""} {
    namespace eval :: "proc $basevars {args} {
        eval $base.$name \[join \$args\]
    }"
}

# then place the widget since place is the window manager for user app forms
if $visual {
    eval [subst "place $base.$name  -x [expr {[lindex $coord 0]-1}] -y [expr {[lindex $coord 1]-1}] -anchor nw $wh -bordermode ignore"]
    # cant do this yet because $wh is both width and height
    #place $base.$name \
	#-x [expr {[lindex $coord 0]-1}] \
	#-y [expr {[lindex $coord 1]-1}] \
	#-anchor nw $wh \
	#-bordermode ignore
}

}; # end foreach widget

# put the startup command with the form, if any, into the toplevel namespace
if {[string length $PgAcVar(fdobj,$PgAcVar(fcnt),0,command)]>0} {
    uplevel #0 $PgAcVar(fdobj,$PgAcVar(fcnt),0,command)
}
    return $base

}; # end proc ::Forms::design:run


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Forms::design:close {} {
global PgAcVar
    if {$PgAcVar(fdvar,$PgAcVar(fcnt),dirty)} {
        if {[tk_messageBox -title [intlmsg Warning] \
        -message [intlmsg "Do you want to save the form into the database?"] \
        -type yesno -default yes]=="yes"} {
            if {[::Forms::design:save 0]==0} {
                return
            }
        } else {
            set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 0
        }
    }
    catch {Window destroy .pgaw:FormDesign:draft}
    catch {Window destroy .pgaw:FormDesign:toolbar}
    catch {Window destroy .pgaw:FormDesign:menu}
    catch {Window destroy .pgaw:FormDesign:attributes}
    catch {Window destroy .pgaw:FormDesign:commands}
    catch {Window destroy .$PgAcVar(fdobj,$PgAcVar(fcnt),0,name)}
}; # end proc ::Forms::design:close


#----------------------------------------------------------
# ::Forms::tableBindingMagic
#
#   Creates automagic widget bindings for UPDATE events
#   as the FocusOut event for the widget.
#
# Arguments:
#   fcnt_   count of the open form on which widget appears
#   item_   the widget number
#
# Results:
#   none returned
#----------------------------------------------------------
#
proc ::Forms::tableBindingMagic {fcnt_ item_} {
global PgAcVar

    set PgAcVar(fdvar,$fcnt_,dirty) 1

    # is it a dataset variable
    if {[lsearch $PgAcVar(fdvar,$fcnt_,dsvars) $PgAcVar(fdobj,$fcnt_,$item_,variable)] > -1} {

        # short hand slice and dice
        set tblname ""
        set varname $PgAcVar(fdobj,$fcnt_,$item_,variable)
        set wgtname [string range $varname [expr {[string last . $varname]+1}] [expr {[string first , $varname]-1}]]
        set colname [string range $varname [expr {[string first , $varname]+1}] end-1]
        set oidname [string range $varname 0 [string first , $varname]]
        append oidname "oid)"

        # make sure its a table dataset variable
        foreach i $PgAcVar(fdvar,$fcnt_,objlist) {
            if {$PgAcVar(fdobj,$fcnt_,$i,name)==$wgtname
              && $PgAcVar(fdobj,$fcnt_,$i,class)=="table"} {
                set tblname $PgAcVar(fdobj,$fcnt_,$i,command)
                break
            }
        }

        # the actual binding
        if {[string length $tblname]>0} {
            append PgAcVar(fdobj,$fcnt_,$item_,plusbind) "

# automagic pseudo-table binding
bind .$PgAcVar(fdobj,$fcnt_,0,name).$PgAcVar(fdobj,$fcnt_,$item_,name) <FocusOut> {
     set sql \"UPDATE [::Database::quoteSQL $tblname]
                  SET $colname='\$$PgAcVar(fdobj,$fcnt_,$item_,variable)'
                WHERE oid=\$$oidname\"
     sql_exec noquiet \$sql
}"

        }

     }

};  # end proc ::Forms::tableBindingMagic



#==========================================================
#==========================================================
proc vTclWindow.pgaw:FormDesign:draft {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:FormDesign:draft
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm geometry $base 375x315+105+105
    wm maxsize $base 785 570
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Form design"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    bind $base <Destroy> {
        if {[string match %W [winfo toplevel %W]]} {
            Forms::design:close
        }
    }
    bind $base <Key-Delete> {
        Forms::design:delete_object
    }
    bind $base <Key-F1> "Help::load form_design"

    # backwards compatibility, didnt use to have background color
    if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),0,bcolor)] \
        || $PgAcVar(fdobj,$PgAcVar(fcnt),0,bcolor)==""} {
        set PgAcVar(fdobj,$PgAcVar(fcnt),0,bcolor) #999999
    }
    # didnt have cursor either
    if {![info exists PgAcVar(fdobj,$PgAcVar(fcnt),0,curse)] \
        || $PgAcVar(fdobj,$PgAcVar(fcnt),0,curse)==""} {
        set PgAcVar(fdobj,$PgAcVar(fcnt),0,curse) left_ptr
    } 
    canvas $base.c \
        -background $PgAcVar(fdobj,$PgAcVar(fcnt),0,bcolor) \
        -height 207 -highlightthickness 0 -relief ridge \
        -selectborderwidth 0 -width 295 
    $base.c configure -cursor $PgAcVar(fdobj,$PgAcVar(fcnt),0,curse)

    bind $base.c <Button-1> {
        Forms::design:mouse_down %x %y
    }
    bind $base.c <ButtonRelease-1> {
        Forms::design:mouse_up %x %y
    }
    bind $base.c <Motion> {
        Forms::design:mouse_move %x %y
    }

    # cut, copy, paste
    bind $base <Control-Key-x> {
        Forms::design:cut_object    
    }
    bind $base <Control-Key-c> {
        Forms::design:copy_object
    }
    bind $base <Control-Key-v> {
        Forms::design:paste_object    
    }

    pack $base.c \
        -in .pgaw:FormDesign:draft -anchor center -expand 1 -fill both -side top
}

proc vTclWindow.pgaw:FormDesign:attributes {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:FormDesign:attributes
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm geometry $base 300x400+485+105
    wm maxsize $base 785 570
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm deiconify $base
    wm title $base [intlmsg "Attributes"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Key-F1> "Help::load form_design"

    bind $base <Destroy> {
        if {[string match %W [winfo toplevel %W]]} {
            Forms::design:close
        }
    }

    # The identification frame

    frame $base.fi \
        -borderwidth 2 -height 75 -relief groove -width 125 

    label $base.fi.lname \
        -borderwidth 0 -text [intlmsg Name]
    entry $base.fi.ename -textvariable PgAcVar(fdvar,$PgAcVar(fcnt),c_name) \
        -background #fefefe -borderwidth 1 -width 260 
    bind $base.fi.ename <Key-Return> {
        Forms::design:set_name
    }

    label $base.fi.lclass \
        -borderwidth 0 -text [intlmsg Class]
    ComboBox $base.fi.comboclass \
        -textvariable PgAcVar(fdvar,$PgAcVar(fcnt),c_class) \
        -background #fefefe -borderwidth 1 -width 260 \
        -values {entry label listbox spinbox combobox button text radio checkbox query table tree subform image notebook} \
        -editable false \
        -modifycmd {
            Forms::design:set_class
            set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
        }

    # The geometry frame

    frame $base.fg \
        -borderwidth 2 -height 75 -relief groove -width 185 
    entry $base.fg.e1 -textvariable PgAcVar(fdvar,$PgAcVar(fcnt),c_width) \
        -background #fefefe -borderwidth 1 -width 5 
    entry $base.fg.e2 -textvariable PgAcVar(fdvar,$PgAcVar(fcnt),c_height) \
        -background #fefefe -borderwidth 1 -width 5 
    entry $base.fg.e3 -textvariable PgAcVar(fdvar,$PgAcVar(fcnt),c_left) \
        -background #fefefe -borderwidth 1 -width 5 
    entry $base.fg.e4 -textvariable PgAcVar(fdvar,$PgAcVar(fcnt),c_top) \
        -background #fefefe -borderwidth 1 -width 5 
    bind $base.fg.e1 <Key-Return> {
        Forms::design:change_coords
    }
    bind $base.fg.e2 <Key-Return> {
        Forms::design:change_coords
    }
    bind $base.fg.e3 <Key-Return> {
        Forms::design:change_coords
    }
    bind $base.fg.e4 <Key-Return> {
        Forms::design:change_coords
    }
    label $base.fg.l1 \
        -borderwidth 0 -text Width 
    label $base.fg.l2 \
        -borderwidth 0 -text Height 
    label $base.fg.l3 \
        -borderwidth 0 -text Left 
    label $base.fg.l4 \
        -borderwidth 0 -text Top 
    label $base.fg.lx1 \
        -borderwidth 0 -text x 
    label $base.fg.lp1 \
        -borderwidth 0 -text + 
    label $base.fg.lp2 \
        -borderwidth 0 -text + 

    # The frame for the rest of the attributes (dynamically generated)

    
    frame $base.f \
        -borderwidth 2 -height 75 -relief groove -width 185 


    # Geometry for "identification frame"


    place $base.fi \
        -x 5 -y 5 -width 290 -height 55 -anchor nw -bordermode ignore 
    grid columnconf $base.fi 1 -weight 1
    grid $base.fi.lname \
        -in $base.fi -column 0 -row 0 -columnspan 1 -rowspan 1 -sticky w 
    grid $base.fi.ename \
        -in $base.fi -column 1 -row 0 -columnspan 2 -rowspan 1 -padx 2 \
        -sticky w 
    grid $base.fi.lclass \
        -in $base.fi -column 0 -row 1 -columnspan 1 -rowspan 1 -sticky w 
    grid $base.fi.comboclass \
        -in $base.fi -column 1 -row 1 -columnspan 2 -rowspan 1 -padx 2 \
        -sticky w 



    # Geometry for "geometry frame"

    place $base.fg \
        -x 5 -y 60 -width 290 -height 45 -anchor nw -bordermode ignore 
    grid $base.fg.e1 \
        -in $base.fg -column 0 -row 0 -columnspan 1 -rowspan 1 
    grid $base.fg.e2 \
        -in $base.fg -column 2 -row 0 -columnspan 1 -rowspan 1 
    grid $base.fg.e3 \
        -in $base.fg -column 4 -row 0 -columnspan 1 -rowspan 1 
    grid $base.fg.e4 \
        -in $base.fg -column 6 -row 0 -columnspan 1 -rowspan 1 
    grid $base.fg.l1 \
        -in $base.fg -column 0 -row 1 -columnspan 1 -rowspan 1 
    grid $base.fg.l2 \
        -in $base.fg -column 2 -row 1 -columnspan 1 -rowspan 1 
    grid $base.fg.l3 \
        -in $base.fg -column 4 -row 1 -columnspan 1 -rowspan 1 
    grid $base.fg.l4 \
        -in $base.fg -column 6 -row 1 -columnspan 1 -rowspan 1 
    grid $base.fg.lx1 \
        -in $base.fg -column 1 -row 0 -columnspan 1 -rowspan 1 
    grid $base.fg.lp1 \
        -in $base.fg -column 5 -row 0 -columnspan 1 -rowspan 1 
    grid $base.fg.lp2 \
        -in $base.fg -column 3 -row 0 -columnspan 1 -rowspan 1 

    place $base.f -x 5 -y 105 -width 290 -height 290 -anchor nw

}


proc vTclWindow.pgaw:FormDesign:commands {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:FormDesign:commands
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm geometry $base 640x480+120+100
    wm maxsize $base 2560 2048
    wm minsize $base 1 19
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm title $base [intlmsg "text"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Key-F1> "Help::load form_design"

    frame $base.f \
        -borderwidth 2 -height 75 -relief groove -width 125 
    scrollbar $base.f.sb \
        -borderwidth 1 -command {.pgaw:FormDesign:commands.f.txt yview} \
        -orient vert -width 12 
    text $base.f.txt \
        -font $PgAcVar(pref,font_fix) -height 1 \
        -tabs {20 40 60 80 100 120 140 160 180 200} \
        -width 200 -yscrollcommand {.pgaw:FormDesign:commands.f.sb set} \
        -background #ffffff
    frame $base.fb \
        -height 75 -width 125 
    Button $base.fb.b1 \
        -borderwidth 1 \
        -helptext [intlmsg {Save}] \
        -command {
            set bad_tcl "yes"
            if {![info complete [.pgaw:FormDesign:commands.f.txt \
                get 1.0 "end - 1 chars"]]} {
                set bad_tcl [tk_messageBox -title [intlmsg Warning] \
                    -parent .pgaw:FormDesign:commands -type yesno \
                    -message [intlmsg "There appears to be invalid Tcl code.  Are you sure you want to save it?"]]
            } 
            if {$bad_tcl=="yes"} {
                set PgAcVar(fdobj,$PgAcVar(fcnt),$PgAcVar(fdvar,$PgAcVar(fcnt),commandFor),$PgAcVar(fdvar,$PgAcVar(fcnt),commandType)) [.pgaw:FormDesign:commands.f.txt get 1.0 "end - 1 chars"]
                #puts "PgAcVar(fdobj,$PgAcVar(fcnt),$PgAcVar(fdvar,$PgAcVar(fcnt),commandFor),$PgAcVar(fdvar,$PgAcVar(fcnt),commandType))"
                #puts "$PgAcVar(fdobj,$PgAcVar(fcnt),$PgAcVar(fdvar,$PgAcVar(fcnt),commandFor),$PgAcVar(fdvar,$PgAcVar(fcnt),commandType))"
                Window hide .pgaw:FormDesign:commands
                set PgAcVar(fdvar,$PgAcVar(fcnt),dirty) 1
                if {$PgAcVar(fdvar,$PgAcVar(fcnt),commandType)=="label"} {
                    Forms::design:set_text
                }
            }
        } -image ::icon::filesave-22
    Button $base.fb.b2 \
        -borderwidth 1 -command {Window hide .pgaw:FormDesign:commands} \
        -helptext [intlmsg {Close}] \
        -image ::icon::exit-22
    # add Ctrl-x|c|v for cut, copy, paste
    bind $base.f.txt <Control-Key-x> {
        set PgAcVar(shared,curseltext) [%W get sel.first sel.last]    
        %W delete sel.first sel.last
    }
    bind $base.f.txt <Control-Key-c> {
        set PgAcVar(shared,curseltext) [%W get sel.first sel.last]    
    }
    bind $base.f.txt <Control-Key-v> {
        if {[info exists PgAcVar(shared,curseltext)]} {
            catch {%W delete sel.first sel.last}
            %W insert insert $PgAcVar(shared,curseltext)
            %W see current
        }
    }
    # searching with Ctrl-f
    bind $base.f.txt <Control-Key-f> {
        set limit 100
        set fndtxt [parameter [intlmsg "Enter text to find:"]]
        set fndlen [string length $fndtxt]
        %W tag delete fndbind
        %W tag configure fndbind -background #ffff00
        if {$fndlen>0} {
            set fnd [%W search $fndtxt 1.0 end]
            if {[string length $fnd]>0} {
                %W see $fnd
                while {[string length $fnd]>0 && $limit>0} {
                    incr limit -1
                    %W tag add fndbind $fnd "$fnd + $fndlen chars"
                    set fnd [%W search $fndtxt "$fnd + $fndlen chars" end]
                }
            } else {
                tk_messageBox \
                    -parent %W \
                    -icon error \
                    -title [intlmsg "Failed"] \
                    -message [format [intlmsg "Couldn't find '%s'!"] $fndtxt]
            }
        }
    }
    pack $base.f \
        -in .pgaw:FormDesign:commands -anchor center -expand 1 \
        -fill both -side top 
    pack $base.f.sb \
        -in .pgaw:FormDesign:commands.f -anchor e -expand 1 \
        -fill y -side right 
    pack $base.f.txt \
        -in .pgaw:FormDesign:commands.f -anchor center -expand 1 \
        -fill both -side top 
    pack $base.fb \
        -in .pgaw:FormDesign:commands -anchor center -expand 0 \
        -fill none -side top 
    pack $base.fb.b1 \
        -in .pgaw:FormDesign:commands.fb -anchor center -expand 0 \
        -fill none -side left 
    pack $base.fb.b2 \
        -in .pgaw:FormDesign:commands.fb -anchor center -expand 0 \
        -fill none -side top 
}

proc vTclWindow.pgaw:FormDesign:menu {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:FormDesign:menu
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm geometry $base 435x75+0+0
    wm maxsize $base 1009 738
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm deiconify $base
    wm title $base [intlmsg "Form designer"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Key-F1> "Help::load form_design"

    bind $base <Destroy> {
        if {[string match %W [winfo toplevel %W]]} {
            Forms::design:close
        }
    }
    frame $base.f1 \
        -height 75 -relief groove -width 125 
    label $base.f1.l1 \
        -borderwidth 0 -text "[intlmsg {Form name}] "
    entry $base.f1.e1 \
        -background #fefefe -borderwidth 1 \
        -textvariable PgAcVar(fdvar,$PgAcVar(fcnt),formtitle) 
    frame $base.f2 \
        -height 75 -relief groove -width 125 
    label $base.f2.l \
        -borderwidth 0 -text "[intlmsg {Form's window internal name}] "
    entry $base.f2.e \
        -background #fefefe -borderwidth 1 \
        -textvariable PgAcVar(fdobj,$PgAcVar(fcnt),0,name) 
    frame $base.f3 \
        -height 1 -width 125 
    button $base.f3.b1 \
        -command {
            if {$PgAcVar(fdvar,testform)==[intlmsg "Test form"]} {
                set PgAcVar(fdvar,testform) [intlmsg "Close test form"]
                set PgAcVar(fdvar,$PgAcVar(fcnt),geometry) \
                    [wm geometry .pgaw:FormDesign:draft]
                Forms::design:run
            } else {
                set PgAcVar(fdvar,testform) [intlmsg "Test form"]
                # make sure we close all the forms opened while testing
                for {set i $PgAcVar(fcnt)} {$i>0} {incr i -1} {
                    if {[winfo exists .$PgAcVar(fdobj,$i,0,name)]} {
                        destroy .$PgAcVar(fdobj,$i,0,name)
                    }
                }
                # get back to the original form we were designing
                set PgAcVar(fcnt) 1
                Forms::design:draw_grid
                foreach i $PgAcVar(fdvar,$PgAcVar(fcnt),objlist) {
                    Forms::design:draw_object $i
                }
                wm geometry .pgaw:FormDesign:draft \
                    $PgAcVar(fdvar,$PgAcVar(fcnt),geometry)
            }
        } -padx 1 \
        -textvariable PgAcVar(fdvar,testform)
    ButtonBox $base.f3.bbox \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $base.f3.bbox add \
        -relief link \
        -borderwidth 1 \
        -helptext [intlmsg {Save}] \
        -command {Forms::design:save 0} \
        -image ::icon::filesave-22
    $base.f3.bbox add \
        -relief link \
        -borderwidth 1 \
        -helptext [intlmsg {Save As}] \
        -command {Forms::design:save 1} \
        -image ::icon::filesaveas-22
    $base.f3.bbox add \
        -relief link \
        -borderwidth 1 \
        -helptext [intlmsg {Help}] \
        -command {::Help::load form_design} \
        -image ::icon::help-22
    $base.f3.bbox add \
        -relief link \
        -borderwidth 1 \
        -helptext [intlmsg {Close}] \
        -command {Forms::design:close} \
        -image ::icon::exit-22
    checkbutton $base.f3.cbgridsnap -text [intlmsg "Snap to Grid"] \
        -variable PgAcVar(fdvar,$PgAcVar(fcnt),gridsnap)
    entry $base.f3.egridsize \
        -borderwidth 1 -width 5 \
        -textvariable PgAcVar(fdvar,$PgAcVar(fcnt),gridsize)
    bind $base.f3.egridsize <Key-Return> "Forms::design:draw_grid"
    label $base.f3.lgridsize \
        -text [intlmsg "Grid Size"]
    
    pack $base.f1 \
        -in .pgaw:FormDesign:menu -anchor center -expand 0 \
        -fill x -pady 2 -side top 
    pack $base.f1.l1 \
        -in .pgaw:FormDesign:menu.f1 -anchor center -expand 0 \
        -fill none -side left 
    pack $base.f1.e1 \
        -in .pgaw:FormDesign:menu.f1 -anchor center -expand 1 \
        -fill x -side left 
    pack $base.f2 \
        -in .pgaw:FormDesign:menu -anchor center -expand 0 \
        -fill x -pady 1 -side top 
    pack $base.f2.l \
        -in .pgaw:FormDesign:menu.f2 -anchor center -expand 0 \
        -fill none -side left 
    pack $base.f2.e \
        -in .pgaw:FormDesign:menu.f2 -anchor center -expand 1 \
        -fill x -side left 
    pack $base.f3 \
        -in .pgaw:FormDesign:menu -anchor center -expand 0 \
        -fill x -pady 2 -side bottom 
    pack $base.f3.b1 \
        -in .pgaw:FormDesign:menu.f3 -anchor center -expand 0 \
        -fill none -side left 
    pack $base.f3.cbgridsnap \
        -in .pgaw:FormDesign:menu.f3 -anchor center -expand 0 \
        -fill none -side left 
    pack $base.f3.egridsize \
        -in .pgaw:FormDesign:menu.f3 -anchor center -expand 0 \
        -fill none -side left 
    pack $base.f3.lgridsize \
        -in .pgaw:FormDesign:menu.f3 -anchor center -expand 0 \
        -fill none -side left 
    pack $base.f3.bbox \
        -in .pgaw:FormDesign:menu.f3 \
        -side right \
        -expand 0 \
        -fill x
}


proc vTclWindow.pgaw:FormDesign:toolbar {base} {
global PgAcVar
    if {$base == ""} {
        set base .pgaw:FormDesign:toolbar
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel -menu .pgaw:FormDesign:toolbar.m17 
    wm geometry $base 50x450+0+100
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm deiconify $base
    wm title $base [intlmsg "Toolbar"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Key-F1> "Help::load form_design"

    bind $base <Destroy> {
        if {[string match %W [winfo toplevel %W]]} {
            Forms::design:close
        }
    }

    ButtonBox $base.bbox \
        -orient vertical \
        -homogeneous 1 \
        -spacing 2

    foreach wedgie {button radio checkbox label text entry listbox spinbox combobox query table tree subform image notebook} {
        $base.bbox add \
            -borderwidth 1 \
            -command [subst {set PgAcVar(fdvar,\$PgAcVar(fcnt),tool) $wedgie}] \
            -image [::Forms::design:getIcon $wedgie] \
            -helptext [intlmsg $wedgie]
    }

    pack $base.bbox \
        -in $base \
        -fill both \
        -expand 1

}

