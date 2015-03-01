##############################################################################
#
# Namespace for image procedures.
#
# This feature is mainly for the small apps, using this feature it is easier to
# put images in user forms.
#
# Usage: 
# 	Images::open $imgname 	/show image in a new window/
#	Images::new		/create new image/
#	Images::design $imgname	/design image (load new from file)/
#	Images::get $imgname	/get the base64 code of the image/
#
# Variable $PgAcVar(images, *) is used.
#
# Bartus Levente (bartus.l at bitel.hu)
#
##############################################################################
namespace eval Images {

proc load_from_file {} {
global PgAcVar
	set filename [tk_getOpenFile -filetypes {{Pictures {.gif .png}}} \
		-title [intlmsg "Load image"]]

	if {$filename != ""} {
		if {[catch {
			set fid [::open $filename r]
			fconfigure $fid -translation binary

			set PgAcVar(images,imagesource) [::base64::encode [read $fid]]
			close $fid
			$PgAcVar(images,image) configure -image [image create photo -data $PgAcVar(images,imagesource)]
		} msg]} {
			showError $msg
		}
	}
}

proc new {} {
global PgAcVar CurrentDB
	set PgAcVar(images,imagename) [intlmsg "New image"]
	set PgAcVar(images,action) "new"
	Window show .pgaw:DesignImage
	load_from_file
}

proc open {imagename} {
global CurrentDB
	set base .openImage$imagename
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	toplevel $base -class Toplevel
	wm focusmodel $base passive
	wm overrideredirect $base 0
	wm resizable $base 1 1
	wm deiconify $base
	wm title $base $imagename
	label $base.image
    set sql "SELECT imagesource
               FROM pga_images
              WHERE imagename='$imagename'" 
    wpg_select $CurrentDB $sql res {
		$base.image configure -image [image create photo -data $res(imagesource)]
	}
	pack $base.image
}

proc design {imagename} {
global PgAcVar CurrentDB
	set PgAcVar(images,imagename) $imagename
	set PgAcVar(images,old_imagename) $imagename
	set PgAcVar(images,action) "design"
	Window show .pgaw:DesignImage
    set sql "SELECT imagesource
               FROM pga_images
              WHERE imagename='$imagename'"
    wpg_select $CurrentDB $sql res {
		$PgAcVar(images,image) configure -image [image create photo -data $res(imagesource)]
		set PgAcVar(images,imagesource) $res(imagesource)
	}
}

proc get {imagename} {
global CurrentDB
set result ""
    set sql "SELECT imagesource
               FROM pga_images
              WHERE imagename='$imagename'"
    wpg_select $CurrentDB $sql res {
		set result $res(imagesource)
	}
	return $result
}

}; # end of Images namespace


#----------------------------------------------------------
# ::Images::introspect --
#
#   Given a imagename, returns the SQL needed to recreate it
#
# Arguments:
#   imagename_  name of a image to introspect
#   dbh_       an optional database handle
#
# Returns:
#   insql      the INSERT statement to make this image
#----------------------------------------------------------
#
proc ::Images::introspect {imagename_ {dbh_ ""}} {

    set insql [::Images::clone $imagename_ $imagename_ $dbh_]

    return $insql

}; # end proc ::Images::introspect


#----------------------------------------------------------
# ::Images::clone --
#
#   Like introspect, only changes the imagename
#
# Arguments:
#   srcimage_   the original image
#   destimage_  the clone image
#   dbh_        an optional database handle
#
# Returns:
#   insql       the INSERT statement to clone this image
#----------------------------------------------------------
#
proc ::Images::clone {srcimage_ destimage_ {dbh_ ""}} {

    global CurrentDB

    if {[string match "" $dbh_]} {
        set dbh_ $CurrentDB
    }

    set insql ""

    set sql "SELECT imagesource
               FROM pga_images
              WHERE imagename='$srcimage_'"

    wpg_select $dbh_ $sql rec {
        set insql "
            INSERT INTO pga_images (imagename, imagesource)
                 VALUES ('[::Database::quoteSQL $destimage_]','[::Database::quoteSQL $rec(imagesource)]');"
    }

    return $insql

}; # end proc ::Images::clone


proc vTclWindow.pgaw:DesignImage {base} {
global PgAcVar
	if {$base == ""} {
		set base .pgaw:DesignImage
	}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	toplevel $base -class Toplevel
	wm focusmodel $base passive
	wm overrideredirect $base 0
	wm resizable $base 1 1
	wm deiconify $base
	wm title $base "[intlmsg {Images}] - $PgAcVar(images,imagename)"

    # some helpful key bindings
    bind $base <Control-Key-w> [subst {destroy $base}]

	LabelEntry $base.name -label [intlmsg "Name"] -textvariable PgAcVar(images,imagename) -padx 2 -pady 2
	frame $base.fp -borderwidth 2 -relief groove
	label $base.fp.image -text [intlmsg "No image"]
	set PgAcVar(images,image) $base.fp.image
	set PgAcVar(images,imagesource) ""
	frame $base.fb
	button $base.fb.save -text [intlmsg "Save"] -command {
		if {$PgAcVar(images,imagesource) != ""} {
			if {$PgAcVar(images,action) == "new"} {
				set res [wpg_exec $CurrentDB "INSERT INTO pga_images VALUES ('$PgAcVar(images,imagename)','$PgAcVar(images,imagesource)')"]
			}
			if {$PgAcVar(images,action) == "design"} {
				say $PgAcVar(images,imagename)
				set res [wpg_exec $CurrentDB "UPDATE pga_images SET imagesource='$PgAcVar(images,imagesource)', imagename='$PgAcVar(images,imagename)' WHERE imagename='$PgAcVar(images,old_imagename)'"]
			}
			if {[pg_result $res -status] != "PGRES_COMMAND_OK"} {
				showError [pg_result $res -error]
			}
			pg_result $res -clear
			wm title .pgaw:DesignImage "[intlmsg {Images}] - $PgAcVar(images,imagename)"
			Mainlib::cmd_Images
		} else {
			showError [intlmsg "No image selected"]
		}
	}
	button $base.fb.load -text [intlmsg "Load"] -command Images::load_from_file
	pack $base.name $base.fp $base.fb -side top
	pack $base.fp.image 
	grid $base.fb.save -row 0 -column 0
	grid $base.fb.load -row 0 -column 1
}



