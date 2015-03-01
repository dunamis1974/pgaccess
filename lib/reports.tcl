#==========================================================
# Reports --
#
#     procedures for retrieving and displaying data
#
#==========================================================
#
namespace eval Reports {
    variable Win
}


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::new {} {

    global PgAcVar

    variable Win

    Window show .pgaw:ReportBuilder:draft
    tkwait visibility .pgaw:ReportBuilder:draft
    Window show .pgaw:ReportBuilder:menu
    tkwait visibility .pgaw:ReportBuilder:menu

    design:init

    set PgAcVar(report,reportname) {}
    set PgAcVar(report,justpreview) 0

}; # end proc ::Reports::new


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::open {reportname} {

    global PgAcVar CurrentDB

    variable Win

    Window show .pgaw:ReportBuilder:draft
    tkwait visibility .pgaw:ReportBuilder:draft
    Window hide .pgaw:ReportBuilder:draft
    Window show .pgaw:ReportBuilder:menu
    tkwait visibility .pgaw:ReportBuilder:menu
    Window hide .pgaw:ReportBuilder:menu
    Window show .pgaw:ReportPreview
    tkwait visibility .pgaw:ReportPreview

    design:init
    set PgAcVar(report,reportname) $reportname
    design:loadReport
    set PgAcVar(report,justpreview) 1
    design:preview

}; # end proc ::Reports::open


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design {reportname} {

    global PgAcVar

    variable ::Reports::Win

    Window show .pgaw:ReportBuilder:draft
    tkwait visibility .pgaw:ReportBuilder:draft
    Window show .pgaw:ReportBuilder:menu
    tkwait visibility .pgaw:ReportBuilder:menu

    design:init
    set PgAcVar(report,reportname) $reportname
    design:loadReport
    set PgAcVar(report,justpreview) 0

}; # end proc ::Reports::design


#----------------------------------------------------------
# introspect --
#
#   Given a reportname, returns the SQL needed to recreate
#   it.
#
# Arguments:
#   reportname_ name of a report to introspect
#   dbh_        an optional database handle
#
# Returns:
#   insql       the INSERT statement to make this graph
#----------------------------------------------------------
#
proc ::Reports::introspect {reportname_ {dbh_ ""}} {

    set insql [::Reports::clone $reportname_ $reportname_ $dbh_]

    return $insql

}; # end proc ::Reports::introspect


#----------------------------------------------------------
# ::Reports::clone --
#
#   Like introspect, only changes the reportname
#
# Arguments:
#   srcreport_  the original report
#   destreport_ the clone report
#   dbh_        an optional database handle
#
# Returns:
#   insql       the INSERT statement to clone this report
#----------------------------------------------------------
#
proc ::Reports::clone {srcreport_ destreport_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set insql ""

    set sql "SELECT reportsource, reportbody, reportprocs, reportoptions
               FROM pga_reports
              WHERE reportname='$srcreport_'"

    wpg_select $dbh_ $sql rec {
        set insql "
            INSERT INTO pga_reports (reportsource, reportbody, reportprocs, reportoptions, reportname)
                 VALUES ('[::Database::quoteSQL $rec(reportsource)]','[::Database::quoteSQL $rec(reportbody)]','$rec(reportprocs)','$rec(reportoptions)','[::Database::quoteSQL $destreport_]');"
    }

    return $insql

}; # end proc ::Reports::clone


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:close {} {

    global PgAcVar

    variable ::Reports::Win

    catch {Window destroy $Win(draft)}
    catch {Window destroy $Win(menu)}

}; # end proc ::Reports::design:close


#----------------------------------------------------------
# ::Reports::design:drawReportAreas --
#
#   handles when the y-coord of different report areas is
#   changed
#
# Arguments:
#   none
#
# Returns:
#   none
#
# Modifies:
#   position of items in the design window canvas
#----------------------------------------------------------
#
proc ::Reports::design:drawReportAreas {} {

    global PgAcVar

    variable ::Reports::Win

    variable oldcoors
    variable newcoors

    foreach rg $PgAcVar(report,regions) {
        set oldcoors($rg) [lindex [$Win(draft).c coords bg_$rg] 1]
        $Win(draft).c delete bg_$rg
        $Win(draft).c create line \
            0 $PgAcVar(report,y_$rg) \
            5000 $PgAcVar(report,y_$rg) \
            -tags [subst {bg_$rg}]
        set newcoors($rg) [lindex [$Win(draft).c coords bg_$rg] 1]
        $Win(draft).c create rectangle \
            6 [expr {$PgAcVar(report,y_$rg)-3}] \
            12 [expr {$PgAcVar(report,y_$rg)+3}] \
            -fill black \
            -tags [subst {bg_$rg mov reg}]
        $Win(draft).c lower bg_$rg
    }

    design:getSourceFieldsForFilling

    foreach {field x y objid objtype} $PgAcVar(report,prev_fields) {
        set objmoves 0
        set movedist 0
        if {$y<$PgAcVar(report,y_rpthdr)} {
            foreach rg [list rpthdr] {
                if {$oldcoors($rg)!=$newcoors($rg) \
                  && [string length $oldcoors($rg)] > 0 \
                  && [string length $oldcoors($rg)] > 0} {
                    set objmoves 1
                    set movedist [expr {$newcoors($rg)-$oldcoors($rg)}]
                }
            }
        }
        if {$y<$PgAcVar(report,y_pghdr) && $y>$PgAcVar(report,y_rpthdr)} {
            foreach rg [list rpthdr pghdr] {
                if {$oldcoors($rg)!=$newcoors($rg) \
                  && [string length $oldcoors($rg)] > 0 \
                  && [string length $oldcoors($rg)] > 0} {
                    set objmoves 1
                    set movedist [expr {$newcoors($rg)-$oldcoors($rg)}]
                }
            }
        }
        if {$y<$PgAcVar(report,y_detail) && $y>$PgAcVar(report,y_pghdr)} {
            foreach rg [list rpthdr pghdr detail] {
                if {$oldcoors($rg)!=$newcoors($rg) \
                  && [string length $oldcoors($rg)] > 0 \
                  && [string length $oldcoors($rg)] > 0} {
                    set objmoves 1
                    set movedist [expr {$newcoors($rg)-$oldcoors($rg)}]
                }
            }
        }
        if {$y<$PgAcVar(report,y_pgfoo) && $y>$PgAcVar(report,y_detail)} {
            foreach rg [list rpthdr pghdr detail pgfoo] {
                if {$oldcoors($rg)!=$newcoors($rg) \
                  && [string length $oldcoors($rg)] > 0 \
                  && [string length $oldcoors($rg)] > 0} {
                    set objmoves 1
                    set movedist [expr {$newcoors($rg)-$oldcoors($rg)}]
                }
            }
        }
        if {$y<$PgAcVar(report,y_rptfoo) && $y>$PgAcVar(report,y_pgfoo)} {
            foreach rg [list rpthdr pghdr detail pgfoo rptfoo] {
                if {$oldcoors($rg)!=$newcoors($rg) \
                  && [string length $oldcoors($rg)] > 0 \
                  && [string length $oldcoors($rg)] > 0} {
                    set objmoves 1
                    set movedist [expr {$newcoors($rg)-$oldcoors($rg)}]
                }
            }
        }
        if {$objmoves} {
            $Win(draft).c move $objid 0 $movedist
        }
    }

}; # end proc ::Reports::design:drawReportAreas


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:toggleAlignMode {} {

    variable ::Reports::Win

    set bb [$Win(draft).c bbox hili]
    if {[llength $bb]<4} {return}
    if {[$Win(frp) cget -text]=="left"} {
        $Win(frp).balign configure -text right
        $Win(frp).balign configure -anchor e
        $Win(draft).c itemconfigure hili -anchor ne
        $Win(draft).c move hili \
            [expr {[lindex $bb 2]-[lindex $bb 0]-3}] 0
    } else {
        $Win(frp).balign configure -text left
        $Win(frp).balign configure -anchor w
        $Win(draft).c itemconfigure hili -anchor nw
        $Win(draft).c move hili \
            [expr {[lindex $bb 0]-[lindex $bb 2]+3}] 0
    }
}; # end proc ::Reports::design:toggleAlignMode


#----------------------------------------------------------
# fonts remain an issue to be dealt with
#----------------------------------------------------------
#
proc ::Reports::design:setFont {} {

    variable ::Reports::Win

    set curr_font [$Win(frp).bfont cget -text]
    if {$curr_font==""} {set curr_font "Helvetica 14"}
    set new_font [SelectFont .fontdlg -parent $Win(menu) \
        -font $curr_font -title "Select Font"]
    if {[string length [string trim $new_font]] != 0} {
        set acflo $new_font
    } else {
        set acflo $curr_font
    }    
    set actual_font $acflo
#    set actual_font "-*"
#    append actual_font "-" [font actual $acflo -family]
#    append actual_font "-" [font actual $acflo -weight]
#    append actual_font "-*"
#    append actual_font "-normal"
#    append actual_font "-"
#    append actual_font "-" [font actual $acflo -size]
#    append actual_font "-*"
#    append actual_font "-*"
#    append actual_font "-*"
#    append actual_font "-*"
#    append actual_font "-*"
#    append actual_font "-iso8859-1"

    $Win(frp).bfont configure -text "$actual_font"
    $Win(frp).bfont configure -font "$actual_font"

    design:setObjectFont

}; # end proc ::Reports::design:setFont


#----------------------------------------------------------
# fills in an array with fields that need to be filled in the form
#----------------------------------------------------------
#
proc ::Reports::design:getSourceFieldsForFilling {} {

    global PgAcVar CurrentDB

    variable ::Reports::Win

    set ol [$Win(draft).c find withtag ro]
    set PgAcVar(report,prev_fields) {}

    foreach objid $ol {
        set tags [$Win(draft).c itemcget $objid -tags]
        lappend PgAcVar(report,prev_fields) \
            [string range [lindex $tags [lsearch -glob $tags f-*]] 2 64]
        lappend PgAcVar(report,prev_fields) \
            [lindex [$Win(draft).c coords $objid] 0]
        lappend PgAcVar(report,prev_fields) \
            [lindex [$Win(draft).c coords $objid] 1]
        lappend PgAcVar(report,prev_fields) $objid
        lappend PgAcVar(report,prev_fields) \
            [lindex $tags [lsearch -glob $tags t_*]]
    }

}; # end proc ::Reports::design:getSourceFieldsForFilling


#----------------------------------------------------------
# fills in an array with columns so formulas can access them
#----------------------------------------------------------
#
proc ::Reports::design:getSourceFieldsForPreview {} {

    global PgAcVar CurrentDB

    set PgAcVar(report,source_fields) [::Database::getColumnsList $PgAcVar(report,tablename)]

}; # end proc ::Reports::design:getSourceFieldsForPreview


