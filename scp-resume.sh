#!/bin/sh
#
# Speed improvements by using blocks by nitro.tm@gmail.com
#
# This script assumes that you have access to the 'dd' utility
# on both the local and remote host.

# dd transfer blocksize (8192 by default)
blocksize=8192

usage()
{
  echo
  echo "Usage: `basename $0` -u(pload)   \$localfile  \$remotefile [\$sshargs]"
  echo "       `basename $0` -d(ownload) \$remotefile \$localfile  [\$sshargs]"
  echo
  echo "  \$remotefile should be in the scp format, i.e.: [user@]host:filename"
  echo "  \$sshargs are option further ssh options such as a port specification"
  echo "     (-p 1234) or use of compression (-C)"
  echo
  echo "  -u:"
  echo "     \$remotefile may be [user@]host: for uploading to your remote home directory"
  echo "  -d:"
  echo "     \$localfile may be a period (.) when downloading a remote file to the"
  echo "       current working directory."
  echo
  exit 1
}

[ -z "$1" -o -z "$2" -o -z "$3" ] && usage

option=$1
case $option in
  -[uU]*)
    localfile=$2
    remote=$3
    shift 3
    sshargs="$*"

    userhost=${remote%:*}
    remotefile=${remote#*:}

    if [ ! -f "$localfile" ]; then
      echo "!! File not found: $localfile"
      usage
    fi
    if [ x"$userhost" = x"$remote" ]; then usage; fi
    if [ x"$remotefile" = x"$remote" -o -z "$remotefile" ]; then remotefile=`basename "$localfile"`; fi

    echo "==>> Getting size of remote file:"
    localsize=`ls -l "${localfile}" | awk '{ print $5 }'`
    remotesize=`ssh $sshargs "$userhost" "[ -f \"${remotefile}\" ] && ls -l \"${remotefile}\"" | awk '{ print $5 }' `

    [ -z "$remotesize" ] && remotesize=0
    echo "=> Remote filesize: $remotesize bytes"
    
    if [ $localsize -eq $remotesize ]; then
      echo "=> Local size equals remote size, nothing to transfer."
      exit 0;
    fi
    
    remainder=$((remotesize % blocksize))
    restartpoint=$((remotesize - remainder))
    blockstransferred=$((remotesize / blocksize))
    
    echo "=> Resuming upload of '$localfile'"
    echo "  at byte: $restartpoint ($blockstransferred blocks x $blocksize bytes/block),"
    echo "  will overwrite the trailing $remainder bytes."

    dd bs=$blocksize skip=$blockstransferred "if=${localfile}" | \
      ssh $sshargs "$userhost" "dd bs=$blocksize seek=$blockstransferred of=\"$remotefile\""

    echo "done."
    ;;
  -[dD]*)
    localfile=$3
    remote=$2
    shift 3
    sshargs="$*"

    userhost=${remote%:*}
    remotefile=${remote#*:}

    if [ x"$localfile" = x"." ]; then localfile=`basename "$remotefile"`; fi
    if [ ! -f "$localfile" ]; then
      localsize=0;
    else
      localsize=`ls -l "${localfile}" | awk '{ print $5 }'`
    fi
    [ x"$remotefile" = x"$remote" ] && usage
    [ -z "$localsize" ] && localsize=0

    remainder=$((localsize % blocksize))
    restartpoint=$((localsize - remainder))
    blockstransferred=$((localsize / blocksize))
    
    echo "=> Resuming download of '$localfile'"
    echo "  at byte: $restartpoint ($blockstransferred blocks x $blocksize bytes/block)"
    echo "  filesize: $localsize; will overwrite the trailing $remainder bytes."
    ssh $sshargs "$userhost" "dd bs=$blocksize skip=$blockstransferred \"if=${remotefile}\"" |
      dd bs=$blocksize seek=$blockstransferred "of=$localfile"

    ;;
  *)
    usage
    ;;
esac

