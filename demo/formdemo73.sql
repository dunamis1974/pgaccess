--
-- PostgreSQL database dump
--

\connect - tester

SET search_path = public, pg_catalog;

--
-- TOC entry 2 (OID 17193)
-- Name: cities_id_seq; Type: SEQUENCE; Schema: public; Owner: tester
--

CREATE SEQUENCE cities_id_seq
    START 1
    INCREMENT 1
    MAXVALUE 2147483647
    MINVALUE 1
    CACHE 1;


--
-- TOC entry 4 (OID 17195)
-- Name: pga_queries; Type: TABLE; Schema: public; Owner: tester
--

CREATE TABLE pga_queries (
    queryname character varying(64),
    querytype character(1),
    querycommand text,
    querytables text,
    querylinks text,
    queryresults text,
    querycomments text
);


--
-- TOC entry 5 (OID 17200)
-- Name: pga_forms; Type: TABLE; Schema: public; Owner: tester
--

CREATE TABLE pga_forms (
    formname character varying(64),
    formsource text
);


--
-- TOC entry 6 (OID 17205)
-- Name: pga_scripts; Type: TABLE; Schema: public; Owner: tester
--

CREATE TABLE pga_scripts (
    scriptname character varying(64),
    scriptsource text
);


--
-- TOC entry 7 (OID 17210)
-- Name: pga_reports; Type: TABLE; Schema: public; Owner: tester
--

CREATE TABLE pga_reports (
    reportname character varying(64),
    reportsource text,
    reportbody text,
    reportprocs text,
    reportoptions text
);


--
-- TOC entry 8 (OID 17215)
-- Name: phonebook; Type: TABLE; Schema: public; Owner: tester
--

CREATE TABLE phonebook (
    name character varying(32),
    phone_nr character varying(16),
    city character varying(32),
    company boolean,
    continent character varying(16)
);


--
-- TOC entry 9 (OID 17217)
-- Name: pga_layout; Type: TABLE; Schema: public; Owner: tester
--

CREATE TABLE pga_layout (
    tablename character varying(64),
    nrcols smallint,
    colnames text,
    colwidth text
);


--
-- TOC entry 10 (OID 17222)
-- Name: pga_schema; Type: TABLE; Schema: public; Owner: tester
--

CREATE TABLE pga_schema (
    schemaname character varying(64),
    schematables text,
    schemalinks text
);


--
-- TOC entry 11 (OID 17222)
-- Name: pga_schema; Type: ACL; Schema: public; Owner: tester
--

GRANT ALL ON TABLE pga_schema TO PUBLIC;


--
-- TOC entry 12 (OID 17227)
-- Name: cities; Type: TABLE; Schema: public; Owner: tester
--

CREATE TABLE cities (
    id integer DEFAULT nextval('cities_id_seq'::text) NOT NULL,
    name character varying(32) NOT NULL,
    prefix character varying(16) NOT NULL
);


--
-- TOC entry 13 (OID 17227)
-- Name: cities; Type: ACL; Schema: public; Owner: tester
--

REVOKE ALL ON TABLE cities FROM PUBLIC;


--
-- TOC entry 15 (OID 17230)
-- Name: getcityprefix (integer); Type: FUNCTION; Schema: public; Owner: tester
--

CREATE FUNCTION getcityprefix (integer) RETURNS character varying
    AS 'select prefix from cities where id = $1 '
    LANGUAGE sql;


--
-- Data for TOC entry 16 (OID 17195)
-- Name: pga_queries; Type: TABLE DATA; Schema: public; Owner: tester
--

COPY pga_queries (queryname, querytype, querycommand, querytables, querylinks, queryresults, querycomments) FROM stdin;
Query that can be saved as view	S	select * from phonebook where continent='usa'    	\N	\N	\N	\N
show the cities	S	select t0."name" from "cities" t0    	cities 10 10 t0		name t0 unsorted {} Yes	\n
get phonebook for city	S	SELECT * FROM phonebook WHERE city='$select_city' 				\n\n\n
\.


--
-- Data for TOC entry 17 (OID 17200)
-- Name: pga_forms; Type: TABLE DATA; Schema: public; Owner: tester
--

