#! /bin/sh
# \
exec tclsh "$0" ${1+"$@"}

if {($argc != 2) && ($argc != 4)} {
    puts "\nWrong args: $argv0 <pgaccess dir> <root destination dir> ?-starpack /path/to/tclkit?\n"
    puts "For example: $argv0 /path/to/pgaccess /tmp\n"
    exit
}

set dir(src) [lindex $argv 0]
if {[string equal "." $dir(src)]} {set dir(src) [pwd]}
set dir(root) [lindex $argv 1]
set dir(dest) [file join $dir(root) pgaccess.vfs]
set file(star) pgaccess.kit
set file(main) [file join $dir(dest) main.tcl]

set starkit ""
if {($argc == 4) && ([string match "-star*" [lindex $argv 2]])} {
    puts "STARPACK"
    set starkit "-runtime [lindex $argv 3]"
    if {[string match "*win*" [lindex $argv 3]]} {
        set file(star) pgaccess.exe
    } else {
        set file(star) pgaccess.bin
    }
} else {
    puts "STARKIT"
}

if {[file exists $dir(dest)]} {

    puts "Deleting existing vfs directory ($dir(dest)) ..."
    if {[catch {file delete -force $dir(dest)} err]} {
        puts "Error while deleting $dir(dest)...make sure you have permissions"
        puts "Error msg: $err"
        exit
    }
}

puts "Making vfs directory..."
if {[catch {file mkdir $dir(dest)} err]} {
        puts "Error while making dir $dir(dest)..."
        puts "Error msg: $err"
        exit
}

puts "Copying files from src dir ($dir(src)) to vfs directory ($dir(dest)) ..."
foreach F [glob -dir $dir(src) *] {
    if {![string match "*win32" $F] && ![string match "*osx" $F]} {
        puts "FILE: $F"
        if {[catch {file copy $F $dir(dest)} err]} {
            puts "Error while copying files from $dir(src) to $dir(dest)..."
            puts "Error msg: $err"
            exit
        }
    }
}

set contents {package require starkit
package require Tk
starkit::startup
#package provide tcllib
set env(PGACCESS_HOME) [file join $starkit::topdir]
starkit::autoextend [file join $env(PGACCESS_HOME) lib]
starkit::autoextend [file join $env(PGACCESS_HOME) lib help]
starkit::autoextend [file join $env(PGACCESS_HOME) lib widgets]
starkit::autoextend [file join $env(PGACCESS_HOME) extra]
source [file join $starkit::topdir pgaccess.tcl]}

puts "Writing main.tcl ... "
set fid [open $file(main) w]
puts $fid $contents
close $fid

puts "Creating $file(star) ... "
set PWD [pwd]
cd $dir(root)
puts [eval exec sdx.kit wrap $file(star) $starkit]
cd $PWD
