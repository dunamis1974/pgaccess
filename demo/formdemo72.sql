--
-- Selected TOC Entries:
--
\connect - tester

--
-- TOC Entry ID 2 (OID 7466820)
--
-- Name: cities_id_seq Type: SEQUENCE Owner: tester
--

CREATE SEQUENCE "cities_id_seq" start 1 increment 1 maxvalue 2147483647 minvalue 1 cache 1;

--
-- TOC Entry ID 4 (OID 7466822)
--
-- Name: pga_queries Type: TABLE Owner: tester
--

CREATE TABLE "pga_queries" (
	"queryname" character varying(64),
	"querytype" character(1),
	"querycommand" text,
	"querytables" text,
	"querylinks" text,
	"queryresults" text,
	"querycomments" text
);

--
-- TOC Entry ID 5 (OID 7466827)
--
-- Name: pga_forms Type: TABLE Owner: tester
--

CREATE TABLE "pga_forms" (
	"formname" character varying(64),
	"formsource" text
);

--
-- TOC Entry ID 6 (OID 7466832)
--
-- Name: pga_scripts Type: TABLE Owner: tester
--

CREATE TABLE "pga_scripts" (
	"scriptname" character varying(64),
	"scriptsource" text
);

--
-- TOC Entry ID 7 (OID 7466837)
--
-- Name: pga_reports Type: TABLE Owner: tester
--

CREATE TABLE "pga_reports" (
	"reportname" character varying(64),
	"reportsource" text,
	"reportbody" text,
	"reportprocs" text,
	"reportoptions" text
);

--
-- TOC Entry ID 8 (OID 7466842)
--
-- Name: phonebook Type: TABLE Owner: tester
--

CREATE TABLE "phonebook" (
	"name" character varying(32),
	"phone_nr" character varying(16),
	"city" character varying(32),
	"company" boolean,
	"continent" character varying(16)
);

--
-- TOC Entry ID 9 (OID 7466844)
--
-- Name: pga_layout Type: TABLE Owner: tester
--

CREATE TABLE "pga_layout" (
	"tablename" character varying(64),
	"nrcols" smallint,
	"colnames" text,
	"colwidth" text
);

--
-- TOC Entry ID 10 (OID 7466849)
--
-- Name: pga_schema Type: TABLE Owner: tester
--

CREATE TABLE "pga_schema" (
	"schemaname" character varying(64),
	"schematables" text,
	"schemalinks" text
);

--
-- TOC Entry ID 11 (OID 7466849)
--
-- Name: pga_schema Type: ACL Owner: 
--

REVOKE ALL on "pga_schema" from PUBLIC;
GRANT ALL on "pga_schema" to PUBLIC;
GRANT ALL on "pga_schema" to "tester";

--
-- TOC Entry ID 12 (OID 7466854)
--
-- Name: cities Type: TABLE Owner: tester
--

CREATE TABLE "cities" (
	"id" integer DEFAULT nextval('cities_id_seq'::text) NOT NULL,
	"name" character varying(32) NOT NULL,
	"prefix" character varying(16) NOT NULL
);

--
-- TOC Entry ID 13 (OID 7466854)
--
-- Name: cities Type: ACL Owner: 
--

REVOKE ALL on "cities" from PUBLIC;
GRANT ALL on "cities" to "tester";

--
-- TOC Entry ID 15 (OID 7466856)
--
-- Name: "getcityprefix" (integer) Type: FUNCTION Owner: tester
--

CREATE FUNCTION "getcityprefix" (integer) RETURNS character varying AS 'select prefix from cities where id = $1 ' LANGUAGE 'sql';

--
-- Data for TOC Entry ID 16 (OID 7466822)
--
-- Name: pga_queries Type: TABLE DATA Owner: tester
--


COPY "pga_queries" FROM stdin;
Query that can be saved as view	S	select * from phonebook where continent='usa'    	\N	\N	\N	\N
get phonebook for city	S	SELECT * FROM phonebook WHERE city='$select_city' 				\

show the cities	S	select t0."name" from "cities" t0    	cities 10 10 t0		name t0 unsorted {} Yes	\

