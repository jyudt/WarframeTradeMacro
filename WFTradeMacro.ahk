#SingleInstance force
#Persistent

#Include  <JSON>
#include <Vis2>

global mxpos := 0
global mypos := 0
global itemList := []
;list of [item name, ducats, price, isToday]
global relicList := []
;list of [relic name, vaulted]
;1=vaulted, 0=not
global myItems := []
global myRelics := []
global vaultedRelics := []
global DefaultDucatValue:=5

ToolTip Starting Warframe Trade Macro

;update tables
updateItemTable()
updateRelicTable()

;loads configs
Iniread, HKVRewSel, Hotkeys.ini, settings, RewardSelectorHK, ^k
Hotkey, %HKVRewSel%,doRewardSel,On

Iniread, HKVDucMan, Hotkeys.ini, settings, DucatManagerHK, ^b
Hotkey, %HKVDucMan%,doDucatMan,On
Iniread, DefaultDucatValue, Hotkeys.ini, settings, DefaultDucatValue, 5

Iniread, HKVRelMan, Hotkeys.ini, settings, RelicManager, ^j
Hotkey, %HKVRelMan%,doRelicMan,On

Iniread, HKVExit, Hotkeys.ini, settings, ExitProg, ^!e
Hotkey, %HKVExit%,ExitProg,On

ToolTip

;~~~~~ Tooltip 
doRTT:
MouseGetPos, mx, my
RToolTip(mx,my)
return

RemoveToolTip:
ToolTip
return

RToolTip(mx, my){
	if(Abs(mxpos-mx)<50 && Abs(mypos-my)<50){
		;~ Don't remove tooltip
	} else {
		ToolTip
		SetTimer, doRTT, Off
	}
	
	return
}

;~~~~~ Table Updating
updateItemTable(){
	MyJsonInstance := new JSON()
	myApi := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
	myURL:= "https://tenno.zone/data/"
	myApi.Open("GET", myURL, false)
	myApi.Send()
	Response := JSON.load(myApi.ResponseText)
	tZoneJsonDumpFile := A_ScriptDir "\temps\tZoneDump.txt"
	FileDelete %tZoneJsonDumpFile%
	tZoneDump:=JSON.Dump(Response)
	FileAppend, %tZoneDump%, %tZoneJsonDumpFile%
	pricesUpdatedOn:=SubStr(Response.pricesUpdated,1,10)
	today:=A_YYYY . "-" . A_MM . "-" . A_DD
	yest:=A_YYYY . "-" . A_MM . "-" . (A_DD-1)
	tom:=A_YYYY . "-" . A_MM . "-" . (A_DD+1)
	;account for timezones, one day off is OK for pricing
	isCurrent:=-1
	if(pricesUpdatedOn==yest or pricesUpdatedOn==today or pricesUpdatedOn==tom){
		isCurrent:=1
	}
	for i in Response.parts{
		name:=Response.parts[A_Index].name
		ducats:=Response.parts[A_Index].ducats
		price:=-1
		partID:=response.parts[A_Index].id
		for x in Response.prices{
			if(Response.prices[A_Index].partId==partID){
				price:=Round(Response.prices[A_Index].priceInfo.average,1)
			}
		}
		itemList.push([name,ducats,price,isCurrent])
	}
	
	itemList.push(["Neuroptics Blueprint",1,-1,1])
	itemList.push(["Chassis Blueprint",1,-1,1])
	itemList.push(["Systems Blueprint",1,-1,1])
	
	itemListFile := A_ScriptDir "\temps\itemList.txt"
	FileDelete %itemListFile%
	loop, % itemList.length(){
		store:= itemList[A_Index][1] . " " . itemList[A_Index][2] . " " . itemList[A_Index][3] . " " . itemList[A_Index][4]"`n"
		FileAppend, %store%, %itemListFile%
	}
	return
}

updateRelicTable(){
	MyJsonInstance := new JSON()
	myApi := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
	myURL:= "https://tenno.zone/data/"
	myApi.Open("GET", myURL, false)
	myApi.Send()
	Response := JSON.load(myApi.ResponseText)
	for i in Response.relics{
		name:=Response.relics[i].name
		vaulted:=Response.relics[i].isVaulted
		relicList.push([name, vaulted])
	}
	relicList.push(["Requiem I", 0])
	relicList.push(["Requiem II", 0])
	relicList.push(["Requiem III", 0])
	relicList.push(["Requiem IV", 0])
	
	relicListFile := A_ScriptDir "\temps\relicList.txt"
	FileDelete %relicListFile%
	loop, % relicList.length(){
		store:= relicList[A_Index][1] . "~" . relicList[A_Index][2] . "`n"
		FileAppend, %store%, %relicListFile%
	}
	
	for i in relicList{
		if(relicList[i][2]==1){
			vaultedRelics.push(relicList[i][1])
		}
	}
	return
}

