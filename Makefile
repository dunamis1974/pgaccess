#-------------------------------------------------------------------------
#
# Makefile for PG Access
#
# Portions Copyright (c) 1996-2001, PostgreSQL Global Development Group
# Portions Copyright (c) 1994, Regents of the University of California
#
#-------------------------------------------------------------------------

bindir = /usr/bin/X11
libdir = /usr/lib
wish = /usr/bin/wish

pgaccess: 
	chmod a+x pgaccess.tcl
	mkdir -p $(libdir)/pgaccess
	cp -R * $(libdir)/pgaccess
	ln -sf $(libdir)/pgaccess/pgaccess.tcl $(bindir)/pgaccess

all: pgaccess

install: pgaccess

clean:
	rm -rf $(libdir)/pgaccess
	rm -rf $(bindir)/pgaccess
