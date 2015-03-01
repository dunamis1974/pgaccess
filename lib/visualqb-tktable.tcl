#----------------------------------------------------------
# VisualQueryBuilder
#
#   provides for rapid query building
#
#----------------------------------------------------------
#
# The following package is required
  package require Tktable 2.8

# The following is the variable for Tktable
# (which must be global)

  global tbquery

#
namespace eval VisualQueryBuilder {
  variable Win
  variable hlite none
  variable lbnam

  # The following array will hold all the local variables
  variable vqb
}


#----------------------------------------------------------
# ::VisualQueryBuilder::init
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::init {} {

  global PgAcVar tbquery
  variable vqb

  catch {unset vqb}
  set vqb(rescriteria) {}
  set vqb(links) {}
  set vqb(ntables) 0
  set vqb(tid) {}; # Array of lists containing table name and table id (needed for dragging individual tables)
  set vqb(newtablename) {}

  # Clear out table
  array unset tbquery

  # Set row headings for table query
  set tbquery(1,0) "Field: "
  set tbquery(2,0) "Table: "
  set tbquery(3,0) "Sort: "
  set tbquery(4,0) "Visible: "
  set tbquery(5,0) "Criteria: "
  set tbquery(6,0) "Or: "

};   # end proc ::VisualQueryBuilder::init


#----------------------------------------------------------
# ::VisualQueryBuilder::print
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::print {} {

  variable Win
  variable vqb

  set g [string trimleft [wm geometry .pgaw:VisualQuery] "="]
  set vqb(xsize) [lindex [split $g "x+"] 0]
  set vqb(ysize) [lindex [split $g "x+"] 1]

  ::Printer::init "::VisualQueryBuilder::printcallback"

};   # end proc ::VisualQueryBuilder::print


#----------------------------------------------------------
# ::VisualQueryBuilder::printcallback
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::printcallback {fid} {

  variable vqb

  set cv .pgaw:VisualQuery.pw.f0.frame.c

  ::Printer::printStart $fid $vqb(xsize) $vqb(ysize) 1
  ::Printer::printPage $fid 1 $cv
  ::Printer::printStop $fid

};   # end proc ::VisualQueryBuilder::print


#------------------------------------------------------------
# ::VisualQueryBuilder::createDropDown
#------------------------------------------------------------
#
proc ::VisualQueryBuilder::createDropDown {} {

  global PgAcVar
  variable vqb

  if {[winfo exists .pgaw:VisualQuery.ddf]} {
    destroy .pgaw:VisualQuery.ddf
  } else {
    create_drop_down .pgaw:VisualQuery 70 27 200
    focus .pgaw:VisualQuery.ddf.sb
    foreach tbl [Database::getTablesList] {.pgaw:VisualQuery.ddf.lb insert end $tbl}
    bind .pgaw:VisualQuery.ddf.lb <ButtonRelease-1> {
      set i [.pgaw:VisualQuery.ddf.lb curselection]
      if {$i!=""} {
        set VisualQueryBuilder::vqb(newtablename) [.pgaw:VisualQuery.ddf.lb get $i]
        VisualQueryBuilder::addNewTable
      }
      destroy .pgaw:VisualQuery.ddf
      break
    }
  }

  return

}; # end proc ::VisualQueryBuilder::createDropDown


