#==========================================================
# ImportExport --
#
#    provides for text transfers between files and PG
#==========================================================
#
namespace eval ImportExport {
    variable exim ; # 1 for import, 0 for export
    variable eximtext
    variable tablename
    variable filename
    variable delimiter
    variable nullas
    variable withoids
}


#----------------------------------------------------------
# sets up the window for the import/export
# defaults appropriate global vars if they arent passed as params
# this is for use by the developers API
#----------------------------------------------------------
#
proc ::ImportExport::setup {{exim_ 1} {tablename_ ""} {filename_ ""} {delimiter_ ""} {nullas_ ""} {withoids_ 0}} {

    global PgAcVar CurrentDB

    variable exim
    variable eximtext
    variable tablename
    variable filename
    variable delimiter
    variable nullas
    variable withoids

    if {$CurrentDB==""} return;

    set exim $exim_
    set tablename $tablename_
    set filename $filename_
    set delimiter $delimiter_
    set nullas $nullas_
    set withoids $withoids_

    # set default as tab output
    if {$nullas==""} {
        set nullas "\x00"
    }
    if {$delimiter==""} {
        set delimiter "\x09"
    }

    if {$exim} {
        set eximtext [intlmsg {Import}]
    } else {
        set eximtext [intlmsg {Export}]
    }

    # well if theres no filename we have to show a window and ask for one
    if {$filename==""} {
        # now we can export queries since they become temp tables first
        if {$PgAcVar(activetab)==[intlmsg Queries] \
          && ![winfo exists .pgaw:ImportExport]} {
            Window show .pgaw:ImportExport
            set tn [Mainlib::get_dwlb_Selection]
            # okay this is odd but export needs to move around namespaces
            if {[string length $tn]!=0} {
                ::Queries::export [::Queries::getSQL $tn]
            }
        } else {
            Window show .pgaw:ImportExport
            if {$PgAcVar(activetab)==[intlmsg Tables]
              || $PgAcVar(activetab)==[intlmsg Views] } {
                set tn [Mainlib::get_dwlb_Selection]
                set tablename $tn
                if {$tn!=""} {set filename "$tn.txt"}
            }
            if {$exim} {
                .pgaw:ImportExport.expbtn configure -text [intlmsg {Import}]
            } else {
                .pgaw:ImportExport.expbtn configure -text [intlmsg {Export}]
            }
        }
    }

}; # end proc ::ImportExport::setup


#----------------------------------------------------------
# performs the actual import or export
#----------------------------------------------------------
#
proc ::ImportExport::execute {} {

    global CurrentDB PgAcVar

    variable exim
    variable tablename
    variable filename
    variable delimiter
    variable nullas
    variable withoids

    if {$tablename==""} {
        showError [intlmsg "You have to supply a table name!"]
    } elseif {$filename==""} {
        showError [intlmsg "You have to supply a external file name!"]
    } else {
        # using delimiters ?
        if {$delimiter==""} {
            set delims ""
        } elseif {$delimiter=="\x09"} {
            set delims " USING DELIMITERS '\x09'"
        } else {
            set delims " USING DELIMITERS '$delimiter'"
        }
        # importing or exporting ?
        if {$exim} {
            set oper "FROM stdin"
            set rw "r"
        } else {
            set oper "TO stdout"
            set rw "w"
        }
        # using oids ?
        if {$withoids} {
            set withoids " WITH OIDS "
        } else {
            set withoids ""
        }
 
        set sqlcmd "COPY [::Database::quoteObject $tablename] $withoids $oper $delims WITH NULL AS '$nullas'"
 
        if {[catch {::open "$filename" $rw} fid]} {
            showError [intlmsg "Can't open the file $filename.  Check file permissions!"]
        } else {
            setCursor CLOCK
 
            set pgres [wpg_exec $CurrentDB $sqlcmd]
            set pgrestr [pg_result $pgres -status]
 
            # importing
            if {$pgrestr=="PGRES_COPY_IN"} {
                set row 1
                set bad_rows 0
                set skip_row 0
                while {![eof $fid]} {
                    set bufcnt [gets $fid buf]
                    if {$bufcnt>0} {
                        catch {puts $CurrentDB $buf}
                    }
                    set pgrestr [pg_result $pgres -status]
                }
                # file is done
                if {$pgrestr=="PGRES_COPY_IN"} {
                    if {[catch {puts $CurrentDB "\\."}]} {
                        # the transfer failed to complete
                        set pgrestr [pg_result $pgres -status]
                        showError [intlmsg "Failed to import!\n$pgrestr"]
                    }
                    # This finishes the copy for pgin.tcl:
                    if {[info exists PgAcVar(PGINTCL)]} {
                        pg_endcopy $pgres
                    }
                }
            # exporting
            } elseif {$pgrestr=="PGRES_COPY_OUT"} {
                while {$pgrestr=="PGRES_COPY_OUT"} {
                    set bufcnt [gets $CurrentDB buf]
                    # This test is for pgin.tcl:
                    if {$bufcnt == 2 && $buf == "\\."} {
                        break
                    }
                    if {$bufcnt>0} {
                        catch {puts $fid $buf}
                    }
                    set pgrestr [pg_result $pgres -status]
                }
                # This finishes the copy for pgin.tcl:
                if {[info exists PgAcVar(PGINTCL)]} {
                    pg_endcopy $pgres
                }
            # not sure how we get here but
            } else {
                showError [intlmsg "Another import/export is occurring.  Please wait!\n$pgrestr"]
            }
            set pgrestr [pg_result $pgres -status]
            setCursor DEFAULT
            pg_result $pgres -clear
            ::close $fid
            if {$pgrestr=="PGRES_COMMAND_OK"} {
                # only say we are finished if fired from the menu command
                if {[winfo exists .pgaw:ImportExport]} {
                    tk_messageBox -title [intlmsg Information] \
                        -message [intlmsg "Operation completed!"]
                }
            } else {
                showError [intlmsg "Failed to import/export!\n$pgrestr"]
            }
        }
    }

}; # end proc ::ImportExport::execute



### END ImportExport NAMESPACE ###
### BEGIN ImportExport::wizard NAMESPACE ###



