# reset-acls

Bash script to restore all acl permissions within a directory tree with those provided by a source acl directory

## Usage: reset-acls &lt;source acl directory&gt; [&lt;target acl directory&gt;]

**Examples:**
To copy the acl from /data/media to all its children

`reset-acls /data/media`

`reset-acls /data/media /data/media`

To copy the acl from /data/media to /data/music and all its children

`reset-acls /data/media /data/music`

## NOTES
- If only the source directory is provided then that directory will
be restored to the acl of the parent of the source.
- You must have appropriate permissions to be able to run this script
or it will not work (read/write/execute) on every directory and file within target
-The acl reset should not cross file systems by design, but I have not 
tested what happens with links yet
- All current acls are backed up before any changes are made so they
can be restored although all files and directories owner and group
names are changed to the source directory so it would be more
difficult to restore
- This script *should* honor the current settings of executable and non
executable files
- It may be possible to set up a cron job to automatically task

## PROCESS
- Target directory current acls are backed up so they can be restored
- All current acl properties are removed
- Target Files and directories are renamed to same as source
- Target is restored to same acl (access and default) as source

## TODO
- May add option not to rename files and directory user and group names automatically
- May require a prompt for users trying to restore a directory structure where the source does not have a default acl
- Don't allow source parent directory to have it acl changed on reset since it is the source and we do not want it messed up if something goes wrong
- Implement a way to prevent specific directory trees or files within the target from being updated.  I am thinking if a sub directory has the +T attribute then it and its children will not be reset.  Same goes for individual files
