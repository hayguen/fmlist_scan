
# some more ls aliases
alias ll='ls -alF'
alias llh='ls -alhF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias gst='git status'
alias gco='git checkout'
alias gu='git pull --rebase'
alias gp='git push'
alias gss='git stash save'
alias gsa='git stash apply'
alias gsl='git stash list'

alias showDABprogs='for f in $( ls -1 DAB_*.log | sort )  ; do if [ $(grep -c "programnameHandler:" $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep "programnameHandler:" ; fi ; done'
alias showDABens='for f in $( ls -1 DAB_*.log | sort )    ; do if [ $(grep -c "ensemblenameHandler:" $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep "ensemblenameHandler:" ; fi ; done'

alias showFMpis='for f in $(ls -1 redsea.*.txt | awk -F. "{ print \$2 \" \" \$0; }" | sort -n | awk "{ print \$2; }" ) ; do if [ $(grep -c \"pi\": $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep \"pi\": ; fi ; done'
alias showFMpss='for f in $(ls -1 redsea.*.txt | awk -F. "{ print \$2 \" \" \$0; }" | sort -n | awk "{ print \$2; }" ) ; do if [ $(grep -c \"ps\": $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep \"ps\": ; fi ; done'
alias showFMp='for f in $(ls -1 redsea.*.txt | awk -F. "{ print \$2 \" \" \$0; }" | sort -n | awk "{ print \$2; }" ) ; do if [ $(grep -c \"ps\": $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |egrep "\"pi\":|\"ps\":" ; fi ; done'

# list* aliases for execution in the date folders, e.g. /mnt/sda1/fmlist_scanner/2019-07-14/
alias listDABens="cat scan_*_dab_ensemble.csv |awk -F, '{ OFS=\",\"; print \$7,\$8,\$9; }' |sort -n |uniq -c"
alias listDABensTii="cat scan_*_dab_ensemble.csv |awk -F, '{ OFS=\",\"; printf(\"%s%s%s%s%s%s\",\$7,OFS,\$8,OFS,\$9,OFS); for(i=21;i<=NF;i+=6) printf(\"%s%s\",\$i,OFS); printf(\"%s\",RS); }' |sort -n |uniq -c"

alias listDABprogs="cat scan_*_dab_audio.csv scan_*_dab_packet.csv | awk -F, '{ OFS=\",\"; print \$7,\$8,\$9,\$10,\$11; }' |sort |uniq"
alias listDABaudio="cat scan_*_dab_audio.csv | awk -F, '{ OFS=\",\"; print \$7,\$8,\$9,\$10,\$11; }' |sort |uniq"
alias listDABdata="cat scan_*_dab_packet.csv | awk -F, '{ OFS=\",\"; print \$7,\$8,\$9,\$10,\$11; }' |sort |uniq"
alias listDABfound='for f in $(ls -1 *_DAB.zip) ; do echo -n "$f : " ; 7z x -so $f $( unzip -l $f |grep scan_duration.txt |awk "{ print \$4; }" ) |grep "DAB scan found" ; done'
alias listDABdur='for f in $(ls -1 *_DAB.zip) ; do echo -n "$f : " ; 7z x -so $f $( unzip -l $f |grep scan_duration.txt |awk "{ print \$4; }" ) |grep "DAB scan duration" ; done'

function listDABch() {
  cat scan_*_dab_ensemble.csv | grep -i ",\"$1\"," | sort -n
}

function listDABeid() {
  cat scan_*_dab_ensemble.csv | grep -i ",0x$1," | sort -n
}


alias listFMp="cat scan_*_fm_rds.csv | awk -F, '{ OFS=\",\"; print \$3,\$13,\$15; }' |sort -n |uniq"

alias listFMcmpPS="cat scan_*_fm_rds.csv | awk -F, '{ OFS=\",\"; print \$3,\$13,\$15; }' |sort -n |uniq -c"
alias listFMcmpPI="cat scan_*_fm_rds.csv | awk -F, '{ OFS=\",\"; print \$3,\$13; }' |sort -n |uniq -c"

