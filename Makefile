# $Header: /raid/cvsroot/rt/Makefile,v 1.153.2.3 2002/01/28 05:40:16 jesse Exp $
# Request Tracker is Copyright 1996-2002 Jesse Vincent <jessebestpractical.com>
# RT is distributed under the terms of the GNU General Public License, version 2

PERL			= 	/usr/bin/perl

CONFIG_FILE_PATH	=	/opt/rt22/etc/RT_Config.pm

GETPARAM		=	$(PERL) -e'require "$(CONFIG_FILE_PATH)"; print $${$$RT::{$$ARGV[0]}};'

RT_VERSION_MAJOR	=	2
RT_VERSION_MINOR	=	1
RT_VERSION_PATCH	=	6

RT_VERSION =	$(RT_VERSION_MAJOR).$(RT_VERSION_MINOR).$(RT_VERSION_PATCH)
TAG 	   =	rt-$(RT_VERSION_MAJOR)-$(RT_VERSION_MINOR)-$(RT_VERSION_PATCH)

BRANCH			=	rt-2-1

# This is the group that all of the installed files will be chgrp'ed to.
RTGROUP			=	rt


# User which should own rt binaries.
BIN_OWNER		=	root

# User that should own all of RT's libraries, generally root.
LIBS_OWNER 		=	root

# Group that should own all of RT's libraries, generally root.
LIBS_GROUP		=	bin

WEB_USER		=	`${GETPARAM} "WebUser"`
WEB_GROUP		=	`${GETPARAM} "WebGroup"`

# {{{ Files and directories 

# DESTDIR allows you to specify that RT be installed somewhere other than
# where it will eventually reside

DESTDIR			=	


RT_PATH			=	`$(GETPARAM) "BasePath"`
RT_ETC_PATH		=	`$(GETPARAM) "EtcPath"`
RT_BIN_PATH		=	`$(GETPARAM) "BinPath"`
RT_SBIN_PATH		=	`$(GETPARAM) "SbinPath"`
RT_LIB_PATH		=	`$(GETPARAM) "LibPath"`
RT_MAN_PATH		=	`$(GETPARAM) "ManPath"`
MASON_HTML_PATH		=	`$(GETPARAM) "MasonComponentRoot"`
MASON_LOCAL_HTML_PATH	=	`$(GETPARAM) "MasonLocalComponentRoot"`
MASON_DATA_PATH		=	`$(GETPARAM) "MasonDataDir"`
MASON_SESSION_PATH	=	`$(GETPARAM) "MasonSessionDir"`
RT_LOG_PATH             =       `$(GETPARAM) "LogDir"`

# RT_READABLE_DIR_MODE is the mode of directories that are generally meant
# to be accessable
RT_READABLE_DIR_MODE	=	0755



# The location of your rt configuration file
RT_CONFIG		=	$(RT_ETC_PATH)/RT_Config.pm

# {{{ all these define the places that RT's binaries should get installed

# RT_MODPERL_HANDLER is the mason handler script for mod_perl
RT_MODPERL_HANDLER	=	$(RT_BIN_PATH)/webmux.pl
# RT_FASTCGI_HANDLER is the mason handler script for FastCGI
RT_FASTCGI_HANDLER	=	$(RT_BIN_PATH)/mason_handler.fcgi
# RT's CLI
RT_CLI_BIN		=	$(RT_BIN_PATH)/rt
# RT's admin CLI
RT_CLI_ADMIN_BIN	=	$(RT_BIN_PATH)/rtadmin
# RT's mail gateway
RT_MAILGATE_BIN		=	$(RT_BIN_PATH)/rt-mailgate

# }}}

SETGID_BINARIES	 	= 	$(DESTDIR)/$(RT_MAILGATE_BIN) \
				$(DESTDIR)/$(RT_FASTCGI_HANDLER) \
				$(DESTDIR)/$(RT_CLI_BIN) \
				$(DESTDIR)/$(RT_CLI_ADMIN_BIN)

BINARIES		=	$(DESTDIR)/$(RT_MODPERL_HANDLER) \
				$(SETGID_BINARIES)
SYSTEM_BINARIES		=	$(DESTDIR)/$(RT_SBIN_PATH)/


# }}}

# {{{ Database setup

#
# DB_TYPE defines what sort of database RT trys to talk to
# "mysql" is known to work.
# "Pg" is known to work
# "Oracle" is in the early stages of working.

DB_TYPE			=	`${GETPARAM} DatabaseType`