\.
--
-- Data for TOC Entry ID 17 (OID 7466827)
--
-- Name: pga_forms Type: TABLE DATA Owner: tester
--


COPY "pga_forms" FROM stdin;
Working with Tables namespace	f3 13 {3 4 5 6 7 9 10 11 12 13} 377x263+59+127 {radio usa {36 24 138 36} {} USA selcont} {radio europe {36 45 141 60} {} Europe selcont} {radio africa {36 66 147 81} {} Africa selcont} {label label6 {9 99 339 114} {} {Select one of the above continents and press} {}} {button button7 {270 93 354 117} {Tables::open phonebook "continent='$selcont'" $selorder} {Show them} {}} {button button9 {66 189 312 213} {Tables::design phonebook} {Show me the phonebook table structure} {}} {button button10 {141 228 240 252} {destroy .f3} {Close the form} {}} {button button11 {93 141 282 165} {Tables::open phonebook "company=true"} {Show me only the companies} {}} {radio name {183 24 261 36} {} {Order by name} selorder} {radio phone_nr {183 45 267 57} {} {Order by phone number} selorder}
The simplest form	mf 5 {FS {set thename {}}} 306x136+82+146 {label label {42 45 99 60} {} Name {} label flat #000000 #d9d9d9 1 {Helvetica 12 bold italic}} {entry ename {120 42 219 63} {} entry2 thename ename sunken #000000 #fefefe 1 n} {button button3 {6 96 108 129} {set thename Teo} {Set the name} {} button3 raised #000000 #d9d9d9 1 n} {button button4 {192 96 300 129} {destroy .mf} {Close the form} {} button4 raised #000000 #d9d9d9 1 n} {button button5 {114 96 186 129} {set thename {}} {Clear it} {} button5 raised #000000 #d9d9d9 1 n}
A simple demo form	asdf 14 {FS {set color none}} 370x310+50+75 {label label1 {15 36 99 57} {} {Selected color} {} label1 flat #000000 #d9d9d9 1} {entry entry2 {111 36 225 54} {} entry2 color entry2 sunken #000000 #fefefe 1} {radio red {249 21 342 36} {} {Red as cherry} color red flat #900000 #d9d9d9 1} {radio green {249 45 342 60} {} {Green as a melon} color green flat #008800 #d9d9d9 1} {radio blue {249 69 342 84} {} {Blue as the sky} color blue flat #00008c #d9d9d9 1} {button button6 {45 69 198 99} {set color spooky} {Set a weird color} {} button6 ridge #0000b0 #dfbcdf 2} {label label7 {24 129 149 145} {} {The checkbox's value} {} label7 flat #000000 #d9d9d9 1} {entry entry8 {162 127 172 145} {} entry8 cbvalue entry8 sunken #000000 #fefefe 1} {checkbox checkbox9 {180 126 279 150} {} {Check me :-)} cbvalue checkbox9 flat #000000 #d9d9d9 1} {button button10 {219 273 366 303} {destroy .asdf} {Close that simple form} {} button10 raised #000000 #d9d9d9 1} {button button11 {219 237 366 267} {Forms::open "Phone book"} {Open my phone book} {} button11 raised #000000 #d9d9d9 1} {listbox lb {12 192 162 267} {} listbox12 {} lb sunken #000000 #fefefe 1} {button button13 {12 156 162 186} {.asdf.lb insert end red green blue cyan white navy black purple maroon violet} {Add some information} {} button13 raised #000000 #d9d9d9 1} {button button14 {12 273 162 303} {.asdf.lb delete 0 end} {Clear this listbox} {} button14 raised #000000 #d9d9d9 1}
Working with listboxes	f2 5 {FS {set thestudent ""}} 257x263+139+147 {listbox lb {6 6 246 186} {} listbox1 {} lb sunken #000000 #ffffd4 1} {button button2 {9 234 124 258} {# Populate the listbox with some data\
#\
\
foreach student {John Bill Doe Gigi} {\
\	.f2.lb insert end $student\
}\
\
\
\
# Binding the event left button release to the\
# list box\
\
bind .f2.lb <ButtonRelease-1> {\
\	set idsel [.f2.lb curselection]\
\	if {$idsel!=""} {\
\	\	set thestudent [.f2.lb get $idsel]\
\	}\
}\
\
# Cleaning the variable thestudent\
\
set thestudent {}} {Show students} {} button2 groove #000000 #d9d9d9 2} {button button3 {132 234 247 258} {destroy .f2} {Close the form} {} button3 groove #000000 #d9d9d9 1} {label label4 {9 213 119 228} {} {You have selected} {} label4 flat #000000 #d9d9d9 1} {label label5 {129 213 219 228} {} {} thestudent label5 flat #00009a #d9d9d9 1}
Invoices	inv 0 {FS {frame .inv.f\
place .inv.f -x 5 -y 100 -width 500 -height 300\
set wn [Tables::getNewWindowName]\
Tables::createWindow .inv.f\
set PgAcVar(mw,.inv.f,updatable) 0\
set PgAcVar(mw,.inv.f,layout_found) 0\
set PgAcVar(mw,.inv.f,layout_name) ""\
Tables::selectRecords .inv.f "select * from cities"\
}} 631x439+87+84
Phone book	{pb 28 {} 470x320+177+446 #999999 left_ptr} {label label1 {30 10 70 30} {} Name {} label1 flat #000000 #d9d9d9 1 n center l left_ptr} {entry name_entry {90 10 230 30} {} entry2 DataSet(.pb.qs,name) name_entry sunken #000000 #fefefe 1 n center l left_ptr} {label label3 {30 40 70 60} {} Phone {} label3 flat #000000 #d9d9d9 1 n center l left_ptr} {entry entry4 {90 40 200 60} {} entry4 DataSet(.pb.qs,phone_nr) entry4 sunken #000000 #fefefe 1 n center l left_ptr} {label label5 {30 70 70 90} {} City {} label5 flat #000000 #d9d9d9 1 n center l left_ptr} {entry entry6 {90 70 200 90} {} entry6 DataSet(.pb.qs,city) entry6 sunken #000000 #fefefe 1 n center l left_ptr} {query qs {3 6 33 33} {} query7 {} qs flat {} {} 1 n center l left_ptr} {button button8 {180 170 260 210} {namespace eval DataControl(.pb.qs) {\
\	setSQL "select oid,* from phonebook where name ~* '$what' order by name"\
\	open\
\	set nrecs [getRowCount]\
\	updateDataSet\
\	fill .pb.allnames name\
\	bind .pb.allnames <ButtonRelease-1> {\
\	   set ancr [.pb.allnames curselection]\
\	   if {$ancr!=""} {\
\	\	DataControl(.pb.qs)::moveTo $ancr\
\	\	DataControl(.pb.qs)::updateDataSet\
\	   }\
\	}\
}} {Start search} {} button8 raised #000000 #d9d9d9 1 n center l left_ptr} {button button9 {390 280 460 310} {DataControl(.pb.qs)::close\
DataControl(.pb.qs)::clearDataSet\
set nrecs {}\
set what {}\
destroy .pb\
} Exit {} button9 raised #000000 #d9d9d9 2 n center l left_ptr} {button button10 {300 240 320 260} {namespace eval DataControl(.pb.qs) {\
\	moveFirst\
\	updateDataSet\
}\
} |< {} button10 ridge #000092 #d9d9d9 2 n center l left_ptr} {button button11 {330 240 350 260} {namespace eval DataControl(.pb.qs) {\
\	movePrevious\
\	updateDataSet\
}\
} << {} button11 ridge #000000 #d9d9d9 2 n center l left_ptr} {button button12 {350 240 370 260} {namespace eval DataControl(.pb.qs) {\
\	moveNext\
\	updateDataSet\
}} >> {} button12 ridge #000000 #d9d9d9 2 n center l left_ptr} {button button13 {380 240 400 260} {namespace eval DataControl(.pb.qs) {\
\	moveLast\
\	updateDataSet\
}\
} >| {} button13 ridge #000088 #d9d9d9 2 n center l left_ptr} {checkbox checkbox14 {40 100 140 120} {} {Is it a company ?} DataSet(.pb.qs,company) checkbox14 flat #000000 #d9d9d9 1 n center l left_ptr} {radio usa {20 130 100 150} {} U.S.A. DataSet(.pb.qs,continent) usa flat #000000 #d9d9d9 1 n center l left_ptr} {radio europe {90 130 170 150} {} Europe DataSet(.pb.qs,continent) europe flat #000000 #d9d9d9 1 n center l left_ptr} {radio africa {170 130 250 150} {} Africa DataSet(.pb.qs,continent) africa flat #000000 #d9d9d9 1 n center l left_ptr} {entry entry18 {130 180 170 200} {} entry18 what entry18 sunken #000000 #fefefe 1 n center l left_ptr} {label label19 {110 220 190 240} {} {records found} {} label19 flat #000000 #d9d9d9 1 n center l left_ptr} {label label20 {90 220 110 240} {} { } nrecs label20 flat #000000 #d9d9d9 1 n center l left_ptr} {label label21 {0 250 30 270} {} OID= {} label21 flat #000000 #d9d9d9 1 n center l left_ptr} {label label22 {39 252 87 267} {} { } pbqs(oid) label22 flat #000000 #d9d9d9 1 n center l left_ptr} {button button23 {10 280 80 310} {set oid {}\
catch {set oid $DataSet(.pb.qs,oid)}\
if {[string trim $oid]!=""} {\
   sql_exec noquiet "update phonebook set name='$DataSet(.pb.qs,name)', phone_nr='$DataSet(.pb.qs,phone_nr)',city='$DataSet(.pb.qs,city)',company='$DataSet(.pb.qs,company)',continent='$DataSet(.pb.qs,continent)' where oid=$oid"\
} else {\
  tk_messageBox -title Error -message "No record is displayed!"\
}\
\
} Update {} button23 raised #000000 #d9d9d9 1 n center l left_ptr} {button button24 {210 280 280 310} {set thisname $DataSet(.pb.qs,name)\
if {[string trim $thisname] != ""} {\
\	sql_exec noquiet "insert into phonebook values (\
\	\	'$DataSet(.pb.qs,name)',\
\	\	'$DataSet(.pb.qs,phone_nr)',\
\	\	'$DataSet(.pb.qs,city)',\
\	\	'$DataSet(.pb.qs,company)',\
\	\	'$DataSet(.pb.qs,continent)'\
\	)"\
\	tk_messageBox -title Information -message "A new record has been added!"\
} else {\
\	tk_messageBox -title Error -message "This one doesn't have a name?"\
}\
\
} {Add record} {} button24 raised #000000 #d9d9d9 1 n center l left_ptr} {button button25 {140 280 200 310} {DataControl(.pb.qs)::clearDataSet\
# clearcontrols stillinitialise\
# incorectly booleans controls to {}\
# so I force it to 'f' (false)\
set DataSet(.pb.qs,company) f\
focus .pb.name_entry} {Clear all} {} button25 raised #000000 #d9d9d9 1 n center l left_ptr} {listbox allnames {270 10 460 230} {} listbox26 {} allnames sunken #000000 #fefefe 1 n center l left_ptr} {label label27 {30 250 90 270} {} {} DataSet(.pb.qs,oid) label27 flat #000000 #d9d9d9 1 n center l left_ptr} {label label28 {0 180 130 200} {} {Find name containing} {} {} flat #000000 #d9d9d9 1 n center l left_ptr}
Full featured form	{full 42 {set entrydemo {nice}\
set color {no color selected}\
\
.full.combobox_demo configure -values {Look a BWidget combo box}\
\
.full.spinbox_demo1 configure -range {0 100 1}\
.full.spinbox_demo2 configure -range {-1000000 1000000 10}\
.full.spinbox_demo3 configure -values {This is a BWidget spin box}\
.full.spinbox_demo3 setvalue first} 420x420+56+126 #996099 left_ptr {}} {label label1 {10 390 170 410} {} {Status line} {} {} sunken #000000 #d9d9d9 2 n center l left_ptr false none {} {}} {label label2 {180 390 410 410} {} {Grooved status line} {} {} groove #000098 #d9d9d9 2 f center l left_ptr false none {} {}} {label label3 {30 10 390 40} {} {     Full featured form} {} {} ridge #000000 #d988d9 4 {Times 16 bold italic} center l left_ptr false none {} {}} {button button4 {10 230 140 260} {.full.lb insert end {it's} a nice demo form} {Java style button} {} {} groove #6161b6 #d9d9d9 2 b center l left_ptr false none {} {}} {label label5 {40 50 150 70} {} {Java style label} {} {} flat #6161b6 #d9d9d9 1 b center l left_ptr false none {} {}} {entry entry6 {160 50 380 70} {} entry6 entrydemo {} groove #000000 #fefefe 2 {Courier 13} center l left_ptr false none {} {}} {listbox lb {10 130 140 220} {} listbox8 {} {} ridge #000000 #ffffc8 2 n center l left_ptr false none {} {}} {button button9 {20 270 40 290} {} 1 {} {} flat #000000 #d9d9d9 1 n center l left_ptr false none {} {}} {button button10 {50 270 70 290} {} 2 {} {} flat #000000 #d9d9d9 1 n center l left_ptr false none {} {}} {button button11 {80 270 230 290} {} {and other hidden buttons} {} {} flat #000000 #d9d9d9 1 n center l left_ptr false none {} {}} {text txt {150 130 330 220} {} text12 {} {} sunken #000000 #d4ffff 1 n center l left_ptr false none {} {}} {button button13 {150 230 330 260} {.full.txt tag configure bold -font {Helvetica 12 bold}\
.full.txt tag configure italic -font {Helvetica 12 italic}\
.full.txt tag configure large -font {Helvetica -14 bold}\
.full.txt tag configure title -font {Helvetica 12 bold italic} -justify center\
.full.txt tag configure link -font {Helvetica -12 underline} -foreground #000080\
.full.txt tag configure code -font {Courier 13}\
.full.txt tag configure warning -font {Helvetica 12 bold} -foreground #800000\
\
# That't the way help files are written\
\
.full.txt delete 1.0 end\
.full.txt insert end {Centered title} {title} "\
\
You can make different " {} "portions of text bold" {bold} " or italic " {italic} ".\
Some parts of them can be written as follows" {} "\
SELECT * FROM PHONEBOOK" {code} "\
You can also change " {} "colors for some words " {warning} "or underline them" {link} } {Old style button} {} {} raised #000000 #d9d9d9 2 n center l left_ptr false none {} {}} {checkbox checkbox14 {50 300 150 320} {} different {} {} flat #00009c #d9d9d9 1 b center l left_ptr false none {} {}} {checkbox checkbox15 {50 330 150 350} {} {fonts and} {} {} flat #cc0000 #d9d9d9 1 i center l left_ptr false none {} {}} {checkbox checkbox16 {50 360 150 380} {} colors {} {} flat #00b600 #dfb2df 1 f center l left_ptr false none {} {}} {radio radio17 {182 300 302 320} {} {red , rosu , rouge} color red flat #9c0000 #d9d9d9 1 n center l left_ptr false none {} {}} {radio radio18 {182 320 302 340} {} {green , verde , vert} color green flat #009000 #d9d9d9 1 n center l left_ptr false none {} {}} {radio radio19 {182 340 302 360} {} {blue , albastru, bleu} color blue flat #000000 #d9d9d9 1 n center l left_ptr false none {} {}} {label selcolor {186 369 321 384} {} {} color {} flat #000000 #d9d9d9 1 n center l left_ptr false none {} {}} {button button21 {330 350 410 380} {destroy .full} Exit {} {} raised #7c0000 #dfdbb8 1 b center l left_ptr false none {} {}} {combobox combobox_demo {280 90 394 110} {} combobox22 {} {} sunken #000000 #fefefe 1 n center l left_ptr true none {} {}} {spinbox spinbox_demo1 {340 130 410 150} {} spinbox23 {} {} sunken #000000 #fefefe 1 n center l left_ptr false none {} {}} {label label24 {10 100 30 120} {} {} {} {} flat #000000 #000000 1 n center l trek false none {} {}} {label label26 {30 80 50 100} {} {} {} {} flat #000000 #000000 1 n center l gobbler false none {} {}} {label label27 {50 100 70 120} {} {} {} {} flat #000000 #000000 1 n center l sizing false none {} {}} {label label28 {70 80 90 100} {} {} {} {} flat #000000 #000000 1 n center l bottom_side false none {} {}} {label label29 {90 100 110 120} {} {} {} {} flat #000000 #000000 1 n center l sb_left_arrow false none {} {}} {label label30 {110 80 130 100} {} {} {} {} flat #000000 #000000 1 n center l coffee_mug false none {} {}} {label label31 {110 100 130 120} {} {} {} {} flat #ffffff #ffffff 1 n center l double_arrow false none {} {}} {label label32 {90 80 110 100} {} {} {} {} flat #ffffff #ffffff 1 n center l question_arrow false none {} {}} {label label33 {70 100 90 120} {} {} {} {} flat #ffffff #ffffff 1 n center l shuttle false none {} {}} {label label34 {50 80 70 100} {} {} {} {} flat #ffffff #ffffff 1 n center l iron_cross false none {} {}} {label label35 {30 100 50 120} {} {} {} {} flat #ffffff #ffffff 0 n center l spraycan false none {} {}} {label label36 {10 80 30 100} {} {} {} {} flat #ffffff #ffffff 1 n center l gumby false none {} {}} {label label37 {180 80 250 120} {} {different\
mouse\
cursors} {} {} flat #000000 #f8fe08 1 n center c left_ptr false none {} {}} {spinbox spinbox_demo2 {340 160 410 180} {} spinbox38 {} {} sunken #000000 #fefefe 1 n center l left_ptr false none {} {}} {spinbox spinbox_demo3 {340 190 410 210} {} spinbox39 {} {} sunken #000000 #fefefe 1 n center l left_ptr false none {} {}} {label label40 {135 96 180 99} {} {} {} {} flat #000000 #fefe00 1 n center l left_ptr false none {} {}} {label label42 {340 230 410 340} {} {a\
multi\
line\
label\
aligned\
on\
the\
right} {} {} flat #000000 #ffff00 1 n e r left_ptr false none {} {}}
Working with comboboxes - NEW	{comb 14 {namespace eval DataControl(.comb.qry_cities) {\
\	# you can either set the SQL manually, or use the name of a stored query\
\	setSQL "show the cities"\
\	open\
\	updateDataSet\
\	fill .comb.combobox_cities name\
}\
\
namespace eval DataControl(.comb.qry_pb) {\
\	open\
\	updateDataSet\
\	fill .comb.combobox_names name\
}\
\
\
# these are bindings for fast lookups on the city combobox\
# keyboard entry will be limited to only those items in the list\
# note the placement of the 'bind' word, this is a BWidget thing\
# standard Tk widgets would put the 'bind' at the beginning instead\
# note also that the combobox must be set Editable=true\
\
# these two variables will hold the keystrokes and the last found index\
variable cb\
variable fnd\
\
# clear out the old keystrokes upon receiving focus\
.comb.combobox_cities bind <FocusIn> {\
\	set cb ""\
}\
\
# clear out the old keystrokes upon receiving a mouse click\
.comb.combobox_cities bind <Button-1> {\
\	set cb ""\
}\
\
# bind to the actual key press\
.comb.combobox_cities bind <KeyRelease> {\
\	append cb %A\
\	set curr $cb\
\	append curr "*"\
\	.comb.combobox_cities setvalue last\
\	set pos [.comb.combobox_cities getvalue]\
\	while {$pos>=0} {\
\	\	.comb.combobox_cities setvalue @$pos\
\	\	set txt [.comb.combobox_cities cget -text]\
\	\	if {[string match -nocase $curr $txt]} {\
\	\	\	set fnd [.comb.combobox_cities getvalue]\
\	\	\	break\
\	\	}\
\	\	incr pos -1\
\	}\
\	.comb.combobox_cities setvalue @$fnd\
}\
\
# this binding isn't necessary, but allows for the lookup\
# to fire the command as if it were selected with the mouse\
.comb.combobox_cities bind <Key-Return> {\
\	Scripts::execute "combobox demo city update"\
}} 375x262+129+209 #999999 left_ptr {DataSet(.comb.qry_pb,phone_nr) DataSet(.comb.qry_pb,city) DataSet(.comb.qry_pb,company) DataSet(.comb.qry_pb,continent) DataSet(.comb.qry_cities,name) DataSet(.comb.qry_pb,name)}} {combobox combobox_cities {20 70 130 90} {Scripts::execute "combobox demo city update"} combobox1 selected_city {} groove #000000 #fefefe 2 f center l left_ptr true none {} {}} {query qry_cities {20 10 40 30} {show the cities} query3 {} {} flat {} {} 1 n center l left_ptr false none {} {}} {query qry_pb {340 10 360 30} {SELECT * FROM phonebook WHERE company='f'} query5 {} {} flat {} {} 1 n center l left_ptr false none {} {}} {combobox combobox_names {180 70 360 90} {DataControl(.comb.qry_pb)::moveTo [.comb.combobox_names getvalue]\
DataControl(.comb.qry_pb)::updateDataSet} combobox6 DataSet(.comb.qry_pb,name) {} sunken #000000 #fefefe 1 n center l left_ptr false none {} {}} {entry entry7 {180 210 360 230} {} entry7 DataSet(.comb.qry_pb,phone_nr) {} sunken #000000 #fefefe 1 n center l left_ptr false none {} {}} {label label9 {20 100 130 250} {} {This combobox has\
fast lookups enabled\
from the Form Startup\
script.\
\
Try typing the first\
letter of a city\
in the entry part.\
\
Hit enter to commit and\
update the name box.} {} {} flat #000000 #d9d9d9 1 n n l left_ptr false none {} {}} {label label10 {20 40 130 60} {} city {} {} flat #ffffff #000000 1 {helvetica 12 bold roman} center l left_ptr false none {} {}} {label label11 {180 40 360 60} {} name {} {} flat #ffffff #000000 1 {helvetica 12 bold roman} center l left_ptr false none {} {}} {label label12 {180 180 360 200} {} phone {} {} flat #ffffff #000000 1 {helvetica 12 bold roman} center l left_ptr false none {} {}} {label label14 {180 100 360 170} {} {When you pick a city, this \
combobox will be limited to\
those people in that city.\
\
Below will be their phone #.} {} {} flat #000000 #d9d9d9 1 n n l left_ptr false none {} {}}
\.
--
-- Data for TOC Entry ID 18 (OID 7466832)
--
-- Name: pga_scripts Type: TABLE DATA Owner: tester
--


