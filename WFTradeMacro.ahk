#SingleInstance force
#Persistent

#Include  <JSON>
#include <Vis2>

global mxpos := 0
global mypos := 0
global itemList := []
;list of [item name, ducats, price, isToday]
global myItems := []

updateItemTable()

doRTT:
MouseGetPos, mx, my
RToolTip(mx,my)
return

RemoveToolTip:
ToolTip
return

determinePlayers(){
	;can't be 1 player
	WinGetPos winx, winy, winwid, winhei, A
	myFile:= A_ScriptDir "\lib\invite.png"
	CoordMode Pixel
	ImageSearch, imgx, imgy, winx+winwid*.0977, winy+winhei*.0347, winx+winwid*.123, winy+winhei*.0868,*20 %myFile%
	if(errorlevel==2){
		;Error in ImageSearch, assume 4 players (most common)
		return 4
	} else if (errorlevel==1){
		;image found, 2 players
		return 2
	}
	;315,50 380 125
	ImageSearch, imgx, imgy, winx+winwid*.123, winy+winhei*.0347, winx+winwid*.1484, winy+winhei*.0868,*20 %myFile%
	if(errorlevel==2){
		;Error in ImageSearch, assume 4 players (most common)
		return 4
	} else if (errorlevel==1){
		;image found, 3 players
		return 3
	} else {
		return 4
	}
	
}

updateItemTable(){
	MyJsonInstance := new JSON()
	myApi := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
	myURL:= "https://tenno.zone/data/"
	myApi.Open("GET", myURL, false)
	myApi.Send()
	Response := JSON.load(myApi.ResponseText)
	pricesUpdatedOn:=SubStr(Response.pricesUpdated,1,10)
	today:=A_YYYY . "-" . A_MM . "-" . A_DD
	yest:=A_YYYY . "-" . A_MM . "-" . (A_DD-1)
	tom:=A_YYYY . "-" . A_MM . "-" . (A_DD+1)
	isToday:=-1
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
	
	itemList.push(["Neuroptics Blueprint",-1,-1,1])
	itemList.push(["Chassis Blueprint",-1,-1,1])
	itemList.push(["Systems Blueprint",-1,-1,1])
	
	itemListFile := A_ScriptDir "\temps\itemList.txt"
	FileDelete %itemListFile%
	loop, % itemList.length(){
		store:= itemList[A_Index][1] . " " . itemList[A_Index][2] . " " . itemList[A_Index][3] . " " . itemList[A_Index][4]"`n"
		FileAppend, %store%, %itemListFile%
	}
	return
}

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



RToolTip(mx, my){
	if(Abs(mxpos-mx)<50 && Abs(mypos-my)<50){
		;~ Don't remove tooltip
	} else {
		ToolTip
		SetTimer, doRTT, Off
	}
	
	return
}

lookup(myItem){
	for i in itemList{
		if(itemList[A_Index][1]==myItem){
			if(itemList[A_Index][4]=="1"){
				MsgBox % itemList[A_Index][3]
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
	testFile := A_ScriptDir "\temps\MyFile.txt"
	FileDelete %testFile%
	JSONDump := JSON.Dump(Result, ,1)
	FileAppend, %JSONDump%, %testFile%
	MouseGetPos, mxpos, mypos
	;SetTimer, doRTT, 500
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
	MsgBox % "Lookup: " lowAvg
	return lowAvg
}

ducatOneScreen(){
	xcords:=[130,415,695,980,1260,1540]
	ycords:=[425,670,930,1200]
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

;254,55 315,121
^j::
	myFile:= A_ScriptDir "\lib\invite.png"
	CoordMode Pixel
	ImageSearch, imgx, imgy, 250, 50, 315, 125,*20 %myFile%
	MsgBox % imgx . "~" . imgy . "~" . ErrorLevel
	return
	
^l::
	MouseMove 275,75
	sleep 2000
	MouseMove 300,100
	return
	
^u::
	updateItemTable()
	return
	
^i::
	MouseGetPos, x, y
	msgbox % x " " y
	return
	
	
	
^4::
	ExitApp
	return
	
;end of mission lookup	
^k::
	players:=determinePlayers()
	SetTimer,RemoveToolTip,-1000
	ToolTip Searching
	WinGetPos winx, winy, winwid, winhei, A	
	box1:=Floor(winx+winwid*.25)
	box2:=Floor(winx+winwid*.367)
	box3:=Floor(winx+winwid*.5)
	box4:=Floor(winx+winwid*.6328)
	x2:=Floor(winx+winwid*.141)
	y1:=Floor(winy+winhei*.375)
	y2:=Floor(winy+winhei*.056)
	results:=[]
	results.push(OCR([box1, y1, x2, y2])) ;640
	results.push(OCR([box2, y1, x2, y2])) ;940
	results.push(OCR([box3, y1, x2, y2])) ;1290
	results.push(OCR([box4, y1, x2, y2])) ;1620
	itemNames:= []
	loop 4{
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
	loop 4{
		itemNames[A_Index]:=[itemNames[A_Index],lookup(itemNames[A_Index])]
		if(itemNames[A_Index][2]>mostPlat){
			mostPlat:=itemNames[A_Index][2]
			mostPlatIndex:=A_Index
		}
	}
	
	strOut:="Reward " mostPlatIndex " has the highest value, " mostPlat "`n`n" itemNames[1][1] " is about " itemNames[1][2] " platinum.`n" itemNames[2][1] " is about " itemNames[2][2] " platinum.`n" itemNames[3][1] " is about " itemNames[3][2] " platinum.`n" itemNames[4][1] " is about " itemNames[4][2] " platinum."
	ToolTip
	MouseGetPos mxpos, mypos
	SetTimer, doRTT, 250
	ToolTip, %strOut%
	return
	
;scrollbar is 0x66A9BE, non is 0x24292F
;bottom is 1790 1282
;issues with some items not being seen and w/ 3 line items
^b::
	myItems:=[]
	InputBox, dppMin, Ducat Manager, Please input the minimum ducat/platinum ratio
	dppMin:= RegExReplace(dppMin, "[^0-9.]", "")
	if(dppMin=""){
		dppMin:=5
	}
	send, {Wheelup 100}
	sleep 100
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
		;thisItem:=myItems[A_Index][1]
		thisItem:=item[1]
		ducats:=-1
		plat:=9999
		for i in itemList{
			if(thisItem == itemList[A_Index][1]){
				ducats:=itemList[A_Index][2]
				plat:=itemList[A_Index][3]
			}
		}
		dpp:=Round(ducats/plat,1)
		if(dpp >= dppMin){
			itemStr.=thisItem . SubStr("                                                  ",1,50-StrLen(thisItem)) . dpp . " dpp `n"
		}
	}
	MsgBox,,Ducat Manager,% itemStr
	return