BEGIN { counter = 0; }
/.*/ {
	if (counter == 0) {
		prev_line = $0;
		counter = 1;
	} else if ( prev_line == $0 ) {
		counter = counter + 1;
	} else {
		print counter, prev_line;
		prev_line = $0;
		counter = 1;
	}
}
END {
	if (counter > 0)
		print counter, prev_line;
}