COPY "pga_scripts" FROM stdin;
How are forms keeped inside ?	Tables::open pga_forms\
\
\
\

Opening a table with filters	Tables::open phonebook "name ~* 'e'" "name desc"\
\
\

Autoexec	Mainlib::tab_click Forms\
Forms::open {Full featured form}\
\
\

combobox demo city update	namespace eval ::DataControl(.comb.qry_pb) {\
\	clearDataSet\
\	setSQL "get phonebook for city"\
\	setVars "{select_city $selected_city}"\
\	open\
\	updateDataSet\
\	fill .comb.combobox_names name\
}\
\

\.
--
-- Data for TOC Entry ID 19 (OID 7466837)
--
-- Name: pga_reports Type: TABLE DATA Owner: tester
--


COPY "pga_reports" FROM stdin;
My phone book	phonebook	set PgAcVar(report,tablename) "phonebook" ; set PgAcVar(report,extrasql) "" ; set PgAcVar(report,rw) 508 ; set PgAcVar(report,rh) 345 ; set PgAcVar(report,pw) 508 ; set PgAcVar(report,ph) 345 ; set PgAcVar(report,y_rpthdr) 21 ; set PgAcVar(report,y_pghdr) 47 ; set PgAcVar(report,y_detail) 66 ; set PgAcVar(report,y_pgfoo) 96 ; set PgAcVar(report,y_rptfoo) 126 ; .pgaw:ReportBuilder:draft.c create text 10 35 -font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* -anchor nw -text {name} -tags {t_l mov ro} ; .pgaw:ReportBuilder:draft.c create text 10 52 -font -Adobe-Helvetica-Medium-R-Normal-*-*-120-*-*-*-*-* -anchor nw -text {name} -tags {f-name t_f rg_detail mov ro} ; .pgaw:ReportBuilder:draft.c create text 141 36 -font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* -anchor nw -text {city} -tags {t_l mov ro} ; .pgaw:ReportBuilder:draft.c create text 141 51 -font -Adobe-Helvetica-Medium-R-Normal-*-*-120-*-*-*-*-* -anchor nw -text {city} -tags {f-city t_f rg_detail mov ro} ; .pgaw:ReportBuilder:draft.c create text 231 35 -font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* -anchor nw -text {phone_nr} -tags {t_l mov ro} ; .pgaw:ReportBuilder:draft.c create text 231 51 -font -Adobe-Helvetica-Medium-R-Normal-*-*-120-*-*-*-*-* -anchor nw -text {phone_nr} -tags {f-phone_nr t_f rg_detail mov ro}	\N	\N
\.
--
-- Data for TOC Entry ID 20 (OID 7466842)
--
-- Name: phonebook Type: TABLE DATA Owner: tester
--