namespace eval ImportExport::wizard {
    variable curr_step
    variable first_step 1
    variable last_step 4
    variable start_file_line 0
    variable stop_file_line 0
    variable colhdr
    variable decoration
    variable row_head
    variable row_foot
    variable page_head
    variable page_foot
    variable presets "TAB"
    variable filecolhdrs
    variable tablecols
    variable progbar 0
    variable transblock
    variable truncate
    variable overwrite
    variable Win
    variable Cols
}


#----------------------------------------------------------
# this proc is used to create the tkwizard widget
#----------------------------------------------------------
#
proc ::ImportExport::wizard::start_tkwizard {} {

    variable ::ImportExport::exim
    variable ::ImportExport::eximtext

    variable Win

    set Win(wiz) .pgaw:ImportExportWizard

    if {[winfo exists $Win(wiz)]} {
        destroy $Win(wiz)
    }

    set wiztit ""
    if {$exim} {
        set eximtext [intlmsg {Import}]
        set wiztit [intlmsg {Import Wizard}]
    } else {
        set eximtext [intlmsg {Export}]
        set wiztit [intlmsg {Export Wizard}]
    }


    tkwizard::tkwizard $Win(wiz) \
        -title $wiztit \
        -geometry 500x400+100+80

    $Win(wiz) eval {
        variable wizData
        # default values
        catch {unset wizData}
    }

    $Win(wiz) step {step_welcome} -layout advanced {
        variable wizData
        set c [$this widget clientArea]
        if {$::ImportExport::exim} {
            $this stepconfigure \
                -title [intlmsg {Welcome to the Import Wizard!}] \
                -subtitle [intlmsg {You must select a file name.  If the table you choose does not exist, it will be created for you.}] \
                -pretext {} \
                -posttext {}
        } else {
            $this stepconfigure \
                -title [intlmsg {Welcome to the Export Wizard!}] \
                -subtitle [intlmsg {You must select a table name.  If the file you choose does not exist, it will be created for you.}] \
                -pretext {} \
                -posttext {}
        }
        ::ImportExport::wizard::add_step_welcome $c
    }; # end step_welcome

    $Win(wiz) step {step_file} -layout basic {
        variable wizData
        set c [$this widget clientArea]
        $this stepconfigure \
            -title [intlmsg {Choose file characteristics}] \
            -subtitle {} \
            -pretext {} \
            -posttext {}
        ::ImportExport::wizard::set_presets
        ::ImportExport::wizard::add_step_file $c
        ::ImportExport::wizard::step_file_redraw
    }; # end step_file

    $Win(wiz) step {step_table} -layout basic {
        variable wizData
        set c [$this widget clientArea]
        $this stepconfigure \
            -title [intlmsg {Choose table characteristics}] \
            -subtitle {} \
            -pretext {} \
            -posttext {}
        ::ImportExport::wizard::add_step_table $c
    }; # end step_table

    $Win(wiz) step {step_finish} -layout advanced {
        variable wizData
        set c [$this widget clientArea]
        if {$::ImportExport::exim} {
            $this stepconfigure \
                -title [intlmsg {Perform Import}] \
                -subtitle [intlmsg {Finally, you can watch the progress of your operation.  Error messages will be written below.}] \
                -pretext {} \
                -posttext {}
        } else {
            $this stepconfigure \
                -title [intlmsg {Perform Export}] \
                -subtitle [intlmsg {Finally, you can watch the progress of your operation.  Error messages will be written below.}] \
                -pretext {} \
                -posttext {}
        }
        ::ImportExport::wizard::add_step_finish $c
    }; # end step_finish

    bind $Win(wiz) <<WizNextStep>> {::ImportExport::wizard::check_step %W}

    $Win(wiz) show

}; # end proc ::ImportExport::wizard::start_tkwizard


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::ImportExport::wizard::check_step {wiz_} {

    variable ::tkwizard::wizData

    variable ::ImportExport::exim
    variable ::ImportExport::filename
    variable ::ImportExport::tablename

    variable Win

    set currstep [$wiz_ cget -step]

    switch $currstep {

        "step_welcome" {
            if {$exim} {
                if {[string length [string trim $filename]]==0} {
                    showError [intlmsg "You must supply a filename."]
                    return -code break
                } elseif {[string length [string trim $tablename]]==0} {
                    showError [intlmsg "You must supply a tablename."]
                    return -code break
                } elseif {![file readable $filename]} {
                    showError [intlmsg "Can't open the file.  Check file permissions!"]
                    return -code break
                } else {
                    return
                }
            }
        }

     }; # end switch

}; # end proc ::ImportExport::wizard::check_step


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::ImportExport::wizard::add_step_welcome {base_} {

    variable ::ImportExport::exim

    variable Win

    set base $base_.fwel
    set Win(step_welcome) $base_

    frame $base
    pack $base \
        -in $base_ \
        -fill both \
        -expand 1

    set row 0

    Label $base.ltbl \
        -anchor e \
        -text [intlmsg {Table}]
    ComboBox $base.cbtbl \
        -editable true \
        -textvariable ::ImportExport::tablename \
        -values [::Database::getTablesList]
    # if export, we must have a table name
    if {!$::ImportExport::exim} {
        $base.cbtbl configure -editable false
    }
    grid $base.ltbl \
        -in $base \
        -sticky news \
        -row $row \
        -column 0 \
        -columnspan 1 \
        -rowspan 1
    grid $base.cbtbl \
        -in $base \
        -sticky news \
        -row $row \
        -column 1 \
        -columnspan 4 \
        -rowspan 1
    incr row

    Label $base.lfile \
        -anchor e \
        -text [intlmsg {File}]
    Entry $base.efile \
        -textvariable ::ImportExport::filename
    Button $base.bfile \
        -text [intlmsg {Browse}] \
        -command {
            set types {
                {{Text Files}    {.txt}}
                {{CSV Files}     {.csv}}
                {{TAB Files}     {.tab}}
                {{HTML Files}     {.html}}
                {{All Files}          *}
            }
            if {$::ImportExport::exim} {
                set tkget "tk_getOpenFile"
                if {[catch {$tkget \
                    -parent $::ImportExport::wizard::Win(wiz) \
                    -filetypes $types \
                    -title [intlmsg {Import}]} \
                    ::ImportExport::filename] || \
                    [string match {} $::ImportExport::filename]} return
            } else {
                set tkget "tk_getSaveFile"
                if {[catch {$tkget \
                    -parent $::ImportExport::wizard::Win(wiz) \
                    -filetypes $types \
                    -title [intlmsg {Export}]} \
                    ::ImportExport::filename] || \
                    [string match {} $::ImportExport::filename]} return
            }
            set ::ImportExport::wizard::start_file_line 0
            set ::ImportExport::wizard::stop_file_line 0
        }
    grid $base.lfile \
        -in $base \
        -sticky news \
        -row $row \
        -column 0 \
        -columnspan 1 \
        -rowspan 1
    grid $base.efile \
        -in $base \
        -sticky news \
        -row $row \
        -column 1 \
        -columnspan 3 \
        -rowspan 1
    grid $base.bfile \
        -in $base \
        -row $row \
        -column 4 \
        -columnspan 1 \
        -rowspan 1
    incr row

    Label $base.lpre \
        -anchor e \
        -text [intlmsg {Presets}]
    ComboBox $base.cbpre \
        -editable true \
        -textvariable ::ImportExport::wizard::presets \
        -values [list TAB CSV HTML WHITESPACE]
    grid $base.lpre \
        -in $base \
        -sticky news \
        -row $row \
        -column 0 \
        -columnspan 1 \
        -rowspan 1
    grid $base.cbpre \
        -in $base \
        -sticky news \
        -row $row \
        -column 1 \
        -columnspan 4 \
        -rowspan 1
    incr row

}; # end proc ::ImportExport::wizard::add_step_welcome


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::ImportExport::wizard::add_step_file {base_} {

    global PgAcVar

    variable Win

    variable ::ImportExport::exim

    #
    # common file characteristics for both import and export
    #

    set Win(step_file) $base_

    set base $base_.fgrid
    set Win(step_file_grid) $base

    set row 0

    frame $base

    pack $base \
        -in $base_ \
        -expand 1 \
        -fill both

    Label $base.ldelim \
        -anchor e \
        -text [intlmsg {Delimeter}]
    ComboBox $base.cbdelim \
        -editable true \
        -textvariable ::ImportExport::delimiter \
        -values [list "\x09" , \" \' \: " " "</td><td>"] \
        -command {::ImportExport::wizard::step_file_redraw} \
        -modifycmd {::ImportExport::wizard::step_file_redraw}
    grid $base.ldelim \
        -in $base \
        -sticky news \
        -row $row \
        -column 0 \
        -columnspan 1 \
        -rowspan 1
    grid $base.cbdelim \
        -in $base \
        -sticky news \
        -row $row \
        -column 1 \
        -columnspan 1 \
        -rowspan 1
    incr row

    Label $base.ldecor \
        -anchor e \
        -text [intlmsg {Decoration}]
    ComboBox $base.cbdecor \
        -editable true \
        -textvariable ::ImportExport::wizard::decoration \
        -values [list \" \'] \
        -command {::ImportExport::wizard::step_file_redraw} \
        -modifycmd {::ImportExport::wizard::step_file_redraw}
    grid $base.ldecor \
        -in $base \
        -sticky news \
        -row $row \
        -column 0 \
        -columnspan 1 \
        -rowspan 1
    grid $base.cbdecor \
        -in $base \
        -sticky news \
        -row $row \
        -column 1 \
        -columnspan 1 \
        -rowspan 1
    incr row

    Label $base.lnull \
        -anchor e \
        -text [intlmsg {Null As}]
    ComboBox $base.cbnull \
        -editable true \
        -textvariable ::ImportExport::nullas \
        -values [list "\x00" "(empty)" "NULL"] \
        -command {::ImportExport::wizard::step_file_redraw} \
        -modifycmd {::ImportExport::wizard::step_file_redraw}
    grid $base.lnull \
        -in $base \
        -sticky news \
        -row $row \
        -column 0 \
        -columnspan 1 \
        -rowspan 1
    grid $base.cbnull \
        -in $base \
        -sticky news \
        -row $row \
        -column 1 \
        -columnspan 1 \
        -rowspan 1
    incr row

    Label $base.lcolhdr \
        -anchor e \
        -text [intlmsg {Column Headers}]
    checkbutton $base.cbcolhdr \
        -variable ::ImportExport::wizard::colhdr \
        -text [intlmsg {Use first row of file ?}] \
        -command {::ImportExport::wizard::step_file_redraw}
    grid $base.lcolhdr \
        -in $base \
        -sticky news \
        -row $row \
        -column 0 \
        -columnspan 1 \
        -rowspan 1
    grid $base.cbcolhdr \
        -in $base \
        -sticky news \
        -row $row \
        -column 1 \
        -columnspan 1 \
        -rowspan 1
    incr row

    Label $base.lrowhead \
        -anchor e \
        -text [intlmsg {Row Header}]
    ComboBox $base.cbrowhead \
        -editable true \
        -textvariable ::ImportExport::wizard::row_head \
        -values [list "<tr><td>"] \
        -command {::ImportExport::wizard::step_file_redraw} \
        -modifycmd {::ImportExport::wizard::step_file_redraw}
    grid $base.lrowhead \
        -in $base \
        -sticky news \
        -row $row \
        -column 0 \
        -columnspan 1 \
        -rowspan 1
    grid $base.cbrowhead \
        -in $base \
        -sticky news \
        -row $row \
        -column 1 \
        -columnspan 1 \
        -rowspan 1
    incr row

    Label $base.lrowfoot \
        -anchor e \
        -text [intlmsg {Row Footer}]
    ComboBox $base.cbrowfoot \
        -editable true \
        -textvariable ::ImportExport::wizard::row_foot \
        -values [list "</td></tr>"] \
        -command {::ImportExport::wizard::step_file_redraw} \
        -modifycmd {::ImportExport::wizard::step_file_redraw}
    grid $base.lrowfoot \
        -in $base \
        -sticky news \
        -row $row \
        -column 0 \
        -columnspan 1 \
        -rowspan 1
    grid $base.cbrowfoot \
        -in $base \
        -sticky news \
        -row $row \
        -column 1 \
        -columnspan 1 \
        -rowspan 1
    incr row

    # now the import specific stuff
    if {$exim} {

        Label $base.lstart \
            -anchor e \
            -text [intlmsg {Start Line}]
        SpinBox $base.sbstart \
            -textvariable ::ImportExport::wizard::start_file_line \
            -modifycmd {::ImportExport::wizard::step_file_redraw}
        grid $base.lstart \
            -in $base \
            -sticky news \
            -row $row \
            -column 0 \
            -columnspan 1 \
            -rowspan 1
        grid $base.sbstart \
            -in $base \
            -sticky news \
            -row $row \
            -column 1 \
            -columnspan 1 \
            -rowspan 1
        incr row

        Label $base.lstop \
            -anchor e \
            -text [intlmsg {Stop Line}]
        SpinBox $base.sbstop \
            -textvariable ::ImportExport::wizard::stop_file_line
        grid $base.lstop \
            -in $base \
            -sticky news \
            -row $row \
            -column 0 \
            -columnspan 1 \
            -rowspan 1
        grid $base.sbstop \
            -in $base \
            -sticky news \
            -row $row \
            -column 1 \
            -columnspan 1 \
            -rowspan 1
        incr row

        #
        # tablelist for file preview
        #

        set base $base_.ftable
        set Win(step_file_tablelist) $base

        frame $base \
            -borderwidth 5

        scrollbar $base.xscroll \
            -width 12 \
            -command [list $base.tlfile xview] \
            -highlightthickness 0 \
            -orient horizontal \
            -background #DDDDDD \
            -takefocus 0
        scrollbar $base.yscroll \
            -width 12 \
            -command [list $base.tlfile yview] \
            -highlightthickness 0 \
            -background #DDDDDD \
            -takefocus 0

        ::tablelist::tablelist $base.tlfile \
            -yscrollcommand [list $base.yscroll set] \
            -xscrollcommand [list $base.xscroll set] \
            -background #fefefe \
            -stripebg #e0e8f0 \
            -selectbackground #DDDDDD \
            -selectmode extended \
            -labelfont $PgAcVar(pref,font_bold) \
            -stretch all \
            -columns [list 0 [intlmsg {First 10 lines of file}] left] \
            -selectforeground #708090 \
            -labelbackground #DDDDDD \
            -labelforeground navy \
            -height 5 \
            -width 50

        pack $base_.ftable.xscroll \
            -in $base_.ftable \
            -side bottom \
            -fill x
        pack $base_.ftable.yscroll \
            -in $base_.ftable \
            -side right \
            -fill y
        pack $base_.ftable.tlfile \
            -in $base_.ftable \
            -side right \
            -anchor nw \
            -expand 1 \
            -fill both
        pack $base_.ftable \
            -in $base_ \
            -fill both \
            -expand 1

    } else {

        # export specific stuff, mostly for HTML output
        # used to include row header/footer
        # but thats useful for HTML imports
        # so just worry about the page header/footer for
        # export

        Label $base.lpagehead \
            -anchor e \
            -text [intlmsg {Page Header}]
        ComboBox $base.cbpagehead \
            -editable true \
            -textvariable ::ImportExport::wizard::page_head \
            -values [list "<table>"] \
            -command {::ImportExport::wizard::step_file_redraw} \
            -modifycmd {::ImportExport::wizard::step_file_redraw}
        grid $base.lpagehead \
            -in $base \
            -sticky news \
            -row $row \
            -column 0 \
            -columnspan 1 \
            -rowspan 1
        grid $base.cbpagehead \
            -in $base \
            -sticky news \
            -row $row \
            -column 1 \
            -columnspan 1 \
            -rowspan 1
        incr row

        Label $base.lpagefoot \
            -anchor e \
            -text [intlmsg {Page Footer}]
        ComboBox $base.cbpagefoot \
            -editable true \
            -textvariable ::ImportExport::wizard::page_foot \
            -values [list "</table>"] \
            -command {::ImportExport::wizard::step_file_redraw} \
            -modifycmd {::ImportExport::wizard::step_file_redraw}
        grid $base.lpagefoot \
            -in $base \
            -sticky news \
            -row $row \
            -column 0 \
            -columnspan 1 \
            -rowspan 1
        grid $base.cbpagefoot \
            -in $base \
            -sticky news \
            -row $row \
            -column 1 \
            -columnspan 1 \
            -rowspan 1
        incr row

    }

}; # end proc ::ImportExport::wizard::add_step_file


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::ImportExport::wizard::add_step_table {base_} {

    global PgAcVar

    variable ::ImportExport::exim
    variable ::ImportExport::tablename
    variable ::ImportExport::filename

    variable colhdr
    variable filecolhdrs
    variable Cols

    variable createtable
    variable tablecols
    variable fileline [list]
    variable start_file_line

    set base $base_.fgrid

    set Win(step_table) $base_
    set Win(step_table_grid) $base

    set tablename [::Database::quoteObject $tablename]

    # do we have to create the table
    if { ![::Database::isTable $tablename] } {
        if {$exim} {
            set createtable 1
        } else {
            # for TEMP tables, tablecols was already set
            set createtable 0
        }
    } else {
        set createtable 0
        set tablecols [::Database::getColumnsList $tablename]
    }

    # get us the line we are starting on from the file to show in a column
    if {$exim} {
        set fid [::open "$filename" r]
        for {set i 0} {$i<$start_file_line && ![eof $fid]} {incr i} {
            set bufcnt [gets $fid buf]
        }
        ::close $fid
        set fileline [parse_lof $buf]
    }

    frame $base

    set row 0
    set col 0

    Label $base.lfilecol \
        -font $PgAcVar(pref,font_bold) \
        -text [intlmsg {File}]
    grid $base.lfilecol \
        -in $base \
        -sticky news \
        -row $row \
        -column $col \
        -columnspan 1 \
        -rowspan 1
    incr col

    if {$exim} {
        Label $base.ltablecol \
            -font $PgAcVar(pref,font_bold) \
            -text [intlmsg {Table}]
        grid $base.ltablecol \
            -in $base \
            -sticky news \
            -row $row \
            -column $col \
            -columnspan 1 \
            -rowspan 1
        incr col
        if {$createtable} {
            Label $base.ltype \
                -font $PgAcVar(pref,font_bold) \
                -text [intlmsg {Type}]
            grid $base.ltype \
                -in $base \
                -sticky news \
                -row $row \
                -column $col \
                -columnspan 1 \
                -rowspan 1
            incr col
        }
        Label $base.lfileline \
            -font $PgAcVar(pref,font_bold) \
            -text [intlmsg {Start Line}]
        grid $base.lfileline \
            -in $base \
            -sticky news \
            -row $row \
            -column $col \
            -columnspan 1 \
            -rowspan 1
        incr col
    }
    Label $base.lskip \
        -font $PgAcVar(pref,font_bold) \
        -text [intlmsg {Skip}]
    grid $base.lskip \
        -in $base \
        -sticky news \
        -row $row \
        -column $col \
        -columnspan 1 \
        -rowspan 1

    incr row

    # loop thru file column headers and start line in file for import
    # loop thru column names for export
    set looper [list]
    if {$exim} {
        set looper $filecolhdrs
    } else {
        set looper $tablecols
    }

    foreach fch $looper fln $fileline {
        set slop "$row$col[join $fch _]"
        set col 0
        Label $base.l$slop \
            -anchor e \
            -text "$fch"
        grid $base.l$slop \
            -in $base \
            -sticky news \
            -row $row \
            -column $col \
            -columnspan 1 \
            -rowspan 1
        incr col
        if {$exim} {
            ComboBox $base.cb$slop \
                -editable true \
                -text "$fch" \
                -textvariable ::ImportExport::wizard::Cols($fch,name)
            grid $base.cb$slop \
                -in $base \
                -sticky news \
                -row $row \
                -column $col \
                -columnspan 1 \
                -rowspan 1
            incr col
            if {!$createtable} {
                $base.cb$slop configure -values $tablecols
                $base.cb$slop configure -editable false
            } else {
                ComboBox $base.cbtype$slop \
                    -editable true \
                    -text "text" \
                    -values [::Database::getAllColumnTypes] \
                    -textvariable ::ImportExport::wizard::Cols($fch,type)
                grid $base.cbtype$slop \
                    -in $base \
                    -sticky news \
                    -row $row \
                    -column $col \
                    -columnspan 1 \
                    -rowspan 1
                incr col
            }
            Label $base.cbfln$slop \
                -text $fln
            grid $base.cbfln$slop \
                -in $base \
                -sticky news \
                -row $row \
                -column $col \
                -columnspan 1 \
                -rowspan 1
            incr col
        }
        checkbutton $base.cbskip$slop \
            -variable ::ImportExport::wizard::Cols($fch,skip)
        grid $base.cbskip$slop \
            -in $base \
            -sticky news \
            -row $row \
            -column $col \
            -columnspan 1 \
            -rowspan 1
        incr row
    }

    pack $base_.fgrid \
        -in $base_ \
        -side top \
        -expand 1 \
        -fill both

}; # end proc ::ImportExport::wizard::add_step_table


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::ImportExport::wizard::add_step_finish {base_} {

    global CurrentDB

    variable ::ImportExport::exim
    variable ::ImportExport::eximtext
    variable ::ImportExport::tablename
    variable ::ImportExport::filename

    variable Win

    variable start_file_line
    variable stop_file_line
    variable progbar 0
    variable createtable
    variable line_count

    # import line count is the lines the user tells us, export is all table row
    if {$exim} {
        set line_count [expr {$stop_file_line - $start_file_line + 1}]
    } else {
        set sql "
            SELECT COUNT(*)
              FROM $tablename"
        set res [wpg_exec $CurrentDB $sql]
        set line_count [lindex [pg_result $res -getTuple 0] 0]
        if {!$line_count} {set line_count 1}
        pg_result $res -clear
    }

    frame $base_.frverytop
    # couple of import only checkbuttons
    if {$exim} {
        checkbutton $base_.frverytop.cbtrans \
            -variable ::ImportExport::wizard::transblock \
            -text [intlmsg {Perform operation in single TRANSACTION block ?}]
        pack $base_.frverytop.cbtrans \
            -in $base_.frverytop
        # if the table exists, should it be truncated
        if {!$createtable} {
        checkbutton $base_.frverytop.cbtrunc \
            -variable ::ImportExport::wizard::truncate \
            -text [intlmsg {TRUNCATE table before import ?}]
        pack $base_.frverytop.cbtrunc \
            -in $base_.frverytop
        }
    # for exporting, check to see if file should be clobbered, default is no
    } else {
        if {[file exists $filename]} {
            checkbutton $base_.frverytop.cbover \
                -variable ::ImportExport::wizard::overwrite \
                -text [intlmsg {Overwrite destination file ?}]
            pack $base_.frverytop.cbover \
                -in $base_.frverytop
        }
    }

    frame $base_.frtop
    Button $base_.frtop.bexim \
        -text $eximtext \
        -borderwidth 2 \
        -command {::ImportExport::wizard::step_finish_perform}
    ProgressBar $base_.frtop.progbar \
        -variable ::ImportExport::wizard::progbar \
        -maximum $line_count \
        -borderwidth 1 \
        -relief sunken

    frame $base_.frbot
    set Win(errortext) $base_.frbot.terr
    set Win(errorxscroll) $base_.frbot.xscroll
    set Win(erroryscroll) $base_.frbot.yscroll
    scrollbar $base_.frbot.xscroll \
        -borderwidth 1 \
        -command [subst {$Win(errortext) xview}] \
        -orient horiz \
        -width 10
    scrollbar $base_.frbot.yscroll \
        -borderwidth 1 \
        -command [subst {$Win(errortext) yview}] \
        -orient vert \
        -width 10
    text $base_.frbot.terr \
        -width 50 \
        -height 13 \
        -borderwidth 1 \
        -wrap word \
        -xscrollcommand [subst {$Win(errorxscroll) set}] \
        -yscrollcommand [subst {$Win(erroryscroll) set}]

    pack $base_.frverytop \
        -in $base_ \
        -side top \
        -expand 1 \
        -fill both

    pack $base_.frtop.bexim \
        -in $base_.frtop \
        -side left
    pack $base_.frtop.progbar \
        -in $base_.frtop \
        -side left \
        -expand 1 \
        -fill both
    pack $base_.frtop \
        -in $base_ \
        -side top \
        -expand 1 \
        -fill both

    # grid columnconf $base_.frbot 0 \
    #    -weight 1
    # grid rowconf $base_.frbot 0 \
    #    -weight 1
    grid $base_.frbot.xscroll \
        -in $base_.frbot \
        -column 0 \
        -row 1 \
        -columnspan 1 \
        -rowspan 1 \
        -sticky we
    grid $base_.frbot.yscroll \
        -in $base_.frbot \
        -column 1 \
        -row 0 \
        -columnspan 1 \
        -rowspan 1 \
        -sticky sn
    grid $base_.frbot.terr \
        -in $base_.frbot \
        -column 0 \
        -row 0 \
        -columnspan 1 \
        -rowspan 1 \
        -sticky news
    pack $base_.frbot \
        -in $base_ \
        -side top \
        -expand 1 \
        -fill both

}; # end proc ::ImportExport::wizard::add_step_finish


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::ImportExport::wizard::step_finish_errormsg {msg_} {

    variable Win

    $Win(errortext) insert end "$msg_\n"
    $Win(errortext) see end

    # this flushes all pending display events
    # and lets us see the error log window plus the progress bar
    update idletasks

}; # end proc ::ImportExport::wizard::step_finish_errormsg


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::ImportExport::wizard::step_finish_perform {} {

    global CurrentDB
    global PgAcVar

    variable Win
    variable Cols

    variable ::ImportExport::exim
    variable ::ImportExport::filename
    variable ::ImportExport::tablename
    variable ::ImportExport::delimiter
    variable ::ImportExport::nullas

    variable colhdr
    variable decoration
    variable row_head
    variable row_foot
    variable page_head
    variable page_foot
    variable filecolhdrs
    variable tablecols
    variable start_file_line
    variable stop_file_line
    variable progbar 0
    variable transblock
    variable truncate
    variable overwrite
    variable createtable

    variable buf

    set eximfailed 0

    # set the tab
    if {$delimiter=="TAB"} {
        set delimiter "\x09"
    }
    # set the whitespace
    if {$delimiter=="WHITESPACE"} {
        set delimiter " "
    }

    set timestart [clock clicks]
    setCursor CLOCK

    # take care of the importing first
    if {$exim} {

        set msg [intlmsg {Starting import}]
        ::ImportExport::wizard::step_finish_errormsg "$msg: $filename..."

        # do we need to create a table
        if {$createtable} {
            set sql "CREATE TABLE $tablename ("
            foreach fch $filecolhdrs {
                if {!$Cols($fch,skip)} {
                    append sql "\"$Cols($fch,name)\" $Cols($fch,type),"
                }
            }
            set sql [string trimright $sql ,]
            append sql ")"
            set msg [intlmsg {Creating table}]
            ::ImportExport::wizard::step_finish_errormsg "$msg: $tablename..."
            sql_exec noquiet $sql
        # the table exists but should be we truncate it
        } elseif {[info exists truncate] && $truncate} {
            set sql "TRUNCATE TABLE $tablename"
            set msg [intlmsg {Truncating table}]
            ::ImportExport::wizard::step_finish_errormsg "$msg: $tablename..."
            sql_exec noquiet $sql
        }

        # if we are doing this in one transaction block start it now
        if {$transblock} {
            wpg_exec $CurrentDB "BEGIN TRANSACTION"
            pg_result $PgAcVar(pgsql,res) -clear
        }

        # open the file
        set fid [::open "$filename" r]

        # keep reading lines until end of file
        for {set row 1} {![eof $fid] && $row<=$stop_file_line} {incr row} {

            # get one file line and split it up
            set bufcnt [gets $fid buf]

            # make sure we start on the right line
            if {$row>=$start_file_line} {

                set progbar [expr {$row - $start_file_line + 1}]

                # really handy for HTML table imports
                set buf [string trimleft $buf $row_head]
                set buf [string trimright $buf $row_foot]

                set delimbuf [::csv::split $buf $delimiter]

                # special check for whitespace
                if {[string length [string trim $delimiter]]==0} {
                    set blankbuf [list]
                    foreach l $delimbuf {
                        if {[string length [string trim $l]]>0} {
                            lappend blankbuf $l
                        }
                    }
                    set delimbuf $blankbuf
                }

                set decorbuf [list]

                # pretty it up
                foreach l $delimbuf {
                    if {[string match $nullas $l]} {
                        lappend decorbuf $nullas
                    } else {
                        lappend decorbuf [string trim $l $decoration]
                    }
                }

                # create the insert line
                set fvals ""
                set tcols ""

                foreach f $decorbuf t $filecolhdrs {
                    if {[info exists Cols($t,skip)] && !$Cols($t,skip)} {
                        append tcols "\"$Cols($t,name)\","
                        if {[string match $nullas $f]} {
                            append fvals "NULL,"
                        } else {
                            regsub -all {\'} $f {\\'} ff
                            regsub -all {\"} $ff {\\"} fff
                            append fvals "'$fff',"
                        }
                    }
                }

                set tcols [string trimright $tcols ,]
                set fvals [string trimright $fvals ,]
                set sql "INSERT INTO $tablename ($tcols)
                              VALUES ($fvals)"

                # start the insert transaction
                # we are doing a ton of work here and need to keep clean
                if {!$transblock} {
                    wpg_exec $CurrentDB "BEGIN TRANSACTION"
                    pg_result $PgAcVar(pgsql,res) -clear
                }

                wpg_exec $CurrentDB $sql

                if {$PgAcVar(pgsql,status)=="PGRES_COMMAND_OK"} {
                    pg_result $PgAcVar(pgsql,res) -clear
                    if {!$transblock} {
                        wpg_exec $CurrentDB "COMMIT TRANSACTION"
                        pg_result $PgAcVar(pgsql,res) -clear
                    }
                } else {
                    set errmsg [intlmsg "ERROR"]
                    append errmsg ": " [pg_result $PgAcVar(pgsql,res) -error]
                    pg_result $PgAcVar(pgsql,res) -clear
                    ::ImportExport::wizard::step_finish_errormsg "$errmsg"
                    set badmsg [intlmsg "BAD ROW"]
                    ::ImportExport::wizard::step_finish_errormsg "$badmsg #$row"
                    ::ImportExport::wizard::step_finish_errormsg "SQL: $sql"
                    wpg_exec $CurrentDB "ROLLBACK TRANSACTION"
                    pg_result $PgAcVar(pgsql,res) -clear
                    if {$transblock} {
                        set eximfailed 1
                        break
                    }
                }
            }
        }

        # close the file
        ::close $fid

        # this is if we were working within one large transaction block
        if {$transblock && $PgAcVar(pgsql,status)=="PGRES_COMMAND_OK"} {
            wpg_exec $CurrentDB "COMMIT TRANSACTION"
            pg_result $PgAcVar(pgsql,res) -clear
        }

        setCursor NORMAL
        set timestop [clock clicks]
        set timediff [expr {double($timestop-$timestart)/double(1000000)}]

        if {$eximfailed} {
            set msg [intlmsg {Import failed, no rows imported.}]
            ::ImportExport::wizard::step_finish_errormsg "$msg"
        } else {
            set msg [intlmsg {Finished import}]
            set msg2 [intlmsg {rows}]
            set total_rows [expr {$row - $start_file_line}]
            ::ImportExport::wizard::step_finish_errormsg "$msg: $total_rows $msg2 in $timediff sec."
        }

    #
    # okay export should be a lot easier
    #
    } else {

        set msg [intlmsg {Starting export}]
        ::ImportExport::wizard::step_finish_errormsg "$msg: $filename..."

        # figure out what columns were skipped, if any
        set tcols [list]
        set ttcols [list]
        foreach t $tablecols {
            if {[info exists Cols($t,skip)] && !$Cols($t,skip)} {
                lappend tcols $t
                lappend ttcols "t1.\"$t\""
            }
        }

        set sql "SELECT [join $ttcols ,]
                   FROM $tablename t1"

        set openmode ""
        if {[info exists overwrite] && $overwrite} {
            set openmode "w"
        } else {
            set openmode "a"
        }
        set fid [::open "$filename" $openmode]

        set row 0

        set timestart [clock clicks]
        setCursor CLOCK

        # see if we have a page header
        if {$page_head!=""} {
            puts $fid $page_head
        }

        # check whether we are letting column names be first row of file
        if {$colhdr} {
            set line $row_head
            foreach t $tcols {
                append line $decoration $t $decoration $delimiter
            }
            set line [string trimright $line $delimiter]
            append line $row_foot
            puts $fid $line
        }

        wpg_select $CurrentDB $sql rec {
            set progbar [expr {$row+1}]
            set line $row_head
            foreach t $tcols {
                append line $decoration $rec($t) $decoration $delimiter
            }
            set line [string trimright $line $delimiter]
            append line $row_foot
            puts $fid $line
            incr row
        }

        # see if we have a page footer
        if {$page_foot!=""} {
            puts $fid $page_foot
        }

        ::close $fid

        setCursor NORMAL
        set timestop [clock clicks]
        set timediff [expr {double($timestop-$timestart)/double(1000000)}]

        set msg [intlmsg {Finished export}]
        set msg2 [intlmsg {rows}]
        ::ImportExport::wizard::step_finish_errormsg "$msg: $row $msg2 in $timediff sec."

    }; # end if

}; # end proc ::ImportExport::wizard::step_finish_perform


#----------------------------------------------------------
#----------------------------------------------------------
#
proc ::ImportExport::wizard::step_file_redraw {} {

    setCursor CLOCK

    variable Win

    variable ::ImportExport::exim
    variable ::ImportExport::filename

    variable start_file_line
    variable stop_file_line
    variable colhdr
    variable filecolhdrs

    # this proc doesnt apply to exporting
    if {!$exim} {
        return
    }

    # set the tablelist to the first 10 lines of the file
    set base $Win(step_file_tablelist)

    $base.tlfile delete 0 end

    set lbuf {}
    set fid [::open "$filename" r]
    for {set i 1} {$i<=[expr {10+$start_file_line}] && ![eof $fid]} {incr i} {
        set bufcnt [gets $fid buf]
        if {$i>=$start_file_line} {
            lappend lbuf [parse_lof $buf]
        }

    }
    ::close $fid

    set colhdrs [list]
    set filecolhdrs [list]
    set c 0
    foreach col [lindex $lbuf 0] {
        incr c
        if {$colhdr} {
            lappend colhdrs 0 $col left
            lappend filecolhdrs $col
        } else {
            lappend colhdrs 0 column$c left
            lappend filecolhdrs column$c
        }
    }

    $base.tlfile configure -columns $colhdrs
    if {$colhdr} {
        set lbuf [lrange $lbuf 1 end]
    }

    foreach l $lbuf {
        $base.tlfile insert end $l
    }

    if {$start_file_line==0 || $stop_file_line==0} {
        # set the scrollbars' ranges to the line count
        set linecnt 0
        ::fileutil::foreachLine linevar $filename {incr linecnt}
        set sbbase $Win(step_file_grid)
        $sbbase.sbstart configure -range [subst {1 $linecnt 1}]
        $sbbase.sbstop configure -range [subst {1 $linecnt 1}]
        $sbbase.sbstart setvalue first
        $sbbase.sbstop setvalue last
    }

    setCursor NORMAL

}; # end proc ::ImportExport::wizard::step_file_redraw


#----------------------------------------------------------
# ::ImportExport::wizard::parse_lof --
#
#   parses one line of a file w/decorations, delims, etc.
#----------------------------------------------------------
#
proc ::ImportExport::wizard::parse_lof {lof_} {

    variable ::ImportExport::delimiter
    variable ::ImportExport::nullas

    variable decoration
    variable row_head
    variable row_foot

    set delimbuf [::csv::split $lof_ $delimiter]

    # gank the row header and footer
    set delimbuf [string trimleft $delimbuf $row_head]
    set delimbuf [string trimright $delimbuf $row_foot]

    # special check for whitespace
    if {[string length [string trim $delimiter]]==0} {
        set blankbuf [list]
        foreach l $delimbuf {
            if {[string length [string trim $l]]>0} {
                lappend blankbuf $l
            }
        }
        set delimbuf $blankbuf
    }

    set decorbuf {}
    foreach l $delimbuf {
        if {[string match $nullas $l]} {
            lappend decorbuf [intlmsg {NULL}]
        } else {
            lappend decorbuf [string trim $l $decoration]
        }
    }

    return $decorbuf

}; # end proc ::ImportExport::wizard::parse_lof


#----------------------------------------------------------
# ::ImportExport::wizard::set_presets --
#
#   handles changing default file formatting characters
#----------------------------------------------------------
#
proc ::ImportExport::wizard::set_presets {} {

    variable presets
    variable page_head
    variable page_foot
    variable row_head
    variable row_foot
    variable decoration
    variable ::ImportExport::nullas
    variable ::ImportExport::delimiter

    switch $presets {

        CSV {
            set page_head ""
            set page_foot ""
            set row_head ""
            set row_foot ""
            set decoration "\""
            set delimiter ","
            set nullas "\x00"
        }

        HTML {
            set page_head "<table>"
            set page_foot "</table>"
            set row_head "<tr><td>"
            set row_foot "</td></tr>"
            set decoration ""
            set delimiter "</td><td>"
            set nullas ""
        }

        WHITESPACE {
            set page_head ""
            set page_foot ""
            set row_head ""
            set row_foot ""
            set decoration ""
            set delimiter " "
            set nullas "\x00"
        }

        # default is tab
        default {
            set page_head ""
            set page_foot ""
            set row_head ""
            set row_foot ""
            set decoration ""
            set delimiter "TAB"
            set nullas "\x00"
        }

    }

}; # end proc ::ImportExport::wizard::set_presets


### END ImportExport::wizard NAMESPACE ###
### BEGIN Visual Tcl code ###



proc vTclWindow.pgaw:ImportExport {base} {
    if {$base == ""} {
        set base .pgaw:ImportExport
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    toplevel $base -class Toplevel
    wm focusmodel $base passive
    wm geometry $base 335x180+259+304
    wm maxsize $base 1280 1024
    wm minsize $base 1 1
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm title $base [intlmsg "Import-Export table"]

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

    label $base.l1  -borderwidth 0 -text [intlmsg {Table name}]
    entry $base.e1  -background #fefefe -borderwidth 1 \
        -textvariable ::ImportExport::tablename
    label $base.l2  -borderwidth 0 -text [intlmsg {File name}]
    entry $base.e2  -background #fefefe -borderwidth 1 \
        -textvariable ::ImportExport::filename
    button $base.browsebtn  -borderwidth 1 -text [intlmsg Browse] -command {
        set types {
            {{Text Files}    {.txt}}
            {{All Files}    *}
        }
        if {[.pgaw:ImportExport.expbtn cget -text]=="Import"} {
            set tkget "tk_getOpenFile"
        } else {
            set tkget "tk_getSaveFile"
        }
        if {[catch {$tkget -defaultextension .txt -filetypes $types \
            -title [.pgaw:ImportExport.expbtn cget -text]} \
            ::ImportExport::filename] || \
            [string match {} $::ImportExport::filename]} return
    }    
    label $base.l3  -borderwidth 0 -text [intlmsg {Field delimiter}]
    entry $base.e3  -background #fefefe -borderwidth 1 \
        -textvariable ::ImportExport::delimiter
    label $base.lnullas  -borderwidth 0 -text [intlmsg {Nulls As}]
    entry $base.enullas  -background #fefefe -borderwidth 1 \
        -textvariable ::ImportExport::nullas
    button $base.expbtn  -borderwidth 1 -text [intlmsg Export] \
        -command {
            ImportExport::execute
            Window destroy .pgaw:ImportExport
        }
    button $base.cancelbtn  -borderwidth 1 \
        -command {Window destroy .pgaw:ImportExport} -text [intlmsg Cancel]
    checkbutton $base.oicb  -borderwidth 1  \
        -text [intlmsg {with OIDs}] -variable ::ImportExport::withoids

    Button $base.wizbtn \
        -helptext [intlmsg {Wizard}] \
        -image ::icon::wizard-22 \
        -borderwidth 2 \
        -command {
            setCursor CLOCK
            Window destroy .pgaw:ImportExport
            ::ImportExport::wizard::start_tkwizard
            setCursor NORMAL
        }

    place $base.l1  -x 15 -y 15 -anchor nw -bordermode ignore 
    place $base.e1  -x 115 -y 10 -height 22 -anchor nw -bordermode ignore 
    place $base.l2  -x 15 -y 45 -anchor nw -bordermode ignore 
    place $base.e2  -x 115 -y 40 -height 22 -anchor nw -bordermode ignore 
    place $base.browsebtn  -x 265 -y 40 -height 25 -width 60 \
        -anchor nw -bordermode ignore 
    place $base.l3  -x 15 -y 75 -height 18 -anchor nw -bordermode ignore 
    place $base.e3  -x 115 -y 74 -width 33 -height 22 \
        -anchor nw -bordermode ignore 
    place $base.lnullas  -x 15 -y 105 -height 18 -anchor nw -bordermode ignore 
    place $base.enullas  -x 115 -y 104 -width 33 -height 22 \
        -anchor nw -bordermode ignore 
    place $base.expbtn  -x 60 -y 140 -height 25 -width 75 \
        -anchor nw -bordermode ignore 
    place $base.cancelbtn  -x 155 -y 140 -height 25 -width 75 \
        -anchor nw -bordermode ignore 
    place $base.oicb  -x 170 -y 105 -anchor nw -bordermode ignore
    place $base.wizbtn -x 260 -y 90 -height 60 -width 60 -anchor nw

}


