#!/bin/sh
#
# cygwin command line installer 
#
# Website: http://kde-cygwin.sf.net 
#
# Requirements:  wget bzip2 gawk sed grep uniq
# 
#   
# Copyright (c) 2003-2007 Ralf Habacker 	  <Ralf Habacker@freenet.de>
# 
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     A copy of the GNU General Public License can be found at
#     http://www.gnu.org/
# 
# Written by Ralf Habacker <Ralf Habacker@freenet.de>
#
# $Id: cygsetup,v 1.4 2007/03/23 07:35:08 habacker Exp $
#
# todo 
#  - in use replacement 
#  - deleting files from old installation 

#. `dirname $0`/cyglib.sh
#------------------------------------------------------------
# cyglib.sh is included below 
#------------------------------------------------------------

#ROOT=""
DB_ROOT="$ROOT/etc/setup"
DB="$DB_ROOT/installed.db"
CONF="$DB_ROOT/cygsetup.conf"
TAR="tar -U"

basename() { echo "${1##*/}"; }

#
# default settings 
# 
show=:
#show=echo
area="Europe"
default_mirror="file:/d" 
mirror=1
mirror_url=

get_arch()
{
  case `uname -m` in
    i[3-6]86) arch=x86 ;;
    *64) arch=x86_64 ;;
  esac
}

config_write()
{
	echo "ROOT=$root" >$CONF
	echo "DB_ROOT=$DB_ROOT" >>$CONF
	echo "CONF=$CONF" >>$CONF
	echo "arch=$arch" >>$CONF
	echo "area=\"$area\"" >>$CONF
	echo "default_mirror=\"$default_mirror\"" >>$CONF
	echo "mirror=\"$mirror\"" >>$CONF
	echo "mirror_url=\"$mirror_url\"" >>$CONF
	echo "setup_ini=$DB_ROOT/setup.ini" >>$CONF
	echo "setup_ini_loaded=$setup_ini_loaded" >>$CONF
}

config_print()
{
	echo "ROOT=$root" 
	echo "DB_ROOT=$DB_ROOT" 
	echo "CONF=$CONF"
	echo "arch=$arch"
	echo "area=\"$area\""
	echo "default_mirror='$default_mirror'"
	echo "mirror='$mirror'"
	echo "mirror_url='$mirror_url'"
	echo "setup_ini=$DB_ROOT/setup.ini"
	echo "setup_ini_loaded=$setup_ini_loaded"
}


config_read()
{
	if ! test -f "$CONF"; then  
		config_write
	else 
		. $CONF
	fi
	
	if test "x$arch" = x; then
	  get_arch
	  config_write
	fi
}
get_arch_suffix()
{
   case "${MACHINE=`uname -m`}" in
     i[3-6]86) echo x86 ;;
     x86?64 |amd64 |x64) echo x86_64 ;;
   esac
}
#
# get mirror list 
# 
get_mirror_list()
{
	if ! test -f "$DB_ROOT/mirrors.lst"; then 
		(wget -O - http://www.cygwin.com/mirrors.lst
		wget -O - http://sourceware.org/mirrors.html  |sed -n 's,.*>\([^< \t:]\+\)[: \t]*<a href="\([^"]*\)/*\">\([^<]*\)</a>.*,\2/cygwinports;\3;\1;\1,p' | sed '/rsync:/d; s,\s*,,g'
		
		) >"$DB_ROOT/mirrors.lst"
	fi
}

#
# build area list
# 
build_area_list()
{
	_all_areas=`grep -v "^#" $DB_ROOT/mirrors.lst | sed 's, ,#,g' | gawk 'BEGIN { FS=";"} { print $3; }' | sort | uniq`
	j=1
	for i in $_all_areas; do 
		all_areas="$all_areas $j~$i"
		j=`expr $j + 1` 
	done
}

#
#
# 
set_new_mirror()
{
	mirror=$*
	if ! test `echo $* | grep "^[0-9]" 2>/dev/null`; then 
		mirror_url=$*
	else 
		for i in $all_areas; do
			area_name=`echo $i | sed 's,^.*~,,g;s,#, ,g'`
			area_num=`echo $i | sed 's,~.*$,,g'`
			url=`grep "$area_name" $DB_ROOT/mirrors.lst | gawk 'BEGIN { FS=";"; i=1} { if(cur==sprintf("%d%d",mn,i) || cur==mn && i==1) print $1; i++; }' mn="$area_num" cur="$1"`
			if test -n "$url"; then 
				mirror_url=$url
			fi
		done
	fi
	echo "mirror='"$*"'"
	echo "mirror_url='"$mirror_url"'"
}

