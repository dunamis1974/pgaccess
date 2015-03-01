#==========================================================
# Languages --
#
#   handling of PostgreSQL languages
#==========================================================
#
namespace eval Languages {}


#----------------------------------------------------------
# ::Languages::new --
#
#   sets up to create a new Language
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Languages::new {} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Languages::new


#----------------------------------------------------------
# ::Languages::open --
#
#   passes work to design proc for opening a Language
#
# Arguments:
#   language_    name of Language to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Languages::open {language_} {

    ::Languages::design $language_

}; # end proc ::Languages::open


#----------------------------------------------------------
# ::Languages::design --
#
#   opens window in design mode for selected Language
#
# Arguments:
#   language_    name of Language to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Languages::design {language_} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Languages::new


