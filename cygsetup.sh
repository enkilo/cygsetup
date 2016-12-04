#!/bin/bash
#
# cygwin command line installer 
#
# Website: http://kde-cygwin.sf.net 
#
# Requirements:  wget bzip2 gawk sed grep uniq
# 
#   
# Copyright (c) 2003-2007 Ralf Habacker     <Ralf Habacker@freenet.de>
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
#if [ -n "$TMP" -a -d "$TMP" ]; then
#  TMPDIR=$(cygpath "$TMP")
#else
  TMPDIR=/tmp
#fi

#ROOT=""
DB_ROOT="$ROOT/etc/setup"
DB="$DB_ROOT/installed.db"
CONF="$DB_ROOT/cygsetup.conf"
TAR="tar -U"

type wget 2>/dev/null >/dev/null && WGET="wget -q --no-config --content-disposition --follow-ftp --user-agent=cygsetup --progress=bar:force:noscroll"
type curl 2>/dev/null >/dev/null && CURL="curl -q -k -L -#"
type lynx 2>/dev/null >/dev/null && LYNX="lynx -accept_all_cookies -force_secure"

basename() { set "${@##*/}"; echo "${1%$2}"; }

mktempfile() { 
 (PREFIX=${0##*/};
  TMPPATH=${1-${TMPDIR-"/tmp"}}
  TEMPFILE=${TMPPATH}/${PREFIX#-}.${2:-$RANDOM}
  rm -f "$TEMPFILE"
  echo -n > "$TEMPFILE"
  echo "$TEMPFILE")
}


test_package_file() {
 (EXT=${1##*.}
  case "$EXT" in
    xz | txz) DECOMPRESS="xz -d -f -c" ;;
    bz2 | tbz | tbz2) DECOMPRESS="bzip2 -d -f -c" ;;
    gz | tgz) DECOMPRESS="gzip -d -f -c" ;;
    lzma) DECOMPRESS="lzma -d -f -c" ;;
    *) echo "No such compression format: $EXT" 1>&9; exit 1 ;;
  esac
  R=$(eval "$DECOMPRESS <\"\$1\" | (tar -t >/dev/null; echo \$?)" 2>/dev/null)
  exit $R)
}

get_tar_flags() {
 (EXT=${1##*.}
  case "$EXT" in
    xz | txz) echo "-J" ;;
    bz2 | tbz | tbz2) echo "-J" ;;
    gz | tgz) echo "-z" ;;
    lzma) echo "--use-compress-program=lzma" ;;
    *) echo "No such compression format: $EXT" 1>&9; exit 1 ;;
  esac)
}

#
# default settings 
# 
SHOW=:
#show=echo
area="Europe"
DEFAULT_MIRROR="FILE:/d" 
mirror=1
MIRROR_URL=

# http_dl <URL> [output-file]
http_dl() {
  echo http_dl "$@" 1>&2
 (URL=$1
  OUTPUT=$2
  CMD=
  if [ "$OUTPUT" ]; then
    HASH=`echo "${OUTPUT#*/cygwin*/}" | sha1sum`
    TMP=`mktempfile $TMPDIR "${HASH:1:8}"`
    rm -f "$OUTPUT"
  else
    TMP=
  fi
  for P in  WGET CURL LYNX; do
    eval V=\$$P 
    [ "$V" ] || continue 
    case "$P" in
      WGET) CMD="\$WGET -O \${OUTPUT:--} -c \"$URL\"" ;;
      CURL) CMD="\$CURL ${OUTPUT:+-o \"\$OUTPUT\" }\"$URL\"" ;;
      LYNX) CMD="\$LYNX -source${OUTPUT:+ >\"\$OUTPUT\"} \"$URL\"" ;;
    esac
    break
  done
  
  IFS="$IFS "  
  
  #[ "$TMP" ] && echo "Temp file: $TMP" 1>&9
  
  [ "$OUTPUT" ] && 
  echo "Downloading $URL ..." 1>&9
 # $RUN echo "+ ${CMD//\$OUTPUT/$OUTPUT}" 1>&9  
  $RUN eval "(OUTPUT=$TMP; $CMD); R=$?"
  
  if [ -n "$TMP" ]; then
    if [ "$R" -eq 0 ]; then
      mv -f "$TMP" "$OUTPUT"
    else
      rm -f "$TMP"
    fi
  fi
  )
}

get_arch()
{
  test -z "$ARCH" && ARCH=`get_arch_suffix`
  echo ARCH=$ARCH 1>&9
}