#----------------------------------------------------------
# fills in the drop box with column names
#----------------------------------------------------------
#
proc ::Reports::design:getSourceFieldsForFieldBox {} {

    global PgAcVar CurrentDB

    variable ::Reports::Win

    # lets really make sure we should have been called
    if {[winfo exists $Win(ffld)]} {
        # dont allow non-existent tables or views
        #if {[lsearch -exact [concat [Database::getTablesList] \
        #    [Database::getViewsList]] $PgAcVar(report,tablename)]==-1} {
        #    showError [intlmsg "That table or view doesn't exist!"]
        #    return;
        #}
        $Win(ffld).lb delete 0 end
        foreach col [::Database::getColumnsList $PgAcVar(report,tablename)] {
            $Win(ffld).lb insert end $col
        }
    }

}; # end proc ::Reports::design:getSourceFieldsForFieldBox


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:hasTag {id tg} {

    variable ::Reports::Win

    if {[lsearch [$Win(draft).c itemcget $id -tags] $tg]==-1} {
        return 0
    } else {
        return 1
    }

}; # end proc ::Reports::design:hasTag


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:init {} {

    global PgAcVar

    set PgAcVar(report,xl_auto) 10
    set PgAcVar(report,xf_auto) 10
    set PgAcVar(report,xp_auto) 10
    set PgAcVar(report,xo_auto) 10
    set PgAcVar(report,regions) {rpthdr pghdr detail pgfoo rptfoo}
    set PgAcVar(report,y_rpthdr) 0
    set PgAcVar(report,y_pghdr) 120
    set PgAcVar(report,y_detail) 240
    set PgAcVar(report,y_pgfoo) 345
    set PgAcVar(report,y_rptfoo) 345
    set PgAcVar(report,e_rpthdr) [intlmsg {Report header}]
    set PgAcVar(report,e_pghdr) [intlmsg {Page header}]
    set PgAcVar(report,e_detail) [intlmsg {Detail record}]
    set PgAcVar(report,e_pgfoo) [intlmsg {Page footer}]
    set PgAcVar(report,e_rptfoo) [intlmsg {Report footer}]

    design:drawReportAreas

}; # end proc ::Reports::design:init


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:loadReport {} {

    global PgAcVar CurrentDB

    variable ::Reports::Win

    $Win(draft).c delete all

    wpg_select $CurrentDB "
        SELECT oid,*
          FROM pga_reports
         WHERE reportname='$PgAcVar(report,reportname)'
    " rcd {
        set PgAcVar(report,oid) $rcd(oid)
        eval $rcd(reportbody)
    }

    design:changeDraftCoords
    design:getSourceFieldsForFieldBox
    design:drawReportAreas
    design:loadRegionFields

}; # end proc ::Reports::design:loadReport


#----------------------------------------------------------
# get the preview cranking
#----------------------------------------------------------
#
proc ::Reports::design:preview {} {

    global PgAcVar

#    if {[winfo exists .pgaw:ReportPreview]} {
#        tkwait visibility .pgaw:ReportPreview
#        wm withdraw .pgaw:ReportPreview
#    }

    design:previewInit
    set PgAcVar(report,curr_page) 1
    if {$PgAcVar(report,last_page)>0} {
        design:previewPage
    }

#    if {[winfo exists .pgaw:ReportPreview]} {
#        wm deiconify .pgaw:ReportPreview
#        tkwait visibility .pgaw:ReportPreview
#    }

}; # end proc ::Reports::design:preview


#----------------------------------------------------------
# finds the record and page counts
#----------------------------------------------------------
#
proc ::Reports::design:previewInit {} {

    global PgAcVar CurrentDB

    variable ::Reports::Win

    # we need to see what we are doing so show the window
    Window show .pgaw:ReportPreview
    # this makes sure we have values for the page width/height
    design:changePreviewCoords
    # set up the fields we need to fill with data
    design:getSourceFieldsForFilling
    # set up all the source fields - needed for formulas
    design:getSourceFieldsForPreview

    set sql "SELECT * 
               FROM $PgAcVar(report,tablename)"
    set res [wpg_exec $CurrentDB $sql]

    set PgAcVar(report,prev_num_recs) [pg_result $res -numTuples]
    pg_result $res -clear
    
    # set up the array of pages and records per page as it will vary
    # set PgAcVar(report,page,recs)

    # get number of detail regions per page (screw report head/foot for now)
    # first: page height - (page header height + page footer height)
    set pgdiff [expr {$PgAcVar(report,ph)-(($PgAcVar(report,y_pghdr)-$PgAcVar(report,y_rpthdr))+($PgAcVar(report,y_pgfoo)-$PgAcVar(report,y_detail)))}]
    # second: result of first / detail height
    set PgAcVar(report,max_recs_per_page) [expr {round(double($pgdiff)/double($PgAcVar(report,y_detail)-$PgAcVar(report,y_pghdr)))}]
    # third: worry about columns, thus chnage the result from second
    set PgAcVar(report,cols_per_page) [expr {int(floor(double($PgAcVar(report,pw)/$PgAcVar(report,rw))))}]
    # double check make sure we at least got one column
    if {$PgAcVar(report,cols_per_page)>1} {
        set PgAcVar(report,max_recs_per_page) [expr {$PgAcVar(report,max_recs_per_page)*$PgAcVar(report,cols_per_page)}]
    } else {
        set PgAcVar(report,cols_per_page) 1
    }
    # get number of pages
    set PgAcVar(report,last_page) [expr {int(ceil(double($PgAcVar(report,prev_num_recs))/double($PgAcVar(report,max_recs_per_page))))}]
    set PgAcVar(report,total_page) $PgAcVar(report,last_page)

}; # end proc ::Reports::design:previewInit


#----------------------------------------------------------
# displays one region
#----------------------------------------------------------
#
proc ::Reports::design:previewRegion {x y objid objtype py recfield shown_recs tuples_list} {

    global PgAcVar CurrentDB

    variable ::Reports::Win

# for fields
if {$objtype=="t_f"} {
    $Win(preview).fr.c create text $x [expr {$py+$y}] \
        -text $recfield \
        -font "[$Win(draft).c itemcget $objid -font]" \
        -anchor [$Win(draft).c itemcget $objid -anchor]
}

# for labels
if {$objtype=="t_l"} {
    $Win(preview).fr.c create text $x [expr {$py+$y}] \
    -text [$Win(draft).c itemcget $objid -text] \
    -font "[$Win(draft).c itemcget $objid -font]" -anchor nw
}

# for pictures
if {$objtype=="t_p"} {
    $Win(preview).fr.c create image $x [expr {$py+$y}] \
        -image [image create photo -file [$Win(draft).c \
            itemcget $objid -image]] \
        -anchor nw
}

# for formulas
if {$objtype=="t_o"} {
    # assign each source field to a variable from the tuples
    for {set c 0} {$c<[llength $tuples_list]} {incr c 2} {
        variable [lindex $tuples_list $c] [lindex $tuples_list [expr {$c+1}]]    
    }
    # compute the formula
    set formula_text [$Win(draft).c itemcget $objid -text]
    set formula_result ""
    # is it a function
    if {[regexp "^Function::" $formula_text]} {
        set func [string range $formula_text [string length "Function::"] end]
        # this SELECT should probably be moved into the SELECT for the page
        set sql "SELECT [subst $func]"
        set func_paren [string range $func 0 \
            [expr {[string first "(" $func]-1}]]
        wpg_select $CurrentDB $sql frec {
            set formula_result $frec($func_paren)
        }
        $Win(preview).fr.c create text $x [expr {$py+$y}] \
            -text $formula_result \
            -font "[$Win(draft).c itemcget $objid -font]" \
            -anchor nw
    # is it picture data
    } elseif {[regexp "^ImageData::" $formula_text]} {
        set imgdata [string range $formula_text \
            [string length "ImageData::"] end]
        $Win(preview).fr.c create image $x [expr {$py+$y}] \
            -image [image create photo -data [subst $imgdata]] -anchor nw
    # is it a pgaccess image
    } elseif {[regexp "^PGAImage::" $formula_text]} {
        set pgaimg [string range $formula_text \
            [string length "ImageData::"] end]
        set imgdata [::Images::get $pgaimg]
        $Win(preview).fr.c create image $x [expr {$py+$y}] \
            -image [image create photo -data [subst $imgdata]] -anchor nw
    # is it a barcode
    } elseif {[regexp "^Barcode::" $formula_text]} {
        set ft [subst [string range $formula_text [string length "Barcode::"] end]]
        set height [string trim [lindex [split $ft] 1]]
        set bc [string trim [lindex [split $ft] 2]]
        set bcpad $bc
        for {set i [string length $bc]} {$i < 12} {incr i} {
            set bcpad "0$bcpad"
        }
        set bst [::Barcode::Code $bcpad]
        for {set i 0} {$i < 95} {incr i} {
            if {[string index $bst $i]} {
                $Win(preview).fr.c create rectangle \
                    [expr {$x + 10 + $i}] [expr {$py+$y}] \
                    [expr {$x + 11 + $i}] [expr {$py+$y+$height}] \
                    -fill black \
                    -width 0
            }
        }
    # well it must just be tcl code then
    } else {
        set formula_result [eval $formula_text]
        $Win(preview).fr.c create text $x [expr {$py+$y}] \
            -text $formula_result \
            -font "[$Win(draft).c itemcget $objid -font]" \
            -anchor nw
    }
}

}; # end proc ::Reports::design:previewRegion


#----------------------------------------------------------
# displays the current page
# for now we worry about the page head/foot and detail, not report head/foot
#----------------------------------------------------------
#
proc ::Reports::design:previewPage {} {

    global PgAcVar CurrentDB

    variable ::Reports::Win

set sql ""
set recfield ""

$Win(preview).fr.c delete all

set shown_recs [expr {($PgAcVar(report,curr_page)-1)*$PgAcVar(report,max_recs_per_page)}]

# get data for all the records on this page
set sql "SELECT * 
           FROM $PgAcVar(report,tablename)
          LIMIT $PgAcVar(report,max_recs_per_page)
         OFFSET [expr {($PgAcVar(report,curr_page)-1)*$PgAcVar(report,max_recs_per_page)}]"
set page_res [wpg_exec $CurrentDB $sql]

# well if there arent any records theres really no point in continuing
if {[pg_result $page_res -numTuples]<1} {return}

# parse the page header
set py $PgAcVar(report,y_rpthdr)
# we only want the first tuple for the page header
pg_result $page_res -tupleArray 0 tuples
foreach {field x y objid objtype} $PgAcVar(report,prev_fields) {
    if {$y < $PgAcVar(report,y_pghdr)} {
        # make sure we line up the region where it was designed to go
        set y [expr {$y-$PgAcVar(report,y_rpthdr)}]
        # looking for fields
        if {$objtype=="t_f"} {
            set recfield [lindex [array get tuples $field] 1]
        } else {
            set recfield ""
        }
        design:previewRegion $x $y $objid $objtype $py \
            $recfield $shown_recs [array get tuples]
    }
}

# Parsing detail group
set shown_detail_recs 0
# loop thru the printing of each column
for {set col 0} {$col<$PgAcVar(report,cols_per_page)} {incr col} {
    set py $PgAcVar(report,y_pghdr)

    # get all the recs on the page
    while {($py < [expr {($PgAcVar(report,ph)-($PgAcVar(report,y_detail)-$PgAcVar(report,y_pghdr)))}]) \
        && ($shown_recs<$PgAcVar(report,prev_num_recs))} {
        # get fields we need to fill
        foreach {field x y objid objtype} $PgAcVar(report,prev_fields) {
            # now lets get some data for a record
            # well this is a little bit of a hack
            # but at least the catch makes sure we get all the records we can
            catch {
                pg_result $page_res -tupleArray $shown_detail_recs tuples
                if {$y > $PgAcVar(report,y_pghdr) \
                    && $y < $PgAcVar(report,y_detail)} {
                    set y [expr {$y-$PgAcVar(report,y_pghdr)}]
                    if {$objtype=="t_f"} {
                        set recfield [lindex [array get tuples $field] 1]
                    } else {
                        set recfield ""
                    }
                    design:previewRegion \
                        [expr {$x+($PgAcVar(report,rw)*$col)}] \
                        $y $objid $objtype $py $recfield $shown_recs \
                        [array get tuples]
                }
            }
        }
        incr shown_recs
        incr shown_detail_recs
        incr py [expr {$PgAcVar(report,y_detail)-$PgAcVar(report,y_pghdr)}]
    }
}

# parse the page footer
# put it in the same place on each page
set py [expr {(($PgAcVar(report,y_detail)-$PgAcVar(report,y_pghdr))*$PgAcVar(report,max_recs_per_page))+$PgAcVar(report,y_pghdr)}]
# get the data for the region, which is the last record on the page
pg_result $page_res \
    -tupleArray [expr {[pg_result $page_res -numTuples]-1}] tuples
foreach {field x y objid objtype} $PgAcVar(report,prev_fields) {
    if {$y > $PgAcVar(report,y_detail) && $y < $PgAcVar(report,y_pgfoo)} {
        set y [expr {$y-$PgAcVar(report,y_detail)}]
        if {$objtype=="t_f"} {
            set recfield [lindex [array get tuples $field] 1]
        } else {
            set recfield ""
        }
        design:previewRegion $x $y $objid $objtype $py $recfield \
            [expr {$shown_recs-1}] [array get tuples]
    }
}

pg_result $page_res -clear

}; # end proc ::Reports::design:previewPage


