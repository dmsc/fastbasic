#!/usr/bin/awk -f
BEGIN {
    if( ARGC > 1 )
    {
        lblfile = ARGV[1]
        ARGC = 1
    }
    else
        lblfile = "bin/fb.lbl"

    # add some basic labels
    lbl["2E5"]="MEMTOP"
    lbl["2E6"]="MEMTOP+1"
    lbl["342"]="ICCOM"
    lbl["343"]="ICSTA"
    lbl["344"]="ICBAL"
    lbl["345"]="ICBAH"
    lbl["346"]="ICPTL"
    lbl["347"]="ICPTH"
    lbl["348"]="ICBLL"
    lbl["349"]="ICBLH"
    lbl["34A"]="ICAX1"
    lbl["34B"]="ICAX2"
    while( getline < lblfile ) {
        if( $3 ~ /\.__/ )
            continue
        gsub(/^\./,"",$3)
        gsub(/^0+/,"",$2)
        if( $2 )
            lbl[$2]=$3
    }
    # Now, set "+1" labels
    for(addr in lbl)
    {
        l = lbl[addr]
        addr=sprintf("%X", ("0x" addr) + 1)
        if( ! lbl[addr] )
            lbl[addr] = l "+1"
    }
    # And "+2" labels
    for(addr in lbl)
    {
        l = lbl[addr]
        if( match(/\+1$/, l) )
            continue
        addr=sprintf("%X", ("0x" addr) + 2)
        if( ! lbl[addr] )
            lbl[addr] = l "+2"
    }
}

{
    gsub(/; /,"             ; ")
    match($0,/PC=([0-9A-F]*) /)
    pc = substr($0, RSTART+3, RLENGTH-4)
    gsub(/^0+/,"",pc)
    lcode = lbl[pc]
    if( match(lcode,/\+[12]/) )
        lcode = ""
    lcode = " " substr(lcode,1,11) ":               ";
    gsub(/ : /, substr(lcode,1,14))
    if( match($0,/ [(]?\$([0-9a-f][0-9a-f][0-9a-f]*)[)]?(,[XY])? /) ) {
        addr=substr($0, RSTART+2, RLENGTH-3)
        gsub(/[^0-9A-Fa-f]*/,"",addr)
        xaddr = addr
        gsub(/^0+/,"",xaddr)
        l=lbl[toupper(xaddr)]
        if( l != "" ) {
            # s = sprintf("%16.16s", l)
            sl="\\$" addr
            sb=15 - length(l) + length(addr) + 1
            gsub(sl, l)
            sbs=substr("                          ",1,sb)
            gsub(/               ; /, sbs "; ")
        }
    }
    print $0
}

