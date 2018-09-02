alias showDABprogs='for f in `ls DAB_*.log`  ; do if [ $(grep -c "programnameHandler:" $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep "programnameHandler:" ; fi ; done'
alias showDABens='for f in `ls DAB_*.log`    ; do if [ $(grep -c "ensemblenameHandler:" $f) -gt 0 ]; then echo -e "\\n\\n$f\\n\\n" ; cat $f |grep "ensemblenameHandler:" ; fi ; done'
alias showFMpis='for f in `ls redsea.*.txt` ; do if [ $(grep -c \"pi\": $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep \"pi\": ; fi ; done'
alias showFMpss='for f in `ls redsea.*.txt` ; do if [ $(grep -c \"ps\": $f) -gt 0 ]; then echo -e "\\n***\\n*** $f\\n***\\n" ; cat $f |grep \"ps\": ; fi ; done'
