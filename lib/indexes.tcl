#==========================================================
# Indexes --
#
#   handling of PostgreSQL indexes
#==========================================================
#
namespace eval Indexes {}


#----------------------------------------------------------
# ::Indexes::new --
#
#   sets up to create a new index
#
# Arguments:
#   none
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Indexes::new {} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Indexes::new


#----------------------------------------------------------
# ::Indexes::open --
#
#   passes work to design proc for opening a index
#
# Arguments:
#   index_    name of index to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Indexes::open {index_} {

    ::Indexes::design $index_

}; # end proc ::Indexes::open


#----------------------------------------------------------
# ::Indexes::design --
#
#   opens window in design mode for selected index
#
# Arguments:
#   index_    name of index to open in design mode
#
# Returns:
#   none
#----------------------------------------------------------
#
proc ::Indexes::design {index_} {

    showError [intlmsg "Not yet implemented."]

}; # end proc ::Indexes::new