;~~~~~ Utility functions borrowed from online
;https://autohotkey.com/board/topic/70202-string-compare-function-nonstandard-method/
Compare(StringA, StringB)
{
	Score := 0, SearchLength := 0, LengthA := StrLen(StringA), LengthB := StrLen(StringB)
	Loop % (LengthA < LengthB ? LengthA : LengthB) * 2 {
		If Mod(A_Index, 2)
			SearchLength += 1, Needle := "A", Haystack := "B"
		Else
			Needle := "B", Haystack := "A"
		StartAtHaystack := 1, StartAtNeedle := 1
		While (StartAtNeedle + SearchLength <= Length%Needle% + 1) {
			SearchText := SubStr(String%Needle%, StartAtNeedle, SearchLength)
			If (Pos := InStr(String%Haystack%, SearchText, 0, StartAtHaystack)) {
				StartAtHaystack := Pos + SearchLength, StartAtNeedle += SearchLength, Score += SearchLength**2
				If (StartAtHaystack + SearchLength > Length%Haystack% + 1)
					Break
			} Else
				StartAtNeedle += 1
		}
	}
	Return Score / (LengthA > LengthB ? LengthA : LengthB)
}

;https://sites.google.com/site/ahkref/custom-functions/sortarray
SortArray(Array, Order="A") {
    ;Order A: Ascending, D: Descending, R: Reverse
    MaxIndex := ObjMaxIndex(Array)
    If (Order = "R") {
        count := 0
        Loop, % MaxIndex
            ObjInsert(Array, ObjRemove(Array, MaxIndex - count++))
        Return
    }
    Partitions := "|" ObjMinIndex(Array) "," MaxIndex
    Loop {
        comma := InStr(this_partition := SubStr(Partitions, InStr(Partitions, "|", False, 0)+1), ",")
        spos := pivot := SubStr(this_partition, 1, comma-1) , epos := SubStr(this_partition, comma+1)    
        if (Order = "A") {    
            Loop, % epos - spos {
                if (Array[pivot] > Array[A_Index+spos])
                    ObjInsert(Array, pivot++, ObjRemove(Array, A_Index+spos))    
            }
        } else {
            Loop, % epos - spos {
                if (Array[pivot] < Array[A_Index+spos])
                    ObjInsert(Array, pivot++, ObjRemove(Array, A_Index+spos))    
            }
        }
        Partitions := SubStr(Partitions, 1, InStr(Partitions, "|", False, 0)-1)
        if (pivot - spos) > 1    ;if more than one elements
            Partitions .= "|" spos "," pivot-1        ;the left partition
        if (epos - pivot) > 1    ;if more than one elements
            Partitions .= "|" pivot+1 "," epos        ;the right partition
    } Until !Partitions
}

;~~~~~ Reward Selector functions
determinePlayers(){
	;can't be 1 player
	WinGetPos winx, winy, winwid, winhei, A
	inviteIcon:= A_ScriptDir "\lib\invite.png"
	CoordMode Pixel
	x1:=Floor(winx+winwid*.0977)
	y1:=Floor(winy+winhei*.0347)
	x2:=Floor(winx+winwid*.123)
	y2:=Floor(winy+winhei*.0868)
	ImageSearch, imgx, imgy, %x1%, %y1%, %x2%, %y2%,*25 *TransWhite %inviteIcon%
	if(errorlevel==2){
		;Error in ImageSearch, assume 4 players (most common)
		return 4
	} else if (errorlevel==0){
		;image found, 2 players
		return 2
	}
	;315,50 380 125
	x3:=Floor(winx+winwid*.123)
	y3:=Floor(winy+winhei*.0347)
	x4:=Floor(winx+winwid*.1484)
	y4:=Floor(winy+winhei*.0868)
	ImageSearch, imgx, imgy, %x3%, %y3%, %x4%, %y4%,*25 *TransWhite %inviteIcon%
	if(errorlevel==2){
		;Error in ImageSearch, assume 4 players (most common)
		return 4
	} else if (errorlevel==0){
		;image found, 3 players
		return 3
	} else {
		return 4
	}
	
}

