#==========================================================
# Casts --
#
#   handling of PostgreSQL casts
#==========================================================
#
namespace eval Casts {}


#----------------------------------------------------------
# ::Casts::new --
#
#   sets up to create a new Cast
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Casts::new {} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Casts::new


#----------------------------------------------------------
# ::Casts::open --
#
#   passes work to design proc for opening a Cast
#
# Arguments:
#   cast_    name of Cast to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Casts::open {cast_} {

    ::Casts::design $cast_

}; # end proc ::Casts::open


#----------------------------------------------------------
# ::Casts::design --
#
#   opens window in design mode for selected Cast
#
# Arguments:
#   cast_    name of Cast to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Casts::design {cast_} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Casts::new