# Set DBA to the name of a unix account with the proper permissions and 
# environment to run your commandline SQL sbin

# Set DB_DBA to the name of a DB user with permission to create new databases 
# Set DB_DBA_PASSWORD to that user's password (if you don't, you'll be prompted
# later)

# For mysql, you probably want 'root'
# For Pg, you probably want 'postgres' 
# For oracle, you want 'system'

DB_DBA			=	`${GETPARAM} DatabaseDBA`
DB_DBA_PASSWORD		=	`${GETPARAM} DatabaseDBAPassword`
DB_HOST			=	`${GETPARAM} DatabaseHost`

# If you're not running your database server on its default port, 
# specifiy the port the database server is running on below.
# It's generally safe to leave this blank 

DB_PORT			=	`${GETPARAM} DatabasePort`

#
# Set this to the canonical name of the interface RT will be talking to the 
# database on.  If you said that the RT_DB_HOST above was "localhost," this 
# should be too. This value will be used to grant rt access to the database.
# If you want to access the RT database from multiple hosts, you'll need
# to grant those database rights by hand.
#

DB_RT_HOST		=	`${GETPARAM} DatabaseRTHost`

# set this to the name you want to give to the RT database in 
# your database server. For Oracle, this should be the name of your sid

DB_DATABASE		=	`${GETPARAM} DatabaseName`
DB_RT_USER		=	`${GETPARAM} DatabaseUser`
DB_RT_PASS		=	`${GETPARAM} DatabasePass`

# }}}


####################################################################
# No user servicable parts below this line.  Frob at your own risk #
####################################################################

all: default

default:
	@echo "Please read RT's readme before installing. Not doing so could"
	@echo "be dangerous."


instruct:
	@echo "Congratulations. RT has been installed. "
	@echo "You must now configure it by editing $(RT_CONFIG)."
	@echo "From here on in, you should refer to the users guide."


upgrade-instruct: 
	@echo "Congratulations. RT has been upgraded. You should now check-over"
	@echo "$(RT_CONFIG) for any necessarysite customization. Additionally,"
	@echo "you should update RT's system database objects by running "
	@echo "	   $(RT_SBIN_PATH)/insertdata <version>"
	@echo "where <version> is the version of RT you're upgrading from."


upgrade: dirs upgrade-noclobber  upgrade-instruct

upgrade-noclobber: libs-install html-install bin-install  fixperms


# {{{ dependencies
testdeps:
	$(PERL) ./sbin/testdeps -warn $(DB_TYPE)

fixdeps:
	$(PERL) ./sbin/testdeps -fix $(DB_TYPE)

#}}}

