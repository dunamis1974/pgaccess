#==========================================================
# OperatorClasses --
#
#   handling of PostgreSQL operator classes
#==========================================================
#
namespace eval OperatorClasses {}


#----------------------------------------------------------
# ::OperatorClasses::new --
#
#   sets up to create a new operator class
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::OperatorClasses::new {} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::OperatorClasses::new


#----------------------------------------------------------
# ::OperatorClasses::open --
#
#   passes work to design proc for opening a operator class
#
# Arguments:
#   operatorclass_    name of operator class to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::OperatorClasses::open {operatorclass_} {

    ::OperatorClasses::design $operatorclass_

}; # end proc ::OperatorClasses::open


#----------------------------------------------------------
# ::OperatorClasses::design --
#
#   opens window in design mode for selected operator class
#
# Arguments:
#   operatorclass_    name of operator class to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::OperatorClasses::design {operatorclass_} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::OperatorClasses::new