alias listFMbySnrL="cat scan_*_fm_rds.csv | awk -F, '{ OFS=\",\"; print \$5,\$6,\$3,\$13,\$15; }' |sort -n | awk -F, '{ OFS=\",\"; print \$3,\$4,\$5,\$1,\$2; }' |uniq"
alias listFMbySnrR="cat scan_*_fm_rds.csv | awk -F, '{ OFS=\",\"; print \$6,\$5,\$3,\$13,\$15; }' |sort -n | awk -F, '{ OFS=\",\"; print \$3,\$4,\$5,\$2,\$1; }' |uniq"
alias listFMbySnrS="cat scan_*_fm_rds.csv | awk -F, '{ OFS=\",\"; print \$5+\$6,\$5,\$6,\$3,\$13,\$15; }' |sort -n | awk -F, '{ OFS=\",\"; print \$4,\$5,\$6,\$2,\$3,int(\$1/2); }' |uniq"

function listFMPIbySnrL() {
  cat scan_*_fm_rds.csv |awk -F, "{ if (\$13 == \"0x$1\") print \$0; }" | awk -F, '{ OFS=","; print $5,$6,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $3,$4,$5,$1; }' |uniq
}
function listFMPIbySnrR() {
  cat scan_*_fm_rds.csv |awk -F, "{ if (\$13 == \"0x$1\") print \$0; }" | awk -F, '{ OFS=","; print $6,$5,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $3,$4,$5,$1; }' |uniq
}
function listFMPIbySnrS() {
  cat scan_*_fm_rds.csv |awk -F, "{ if (\$13 == \"0x$1\") print \$0; }" | awk -F, '{ OFS=","; print $5+$6,$5,$6,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $4,$5,$6,int($1/2); }' |uniq
}

function listFMfreqBySnrL() {
  cat scan_*_fm_rds.csv |awk -F, "{ if (\$3 == \"${1}000\") print \$0; }" | awk -F, '{ OFS=","; print $5,$6,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $3,$4,$5,$1; }' |uniq
}
function listFMfreqBySnrR() {
  cat scan_*_fm_rds.csv |awk -F, "{ if (\$3 == \"${1}000\") print \$0; }" | awk -F, '{ OFS=","; print $6,$5,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $3,$4,$5,$1; }' |uniq
}
function listFMfreqBySnrS() {
  cat scan_*_fm_rds.csv |awk -F, "{ if (\$3 == \"${1}000\") print \$0; }" | awk -F, '{ OFS=","; print $5+$6,$5,$6,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $4,$5,$6,int($1/2); }' |uniq
}

function listFMfreqs() {
  cat scan_*_fm_rds.csv |awk -F, '{ OFS=","; print $3; }' |sort -n |uniq |sed 's/...$//g'
}

function listFMfreqsByMinSnrL() {
  for freq in $( listFMfreqs ) ; do  listFMfreqBySnrL $freq |head -n 1  ; done
}
function listFMfreqsByMinSnrR() {
  for freq in $( listFMfreqs ) ; do  listFMfreqBySnrR $freq |head -n 1  ; done
}
function listFMfreqsByMinSnrS() {
  for freq in $( listFMfreqs ) ; do  listFMfreqBySnrS $freq |head -n 1  ; done
}

function listFMfreqsByMaxSnrL() {
  for freq in $( listFMfreqs ) ; do  listFMfreqBySnrL $freq |tail -n 1  ; done
}
function listFMfreqsByMaxSnrR() {
  for freq in $( listFMfreqs ) ; do  listFMfreqBySnrR $freq |tail -n 1  ; done
}
function listFMfreqsByMaxSnrS() {
  for freq in $( listFMfreqs ) ; do  listFMfreqBySnrS $freq |tail -n 1  ; done
}