#----------------------------------------------------------
# opens the print dialog and registers the callback function
#----------------------------------------------------------
#
proc ::Reports::design:print {} {

    ::Printer::init "::Reports::design:printcallback"

}; # end proc ::Reports::design:print


#----------------------------------------------------------
# prints all pages between and including those in the entry boxes
# gets a channel from print dialog and starts feeding it postscript
#----------------------------------------------------------
#
proc ::Reports::design:printcallback {fid} {

    global PgAcVar

    variable ::Reports::Win

    Printer::printStart $fid $PgAcVar(report,pw) $PgAcVar(report,ph) \
        [expr {$PgAcVar(report,last_page)-$PgAcVar(report,curr_page)+1}]

    set start_page $PgAcVar(report,curr_page)

    for {set pgcnt 1} \
        {$PgAcVar(report,curr_page)<=$PgAcVar(report,last_page)} \
        {incr PgAcVar(report,curr_page)} {
            design:previewPage
            Printer::printPage $fid $pgcnt $Win(preview).fr.c
            incr pgcnt
    }

    Printer::printStop $fid

    # reset current page to the page we started printing on
    set PgAcVar(report,curr_page) $start_page
    design:previewPage

}; # end proc ::Reports::design:printcallback


#----------------------------------------------------------
# ::Reports::design:save --
#
#   Saves the report meta-data, or saves a copy of it.
#
# Arguments:
#   copy_   0 default of regular save, 1 for saving a copy
#----------------------------------------------------------
#
proc ::Reports::design:save {{copy_ 0}} {

    global PgAcVar CurrentDB

    variable ::Reports::Win

    # do not allow empty report names
    if {[string length $PgAcVar(report,reportname)]==0} {
        showError [intlmsg "You must supply a name for the report before you can save it!"]
        return
    }

    set prog "set PgAcVar(report,tablename) {$PgAcVar(report,tablename)}"
    append prog " ; set PgAcVar(report,rw) $PgAcVar(report,rw)"
    append prog " ; set PgAcVar(report,rh) $PgAcVar(report,rh)"
    append prog " ; set PgAcVar(report,pw) $PgAcVar(report,pw)"
    append prog " ; set PgAcVar(report,ph) $PgAcVar(report,ph)"
    foreach region $PgAcVar(report,regions) {
        append prog " ; set PgAcVar(report,y_$region) $PgAcVar(report,y_$region)"
    }

    foreach obj [$Win(draft).c find all] {

        if {[$Win(draft).c type $obj]=="text"} {
            set bb [$Win(draft).c bbox $obj]
            if {[$Win(draft).c itemcget $obj -anchor]=="nw"} {
                set x [expr {[lindex $bb 0]+1}]
            } else {
                set x [expr {[lindex $bb 2]-2}]
            }
            append prog " ; $Win(draft).c create text $x [lindex $bb 1] -font \"[$Win(draft).c itemcget $obj -font]\" -anchor [$Win(draft).c itemcget $obj -anchor] -text {[string map {\' \\'} [$Win(draft).c itemcget $obj -text]]} -tags {[$Win(draft).c itemcget $obj -tags]}"
        }

        if {[$Win(draft).c type $obj]=="image"} {
            set bb [$Win(draft).c bbox $obj]
            if {[$Win(draft).c itemcget $obj -anchor]=="nw"} {
                set x [expr {[lindex $bb 0]+1}]
            } else {
                set x [expr {[lindex $bb 2]-2}]
            }
            append prog " ; image create photo [$Win(draft).c itemcget $obj -image] -file [$Win(draft).c itemcget $obj -image] ; $Win(draft).c create image $x [lindex $bb 1] -anchor [$Win(draft).c itemcget $obj -anchor] -image {[$Win(draft).c itemcget $obj -image]} -tags {[$Win(draft).c itemcget $obj -tags]}"
        }
    }

    if {$copy_ == 0 && [info exists PgAcVar(report,oid)]} {
        sql_exec noquiet "
            DELETE FROM pga_reports
                  WHERE oid=$PgAcVar(report,oid)"
    }

    sql_exec noquiet "
        INSERT INTO pga_reports (reportname,reportsource,reportbody)
             VALUES ('$PgAcVar(report,reportname)','$PgAcVar(report,tablename)','$prog')"

    # refresh OID
    set res [wpg_exec $CurrentDB "
        SELECT oid
          FROM pga_reports
         WHERE reportname='$PgAcVar(report,reportname)'
         "]
    set PgAcVar(report,oid) [lindex [pg_result $res -getTuple 0] 0]
    pg_result $res -clear

    # refresh right pane
    ::Mainlib::cmd_Reports

}; # end proc ::Reports::design:save


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:addField {} {

    global PgAcVar

    variable ::Reports::Win

    set fldname [$Win(ffld).lb get \
        [$Win(ffld).lb curselection]]
    set newid [$Win(draft).c create text \
        $PgAcVar(report,xf_auto) [expr {$PgAcVar(report,y_pghdr)+5}] \
        -text $fldname -tags [subst {f-$fldname t_f rg_detail mov ro}] \
        -anchor nw -font "$PgAcVar(pref,font_normal)"]
    set bb [$Win(draft).c bbox $newid]
    incr PgAcVar(report,xf_auto) [expr {5+[lindex $bb 2]-[lindex $bb 0]}]
    $Win(frgf).lbrgdetail insert end "$newid - $fldname"

}; # end proc ::Reports::design:addField


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:addLabel {} {

    global PgAcVar

    variable ::Reports::Win

    set fldname $PgAcVar(report,labeltext)
    set newid [$Win(draft).c create text \
        $PgAcVar(report,xl_auto) [expr {$PgAcVar(report,y_rpthdr)+5}] \
        -text $fldname -tags [subst {t_l mov ro}] \
        -anchor nw -font "$PgAcVar(pref,font_normal)"]
    set bb [$Win(draft).c bbox $newid]

    incr PgAcVar(report,xl_auto) [expr {5+[lindex $bb 2]-[lindex $bb 0]}]

}; # end proc ::Reports::design:addLabel


#----------------------------------------------------------
# browse for pictures
#----------------------------------------------------------
#
proc ::Reports::design:browsePicture {} {

    global PgAcVar

    set types {
        {{GIF Files}    {.gif}}
        {{BMP Files}    {.bmp}}
        {{All Files}    *}
    }

    set PgAcVar(report,picture) [tk_getOpenFile \
        -filetypes $types -title "Choose Picture"]

}; # end proc ::Reports::design:browsePicture


#----------------------------------------------------------
# pictures are from files and not the database, maybe this should be different
#----------------------------------------------------------
#
proc ::Reports::design:addPicture {} {

    global PgAcVar

    variable ::Reports::Win

    set fldname $PgAcVar(report,picture)
    if {[file exists $fldname]} {
        set newid [$Win(draft).c create image \
            $PgAcVar(report,xp_auto) [expr {$PgAcVar(report,y_rpthdr)+5}] \
            -image [image create photo $fldname -file $fldname] \
            -tags [subst {t_p mov ro}] -anchor nw]
        set bb [$Win(draft).c bbox $newid]
        incr PgAcVar(report,xp_auto) [expr {5+[lindex $bb 2]-[lindex $bb 0]}]
    }

}; # end proc ::Reports::design:addPicture


#----------------------------------------------------------
# formulas are tcl snippets or functions, could be scripts sometime too
#----------------------------------------------------------
#
proc ::Reports::design:addFormula {} {

    global PgAcVar

    variable ::Reports::Win

    set fldname $PgAcVar(report,formula)
    set newid [$Win(draft).c create text \
        $PgAcVar(report,xo_auto) [expr {$PgAcVar(report,y_rpthdr)+5}] \
        -text $fldname -tags [subst {t_o mov ro}] \
        -anchor nw -font "$PgAcVar(pref,font_normal)"]
    set bb [$Win(draft).c bbox $newid]

    incr PgAcVar(report,xo_auto) [expr {5+[lindex $bb 2]-[lindex $bb 0]}]

}; # end proc ::Reports::design:addFormula


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:setObjectFont {} {

    global PgAcVar

    variable ::Reports::Win

    $Win(draft).c itemconfigure hili \
        -font "[$Win(frp).bfont cget -text]"

}; # end proc ::Reports::design:setObjectFont


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:updateObject {} {

    global PgAcVar

    variable ::Reports::Win

    set obj [$Win(draft).c find withtag hili] 
    if {[design:hasTag $obj t_l]} {
        $Win(draft).c itemconfigure hili \
            -text $PgAcVar(report,labeltext)
    } elseif {[design:hasTag $obj t_o]} {
        $Win(draft).c itemconfigure hili \
            -text $PgAcVar(report,formula)
    }

}; # end proc ::Reports::design:updateObject


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:deleteObject {} {

    variable ::Reports::Win

    if {[tk_messageBox -title [intlmsg Warning] \
        -parent $Win(draft) -message "Delete current report object?" \
        -type yesno -default no]=="no"} return;
    set obj [$Win(draft).c find withtag hili]
    if {[design:hasTag $obj t_f]} {
        set rg [design:determineRegion [lindex [$Win(draft).c coords $obj] 1]]
        set lbindex [lsearch -regexp [$Win(frgf).lbrg$rg get 0 end] "^$obj"]
        $Win(frgf).lbrg$rg delete $lbindex $lbindex
    }

    $Win(draft).c delete hili

}; # end proc ::Reports::design:deleteObject


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:dragMove {w x y} {

    global PgAcVar

    # Showing current region
    if {![info exists PgAcVar(report,regions)]} {return}

    foreach rg $PgAcVar(report,regions) {
        set PgAcVar(report,msg) $PgAcVar(report,e_$rg)
        if {$PgAcVar(report,y_$rg)>$y} break;
    }

    set temp {}

    catch {set temp $PgAcVar(draginfo,obj)}

    if {"$temp" != ""} {
        set dx [expr {$x - $PgAcVar(draginfo,x)}]
        set dy [expr {$y - $PgAcVar(draginfo,y)}]
        if {$PgAcVar(draginfo,region)!=""} {
            set x $PgAcVar(draginfo,x)
            $w move bg_$PgAcVar(draginfo,region) 0 $dy
        } else {
            $w move $PgAcVar(draginfo,obj) $dx $dy
        }
        set PgAcVar(draginfo,x) $x
        set PgAcVar(draginfo,y) $y
    }

}; # end proc ::Reports::design:dragMove


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:dragStart {w x y} {

    global PgAcVar

    variable ::Reports::Win

focus $Win(draft).c
catch {unset draginfo}
set obj {}

# Only movable objects start dragging
foreach id [$w find overlapping $x $y $x $y] {
    if {[design:hasTag $id mov]} {
        set obj $id
        break
    }
}

# mouse resize does update after a click
if {$obj==""} {
    $Win(draft).c configure -cursor watch
    set c [split [winfo geometry $Win(draft).c] x+]
    set PgAcVar(report,rw) [lindex $c 0]
    set PgAcVar(report,rh) [lindex $c 1]
    Reports::design:changeDraftCoords
    return
}

set PgAcVar(draginfo,obj) $obj
set taglist [$Win(draft).c itemcget $obj -tags]
set i [lsearch -glob $taglist bg_*]

if {$i==-1} {
    set PgAcVar(draginfo,region) {}
} else {
    set PgAcVar(draginfo,region) [string range [lindex $taglist $i] 3 64]
}

$Win(draft).c configure -cursor hand1
# dont highlight pictures when moving them, it just wont work
if {![design:hasTag [$Win(draft).c find withtag hili] t_p]} {
    $Win(draft).c itemconfigure \
        [$Win(draft).c find withtag hili] -fill black
}
    $Win(draft).c dtag \
        [$Win(draft).c find withtag hili] hili
    $Win(draft).c addtag hili withtag $PgAcVar(draginfo,obj)
if {![design:hasTag $obj t_p]} {
    $Win(draft).c itemconfigure hili -fill blue
}
set PgAcVar(draginfo,x) $x
set PgAcVar(draginfo,y) $y
set PgAcVar(draginfo,sx) $x
set PgAcVar(draginfo,sy) $y
# Setting font information
if {[$Win(draft).c type hili]=="text"} {
    $Win(frp).bfont configure \
        -text [$Win(draft).c itemcget hili -font]
    if {[$Win(draft).c itemcget $obj -anchor]=="nw"} {
        $Win(frp).balign configure -text left
        $Win(frp).balign configure -anchor w
    } else {
        $Win(frp).balign configure -text right
        $Win(frp).balign configure -anchor e
    }
}

if {[design:hasTag $obj t_f]} {
    set PgAcVar(report,info) "Database field"
    design:selectField $obj
}
if {[design:hasTag $obj t_l]} {
    set PgAcVar(report,info) "Label"
    set PgAcVar(report,labeltext) \
        [$Win(draft).c itemcget $obj -text]
}
if {[design:hasTag $obj t_o]} {
    set PgAcVar(report,info) "Formula"
    set PgAcVar(report,formula) [$Win(draft).c itemcget $obj -text]
}
if {[design:hasTag $obj t_p]} {
    set PgAcVar(report,info) "Picture"
    set PgAcVar(report,picture) \
        [$Win(draft).c itemcget $obj -image]
}

}; # end proc ::Reports::design:dragStart


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:dragStop {x y} {

    global PgAcVar

    variable ::Reports::Win

# when click Close, ql window is destroyed but event ButtonRelease-1 is fired
if {![winfo exists $Win(draft).c]} return;
$Win(draft).c configure -cursor left_ptr
set este {}
catch {set este $PgAcVar(draginfo,obj)}
if {$este==""} return
# Erase information about object beeing dragged
if {$PgAcVar(draginfo,region)!=""} {
    set dy 0
    foreach rg $PgAcVar(report,regions) {
        $Win(draft).c move rg_$rg 0 $dy
        if {$rg==$PgAcVar(draginfo,region)} {
            set dy [expr {$y-$PgAcVar(report,y_$PgAcVar(draginfo,region))}]
        }
        incr PgAcVar(report,y_$rg) $dy
    }
#    .pgaw:ReportBuilder:menu.c move det 0 [expr $y-$PgAcVar(report,y_$PgAcVar(draginfo,region))]
    set PgAcVar(report,y_$PgAcVar(draginfo,region)) $y
    design:drawReportAreas
} else {
    # Check if object beeing dragged is inside the canvas
    set bb [$Win(draft).c bbox $PgAcVar(draginfo,obj)]
    # too far to the left
    if {[lindex $bb 0] < 5} {
        $Win(draft).c move $PgAcVar(draginfo,obj) \
            [expr {5-[lindex $bb 0]}] 0
    }
    # too far to the right
    if {[lindex $bb 0] > [expr {$PgAcVar(report,rw)-10}]} {
        $Win(draft).c move $PgAcVar(draginfo,obj) \
            [expr {$PgAcVar(report,rw)-25-[lindex $bb 0]}] 0
    }
    # too far above
    if {[lindex $bb 1] < 2} {
        $Win(draft).c move $PgAcVar(draginfo,obj) \
            0 [expr {2-[lindex $bb 1]}]
    }
    # too far below canvas
    if {[lindex $bb 1] > [expr {$PgAcVar(report,rh)-10}]} {
        $Win(draft).c move $PgAcVar(draginfo,obj) \
            0 [expr {$PgAcVar(report,rh)-15-[lindex $bb 1]}]
    }
    # too far below report footer
    if {[lindex $bb 1] > [expr {$PgAcVar(report,y_rptfoo)-10}]} {
        $Win(draft).c move $PgAcVar(draginfo,obj) \
            0 [expr {$PgAcVar(report,y_rptfoo)-15-[lindex $bb 1]}]
    }
    # if a field is being moved check if it changed regions
    if {[design:hasTag $PgAcVar(draginfo,obj) t_f]} {
        set bb [$Win(draft).c bbox $PgAcVar(draginfo,obj)]
        set newrg [design:determineRegion [lindex $bb 1]]
        foreach rg $PgAcVar(report,regions) {
            set lbindex [lsearch -regexp [$Win(frgf).lbrg$rg get 0 end] \
                "^$PgAcVar(draginfo,obj)"]
            if {$lbindex!=-1 && ![string match $rg $newrg]} {
                $Win(frgf).lbrg$rg delete $lbindex $lbindex
                if {[string length $newrg]>0} {
                    $Win(frgf).lbrg$newrg insert end \
                        [concat $PgAcVar(draginfo,obj) - \
                        [$Win(draft).c itemcget $PgAcVar(draginfo,obj) -text]]
                }    
                break
            }
        }
        design:selectField $PgAcVar(draginfo,obj)
    }
}
set PgAcVar(draginfo,obj) {}
PgAcVar:clean draginfo,*

}; # end proc ::Reports::design:dragStop


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:deleteAllObjects {} {

    variable ::Reports::Win

    if {[tk_messageBox -title [intlmsg Warning] \
        -parent $Win(draft) \
        -message [intlmsg "All report information will be deleted.\n\nProceed ?"] -type yesno -default no]=="yes"} then {
        $Win(draft).c delete all
        design:init
        design:drawReportAreas
    }

}; # end proc ::Reports::design:deleteAllObjects


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:changeDraftCoords {} {

    global PgAcVar

    variable ::Reports::Win

    # make sure we have a report width and height, if not default something
    if {[string length $PgAcVar(report,rw)]==0} {
        set PgAcVar(report,rw) 508
    }

    if {[string length $PgAcVar(report,rh)]==0} {
        set PgAcVar(report,rh) 345
    }

    wm geometry $Win(draft) \
        $PgAcVar(report,rw)x$PgAcVar(report,rh)
    place $Win(draft).c -x 0 -y 0 \
        -width $PgAcVar(report,rw) -height $PgAcVar(report,rh) \
        -anchor nw -bordermode ignore

}; # end proc ::Reports::design:changeDraftCoords


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::Reports::design:changePreviewCoords {} {

    global PgAcVar

    variable ::Reports::Win

    # make sure we have a page width and height, if not default something
    if {![info exists PgAcVar(report,pw)] || \
        [string length $PgAcVar(report,pw)]<=1} {
        set PgAcVar(report,pw) 508
    }

    if {![info exists PgAcVar(report,ph)] || \
        [string length $PgAcVar(report,ph)]<=1} {
        set PgAcVar(report,ph) 345
    }

    # check the geometry so you dont have to resize in order to print
    set g ""
    set w $PgAcVar(report,pw)
    set h $PgAcVar(report,ph)
    if {$PgAcVar(report,pw) < 350} {
        set w 350
    }
    if {$PgAcVar(report,ph) < 100} {
        set h 100
    }
    append g $w "x" $h
    wm geometry $Win(preview) $g
    place $Win(preview).fr.c -x 0 -y 0 \
        -width $PgAcVar(report,pw) -height $PgAcVar(report,ph) \
        -anchor nw -bordermode ignore
    wm deiconify $Win(preview)

}; # end proc ::Reports::design:changePreviewCoords


#----------------------------------------------------------
# fills the list box for each region with the fields in that region
#----------------------------------------------------------
#
proc ::Reports::design:loadRegionFields {} {

    global PgAcVar

    variable ::Reports::Win

    design:getSourceFieldsForFilling

    foreach {field x y objid objtype} $PgAcVar(report,prev_fields) {
        if {$objtype=="t_f"} {
            if {$y<$PgAcVar(report,y_rpthdr)} {
                $Win(frgf).lbrgrpthdr insert end \
                    [concat $objid - [$Win(draft).c \
                    itemcget $objid -text]]
            }
            if {$y<$PgAcVar(report,y_pghdr) && $y>$PgAcVar(report,y_rpthdr)} {
                $Win(frgf).lbrgpghdr insert end \
                    [concat $objid - [$Win(draft).c \
                    itemcget $objid -text]]
            }
            if {$y<$PgAcVar(report,y_detail) && $y>$PgAcVar(report,y_pghdr)} {
                $Win(frgf).lbrgdetail insert end \
                    [concat $objid - [$Win(draft).c \
                    itemcget $objid -text]]
            }
            if {$y<$PgAcVar(report,y_pgfoo) && $y>$PgAcVar(report,y_detail)} {
                $Win(frgf).lbrgpgfoo insert end \
                    [concat $objid - [$Win(draft).c \
                    itemcget $objid -text]]
            }
            if {$y<$PgAcVar(report,y_rptfoo) && $y>$PgAcVar(report,y_pgfoo)} {
                $Win(frgf).lbrgrptfoo insert end \
                    [concat $objid - [$Win(draft).c \
                    itemcget $objid -text]]
            }
        }
    }

}; # end proc ::Reports::design:loadRegionFields


#----------------------------------------------------------
# given a y value detemines region item is in and returns it
#----------------------------------------------------------
#
proc ::Reports::design:determineRegion {y} {

    global PgAcVar

    set retval ""

    if {$y<$PgAcVar(report,y_rpthdr)} {
        set retval "rpthdr"
    }
    if {$y<$PgAcVar(report,y_pghdr) && $y>$PgAcVar(report,y_rpthdr)} {
        set retval "pghdr"
    }
    if {$y<$PgAcVar(report,y_detail) && $y>$PgAcVar(report,y_pghdr)} {
        set retval "detail"
    }
    if {$y<$PgAcVar(report,y_pgfoo) && $y>$PgAcVar(report,y_detail)} {
        set retval "pgfoo"
    }
    if {$y<$PgAcVar(report,y_rptfoo) && $y>$PgAcVar(report,y_pgfoo)} {
        set retval "rptfoo"
    }

    return $retval

}; # end proc ::Reports::design:determineRegion


#----------------------------------------------------------
# gets info on the selected field in a region by clicking in the menu window
#----------------------------------------------------------
#
proc ::Reports::design:selectRegionFieldFromMenu {w x y} {

    global PgAcVar

    set objid [lindex [split [$w get [$w nearest $y]]] 0]

    design:selectField $objid

}; # end proc ::Reports::design:selectRegionFieldFromMenu


#----------------------------------------------------------
# highlight the field, select it in the listbox, and determine if group/ordered
#----------------------------------------------------------
#
proc ::Reports::design:selectField {objid} {

    global PgAcVar

    variable ::Reports::Win

    set grp [lsearch -exact [$Win(draft).c find withtag "grouped"] $objid]
    set ord [lsearch -exact [$Win(draft).c find withtag "ordered"] $objid]
    set rg [design:determineRegion [lindex [$Win(draft).c coords $objid] 1]]
    # highlight the item (in case it isnt already)
    $Win(draft).c itemconfigure [$Win(draft).c find withtag hili] -fill black
    $Win(draft).c dtag [$Win(draft).c find withtag hili] hili
    $Win(draft).c addtag hili withtag $objid
    $Win(draft).c itemconfigure $objid -fill blue
    # clears then selects the item in the listbox (in case it isnt already)
    # check first to see if we are actually in a region
    if {[string length $rg]>0} {
        set lbindex [lsearch -regexp [$Win(frgf).lbrg$rg get 0 end] "^$objid"]
        $Win(frgf).lbrg$rg selection clear 0 end
        $Win(frgf).lbrg$rg activate $lbindex
        $Win(frgf).lbrg$rg selection set $lbindex $lbindex
        $Win(frgf).lbrg$rg see $lbindex
    }
    # deselect all the checkbuttons for group/order
    foreach oldrg {pghdr detail pgfoo} {
        $Win(frgf).cbgrouped$oldrg deselect
        $Win(frgf).cbordered$oldrg deselect
    }
    # make sure we are in a region that can group/order by field items
    if {[lsearch {pghdr detail pgfoo} $rg]!=-1} {
        # set the grouped/ordered checkbuttons if the item is grouped/ordered
        if {$grp!=-1} {
            $Win(frgf).cbgrouped$rg select
        }
        if {$ord!=-1} {
            $Win(frgf).cbordered$rg select
        }
    }

}; # end proc ::Reports::design:selectField


#----------------------------------------------------------
# adds or deletes tags for grouping / ordering on a field in a region
# og is set to either grouped or ordered when it is called from checkbuttons
#----------------------------------------------------------
#
proc ::Reports::design:toggleGroupingAndOrdering {cb rg og} {

    global PgAcVar

    set lb "lbrg$rg"
    # see if anything in this region's listbox is selected
    set cursel [$Win(frgf).$lb curselection] 
    if {$cursel!=""} {
        # find the objid from the listbox
        set objid [lindex [split [$Win(frgf).$lb get [lindex $cursel 0]]] 0]
        # check to see if we are currently being grouped / ordered
        set grp_ord [lsearch -exact [$Win(draft).c find withtag $og] $objid]
        # either add a tag or delete one, depends on checkbox 
        if {$cb==1} {
            if {$grp_ord==-1} {
                $Win(draft).c addtag $og withtag $objid
            }
        } else {
            # check to see if we are already being grouped / ordered
            if {$grp_ord!=-1} {
                $Win(draft).c dtag $objid $og
            }
        }
    }

}; # end proc ::Reports::design:toggleGroupingAndOrdering



#==========================================================
# The new portion of the Reports namespace follows.
#==========================================================



# ------------------------------------------------------------------------------
# Report
# ------------------------------------------------------------------------------
namespace eval ::Reports {
    variable Name
    variable RecSource
    variable Filter
    variable FilterOn
    variable OrderBy
    variable OrderByOn
    variable Caption
    variable RecLocks
    variable PageHead
    variable PageFoot
    variable DateGroup
    variable KeepTogether
    variable Width
    variable Pic
    variable PicType
    variable PicSizeMode
    variable PicAlign
    variable PicTiling
    variable PicPages
    variable MenuBar
    variable Toolbar
    variable ShortMenuBar
    variable GridX
    variable GridY
    variable LayoutPrint
    variable FastLaser
    variable HelpFile
    variable HelpContextID
    variable PaletteSrc
    variable Tag
    variable OnOpen
    variable OnClose
    variable OnActivate
    variable OnDeactivate
    variable OnNoData
    variable OnPage
    variable OnError
    variable HasModule
}

# ------------------------------------------------------------------------------
# Command ::Reports::create
#
# Values MSAccess uses for properties
# RecLocks - No Locks, All Records
# PageHead - All Pages, Not with Rpt Hdr, Not with Rpt Ftr, Not with Rpt Hdr/Ftr
# PageFoot - All Pages, Not with Rpt Hdr, Not with Rpt Ftr, Not with Rpt Hdr/Ftr
# DateGroup - Use System Settings, US Default
# KeepTogether - Per Column, Per Page
# Pic - The actual path to the picture
# PicType - Embedded, Link
# PicSizeMode - Clip, Stretch, Zoom
# PicPages - All Pages, First Page, No Pages
# OnOpen - [Event Procedure]- User written TCL script
# OnClose - [Event Procedure]- User written TCL script 
# OnActivate - [Event Procedure]- User written TCL script 
# OnDeactivate - [Event Procedure]- User written TCL script 
# OnNoData - [Event Procedure]- User written TCL script 
# OnPage - [Event Procedure]- User written TCL script 
# OnError - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc ::Reports::create {path args} {

    variable $path
    upvar 0 $path data

    set Name {};      # Need to add code to increment Report 1, Report 2, ect...
    set RecSource {}; # Can be a query or table
    set Filter    {}
    set FilterOn 0
    set OrderBy {}
    set OrderByOn 0
    set Caption {}
    set RecLocks [intlmsg {No Locks}]
    set PageHead [intlmsg {All Pages}]
    set PageFoot [intlmsg {All Pages}]
    set DateGroup [intlmsg {Use System Settings}]
    set KeepTogether [intlmsg {Per Column}]
    set Width "5\""
    set Pic {(none)}
    set PicType [intlmsg {Embedded}]
    set PicSizeMode [intlmsg {Clip}]
    set PicAlign [intlmsg {Center}]
    set PicTiling 0
    set PicPages [intlmsg {All Pages}]
    set MenuBar {}
    set Toolbar {}
    set ShortMenuBar {}
    set GridX 24
    set GridY 24
    set LayoutPrint 1
    set FastLaser 1
    set HelpFile {}
    set HelpContextID 0
    set PaletteSrc {(Default)}
    set Tag {}
    set OnOpen {}
    set OnClose {}
    set OnActivate {}
    set OnDeactivate {}
    set OnNoData {}
    set OnPage {}
    set OnError {}
    set HasModule 0

}; # end proc ::Reports::create


