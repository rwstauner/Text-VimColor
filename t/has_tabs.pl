# Perl script containing tabs.

if (@ARGV) {
	for (1 .. shift) {
		print "Number $_",
		      "\n";
	}
}
