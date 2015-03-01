# partially taken from the Tk revitalization project
#

option add *Menu.tearOff 0

set SystemButtonFace #D4D0C8
set SystemButtonText #000000
set SystemHighlight #0A226A
set SystemHighlightText #ffffff
set SystemWindow #ffffff
set SystemDisabledWindow #fbfbfb
set SystemWindowText #000000
set SystemDisabledWindowText #222222
set SystemWindowFrame #000000
set NORMAL_BG [. cget -bg]
set NORMAL_FG $SystemButtonText
set SELECT_BG $SystemHighlight
set SELECT_FG $SystemHighlightText
set MENU_BG $NORMAL_BG
set MENU_FG $NORMAL_FG
set HIGHLIGHT $SystemWindowFrame
set TEXT_FG $SystemWindowText
set TROUGH $NORMAL_BG

# on X11, adjust the default widths of some widgets, to look less clunky
if {[tk windowingsystem]=="x11"} {
    option add *Button.padX 1
    option add *Button.padY 1
    option add *Listbox.selectBorderWidth 0
    option add *Entry.selectBorderWidth 0
    option add *Entry.borderWidth 1
    option add *Text.selectBorderWidth 0
    option add *Menu.activeBorderWidth 0
    option add *Menu.highlightThickness 0
    option add *Menu.borderWidth 2
    option add *Menu.relief flat
    option add *Menubutton.activeBorderWidth 0
    option add *Menubutton.highlightThickness 0
    option add *Menubutton.borderWidth 2
    option add *highlightThickness 0
    option add *Scrollbar.borderWidth 1

    # don't use the handle for paned windows
    option add *Panedwindow.showHandle 0
    set SystemButtonFace #D4D0C8
    set SystemButtonText #000000
    set SystemHighlight #0A226A
    set SystemHighlightText #ffffff
    set SystemWindow #ffffff
    set SystemDisabledWindow #fbfbfb
    set SystemWindowText #000000
    set SystemDisabledWindowText #222222
    set SystemWindowFrame #000000
    #set NORMAL_BG $SystemButtonFace
    set NORMAL_BG [. cget -bg]
    set NORMAL_FG $SystemButtonText
    set SELECT_BG $SystemHighlight
    set SELECT_FG $SystemHighlightText
    set MENU_BG $NORMAL_BG
    set MENU_FG $NORMAL_FG
    set HIGHLIGHT $SystemWindowFrame
    set TEXT_FG $SystemWindowText
    set TROUGH $NORMAL_BG

    # need to set this explicitly, since its already been created
    #. configure -bg $NORMAL_BG

    option add *Button.activeBackground $NORMAL_BG
    option add *Button.activeForeground $NORMAL_FG
    option add *Button.background $NORMAL_BG
    option add *Button.foreground $NORMAL_FG
    option add *Button.highlightBackground $NORMAL_BG
    option add *Button.highlightForeground $NORMAL_FG

    option add *Label.activeBackground $NORMAL_BG
    option add *Label.activeForeground $NORMAL_FG
    option add *Label.background $NORMAL_BG
    option add *Label.foreground $NORMAL_FG
    option add *Label.highlightBackground $NORMAL_BG
    option add *Label.highlightForeground $NORMAL_FG

    option add *Checkbutton.background $NORMAL_BG
    option add *Checkbutton.foreground $NORMAL_FG
    option add *Checkbutton.highlightBackground $NORMAL_BG
    option add *Checkbutton.highlightForeground $NORMAL_FG
    option add *Checkbutton.activeForeground $NORMAL_FG
    option add *Checkbutton.activeBackground $NORMAL_BG

    option add *Radiobutton.background $NORMAL_BG
    option add *Radiobutton.foreground $NORMAL_FG
    option add *Radiobutton.highlightBackground $NORMAL_BG
    option add *Radiobutton.highlightForeground $NORMAL_FG
    option add *Radiobutton.activeForeground $NORMAL_FG
    option add *Radiobutton.activeBackground $NORMAL_BG

    option add *Canvas.background $NORMAL_BG

    option add *Entry.background $SystemWindow
    option add *Entry.disabledBackground $SystemDisabledWindow
    option add *Entry.foreground $SystemWindowText
    option add *Entry.disabledForeground $SystemDisabledWindowText
    option add *Entry.highlightBackground $NORMAL_BG
    option add *Entry.insertBackground $SystemWindowText
    option add *Entry.selectBackground $SELECT_BG
    option add *Entry.selectForeground $SELECT_FG

    option add *Frame.background $NORMAL_BG
    option add *Frame.highlightBackground $NORMAL_BG
    option add *Frame.highlightForeground $SystemWindowFrame

    option add *Labelframe.foreground $NORMAL_FG
    option add *Labelframe.background $NORMAL_BG

    option add *Listbox.background $SystemWindow
    option add *Listbox.foreground $NORMAL_FG
    option add *Listbox.selectForeground $SELECT_FG
    option add *Listbox.selectBackground $SELECT_BG
    option add *Listbox.highlightBackground $NORMAL_BG
    option add *Listbox.highlightForeground $HIGHLIGHT

    option add *Menu.activeBackground $SELECT_BG
    option add *Menu.activeForeground $SELECT_FG
    option add *Menu.background $MENU_BG
    option add *Menu.foreground $MENU_FG
    option add *Menu.selectForeground $MENU_FG
    
    option add *Menubutton.activeBackground $NORMAL_BG
    option add *Menubutton.activeForeground $NORMAL_FG
    option add *Menubutton.background $NORMAL_BG
    option add *Menubutton.foreground $NORMAL_FG

    option add *Message.background $NORMAL_BG
    option add *Messsage.foreground $NORMAL_FG

    option add *Panedwindow.background $NORMAL_BG

    option add *Scale.activeBackground $NORMAL_BG
    option add *Scale.background $NORMAL_BG
    option add *Scale.foreground $NORMAL_FG
    option add *Scale.troughColor $TROUGH

    option add *Scrollbar.activeBackground $NORMAL_BG
    option add *Scrollbar.background $NORMAL_BG
    option add *Scrollbar.highlightBackground $NORMAL_BG
    option add *Scrollbar.highlightForeground $HIGHLIGHT
    option add *Scale.troughColor $TROUGH

    option add *Text.background $SystemWindow
    option add *Text.foreground $SystemWindowText
    option add *Text.highlightBackground $NORMAL_BG
    option add *Text.highlightForeground $HIGHLIGHT
    option add *Text.insertForeground $TEXT_FG
    option add *Text.selectBackground $SELECT_BG
    option add *Text.selectForeground $SELECT_FG

    option add *Toplevel.background $NORMAL_BG
}


option add *Entry.disabledBackground $SystemDisabledWindow
option add *Entry.disabledForeground $SystemDisabledWindowText
