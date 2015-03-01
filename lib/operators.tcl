#==========================================================
# Operators --
#
#   handling of PostgreSQL operators
#==========================================================
#
namespace eval Operators {}


#----------------------------------------------------------
# ::Operators::new --
#
#   sets up to create a new Operator
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Operators::new {} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Operators::new


#----------------------------------------------------------
# ::Operators::open --
#
#   passes work to design proc for opening a Operator
#
# Arguments:
#   operator_    name of Operator to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Operators::open {operator_} {

    ::Operators::design $operator_

}; # end proc ::Operators::open


#----------------------------------------------------------
# ::Operators::design --
#
#   opens window in design mode for selected Operator
#
# Arguments:
#   operator_    name of Operator to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Operators::design {operator_} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Operators::new