COPY "phonebook" FROM stdin;
FIAT	623463445		t	europe
Gelu Voican	01-32234	Bucuresti	f	europe
Radu Vasile	01-5523423	Bucuresti	f	europe
MUGADUMBU SRL	+92 534662634	Cairo	t	africa
Jimmy Page	66323452		f	europe
IBM	623346234	\N	t	usa
John Doe	+44 35 2993825	Washington	f	usa
Bill Clinton	+44 35 9283845	New York	f	usa
Monica Levintchi	+44 38 5234526	Dallas	f	usa
Bill Gates	+42 64 4523454	Los Angeles	f	usa
COMPAQ	623462345	\N	t	usa
SUN	784563253	\N	t	usa
DIGITAL	922644516	\N	t	usa
Frank Zappa	6734567	Montreal	f	usa
Constantin Teodorescu	+40 39 611820	Braila	f	europe
Ngbendu Wazabanga	34577345		f	africa
Mugabe Kandalam	7635745		f	africa
Vasile Lupu	52345623	Bucuresti	f	europe
Gica Farafrica	+42 64 4523454	Los Angeles	f	usa
Victor Ciorbea	634567	Bucuresti	f	europe
\.
--
-- Data for TOC Entry ID 21 (OID 7466844)
--
-- Name: pga_layout Type: TABLE DATA Owner: tester
--


