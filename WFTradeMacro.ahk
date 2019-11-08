#SingleInstance force
#Persistent

#Include  <JSON>
#include <Vis2>

global mxpos := 0
global mypos := 0
global itemList := []
global myItems := []

updateItemTable()

doRTT:
MouseGetPos, mx, my
RToolTip(mx,my)
return

updateItemTableWiki(){
	myApi := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
	myURL:= "https://warframe.fandom.com/wiki/Ducats/Prices/All"
	myApi.Open("GET", myURL, false)
	myApi.Send()
	Response := myApi.ResponseText
	testFile := A_ScriptDir "\temps\itemList.txt"
	document := ComObjCreate("HTMLfile")
	document.write(Response)
	table := document.getElementsByTagName("table")[0]
	prevItem:= ""
	loop, % table.rows.length {
		itemList.Push([table.rows[A_Index].cells[0].innertext,table.rows[A_Index].cells[1].innertext])
	}
	itemList.push(["Neuroptics Blueprint",-1])
	itemList.push(["Chassis Blueprint",-1])
	itemList.push(["Systems Blueprint",-1])

	FileDelete %testFile%
	loop, % itemList.length(){
		store:= itemList[A_Index][1] . " " . itemList[A_Index][2] . "`n"
		FileAppend, %store%, %testFile%
	}
	return
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
	isToday:=-1
	if(today==pricesUpdatedOn){
		isToday==1
	}
	for i in Response.parts{
		itemList.push([Response.parts[A_Index].name,Response.parts[A_Index].ducats,Round(Response.prices[A_Index].priceInfo.average,1),isToday])
	}
	
	
	itemListFile := A_ScriptDir "\temps\itemList.txt"
	FileDelete %itemListFile%
	loop, % itemList.length(){
		store:= itemList[A_Index][1] . " " . itemList[A_Index][2] . "`n"
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
			if(itemList[A_Index][4]==1){
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
	;MsgBox % Floor(lowestPrice) " by " sname
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
	;MsgBox % "Low Average = " lowAvg
	for i in itemList{
		if(itemList[A_Index][1]==myItem){
			itemList[A_Index][4]:=1
		}
	}
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

^j::
	thisItem:=OCR([415,395,215,90])
	MsgBox % thisItem
	thisItem:=RegExReplace(thisItem, "[^a-zA-Z]", "")
	MsgBox % thisItem
	return
	
^l::
	WinMove, Snipping Tool, ,0,0
	;MouseMove, 415, 425, 0
	;Sleep, 1000
	;MouseMove, 630, 485
	MouseClickDrag, L, 415, 425, 630, 485
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
	WinGetPos winx, winy, winwid, winhei, A
	box1:=Floor(winx+winwid*.25)
	box2:=Floor(winx+winwid*.367)
	box3:=Floor(winx+winwid*.5)
	box4:=Floor(winx+winwid*.6328)
	results:=[]
	results.push(OCR([box1, 540, 360, 80])) ;640
	results.push(OCR([box2, 540, 360, 80])) ;940
	results.push(OCR([box3, 540, 360, 80])) ;1290
	results.push(OCR([box4, 540, 360, 80])) ;1620
	itemNames:= []
	loop 4{
		bestScore:=0
		bestIndex:=0
		iOuter:=A_Index
		results[iOuter]:=RegExReplace(results[iOuter], "[^a-zA-Z]", "")
		;MsgBox % results[iOuter]
		for i in itemList{
			iScore:= Compare(results[iOuter],RegExReplace(itemList[A_Index][1], "[^a-zA-Z]", ""))
			if(iScore>bestScore){
				bestScore:=iScore
				bestIndex:=A_Index
			}
		}
		;MsgBox % "I guess " . itemList[bestIndex] " score of " . bestScore
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
	SetTimer, doRTT, 500
	tooltip, %strOut%
	return
	
;scrollbar is 0x66A9BE, non is 0x24292F
;bottom is 1790 1282
;issues with some items not being seen and w/ 3 line items
^b::
	myItems:=[]
	MsgBox Beginning work
	WinGetPos winx, winy, winwid, winhei, A
	PixelGetColor, clr, winx+winwid*.699, winy+winhei*.89
	ducatOneScreen()
	while clr != 0x66A9BE{
		send, {Wheeldown 4}
		ducatOneScreen()
		PixelGetColor, clr, winx+winwid*.699, winy+winhei*.89
	}
	MsgBox done!
	
	dppMin:=5
	itemStr:= "Items worth at least " . dppMin . " ducats per plat: `n"
	for item in myItems{
		thisItem:=myItems[A_Index][1]
		ducats:=-1
		plat:=9999
		if(thisItem!="Forma"){
			for i in itemList{
				if(thisItem == itemList[A_Index][1]){
					ducats:=itemList[A_Index][2]
					plat:=itemList[A_Index][3]
				}
			}
		}
		dpp:=Round(ducats/plat,1)
		if(dpp >= dppMin){
			itemStr.=thisItem . dpp . "dpp `n"
		}
	}
	MsgBox % itemStr
	return