list_all_mirrors()
{
	for i in $all_areas; do
		area_name=`echo $i | sed 's,^.*~,,g;s,#, ,g'`
		area_num=`echo $i | sed 's,~.*$,,g'`
		echo $area_name
		grep "$area_name" $DB_ROOT/mirrors.lst | gawk 'BEGIN { FS=";"; i=1} { if ($4 == old) c=""; else c=$4; if(cur==sprintf("%d%d",mn,i) || cur==mn && i==1) sel=" >"; else sel="  "; printf("%s%1d%-2d  %-14s %s\n",sel,mn,i++,c,$1); old=$4;}' mn="$area_num" cur="$mirror"
		echo 
	done
}

load_setup_ini()
{
mkdir -p "$DB_ROOT/"
rm -f "$DB_ROOT/setup.ini"
for url in $mirror_url; do
	echo $url 1>&2
	# unpack archive 
	case $url in
		http:* | ftp:*)
#<<<<<<< HEAD
		cmd="(cd \"\$DB_ROOT\"; URL=\"$url/$(get_arch_suffix)\"; wget -O - \"\$URL/setup.bz2\" | bzip2 -d -c - | sed \"\\\\|/| s|^\\\\([a-z]*\\\\):\\\\s\\\\+|\\\\1: \${URL%/$(get_arch_suffix)}/|\")  || exit 1"
			$show eval "$cmd"
			$run eval "$cmd"