COPY "pga_layout" FROM stdin;
pga_forms	2	formname formsource	82 713
Usaisti	5	name phone_nr city company continent	150 150 150 150 150
q1	5	name phone_nr city company continent	150 150 150 150 150
view_saved_from_that_query	5	name phone_nr city company continent	150 150 150 150 150
phonebook	5	name phone_nr city company continent	150 105 80 66 104
Query that can be saved as view	5	name phone_nr city company continent	150 150 150 150 150
pg_database	4	datname datdba encoding datpath	150 150 150 150
pg_language	5	lanname lanispl lanpltrusted lanplcallfoid lancompiler	150 150 150 150 150
cities	3	id name prefix	60 150 150
	3	id name prefix	125 150 150
	3	id name prefix	150 150 150
	3	id name prefix	150 150 150
	3	id name prefix	150 150 150
show the cities	1	name	150
\.
--
-- Data for TOC Entry ID 22 (OID 7466849)
--
-- Name: pga_schema Type: TABLE DATA Owner: tester
--


COPY "pga_schema" FROM stdin;
Simple schema	cities 10 10 phonebook 201.0 84.0	{cities name phonebook city}
\.
--
-- Data for TOC Entry ID 23 (OID 7466854)
--
-- Name: cities Type: TABLE DATA Owner: tester
--


COPY "cities" FROM stdin;
3	Braila	4039
4	Galati	4036
5	Dallas	5362
6	Cairo	9352
1	Bucuresti	4013
7	Montreal	5325
\.
--
-- TOC Entry ID 14 (OID 7466909)
--
-- Name: "cities_id_key" Type: INDEX Owner: tester
--

CREATE UNIQUE INDEX cities_id_key ON cities USING btree (id);

--
-- TOC Entry ID 3 (OID 7466820)
--
-- Name: cities_id_seq Type: SEQUENCE SET Owner: tester
--

SELECT setval ('"cities_id_seq"', 7, true);