function lastFMPIbySnrL() {
  N="$2"
  if [ -z "$N" ]; then N="1" ; fi
  FILES=$( ls -1 scan_*_fm_rds.csv | sort | tail -n $N )
  cat ${FILES} |awk -F, "{ if (\$13 == \"0x$1\") print \$0; }" | awk -F, '{ OFS=","; print $5,$6,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $3,$4,$5,$1; }' |uniq
}
function lastFMPIbySnrR() {
  N="$2"
  if [ -z "$N" ]; then N="1" ; fi
  FILES=$( ls -1 scan_*_fm_rds.csv | sort | tail -n $N )
  cat ${FILES} |awk -F, "{ if (\$13 == \"0x$1\") print \$0; }" | awk -F, '{ OFS=","; print $6,$5,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $3,$4,$5,$1; }' |uniq
}
function lastFMPIbySnrS() {
  N="$2"
  if [ -z "$N" ]; then N="1" ; fi
  FILES=$( ls -1 scan_*_fm_rds.csv | sort | tail -n $N )
  cat ${FILES} |awk -F, "{ if (\$13 == \"0x$1\") print \$0; }" | awk -F, '{ OFS=","; print $5+$6,$5,$6,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $4,$5,$6,int($1/2); }' |uniq
}

function lastFMfreqBySnrL() {
  N="$2"
  if [ -z "$N" ]; then N="1" ; fi
  FILES=$( ls -1 scan_*_fm_rds.csv | sort | tail -n $N )
  cat ${FILES} |awk -F, "{ if (\$3 == \"${1}000\") print \$0; }" | awk -F, '{ OFS=","; print $5,$6,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $3,$4,$5,$1; }' |uniq
}
function lastFMfreqBySnrR() {
  N="$2"
  if [ -z "$N" ]; then N="1" ; fi
  FILES=$( ls -1 scan_*_fm_rds.csv | sort | tail -n $N )
  cat ${FILES} |awk -F, "{ if (\$3 == \"${1}000\") print \$0; }" | awk -F, '{ OFS=","; print $6,$5,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $3,$4,$5,$1; }' |uniq
}
function lastFMfreqBySnrS() {
  N="$2"
  if [ -z "$N" ]; then N="1" ; fi
  FILES=$( ls -1 scan_*_fm_rds.csv | sort | tail -n $N )
  cat ${FILES} |awk -F, "{ if (\$3 == \"${1}000\") print \$0; }" | awk -F, '{ OFS=","; print $5+$6,$5,$6,$3,$13,$15; }' |sort -n | awk -F, '{ OFS=","; print $4,$5,$6,int($1/2); }' |uniq
}

function lastFMfreqs() {
  N="$1"
  if [ -z "$N" ]; then N="1" ; fi
  FILES=$( ls -1 scan_*_fm_rds.csv | sort | tail -n $N )
  cat ${FILES} |awk -F, '{ OFS=","; print $3; }' |sort -n |uniq |sed 's/...$//g'
}

function lastFMfreqsByMinSnrLu() {
  for freq in $( lastFMfreqs $1 ) ; do  lastFMfreqBySnrL $freq $1 |head -n 1  ; done
}
function lastFMfreqsByMinSnrRu() {
  for freq in $( lastFMfreqs $1 ) ; do  lastFMfreqBySnrR $freq $1 |head -n 1  ; done
}
function lastFMfreqsByMinSnrSu() {
  for freq in $( lastFMfreqs $1 ) ; do  lastFMfreqBySnrS $freq $1 |head -n 1  ; done
}

function lastFMfreqsByMaxSnrLu() {
  for freq in $( lastFMfreqs $1 ) ; do  lastFMfreqBySnrL $freq $1 |tail -n 1  ; done
}
function lastFMfreqsByMaxSnrRu() {
  for freq in $( lastFMfreqs $1 ) ; do  lastFMfreqBySnrR $freq $1 |tail -n 1  ; done
}
function lastFMfreqsByMaxSnrSu() {
  for freq in $( lastFMfreqs $1 ) ; do  lastFMfreqBySnrS $freq $1 |tail -n 1  ; done
}


