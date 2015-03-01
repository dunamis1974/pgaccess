# ------------------------------------------------------------------------------
#  2002/12/18 - Karl Swisher
#  Attempt to convert MSAccess report widgets
#
#  This would be a start in the direction the new forms code has gone.  The new
#  forms code makes PGAccess more similar to MSAccess in the design of forms.
#
#  Tried NOT to clutter this up with a lot of unusuable code.  Should be fairly
#  easy to do global replace here if any variable names need changed and/or
#  copy/past the code into the real script where needed.
#
#  These variables are properties of the widgets.  Can be used for the report and
#  also the widget to edit them.  Even if all are not used right now they could
#  be available for future use.  Tried to keep variable names as short as possible
#  but still maintain some type of description of what the property does.  With
#  that being said there are still some of the properties that I'm not sure what
#  they are or how they might be used.
#
#  The default values each property is set to are the ones that MSAccess defaults
#  to when the widget is created.  In the comments above each create are some other
#  values Microsoft uses which may not be obvious.  If a value is "Yes" then the
#  other value is obviously "No" so I did not list out these types.
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# Report
# ------------------------------------------------------------------------------

namespace eval PGAReport {
	variable Name
	variable RecSource
	variable Filter
	variable FilterOn
	variable OrderBy
	variable OrderByOn
	variable Caption
	variable RecLocks
	variable PageHead
	variable PageFoot
	variable DateGroup
	variable KeepTogether
	variable Width
	variable Pic
	variable PicType
	variable PicSizeMode 
	variable PicAlign
	variable PicTiling
	variable PicPages
	variable MenuBar
	variable Toolbar
	variable ShortMenuBar
	variable GridX
	variable GridY
	variable LayoutPrint
	variable FastLaser
	variable HelpFile
	variable HelpContextID
	variable PaletteSrc
	variable Tag
	variable OnOpen
	variable OnClose
	variable OnActivate
	variable OnDeactivate
	variable OnNoData
	variable OnPage
	variable OnError
	variable HasModule
}

# ------------------------------------------------------------------------------
# Command PGAReport::create
#
# Values MSAccess uses for properties
# RecLocks - No Locks, All Records
# PageHead - All Pages, Not with Rpt Hdr, Not with Rpt Ftr, Not with Rpt Hdr/Ftr
# PageFoot - All Pages, Not with Rpt Hdr, Not with Rpt Ftr, Not with Rpt Hdr/Ftr
# DateGroup - Use System Settings, US Default
# KeepTogether - Per Column, Per Page
# Pic - The actual path to the picture
# PicType - Embedded, Link
# PicSizeMode - Clip, Stretch, Zoom
# PicPages - All Pages, First Page, No Pages
# OnOpen - [Event Procedure]- User written TCL script
# OnClose - [Event Procedure]- User written TCL script 
# OnActivate - [Event Procedure]- User written TCL script 
# OnDeactivate - [Event Procedure]- User written TCL script 
# OnNoData - [Event Procedure]- User written TCL script 
# OnPage - [Event Procedure]- User written TCL script 
# OnError - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc PGAReport::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {}  # Need to add code to increment Report 1, Report 2, ect...
	set RecSource {} # Can be a query or table
	set Filter	{}
	set FilterOn {No}
	set OrderBy {}
	set OrderByOn {No}
	set Caption {}
	set RecLocks {No Locks}
	set PageHead {All Pages}
	set PageFoot {All Pages}
	set DateGroup {Use System Settings}
	set KeepTogether {Per Column}
	set Width {5"}
	set Pic {(none)}
	set PicType {Embedded}
	set PicSizeMode {Clip}
	set PicAlign {Center}
	set PicTiling {No}
	set PicPages {All Pages}
	set MenuBar {}
	set Toolbar {}
	set ShortMenuBar {}
	set GridX 24
	set GridY 24
	set LayoutPrint {Yes}
	set FastLaser {Yes}
	set HelpFile {}
	set HelpContextID 0
	set PaletteSrc {(Default)}
	set Tag {}
	set OnOpen {}
	set OnClose {}
	set OnActivate {}
	set OnDeactivate {}
	set OnNoData {}
	set OnPage {}
	set OnError {}
	set HasModule {No}

}

