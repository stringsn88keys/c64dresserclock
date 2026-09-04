1 poke56,peek(56)-4:clr
2 rem ponytail: rs232 open allocates its rx/tx buffers at the current top of
3 rem basic memory, stomping whatever variables basic already put there (sr/
4 rem sc/pr/pc went to 0 mid-program) - reserve 4 pages before any variable
5 rem copal-style dresser flip clock (c64 port)
6 rem time comes over userport rs232 (device 2) from a host tcp time server
7 rem ponytail: screen/color ram pokes approximate flipping cards, not real animation
8 rem ponytail: chr$(17)/chr$(19) (cursor-down/home) are also the rs232 xon/xoff
9 rem bytes - printing them for cursor positioning gets intercepted once rs232 is
10 rem open, so position via direct poke (gosub9000) instead of print+cursor-keys
11 rem ponytail: once rs232 is open, a lookup of a variable that hasn't been
12 rem touched in a while (sr, or an array index like dg$(dv,r)) comes back
13 rem wrong - rs232's nmi handler likely interrupts the scan mid-step. the 6
14 rem fixed positions used after open are hardcoded literal addresses below,
15 rem the digit array is gone in favor of ga$-ge$ + a char lookup, and the
16 rem hour math is a literal table instead of a mod-12 calculation
22 rem ponytail: ga$-ge$ (glyph blocks) get reassigned fresh every pass of the
23 rem main loop (405) rather than defined once here - a variable read long
24 rem after it was last touched is what goes wrong once rs232 is open, so
25 rem these are kept "recently touched" instead of relying on their very
26 rem first assignment surviving untouched for the rest of the run
70 print chr$(147);
80 poke53280,9:poke53281,0
90 bx=3:by=6:bw=34:bh=14:sc=5:sr=9
100 b$=chr$(18):for i=1 to bw:b$=b$+" ":next i:b$=b$+chr$(146)
110 cl=9
120 ad=1024+by*40+bx:cd=55296+by*40+bx:s$=b$:gosub9000
130 ad=1024+(by+1)*40+bx:cd=55296+(by+1)*40+bx:s$=b$:gosub9000
140 ad=1024+(by+bh-2)*40+bx:cd=55296+(by+bh-2)*40+bx:s$=b$:gosub9000
150 ad=1024+(by+bh-1)*40+bx:cd=55296+(by+bh-1)*40+bx:s$=b$:gosub9000
155 for r=by+2 to by+bh-3
156 ad=1024+r*40+bx:cd=55296+r*40+bx:s$=chr$(18)+"  "+chr$(146):gosub9000
157 ad=1024+r*40+bx+bw-2:cd=55296+r*40+bx+bw-2:s$=chr$(18)+"  "+chr$(146):gosub9000
158 next r
160 cl=1
170 ad=1024+16*40+sc:cd=55296+16*40+sc:s$="copal":gosub9000
180 open2,2,0,chr$(8)+chr$(0)
190 cl=2
200 ad=1349:cd=55621:s$="connecting...":gosub9000
210 t$="":lh$="":lm$=""
220 rem --- main loop: read one line from rs232, redraw on change ---
230 get#2,a$
240 ifa$=""then230
250 ifa$<>chr$(13)then t$=t$+a$:goto230
260 iflen(t$)<>8then t$="":goto230
262 ifmid$(t$,3,1)<>":"then t$="":goto230
264 ifmid$(t$,6,1)<>":"then t$="":goto230
270 hh$=left$(t$,2):mm$=mid$(t$,4,2):t$=""
280 ifhh$=lh$andmm$=lm$then230
290 lh$=hh$:lm$=mm$
300 h=val(hh$)
310 rem ponytail: hn$ is the 12-hour display value, space-padded ("  1".."12")
315 rem so a single-digit hour's blank tens place falls out of the table free
320 ifh=0thenhn$="12":ap$="am"
321 ifh=1thenhn$=" 1":ap$="am"
322 ifh=2thenhn$=" 2":ap$="am"
323 ifh=3thenhn$=" 3":ap$="am"
324 ifh=4thenhn$=" 4":ap$="am"
325 ifh=5thenhn$=" 5":ap$="am"
326 ifh=6thenhn$=" 6":ap$="am"
327 ifh=7thenhn$=" 7":ap$="am"
328 ifh=8thenhn$=" 8":ap$="am"
329 ifh=9thenhn$=" 9":ap$="am"
331 ifh=10thenhn$="10":ap$="am"
332 ifh=11thenhn$="11":ap$="am"
333 ifh=12thenhn$="12":ap$="pm"
334 ifh=13thenhn$=" 1":ap$="pm"
335 ifh=14thenhn$=" 2":ap$="pm"
336 ifh=15thenhn$=" 3":ap$="pm"
337 ifh=16thenhn$=" 4":ap$="pm"
338 ifh=17thenhn$=" 5":ap$="pm"
339 ifh=18thenhn$=" 6":ap$="pm"
341 ifh=19thenhn$=" 7":ap$="pm"
342 ifh=20thenhn$=" 8":ap$="pm"
343 ifh=21thenhn$=" 9":ap$="pm"
344 ifh=22thenhn$="10":ap$="pm"
345 ifh=23thenhn$="11":ap$="pm"
380 cl=1
390 ad=1349:cd=55621:s$="                ":gosub9000
400 ad=1349:cd=55621:s$=ap$:gosub9000
410 for r=0 to 4
420 dc$=mid$(hn$,1,1):gosub8000:l$=g$
430 dc$=mid$(hn$,2,1):gosub8000:l$=l$+" "+g$
440 co$="  ":ifr=1orr=3thenco$=chr$(18)+"  "+chr$(146)
450 l$=l$+" "+co$+" "
460 dc$=mid$(mm$,1,1):gosub8000:l$=l$+g$
470 dc$=mid$(mm$,2,1):gosub8000:l$=l$+" "+g$
475 ifr=0thenad=1389:cd=55661
476 ifr=1thenad=1429:cd=55701
477 ifr=2thenad=1469:cd=55741
478 ifr=3thenad=1509:cd=55781
479 ifr=4thenad=1549:cd=55821
480 s$=l$:gosub9000
490 next r
500 goto230
7900 rem ponytail: ga$-ge$ recomputed fresh on every gosub8000 call rather
7901 rem than defined once - see the note by line22 for why a variable that
7902 rem hasn't been read/written in a while comes back wrong once rs232 is
7903 rem open, and this gets called ~20 times per redraw
8000 rem cell subroutine: in dc$(one digit char, or space=blank),r  out g$
8001 ga$=chr$(18)+"  "+chr$(146)+chr$(18)+"  "+chr$(146)+chr$(18)+"  "+chr$(146)
8002 gb$=chr$(18)+"  "+chr$(146)+"  "+chr$(18)+"  "+chr$(146)
8003 gc$="  "+chr$(18)+"  "+chr$(146)+"  "
8004 gd$="    "+chr$(18)+"  "+chr$(146)
8005 ge$=chr$(18)+"  "+chr$(146)+"    "
8006 ifdc$=" "theng$="      ":return
8007 ifdc$="0"thendp$="ABBBA"
8008 ifdc$="1"thendp$="CCCCC"
8009 ifdc$="2"thendp$="ADAEA"
8011 ifdc$="3"thendp$="ADADA"
8012 ifdc$="4"thendp$="BBADD"
8013 ifdc$="5"thendp$="AEADA"
8014 ifdc$="6"thendp$="AEABA"
8016 ifdc$="7"thendp$="ADDDD"
8017 ifdc$="8"thendp$="ABABA"
8018 ifdc$="9"thendp$="ABADA"
8020 pn$=mid$(dp$,r+1,1)
8021 ifpn$="A"theng$=ga$:return
8022 ifpn$="B"theng$=gb$:return
8023 ifpn$="C"theng$=gc$:return
8024 ifpn$="D"theng$=gd$:return
8025 g$=ge$:return
9000 rem pokestr: draw s$ starting at screen ad, color cd, in color cl
9010 rv=0
9020 for ii=1 to len(s$)
9030 c$=mid$(s$,ii,1)
9040 ifc$=chr$(18)thenrv=128:goto9080
9050 ifc$=chr$(146)thenrv=0:goto9080
9060 cc=asc(c$):ifcc>64andcc<91thencc=cc-64
9070 pokead,cc+rv:pokecd,cl:ad=ad+1:cd=cd+1
9080 next ii
9090 return