function lastFMfreqsByMinSnrL() {
  lastFMfreqsByMinSnrLu $1 |awk -F, '{ OFS=","; print $4,$1,$2,$3; }' |sort -n |awk -F, '{ OFS=","; print $2,$3,$4,$1; }'
}
function lastFMfreqsByMinSnrR() {
  lastFMfreqsByMinSnrRu $1 |awk -F, '{ OFS=","; print $4,$1,$2,$3; }' |sort -n |awk -F, '{ OFS=","; print $2,$3,$4,$1; }'
}
function lastFMfreqsByMinSnrS() {
  lastFMfreqsByMinSnrSu $1 |awk -F, '{ OFS=","; print $4,$1,$2,$3; }' |sort -n |awk -F, '{ OFS=","; print $2,$3,$4,$1; }'
}

function lastFMfreqsByMaxSnrL() {
  lastFMfreqsByMaxSnrLu $1 |awk -F, '{ OFS=","; print $4,$1,$2,$3; }' |sort -n |awk -F, '{ OFS=","; print $2,$3,$4,$1; }'
}
function lastFMfreqsByMaxR() {
  lastFMfreqsByMaxSnrRu $1 |awk -F, '{ OFS=","; print $4,$1,$2,$3; }' |sort -n |awk -F, '{ OFS=","; print $2,$3,$4,$1; }'
}
function lastFMfreqsByMaxSnrS() {
  lastFMfreqsByMaxSnrSu $1 |awk -F, '{ OFS=","; print $4,$1,$2,$3; }' |sort -n |awk -F, '{ OFS=","; print $2,$3,$4,$1; }'
}

alias listFMfound='for f in $(ls -1 *_FM.zip) ; do echo -n "$f : " ; 7z x -so $f $( unzip -l $f |grep scan_duration.txt |awk "{ print \$4; }" ) |grep "FM scan found" ; done'
alias listFMdur='for f in $(ls -1 *_FM.zip) ; do echo -n "$f : " ; 7z x -so $f $( unzip -l $f |grep scan_duration.txt |awk "{ print \$4; }" ) |grep "FM scan duration" ; done'
alias listFMddcs='for f in $(ls -1 *_FM.zip) ; do echo -n "$f : " ; 7z x -so $f $( unzip -l $f |grep scan_duration.txt ) |grep "^ddc freqs are" ; done'


function showZipDABprogs {
  rm -rf $HOME/ram/tempDAB &>/dev/null
  mkdir -p $HOME/ram/tempDAB
  unzip -j $1 -d $HOME/ram/tempDAB &>/dev/null
  pushd $HOME/ram/tempDAB &>/dev/null
  for f in $( ls -1 DAB_*.log | sort )  ; do
    if [ $(grep -c "programnameHandler:" $f) -gt 0 ]; then
      echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep "programnameHandler:"
    fi
  done
  popd &>/dev/null
}

function showZipFMp {
  rm -rf $HOME/ram/tempFM &>/dev/null
  mkdir -p $HOME/ram/tempFM
  unzip -j $1 -d $HOME/ram/tempFM &>/dev/null
  pushd $HOME/ram/tempFM &>/dev/null
  for f in $(ls -1 redsea.*.txt | awk -F. "{ print \$2 \" \" \$0; }" | sort -n | awk "{ print \$2; }" ) ; do
    if [ $(grep -c \"ps\": $f) -gt 0 ]; then
      echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |egrep "\"pi\":|\"ps\":"
    fi
  done
  popd &>/dev/null
}

alias scanLog="echo -e 'abort with Ctrl-C\n' ; sleep 2 ; tail -f /dev/shm/$(whoami)_fmlist_scan/scanner.log"
alias scanScreen="echo -e 'abort with Ctrl-A D\n' ; sleep 2 ; screen -r scanLoopBg"