#			$show eval "(cd \"\$DB_ROOT\"; bzip2 -d -c -  >>setup.ini)"
#			$run eval "(cd \"\$DB_ROOT\"; bzip2 -d -c setup.bz2  >>setup.ini)"
			setup_ini_loaded=1
			;;
		file:*)
			url=`echo $url | sed 's,^file:,,g'`
			$show "(bzip2 -d -c $url/setup.bz2)  || exit 1"
			$run eval "(bzip2 -d -c $url/setup.bz2)  || exit 1"
			setup_ini_loaded=1
			;;
		/*)
			url=$url;
			$show "(bzip2 -d -c $url/setup.bz2)  || exit 1"
			$run eval "(bzip2 -d -c $url/setup.bz2)  || exit 1"
#=======
#			$show eval "(cd $DB_ROOT; wget -nd -O setup.bz2 $mirror_url/$arch/setup.bz2) || exit 1"
#			$run eval "(cd $DB_ROOT; wget -nd -O setup.bz2 $mirror_url/$arch/setup.bz2) || exit 1"
#			$show eval "(cd $DB_ROOT; bzip2 -d -c setup.bz2  >setup.ini)"
#			$run eval "(cd $DB_ROOT; bzip2 -d -c setup.bz2  >setup.ini)"
#			setup_ini_loaded=1
#			;;
#		file:*)
#			url=`echo $mirror_url | sed 's,^file:,,g'`
#			$show "(bzip2 -d -c $url/$arch/setup.bz2 >$DB_ROOT/setup.ini)  || exit 1"
#			$run eval "(bzip2 -d -c $url/$arch/setup.bz2 >$DB_ROOT/setup.ini)  || exit 1"
#			setup_ini_loaded=1
#			;;
#		/*)
#			url=$mirror_url;
#			$show "(bzip2 -d -c $url/$arch/setup.bz2 >$DB_ROOT/setup.ini)  || exit 1"
#			$run eval "(bzip2 -d -c $url/$arch/setup.bz2 >$DB_ROOT/setup.ini)  || exit 1"
#>>>>>>> 5613de26e0e70b7ee7a937144298dbe20da18d48
			setup_ini_loaded=1
			;;
	esac 
done >"$DB_ROOT/setup.ini"
	config_write
}

list_all_packages()
{
	list_package ""
}

list_package()
{
	get_installed_packages
	installed_list=$ret
	
	gawk '$1 == "@" && (KEY == "" || $2 == KEY) {found=1; name=$2;}
				$1 == "version:" {ver=$2;}
				$1 == "sdesc:" { $1=""; desc=$0}
				$1 == "install:" {
					if (found) { 
						if (index(INSTALLED,name))
							x="I";
						else
							x=" ";
							
						printf("%-25s %s %-10s %8d %s\n",name,x,ver,$3,desc);
						found=0; 
					} 
				}' KEY="$1" INSTALLED="$ret" $DB_ROOT/setup.ini
}

#
# $1 empty for all packages otherwise space separated list of packages 
#
list_packages_for_upgrade()
{
	if test -z "$1"; then 
		installed=`grep -v "INSTALLED" $DB | gawk '{ printf("%s#%s ",$1,$2);}'`
	else 
		TMPFILE=/tmp/`basename $0`.$$
		rm $TMPFILE 2>/dev/null
		for i in `echo $1`; do
			echo $i >$TMPFILE
		done
		installed=`grep -f "$TMPFILE" $DB | gawk '{ printf("%s#%s ",$1,$2);}'`
	fi 

	TMPFILE=/tmp/`basename $0`.$$
	rm $TMPFILE 2>/dev/null

	for i in `echo $installed`; do 
		pkg=`echo $i | sed 's,#.*$,,g'`
		file=`echo $i | sed 's,^.*#,,g'`
		gawk '$1 == "@" && (KEY == "" || $2 == KEY) {found=1; name=$2;}
				$1 == "version:" {ver=$2;}
				$1 == "sdesc:" { $1=""; desc=$0}
				$1 == "install:" {
					# check if current package is installed has the filename is found is equal with setup.ini 
					# filename and return package name, indicating that an upgrade is required 
					if (found) { 
							n=split($2,a,"/");
							filename=a[n]; 
							if (FILE != filename)
								print name 
								#" " FILE " " filename;
						found=0;
						exit 0
					} 
				}' KEY="$pkg" FILE="$file" $DB_ROOT/setup.ini >>$TMPFILE
	done 
	ret=`cat $TMPFILE`
}


get_installed_packages()
{
	ret=`grep -v "INSTALLED" $DB | gawk '{printf("%s ",$1);}'`
}

#
# build dependency list 
#
# param is list of packages
# the function returns a list of non installed related packages in variable $ret
#
build_dep_list()
{
	ret=
	TMPFILE=/tmp/`basename $0`.$$
	rm $TMPFILE 2>/dev/null
	for i in $1; do
		echo $i >>$TMPFILE
		DEP=`gawk  '$1 == "@" && $2 == KEY { found=1} 
								$1 == "requires:" && found == 1 { 
										$1 = ""; print $0; found=0 
								}' KEY="$i" $DB_ROOT/setup.ini`
								
		for j in $DEP; do
			echo $j >>$TMPFILE
		done
	done
	cat $TMPFILE | sort | uniq >$TMPFILE.1
	for i in `cat $TMPFILE.1`; do 
		ret="$ret $i" 
	done
}	

#
# check for already installed packages 
# 
# $1 - list of packages
# 
# return value 
#   $ret - list of installed packages 
#
check_for_installed_packages()
{
	ret=
	packages=`grep -v "INSTALLED" $DB | gawk '{printf("%s ",$1);}'`
	for i in `echo $1`; do
		echo "i=$i"
		case "$packages" in
			*$i*)
				ret="$ret $i"
				;;
			*)
				;;
		esac
	done
	
	$show "check_for_installed_packages=$ret"
}

#
# check for not installed packages 
# 
# $1 - list of packages
# 
# return value 
#   $ret - list of not installed packages 
#
check_for_not_installed_packages()
{
	ret=
	packages=`grep -v "INSTALLED" $DB | gawk '{printf("%s ",$1);}'`
	$show "check_for_not_installed_packages=$1"
	$show "packages=$packages"
	for i in `echo $1`; do
		$show "i=$i"
		case "$packages" in
			*$i*)
				$show "!!!$i!!!"
				;;
			*)
				ret="$ret $i"
				;;
		esac
	done
	
	$show "check_for_not_installed_packages=$ret"
}

#
# return a list of urls given by a list of package names 
# 
# $1 - package list 
# 
# return value 
#   $ret - list of $mirror based path 
# 
get_install_url_path()
{
	echo "------- download package path --------"
	ret=
	for i in `echo $1`; do
		FILE=`gawk '$1 == "@" && $2 == KEY { found=1} $1 == "install:" && found == 1 { print $2; found=0 }' KEY="$i" $DB_ROOT/setup.ini`
		if test -z "$FILE"; then 
			echo "package '$i' not found on installation mirror"
		else 
			ret="$ret $i#$FILE"
		fi
	done
	echo "get_install_url_path=$ret"
}

#
# return a list of urls given by a list of package names 
# 
# $1 - package list 
# 
# return value 
#   $ret - list of $mirror based path 
# 
get_source_url_path()
{
	echo "------- download package path --------"
	ret=
	for i in `echo $1`; do
		FILE=`gawk '$1 == "@" && $2 == KEY { found=1} $1 == "source:" && found == 1 { print $2; found=0 }' KEY="$i" $DB_ROOT/setup.ini`
		if test -z "$FILE"; then 
			echo "package '$i' not found on installation mirror"
		else 
			ret="$ret $i#$FILE"
		fi
	done
	echo "get_source_url_path=$ret"
}
#
# install packages 
# 
# $1 - package list 
# $2 - 'source' - install source package 
install_packages()
{
$show "install_packages \""$1"\" \""$2"\""
	echo "------- install packages --------"
	for i in $1; do
		name=`echo $i | gawk 'BEGIN {FS="#";} { print $1}'`
		relpath=`echo $i | gawk 'BEGIN {FS="#";} { print $2}'`
		
		case "$relpath" in
		 *://*) abspath="$relpath" ;;
		 *) abspath="$mirror_url/$relpath" ;;
		 esac
		file_name=${relpath##*/}
		tmp_dir_name=`echo "$relpath" | sed "s|.*/\($(get_arch_suffix)\)|/tmp/cygsetup/\1|"`
		mkdir -p $tmp_dir_name

		if test "$2" = "source"; then 
			myroot=$ROOT/usr/src
		else
			myroot=$ROOT/
		fi 
		# unpack archive 
		case $mirror_url in
			http:* | ftp:*)
				# if file is available check integrity 
				if ! test -f "$tmp_dir_name/$file_name" || test -n "`bzip2 -t $tmp_dir_name/$file_name 2>&1`"; then 
					$run eval "(set -x; cd $tmp_dir_name; rm "$file_name.*" 2>/dev/null; wget -nd -c $abspath)"
				fi
				if test "$2" = "source"; then 
					$run eval "$TAR -C $myroot -xvf $tmp_dir_name/$file_name 2>/dev/null"
				else
					$run eval "$TAR -C $myroot -xvf $tmp_dir_name/$file_name 2>/dev/null | tee $DB_ROOT/$name.lst"
					$run eval "gzip -f $DB_ROOT/$name.lst"
					add_package_to_cygwin_db $name $file_name
					run_postinstall_script $name 
				fi
				;;
			file:*)
				url=`echo $mirror_url | sed 's,^file:,,g'`
				if test "$2" = "source"; then 
					$run eval "$TAR -C $myroot -xvf $url/$relpath 2>/dev/null"
				else
					$run eval "$TAR -C $myroot -xvf $url/$relpath 2>/dev/null | tee $DB_ROOT/$name.lst"
					$run eval "gzip -f $DB_ROOT/$name.lst"
					add_package_to_cygwin_db $name $file_name
					run_postinstall_script $name 
				fi 
				;;
			*)			
				echo "unknown protocol in '$mirror_url'" ; exit 1;;
		esac
	done 
}

