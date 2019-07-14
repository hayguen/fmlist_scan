
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
alias listDABens="cat scan_*_dab_ensemble.csv |awk -F, '{ OFS=\",\"; print \$7,\$8,\$9; }' |sort |uniq"
alias listDABprogs="cat scan_*_dab_audio.csv scan_*_dab_packet.csv | awk -F, '{ OFS=\",\"; print \$7,\$8,\$9,\$10,\$11; }' |sort |uniq"
alias listDABaudio="cat scan_*_dab_audio.csv | awk -F, '{ OFS=\",\"; print \$7,\$8,\$9,\$10,\$11; }' |sort |uniq"
alias listDABdata="cat scan_*_dab_packet.csv | awk -F, '{ OFS=\",\"; print \$7,\$8,\$9,\$10,\$11; }' |sort |uniq"

alias listFMp="cat scan_*_fm_rds.csv | awk -F, '{ OFS=\",\"; print \$3,\$13,\$15; }' |sort |uniq"



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