config_write()
{
  echo "ROOT=$ROOT" >$CONF
  echo "DB_ROOT=$DB_ROOT" >>$CONF
  echo "CONF=$CONF" >>$CONF
  echo "ARCH=$ARCH" >>$CONF
  echo "DLDIR=\"$DLDIR\"" >>$CONF
  echo "area=\"$area\"" >>$CONF
  echo "DEFAULT_MIRROR=\"$DEFAULT_MIRROR\"" >>$CONF
  echo "mirror=\"$mirror\"" >>$CONF
  echo "MIRROR_URL=\"$MIRROR_URL\"" >>$CONF
  #echo "setup_ini=$DB_ROOT/setup.ini" >>$CONF
  #echo "SETUP_INI_LOADED=$SETUP_INI_LOADED" >>$CONF
}

config_print()
{
  echo "ROOT=$ROOT" 
  echo "DB_ROOT=$DB_ROOT" 
  echo "CONF=$CONF"
  echo "ARCH=$ARCH"
  echo "DLDIR=${DLDIR:-$TMPDIR/`basename "$0" .sh`}"
  echo "area=\"$area\""
  echo "DEFAULT_MIRROR='$DEFAULT_MIRROR'"
  echo "mirror='$mirror'"
  echo "MIRROR_URL='$MIRROR_URL'"
  #echo "setup_ini=$DB_ROOT/setup.ini"
  #echo "SETUP_INI_LOADED=$SETUP_INI_LOADED"
}


config_read()
{
  #echo "CONF=$CONF" 1>&9
  if ! test -f "$CONF"; then  
    config_write
  else 
    echo "Loading config $CONF" 1>&9
    . $CONF
  fi
  
  if test "x$ARCH" = x; then
    get_arch
    config_write
  fi
}

get_arch_suffix()
{
   if [ -z "$1" -a -n "$ARCH" ]; then
     echo "$ARCH"
     return 0
   fi

   [ -n "$1" ] && MACHINE="$1" || MACHINE=`$ROOT/bin/uname -m`
   
   echo MACHINE="$MACHINE" 1>&9
   
   case "${MACHINE}" in
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
    (http_dl "http://www.cygwin.com/mirrors.lst"
    http_dl "http://sourceware.org/mirrors.html"  |sed -n 's,.*>\([^< \t:]\+\)[: \t]*<a href="\([^"]*\)/*\">\([^<]*\)</a>.*,\2/cygwinports;\3;\1;\1,P' | sed '/rsync:/d; s,\s*,,g'
    
    ) >"$DB_ROOT/mirrors.lst"
  fi
}

#
# build area list
# 
build_area_list()
{
  _ALL_AREAS=`grep -v "^#" $DB_ROOT/mirrors.lst | sed 's, ,#,g' | gawk 'BEGIN { FS=";"} { print $3; }' | sort | uniq`
  J=1
  for i in $_ALL_AREAS; do 
    ALL_AREAS="$ALL_AREAS $J~$i"
    J=`EXPR $J + 1` 
  done
}

#
#
# 
set_new_mirror()
{
  mirror=$*
  if ! test `echo $* | grep "^[0-9]" 2>/dev/null`; then 
    MIRROR_URL=${*%/}
  else 
    for i in $ALL_AREAS; do
      AREA_NAME=`echo $i | sed 's,^.*~,,g;s,#, ,g'`
      AREA_NUM=`echo $i | sed 's,~.*$,,g'`
      URL=`grep "$AREA_NAME" $DB_ROOT/mirrors.lst | gawk 'BEGIN { FS=";"; i=1} { if(cur==sprintf("%d%d",mn,i) || cur==mn && i==1) print $1; i++; }' mn="$AREA_NUM" cur="$1" | sed 's,/*$,,'`
      if test -n "$URL"; then 
        MIRROR_URL=$URL
      fi
    done
  fi
  echo "mirror='"$*"'"
  echo "MIRROR_URL='"$MIRROR_URL"'"
}

list_all_mirrors()
{
  for i in $ALL_AREAS; do
    AREA_NAME=`echo $i | sed 's,^.*~,,g;s,#, ,g'`
    AREA_NUM=`echo $i | sed 's,~.*$,,g'`
    echo $AREA_NAME
    grep "$AREA_NAME" $DB_ROOT/mirrors.lst | gawk 'BEGIN { FS=";"; i=1} { if ($4 == old) c=""; else c=$4; if(cur==sprintf("%d%d",mn,i) || cur==mn && i==1) sel=" >"; else sel="  "; printf("%s%1d%-2d  %-14s %s\n",sel,mn,i++,c,$1); old=$4;}' mn="$AREA_NUM" cur="$mirror"
    echo 
  done
}