lookup(myItem){
	for i in itemList{
		if(itemList[A_Index][1]==myItem){
			if(itemList[A_Index][4]=="1"){
				return itemList[A_Index][3]
			} else {
				itemList[A_Index][4]:=1
			}
		}
	}
	itemToFind:=StrReplace(myItem, " ", "_")
	StringLower, itemToFind, itemToFind
	MyJsonInstance := new JSON()
	myApi := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
	myURL:= "https://api.warframe.market/v1/items/" . itemToFind . "/orders?include=item"
	myApi.Open("GET", myURL, false)
	myApi.SetRequestHeader("Content-Type", "application/json")
	myApi.Send()
	if(myApi.status==404){
		;Might be a warframe part, if so, remove " blueprint"
		itemToFind:= SubStr(itemToFind,1,StrLen(itemToFind)-10)
		myApi := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
		myURL:= "https://api.warframe.market/v1/items/" . itemToFind . "/orders?include=item"
		myApi.Open("GET", myURL, false)
		myApi.SetRequestHeader("Content-Type", "application/json")
		myApi.Send()
	}
	Result := JSON.Load(myApi.ResponseText)
	jsonDumpFile := A_ScriptDir "\temps\jsonDump.txt"
	FileDelete %jsonDumpFile%
	JSONDump := JSON.Dump(Result, ,1)
	FileAppend, %JSONDump%, %jsonDumpFile%
	MouseGetPos, mxpos, mypos
	isMod:= false
	modLevel:=0
	loop % Results.include.item.items_in_set[0].tags.length(){
		if(Results.include.item.items_in_set[0].tags[A_Index]=="mod"){
			isMod:=true
		}
	}
	orders:= Result.payload.orders
	onlineOrders := []
	lowestPrice:=999999999
	sname:=""
	Loop % orders.length(){
		thisOrder:=orders[A_Index]
		if(thisOrder.user.status!="offline" and thisOrder.order_type=="sell"){
			onlineOrders.Push(thisOrder)
			if(thisOrder.platinum<lowestPrice){
				lowestPrice:=thisOrder.platinum
				sname:=thisOrder.user.ingame_name
			}
		}
	}
	total:= 0
	qCount:=0
	if(onlineOrders.length()<5){
		loop % onlineOrders.length(){
			o:=onlineOrders[A_Index]
			total+=o.platinum*o.quantity
			qcount+=o.quantity
		}
	}else{
		loop % onlineOrders.length(){
			o:=onlineOrders[A_Index]
 			if(o.platinum<(lowestPrice*2)){
				total+=o.platinum*o.quantity
				qcount+=o.quantity
			}
		}
	}
	lowAvg:= Round(total/qcount,1)
	for i in itemList{
		if(itemList[A_Index][1]==myItem){
			itemList[A_Index][4]:=1
		}
	}
	return lowAvg
}

;~~~~~ Ducat Manager functions
ducatOneScreen(){
	;xcords:=[130,415,695,980,1260,1540]
	;ycords:=[425,670,930,1200]
	WinGetPos winx, winy, winwid, winhei, A
	xcords:= [Floor(winx+winwid*.0507),Floor(winx+winwid*.1621),Floor(winx+winwid*.271),Floor(winx+winwid*.383),Floor(winx+winwid*.4922),Floor(winx+winwid*.602)]
	ycords:= [Floor(winy+winhei*.295),Floor(winy+winhei*.465),Floor(winy+winhei*.646),Floor(winy+winhei*.833)]
	loop 4 {
		yind:=A_Index
		loop 6{
			thisItem:=OCR([xcords[A_Index],ycords[yind],215,60])
			bestScore:=0
			bestIndex:=0
			thisItem:=RegExReplace(thisItem, "[^a-zA-Z]", "")
			for i in itemList{
				iScore:= Compare(thisItem,RegExReplace(itemList[A_Index][1], "[^a-zA-Z]", ""))
				if(iScore>bestScore){
					bestScore:=iScore
					bestIndex:=A_Index
				}
			}
			
			if(itemList[bestIndex][1]=="Neuroptics Blueprint" or itemList[bestIndex][1]=="Chassis Blueprint" or itemList[bestIndex][1]=="Systems Blueprint"){
				thisItem:=OCR([xcords[A_Index],ycords[yind]-30,215,90])
				bestScore:=0
				bestIndex:=0
				thisItem:=RegExReplace(thisItem, "[^a-zA-Z]", "")
				for i in itemList{
					iScore:= Compare(thisItem,RegExReplace(itemList[A_Index][1], "[^a-zA-Z]", ""))
					if(iScore>bestScore){
						bestScore:=iScore
						bestIndex:=A_Index
					}
				}
			}
			if(bestScore<5){
				myItems.push(["unknown",bestScore])
			} else {
				doAdd = true
				toAdd:=[itemList[bestIndex][1]]
				for i in myItems{
					if(myItems[A_Index]==toAdd){
						doAdd = false
					}
				}
				if(doAdd){
					toAdd:=[itemList[bestIndex][1],bestScore]
					myItems.push(toAdd)
				}
			}
		}
	}
	return
}