# ------------------------------------------------------------------------------
# Report Header
# ------------------------------------------------------------------------------

namespace eval PGAReportHead {

	variable Name 
	variable ForceNewPg
	variable NewRowCol
	variable KeepTogether
	variable Visible
	variable Grow
	variable Shrink
	variable Heigh
	variable BackColor
	variable SpecEffect
	variable Tag
	variable OnFormat
	variable OnPrint
	variable OnRetreat
}

# ------------------------------------------------------------------------------
# Command PGAReportHead::create
#
# Values MSAccess uses for properties
# ForceNewPg - None, Before Section, After Section, Before & After
# NewRowCol - None, Before Section, After Section, Before & After
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc PGAReportHead::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {ReportHeader}
	set ForceNewPg {None}
	set NewRowCol {None}
	set KeepTogether {Yes}
	set Visible {Yes}
	set Grow {No}
	set Shrink {No}
	set Height {0.25"}
	set BackColor \xFFFFFF #White
	set SpecEffect {Flat}
	set Tag {}
	set OnFormat {}
	set OnPrint {}
	set OnRetreat {}
}

# ------------------------------------------------------------------------------
# Page Header
# ------------------------------------------------------------------------------

namespace eval PGAPageHead {

	variable Name
	variable Visible
	variable Height
	variable BackColor
	variable SpecEffect
	variable Tag
	variable OnFormat
	variable OnPrint
}

# ------------------------------------------------------------------------------
# Command PGAPageHead::create
#
# Values MSAccess uses for properties
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc PGAPageHead::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {PageHeaderSection}
	set Visible {Yes}
	set Height {0.25"}
	set BackColor \xFFFFFF #White
	set SpecEffect {Flat}
	set Tag {}
	set OnFormat {}
	set OnPrint {}

}

# ------------------------------------------------------------------------------
# Group Header
# ------------------------------------------------------------------------------
namespace eval PGAGroupHead {
	variable Name
	variable ForceNewPg
	variable NewRowCol
	variable KeepTogether
	variable Visible
	variable Grow
	variable Shrink
	variable RepeatSection
	variable Height
	variable BackColor
	variable SpecEffect
	variable Tag
	variable OnFormat
	variable OnPrint
	variable OnRetreat
}

