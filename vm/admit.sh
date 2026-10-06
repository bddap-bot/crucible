exec 2>/dev/null
slot=0
until exec 9>>"$TMPDIR/admit.$slot" && flock -n 9; do
  ((++slot < 64)) || exit
done
lines=0
getline() { ((++lines <= 100)) && read -r -t 10 -n 8192 line && ((${#line} < 8192)); }