;~~~~~ Hotkey functions
ExitProg:
	ExitApp
	return
	
;end of mission lookup	
doRewardSel:
	players:=determinePlayers()
	SetTimer,RemoveToolTip,-1000
	ToolTip Searching
	WinGetPos winx, winy, winwid, winhei, A	
	if(players==4){
		box1:=Floor(winx+winwid*.25)
		box2:=Floor(winx+winwid*.367)
		box3:=Floor(winx+winwid*.5)
		box4:=Floor(winx+winwid*.6328)
	} else if(players==3){
		box1:=Floor(winx+winwid*.3125)
		box2:=Floor(winx+winwid*.4395)
		box3:=Floor(winx+winwid*.5664)
	} else if(players==2){
		box1:=Floor(winx+winwid*.375)
		box2:=Floor(winx+winwid*.5)
	}
	x2:=Floor(winx+winwid*.141)
	y1:=Floor(winy+winhei*.375)
	y2:=Floor(winy+winhei*.056)
	results:=[]
	results.push(OCR([box1, y1, x2, y2])) ;640
	results.push(OCR([box2, y1, x2, y2])) ;940
	if(players>2){
		results.push(OCR([box3, y1, x2, y2])) ;1290
	}
	if(players>3){
		results.push(OCR([box4, y1, x2, y2])) ;1620
	}
	itemNames:= []
	loop %players%{
		bestScore:=0
		bestIndex:=0
		iOuter:=A_Index
		results[iOuter]:=RegExReplace(results[iOuter], "[^a-zA-Z]", "")
		for i in itemList{
			iScore:= Compare(results[iOuter],RegExReplace(itemList[A_Index][1], "[^a-zA-Z]", ""))
			if(iScore>bestScore){
				bestScore:=iScore
				bestIndex:=A_Index
			}
		}
		itemNames[iOuter]:=itemList[bestIndex][1]
	}
	mostPlat:=0
	mostPlatIndex:=0
	loop %players%{
		itemNames[A_Index]:=[itemNames[A_Index],lookup(itemNames[A_Index])]
		if(itemNames[A_Index][2]>mostPlat){
			mostPlat:=itemNames[A_Index][2]
			mostPlatIndex:=A_Index
		}
	}
	
	strOut:="Reward " mostPlatIndex " has the highest value, " mostPlat "`n`n" itemNames[1][1] " is about " itemNames[1][2] " platinum.`n" itemNames[2][1] " is about " itemNames[2][2] " platinum.`n" 
	if(players>2){
		strOut.=itemNames[3][1] " is about " itemNames[3][2] " platinum.`n" 
	}
	if(players>3){
		strOut.=itemNames[4][1] " is about " itemNames[4][2] " platinum."
	}
	ToolTip
	MouseGetPos mxpos, mypos
	ToolTip, %strOut%
	SetTimer, doRTT, 250
	return
	
