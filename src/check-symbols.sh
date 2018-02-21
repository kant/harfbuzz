#!/bin/sh

LC_ALL=C
export LC_ALL

test -z "$srcdir" && srcdir=.
test -z "$libs" && libs=.libs
stat=0

IGNORED_SYMBOLS='_fini\>\|_init\>\|_fdata\>\|_ftext\>\|_fbss\>\|__bss_start\>\|__bss_start__\>\|__bss_end__\>\|_edata\>\|_end\>\|_bss_end__\>\|__end__\>\|__gcov_flush\>\|llvm_'

if which nm 2>/dev/null >/dev/null; then
	:
else
	echo "check-symbols.sh: 'nm' not found; skipping test"
	exit 77
fi

tested=false
for soname in harfbuzz harfbuzz-subset harfbuzz-icu harfbuzz-gobject; do
	for suffix in so dylib; do
		so=$libs/lib$soname.$suffix
		if ! test -f "$so"; then continue; fi

		# On macOS, C symbols are prefixed with _
		if test $suffix = dylib; then prefix="_$prefix"; fi

		EXPORTED_SYMBOLS="`nm "$so" | grep ' [BCDGINRSTVW] .' | grep -v " \\($IGNORED_SYMBOLS\\)" | cut -d' ' -f3 | c++filt`"

		prefix=`basename "$so" | sed 's/libharfbuzz/hb/; s/-/_/g; s/[.].*//'`


		echo
		echo "Checking that $so does not expose internal symbols"
		if echo "$EXPORTED_SYMBOLS" | grep -v "^${prefix}\(_\|$\)"; then
			echo "Ouch, internal symbols exposed"
			stat=1
		fi

		tested=true
	done
done
if ! $tested; then
	echo "check-symbols.sh: no shared libraries found; skipping test"
	exit 77
fi

exit $stat
