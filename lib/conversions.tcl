#==========================================================
# Conversions --
#
#   handling of PostgreSQL Conversions
#==========================================================
#
namespace eval Conversions {}


#----------------------------------------------------------
# ::Conversions::new --
#
#   sets up to create a new Conversion
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Conversions::new {} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Conversions::new


#----------------------------------------------------------
# ::Conversions::open --
#
#   passes work to design proc for opening a Conversion
#
# Arguments:
#   conversion_    name of Conversion to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Conversions::open {conversion_} {

    ::Conversions::design $conversion_

}; # end proc ::Conversions::open


#----------------------------------------------------------
# ::Conversions::design --
#
#   opens window in design mode for selected Conversion
#
# Arguments:
#   conversion_    name of Conversion to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Conversions::design {conversion_} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Conversions::new