;scrollbar is 0x66A9BE, non is 0x24292F
;bottom is 1790 1282
doDucatMan:
	myItems:=[]
	InputBox, dppMin, Ducat Manager, Please input the minimum ducat/platinum ratio,,,,,,,,%DefaultDucatValue%
	if(ErrorLevel==1){
		ToolTip  Cancelling Ducat Manager
		Sleep 1000
		ToolTip
		return
	}
	dppMin:= RegExReplace(dppMin, "[^0-9.]", "")
	if(dppMin=""){
		dppMin:=DefaultDucatValue
	}
	dppMin:=Round(dppMin,1)
	send, {Wheelup 100}
	sleep 100
	MouseMove 30,30
	;PixelGetColor, SWBlankColor, winx+winwid*.699, winy+winhei*.89,slow
	;PixelGetColor, SWColor, winx+winwid*.699, winy+winhei*.2,slow
	ToolTip % "Beginning work, this may take a while.  Please don't touch anything."
	;MsgBox,,Ducat Manager, Beginning work.  This may take a while., 5
	WinGetPos winx, winy, winwid, winhei, A
	PixelGetColor, clr, winx+winwid*.699, winy+winhei*.89,slow
	ducatOneScreen()
	while clr != 0x66A9BE{
		send, {Wheeldown 4}
		ducatOneScreen()
		PixelGetColor, clr, winx+winwid*.699, winy+winhei*.89,slow
		;if(clr!=SWColor and clr!=SWBlankColor){
		;	MsgBox Location Error!  Make sure you are in Fullscreen or Borderless!
		;	return
		;}
	}	
	ToolTip
	
	itemStr:= "Items worth at least " . dppMin . " ducats per plat: `n"
	for index, item in myItems{
		thisItem:=item[1]
		ducats:=-1
		plat:=9999
		if(thisItem=="unknown"){
			dpp:=-1
		} else {
			for i in itemList{
				if(thisItem == itemList[A_Index][1]){
					ducats:=itemList[A_Index][2]
					plat:=itemList[A_Index][3]
				}
			}
			dpp:=Round(ducats/plat,1)
		}
		if(dpp >= dppMin){
			itemStr.=thisItem . SubStr("                                                  ",1,50-StrLen(thisItem)) . dpp . " dpp `n"
		}
	}
	MsgBox,,Ducat Manager,% itemStr
	return
	
doRelicMan:
	relicStr:= "Vaulted relics: `n"
	sortArray(vaultedRelics)
	sect:=Ceil(vaultedRelics.length()/6)
	for i in vaultedRelics{
		relicStr.=vaultedRelics[i] "       "vaultedRelics[sect+i] "       " vaultedRelics[sect*2+i]"       "vaultedRelics[sect*3+i]"       "vaultedRelics[sect*4+i]"       "vaultedRelics[sect*5+i]"`n"
		if(i==sect){
			break
		}
	}
	MsgBox,,Relic Manager, %relicStr%
	return
	
;~~~~~ Developer Hotkeys - Should be empty/commented on releases
/*

^i::
	MsgBox % determinePlayers()


*/
;~~~~~~~~~~~~~~~~~~~~~
;Unused code that may be useful in the future
;~~~~~~~~~~~~~~~~~~~~~

/*
doRelicMan:
	myRelics:= []
	send, {Wheelup 100}
	sleep 100
	ToolTip % "Beginning work, this may take a while.  Please don't touch anything."
	WinGetPos winx, winy, winwid, winhei, A
	MouseMove 30,30
	PixelGetColor, clr, winx+winwid*.599, winy+winhei*.895,slow
	relicOneScreen()
	ToolTip
	relicStr:= "Vaulted relics: `n"
	for i in myRelics{
		if(myRelics[i][2]==1){
			relicStr.= myRelics[i][1] " " myRelics[i][2] "`n"
		}
	}
	MsgBox % relicStr
	
	return
	
*/

;Seems unviable.  Too much mixing of letters/numbers (5/S, 5/b, etc) and would take too long to be very useful
/*
relicOneScreen(){
	xcords:=[130,420,700,1000,1285]
	ycords:=[425,690,970,1230]
	loop 4 {
		yind:=A_Index
		loop 5{
			thisItem:=OCR([xcords[A_Index],ycords[yind],230,70])
			bestScore:=0
			bestIndex:=0
			thisRelic:=RegExReplace(thisItem, "[^a-zA-Z1-9 ]", "")
			thisRelic:=StrReplace(thisRelic, "Radiant")
			thisRelic:=StrReplace(thisRelic, "Flawless")
			thisRelic:=StrReplace(thisRelic, "Exceptional")
			thisRelic:=StrReplace(thisRelic, "Relic")
			MsgBox % thisRelic
			for i in relicList{
				iScore:= Compare(thisRelic,RegExReplace(relicList[A_Index][1], "[^a-zA-Z1-9 ]", ""))
				if(iScore>bestScore){
					bestScore:=iScore
					bestIndex:=A_Index
				}
			}
			
			if(bestScore<5){
				myRelics.push(["unknown",bestScore])
			} else {
				doAdd = true
				toAdd:=[relicList[bestIndex][1]]
				for i in myRelics{
					if(myRelics[A_Index]==toAdd){
						doAdd = false
					}
				}
				if(doAdd){
					toAdd:=[relicList[bestIndex][1],bestScore]
					myRelics.push(toAdd)
				}
			}
		}
	}
}
*/