#----------------------------------------------------------
# ::VisualQueryBuilder::addNewTable
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::addNewTable {{tabx 0} {taby 0} {alias -1}} {

  global PgAcVar CurrentDB
  variable vqb
  variable Win

  if {$vqb(newtablename)==""} return
  set fldlist {}
  set l [split [string map {\" \'} $vqb(newtablename)] "."]
  if {[llength $l] == 2} {
    set schemaname [lindex $l 0]
  }
  set tablename [lindex $l end]
  set ver [string range [::Database::getPgVersion $CurrentDB] 0 2]
  setCursor CLOCK
  set fldlist [::Database::getColumnsList $vqb(newtablename)]
  setCursor DEFAULT
  if {$fldlist==""} {
    showError [format [intlmsg "Table '%s' not found!"] $vqb(newtablename)]
    return
  }
  if {$alias==-1} {
    set tabnum $vqb(ntables)
  } else {
    regsub t $alias "" tabnum
  }
  set vqb(tablename$tabnum) $vqb(newtablename)
  set vqb(tablestruct$tabnum) $fldlist
  set vqb(tablealias$tabnum) "t$tabnum"
  set vqb(ali_t$tabnum) $vqb(newtablename)
  set vqb(tablex$tabnum) $tabx
  set vqb(tabley$tabnum) $taby
  incr vqb(ntables)
  if {$vqb(ntables)==1} {
    repaintAll
  } else {
    drawTable [expr $vqb(ntables)-1]
  }
  set vqb(newtablename) {}
  focus $Win(entertable)

};   # end proc ::VisualQueryBuilder::addNewTable


#----------------------------------------------------------
# ::VisualQueryBuilder::drawTable
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::drawTable {it} {

  global PgAcVar
  variable vqb
  variable hlite
  variable lbnam

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  set tbl .pgaw:VisualQuery.pw.f1.frame.tb

  # Get the number of pixels for (scrollregion) 29.7cm and 21cm on the canvas
  set nx [winfo fpixels $cv 29.7c]
  set ny [winfo fpixels $cv 21.0c]
  if {$vqb(tablex$it)==0} {
    set posy 10
    set allbox [$cv bbox ftbl]
    if {$allbox==""} {
        set posx 10
    } else {
        set posx [expr 20 + [lindex $allbox 2]]
    }
    # ToDo: Try to get smarter placement
    if {$posx > $nx} {
      set posx 20
      set posy 20
    }
    set vqb(tablex$it) $posx
    set vqb(tabley$it) $posy
  } else {
    set posx [expr int($vqb(tablex$it))]
    set posy [expr int($vqb(tabley$it))]
  }

  # Remove leading and trailing double-quotes
  set tablename [string trim $vqb(tablename$it) \"]
  set tablealias $vqb(tablealias$it)

  # Create table window (frame, label and Listbox)
  set fnam tab$it
  frame $cv.$fnam -borderwidth 2 -relief raised -height 10 -width 10
  label $cv.$fnam.lab -borderwidth 2 -text $tablename
  ListBox $cv.$fnam.lb -background #fefefe -foreground #000000 \
    -selectforeground white -selectbackground darkblue \
    -borderwidth 1 -highlightthickness 0 -deltay 14 -selectmode single\
    -yscrollcommand [subst {$cv.$fnam.sb set}] \
    -dragenabled 1 -dragevent 1 -dropenabled 1 -dropovermode i\
    -dropcmd {VisualQueryBuilder::lbdrop}
  scrollbar $cv.$fnam.sb -borderwidth 1 -command [subst {$cv.$fnam.lb yview}] -highlightthickness 0 -orient vert

  # Get the width of the longest field and height of fields
  set w 0
  set numflds 0
  foreach fld $vqb(tablestruct$it) {
    set tmp [font measure system -displayof $cv.$fnam.lb $fld]
    if {$tmp > $w} {
      set w $tmp}
    incr numflds
  }
  set h [expr $numflds * 14]

  # Add 30 to width to allow for left border where an image can be displayed
  # Add 30 to height to allow for the label
  set tid [$cv create window $posx $posy -anchor nw -window $cv.$fnam \
           -height [expr $h + 30] -width [expr $w + 30] -tags ftbl]
  lappend vqb(tid) [list $cv.$fnam $tid]
  pack $cv.$fnam.lab -side top -fill x
  pack $cv.$fnam.lb -side left -expand 1 -fill y
  foreach fld $vqb(tablestruct$it) {$cv.$fnam.lb insert end $fld -text $fld -data $it}
  $cv.$fnam.lb bindText <Button-1> [list VisualQueryBuilder::clickListbox $cv.$fnam.lb]
  $cv.$fnam.lb bindText <Double-Button-1> [list VisualQueryBuilder::dblclickListbox $cv.$fnam.lb]

  # Set up events for dragging the tables on the canvas
  bind $cv.$fnam.lab <ButtonPress-1> {
    set dragx %x
    set dragy %y
    set w [winfo parent %W]
    set tid [VisualQueryBuilder::findtid $w]
  }

  bind $cv.$fnam.lab <B1-Motion> {
    set dx [expr %x - $dragx]
    set dy [expr %y - $dragy]
    .pgaw:VisualQuery.pw.f0.frame.c move $tid $dx $dy
    VisualQueryBuilder::drawLinks
  }

  bind $cv.$fnam.lab <ButtonRelease-1> {
    #set dragstart 0
  }

}; # end proc ::VisualQueryBuilder::drawTable


#----------------------------------------------------------
# ::VisualQueryBuilder::clickListbox
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::clickListbox {w i} {
  VisualQueryBuilder::deselectGrid
  VisualQueryBuilder::deselectLinks
  VisualQueryBuilder::deselectTables
  $w selection set $i
  set VisualQueryBuilder::hlite tabl
  set VisualQueryBuilder::lbnam $w
}


#----------------------------------------------------------
# ::VisualQueryBuilder::dblclickListbox
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::dblclickListbox {w i} {

  global PgAcVar
  variable vqb

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  set tbl .pgaw:VisualQuery.pw.f1.frame.tb

  VisualQueryBuilder::deselectGrid
  VisualQueryBuilder::deselectLinks
  VisualQueryBuilder::deselectTables
  $w selection set $i
  set VisualQueryBuilder::hlite tabl
  set VisualQueryBuilder::lbnam $w

  # Find first free column in table
  # If none free, add column to end of table
  set cl -1
  for {set c 1} {$c < [$tbl cget -cols]} {incr c} {
    if {[$tbl get 1,$c] == ""} {
      set cl $c
      break
    }
  }
  if {$cl == -1} {
    $tbl insert cols $c 1
    set cl [expr [$tbl cget -cols] - 1]
  }

  set f [winfo parent $w]
  set tablename [$f.lab cget -text]
  $tbl set 1,$cl $i
  $tbl set 2,$cl $tablename
  $tbl set 3,$cl Unsorted
  $tbl set 4,$cl Yes
}


#----------------------------------------------------------
# ::VisualQueryBuilder::findtid
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::findtid {w} {
  variable vqb

  foreach l $vqb(tid) {
    if {[lindex $l 0]==$w} {
      set tid [lindex $l 1]
      break;
    }
  }
  return $tid
}; # end proc ::VisualQueryBuilder::findtid


#----------------------------------------------------------
# ListBox drop (lbdrop)
#
# target: pathname of the listbox dropped onto
# source: pathname of the drag source
# lst   : list describing where the drop occurs. It can be
#           {widget}
#           {item item} or
#           {position index}
# op    : current operation
# type  : data type (of drag source, should be LISTBOX_ITEM)
# data  : data (of drag source)
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::lbdrop {target source lst op type data} {
  global PgAcVar
  variable vqb

  set sourcetable [winfo parent [winfo parent $source]]
  set targetfield [lindex $lst end]
  set targettable [winfo parent $target]

  if {$sourcetable!=$targettable} {
    lappend vqb(links) [list $sourcetable $data $targettable $targetfield]
    drawLinks
  }
}


#----------------------------------------------------------
# ::VisualQueryBuilder::tableDrop
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::tableDrop {target source x y currentop type data} {

  global PgAcVar
  variable vqb

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  set tbl .pgaw:VisualQuery.pw.f1.frame.tb

  set c [$tbl index @$x,$y col]
  if {$c <= 0} return

  # Check if already a field in this column. If yes
  # insert this before the current column
  if {[$tbl get 1,$c] != ""} {
    $tbl insert cols $c -1
  }
  set it [[winfo parent $source] itemcget $data -data]
  set tablename [string trim $vqb(tablename$it) \"]
  $tbl set 1,$c $data
  $tbl set 2,$c $tablename
  $tbl set 3,$c Unsorted
  $tbl set 4,$c Yes

}


#----------------------------------------------------------
# ::VisualQueryBuilder::drawLinks
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::drawLinks {} {

  global PgAcVar
  variable vqb

  if {[llength $vqb(links)]==0} return

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  
  $cv delete links
  set i 0

  # vqb(links) is an array of lists
  # each list (link) contains sourcetable, sourcefield, targettable, targetfield
  foreach link $vqb(links) {
    set sourcetable [lindex $link 0]
    set sourcefield [lindex $link 1]
    set targettable [lindex $link 2]
    set targetfield [lindex $link 3]

    # Compute the source and destination right edge
    set tid [findtid $sourcetable]
    set scoords [$cv bbox $tid]
    set sre [lindex $scoords 2]
    set tid [findtid $targettable]
    set tcoords [$cv bbox $tid]
    set dre [lindex $tcoords 2]

    # Compute field bound boxes
    set slb $sourcetable.lb
    set sidx [$slb index $sourcefield]
    set tlb $targettable.lb
    set tidx [$tlb index $targetfield]

    # Compute the auxiliary lines
    if {$sre < $dre} {
      # Source object is on the left of target object
      set x1 $sre
      set y1 [expr $sidx * 14 + [lindex $scoords 1] + 30]
      $cv create line $x1 $y1 [expr $x1+10] $y1 -tags [subst {links lkid$i}] -width 3
      set x2 [lindex $tcoords 0]
      set y2 [expr $tidx * 14 + [lindex $tcoords 1] + 30]
      $cv create line [expr $x2-10] $y2 $x2 $y2 -tags [subst {links lkid$i}] -width 3
      $cv create line [expr $x1+10] $y1 [expr $x2-10] $y2 -tags [subst {links lkid$i}] -width 2
    } else {
      # source object is on the right of target object
      set x1 $dre
      set y1 [expr $tidx * 14 + [lindex $tcoords 1] + 30]
      $cv create line $x1 $y1 [expr $x1+10] $y1 -tags [subst {links lkid$i}] -width 3
      set x2 [lindex $scoords 0]
      set y2 [expr $sidx * 14 + [lindex $scoords 1] + 30]
      $cv create line $x2 $y2 [expr $x2-10] $y2 -tags [subst {links lkid$i}] -width 3
      $cv create line [expr $x1+10] $y1 [expr $x2-10] $y2 -tags [subst {links lkid$i}] -width 2
      }
      incr i
  }

  $cv lower links
  #$cv bind links <Button-1> {VisualQueryBuilder::linkClick %x %y}

}; # end proc ::VisualQueryBuilder::drawLinks


#----------------------------------------------------------
# ::VisualQueryBuilder::linkClick
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::linkClick {obj} {

  global PgAcVar
  variable vqb
  variable hlite

  set cv  .pgaw:VisualQuery.pw.f0.frame.c

  set taglist [$cv gettags $obj]

  # deselct everything
  deselectGrid
  deselectLinks
  deselectTables

  set lt [lindex $taglist 1]
  $cv addtag hili withtag $lt
  foreach i [$cv find withtag hili] {
    $cv itemconfigure $i -fill blue
  }
  set hlite link
}; # end proc ::VisualQueryBuilder::linkClick


#----------------------------------------------------------
# ::VisualQueryBuilder::canvasClick
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::canvasClick {x y} {

  global PgAcVar
  variable vqb
  variable hlite

  set cv  .pgaw:VisualQuery.pw.f0.frame.c

  # As the scrollregion for the canvas is larger than the
  # screen, we need to convert the screen x,y coordinates
  # to the canvas x,y coordinates.
  set lx [$cv canvasx $x] 
  set ly [$cv canvasy $y]
  set obj [$cv find overlapping $lx $ly $lx $ly]
  if {$obj != ""} {
    linkClick $obj
  } else {
    deselectGrid
    deselectLinks
    deselectTables
    set hlite none
  }
}


#----------------------------------------------------------
# ::VisualQueryBuilder::computeSQL
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::computeSQL {} {

  global PgAcVar
  variable vqb

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  set tbl .pgaw:VisualQuery.pw.f1.frame.tb

  set vqb(rescriteria) {}

  set sqlcmd "SELECT "

  for {set c 1} {$c < [$tbl cget -cols]} {incr c} {
    if {[string trim [$tbl get 4,$c]] == "Yes"} {
      if {![string match "$sqlcmd" "SELECT "]} {
        set sqlcmd "$sqlcmd, "
      }
      set f [$tbl get 1,$c]
      set t [$tbl get 2,$c]
      append sqlcmd "\"${t}\".\"${f}\""
    }
  }

  # Read table names from grid and sort unique to remove duplicates
  set tables [list]
  for {set c 1} {$c < [$tbl cget -cols]} {incr c} {
    set t [string trim [$tbl get 2,$c]]
    if {$t != ""} {
      lappend tables "$t"
    }
  }
  set tables [lsort -unique $tables]
  append sqlcmd "\nFROM [join $tables ,] "

  set sup1 {}
  if {[llength $vqb(links)] > 0} {
    set sup1 "\nWHERE "
    foreach link $vqb(links) {
      if {$sup1 != "\nWHERE "} {
        append sup1 " AND "
      }
      foreach {t1 f1 t2 f2} $link {break}
      set tab1 [$t1.lab cget -text]
      set tab2 [$t2.lab cget -text]
      append sup1 " (\"${tab1}\".\"${f1}\"=\"${tab2}\".\"${f2}\")"
    }
  }


  # Expressions in multiple columns in a single row are treated as And criteria. To be
  # selected as part of the query's results, a record must meet all the criteria in a given row.
  # Expressions in different rows are treated as Or criteria. To be selected, a record needs
  # to meet the criteria only in any one row.
  #--------------------------------------------------------------------------
  # Assume this section is empty
  set addSectionStart 0

  # set start of this section to 'where' or 'and'
  if {$sup1 == ""} {
    set strt "\nWHERE ("
  } else {
    set strt " AND ("
  }
  
  for {set r 5} {$r < [$tbl cget -rows]} {incr r} {
    set str "("
    for {set c 1} {$c < [$tbl cget -cols]} {incr c} {
      if {[string trim [$tbl get $r,$c]] != ""} {
        set f [$tbl get 1,$c]
        set t [$tbl get 2,$c]
        set o [$tbl get $r,$c]
        append str "(\"${t}\".\"${f}\" $o) AND "
      }
    }
    # remove last " and " if there is one
    set pos [string last " AND " $str]
    if {$pos > 0} {
      set str [string range $str 0 [expr $pos - 1]]
    }
    append str ")"
    if {$str != "()"} {
      set addSectionStart 1
    }
    lappend vqb(rescriteria) $str
  }

  if {$addSectionStart == 1} {
    set addor 0
    append sup1 $strt

    foreach s $vqb(rescriteria) {
      if {$s != "()"} {
        if {$addor == 1} {
          append sup1 "\nOR "
        }
        append sup1 $s
        set addor 1
      }
    }
    append sup1 ")"
  }
  append sqlcmd " $sup1"


  set sup2 {}
  for {set c 1} {$c < [$tbl cget -cols]} {incr c} {
    set how [$tbl get 3,$c]
    if {$how != ""} {
      if {$how != "Unsorted"} {
        if {$how == "Ascending"} {
          set how ASC
        } else {
          set how DESC
        }
        if {$sup2 == ""} {
          set sup2 "\nORDER BY "
        } else {
          append sup2 ","
        }
        set f [$tbl get 1,$c]
        set t [$tbl get 2,$c]
        append sup2 "\"${t}\".\"${f}\" $how "
      }
    }
  }

  append sqlcmd " $sup2"

  return [set vqb(qcmd) $sqlcmd]

};   # end proc ::VisualQueryBuilder::computeSQL


#----------------------------------------------------------
# ::VisualQueryBuilder::deleteObject
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::deleteObject {} {

  global PgAcVar
  variable vqb
  variable hlite
  variable lbnam

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  set tbl .pgaw:VisualQuery.pw.f1.frame.tb

  switch $hlite {
    grid {set c [$tbl tag col HILITEcol]
          set r [$tbl tag row HILITErow]
          foreach cl $c {$tbl delete cols $cl 1}
          foreach rw $r {$tbl delete rows $rw 1}
         }
    link {set lnks [$cv find withtag hili]
          if {$lnks==""} return
          set taglist [$cv gettags [lindex $lnks 0]]
          if {$taglist==""} return
          set lt [lindex $taglist 1]           
          set tagpos [string range $lt 4 end]
          set vqb(links) [lreplace $vqb(links) $tagpos $tagpos]
          $cv delete hili
          drawLinks
         }
    tabl {set it [$lbnam itemcget [$lbnam selection get] -data]
          set tablename [string trim $vqb(tablename$it) \"]

          # First, delete columns in query table
          # If you delete column 3 (for example) column 4 becomes column 3
          # and it is missed as c has been incremented to 4. So reverse the loop
          for {set c [expr [$tbl cget -cols] - 1]} {$c > 0 } {set c [expr $c - 1]} {
            if {[string trim [$tbl get 2,$c]] == $tablename} {
              $tbl delete cols $c 1
            }
          }

          # Second, find and delete links to the table
          set tnam [winfo parent $lbnam]
          set tagpos 0
          # Reverse the loop
          # Does the following work?
          foreach lnk $vqb(links) {
            if {[lindex $lnk 0]==$tnam || [lindex $lnk 2]==$tnam} {
              set vqb(links) [lreplace $vqb(links) $tagpos $tagpos]
            } else {
              incr tagpos
            }
          }
          $cv delete links
          drawLinks

          # Finally, delete the table
          set tid [VisualQueryBuilder::findtid $tnam]
          $cv delete $tid
          # delete from vqb(tid)
          for {set pos 0} {$pos < [llength $vqb(tid)]} {incr pos} {
            set lst [lindex $vqb(tid) $pos]
            if {[lindex $lst 0]==$tnam} {
              set vqb(tid) [lreplace $vqb(tid) $pos $pos]
              break;
            }
          }
         }
  }; # end switch

}; # end proc ::VisualQueryBuilder::deleteObject


#----------------------------------------------------------
# ::VisualQueryBuilder::deselectGrid
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::deselectGrid {} {

  variable vqb

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  set tbl .pgaw:VisualQuery.pw.f1.frame.tb

  set c [$tbl tag col HILITEcol]
  set r [$tbl tag row HILITErow]
  foreach cl $c {$tbl tag col {} $cl}
  foreach rw $r {$tbl tag row {} $rw}
  $tbl selection clear all
}


#----------------------------------------------------------
# ::VisualQueryBuilder::deselectLinks
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::deselectLinks {} {

  variable vqb

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  set tbl .pgaw:VisualQuery.pw.f1.frame.tb

  set lnks [$cv find withtag hili]
  if {$lnks==""} return
  foreach i $lnks {
    $cv itemconfigure $i -fill black
    $cv dtag $i hili
  }
}


#----------------------------------------------------------
# ::VisualQueryBuilder::deselectTables
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::deselectTables {} {

  variable vqb

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  set tbl .pgaw:VisualQuery.pw.f1.frame.tb

  foreach l $vqb(tid) {
    set w [lindex $l 0]
    $w.lb selection clear 0 end
  }  
}


#----------------------------------------------------------
# ::VisualQueryBuilder::getTableList
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::getTableList {} {

    global PgAcVar
    variable vqb

    set tablelist {}
    set num 0
    foreach lst $vqb(tid) {
      set f [lindex $lst 0]
      set name [$f.lab cget -text]
      lappend tablelist $name [winfo x $f] [winfo y $f] t$num
      incr num
    }

    return $tablelist

}; # end proc ::VisualQueryBuilder::getTableList


#----------------------------------------------------------
# ::VisualQueryBuilder::getLinkList
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::getLinkList {} {

    global PgAcVar
    variable vqb

    set linklist {}
    foreach lst $vqb(links) {
        lappend linklist [lindex $lst 0] [lindex $lst 1] [lindex $lst 2] [lindex $lst 3]
    }

    return $linklist

}; # end proc ::VisualQueryBuilder::getLinkList {} {


#----------------------------------------------------------
# ::VisualQueryBuilder::loadVisualLayout
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::loadVisualLayout {} {

    global PgAcVar tbquery
    variable vqb

    set tbl .pgaw:VisualQuery.pw.f1.frame.tb

    init
    foreach {t x y a} $PgAcVar(query,tables) {
        set vqb(newtablename) $t
        addNewTable $x $y $a
    }
    foreach {t0 f0 t1 f1} $PgAcVar(query,links) {
        lappend vqb(links) [list $t0 $f0 $t1 $f1]
    }
    if {$PgAcVar(query,results)!=""} {
      set lst $PgAcVar(query,results)
      $tbl configure -rows [lindex $lst 0]
      $tbl configure -cols [lindex $lst 1]
      array set tbquery [lindex $lst 2]
      drawLinks
    }

}; # end proc ::VisualQueryBuilder::loadVisualLayout {} {


#----------------------------------------------------------
# ::VisualQueryBuilder::repaintAll
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::repaintAll {} {

  global PgAcVar
  variable vqb

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  set tbl .pgaw:VisualQuery.pw.f1.frame.tb

  $cv delete all
  set posx 20

  foreach tn [array names vqb tablename*] {
    regsub tablename $tn "" it
    drawTable $it
  }

  drawLinks
  #drawResultPanel

  bind .pgaw:VisualQuery <Key-Delete> {
    VisualQueryBuilder::deleteObject
  }

}; # end proc ::VisualQueryBuilder::repaintAll


#----------------------------------------------------------
# ::VisualQueryBuilder::showSQL
#----------------------------------------------------------
#
proc ::VisualQueryBuilder::showSQL {} {

  global PgAcVar
  variable vqb

  set sqlcmd [computeSQL]
  set tl .showSQL
  toplevel $tl -class Toplevel
  wm title $tl [intlmsg "Show SQL"]
  text $tl.txtSQL -height 15 -width 80 -bg white -wrap word
  $tl.txtSQL insert end $sqlcmd
  $tl.txtSQL configure -state disabled
  button $tl.close -text "Close" -command {destroy .showSQL}
  pack $tl.txtSQL -in $tl -fill both
  pack $tl.close -in $tl -fill x

}; # end proc ::VisualQueryBuilder::showSQL


#------------------------------------------------------------
# ::VisualQueryBuilder::saveToQueryBuilder
#------------------------------------------------------------
#
proc ::VisualQueryBuilder::saveToQueryBuilder {} {

    global PgAcVar tbquery
    variable vqb

    set tbl .pgaw:VisualQuery.pw.f1.frame.tb

    Window show .pgaw:QueryBuilder
    $::Queries::Win(qrytxt) delete 1.0 end
    set vqb(qcmd) [computeSQL]
    set PgAcVar(query,tables) [getTableList]
    set PgAcVar(query,links) [getLinkList]
    set PgAcVar(query,results) [list [$tbl cget -rows] [$tbl cget -cols] [array get tbquery]]
    $::Queries::Win(qrytxt) insert end $vqb(qcmd)
    focus .pgaw:QueryBuilder

    return

}; # end proc ::VisualQueryBuilder::saveToQueryBuilder


#------------------------------------------------------------
# ::VisualQueryBuilder::executeSQL
#------------------------------------------------------------
#
proc ::VisualQueryBuilder::executeSQL {} {

    global PgAcVar
    variable vqb

    set vqb(qcmd) [computeSQL]
    set wn [Tables::getNewWindowName]
    set PgAcVar(mw,$wn,query) [subst $vqb(qcmd)]
    set PgAcVar(mw,$wn,updatable) 0
    set PgAcVar(mw,$wn,isaquery) 1
    Tables::createWindow
    Tables::loadLayout $wn nolayoutneeded
    Tables::selectRecords $wn $PgAcVar(mw,$wn,query)

}; # end proc ::VisualQueryBuilder::executeSQL


#------------------------------------------------------------
# ::VisualQueryBuilder::tableButton1
#------------------------------------------------------------
#
proc ::VisualQueryBuilder::tableButton1 {w x y} {

  global PgAcVar
  variable vqb
  variable hlite

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  set tbl .pgaw:VisualQuery.pw.f1.frame.tb

  set r [$tbl index @$x,$y row]
  set c [$tbl index @$x,$y col]

  # deselect everything else
  deselectLinks
  deselectTables
  set hlite grid

  if {$r==0 && $c>0} {
    if {[$tbl tag includes HILITEcol $r,$c]} {
      $tbl tag col {} $c
    } else {
      $tbl tag col HILITEcol $c
    }
  } elseif {$r>6 && $c==0} {
    if {[$tbl tag includes HILITErow $r,$c]} {
      $tbl tag row {} $r
    } else {
      $tbl tag row HILITErow $r
    }
  }

  if {$r==4 && $c>0} {
    if {[$tbl get $r,$c] != ""} {
      if {[string match Yes [$tbl get $r,$c]]} {
        $tbl set $r,$c No
      } else {
        $tbl set $r,$c Yes
      }
    }
  } 

  if {$r==3 && $c>0} {
    if {[$tbl get $r,$c] != ""} {
      if {[string match Unsorted [$tbl get $r,$c]]} {
        $tbl set $r,$c Ascending
      } elseif {[string match Ascending [$tbl get $r,$c]]} {
        $tbl set $r,$c Descending
      } elseif {[string match Descending [$tbl get $r,$c]]} {
        $tbl set $r,$c Unsorted
      } else {
        $tbl set $r,$c Unsorted
      }
    }
  }
}


#------------------------------------------------------------
# ::VisualQueryBuilder::tableButton3
#------------------------------------------------------------
#
proc ::VisualQueryBuilder::tableButton3 {w x y} {

  global PgAcVar
  variable vqb

  set cv  .pgaw:VisualQuery.pw.f0.frame.c
  set tbl .pgaw:VisualQuery.pw.f1.frame.tb

  #set r [$tbl index @$x,$y row]
  #set c [$tbl index @$x,$y col]

  if {[$tbl tag cell active] == ""} {return}
  if {[$tbl index active col]==0} {return}
  if {[$tbl index active row]>6} {
    $tbl.pop.casd entryconfigure 1 -state normal
    $tbl.pop.casi entryconfigure 1 -state normal
  } else {
    $tbl.pop.casd entryconfigure 1 -state disabled
    $tbl.pop.casi entryconfigure 1 -state disabled
  }

  tk_popup $tbl.pop [winfo pointerx $w] [winfo pointery $w]
}


#============================================================
#   GUI
#============================================================
#
proc vTclWindow.pgaw:VisualQuery {base} {

    global PgAcVar
    variable vqb

    if {$base==""} {
        set base .pgaw:VisualQuery
    }

    if {[winfo exists $base]} {
        wm deiconify $base; return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 759x530+10+13
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Visual query designer"]

    bind $base <Key-F1> "Help::load visual_designer"

    # frame widget for label and combobox
    frame $base.fb \
        -height 75 \
        -width 125

    # label and combobox widgets to add a table
    Label $base.fb.ltable \
        -borderwidth 0 \
        -text [intlmsg "Add table"]
    ComboBox $base.fb.cbtable \
        -background #fefefe \
        -borderwidth 1 \
        -highlightthickness 0 \
        -values [concat [::Database::getPrefObjList Tables] \
            [::Database::getPrefObjList Views]] \
        -editable true \
        -textvariable ::VisualQueryBuilder::vqb(newtablename) \
        -modifycmd {::VisualQueryBuilder::addNewTable}

    set ::VisualQueryBuilder::Win(entertable) $base.fb.cbtable

    # butoon widgets for toolbar
    ButtonBox $base.fb.bbox \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $base.fb.bbox add \
        -borderwidth 1 \
        -image ::icon::imagegallery-22 \
        -helptext [intlmsg "Show SQL"] \
        -command VisualQueryBuilder::showSQL
    $base.fb.bbox add \
        -borderwidth 1 \
        -image ::icon::misc-16 \
        -helptext [intlmsg "Execute SQL"] \
        -command VisualQueryBuilder::executeSQL
    $base.fb.bbox add \
        -borderwidth 1 \
        -image ::icon::filesave-22 \
        -helptext [intlmsg "Save to query builder"] \
        -command VisualQueryBuilder::saveToQueryBuilder
    $base.fb.bbox add \
        -borderwidth 1 \
        -image ::icon::fileprint-22 \
        -helptext [intlmsg "Print"] \
        -command VisualQueryBuilder::print
    $base.fb.bbox add \
        -borderwidth 1 \
        -image ::icon::help-22 \
        -helptext [intlmsg "Help"] \
        -command {::Help::load visual_designer}
    $base.fb.bbox add \
        -borderwidth 1 \
        -image ::icon::exit-22 \
        -helptext [intlmsg "Close"] \
        -command {Window destroy .pgaw:VisualQuery}

    # create paned window to hold canvas and table
    set pw1 [PanedWindow $base.pw -side left]
    set pane1 [$pw1 add -minsize 100 -weight 2]
    set pane2 [$pw1 add -minsize 60 -weight 1]

    canvas $pane1.c \
        -width 295 -height 207 \
        -background #CCCCCC \
        -borderwidth 2 \
        -relief ridge \
        -takefocus 0 \
        -yscrollcommand {.pgaw:VisualQuery.pw.f0.frame.sy set} \
        -xscrollcommand {.pgaw:VisualQuery.pw.f0.frame.sx set} \
        -scrollregion {-29.7c -21.0c 29.7c 21.0c};   #scrollregion equivalent to an A2 sheet

    scrollbar $pane1.sy -command [list $pane1.c yview]
    scrollbar $pane1.sx -command [list $pane1.c xview] -orient horizontal

    place $pane1.c -x 0 -y 0 -relheight 1.0 -relwidth 1.0 -height -18 -width -18 -anchor nw
    place $pane1.sy -relx 1.0 -y 0 -relheight 1.0 -height -18 -width 18 -anchor ne
    place $pane1.sx -x -18 -relx 1.0 -rely 1.0 -relwidth 1.0 -width -18 -anchor se

    table $pane2.tb \
        -background white \
        -borderwidth 1 \
        -bordercursor crosshair \
        -colwidth 20 \
        -drawmode fast \
        -relief solid \
        -resizeborders both \
        -selectmode browse \
        -titlecols 1 -titlerows 1 \
        -yscrollcommand {.pgaw:VisualQuery.pw.f1.frame.sy set} \
        -xscrollcommand {.pgaw:VisualQuery.pw.f1.frame.sx set} \
        -variable tbquery

    scrollbar $pane2.sy -command [list $pane2.tb yview]
    scrollbar $pane2.sx -command [list $pane2.tb xview] -orient horizontal

    # Set table properties
    $pane2.tb tag config title -bg #CCCCCC -fg #000000 -anchor e
    $pane2.tb height 0 -10
    $pane2.tb width 0 -78
    #$pane2.tb tag configure sel -fg black
    $pane2.tb tag configure active -fg black

    # set up tags for the various states of the columns
    $pane2.tb tag configure HILITEcol -bg darkblue -fg white
    $pane2.tb tag configure HILITErow -bg darkblue -fg white

    place $pane2.tb -x 0 -y 0 -relheight 1.0 -relwidth 1.0 -height -18 -width -18 -anchor nw
    place $pane2.sy -relx 1.0 -y 0 -relheight 1.0 -height -18 -width 18 -anchor ne
    place $pane2.sx -x -18 -relx 1.0 -rely 1.0 -relwidth 1.0 -width [expr [$pane2.tb width 0] + -18] -anchor se

    # create popup menu
    set p $pane2.tb.pop
    menu $p -type normal
    $p add cascade -label "Delete" -underline 0 -menu $pane2.tb.pop.casd
    $p add cascade -label "Insert" -underline 0 -menu $pane2.tb.pop.casi

    # create cascade menu
    set d $pane2.tb.pop.casd
    menu $d -type normal
    $d add command -label "Column" -command {.pgaw:VisualQuery.pw.f1.frame.tb delete cols [.pgaw:VisualQuery.pw.f1.frame.tb index active col] 1}
    $d add command -label "Row" -command {.pgaw:VisualQuery.pw.f1.frame.tb delete rows [.pgaw:VisualQuery.pw.f1.frame.tb index active row] 1}

    # create cascade menu
    set i $pane2.tb.pop.casi
    menu $i -type normal
    $i add command -label "Column" -command {.pgaw:VisualQuery.pw.f1.frame.tb insert cols [.pgaw:VisualQuery.pw.f1.frame.tb index active col] -1}
    $i add command -label "Row" -command {.pgaw:VisualQuery.pw.f1.frame.tb insert rows [.pgaw:VisualQuery.pw.f1.frame.tb index active row] -1}

    # display widgets
    # frame
    pack $base.fb \
        -in $base \
        -expand 0 \
        -fill x
    # label
    pack $base.fb.ltable \
        -in $base.fb \
        -side left
    # combobox
    pack $base.fb.cbtable \
        -in $base.fb \
        -side left
    # toolbar
    pack $base.fb.bbox \
        -in $base.fb \
        -side right \
        -expand 0 \
        -fill x
    # PanedWindow
    pack $pw1 \
        -in $base \
        -expand 1 \
        -fill both

    # point to canvas
    set cv  .pgaw:VisualQuery.pw.f0.frame.c

    # some helpful key bindings for canvas
    bind $cv <Control-Key-w> [subst {destroy $base}]
    bind $cv <Key-Delete> {VisualQueryBuilder::deleteObject}
    bind $cv <Button-1> {VisualQueryBuilder::canvasClick %x %y}

    #point to table
    set tbl .pgaw:VisualQuery.pw.f1.frame.tb

    # some helpful key bindings for table
    bind $tbl <Button-1> {VisualQueryBuilder::tableButton1 %W %x %y}
    bind $tbl <Button-3> {VisualQueryBuilder::tableButton3 %W %x %y}

    # Set up events for drop on table
    # -dropcmd and -droptypes must be set for DropSite to work
    DropSite::register $tbl -dropcmd {VisualQueryBuilder::tableDrop} \
                            -droptypes [list LISTBOX_ITEM [list copy [list alt]]]
}
