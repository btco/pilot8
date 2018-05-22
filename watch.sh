#!/bin/bash
echo "Watching pilot8.lua..."
last_mtime="not_yet_computed"
i=0

if [ "$(uname)" == "Darwin" ]; then
  # MacOS stat command.
  stat_cmd="stat -f %m"
else
  # Linux stat command.
  stat_cmd="stat -c %Y"
fi

while true; do
  this_mtime=`$stat_cmd pilot8.lua`
  if [ "$this_mtime" != "$last_mtime" ]; then
    last_mtime="$this_mtime"
    bash go.sh
    echo "[$i]"
    ((i++))
  fi
  sleep 3
done
