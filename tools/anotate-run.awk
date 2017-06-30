#!/usr/bin/awk -f
BEGIN {
    while( getline < "fastbasic.lbl" ) {
        gsub(/^\./,"",$3)
        lbl[$2]=$3
    }
}

{
    gsub(/; /,"        ; ")
    match($0,/PC=([0-9A-F]*) /,m);
    lcode = lbl["00" m[1]]
    lcode = " " substr(lcode,1,11) ":               ";
    gsub(/\> : \</, substr(lcode,1,14))
    if( match($0,/ \$([0-9a-f][0-9a-f][0-9a-f]*)(,[XY])?        /,m) ) {
        addr="000000" m[1];
        addr=toupper(substr(addr,length(addr)-5,6))
        l=lbl[addr]
        if( l ) {
            # s = sprintf("%16.16s", l)
            sl="\\$" m[1] "\\>"
            sb=10 - length(l) + length(m[1]) + 1
            gsub(sl, l)
            sbs=substr("              ",1,sb)
            gsub(/          ; /, sbs "; ")
        }
    }
    print $0
}