load_setup_ini()
{
mkdir -P "$DB_ROOT/"
rm -f "$DB_ROOT/setup.ini"
for URL in $MIRROR_URL; do
  echo $URL 1>&9
  # unpack archive 
  case $URL in
    http:* | ftp:*)
#<<<<<<< HEAD
    CMD="(cd \"\$DB_ROOT\"; URL=\"$URL/$(get_arch_suffix)\"; http_dl \"\$URL/setup.bz2\" | bzip2 -d -c - | sed \"\\\\|/| s|^\\\\([a-z]*\\\\):\\\\s\\\\+|\\\\1: \${URL%/$(get_arch_suffix)}/|\")  || exit 1"
      $SHOW eval "$CMD"
      $RUN eval "$CMD"
#      $show eval "(cd \"\$DB_ROOT\"; bzip2 -d -c -  >>setup.ini)"
#      $RUN eval "(cd \"\$DB_ROOT\"; bzip2 -d -c setup.bz2  >>setup.ini)"
      SETUP_INI_LOADED=1
      ;;
    FILE:*)
      URL=`echo $URL | sed 's,^FILE:,,g'`
      $SHOW "(bzip2 -d -c $URL/setup.bz2)  || exit 1"
      $RUN eval "(bzip2 -d -c $URL/setup.bz2)  || exit 1"
      SETUP_INI_LOADED=1
      ;;
    /*)
      URL=$URL;
      $SHOW "(bzip2 -d -c $URL/setup.bz2)  || exit 1"
      $RUN eval "(bzip2 -d -c $URL/setup.bz2)  || exit 1"
#=======
#      $show eval "(cd $DB_ROOT; http_dl \"$MIRROR_URL/$ARCH/setup.bz2\" setup.bz2) || exit 1"
#      $RUN eval "(cd $DB_ROOT; http_dl \"$MIRROR_URL/$ARCH/setup.bz2\" setup.bz2) || exit 1"
#      $show eval "(cd $DB_ROOT; bzip2 -d -c setup.bz2  >setup.ini)"
#      $RUN eval "(cd $DB_ROOT; bzip2 -d -c setup.bz2  >setup.ini)"
#      SETUP_INI_LOADED=1
#      ;;
#    file:*)
#      URL=`echo $MIRROR_URL | sed 's,^file:,,g'`
#      $show "(bzip2 -d -c $URL/$ARCH/setup.bz2 >$DB_ROOT/setup.ini)  || exit 1"
#      $RUN eval "(bzip2 -d -c $URL/$ARCH/setup.bz2 >$DB_ROOT/setup.ini)  || exit 1"
#      SETUP_INI_LOADED=1
#      ;;
#    /*)
#      URL=$MIRROR_URL;
#      $show "(bzip2 -d -c $URL/$ARCH/setup.bz2 >$DB_ROOT/setup.ini)  || exit 1"
#      $RUN eval "(bzip2 -d -c $URL/$ARCH/setup.bz2 >$DB_ROOT/setup.ini)  || exit 1"
#>>>>>>> 5613de26e0e70b7ee7a937144298dbe20da18d48
      SETUP_INI_LOADED=1
      ;;
  esac 
done >"$DB_ROOT/setup.ini"
  config_write
}

get_package_info() {
  echo "Reading $DB_ROOT/setup.ini" 1>&9
	sed -n  <"$DB_ROOT/setup.ini"  "/^@ ${1}\$/ {
	:lp
	/: \"[^\"\n]*\$/ { N; s|\n\([^\n]*\)\$|\\\\n\\1|; b lp; }	
	N
	/\\n\$/! { b lp; }
	P
	}"
}

get_all_package_info() {
  echo "Reading $DB_ROOT/setup.ini" 1>&9
	sed -n  <"$DB_ROOT/setup.ini"  "/^@ / {
	:lp
	N
	/\\n\$/! { b lp; }
	s/\\n/|/g
	P
	}"
}

list_all_packages()
{
  list_package ""
}

list_package()
{
  get_installed_packages
  installed_list=$RET
  
  echo "Reading $DB_ROOT/setup.ini" 1>&9
  gawk '$1 == "@" && (KEY == "" || $2 == KEY) {found=1; NAME=$2;}
        $1 == "version:" {ver=$2;}
        $1 == "sdesc:" { $1=""; desc=$0}
        $1 == "install:" {
          if (found) { 
            if (index(installed,NAME))
              x="i";
            else
              x=" ";
              
            printf("%-25s %s %-10s %8d %s\n",NAME,x,ver,$3,desc);
            found=0; 
          } 
        }' KEY="$1" installed="$RET" $DB_ROOT/setup.ini
}

#
# $1 empty for all packages otherwise space separated list of packages 
#
list_packages_for_upgrade()
{
  if test -z "$1"; then 
    installed=`grep -v "installed" $DB | gawk '{ printf("%s#%s ",$1,$2);}'`
  else 
    TMPFILE=$TMPDIR/`basename $0`.$$
    rm $TMPFILE 2>/dev/null
    for i in `echo $1`; do
      echo $i >$TMPFILE
    done
    installed=`grep -f "$TMPFILE" $DB | gawk '{ printf("%s#%s ",$1,$2);}'`
  fi 

  TMPFILE=$TMPDIR/`basename $0`.$$
  rm $TMPFILE 2>/dev/null

  for i in `echo $installed`; do 
    PKG=`echo $i | sed 's,#.*$,,g'`
    FILE=`echo $i | sed 's,^.*#,,g'`
    gawk '$1 == "@" && (KEY == "" || $2 == KEY) {found=1; NAME=$2;}
        $1 == "version:" {ver=$2;}
        $1 == "sdesc:" { $1=""; desc=$0}
        $1 == "install:" {
          # check if current package is installed has the filename is found is equal with setup.ini 
          # filename and return package name, indicating that an upgrade is required 
          if (found) { 
              n=split($2,a,"/");
              filename=a[n]; 
              if (FILE != filename)
                print NAME 
                #" " file " " filename;
            found=0;
            exit 0
          } 
        }' KEY="$PKG" FILE="$FILE" $DB_ROOT/setup.ini >>$TMPFILE
  done 
  RET=`cat $TMPFILE`
}


get_installed_packages()
{
  RET=`grep -v "installed" $DB | gawk '{printf("%s ",$1);}'`
}

#
# build dependency list 
#
# param is list of packages
# the function returns a list of non installed related packages in variable $RET
#
build_dep_list()
{
  RET=
  TMPFILE=$TMPDIR/`basename $0`.$$
  rm $TMPFILE 2>/dev/null
  for i in $1; do
    echo $i >>$TMPFILE
    DEP=`gawk  '$1 == "@" && $2 == KEY { found=1} 
                $1 == "requires:" && found == 1 { 
                    $1 = ""; print $0; found=0 
                }' KEY="$i" $DB_ROOT/setup.ini`
                
    for J in $DEP; do
      echo $J >>$TMPFILE
    done
  done
  cat $TMPFILE | sort | uniq >$TMPFILE.1
  for i in `cat $TMPFILE.1`; do 
    RET="$RET $i" 
  done
}  

#
# check for already installed packages 
# 
# $1 - list of packages
# 
# return VALUE 
#   $RET - list of installed packages 
#
check_for_installed_packages()
{
  RET=
  packages=`grep -v "installed" $DB | gawk '{printf("%s ",$1);}'`
  for i in `echo $1`; do
    echo "i=$i"
    case "$packages" in
      *$i*)
        RET="$RET $i"
        ;;
      *)
        ;;
    esac
  done
  
  $SHOW "check_for_installed_packages=$RET"
}

#
# check for not installed packages 
# 
# $1 - list of packages
# 
# return VALUE 
#   $RET - list of not installed packages 
#
check_for_not_installed_packages()
{
  RET=
  packages=`grep -v "installed" $DB | gawk '{printf("%s ",$1);}'`
  $SHOW "check_for_not_installed_packages=$1"
  $SHOW "packages=$packages"
  for i in `echo $1`; do
    $SHOW "i=$i"
    case "$packages" in
      *$i*)
        $SHOW "!!!$i!!!"
        ;;
      *)
        RET="$RET $i"
        ;;
    esac
  done
  
  $SHOW "check_for_not_installed_packages=$RET"
}

#
# return a list of urls given by a list of package names 
# 
# $1 - package list 
# 
# return VALUE 
#   $RET - list of $mirror based path 
# 
get_install_url_path()
{
  echo "------- download package path --------" 1>&9
  RET=
  for i in `echo $1`; do
    FILE=`gawk '$1 == "@" && $2 == KEY { found=1} $1 == "install:" && found == 1 { print $2; found=0 }' KEY="$i" $DB_ROOT/setup.ini`
    if test -z "$FILE"; then 
      echo "package '$i' not found on installation mirror"
    else 
      RET="$RET $i#$FILE"
    fi
  done
  set -- ${RET%%'#'*}
  echo 1>&9 "$@" #get_install_url_path=$RET" 
}

#
# return a list of urls given by a list of package names 
# 
# $1 - package list 
# 
# return VALUE 
#   $RET - list of $mirror based path 
# 
get_source_url_path()
{
  echo "------- download package path --------"
  RET=
  for i in `echo $1`; do
    FILE=`gawk '$1 == "@" && $2 == KEY { found=1} $1 == "source:" && found == 1 { print $2; found=0 }' KEY="$i" $DB_ROOT/setup.ini`
    if test -z "$FILE"; then 
      echo "package '$i' not found on installation mirror"
    else 
      RET="$RET $i#$FILE"
    fi
  done
  echo "get_source_url_path=$RET"
}
#
# install packages 
# 
# $1 - package list 
# $2 - 'source' - install source package 
install_packages()
{
  #echo "TMPDIR=$TMPDIR" 1>&9
$SHOW "install_packages \""$1"\" \""$2"\""
  echo "------- install packages --------"
  for i in $1; do
    NAME=`echo $i | gawk 'BEGIN {FS="#";} { print $1}'`
    RELPATH=`echo $i | gawk 'BEGIN {FS="#";} { print $2}'`
    
    case "$RELPATH" in
     *://*) ABSPATH="$RELPATH" ;;
     *) ABSPATH="${MIRROR_URL%/}/$RELPATH" ;;
     esac
    FILE_NAME=${RELPATH##*/}
    
    TRAILPATH=$ABSPATH
    TRAILPATH=${TRAILPATH#*/cygwin/}
    TRAILPATH=${TRAILPATH#*/cygwinports/}
    
    OUTPATH=${ABSPATH%/$TRAILPATH}
    
#    OUTPATH=${OUTPATH%/cygwin*}
#    OUTPATH=${OUTPATH%/cygwinports/*}
    
    
    OUTPATH=${OUTPATH//":"/"%3a"}
    OUTPATH=${OUTPATH//"/"/"%2f"}
    
    TMP_FILE_NAME=${MIRROR_URL#*://} 
    TMP_FILE_NAME=$TMPDIR/${TMP_FILE_NAME%%/*}/${FILE_NAME##*/}
    
#    TMP_file_name=`echo "$RELPATH" | sed "s|.*/\([^/]\+\)/\+\([^/]\+\)/\+release/|$TMPDIR/cygsetup/\1/\2/release/|"`
    TMP_DIR_NAME=`dirname "$TMP_FILE_NAME"`
    
    mkdir -P "$TMP_DIR_NAME"

    if test "$2" = "source"; then 
      MYROOT=$ROOT/usr/src
    else
      MYROOT=$ROOT/
    fi 
    # unpack archive 
         [ "$LIST_ONLY" = true ] && DL=echo || DL=http_dl
    case $MIRROR_URL in
      http:* | ftp:*)
        # if file is available check integrity 
        #echo "Package file:" $TMP_file_name 1>&9
        if [ "$FORCE" = true ]; then
          rm -f "$TMP_DIR_NAME/$FILE_NAME"
        fi
        if [ ! -f "$TMP_DIR_NAME/$FILE_NAME" ] || ! test_package_file "$TMP_FILE_NAME"; then
          $RUN eval "(rm -rf "$TMP_FILE_NAME" 2>/dev/null
          
          #$WGET -c -O "$TMP_file_name" "$ABSPATH"
          $DL "$ABSPATH" "$TMP_FILE_NAME"
          
         )"
        fi
        if [ "$DOWNLOAD_ONLY" = true ]; then
          return 0
        fi
        TAR_FLAGS=`get_tar_flags "$TMP_FILE_NAME"`
        TAR_LOG=`mktempfile $TMPDIR`
        if test "$2" = "source"; then 
          $RUN echo "\$TAR${TAR_FLAGS:+ $TAR_FLAGS} --hard-dereference -h -U -C $MYROOT -x -f $TRAILPATH/$FILE_NAME"
          $RUN eval "\$TAR${TAR_FLAGS:+ $TAR_FLAGS} --hard-dereference -h -U -C $MYROOT -x -f $TMP_DIR_NAME/$FILE_NAME 2>\"\$TAR_LOG\""
        else
          $RUN echo "\$TAR${TAR_FLAGS:+ $TAR_FLAGS} --hard-dereference -h -U -C $MYROOT -x -v -f $TRAILPATH/$FILE_NAME 2>\$TAR_LOG >$DB_ROOT/$NAME.lst"
          $RUN eval "\$TAR${TAR_FLAGS:+ $TAR_FLAGS} --hard-dereference -h -U -C $MYROOT -x -v -f $TMP_DIR_NAME/$FILE_NAME 2>\"\$TAR_LOG\" >\"$DB_ROOT/$NAME.lst\""
          $RUN eval "gzip -f $DB_ROOT/$NAME.lst"
          add_package_to_cygwin_db $NAME $FILE_NAME
          run_postinstall_script $NAME 
        fi
        (while read -r LINE; do
           case "$LINE" in
             *"Cannot hard link to"*)
               LINK=${LINE#"tar: "}
               LINK=${LINK%%": "*}
               TARGET=${LINE##*"annot hard link to '"}
               TARGET=${TARGET%%"': "*}
               rm -f /"$LINK"
               mkdir -P "$(dirname "/$LINK")"
               ln -svf "/$TARGET" /"$LINK"
#               echo "Hard link: $LINK $TARGET" 1>&9
             ;;
           esac
         done <"$TAR_LOG")
        rm -f "$TAR_LOG"
        ;;
      FILE:*)
        URL=`echo $MIRROR_URL | sed 's,^FILE:,,g'`
        if test "$2" = "source"; then 
          $RUN eval "$TAR --hard-dereference -h -U -C $MYROOT -xvf $URL/$RELPATH 2>/dev/null"
        else
          $RUN eval "$TAR --hard-dereference -h -U -C $MYROOT -xvf $URL/$RELPATH 2>/dev/null | tee $DB_ROOT/$NAME.lst"
          $RUN eval "gzip -f $DB_ROOT/$NAME.lst"
          add_package_to_cygwin_db $NAME $FILE_NAME
          run_postinstall_script $NAME 
        fi 
        ;;
      *)      
        echo "unknown protocol in '$MIRROR_URL'" ; exit 1;;
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
  NAME=$1
  FILE_NAME=$2
  
  # add entry to db 
  $SHOW "cp $DB $DB.bak" 
  $RUN eval "cp $DB $DB.bak" 

  $SHOW "grep -v "$NAME" $DB >$DB.$$" 
  $RUN eval "grep -v "$NAME" $DB >$DB.$$" 

  $SHOW "echo $NAME $FILE_NAME 0 >>$DB.$$"
  $RUN eval "echo $NAME $FILE_NAME 0 >>$DB.$$"

  $SHOW "mv $DB.$$ $DB" 
  $RUN eval "mv $DB.$$ $DB" 
}

#
# $1 - package name 
#

remove_package_from_cygwin_db()
{  
    NAME=`echo $1`

    if test -z "`grep "$NAME" $DB`"; then 
      echo "package not found" 
      return 
    fi

    echo "remove package from db"
    $SHOW "cp $DB $DB.bak" 
    $RUN eval "cp $DB $DB.bak" 
  
    $SHOW "grep -v "$NAME" $DB >$DB.$$" 
    $RUN eval "grep -v "$NAME" $DB >$DB.$$" 
  
    $SHOW "mv $DB.$$ $DB" 
    $RUN eval "mv $DB.$$ $DB" 

    if ! test -f "$DB_ROOT/$NAME.lst.gz" ; then
      echo "could not remove files from package '$NAME'."
      return
    fi 

    echo "removing package files"  
    (cd /; zcat $DB_ROOT/$NAME.lst.gz | xargs rm -v 2>/dev/null )
    rm /etc/postinstall/$NAME.sh* 2>/dev/null
    rm $DB_ROOT/$NAME.lst.gz 
}

#
# $1 - package name 
#
run_postinstall_script()
{
  NAME=$1

  # show postinstall script
  PIDIR=$ROOT/etc/postinstall
  if test -f "$PIDIR/$NAME.sh"; then
    cd $PIDIR
    $SHOW "$NAME.sh && mv $NAME.sh $NAME.sh.done"
    $RUN eval "sh $NAME.sh && mv $NAME.sh $NAME.sh.done "
  fi
}
#------------------------------------------------------------
# end of cyglib.sh 
#------------------------------------------------------------

exec 9>&2

config_read

ORIGIN_MIRROR=$mirror

# searches for packages containing files or list cygwin packages for an 
# expression given as parameter.  
# The script lookups the setup database in /etc/setup

pkg_dir=$MIRROR_URL

print_help()
{
  echo "usage: cygsetup <MODE> <options>     - generic command format"
  echo
  echo "   --mirror                 - list all mirrors"
  echo "   --mirror=<num>           - set active mirror and download recent setup.ini"
  echo
  echo "   [-q | --query] [<opt>]   - query informations about installed packages"
  echo "    -q -l [-a | --all]      - query informations of all installed packages"
  echo "    -q -l <PKG>             - query FILE of installed package <PKG>"
  echo "    -q -f <FILE>            - find package for FILE <FILE>"
  echo
  echo "   [-l | --list] <opt>      - list informations about available packages from recent mirror"
  echo "    -l <PKG>                - list informations about available <PKG>"
  echo "    -l [-a | -all]          - list informations about all available"
  echo 
  echo "   [-i | --install] <PKG>   - install package <PKG>"
  echo
  echo "   [-u | --upgrade] <opt>   - upgrade package (please stop any running app)"
  echo "    -u <PKG>                - upgrade package <PKG>"
  echo "     u [-a | --all]          - upgrade all installed packages"
  echo 
  echo "   [-r | --reinstall] <PKG> - reinstall package <PKG>"
  echo 
  echo "   [-e | --erase] <PKG>     - remove package <PKG>"
  echo "   --download-only          - only download packages"
  exit 1
}

case "${0##*/}" in
  *cygsetup*)

