#==========================================================
# Rules --
#
#   handling of PostgreSQL rules
#==========================================================
#
namespace eval Rules {}


#----------------------------------------------------------
# ::Rules::new --
#
#   sets up to create a new Rule
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Rules::new {} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Rules::new


#----------------------------------------------------------
# ::Rules::open --
#
#   passes work to design proc for opening a Rule
#
# Arguments:
#   rule_    name of Rule to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Rules::open {rule_} {

    ::Rules::design $rule_

}; # end proc ::Rules::open


#----------------------------------------------------------
# ::Rules::design --
#
#   opens window in design mode for selected Rule
#
# Arguments:
#   rule_    name of Rule to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Rules::design {rule_} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Rules::new