# ------------------------------------------------------------------------------
# Report Header
# ------------------------------------------------------------------------------
namespace eval ::Reports::Head {
    variable Name
    variable ForceNewPg
    variable NewRowCol
    variable KeepTogether
    variable Visible
    variable Grow
    variable Shrink
    variable Heigh
    variable BackColor
    variable SpecEffect
    variable Tag
    variable OnFormat
    variable OnPrint
    variable OnRetreat
}

# ------------------------------------------------------------------------------
# Command ::Reports::Head::create
#
# Values MSAccess uses for properties
# ForceNewPg - None, Before Section, After Section, Before & After
# NewRowCol - None, Before Section, After Section, Before & After
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc ::Reports::Head::create {path args} {

    variable $path
    upvar 0 $path data

    set Name [intlmsg {ReportHeader}]
    set ForceNewPg [intlmsg {None}]
    set NewRowCol [intlmsg {None}]
    set KeepTogether 1
    set Visible 1
    set Grow 0
    set Shrink 0
    set Height "0.25\""
    set BackColor \xFFFFFF; #White
    set SpecEffect [intlmsg {Flat}]
    set Tag {}
    set OnFormat {}
    set OnPrint {}
    set OnRetreat {}

}; # end proc ::Reports::Head::create {path args} {


# ------------------------------------------------------------------------------
# Page Header
# ------------------------------------------------------------------------------
namespace eval ::Reports::Page::Head {
    variable Name
    variable Visible
    variable Height
    variable BackColor
    variable SpecEffect
    variable Tag
    variable OnFormat
    variable OnPrint
}

