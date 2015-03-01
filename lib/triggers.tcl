#==========================================================
# Triggers --
#
#   handling of PostgreSQL triggers
#==========================================================
#
namespace eval Triggers {}


#----------------------------------------------------------
# ::Triggers::new --
#
#   sets up to create a new Trigger
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Triggers::new {} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Triggers::new


#----------------------------------------------------------
# ::Triggers::open --
#
#   passes work to design proc for opening a Trigger
#
# Arguments:
#   trigger_    name of Trigger to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Triggers::open {trigger_} {

    ::Triggers::design $trigger_

}; # end proc ::Triggers::open


#----------------------------------------------------------
# ::Triggers::design --
#
#   opens window in design mode for selected Trigger
#
# Arguments:
#   trigger_    name of Trigger to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Triggers::design {trigger_} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Triggers::design