#
# add package to cygwin db 
# 
# $1 - package name
# $2 - filename of archive tar.bz2 
#
add_package_to_cygwin_db()
{	
	name=$1
	file_name=$2
	
	# add entry to db 
	$show "cp $DB $DB.bak" 
	$run eval "cp $DB $DB.bak" 

	$show "grep -v "$name" $DB >$DB.$$" 
	$run eval "grep -v "$name" $DB >$DB.$$" 

	$show "echo $name $file_name 0 >>$DB.$$"
	$run eval "echo $name $file_name 0 >>$DB.$$"

	$show "mv $DB.$$ $DB" 
	$run eval "mv $DB.$$ $DB" 
}

#
# $1 - package name 
#

remove_package_from_cygwin_db()
{	
		name=`echo $1`

		if test -z "`grep "$name" $DB`"; then 
			echo "package not found" 
			return 
		fi

		echo "remove package from db"
		$show "cp $DB $DB.bak" 
		$run eval "cp $DB $DB.bak" 
	
		$show "grep -v "$name" $DB >$DB.$$" 
		$run eval "grep -v "$name" $DB >$DB.$$" 
	
		$show "mv $DB.$$ $DB" 
		$run eval "mv $DB.$$ $DB" 

		if ! test -f "$DB_ROOT/$name.lst.gz" ; then
			echo "could not remove files from package '$name'."
			return
		fi 

		echo "removing package files"  
		(cd /; zcat $DB_ROOT/$name.lst.gz | xargs rm -v 2>/dev/null )
		rm /etc/postinstall/$name.sh* 2>/dev/null
		rm $DB_ROOT/$name.lst.gz 
}