COPY pga_forms (formname, formsource) FROM stdin;
Working with Tables namespace	f3 13 {3 4 5 6 7 9 10 11 12 13} 377x263+59+127 {radio usa {36 24 138 36} {} USA selcont} {radio europe {36 45 141 60} {} Europe selcont} {radio africa {36 66 147 81} {} Africa selcont} {label label6 {9 99 339 114} {} {Select one of the above continents and press} {}} {button button7 {270 93 354 117} {Tables::open phonebook "continent='$selcont'" $selorder} {Show them} {}} {button button9 {66 189 312 213} {Tables::design phonebook} {Show me the phonebook table structure} {}} {button button10 {141 228 240 252} {destroy .f3} {Close the form} {}} {button button11 {93 141 282 165} {Tables::open phonebook "company=true"} {Show me only the companies} {}} {radio name {183 24 261 36} {} {Order by name} selorder} {radio phone_nr {183 45 267 57} {} {Order by phone number} selorder}
The simplest form	mf 5 {FS {set thename {}}} 306x136+82+146 {label label {42 45 99 60} {} Name {} label flat #000000 #d9d9d9 1 {Helvetica 12 bold italic}} {entry ename {120 42 219 63} {} entry2 thename ename sunken #000000 #fefefe 1 n} {button button3 {6 96 108 129} {set thename Teo} {Set the name} {} button3 raised #000000 #d9d9d9 1 n} {button button4 {192 96 300 129} {destroy .mf} {Close the form} {} button4 raised #000000 #d9d9d9 1 n} {button button5 {114 96 186 129} {set thename {}} {Clear it} {} button5 raised #000000 #d9d9d9 1 n}
A simple demo form	asdf 14 {FS {set color none}} 370x310+50+75 {label label1 {15 36 99 57} {} {Selected color} {} label1 flat #000000 #d9d9d9 1} {entry entry2 {111 36 225 54} {} entry2 color entry2 sunken #000000 #fefefe 1} {radio red {249 21 342 36} {} {Red as cherry} color red flat #900000 #d9d9d9 1} {radio green {249 45 342 60} {} {Green as a melon} color green flat #008800 #d9d9d9 1} {radio blue {249 69 342 84} {} {Blue as the sky} color blue flat #00008c #d9d9d9 1} {button button6 {45 69 198 99} {set color spooky} {Set a weird color} {} button6 ridge #0000b0 #dfbcdf 2} {label label7 {24 129 149 145} {} {The checkbox's value} {} label7 flat #000000 #d9d9d9 1} {entry entry8 {162 127 172 145} {} entry8 cbvalue entry8 sunken #000000 #fefefe 1} {checkbox checkbox9 {180 126 279 150} {} {Check me :-)} cbvalue checkbox9 flat #000000 #d9d9d9 1} {button button10 {219 273 366 303} {destroy .asdf} {Close that simple form} {} button10 raised #000000 #d9d9d9 1} {button button11 {219 237 366 267} {Forms::open "Phone book"} {Open my phone book} {} button11 raised #000000 #d9d9d9 1} {listbox lb {12 192 162 267} {} listbox12 {} lb sunken #000000 #fefefe 1} {button button13 {12 156 162 186} {.asdf.lb insert end red green blue cyan white navy black purple maroon violet} {Add some information} {} button13 raised #000000 #d9d9d9 1} {button button14 {12 273 162 303} {.asdf.lb delete 0 end} {Clear this listbox} {} button14 raised #000000 #d9d9d9 1}
Working with listboxes	f2 5 {FS {set thestudent ""}} 257x263+139+147 {listbox lb {6 6 246 186} {} listbox1 {} lb sunken #000000 #ffffd4 1} {button button2 {9 234 124 258} {# Populate the listbox with some data\n#\n\nforeach student {John Bill Doe Gigi} {\n\t.f2.lb insert end $student\n}\n\n\n\n# Binding the event left button release to the\n# list box\n\nbind .f2.lb <ButtonRelease-1> {\n\tset idsel [.f2.lb curselection]\n\tif {$idsel!=""} {\n\t\tset thestudent [.f2.lb get $idsel]\n\t}\n}\n\n# Cleaning the variable thestudent\n\nset thestudent {}} {Show students} {} button2 groove #000000 #d9d9d9 2} {button button3 {132 234 247 258} {destroy .f2} {Close the form} {} button3 groove #000000 #d9d9d9 1} {label label4 {9 213 119 228} {} {You have selected} {} label4 flat #000000 #d9d9d9 1} {label label5 {129 213 219 228} {} {} thestudent label5 flat #00009a #d9d9d9 1}
Invoices	inv 0 {FS {frame .inv.f\nplace .inv.f -x 5 -y 100 -width 500 -height 300\nset wn [Tables::getNewWindowName]\nTables::createWindow .inv.f\nset PgAcVar(mw,.inv.f,updatable) 0\nset PgAcVar(mw,.inv.f,layout_found) 0\nset PgAcVar(mw,.inv.f,layout_name) ""\nTables::selectRecords .inv.f "select * from cities"\n}} 631x439+87+84
Phone book	{pb 28 {} 470x320+177+446 #999999 left_ptr} {label label1 {30 10 70 30} {} Name {} label1 flat #000000 #d9d9d9 1 n center l left_ptr} {entry name_entry {90 10 230 30} {} entry2 DataSet(.pb.qs,name) name_entry sunken #000000 #fefefe 1 n center l left_ptr} {label label3 {30 40 70 60} {} Phone {} label3 flat #000000 #d9d9d9 1 n center l left_ptr} {entry entry4 {90 40 200 60} {} entry4 DataSet(.pb.qs,phone_nr) entry4 sunken #000000 #fefefe 1 n center l left_ptr} {label label5 {30 70 70 90} {} City {} label5 flat #000000 #d9d9d9 1 n center l left_ptr} {entry entry6 {90 70 200 90} {} entry6 DataSet(.pb.qs,city) entry6 sunken #000000 #fefefe 1 n center l left_ptr} {query qs {3 6 33 33} {} query7 {} qs flat {} {} 1 n center l left_ptr} {button button8 {180 170 260 210} {namespace eval DataControl(.pb.qs) {\n\tsetSQL "select oid,* from phonebook where name ~* '$what' order by name"\n\topen\n\tset nrecs [getRowCount]\n\tupdateDataSet\n\tfill .pb.allnames name\n\tbind .pb.allnames <ButtonRelease-1> {\n\t   set ancr [.pb.allnames curselection]\n\t   if {$ancr!=""} {\n\t\tDataControl(.pb.qs)::moveTo $ancr\n\t\tDataControl(.pb.qs)::updateDataSet\n\t   }\n\t}\n}} {Start search} {} button8 raised #000000 #d9d9d9 1 n center l left_ptr} {button button9 {390 280 460 310} {DataControl(.pb.qs)::close\nDataControl(.pb.qs)::clearDataSet\nset nrecs {}\nset what {}\ndestroy .pb\n} Exit {} button9 raised #000000 #d9d9d9 2 n center l left_ptr} {button button10 {300 240 320 260} {namespace eval DataControl(.pb.qs) {\n\tmoveFirst\n\tupdateDataSet\n}\n} |< {} button10 ridge #000092 #d9d9d9 2 n center l left_ptr} {button button11 {330 240 350 260} {namespace eval DataControl(.pb.qs) {\n\tmovePrevious\n\tupdateDataSet\n}\n} << {} button11 ridge #000000 #d9d9d9 2 n center l left_ptr} {button button12 {350 240 370 260} {namespace eval DataControl(.pb.qs) {\n\tmoveNext\n\tupdateDataSet\n}} >> {} button12 ridge #000000 #d9d9d9 2 n center l left_ptr} {button button13 {380 240 400 260} {namespace eval DataControl(.pb.qs) {\n\tmoveLast\n\tupdateDataSet\n}\n} >| {} button13 ridge #000088 #d9d9d9 2 n center l left_ptr} {checkbox checkbox14 {40 100 140 120} {} {Is it a company ?} DataSet(.pb.qs,company) checkbox14 flat #000000 #d9d9d9 1 n center l left_ptr} {radio usa {20 130 100 150} {} U.S.A. DataSet(.pb.qs,continent) usa flat #000000 #d9d9d9 1 n center l left_ptr} {radio europe {90 130 170 150} {} Europe DataSet(.pb.qs,continent) europe flat #000000 #d9d9d9 1 n center l left_ptr} {radio africa {170 130 250 150} {} Africa DataSet(.pb.qs,continent) africa flat #000000 #d9d9d9 1 n center l left_ptr} {entry entry18 {130 180 170 200} {} entry18 what entry18 sunken #000000 #fefefe 1 n center l left_ptr} {label label19 {110 220 190 240} {} {records found} {} label19 flat #000000 #d9d9d9 1 n center l left_ptr} {label label20 {90 220 110 240} {} { } nrecs label20 flat #000000 #d9d9d9 1 n center l left_ptr} {label label21 {0 250 30 270} {} OID= {} label21 flat #000000 #d9d9d9 1 n center l left_ptr} {label label22 {39 252 87 267} {} { } pbqs(oid) label22 flat #000000 #d9d9d9 1 n center l left_ptr} {button button23 {10 280 80 310} {set oid {}\ncatch {set oid $DataSet(.pb.qs,oid)}\nif {[string trim $oid]!=""} {\n   sql_exec noquiet "update phonebook set name='$DataSet(.pb.qs,name)', phone_nr='$DataSet(.pb.qs,phone_nr)',city='$DataSet(.pb.qs,city)',company='$DataSet(.pb.qs,company)',continent='$DataSet(.pb.qs,continent)' where oid=$oid"\n} else {\n  tk_messageBox -title Error -message "No record is displayed!"\n}\n\n} Update {} button23 raised #000000 #d9d9d9 1 n center l left_ptr} {button button24 {210 280 280 310} {set thisname $DataSet(.pb.qs,name)\nif {[string trim $thisname] != ""} {\n\tsql_exec noquiet "insert into phonebook values (\n\t\t'$DataSet(.pb.qs,name)',\n\t\t'$DataSet(.pb.qs,phone_nr)',\n\t\t'$DataSet(.pb.qs,city)',\n\t\t'$DataSet(.pb.qs,company)',\n\t\t'$DataSet(.pb.qs,continent)'\n\t)"\n\ttk_messageBox -title Information -message "A new record has been added!"\n} else {\n\ttk_messageBox -title Error -message "This one doesn't have a name?"\n}\n\n} {Add record} {} button24 raised #000000 #d9d9d9 1 n center l left_ptr} {button button25 {140 280 200 310} {DataControl(.pb.qs)::clearDataSet\n# clearcontrols stillinitialise\n# incorectly booleans controls to {}\n# so I force it to 'f' (false)\nset DataSet(.pb.qs,company) f\nfocus .pb.name_entry} {Clear all} {} button25 raised #000000 #d9d9d9 1 n center l left_ptr} {listbox allnames {270 10 460 230} {} listbox26 {} allnames sunken #000000 #fefefe 1 n center l left_ptr} {label label27 {30 250 90 270} {} {} DataSet(.pb.qs,oid) label27 flat #000000 #d9d9d9 1 n center l left_ptr} {label label28 {0 180 130 200} {} {Find name containing} {} {} flat #000000 #d9d9d9 1 n center l left_ptr}
Full featured form	{full 23 {set entrydemo {nice}\nset color {no color selected}} 420x420+50+100 #999999 left_ptr} {label label1 {10 390 170 410} {} {Status line} {} {} sunken #000000 #d9d9d9 2 n center l left_ptr false} {label label2 {180 390 410 410} {} {Grooved status line} {} {} groove #000098 #d9d9d9 2 f center l left_ptr false} {label label3 {80 10 340 30} {} {     Full featured form} {} {} ridge #000000 #d9d9d9 4 {Times 16 bold italic} center l left_ptr false} {button button4 {10 210 140 240} {.full.lb insert end {it's} a nice demo form} {Java style button} {} {} groove #6161b6 #d9d9d9 2 b center l left_ptr false} {label label5 {30 40 140 60} {} {Java style label} {} {} flat #6161b6 #d9d9d9 1 b center l left_ptr false} {entry entry6 {150 40 390 60} {} entry6 entrydemo {} groove #000000 #fefefe 2 {Courier 13} center l left_ptr false} {listbox lb {10 70 140 200} {} listbox8 {} {} ridge #000000 #ffffc8 2 n center l left_ptr false} {button button9 {20 260 40 280} {} 1 {} {} flat #000000 #d9d9d9 1 n center l left_ptr false} {button button10 {50 260 70 280} {} 2 {} {} flat #000000 #d9d9d9 1 n center l left_ptr false} {button button11 {80 260 230 280} {} {and other hidden buttons} {} {} flat #000000 #d9d9d9 1 n center l left_ptr false} {text txt {150 69 270 200} {} text12 {} {} sunken #000000 #d4ffff 1 n center l left_ptr false} {button button13 {150 210 410 240} {.full.txt tag configure bold -font {Helvetica 12 bold}\n.full.txt tag configure italic -font {Helvetica 12 italic}\n.full.txt tag configure large -font {Helvetica -14 bold}\n.full.txt tag configure title -font {Helvetica 12 bold italic} -justify center\n.full.txt tag configure link -font {Helvetica -12 underline} -foreground #000080\n.full.txt tag configure code -font {Courier 13}\n.full.txt tag configure warning -font {Helvetica 12 bold} -foreground #800000\n\n# That't the way help files are written\n\n.full.txt delete 1.0 end\n.full.txt insert end {Centered title} {title} "\n\nYou can make different " {} "portions of text bold" {bold} " or italic " {italic} ".\nSome parts of them can be written as follows" {} "\nSELECT * FROM PHONEBOOK" {code} "\nYou can also change " {} "colors for some words " {warning} "or underline them" {link} } {Old style button} {} {} raised #000000 #d9d9d9 2 n center l left_ptr false} {checkbox checkbox14 {48 297 148 317} {} different {} {} flat #00009c #d9d9d9 1 b center l left_ptr false} {checkbox checkbox15 {48 321 148 341} {} {fonts and} {} {} flat #cc0000 #d9d9d9 1 i center l left_ptr false} {checkbox checkbox16 {48 345 148 365} {} colors {} {} flat #00b600 #dfb2df 1 f center l left_ptr false} {radio radio17 {200 300 320 320} {} {red , rosu , rouge} color red flat #9c0000 #d9d9d9 1 n center l left_ptr false} {radio radio18 {200 320 320 340} {} {green , verde , vert} color green flat #009000 #d9d9d9 1 n center l left_ptr false} {radio radio19 {200 340 320 360} {} {blue , albastru, bleu} color blue flat #000000 #d9d9d9 1 n center l left_ptr false} {label selcolor {210 369 345 384} {} {} color {} flat #000000 #d9d9d9 1 n center l left_ptr false} {button button21 {330 260 410 290} {destroy .full} Exit {} {} raised #7c0000 #dfdbb8 1 b center l left_ptr false} {combobox combobox22 {280 70 410 90} {} combobox22 {} {} sunken #000000 #fefefe 1 n center l left_ptr true} {spinbox spinbox23 {280 110 410 130} {} spinbox23 {} {} sunken #000000 #fefefe 1 n center l left_ptr false}
Working with comboboxes - NEW	{comb 8 {namespace eval DataControl(.comb.qry_cities) {\n\t# you can either set the SQL manually, or use the name of a stored query\n\tsetSQL "show the cities"\n\topen\n\tupdateDataSet\n\tfill .comb.combobox_cities name\n}\n\nnamespace eval DataControl(.comb.qry_pb) {\n\topen\n\tupdateDataSet\n\tfill .comb.combobox_names name\n}} 375x315+105+105 #999999 left_ptr} {combobox combobox_cities {20 40 130 60} {namespace eval DataControl(.comb.qry_pb) {\n\tclearDataSet\n\tsetSQL "get phonebook for city"\n\tsetVars "{select_city $selected_city}"\n\topen\n\tupdateDataSet\n\tfill .comb.combobox_names name\n}} combobox1 selected_city {} groove #000000 #fefefe 2 f center l left_ptr false none {} {}} {query qry_cities {20 10 40 30} {show the cities} query3 {} {} flat {} {} 1 n center l left_ptr false none {} {}} {query qry_pb {180 10 200 30} {SELECT * FROM phonebook} query5 {} {} flat {} {} 1 n center l left_ptr false none {} {}} {combobox combobox_names {180 40 360 60} {DataControl(.comb.qry_pb)::moveTo [.comb.combobox_names getvalue]\nDataControl(.comb.qry_pb)::updateDataSet} combobox6 DataSet(.comb.qry_pb,name) {} sunken #000000 #fefefe 1 n center l left_ptr false none {} {}} {entry entry7 {20 230 170 250} {} entry7 DataSet(.comb.qry_pb,phone_nr) {} sunken #000000 #fefefe 1 n center l left_ptr false none {} {}} {entry entry8 {210 230 350 250} {} entry8 DataSet(.comb.qry_pb,company) {} sunken #000000 #fefefe 1 n center l left_ptr false none {} {}}
\.


--
-- Data for TOC entry 18 (OID 17205)
-- Name: pga_scripts; Type: TABLE DATA; Schema: public; Owner: tester
--

COPY pga_scripts (scriptname, scriptsource) FROM stdin;
How are forms keeped inside ?	Tables::open pga_forms\n\n\n\n
Opening a table with filters	Tables::open phonebook "name ~* 'e'" "name desc"\n\n\n
Autoexec	Mainlib::tab_click Forms\nForms::open {Full featured form}\n\n\n
\.


--
-- Data for TOC entry 19 (OID 17210)
-- Name: pga_reports; Type: TABLE DATA; Schema: public; Owner: tester
--

COPY pga_reports (reportname, reportsource, reportbody, reportprocs, reportoptions) FROM stdin;
My phone book	phonebook	set PgAcVar(report,tablename) "phonebook" ; set PgAcVar(report,extrasql) "" ; set PgAcVar(report,rw) 508 ; set PgAcVar(report,rh) 345 ; set PgAcVar(report,pw) 508 ; set PgAcVar(report,ph) 345 ; set PgAcVar(report,y_rpthdr) 21 ; set PgAcVar(report,y_pghdr) 47 ; set PgAcVar(report,y_detail) 66 ; set PgAcVar(report,y_pgfoo) 96 ; set PgAcVar(report,y_rptfoo) 126 ; .pgaw:ReportBuilder:draft.c create text 10 35 -font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* -anchor nw -text {name} -tags {t_l mov ro} ; .pgaw:ReportBuilder:draft.c create text 10 52 -font -Adobe-Helvetica-Medium-R-Normal-*-*-120-*-*-*-*-* -anchor nw -text {name} -tags {f-name t_f rg_detail mov ro} ; .pgaw:ReportBuilder:draft.c create text 141 36 -font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* -anchor nw -text {city} -tags {t_l mov ro} ; .pgaw:ReportBuilder:draft.c create text 141 51 -font -Adobe-Helvetica-Medium-R-Normal-*-*-120-*-*-*-*-* -anchor nw -text {city} -tags {f-city t_f rg_detail mov ro} ; .pgaw:ReportBuilder:draft.c create text 231 35 -font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* -anchor nw -text {phone_nr} -tags {t_l mov ro} ; .pgaw:ReportBuilder:draft.c create text 231 51 -font -Adobe-Helvetica-Medium-R-Normal-*-*-120-*-*-*-*-* -anchor nw -text {phone_nr} -tags {f-phone_nr t_f rg_detail mov ro}	\N	\N
\.


--
-- Data for TOC entry 20 (OID 17215)
-- Name: phonebook; Type: TABLE DATA; Schema: public; Owner: tester
--

COPY phonebook (name, phone_nr, city, company, continent) FROM stdin;
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
King George II	19005551234	Washington	f	usa
\.


--
-- Data for TOC entry 21 (OID 17217)
-- Name: pga_layout; Type: TABLE DATA; Schema: public; Owner: tester
--

COPY pga_layout (tablename, nrcols, colnames, colwidth) FROM stdin;
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
nolayoutneeded	1	name	150
show the cities	1	name	150
\.


--
-- Data for TOC entry 22 (OID 17222)
-- Name: pga_schema; Type: TABLE DATA; Schema: public; Owner: tester
--

COPY pga_schema (schemaname, schematables, schemalinks) FROM stdin;
Simple schema	cities 10 10 phonebook 201.0 84.0	{cities name phonebook city}
\.


--
-- Data for TOC entry 23 (OID 17227)
-- Name: cities; Type: TABLE DATA; Schema: public; Owner: tester
--

COPY cities (id, name, prefix) FROM stdin;
3	Braila	4039
4	Galati	4036
5	Dallas	5362
6	Cairo	9352
1	Bucuresti	4013
7	Montreal	5325
8	Washington	1900
\.


--
-- TOC entry 14 (OID 17283)
-- Name: cities_id_key; Type: INDEX; Schema: public; Owner: tester
--

CREATE UNIQUE INDEX cities_id_key ON cities USING btree (id);


--
-- TOC entry 3 (OID 17193)
-- Name: cities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tester
--

SELECT pg_catalog.setval ('cities_id_seq', 40, true);


