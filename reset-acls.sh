#!/bin/bash
#
# reset-acls - recursively reset acls from a target acl directory
# version 0.11 (February 28, 2014)
# Copyright (C) 2014 Jason Mehring
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#
# Usage: reset-acls <source acl directory> [<target acl directory>]
#

if [ ! "$1" ]; then
  echo "restore-acl source-acl(directory) [target directory to restore]"
  echo "Exiting"
  exit
fi

[ "$2" ] && TARGET=1

if [ "$3" ]; then
  echo "too many arguments, exiting"
  echo "restore-acl source-acl(directory) [target directory to restore]"
  exit
fi

if [ ! -d "$1" ]; then
  echo "$1 is not a source directory, exiting"
  exit
fi

if [ "$TARGET" = "1" -a ! -d "$2" ]; then
  echo "$2 is not a target directory, exiting"
  exit
fi

SOURCE=$1
[ "$2" ] && TARGET=$2 || TARGET=$1

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d-%H-%M-%S"
}

# Backup original acl structure
TIMESTAMP=$(timestamp)
getfacl -R "$SOURCE" > "acl.backup-$TIMESTAMP"

# Get the master ACL
ACL=$(getfacl "$SOURCE")
ACL_ACCESS=$(getfacl -a "$SOURCE")
ACL_DEFAULT=$(getfacl -d "$SOURCE")

export ACL
export ACL_ACCESS
export ACL_DEFAULT

# Remove all existing ACL's
setfacl -bR "$TARGET"

# Change ownership recursively to match source
chown -R --reference="$SOURCE" "$TARGET"

# Ensure user 'x' mask gets set
function modify_file_executable {
   local _acl=$ACL_ACCESS
   _acl=$(echo "$_acl" | sed 's/\(^user::..\)\(.\)/\1x/')
   echo "$_acl" | setfacl --set-file=- "$1"
   return 1
}
export -f modify_file_executable

# Remove all executable permissions on user and mask
function modify_file {
   local _acl=$ACL_ACCESS
   _acl=$(echo "$_acl" | sed 's/\(^user::..\)\(.\)/\1-/')
   _acl=$(echo "$_acl" | sed 's/\(^group::..\)\(.\)/\1-/')
   _acl=$(echo "$_acl" | sed 's/\(^other::..\)\(.\)/\1-/')
   _acl=$(echo "$_acl" | sed 's/\(^mask::..\)\(.\)/\1-/')
   echo "$_acl" | setfacl --set-file=- "$1"
   return 1
}
export -f modify_file

# Ensure user 'x' mask gets set
function modify_directory {
   local _acl=$ACL
   echo "$_acl" | setfacl --set-file=- "$1"
   return 1
}
export -f modify_directory

find "$TARGET" -xdev \
     \( -type f -executable -exec bash -c 'modify_file_executable "$1"' - '{}' \; \) \
  -o \( -type d -exec bash -c 'modify_directory "$1"' - '{}' \; \) \
  -o \( -type f ! -executable -exec bash -c 'modify_file "$1"' - '{}' \; \)