#
# $1 - package name 
#
run_postinstall_script()
{
	name=$1

	# show postinstall script
	PIDIR=$ROOT/etc/postinstall
	if test -f "$PIDIR/$name.sh"; then
	  cd $PIDIR
	  $show "$name.sh && mv $name.sh $name.sh.done"
		$run eval "sh $name.sh && mv $name.sh $name.sh.done "
	fi
}
#------------------------------------------------------------
# end of cyglib.sh 
#------------------------------------------------------------
config_read

origin_mirror=$mirror

# searches for packages containing files or list cygwin packages for an 
# expression given as parameter.  
# The script lookups the setup database in /etc/setup

pkg_dir=$mirror_url

print_help()
{
	echo "usage: cygsetup <mode> <options>     - generic command format"
	echo
	echo "   --mirror                 - list all mirrors"
	echo "   --mirror=<num>           - set active mirror and download recent setup.ini"
	echo
	echo "   [-q | --query] [<opt>]   - query informations about installed packages"
	echo "    -q -l [-a | --all]      - query informations of all installed packages"
	echo "    -q -l <pkg>             - query file of installed package <pkg>"
	echo "    -q -f <file>            - find package for file <file>"
	echo
	echo "   [-l | --list] <opt>      - list informations about available packages from recent mirror"
	echo "    -l <pkg>                - list informations about available <pkg>"
	echo "    -l [-a | -all]          - list informations about all available"
	echo 
	echo "   [-i | --install] <pkg>   - install package <pkg>"
	echo
	echo "   [-u | --upgrade] <opt>   - upgrade package (please stop any running app)"
	echo "    -u <pkg>                - upgrade package <pkg>"
	echo "     u [-a | --all]      	  - upgrade all installed packages"
	echo 
	echo "   [-r | --reinstall] <pkg> - reinstall package <pkg>"
  echo 
	echo "   [-e | --erase] <pkg>     - remove package <pkg>"
	exit 1
}

verbose="1"
if test $# -eq "0"; then 
	print_help
fi 


while :; do
  case "$1" in
    --mirror=*) set_mirror="${set_mirror:+$set_mirror }${1#*=}"; shift ;;
    *) break ;;
  esac
done



mode=$1; shift
if test $# -gt "0"; then 
	option=$1; shift
fi
if test $# -gt "0"; then 
	params=$*
fi

if [ "$set_mirror" ]; then
		setup_ini_loaded=
		get_mirror_list
		build_area_list
		set_new_mirror $set_mirror
		config_write
		if test "$mirror" != "$origin_mirror" || test -z "$setup_ini_loaded"; then 
			load_setup_ini $mirror
		fi
		config_print
fi

