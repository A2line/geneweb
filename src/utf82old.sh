#!/bin/sh

cat $1 |
sed -e 's/"/@/g' -e 's/\$/\$/g' |
awk '
BEGIN { enc="" }
function disp() {
    if (enc == "ar") ;
    else if (enc == "iso-8859-3")
        system("echo \"" $0 "\" | iconv -f utf-8 -t " enc " | sed -e 's/�/cx/g' -e 's/�/gx/g' -e 's/�/jx/g' -e 's/�/sx/g' -e 's/�/ux/g'")
    else if (enc == "iso-8859-8")
        system("echo \"" $0 "\" | iconv -f utf-8 -t " enc " | sed -e \"s/he: \\([����]\\)/he:  \\1/\" -e \"s|/\\([����]\\)|/ \\1|g\"")
    else if (enc == "lv")
        system("echo \"" $0 "\" | sed -e 's/�\\214/�/g' -e 's/�\\201/�/g' -e 's/�\\206/�/g' -e 's/ļ/�/g' -e 's/�\\215/�/g' -e 's/š/�/g' -e 's/ū/�/g' -e 's/�\\223/�/g' -e 's/Ģ/�/g' -e 's/ģ/�/g' -e 's/Ķ/�/g' -e 's/ī/�/g' -e 's/ķ/�/g' -e 's/þ/�/g'")
    else system("echo \"" $0 "\" | iconv -f utf-8 -t " enc);
    next;
}
function conv(t) { enc=t; disp() }
/^af: / { conv("iso-8859-1") }
/^ar: / { enc="ar"; next }
/^bg: / { conv("windows-1251") }
/^br: / { conv("iso-8859-1") }
/^ca: / { conv("iso-8859-1") }
/^cs: / { conv("iso-8859-2") }
/^da: / { conv("iso-8859-1") }
/^eo: / { conv("iso-8859-3") }
/^de: / { conv("iso-8859-1") }
/^es: / { conv("iso-8859-1") }
/^et: / { conv("iso-8859-15") }
/^fi: / { conv("iso-8859-1") }
/^fr: / { conv("iso-8859-1") }
/^fr-cr: / { conv("iso-8859-1") }
/^he: / { conv("iso-8859-8") }
/^is: / { conv("iso-8859-1") }
/^it: / { conv("iso-8859-1") }
/^lv: / { conv("lv") }
/^nl: / { conv("iso-8859-1") }
/^no: / { conv("iso-8859-1") }
/^pl: / { conv("iso-8859-2") }
/^pt: / { conv("iso-8859-1") }
/^pt-br: / { conv("iso-8859-1") }
/^ru: / { conv("windows-1251") }
/^sl: / { conv("iso-8859-2") }
/^sv: / { conv("iso-8859-1") }
/^zh: / { conv("gb2312") }
enc== "" { print; next }
/^  / { disp(); next }
{ enc=""; print; next }
' |
sed -e 's/@/"/g'