# ------------------------------------------------------------------------------
# Command ::Reports::Page::Head::create
#
# Values MSAccess uses for properties
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc ::Reports::Page::Head::create {path args} {

    variable $path
    upvar 0 $path data

    set Name [intlmsg {PageHeaderSection}]
    set Visible 1
    set Height "0.25\""
    set BackColor \xFFFFFF; #White
    set SpecEffect [intlmsg {Flat}]
    set Tag {}
    set OnFormat {}
    set OnPrint {}

}; # end proc ::Reports::Page::Head::create


# ------------------------------------------------------------------------------
# Group Header
# ------------------------------------------------------------------------------
namespace eval ::Reports::Group::Head {
    variable Name
    variable ForceNewPg
    variable NewRowCol
    variable KeepTogether
    variable Visible
    variable Grow
    variable Shrink
    variable RepeatSection
    variable Height
    variable BackColor
    variable SpecEffect
    variable Tag
    variable OnFormat
    variable OnPrint
    variable OnRetreat
}

# ------------------------------------------------------------------------------
# Command ::Reports::Group::Head::create
#
# Values MSAccess uses for properties
# ForceNewPg - None, Before Section, After Section, Before & After
# NewRowCol - None, Before Section, After Section, Before & After
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc ::Reports::Group::Head::create {path args} {

    variable $path
    upvar 0 $path data

    set Name [intlmsg {GroupHeader1} {};  # Need to add code to increment GroupHeader1, GroupHeader2, ect...
    set ForceNewPg [intlmsg {None}]
    set NewRowCol [intlmsg {None}]
    set KeepTogether 1
    set Visible 1
    set Grow 0
    set Shrink 0
    set RepeatSection 0
    set Height "0.25\""
    set BackColor \xFFFFFF; #White
    set SpecEffect [intlmsg {Flat}]
    set Tag {}
    set OnFormat {}
    set OnPrint {}
    set OnRetreat {}

}; # end proc ::Reports::Group::Head::create


# ------------------------------------------------------------------------------
# Report Detail
# ------------------------------------------------------------------------------
namespace eval ::Reports::Detail {
    variable Name
    variable ForceNewPg
    variable NewRowCol
    variable KeepTogether
    variable Visible
    variable Grow
    variable Shrink
    variable Height
    variable BackColor
    variable SpecEffect
    variable Tag
    variable OnFormat
    variable OnPrint
    variable OnRetreat
}

# ------------------------------------------------------------------------------
# Command ::Reports::Detail::create
#
# Values MSAccess uses for properties
# ForceNewPg - None, Before Section, After Section, Before & After
# NewRowCol - None, Before Section, After Section, Before & After
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc ::Reports::Detail::create {path args} {

    variable $path
    upvar 0 $path data

    set Name [intlmsg {Detail}]
    set ForceNewPg [intlmsg {None}]
    set NewRowCol [intlmsg {None}]
    set KeepTogether 1
    set Visible 1
    set Grow 0
    set Shrink 0
    set Height "2\""
    set BackColor \xFFFFFF; #White
    set SpecEffect [intlmsg {Flat}]
    set Tag {}
    set OnFormat {}
    set OnPrint {}
    set OnRetreat {}

}; # end proc ::Reports::Detail::create


# ------------------------------------------------------------------------------
# Group Footer
# ------------------------------------------------------------------------------
namespace eval ::Reports::Group::Foot {
    variable Name
    variable ForceNewPg
    variable NewRowCol
    variable KeepTogether
    variable Visible
    variable Grow
    variable Shrink
    variable Height
    variable BackColor
    variable SpecEffect
    variable Tag
    variable OnFormat
    variable OnPrint
    variable OnRetreat
}

# ------------------------------------------------------------------------------
# Command ::Reports::Group::Foot::create
#
# Values MSAccess uses for properties
# ForceNewPg - None, Before Section, After Section, Before & After
# NewRowCol - None, Before Section, After Section, Before & After
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc ::Reports::Group::Foot::create {path args} {

    variable $path
    upvar 0 $path data

    set Name [intlmsg {GroupFooter1}; # Need to add code to increment GroupFooter1, GroupFooter2, ect...
    set ForceNewPg [intlmsg {None}]
    set NewRowCol [intlmsg {None}]
    set KeepTogether 1
    set Visible 1
    set Grow 0
    set Shrink 0
    set Height "0.25\""
    set BackColor \xFFFFFF; #White
    set SpecEffect [intlmsg {Flat}]
    set Tag {}
    set OnFormat {}
    set OnPrint {}
    set OnRetreat {}

}; # end proc ::Reports::Group::Foot::create {path args} {


# ------------------------------------------------------------------------------
# Page Footer
# ------------------------------------------------------------------------------
namespace eval ::Reports::Page::Foot {
    variable Name
    variable Visible
    variable Hieght
    variable BackColor
    variable SpecEffect
    variable Tag
    variable OnFormat
    variable OnPrint
}

# ------------------------------------------------------------------------------
# Command ::Reports::Page::Foot::create
#
# Values MSAccess uses for properties
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc ::Reports::Page::Foot::create {path args} {

    variable $path
    upvar 0 $path data

    set Name [intlmsg {PageFooterSection}]
    set Visible 1
    set Hieght "0.25\""
    set BackColor \xFFFFFF; #White
    set SpecEffect [intlmsg {Flat}]
    set Tag {}
    set OnFormat {}
    set OnPrint {}

}; # end proc ::Reports::Page::Foot::create


# ------------------------------------------------------------------------------
# Report Footer
# ------------------------------------------------------------------------------
namespace eval ::Reports::Foot {
    variable Name
    variable ForceNewPg
    variable NewRowCol
    variable KeepTogether
    variable Visible
    variable Grow
    variable Shrink
    variable Height
    variable BackColor
    variable SpecEffect
    variable Tag
    variable OnFormat
    variable OnPrint
    variable OnRetreat
}

# ------------------------------------------------------------------------------
# Command ::Reports::Foot::create
#
# Values MSAccess uses for properties
# ForceNewPg - None, Before Section, After Section, Before & After
# NewRowCol - None, Before Section, After Section, Before & After
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc ::Reports::Foot::create {path args} {

    variable $path
    upvar 0 $path data

    set Name [intlmsg {ReportFooter}]
    set ForceNewPg [intlmsg {None}]
    set NewRowCol [intlmsg {None}]
    set KeepTogether 1
    set Visible 1
    set Grow 0
    set Shrink 0
    set Height "0.25\""
    set BackColor \xFFFFFF; #White
    set SpecEffect [intlmsg {Flat}]
    set Tag {}
    set OnFormat {}
    set OnPrint {}
    set OnRetreat {}

}; # end proc ::Reports::Foot::create


# ------------------------------------------------------------------------------
# Sub Report
# ------------------------------------------------------------------------------
namespace eval ::Reports::SubReport {
    variable Name
    variable SourceObject
    variable LinkChild
    variable LinkMaster
    variable Visible
    variable Grow
    variable Shrink
    variable Left
    variable Top
    variable Width
    variable Height
    variable SpecEffect
    variable BorderStyle
    variable BorderWidth
    variable BorderColor
    variable Tag

}

# ------------------------------------------------------------------------------
# Command ::Reports::SubReport::create
#
# Values MSAccess uses for properties
# SpecEffect - Flat, Raised, Sunken
# BorderStyle - Transparent, Solid, Dashes, Short Dashes, Dots, Sparse Dots,
#               Dash Dot, Dash Dot Dot
# BorderWidth - Hairline, 1 pt, 2 pt, 3 pt, 4 pt, 5 pt, 6 pt
# ------------------------------------------------------------------------------
proc ::Reports::SubReport::create {path args} {

    variable $path
    upvar 0 $path data

    set Name {};         # Name of the report, table or query
    set SourceObject {}; # Name of the report, table or query with "Report." prepended
    set LinkChild {};    # Name of field
    set LinkMaster {};   # Name of field
    set Visible 1
    set Grow 1
    set Shrink 0
    set Left {};         # Function of where you actually place widget
    set Top {};          # Function of where you actually place widget
    set Width {};        # Function of how you size widget
    set Height {};       # Function of how you size widget
    set SpecEffect [intlmsg {Flat}]
    set BorderStyle [intlmsg {Transparent}]
    set BorderWidth [intlmsg {Hairline}]
    set BorderColor 0;   #Black
    set Tag {}

}; # end proc ::Reports::SubReport::create



#==========================================================
# END REPORTS NAMESPACE
# BEGIN VISUAL TCL CODE
#==========================================================



# handmade but call it vTcl for continuity, someday use visualtcl again
proc vTclWindow.pgaw:ReportBuilder:draft {base} {

    global PgAcVar Win

    if {$base == ""} {
        set base .pgaw:ReportBuilder:draft
    }

    if {[winfo exists $base]} {
        wm deiconify $base; return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 508x345+605+120
    wm maxsize $base 2560 2048
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Report draft"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Key-F1> "::Help::load reports"

    set ::Reports::Win(draft) $base

    canvas $base.c \
        -background #fffeff -borderwidth 2 -height 207 -highlightthickness 0 \
        -relief ridge -takefocus 1 -width 295 
    place $base.c \
        -x 0 -y 0 -width 508 -height 345 -anchor nw -bordermode ignore 
    bind $base.c <Button-1> {
        Reports::design:dragStart %W %x %y
    }
    bind $base.c <ButtonRelease-1> {
        Reports::design:dragStop %x %y
    }
    bind $base.c <Key-Delete> {
        Reports::design:deleteObject
    }
    bind $base.c <Motion> {
        Reports::design:dragMove %W %x %y
    }
    bind $base <Destroy> {
        if {[string match %W [winfo toplevel %W]]} {
            Reports::design:close
        }
    }
}


proc vTclWindow.pgaw:ReportBuilder:menu {base} {

    global PgAcVar Win

    if {$base == ""} {
        set base .pgaw:ReportBuilder:menu
    }

    if {[winfo exists $base]} {
        wm deiconify $base; return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 555x475+43+120
    wm maxsize $base 2560 2048
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm deiconify $base
    wm title $base [intlmsg "Report menu"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Key-F1> "::Help::load reports"

    # if its a list box being destroyed let it go
    # we only want to close when the whole window closes
    bind $base <Destroy> {
        if {[string match %W [winfo toplevel %W]]} {
            Reports::design:close
        }
    }

    set ::Reports::Win(menu) $base

    # setup big frames
    frame $base.fleft
    frame $base.fleft.ftop
    frame $base.fleft.fmiddle
    frame $base.fleft.fbottom
    frame $base.fright
    frame $base.fright.ftop
    frame $base.fright.fmiddle
    frame $base.fright.fbottom
    pack $base.fleft \
        -in $base \
        -side left \
        -expand 1 \
        -fill both
    pack $base.fleft.ftop \
        -in $base.fleft \
        -side top \
        -expand 1 \
        -fill both
    pack $base.fleft.fmiddle \
        -in $base.fleft \
        -side top \
        -expand 1 \
        -fill both
    pack $base.fleft.fbottom \
        -in $base.fleft \
        -side top \
        -expand 1 \
        -fill both
    pack $base.fright \
        -in $base \
        -side right \
        -expand 1 \
        -fill both
    pack $base.fright.ftop \
        -in $base.fright \
        -side top \
        -expand 1 \
        -fill both
    pack $base.fright.fmiddle \
        -in $base.fright \
        -side top \
        -expand 1 \
        -fill both
    pack $base.fright.fbottom \
        -in $base.fright \
        -side top \
        -expand 1 \
        -fill both

    # report and page size frame
    # report size
    set base .pgaw:ReportBuilder:menu
    set base $base.fleft.fmiddle
    set ::Reports::Win(frp) $base.frp
    frame $base.frp \
        -borderwidth 0 -height 195 -relief groove -width 195
    label $base.frp.lrsize \
        -borderwidth 1 -relief raised \
        -text [intlmsg {Report size}]
    SpinBox $base.frp.erw \
        -background #fefefe -highlightthickness 0 -relief groove \
        -textvariable PgAcVar(report,rw) \
        -range {0 2560 1} \
        -modifycmd {Reports::design:changeDraftCoords} \
        -text 345 \
        -width 0
    label $base.frp.lrwbyh \
        -borderwidth 0 \
        -text x
    SpinBox $base.frp.erh \
        -background #fefefe -highlightthickness 0 -relief groove \
        -textvariable PgAcVar(report,rh) \
        -range {0 2048 1} \
        -modifycmd {Reports::design:changeDraftCoords} \
        -text 508 \
        -width 0
    # page size
    label $base.frp.lpsize \
        -borderwidth 1 -relief raised \
        -text [intlmsg {Page size}]
    SpinBox $base.frp.epw \
        -background #fefefe -highlightthickness 0 -relief groove \
        -textvariable PgAcVar(report,pw) \
        -range {0 2560 1} \
        -text 345 \
        -width 0
    label $base.frp.lpwbyh \
        -borderwidth 0 \
        -text x
    SpinBox $base.frp.eph \
        -background #fefefe -highlightthickness 0 -relief groove \
        -textvariable PgAcVar(report,ph) \
        -range {0 2048 1} \
        -text 508 \
        -width 0

    label $base.frp.lselreg \
        -borderwidth 1 -relief raised \
        -text [intlmsg {Report region}]
    label $base.frp.lmsg \
        -relief groove -text [intlmsg {Report header}] \
        -textvariable PgAcVar(report,msg) 
    label $base.frp.lseltype \
        -borderwidth 1 -relief raised \
        -text [intlmsg {Text type}]
    label $base.frp.linfo \
        -relief groove -text [intlmsg {Database field}] \
        -textvariable PgAcVar(report,info) 

    label $base.frp.lfont \
        -borderwidth 1 -relief raised \
        -text [intlmsg {Font}]
    Button $base.frp.bfont \
        -helptext [intlmsg {Choose Font}] \
        -borderwidth 1 \
        -command Reports::design:setFont \
        -relief groove -text "Courier 14" \
        -width 5
    label $base.frp.llal \
        -borderwidth 0 -text Align 
    Button $base.frp.balign \
        -helptext [intlmsg {Choose Alignment}] \
        -borderwidth 0 -command Reports::design:toggleAlignMode \
        -relief groove -text right 

    pack $base.frp \
        -in $base \
        -side right \
        -expand 1 \
        -fill both
    grid $base.frp.lrsize \
        -in $base.frp -column 0 -row 0 -columnspan 3 -rowspan 1 -sticky w
    grid $base.frp.lpsize \
        -in $base.frp -column 3 -row 0 -columnspan 3 -rowspan 1 -sticky w
    grid $base.frp.erw \
        -in $base.frp -column 0 -row 1 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.frp.lrwbyh \
        -in $base.frp -column 1 -row 1 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.frp.erh \
        -in $base.frp -column 2 -row 1 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.frp.epw \
        -in $base.frp -column 3 -row 1 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.frp.lpwbyh \
        -in $base.frp -column 4 -row 1 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.frp.eph \
        -in $base.frp -column 5 -row 1 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.frp.lselreg \
        -in $base.frp -column 0 -row 2 -columnspan 3 -rowspan 1 -sticky nsew
    grid $base.frp.lmsg \
        -in $base.frp -column 0 -row 3 -columnspan 6 -rowspan 1 -sticky nsew
    grid $base.frp.lseltype \
        -in $base.frp -column 0 -row 4 -columnspan 3 -rowspan 1 -sticky nsew
    grid $base.frp.linfo \
        -in $base.frp -column 0 -row 5 -columnspan 6 -rowspan 1 -sticky nsew
    grid $base.frp.lfont \
        -in $base.frp -column 0 -row 6 -columnspan 3 -rowspan 1 -sticky nsew
    grid $base.frp.bfont \
        -in $base.frp -column 0 -row 7 -columnspan 6 -rowspan 1 -sticky nsew
    grid $base.frp.llal \
        -in $base.frp -column 0 -row 8 -columnspan 2 -rowspan 1 -sticky e
    grid $base.frp.balign \
        -in $base.frp -column 2 -row 8 -columnspan 4 -rowspan 1 -sticky nsew


    # report fields frame
    set base .pgaw:ReportBuilder:menu
    set base $base.fleft.fmiddle
    set ::Reports::Win(ffld) $base.ffld
    frame $base.ffld \
        -borderwidth 0 -height 195 -relief groove -width 80
    label $base.ffld.lrepflds \
        -borderwidth 1 \
        -relief raised -text [intlmsg {Report fields}]
    scrollbar $base.ffld.sb \
        -borderwidth 1 -command [subst {$base.ffld.lb yview}] \
        -orient vert -width 12 
    listbox $base.ffld.lb \
        -background #fefefe -foreground #000000 -borderwidth 1 \
        -selectbackground #c3c3c3 \
        -highlightthickness 1 -selectborderwidth 0 \
        -yscrollcommand [subst {$base.ffld.sb set}] 
    bind $base.ffld.lb <ButtonRelease-1> {
        Reports::design:addField
    }

    pack $base.ffld \
        -in $base \
        -side left \
        -expand 1 \
        -fill both
    grid $base.ffld.lrepflds \
        -in $base.ffld -column 0 -row 0 -columnspan 2 -rowspan 1 -sticky nsew
    grid $base.ffld.lb \
        -in $base.ffld -column 0 -row 1 -columnspan 1 -rowspan 2
    grid $base.ffld.sb \
        -in $base.ffld -column 1 -row 1 -columnspan 1 -rowspan 2 -sticky nsew


    # control buttons box
    set base .pgaw:ReportBuilder:menu
    set base $base.fright.ftop
    set ::Reports::Win(fbtn) $base.fbtn
    frame $base.fbtn \
        -borderwidth 0 \
        -height 30 \
        -width 350
    ButtonBox $base.fbtn.bbox \
        -orient horizontal \
        -homogeneous 1 \
        -spacing 2
    $base.fbtn.bbox add \
        -relief link \
        -image ::icon::filesave-22 \
        -borderwidth 1 \
        -command {::Reports::design:save 0} \
        -helptext [intlmsg {Save}]
    $base.fbtn.bbox add \
        -relief link \
        -image ::icon::filesaveas-22 \
        -borderwidth 1 \
        -command {::Reports::design:save 1} \
        -helptext [intlmsg {Save As}]
    $base.fbtn.bbox add \
        -relief link \
        -image ::icon::imagegallery-22 \
        -borderwidth 1 \
        -command {::Reports::design:preview} \
        -helptext [intlmsg {Preview}]
    $base.fbtn.bbox add \
        -relief link \
        -image ::icon::editdelete-22 \
        -borderwidth 1 \
        -command {::Reports::design:deleteAllObjects} \
        -helptext [intlmsg {Delete all}]
    $base.fbtn.bbox add \
        -relief link \
        -image ::icon::help-22 \
        -borderwidth 1 \
        -command {::Help::load reports} \
        -helptext [intlmsg {Help}]
    $base.fbtn.bbox add \
        -relief link \
        -image ::icon::exit-22 \
        -borderwidth 1 \
        -command {::Reports::design:close} \
        -helptext [intlmsg {Close}]

    pack $base.fbtn \
        -in $base \
        -side right \
        -expand 1 \
        -fill both
    pack $base.fbtn.bbox \
        -in $base.fbtn \
        -side right \
        -expand 0 \
        -fill x

    # report name and source frame
    set base .pgaw:ReportBuilder:menu
    set base $base.fleft.ftop
    set ::Reports::Win(fns) $base.fns
    frame $base.fns \
        -borderwidth 0 -height 50 -relief groove -width 350
    label $base.fns.lrn \
        -borderwidth 0 -text [intlmsg {Report name}]
    entry $base.fns.ern \
        -background #fefefe -borderwidth 1 -highlightthickness 0 \
        -textvariable PgAcVar(report,reportname) \
        -width 35
    bind $base.fns.ern <Key-F5> {
        loadReport
    }
    label $base.fns.lrs \
        -borderwidth 0 -text [intlmsg {Report source}]
    ComboBox $base.fns.cbrs \
        -background #fefefe -borderwidth 1 -highlightthickness 0 \
        -values [concat [::Database::getPrefObjList Tables] \
            [::Database::getPrefObjList Views]] \
        -editable true \
        -textvariable PgAcVar(report,tablename) \
        -modifycmd {::Reports::design:getSourceFieldsForFieldBox}
    
    pack $base.fns \
        -in $base \
        -side top \
        -expand 1 \
        -fill both
    grid $base.fns.lrn \
        -in $base.fns -column 0 -row 0 -columnspan 1 -rowspan 1 -sticky e
    grid $base.fns.ern \
        -in $base.fns -column 1 -row 0 -columnspan 2 -rowspan 1 -sticky ew
    grid $base.fns.lrs \
        -in $base.fns -column 0 -row 1 -columnspan 1 -rowspan 1 -sticky e
    grid $base.fns.cbrs \
        -in $base.fns -column 1 -row 1 -columnspan 2 -rowspan 1 -sticky ew

    # add label, formula, picture
    set base .pgaw:ReportBuilder:menu
    set base $base.fleft.fbottom
    set ::Reports::Win(fadd) $base.fadd
    frame $base.fadd \
        -borderwidth 0 -height 160 -relief groove -width 350 
    entry $base.fadd.elab \
        -background #fefefe -borderwidth 1 -highlightthickness 0 \
        -textvariable PgAcVar(report,labeltext) \
        -width 30
    bind $base.fadd.elab <Key-Return> {
        Reports::design:updateObject
    }
    button $base.fadd.badl \
        -borderwidth 1 -command Reports::design:addLabel \
        -text [intlmsg {Add label}]
    button $base.fadd.bupl \
        -borderwidth 1 -command Reports::design:updateObject \
        -text [intlmsg {Update label}]
    button $base.fadd.beditlabel \
        -borderwidth 1 -command "
            Window show .pgaw:ReportBuilder:commands
            set PgAcVar(report,commandType) labeltext
            .pgaw:ReportBuilder:commands.f.txt delete 1.0 end
            .pgaw:ReportBuilder:commands.f.txt insert end \$PgAcVar(report,labeltext)" \
        -text [intlmsg {Edit}]
    entry $base.fadd.ef \
        -background #fefefe -borderwidth 1 -highlightthickness 0 \
        -textvariable PgAcVar(report,formula) 
    bind $base.fadd.ef <Key-Return> {
        Reports::design:updateObject
    }
    button $base.fadd.baf \
        -borderwidth 1 -command Reports::design:addFormula \
        -text [intlmsg {Add formula}]
    button $base.fadd.buf \
        -borderwidth 1 -command Reports::design:updateObject \
        -text [intlmsg {Update formula}]
    button $base.fadd.beditformula \
        -borderwidth 1 -command "
            Window show .pgaw:ReportBuilder:commands
            set PgAcVar(report,commandType) formula
            .pgaw:ReportBuilder:commands.f.txt delete 1.0 end
            .pgaw:ReportBuilder:commands.f.txt insert end \$PgAcVar(report,formula)
            Syntax::highlight .pgaw:ReportBuilder:commands.f.txt tcl" \
        -text [intlmsg {Edit}]
    entry $base.fadd.ep \
        -background #fefefe -borderwidth 1 -highlightthickness 0 \
        -textvariable PgAcVar(report,picture) 
    button $base.fadd.bap \
        -borderwidth 1 -command Reports::design:addPicture \
        -text [intlmsg {Add picture}]
    button $base.fadd.bbrowsepic \
        -borderwidth 1 -command Reports::design:browsePicture \
        -text [intlmsg {Browse}]
    
    pack $base.fadd \
        -in $base \
        -side top \
        -expand 1 \
        -fill both
    grid $base.fadd.elab \
        -in $base.fadd -column 0 -row 0 -columnspan 2 -rowspan 1 -sticky nsew
    grid $base.fadd.beditlabel \
        -in $base.fadd -column 2 -row 0 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.fadd.badl \
        -in $base.fadd -column 0 -row 1 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.fadd.bupl \
        -in $base.fadd -column 1 -row 1 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.fadd.ef \
        -in $base.fadd -column 0 -row 2 -columnspan 2 -rowspan 1 -sticky nsew
    grid $base.fadd.beditformula \
        -in $base.fadd -column 2 -row 2 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.fadd.baf \
        -in $base.fadd -column 0 -row 3 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.fadd.buf \
        -in $base.fadd -column 1 -row 3 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.fadd.ep \
        -in $base.fadd -column 0 -row 4 -columnspan 2 -rowspan 1 -sticky nsew
    grid $base.fadd.bbrowsepic \
        -in $base.fadd -column 2 -row 4 -columnspan 1 -rowspan 1 -sticky nsew
    grid $base.fadd.bap \
        -in $base.fadd -column 0 -row 5 -columnspan 1 -rowspan 1 -sticky nsew

    # regions and fields
    set base .pgaw:ReportBuilder:menu
    set base $base.fright.fbottom
    set ::Reports::Win(frgf) $base.frgf
    frame $base.frgf \
        -borderwidth 2 -height 450 -relief groove -width 190 
    label $base.frgf.lrg \
        -relief raised -borderwidth 1 -text [intlmsg {Regions & Fields}]
    pack $base.frgf \
        -in $base \
        -side right \
        -expand 1 \
        -fill both
    grid $base.frgf.lrg \
        -in $base.frgf -column 0 -row 0 -columnspan 6 -rowspan 1 -sticky nsew
    set row 1
    foreach reg {rpthdr pghdr detail pgfoo rptfoo} \
        regtit {"Report Header" "Page Header" "Detail" "Page Footer" "Report Footer"} {
        label $base.frgf.lrg$reg \
            -borderwidth 0 -text [intlmsg $regtit]
        label $base.frgf.lyrg$reg \
            -borderwidth 0 -text y
        SpinBox $base.frgf.spinrg$reg \
            -background #fefefe -borderwidth 1 -highlightthickness 0 \
            -textvariable PgAcVar(report,y_$reg) \
            -range {0 1000 1} \
            -modifycmd ::Reports::design:drawReportAreas \
            -width 0
        scrollbar $base.frgf.sbrg$reg \
            -borderwidth 1 \
            -command [subst {$base.frgf.lbrg$reg yview}] \
            -orient vert -width 12
        listbox $base.frgf.lbrg$reg \
            -background #fefefe -foreground #000000 -borderwidth 1 \
            -selectbackground #c3c3c3 \
            -highlightthickness 0 -selectborderwidth 0 \
            -yscrollcommand [subst {$base.frgf.sbrg$reg set}] \
            -height 3 \
            -width 12
        bind $base.frgf.lbrg$reg <ButtonRelease-1> {
            Reports::design:selectRegionFieldFromMenu %W %x %y
        }
        checkbutton $base.frgf.cbordered$reg \
            -text [intlmsg {Ordered}] \
            -command [subst {::Reports::design:toggleGroupingAndOrdering \
                \$cbordered$reg $reg "ordered"}]
        checkbutton $base.frgf.cbgrouped$reg \
            -text [intlmsg {Grouped}] \
            -command [subst {::Reports::design:toggleGroupingAndOrdering \
                \$cbgrouped$reg $reg "grouped"}]
        label $base.frgf.blankrg$reg -text ""
        grid $base.frgf.blankrg$reg \
            -in $base.frgf -column 0 -row $row -columnspan 4 -rowspan 1 \
            -sticky s
        incr row
        grid $base.frgf.lrg$reg \
            -in $base.frgf -column 0 -row $row -columnspan 2 -rowspan 1 \
            -sticky s
        grid $base.frgf.lyrg$reg \
            -in $base.frgf -column 2 -row $row -columnspan 1 -rowspan 1 \
            -sticky se
        grid $base.frgf.spinrg$reg \
            -in $base.frgf -column 3 -row $row -columnspan 1 -rowspan 1 \
            -sticky sw
        incr row
        grid $base.frgf.cbordered$reg \
            -in $base.frgf -column 0 -row $row -columnspan 1 -rowspan 1
        grid $base.frgf.cbgrouped$reg \
            -in $base.frgf -column 0 -row [expr {$row+1}] \
            -columnspan 1 -rowspan 1
        grid $base.frgf.lbrg$reg \
            -in $base.frgf -column 1 -row $row -columnspan 3 -rowspan 2
        grid $base.frgf.sbrg$reg \
            -in $base.frgf -column 4 -row $row -columnspan 1 -rowspan 2 \
            -sticky nsew
        incr row 2
    }

}


proc vTclWindow.pgaw:ReportBuilder:commands {base} {

    global PgAcVar Win

    if {$base==""} {
        set base .pgaw:ReportBuilder:commands
    }

    if {[winfo exists $base]} {
        wm deiconify $base; return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 640x480+120+100
    wm maxsize $base 785 570
    wm minsize $base 1 19
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm title $base [intlmsg "text"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Key-F1> "::Help::load reports"

    frame $base.f \
        -borderwidth 2 -height 75 -relief groove -width 125 
    scrollbar $base.f.sb \
        -borderwidth 1 -command {.pgaw:ReportBuilder:commands.f.txt yview} \
        -orient vert -width 12 
    text $base.f.txt \
        -font "$PgAcVar(pref,font_fix)" -height 1 \
        -tabs {20 40 60 80 100 120 140 160 180 200} \
        -width 200 -yscrollcommand {.pgaw:ReportBuilder:commands.f.sb set} \
        -background #ffffff
    frame $base.fb \
        -height 75 -width 125 
    button $base.fb.b1 \
        -borderwidth 1 \
        -command {
            set bad_tcl "yes"
            if {![info complete [.pgaw:ReportBuilder:commands.f.txt \
                get 1.0 "end - 1 chars"]]} {
                set bad_tcl [tk_messageBox -title [intlmsg Warning] \
                    -parent .pgaw:ReportBuilder:commands -type yesno \
                    -message [intlmsg "There appears to be invalid Tcl code.  Are you sure you want to save it?"]]
            } 
            if {$bad_tcl=="yes"} {
                set PgAcVar(report,$PgAcVar(report,commandType)) [.pgaw:ReportBuilder:commands.f.txt get 1.0 "end - 1 chars"]
                Window hide .pgaw:ReportBuilder:commands
                Reports::design:updateObject    
            }
        } -text [intlmsg Save] -width 5 
    button $base.fb.b2 \
        -borderwidth 1 -command {Window hide .pgaw:ReportBuilder:commands} \
        -text [intlmsg Cancel]
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
    pack $base.f \
        -in .pgaw:ReportBuilder:commands -anchor center -expand 1 \
        -fill both -side top 
    pack $base.f.sb \
        -in .pgaw:ReportBuilder:commands.f -anchor e -expand 1 \
        -fill y -side right 
    pack $base.f.txt \
        -in .pgaw:ReportBuilder:commands.f -anchor center -expand 1 \
        -fill both -side top 
    pack $base.fb \
        -in .pgaw:ReportBuilder:commands -anchor center -expand 0 \
        -fill none -side top 
    pack $base.fb.b1 \
        -in .pgaw:ReportBuilder:commands.fb -anchor center -expand 0 \
        -fill none -side left 
    pack $base.fb.b2 \
        -in .pgaw:ReportBuilder:commands.fb -anchor center -expand 0 \
        -fill none -side top 
}


proc vTclWindow.pgaw:ReportPreview {base} {

    global PgAcVar Win

    if {$base == ""} {
        set base .pgaw:ReportPreview
    }

    if {[winfo exists $base]} {
        wm deiconify $base; return
    }

    toplevel $base -class Toplevel
    wm focusmodel $base passive
#    wm geometry $base 495x500+230+50
    wm maxsize $base 2560 2048
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm title $base "Report preview"

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]
    bind $base <Control-Key-p> ::Reports::design:print
    bind $base <Key-F1> "::Help::load reports"

    set ::Reports::Win(preview) $base

    frame $base.fr \
        -borderwidth 1 -height 75 -relief groove -width 125 
    canvas $base.fr.c \
        -background #fcfefe -borderwidth 2 -height 207 -relief ridge \
        -scrollregion {0 0 2560 2048} -width 295 \
        -yscrollcommand [subst {$base.fr.sb set}] 
    scrollbar $base.fr.sb \
        -borderwidth 1 -command [subst {$base.fr.c yview}] \
        -highlightthickness 0 \
        -orient vert -width 12 
    frame $base.fp \
        -borderwidth 1 -height 75 -width 125 

    Button $base.fp.bclose \
        -helptext [intlmsg {Close}] \
        -borderwidth 1 -command {
            if {$PgAcVar(report,justpreview)} {
                Window destroy .pgaw:ReportBuilder:menu
                Window destroy .pgaw:ReportBuilder:draft
            }
            Window destroy .pgaw:ReportPreview
        } -image ::icon::exit-22

    Button $base.fp.bprint \
        -helptext [intlmsg {Print}] \
        -borderwidth 1 -command Reports::design:print \
        -image ::icon::fileprint-22

    label $base.fp.ltexttotal -text "pages "
    label $base.fp.ltotal -textvariable PgAcVar(report,total_page)

    Button $base.fp.bfirst \
        -helptext [intlmsg {First Page}] \
        -image ::icon::2leftarrow-22
    bind $base.fp.bfirst <Button-1> { 
        if {$PgAcVar(report,curr_page)>1} {
            set PgAcVar(report,curr_page) 1
        }
        Reports::design:previewPage
    }

    Button $base.fp.bprev \
        -helptext [intlmsg {Previous Page}] \
        -image ::icon::1leftarrow-22
    bind $base.fp.bprev <Button-1> { 
        if {$PgAcVar(report,curr_page)>1} {
            set PgAcVar(report,curr_page) [expr {$PgAcVar(report,curr_page)-1}]
        }
        Reports::design:previewPage
    }

    Button $base.fp.bnext \
        -helptext [intlmsg {Next Page}] \
        -image ::icon::1rightarrow-22
    bind $base.fp.bnext <Button-1> { 
        if {$PgAcVar(report,curr_page)<$PgAcVar(report,last_page)} {
            set PgAcVar(report,curr_page) [expr {$PgAcVar(report,curr_page)+1}]
        }
        Reports::design:previewPage
    }

    Button $base.fp.blast \
        -helptext [intlmsg {Last Page}] \
        -image ::icon::2rightarrow-22
    bind $base.fp.blast <Button-1> { 
        if {$PgAcVar(report,curr_page)<$PgAcVar(report,last_page)} {
            set PgAcVar(report,curr_page) $PgAcVar(report,last_page)
        }
        Reports::design:previewPage
    }

    Entry $base.fp.estart \
        -helptext [intlmsg {Current Page to Start Printing}] \
        -width 5 \
        -textvariable PgAcVar(report,curr_page)
    bind $base.fp.estart <Key-Return> { 
        Reports::design:previewPage
    }

    label $base.fp.lthru -text -

    Entry $base.fp.estop \
        -helptext [intlmsg {Last Page to Stop Printing}] \
        -width 5 \
        -textvariable PgAcVar(report,last_page)
    bind $base.fp.estop <Key-Return> { 
        Reports::design:previewPage
    }

    pack $base.fr \
        -in .pgaw:ReportPreview -anchor center -expand 1 \
        -fill both -side top 
    pack $base.fr.c \
        -in .pgaw:ReportPreview.fr -anchor center -expand 1 \
        -fill both -side left 
    pack $base.fr.sb \
        -in .pgaw:ReportPreview.fr -anchor center -expand 0 \
        -fill y -side right 
    pack $base.fp \
        -in .pgaw:ReportPreview -anchor center -expand 0 \
        -fill none -side bottom
    pack $base.fp.ltotal \
        -in .pgaw:ReportPreview.fp -expand 0 -fill none -side left
    pack $base.fp.ltexttotal \
        -in .pgaw:ReportPreview.fp -expand 0 -fill none -side left
    pack $base.fp.bfirst \
        -in .pgaw:ReportPreview.fp -expand 0 -fill none -side left
    pack $base.fp.bprev \
        -in .pgaw:ReportPreview.fp -expand 0 -fill none -side left
    pack $base.fp.bnext \
        -in .pgaw:ReportPreview.fp -expand 0 -fill none -side left
    pack $base.fp.blast \
        -in .pgaw:ReportPreview.fp -expand 0 -fill none -side left
    pack $base.fp.estart \
        -in .pgaw:ReportPreview.fp -expand 0 -fill none -side left
    pack $base.fp.lthru \
        -in .pgaw:ReportPreview.fp -expand 0 -fill none -side left
    pack $base.fp.estop \
        -in .pgaw:ReportPreview.fp -expand 0 -fill none -side left
    pack $base.fp.bprint \
        -in .pgaw:ReportPreview.fp -expand 0 -fill none -side left
    pack $base.fp.bclose \
        -in .pgaw:ReportPreview.fp -expand 0 -fill none -side left

    if {[info exists PgAcVar(PGACCESS_NICEREPORTPREVIEW)]} {
        pack propagate $base 0
        update idletasks
        wm geometry $base +0+0
        wm minsize $base [expr {round(.80*[winfo screenwidth $base])}] \
                         [expr {round(.80*[winfo screenheight $base])}]
        wm maxsize $base [expr {round(.80*[winfo screenwidth $base])}] \
                         [expr {round(.80*[winfo screenheight $base])}]
    }

}
