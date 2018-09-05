
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

alias showDABprogs='for f in $( ls -1 DAB_*.log | sort )  ; do if [ $(grep -c "programnameHandler:" $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep "programnameHandler:" ; fi ; done'
alias showDABens='for f in $( ls -1 DAB_*.log | sort )    ; do if [ $(grep -c "ensemblenameHandler:" $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep "ensemblenameHandler:" ; fi ; done'

alias showFMpis='for f in $(ls -1 redsea.*.txt | awk -F. "{ print \$2 \" \" \$0; }" | sort -n | awk "{ print \$2; }" ) ; do if [ $(grep -c \"pi\": $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep \"pi\": ; fi ; done'
alias showFMpss='for f in $(ls -1 redsea.*.txt | awk -F. "{ print \$2 \" \" \$0; }" | sort -n | awk "{ print \$2; }" ) ; do if [ $(grep -c \"ps\": $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep \"ps\": ; fi ; done'
alias showFMp='for f in $(ls -1 redsea.*.txt | awk -F. "{ print \$2 \" \" \$0; }" | sort -n | awk "{ print \$2; }" ) ; do if [ $(grep -c \"ps\": $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |egrep "\"pi\":|\"ps\":" ; fi ; done'

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