VERBOSE="1"
if test $# -eq "0"; then 
  print_help
fi 

process_args() {
  while :; do
    #echo "Processing arg: $1" 1>&9
    case $1 in
    -q|--query|-l|--list|-f|--files|-d|--deps|-c|--check|-l|--list|-r|--reinstall|-ds|--source|-u|--upgrade|-i|--install|-e|--erase|-h|--help|--SHOW|--info)
      if [ -z "$MODE" ]; then
      MODE="$1"
     else
       break
     fi
     shift ;;
      --match)
         WHAT="${2%%[!A-Za-z]*}"
         EXPR="${2#*[!A-Za-z]}"
         COMP=${2%%"$EXPR"}
         COMP=${COMP#$WHAT}
         case "$COMP" in
           "!=" | "!") GREP_ARGS="-v" ;;
           *) GREP_ARGS="" ;;
         esac
         shift 2
         PKGS=`get_all_package_info | grep -i $GREP_ARGS -E "\|$WHAT[^|]*($EXPR)" | sed 's,^@ ,, ; s,|.*,,'`
         echo "Packages:" $PKGS 1>&9
         set -- "$@" $PKGS
      ;;
      --list-only*) MODE="-r" LIST_ONLY="true"; shift ;; 
      --download*) MODE="-r" DOWNLOAD_ONLY="true"; shift ;; 
      --ROOT=*) ROOT=${1#*=} ; shift ;;
      --force) FORCE=true; shift ;;
      --ARCH=*) echo "Setting ARCH to ${1#*=}" 1>&9 ; ARCH=`get_arch_suffix ${1#*=}` ;  shift ;;
      --mirror=*) SET_MIRROR="${SET_MIRROR:+$SET_MIRROR }${1#*=}"; shift ;;
      *) break ;;
    esac
  done
  PARAMS=$*
}