# {{{ fixperms
fixperms:
	# Make the libraries readable
	chmod -R $(RT_READABLE_DIR_MODE) $(DESTDIR)/$(RT_PATH)
	chown -R $(LIBS_OWNER) $(DESTDIR)/$(RT_LIB_PATH)
	chgrp -R $(LIBS_GROUP) $(DESTDIR)/$(RT_LIB_PATH)

	chown -R $(BIN_OWNER) $(DESTDIR)/$(RT_BIN_PATH)
	chgrp -R $(RTGROUP) $(DESTDIR)/$(RT_BIN_PATH)


	chmod $(RT_READABLE_DIR_MODE) $(DESTDIR)/$(RT_BIN_PATH)
	chmod $(RT_READABLE_DIR_MODE) $(DESTDIR)/$(RT_BIN_PATH)	

	chmod 0755 $(DESTDIR)/$(RT_ETC_PATH)
	chmod 0500 $(DESTDIR)/$(RT_ETC_PATH)/*

	#TODO: the config file should probably be able to have its
	# owner set seperately from the binaries.
	chown -R $(BIN_OWNER) $(DESTDIR)/$(RT_ETC_PATH)
	chgrp -R $(RTGROUP) $(DESTDIR)/$(RT_ETC_PATH)

	chmod 0550 $(DESTDIR)/$(RT_CONFIG)

	# Make the interfaces executable and setgid rt
	chown $(BIN_OWNER) $(SETGID_BINARIES)
	chgrp $(RTGROUP) $(SETGID_BINARIES)
	chmod 0755  $(SETGID_BINARIES)
	
	chmod g+s $(SETGID_BINARIES)

	# Make the web ui readable by all. 
	chmod -R  u+rwX,go-w,go+rX 	$(DESTDIR)/$(MASON_HTML_PATH) \
					$(DESTDIR)/$(MASON_LOCAL_HTML_PATH)
	chown -R $(LIBS_OWNER) 	$(DESTDIR)/$(MASON_HTML_PATH) \
				$(DESTDIR)/$(MASON_LOCAL_HTML_PATH)
	chgrp -R $(LIBS_GROUP) 	$(DESTDIR)/$(MASON_HTML_PATH) \
				$(DESTDIR)/$(MASON_LOCAL_HTML_PATH)

	# Make the web ui's data dir writable
	chmod 0770  	$(DESTDIR)/$(MASON_DATA_PATH) \
			$(DESTDIR)/$(MASON_SESSION_PATH)
	chown -R $(WEB_USER) 	$(DESTDIR)/$(MASON_DATA_PATH) \
				$(DESTDIR)/$(MASON_SESSION_PATH)
	chgrp -R $(WEB_GROUP) 	$(DESTDIR)/$(MASON_DATA_PATH) \
				$(DESTDIR)/$(MASON_SESSION_PATH)
# }}}

fixperms-nosetgid: fixperms
	@echo "You should never be running RT this way. it's unsafe"
	chmod -s $(SETGID_BINARIES)
	chmod 0555 $(DESTDIR)/$(RT_CONFIG)

# {{{ dirs
dirs:
	mkdir -p $(DESTDIR)/$(MASON_DATA_PATH)
	mkdir -p $(DESTDIR)/$(MASON_SESSION_PATH)
	mkdir -p $(DESTDIR)/$(MASON_HTML_PATH)
	mkdir -p $(DESTDIR)/$(MASON_LOCAL_HTML_PATH)
# }}}

install: config-install dirs files-install initialize-database fixperms

files-install: libs-install etc-install bin-install sbin-install html-install

initialize-database: createdb insert-schema database-acl insert-baseline-data

config-install:
	install -b -D -g $(RTGROUP) -o $(BIN_OWNER) etc/RT_Config.pm $(DESTDIR)/$(CONFIG_FILE_PATH)
	@echo "Installed configuration. about to install rt in  $(RT_PATH)"

test: 
	$(PERL) -Ilib lib/t/smoke.t

regression: libs-install sbin-install bin-install regression-instruct dropdb initialize-database
	(cd ./lib; $(PERL) Makefile.PL && make testifypods && $(PERL) t/regression.t)
		
regression-instruct:
	@echo "About to wipe your database for a regression test. ABORT NOW with Control-C"


# {{{ database-installation
genschema:
	$(PERL)	$(DESTDIR)/$(RT_SBIN_PATH)/initdb generate

dropdb: 
	$(PERL)	$(DESTDIR)/$(RT_SBIN_PATH)/initdb drop 

database-acl:
	$(PERL) $(DESTDIR)/$(RT_SBIN_PATH)/initdb acl

createdb: 
	$(PERL)	$(DESTDIR)/$(RT_SBIN_PATH)/initdb create 

insert-schema: etc-install
	$(PERL)	$(DESTDIR)/$(RT_SBIN_PATH)/initdb insert

insert-baseline-data:
	$(PERL)	$(DESTDIR)/$(RT_SBIN_PATH)/insertdata

# }}}

# {{{ libs-install
libs-install: 
	[ -d $(DESTDIR)/$(RT_LIB_PATH) ] || mkdir $(DESTDIR)/$(RT_LIB_PATH)
	chown -R $(LIBS_OWNER) $(DESTDIR)/$(RT_LIB_PATH)
	chgrp -R $(LIBS_GROUP) $(DESTDIR)/$(RT_LIB_PATH)
	chmod -R $(RT_READABLE_DIR_MODE) $(DESTDIR)/$(RT_LIB_PATH)
	( cd ./lib; \
	  $(PERL) Makefile.PL INSTALLSITELIB=$(DESTDIR)/$(RT_LIB_PATH) \
			      INSTALLMAN1DIR=$(DESTDIR)/$(RT_MAN_PATH)/man1 \
			      INSTALLMAN3DIR=$(DESTDIR)/$(RT_MAN_PATH)/man3 \
	    && $(MAKE) \
	    && $(PERL) -p -i -e " s'!!RT_VERSION!!'$(RT_VERSION)'g; \
	    			  s'!!RT_CONFIG!!'$(CONFIG_FILE_PATH)'g;" \
				  			blib/lib/RT.pm ; \
	    $(MAKE) install \
		   INSTALLSITEMAN1DIR=$(DESTDIR)/$(RT_MAN_PATH)/man1 \
		   INSTALLSITEMAN3DIR=$(DESTDIR)/$(RT_MAN_PATH)/man3 \
	)

libs-install-quick:
	cd ./lib; \
	$(PERL) Makefile.PL INSTALLSITELIB=$(DESTDIR)/$(RT_LIB_PATH) \
			      INSTALLMAN1DIR=none \
			      INSTALLMAN3DIR=none 
	cd ./lib; $(MAKE)
	cd ./lib; $(PERL) -p -i -e " s'!!RT_VERSION!!'$(RT_VERSION)'g; \
	    		  s'!!RT_CONFIG!!'$(CONFIG_FILE_PATH)'g;" blib/lib/RT.pm 
	
	cd ./lib ;$(MAKE) install \
			      INSTALLSITEMAN1DIR= \
			      INSTALLSITEMAN3DIR= 
	
# }}}

# {{{ html-install
html-install:
	cp -rp ./html/* $(DESTDIR)/$(MASON_HTML_PATH)
# }}}

# {{{ etc-install

etc-install:
	mkdir -p $(DESTDIR)/$(RT_ETC_PATH)
	cp -rp \
		etc/acl.* \
		etc/schema.* \
		$(DESTDIR)/$(RT_ETC_PATH)
# }}}

# {{{ sbin-install

sbin-install:
	mkdir -p $(DESTDIR)/$(RT_SBIN_PATH)
	cp -rp \
		sbin/initdb \
		sbin/testdeps \
		sbin/insertdata \
		$(DESTDIR)/$(RT_SBIN_PATH)
	$(PERL) -p -i -e " s'!!PERL!!'"$(PERL)"'g;\
				s'!!RT_LIB_PATH!!'"$(RT_LIB_PATH)"'g;"\
		$(DESTDIR)/$(RT_SBIN_PATH)/*

# }}}

# {{{ bin-install

bin-install:
	@echo "Bin path is $(RT_BIN_PATH)"
	mkdir -p $(DESTDIR)/$(RT_BIN_PATH)
	cp -rp \
		bin/rt \
		bin/rtadmin \
		bin/rt-mailgate \
		bin/enhanced-mailgate \
		bin/mason_handler.fcgi \
		bin/webmux.pl \
		bin/rt-commit-handler \
		$(DESTDIR)/$(RT_BIN_PATH)
	$(PERL) -p -i -e " s'!!PERL!!'"$(PERL)"'g;\
				s'!!RT_LIB_PATH!!'"$(RT_LIB_PATH)"'g;"\
		$(BINARIES)
# }}}

# {{{ Best Practical Build targets -- no user servicable parts inside

factory: createdb insert-schema
	cd lib; $(PERL) ../sbin/factory  $(DB_DATABASE) RT

commit:
	aegis -build ; aegis -diff ; aegis -test; aegis --development_end

integrate:
	aegis -build; aegis -dist; aegis -test ; aegis -integrate_pass

predist: commit tag-and-tar

tag-and-release-baseline:
	aegis -cp -ind Makefile -output /tmp/Makefile.tagandrelease; \
	$(MAKE) -f /tmp/Makefile.tagandrelease tag-and-release


# Running this target in a working directory is 
# WRONG WRONG WRONG.
# it will tag the current baseline with the version of RT defined 
# in the currently-being-worked-on makefile. which is wrong.
#  you want tag-and-release-baseline

tag-and-release:
	aegis --delta-name $(TAG)
	rm -rf /tmp/$(TAG)
	mkdir /tmp/$(TAG)
	cd /tmp/$(TAG); \
		aegis -cp -ind -delta $(TAG) . ;\
		chmod 600 Makefile;\
		aegis --report --project rt.$(RT_VERSION_MAJOR) \
		      --page_width 80 \
		      --page_length 9999 \
		      --change $(RT_VERSION_MINOR) --output Changelog Change_Log

	cd /tmp; tar czvf /home/ftp/pub/rt/devel/$(TAG).tar.gz $(TAG)/
	chmod 644 /home/ftp/pub/rt/devel/$(TAG).tar.gz

dist: commit predist
	rm -rf /home/ftp/pub/rt/devel/rt.tar.gz
	ln -s ./$(TAG).tar.gz /home/ftp/pub/rt/devel/rt.tar.gz

rpm:
	(cd ..; tar czvf /usr/src/redhat/SOURCES/rt.tar.gz rt)
	rpm -ba etc/rt.spec


apachectl:
	/usr/sbin/apachectl stop
	/usr/sbin/apachectl start
# }}}
