#==========================================================
# Aggregates --
#
#   handling of PostgreSQL Aggregates
#==========================================================
#
namespace eval Aggregates {}


#----------------------------------------------------------
# ::Aggregates::new --
#
#   sets up to create a new Aggregate
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Aggregates::new {} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Aggregates::new


#----------------------------------------------------------
# ::Aggregates::open --
#
#   passes work to design proc for opening a Aggregate
#
# Arguments:
#   aggregate_    name of Aggregate to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Aggregates::open {aggregate_} {

    ::Aggregates::design $aggregate_

}; # end proc ::Aggregates::open


#----------------------------------------------------------
# ::Aggregates::design --
#
#   opens window in design mode for selected Aggregate
#
# Arguments:
#   aggregate_    name of Aggregate to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Aggregates::design {aggregate_} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Aggregates::new