get_options_params() {
  while [ $# -gt 0 -a "${1#-}" != "$1" ]; do
    OPTION="${OPTION:+$OPTION
}$1"; shift
  done
  PARAMS=$*
}

process_args "$@"
set -- $PARAMS

get_options_params "$@"
set -- $OPTION $PARAMS

if [ "$SET_MIRROR" ]; then
    SETUP_INI_LOADED=
    get_mirror_list
    build_area_list
    set_new_mirror $SET_MIRROR
    config_write
    if test "$mirror" != "$ORIGIN_MIRROR" || test -z "$SETUP_INI_LOADED"; then 
      load_setup_ini $mirror
    fi
    config_print
fi

while :; do
      #echo "MODE=$MODE" 1>&9
  case $MODE in
    --mirror)
      get_mirror_list
      build_area_list
      list_all_mirrors $mirror
      ;;
  
    --set-area*)
      area=$VALUE
      ;;
    
    --info | --SHOW)
    
    for P in $PARAMS; do
			get_package_info "$P" | sed 's/^@ /Package: /
/desc:/ {
	s/sdesc: "\([^"]*\)"/Short Description: \1/
	s/ldesc: "\([^"]*\)"/Long Description: \1/
	s/\\n/\n  /g
}
s/category: \(.*\)/Category: \1/
s/requires: \(.*\)/Dependencies: \1/
s/version: \(.*\)/Version: \1/
s/install: \(.*\)/Install: \1/
s/source: \(.*\)/Source: \1/'
	  done
    
    ;;
    
    -q | --query)
      echo "OPTION=$OPTION" 1>&9
        case $OPTION in 
          # all packages 
          -a |--all)
            cat $DB | sed 's#.tar.*##g' | gawk '{ n = match($2,/-[0-9][^/a-zA-Z]/); if (n > 0) release=substr($2,n+1); printf("%-20s %s\n", $1,release) }' | sort
              ;;
          # list package files  
          -l | --list)
            if test -z "$PARAMS"; then
              echo "usage: $0 -q -l <package>"
              exit 1
            fi
            $0 -q "^$PARAMS"
            if test -e "$DB_ROOT/$PARAMS.lst.gz"; then
              find $DB_ROOT -NAME "$PARAMS.lst.gz" -exec zcat {} \; | grep -v "/$" | gawk '{ print "\t" $1 }'
            else    
              echo "no files available" 
            fi 
            ;;
          # find package 
          -f | --files)
            packages=`find $DB_ROOT -NAME '*.lst.gz'`
            for i in $packages; do 
              FILES=`zcat $i | egrep "$PARAMS"`
              if test -n "$FILES"; then
                PACKAGE_NAME=`echo $i | sed "s#.lst.gz##; s#$DB_ROOT/##;"`
                echo $PACKAGE_NAME
                for J in $FILES; do 
                  echo -e "\t" $J
                done
                echo 
              fi
            done
            ;;
          -d | --deps)
            for i in `echo $PARAMS`; do 
              build_dep_list "$i"
              echo "$RET"
            done
            ;;
          esac
          ;;
    # check files of a package 
    -c | --check)
      # get installed packages 
      packages=`cat $DB | grep -v "installed" | gawk '{ print db_root "/" $1 ".lst.gz" }' db_root=$DB_ROOT`
      for i in $packages; do 
        # get file list 
        FILES=`zcat $i | grep -v "/$i"`
        if test -n "$VERBOSE"; then 
          echo -n "checking package $i"
        fi 
  
        # create package name 
    
        # check if file is installed 
        REPAIR=""
        for J in $FILES; do 
          if test -f "/$J"; then
            echo ""
          else 
            REPAIR="1"
            echo "FILE $J is deleted" 
          fi
        done 
        if test -n "$REPAIR"; then 
          if test -n "$VERBOSE"; then 
            echo "... has to be repaired "
          else 
            echo "$i"
          fi
        else 
          echo "" 
        fi  
      done
      ;;      
  #    *)
  #      if test -z "$OPTION"; then
  #        echo "usage: $0 -q <package>"
  #        exit 1
  #      fi
  #      cat $DB | grep "$OPTION" | sed 's#.tar.*##g' | gawk '{ n = match($2,/-[0-9][^/a-zA-Z]/); if (n > 0) release=substr($2,n+1); if (release == "") release = "no release available"; printf("%-20s %s\n", $1,release) }' | sort
  #      ;;
  
    # search for packages in a local package tree 
    -l | --list)
        case $OPTION in 
          # all packages 
          -a | --all)
            list_all_packages
          ;;
          *) 
            for i in `echo $OPTION $PARAMS`; do 
              list_package "$i"
            done
          ;;
      esac
        ;;
  
    # install packages from a local package tree 
    -r | --reinstall)
      case $OPTION in 
        # all packages 
        -a | --all)
        ;;
        *)
        pkgname=""
        for i in `echo $OPTION $PARAMS`; do 
  # do not reinstall depending packages
  #        build_dep_list "$i"
          get_install_url_path "$i"
          install_packages "$RET"  
        done 
      esac
        ;;  
  
    # download source 
    -ds | --source)
        pkgname=""
        for i in `echo $OPTION $PARAMS`; do 
          get_source_url_path "$i"
          install_packages "$RET"  "source"
        done
        ;;
    
    # upgrade packages 
    -u | --upgrade)
      case $OPTION in 
        # all packages 
        -a | --all)
          list_packages_for_upgrade "" 
          get_install_url_path "$RET"
          #install_packages "$RET"
        ;;
        *)
        pkgname=""
        for i in `echo $OPTION $PARAMS`; do 
          list_packages_for_upgrade "$i"
          get_install_url_path "$RET"
          install_packages "$RET"  
        done 
      esac
        ;;  
  
  
    # install packages from a local package tree 
    -i | --install)
      process_args $PARAMS
      get_options_params $PARAMS
      
      case $OPTION in 
        # all packages 
        -a | --all)
        ;;
        *)
        pkgname=""
        for i in `echo $OPTION $PARAMS`; do 
          build_dep_list "$i"
          check_for_not_installed_packages "$RET"
          get_install_url_path "$RET"
          install_packages "$RET"
        done
      esac
        ;;  
  
    # remove installed package 
    -e | --erase)
      case $OPTION in 
        *)
        for i in `echo $OPTION $PARAMS`; do 
          echo $i
          remove_package_from_cygwin_db "$i"
        done 
      ;;
      esac
      ;;
  
    # help 
    -h | --help)
      print_help
        ;;    
    
  esac
  
  break
done
;;
esac