while :; do
  case $mode in
    --root=*) ROOT=${mode#*=} ;;
  	--mirror)
  		get_mirror_list
  		build_area_list
  		list_all_mirrors $mirror
  		;;
  
  	--set-area*)
  		area=$value
  		;;
  	
  	-q | --query)
      	case $option in 
      		# all packages 
      		-a |--all)
      			cat $DB | sed 's#.tar.*##g' | gawk '{ n = match($2,/-[0-9][^/a-zA-Z]/); if (n > 0) release=substr($2,n+1); printf("%-20s %s\n", $1,release) }' | sort
      		    ;;
      		# list package files  
      		-l | --list)
      			if test -z "$params"; then
      				echo "usage: $0 -q -l <package>"
      				exit 1
      			fi
      			$0 -q "^$params"
      			if test -e "$DB_ROOT/$params.lst.gz"; then
      				find $DB_ROOT -name "$params.lst.gz" -exec zcat {} \; | grep -v "/$" | gawk '{ print "\t" $1 }'
      			else		
      				echo "no files available" 
      			fi 
      			;;
      		# find package 
      		-f | --files)
      			PACKAGES=`find $DB_ROOT -name '*.lst.gz'`
      			for i in $PACKAGES; do 
      				FILES=`zcat $i | egrep "$params"`
      				if test -n "$FILES"; then
      					PACKAGE_NAME=`echo $i | sed "s#.lst.gz##; s#$DB_ROOT/##;"`
      					echo $PACKAGE_NAME
      					for j in $FILES; do 
      						echo -e "\t" $j
      					done
      					echo 
      				fi
      			done
      			;;
      		-d | --deps)
      			for i in `echo $params`; do 
      				build_dep_list "$i"
      				echo "$ret"
      			done
      			;;
          esac
          ;;
  	# check files of a package 
  	-c | --check)
  		# get installed packages 
  		PACKAGES=`cat $DB | grep -v "INSTALLED" | gawk '{ print db_root "/" $1 ".lst.gz" }' db_root=$DB_ROOT`
  		for i in $PACKAGES; do 
  			# get file list 
  			FILES=`zcat $i | grep -v "/$i"`
  			if test -n "$verbose"; then 
  				echo -n "checking package $i"
  			fi 
  
  			# create package name 
  	
  			# check if file is installed 
  			repair=""
  			for j in $FILES; do 
  				if test -f "/$j"; then
  					echo ""
  				else 
  					repair="1"
  					echo "file $j is deleted" 
  				fi
  			done 
  			if test -n "$repair"; then 
  				if test -n "$verbose"; then 
  					echo "... has to be repaired "
  				else 
  					echo "$i"
  				fi
  			else 
  				echo "" 
  			fi	
  		done
  		;;			
  #		*)
  #			if test -z "$option"; then
  #				echo "usage: $0 -q <package>"
  #				exit 1
  #			fi
  #			cat $DB | grep "$option" | sed 's#.tar.*##g' | gawk '{ n = match($2,/-[0-9][^/a-zA-Z]/); if (n > 0) release=substr($2,n+1); if (release == "") release = "no release available"; printf("%-20s %s\n", $1,release) }' | sort
  #			;;
  
  	# search for packages in a local package tree 
  	-l | --list)
      	case $option in 
      		# all packages 
      		-a | --all)
      			list_all_packages
      		;;
      		*) 
      			for i in `echo $option $params`; do 
      				list_package "$i"
      			done
      		;;
  		esac
      	;;
  
  	# install packages from a local package tree 
  	-r | --reinstall)
  		case $option in 
  			# all packages 
  			-a | --all)
  			;;
  			*)
  			pkgname=""
  			for i in `echo $option $params`; do 
  # do not reinstall depending packages
  #				build_dep_list "$i"
  				get_install_url_path "$i"
  				install_packages "$ret"	
  			done 
  		esac
  	    ;;	
  
  	# download source 
  	-ds)
  			pkgname=""
  			for i in `echo $option $params`; do 
  				get_source_url_path "$i"
  				install_packages "$ret"	"source"
  			done
  	    ;;
  	
  	# upgrade packages 
  	-u | --upgrade)
  		case $option in 
  			# all packages 
  			-a | --all)
  				list_packages_for_upgrade "" 
  				get_install_url_path "$ret"
  				#install_packages "$ret"
  			;;
  			*)
  			pkgname=""
  			for i in `echo $option $params`; do 
  				list_packages_for_upgrade "$i"
  				get_install_url_path "$ret"
  				install_packages "$ret"	
  			done 
  		esac
  	    ;;	
  
  
  	# install packages from a local package tree 
  	-i | --install)
  		case $option in 
  			# all packages 
  			-a | --all)
  			;;
  			*)
  			pkgname=""
  			for i in `echo $option $params`; do 
  				build_dep_list "$i"
  				check_for_not_installed_packages "$ret"
  				get_install_url_path "$ret"
  				install_packages "$ret"
  			done
  		esac
  	    ;;	
  
  	# remove installed package 
  	-e | --erase)
  		case $option in 
  			*)
  			for i in `echo $option $params`; do 
  				echo $i
  				remove_package_from_cygwin_db "$i"
  			done 
  		esac
  	    ;;	
  
  	# help 
  	-h | --help)
  		print_help
  	    ;;		
  	
  esac
  
  break
done