# ------------------------------------------------------------------------------
# Command PGAGroupHead::create
#
# Values MSAccess uses for properties
# ForceNewPg - None, Before Section, After Section, Before & After
# NewRowCol - None, Before Section, After Section, Before & After
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc PGAGroupHead::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {GroupHeader1} {}  # Need to add code to increment GroupHeader1, GroupHeader2, ect...
	set ForceNewPg {None}
	set NewRowCol {None}
	set KeepTogether {Yes}
	set Visible {Yes}
	set Grow {No}
	set Shrink {No}
	set RepeatSection {No}
	set Height {0.25"}
	set BackColor \xFFFFFF #White
	set SpecEffect {Flat}
	set Tag {}
	set OnFormat {}
	set OnPrint {}
	set OnRetreat {}


# ------------------------------------------------------------------------------
# Report Detail
# ------------------------------------------------------------------------------
namespace eval PGAReportDetail {
	variable Name
	variable ForceNewPg
	variable NewRowCol
	variable KeepTogether
	variable Visible
	variable Grow
	variable Shrink
	variable Height
	variable BackColor
	variable SpecEffect
	variable Tag
	variable OnFormat
	variable OnPrint
	variable OnRetreat
}

# ------------------------------------------------------------------------------
# Command PGAReportDetail::create
#
# Values MSAccess uses for properties
# ForceNewPg - None, Before Section, After Section, Before & After
# NewRowCol - None, Before Section, After Section, Before & After
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc PGAReportDetail::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {Detail}
	set ForceNewPg {None}
	set NewRowCol {None}
	set KeepTogether {Yes}
	set Visible {Yes}
	set Grow {No}
	set Shrink {No}
	set Height {2"}
	set BackColor \xFFFFFF #White
	set SpecEffect {Flat}
	set Tag {}
	set OnFormat {}
	set OnPrint {}
	set OnRetreat {}
}

# ------------------------------------------------------------------------------
# Group Footer
# ------------------------------------------------------------------------------
namespace eval PGAGroupFoot {
	variable Name
	variable ForceNewPg
	variable NewRowCol
	variable KeepTogether
	variable Visible
	variable Grow
	variable Shrink
	variable Height
	variable BackColor
	variable SpecEffect
	variable Tag
	variable OnFormat
	variable OnPrint
	variable OnRetreat
}

# ------------------------------------------------------------------------------
# Command PGAGroupFoot::create
#
# Values MSAccess uses for properties
# ForceNewPg - None, Before Section, After Section, Before & After
# NewRowCol - None, Before Section, After Section, Before & After
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc PGAGroupFoot::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {GroupFooter1}  # Need to add code to increment GroupFooter1, GroupFooter2, ect...
	set ForceNewPg {None}
	set NewRowCol {None}
	set KeepTogether {Yes}
	set Visible {Yes}
	set Grow {No}
	set Shrink {No}
	set Height {0.25"}
	set BackColor \xFFFFFF #White
	set SpecEffect {Flat}
	set Tag {}
	set OnFormat {}
	set OnPrint {}
	set OnRetreat {}
}

# ------------------------------------------------------------------------------
# Page Footer
# ------------------------------------------------------------------------------
namespace eval PGAPageFoot {
	variable Name
	variable Visible
	variable Hieght
	variable BackColor
	variable SpecEffect
	variable Tag
	variable OnFormat
	variable OnPrint
}

# ------------------------------------------------------------------------------
# Command PGAPageFoot::create
#
# Values MSAccess uses for properties
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc PGAPageFoot::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {PageFooterSection}
	set Visible {Yes}
	set Hieght {0.25"}
	set BackColor \xFFFFFF #White
	set SpecEffect {Flat}
	set Tag {}
	set OnFormat {}
	set OnPrint {}
}

# ------------------------------------------------------------------------------
# Report Footer
# ------------------------------------------------------------------------------
namespace eval PGAPageFoot {
	variable Name
	variable ForceNewPg
	variable NewRowCol
	variable KeepTogether
	variable Visible
	variable Grow
	variable Shrink
	variable Height
	variable BackColor
	variable SpecEffect
	variable Tag
	variable OnFormat
	variable OnPrint
	variable OnRetreat
}

# ------------------------------------------------------------------------------
# Command PGAReportFoot::create
#
# Values MSAccess uses for properties
# ForceNewPg - None, Before Section, After Section, Before & After
# NewRowCol - None, Before Section, After Section, Before & After
# SpecEffect - Flat, Raised, Sunken
# OnFormat - [Event Procedure]- User written TCL script
# OnPrint - [Event Procedure]- User written TCL script 
# OnRetreat - [Event Procedure]- User written TCL script 
# ------------------------------------------------------------------------------
proc PGAReportFoot::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {ReportFooter}
	set ForceNewPg {None}
	set NewRowCol {None}
	set KeepTogether {Yes}
	set Visible {Yes}
	set Grow {No}
	set Shrink {No}
	set Height {0.25")
	set BackColor \xFFFFFF #White
	set SpecEffect {Flat}
	set Tag {}
	set OnFormat {}
	set OnPrint {}
	set OnRetreat {}

}

# ------------------------------------------------------------------------------
# Report Label Box
# ------------------------------------------------------------------------------
namespace eval PGALabelBox {
	variable Name
	variable Caption
	variable HypAdd
	variable HypSubAdd
	variable Visible
	variable Vertical
	variable Left
	variable Top
	variable Width
	variable Height
	variable BackStyle
	variable BackColor
	variable SpecEffect
	variable BroderStyle
	variable BorderColor
	variable BorderWidth
	variable ForeColor
	variable FontName
	variable FontSize
	variable FontWeight
	variable FontItalic
	variable FontUnderline
	variable TextAlign
	variable Tag
	variable LeftMargin
	variable TopMargin
	variable RightMargin
	variable BottomMargin
	variable LineSpacing
 }

# ------------------------------------------------------------------------------
# Command PGALabelBox::create
#
# Values MSAccess uses for properties
# SpecEffect - Flat, Raised, Sunken
# BorderStyle - Transparent, Solid, Dashes, Short Dashes, Dots, Sparse Dots,
#               Dash Dot, Dash Dot Dot
# BorderWidth - Hairline, 1 pt, 2 pt, 3 pt, 4 pt, 5 pt, 6 pt
# ------------------------------------------------------------------------------
proc PGALabelBox::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {Label1}  # Need to add code to increment Label1, Label2, ect...
	set Caption {} # This is what is displayed in the label
	set HypAdd {}
	set HypSubAdd {}
	set Visible {Yes}
	set Vertical {No}
	set Left {} # Function of where you actually place widget
	set Top {} # Function of where you actually place widget
	set Width {} # Function of how you size widget
	set Height {}  # Function of how you size widget
	set BackStyle {Transparent}
	set BackColor \xFFFFFF # White
	set SpecEffect {Flat}
	set BorderStyle {Transparent}
	set BorderColor 0  #Black
	set BorderWidth {Hairline}
	set ForeColor \xF8F7F6 #Some other color besides white
	set FontName {Times New Roman}
	set FontSize 11
	set FontWeight {Bold}
	set FontItalic {Yes}
	set FontUnderline {No}
	set TextAlign {Left}
	set Tag {}
	set LeftMargin {0"}
	set TopMargin {0"}
	set RightMargin {0"}
	set BottomMargin {0"}
	set LineSpacing {0"}
}


# ------------------------------------------------------------------------------
# Report Text Box
# ------------------------------------------------------------------------------
# The text box does the same function as the entry widget.
 namespace eval PGATextBox {
	variable Name
	variable ControlSrc   # Can be query, table, data from another widget, or fixed value
	variable Format
	variable DecPlaces
	variable InputMask
	variable Visible
	variable Vertical
	variable HideDup
	variable Grow
	variable Shrink
	variable RunSum
	variable Left
	variable Top
	variable Width
	variable Height
	variable BackStyle
	variable BackColor
	variable SpecEffect
	variable BroderStyle
	variable BorderColor
	variable BorderWidth
	variable ForeColor
	variable FontName
	variable FontSize
	variable FontWeight
	variable FontItalic
	variable FontUnder
	variable TextAlign
	variable Tag
	variable LeftMargin
	variable TopMargin
	variable RightMargin
	variable BottomMargin
	variable LineSpacing
	variable IsHypLink
 }
# ------------------------------------------------------------------------------
# Command PGATextBox::create
#
# Values MSAccess uses for properties
# Format - General Date, Long Date, Medium Date, Short Date, Long Time,
#          Medium Time, Short Time, General Number, Currency, Euro, Fixed
#          Standard, Percent, Scienfitic, True/False, Yes/No, On/Off
# DecPlaces - Auto, 0, 1 ,2 ,3 ,4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
# InputMask - Phone Number, Social Security Number, Zip Code, Extension
#             Password, Long Time, Short Date, Short Time, Medium Time, 
#             Medium Date
# SpecEffect - Flat, Raised, Sunken
# BorderStyle - Transparent, Solid, Dashes, Short Dashes, Dots, Sparse Dots,
#               Dash Dot, Dash Dot Dot
# BorderWidth - Hairline, 1 pt, 2 pt, 3 pt, 4 pt, 5 pt, 6 pt
# FontWeight - Thin, Extra Light, Light, Normal, Medium, Semi-bold, Bold,
#              Extra Bold, Heavy
# TextAlign - General, Left, Center, Right, Distribute
# ------------------------------------------------------------------------------
proc PGATextBox::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {TextBox1}  # Need to add code to increment TextBox1, TextBox2, ect...
	set ControlSrc {}  # Can be query, table, data from another widget, or fixed value
	set Format {}
	set DecPlaces {Auto}
	set InputMask {}
	set Visible {Yes}
	set Vertical {No}
	set HideDup {No}
	set Grow {No}
	set Shrink {No}
	set RunSum {No}
	set Left {} # Function of where you actually place widget
	set Top {} # Function of where you actually place widget
	set Width {} # Function of how you size widget
	set Height {}  # Function of how you size widget
	set BackStyle {Transparent}
	set BackColor \xFFFFFF # White
	set SpecEffect {Flat}
	set BorderStyle {Transparent}
	set BorderColor 0  #Black
	set BorderWidth {Hairline}
	set ForeColor  0  #Black
	set FontName {Arial}
	set FontSize 8
	set FontWeight {Normal}
	set FontItalic {No}
	set FontUnderline {No}
	set TextAlign {General}
	set Tag {}
	set LeftMargin {0"}
	set TopMargin {0"}
	set RightMargin {0"}
	set BottomMargin {0"}
	set LineSpacing {0"}
	set IsHypLink {No}

}

# ------------------------------------------------------------------------------
# Report Image Box
# ------------------------------------------------------------------------------
 namespace eval PGAImageBox {
	variable Name
	variable Pic
	variable PicType
	variable SizeMode
	variable PicAlign
	variable HypAdd
	variable HypSubAdd
	variable Visible
	variable Left
	variable Top
	variable Width
	variable Height
	variable BackStyle
	variable BackColor
	variable SpecEffect
	variable BorderStyle
	variable BorderColor
	variable BorderWidth
	variable Tag
 }

# ------------------------------------------------------------------------------
# Command PGAImageBox::create
#
# Values MSAccess uses for properties
# Pic - The actual path to the picture
# PicType - Embedded, Link
# PicSizeMode - Clip, Stretch, Zoom
# BackStyle - Transparent, Normal
# SpecEffect - Flat, Raised, Sunken
# BorderStyle - Transparent, Solid, Dashes, Short Dashes, Dots, Sparse Dots,
#               Dash Dot, Dash Dot Dot
# BorderWidth - Hairline, 1 pt, 2 pt, 3 pt, 4 pt, 5 pt, 6 pt
# ------------------------------------------------------------------------------
proc PGAImageBox::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {Image1}  # Need to add code to increment Image1, Image2, ect...
	set Pic {}  # The actual path to the picture
	set PicType {Empedded}
	set SizeMode {Clip}
	set PicAlign {Center}
	set HypAdd {}
	set HypSubAdd {}
	set Visible {Yes}
	set Left {} # Function of where you actually place widget
	set Top {} # Function of where you actually place widget
	set Width {} # Function of how you size widget
	set Height {}  # Function of how you size widget
	set BackStyle {Normal}
	set BackColor \xFFFFFF # White
	set SpecEffect {Flat}
	set BorderStyle {Transparent}
	set BorderColor 0  #Black
	set BorderWidth {Hairline}
	set Tag {}
 }

# ------------------------------------------------------------------------------
# Report Unbound Object Frame
# ------------------------------------------------------------------------------
 namespace eval PGAUnboundObjectFrame {
	variable Name
	variable SizeMode
	variable OLEClass
	variable RowSrcType
	variable RowSrc
	variable LinkChild
	variable LinkMaster
	variable DisplayType
	variable UpdateOptions
	variable Verb
	variable OLEType
	variable OLETypeAllow
	variable Class
	variable SourceDoc
	variable SourceItem
	variable NumCol
	variable ColHead
	variable Visible
	variable Left
	variable Top
	variable Width
	variable Height
	variable BackStyle
	variable BackColor
	variable SpecEffect
	variable BorderStyle
	variable BorderColor
	variable BorderWidth
	variable Tag

 }

# ------------------------------------------------------------------------------
# Command PGAUnboundObjectFrame::create
#
# Values MSAccess uses for properties
# SizeMode - Clip, Stretch, Zoom
# RowSrcType - Table/Query, Value List, Field List
# DisplayType - Content, Icon
# UpdateOptions - Automatic, Manual
# OLEType - Embedded, Link, None
# OLETypeAllow - Embedded, Link, Either
# BackStyle - Transparent, Normal
# SpecEffect - Flat, Raised, Sunken
# BorderStyle - Transparent, Solid, Dashes, Short Dashes, Dots, Sparse Dots,
#               Dash Dot, Dash Dot Dot
# BorderWidth - Hairline, 1 pt, 2 pt, 3 pt, 4 pt, 5 pt, 6 pt
# ------------------------------------------------------------------------------
proc PGAUnboundObjectFrame::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {OLEUnbound1}  # Need to add code to increment OLEUnbound1, OLEUnbound2, ect...
	set SizeMode {Clip}
	set OLEClass {} # Name of the class Example-Microsoft Excel 2000
	set RowSrcType {}
	set RowSrc {}
	set LinkChild {}
	set LinkMaster {}
	set DisplayType {Content}
	set UpdateOptions {Automatic}
	set Verb 0
	set OLEType {Embedded}
	set OLETypeAllow {Either}
	set Class {} # With the Excel example - Excel.Sheet.8
	set SourceDoc {}
	set SourceItem {}
	set NumCol 0
	set ColHead {No}
	set Visible {Yes}
	set Left {} # Function of where you actually place widget
	set Top {} # Function of where you actually place widget
	set Width {} # Function of how you size widget
	set Height {}  # Function of how you size widget
	set BackStyle {Normal}
	set BackColor \xFFFFFF # White
	set SpecEffect {Flat}
	set BorderStyle {Solid}
	set BorderColor 0  #Black
	set BorderWidth {Hairline}
	set Tag {}

 }




# ------------------------------------------------------------------------------
# Report Bound Object Frame
# ------------------------------------------------------------------------------
 namespace eval PGABoundObjectFrame {
	variable Name
	variable ControlSrc
	variable SizeMode
	variable Class
	variable SourceDoc
	variable SourceItem
	variable DisplayType
	variable UpdateOptions
	variable Verb
	variable OLETypeAllow
	variable Visible
	variable Left
	variable Top
	variable Width
	variable Height
	variable BackStyle
	variable BackColor
	variable SpecEffect
	variable BorderStyle
	variable BorderColor
	variable BorderWidth
	variable Tag

 }

# ------------------------------------------------------------------------------
# Command PGABoundObjectFrame::create
#
# Values MSAccess uses for properties
# SizeMode - Clip, Stretch, Zoom
# RowSrcType - Table/Query, Value List, Field List
# DisplayType - Content, Icon
# UpdateOptions - Automatic, Manual
# OLETypeAllow - Embedded, Link, Either
# BackStyle - Transparent, Normal
# SpecEffect - Flat, Raised, Sunken
# BorderStyle - Transparent, Solid, Dashes, Short Dashes, Dots, Sparse Dots,
#               Dash Dot, Dash Dot Dot
# BorderWidth - Hairline, 1 pt, 2 pt, 3 pt, 4 pt, 5 pt, 6 pt
# ------------------------------------------------------------------------------
proc PGABoundObjectFrame::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {OLEBound1}  # Need to add code to increment OLEBound1, OLEBound2, ect...
	set ControlSrc {}
	set SizeMode {Clip}
	set Class {}
	set SourceDoc {}
	set SourceItem {}
	set DisplayType {Content}
	set UpdateOptions {Automatic}
	set Verb 0
	set OLETypeAllow {Either}
	set Visible {Yes}
	set Left {} # Function of where you actually place widget
	set Top {} # Function of where you actually place widget
	set Width {} # Function of how you size widget
	set Height {}  # Function of how you size widget
	set BackStyle {Normal}
	set BackColor \xFFFFFF # White
	set SpecEffect {Flat}
	set BorderStyle {Solid}
	set BorderColor 0  #Black
	set BorderWidth {Hairline}
	set Tag {}
 }

# ------------------------------------------------------------------------------
# Sub Report
# ------------------------------------------------------------------------------

 namespace eval PGASubReport {
	variable Name
	variable SourceObject
	variable LinkChild
	variable LinkMaster
	variable Visible
	variable Grow
	variable Shrink
	variable Left
	variable Top
	variable Width
	variable Height
	variable SpecEffect
	variable BorderStyle
	variable BorderWidth
	variable BorderColor
	variable Tag

 }

# ------------------------------------------------------------------------------
# Command PGASubReport::create
#
# Values MSAccess uses for properties
# SpecEffect - Flat, Raised, Sunken
# BorderStyle - Transparent, Solid, Dashes, Short Dashes, Dots, Sparse Dots,
#               Dash Dot, Dash Dot Dot
# BorderWidth - Hairline, 1 pt, 2 pt, 3 pt, 4 pt, 5 pt, 6 pt
# ------------------------------------------------------------------------------
proc PGASubReport::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {}  # Name of the report, table or query
	set SourceObject {} # Name of the report, table or query with "Report." prepended
	set LinkChild {} # Name of field
	set LinkMaster {} # Name of field
	set Visible {Yes}
	set Grow {Yes}
	set Shrink {No}
	set Left {} # Function of where you actually place widget
	set Top {} # Function of where you actually place widget
	set Width {} # Function of how you size widget
	set Height {}  # Function of how you size widget
	set SpecEffect {Flat}
	set BorderStyle {Transparent}
	set BorderWidth {Hairline}
	set BorderColor 0  #Black
	set Tag {}
 }

# ------------------------------------------------------------------------------
# Report Line
# ------------------------------------------------------------------------------

 namespace eval PGALine {
	variable Name
	variable Slant
	variable Visible
	variable Left
	variable Top
	variable Width
	variable Height
	variable SpecEffect
	variable BorderStyle
	variable BorderColor
	variable BorderWidth
	variable Tag
 }

# ------------------------------------------------------------------------------
# Command PGALine::create
#
# Values MSAccess uses for properties
# Slant - \, /
# SpecEffect - Flat, Raised, Sunken
# BorderStyle - Transparent, Solid, Dashes, Short Dashes, Dots, Sparse Dots,
#               Dash Dot, Dash Dot Dot
# BorderWidth - Hairline, 1 pt, 2 pt, 3 pt, 4 pt, 5 pt, 6 pt
# ------------------------------------------------------------------------------
proc PGALine::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {Line1}  # Need to add code to increment Line1, Line2, ect...
	set Slant {\} 
	set Visible {Yes}
	set Left {} # Function of where you actually place widget
	set Top {} # Function of where you actually place widget
	set Width {} # Function of how you size widget
	set Height {}  # Function of how you size widget
	set SpecEffect {Flat}
	set BorderStyle {Transparent}
	set BorderColor 0  #Black
	set BorderWidth {Hairline}
	set Tag {}
}


# ------------------------------------------------------------------------------
# Report Rectangle
# ------------------------------------------------------------------------------
 namespace eval PGARectangle {
	variable Name
	variable Visible
	variable Left
	variable Top
	variable Width
	variable Height
	variable BackStyle
	variable BackColor
	variable SpecEffect
	variable BorderStyle
	variable BorderColor
	variable BorderWidth
	variable Tag
 }

# ------------------------------------------------------------------------------
# Command PGARectangle::create
#
# Values MSAccess uses for properties
# BackStyle - Transparent, Normal
# SpecEffect - Flat, Raised, Sunken
# BorderStyle - Transparent, Solid, Dashes, Short Dashes, Dots, Sparse Dots,
#               Dash Dot, Dash Dot Dot
# BorderWidth - Hairline, 1 pt, 2 pt, 3 pt, 4 pt, 5 pt, 6 pt
# ------------------------------------------------------------------------------
proc PGALine::create {path args} {
	variable $path
	upvar 0 $path data

	set Name {Box}  # Need to add code to increment Box1, Box2, ect...
	set Visible {Yes}
	set Left {} # Function of where you actually place widget
	set Top {} # Function of where you actually place widget
	set Width {} # Function of how you size widget
	set Height {}  # Function of how you size widget
	set BackStyle {Transparent}
	set BackColor \xF8F7F6 # Some other color than white
	set SpecEffect {Flat}
	set BorderStyle {Transparent}
	set BorderColor 0  #Black
	set BorderWidth {1 pt}
	set Tag {}


}


