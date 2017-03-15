Rem
	MyData
	A simple Database program which can output to Lua and Python
	
	
	
	(c) Jeroen P. Broks, 2015, 2016, 2017, All rights reserved
	
		This program is free software: you can redistribute it and/or modify
		it under the terms of the GNU General Public License as published by
		the Free Software Foundation, either version 3 of the License, or
		(at your option) any later version.
		
		This program is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		GNU General Public License for more details.
		You should have received a copy of the GNU General Public License
		along with this program.  If not, see <http://www.gnu.org/licenses/>.
		
	Exceptions to the standard GNU license are available with Jeroen's written permission given prior 
	to the project the exceptions are needed for.
Version: 17.03.15
End Rem
' 15.02.17 - Initial version
' 16.12.08 - Several enhancements


Rem
Note to Mac users.
For some reason this program ALWAYS crashes in the release mode, and I don't know why.
In the DEBUG build the program always worked for me, making it impossible to find out what happens.
I really don't know how this goes in Linux and Windows as I never tried it in those OSes.
End Rem

Strict
Framework tricky_units.Listfile
Import    tricky_units.MKL_Version
Import    tricky_units.StringMap
Import    tricky_units.FilePicker
Import    maxgui.drivers
Import    brl.pngloader
Import    jcr6.zlibdriver
Import    jcr6.realdir


Incbin "MyData.png"

MKL_Version "MyData - MyData.bmx","17.03.15"
MKL_Lic     "MyData - MyData.bmx","GNU General Public License 3"

AppTitle = "MyData v"+MKL_NewestVersion()

'We need a file before we can do anything at all
Global File$ = FilePicker("Pick the database","Databases")
If Not file End

' System vars
Global OutputLuaRec$,OutputLuaBase$,OutputPythonRec$,OutputPythonBase$,OutLicense$,AutoOutput,outputmysqlbase$

' Browing vars
Global CurrentRec$

' Build Gui
Global Logo:TPixmap = LoadPixmap("incbin::MyData.png")
Global Win:TGadget = CreateWindow("MyData - Coded by Tricky - Build: "+MKL_NewestVersion(),0,0,ClientWidth(Desktop())*.75,ClientHeight(Desktop())*.75,Null,window_titlebar|window_center)
Global ww = ClientWidth(win)
Global wh = ClientHeight(win)
Global fbw = (ww-100)/3
Global logopan:TGadget = CreatePanel(0,0,88,75,win); SetGadgetPixmap logopan,logo
Global NewRec:TGadget = CreateButton("New"          ,100+(fbw*0), 0,fbw,25,Win)
Global RemRec:TGadget = CreateButton("Remove"       ,100+(fbw*1), 0,fbw,25,Win)
Global RenRec:TGadget = CreateButton("Rename"       ,100+(fbw*2), 0,fbw,25,Win)
Global RecLua:TGadget = CreateButton("Rec 2 Lua"    ,100+(fbw*0),25,fbw,25,win)
Global BasLua:TGadget = CreateButton("Base 2 Lua"   ,100+(fbw*1),25,fbw,25,win)
Global RecPyt:TGadget = CreateButton("Rec 2 Python" ,100+(fbw*0),50,fbw,25,win)
Global BasPyt:TGadget = CreateButton("Base 2 Python",100+(fbw*1),50,fbw,25,win)

Global Duplic:TGadget = CreateButton("Duplicate"    ,100+(fbw*2),25,fbw,25,win)
Global Save  :TGadget = CreateButton("Save"         ,100+(fbw*2),50,fbw,25,win)

Global RecList:TGadget = CreateListBox(0,75,200,wh-75,win)
Global Tabber:TGadget = CreateTabber(200,75,ww-200,wh-75,Win)
Global tw = ClientWidth(tabber)
Global th = ClientHeight(tabber)
Global Panels:TGadget[]

' Let's load the datalines
Global LF:TList = Listfile("Databases/"+File)
Global L$,TL$
Global pages=1,cpage=0

' Count da pages
For L=EachIn LF
	If Left(Trim(L),6).ToUpper()="[PAGE:" And Right(Trim(L),1)="]" Pages:+1
	Next
Panels = New TGadget[Pages]

' Set up the about panel
AddGadgetItem Tabber,"Version Info"
panels[0] = CreateLabel(MKL_GetAllversions(),0,0,tw,th,tabber)
SetGadgetFont panels[0],LookupGuiFont(guifont_monospaced,15)

' Record gadgets
Global RecGadget:TMap = New TMap
Global MapColor:TMap = New TMap

' Now load the actual data
Global fields:StringMap = New StringMap
Global Recs:TMap = New TMap
Global TRec:StringMap
Global DefaultValues:StringMap = New StringMap
Global Chunk$ = "System"
Global SL$[],TTL$
Global pagey=0
Global linecount
Global LastList:TGadget
Global RemoveNonExistent
Global OnlyAllowExt$,OnlyAllowExtList:TList
Global OnlyAllowPath$,OnlyAllowPathList:TList
Global Ok
Global Allow:TMap = New TMap
Global AllowList:TList
Global fieldonpage:StringMap = New StringMap,pagename$
For L=EachIn LF
	linecount:+1
	TL = Trim(L)
	If Trim(L) And Left(Trim(L),1)<>"#" And Left(Trim(L),2)<>"//" And Left(Trim(L),2)<>"--" ' No empty lines and no comments either!
		If Left(TL,1)="[" And Right(TL,1)="]"
			If Upper(TL)="[SYSTEM]" 
				Chunk="System"
			ElseIf Upper(Left(TL,6))="[PAGE:"
				Chunk = "Structure"
				cpage:+1
				pagey=0
				Panels[cpage] = CreatePanel(0,0,tw,th,Tabber)
				HideGadget Panels[cpage]
				AddGadgetItem tabber,Mid(TL,7,Len(TL)-7)
				pagename = Trim(Mid(TL,7,Len(TL)-7))
			ElseIf Upper(TL)="[RECORDS]"
				Chunk = "Records"
			ElseIf Upper(TL)="[DEFAULT]"
				chunk = "Default"
			ElseIf Upper(Left(TL,7))="[ALLOW:"
				chunk = "Allow"
				AllowList = New TList
				MapInsert allow,Trim(Mid(TL,8,Len(TL)-8)),allowlist
				Print "Start Allow: "+Trim(Mid(TL,8,Len(TL)-8))
			Else 
				Error "Unknown [ ] definition: "+TL	
				EndIf
		Else
			Select Chunk
				Case "System"
					If TL.find("=")=-1 error("Invalid line: "+TL)
					SL = TL.split("=")
					Select Upper(Trim(SL[0]))
						Case "OUTPUTLUAREC"
							OutputLuaRec = Trim(SL[1])
						Case "OUTPUTLUABASE"
							OutputLuaBase = Trim(SL[1])
						Case "OUTPUTPYTHONREC"
							outputpythonrec = Trim(SL[1])
						Case "OUTPUTPYTHONBASE"
							outputpythonbase = Trim(SL[1])
						Case "OUTPUTMYSQLBASE"
							outputmysqlbase = Trim(SL[1])
						Case "LICENSE"
							outlicense = Trim(SL[1])	
						Case "AUTOOUTPUT"
							AutoOutput = Trim(Upper(SL[1]))="YES" Or Trim(Upper(SL[1]))="TRUE"
						Case "REMOVENONEXISTENTFIELDS"
							RemoveNonExistent = Trim(Upper(SL[1]))="YES" Or Trim(Upper(SL[1]))="TRUE"
						Default 
							Error"Unknown variable: "+Trim(SL[0])
						End Select
				Case "Structure"
					TTL = Replace(TL,"~t"," ")
					Repeat
					TL = TTL
					TTL = Replace(TTL,"  "," ")
					Until TTL=TL					
					If TL.find(" ")=-1 And Left(tl,6).tolower()<>"strike" error "Invalid line: "+TL+"~nline #"+Linecount
					SL = TL.split(" ")
					If Left(SL[0],1)<>"@" And Left(tl,6).tolower()<>"strike" And Left(tl,4).tolower()<>"info"
						CreateLabel Lower(SL[0]),0,pagey,250,15,panels[cpage]
						CreateLabel SL[1],250,pagey,250,15,panels[cpage]
						If MapContains(fields,SL[1]) error "Duplicate field: "+SL[1]
						MapInsert fields,SL[1],SL[0]
						MapInsert fieldonpage,SL[1],pagename
					ElseIf Len(SL)>1
						SL[1] = Replace(SL[1],"\space"," ")
						EndIf									
					Select Lower(SL[0])
						Case "strike"
							CreateLabel("---",0,pagey,ClientWidth(panels[cpage]),25,panels[cpage],LABEL_SEPARATOR)
							pagey:+25
						Case "info"
						      CreateLabel Right(TL,Len(TL)-5),0,pagey,1000,25,panels[cpage]
							pagey:+25
						Case "string"
							MapInsert recgadget,SL[1],CreateTextField(500,pagey,500,25,panels[cpage])
							pagey:+25
						Case "int","double"
							MapInsert recgadget,SL[1],CreateTextField(500,pagey,250,25,panels[cpage])
							pagey:+25
						Case "color"
							CreateLabel "R:",500,Pagey,50,25,panels[cpage]
							MapInsert RecGadget,SL[1]+".Red",CreateTextField(550,pagey,50,25,Panels[cpage])
							CreateLabel "G:",610,Pagey,50,25,panels[cpage]
							MapInsert RecGadget,SL[1]+".Green",CreateTextField(660,pagey,50,25,Panels[cpage])
							CreateLabel "B:",720,Pagey,50,25,panels[cpage]
							MapInsert RecGadget,SL[1]+".Blue",CreateTextField(770,pagey,50,25,Panels[cpage])
							MapInsert RecGadget,SL[1]+".Pick",CreateButton("Pick",880,pagey,80,25,Panels[cpage])
							MapInsert MapColor,GadField(SL[1]+".Pick"),SL[1]
							SetGadgetColor GadField(SL[1]+".Red")  ,255,180,180
							SetGadgetColor GadField(SL[1]+".Green"),180,255,180
							SetGadgetColor GadField(SL[1]+".Blue") ,180,180,255
							pagey:+25
						Case "bool"
							MapInsert RecGadget,SL[1]+".Panel",CreatePanel(500,pagey,400,25,Panels[cpage])
							MapInsert RecGadget,SL[1]+".True",CreateButton("True",0,0,200,25,gadfield(SL[1]+".Panel"),Button_radio)
							MapInsert RecGadget,SL[1]+".False",CreateButton("False",200,0,200,25,gadfield(SL[1]+".Panel"),Button_radio)
							pagey:+25
						Case "mc"
							MapInsert recgadget,SL[1],CreateComboBox(500,pagey,500,25,panels[cpage])
							lastlist = gadfield(SL[1])
							pagey:+25
						Case "@noextfilter"
							OnlyAllowExt = ""
							OnlyAllowExtList = Null	
						Case "@nopathfilter","@nodirfilter"
							OnlyAllowPath = ""
							OnlyAllowPathList = Null
						Case "@extfilter"
							OnlyAllowExt = Upper(Trim(Right(TL,Len(TL)-Len("@extfilter "))))
							OnlyAllowExtList = ListFromArray(OnlyAllowExt.split(","))	
						Case "@pathfilter"
							OnlyAllowPath = Upper(Trim(Right(TL,Len(TL)-Len("@pathfilter "))))
							OnlyAllowPathList = ListFromArray(OnlyAllowpath.split(","))	
						Case "@dirfilter"
							OnlyAllowPath = Upper(Trim(Right(TL,Len(TL)-Len("@dirfilter "))))
							OnlyAllowPathList = ListFromArray(OnlyAllowPath.split(","))	
						Case "@db"	
						        If Not lastlist error "No list to add this item to in line #"+linecount
							Print "Importing database: "+Trim(Right(TL,Len(TL)-4))
							For Local l$=EachIn Listfile("Databases/"+Trim(Right(TL,Len(TL)-4)))
								Local readrec=False
								If Upper(l)="[RECORDS]" 
									readrec=True
								ElseIf Left(l,1)="["
									readrec=False
								EndIf	
								If Prefixed(l,"Rec: ")	AddGadgetItem lastlist,Trim(Right(l,Len(l)-4))
							Next
						Case "@f"
							If Not lastlist error "No list to add this item to in line #"+linecount
							Print "Importing JCR: "+Trim(Right(TL,Len(TL)-3))
							Local JD:TJCRDir = JCR_Dir(Trim(Right(TL,Len(TL)-3)))
							Ok = True
							If Not JD error "JCR could not read file: "+Trim(Right(TL,Len(TL)-3))
							'For Local F$=EachIn OnlyAllowPathlist DebugLog "Dir Allowed: "+f; Next
							'For Local F$=EachIn OnlyAllowextlist  DebugLog "Ext Allowed: "+F; Next
							For Local D:TJCREntry=EachIn MapValues(JD.Entries)
							      Rem Old and inefficient
								If Not OnlyAllowExtList
									Print "Adding entry: "+D.FileName
									AddGadgetItem lastlist,D.FileName
								ElseIf ListContains(OnlyAllowExtList,Upper(ExtractExt(D.FileName)	))
									Print "Adding entry: "+D.FileName+" (approved by the ext filter)"
									AddGadgetItem lastlist,D.FileName
									Else
									'Print " Disapproved: "+D.FileName+"  ("+Upper(ExtractExt(D.FileName))+" is not in the filterlist"+")"
									EndIf
								End Rem
								Ok = True                                                                                                '               '
								If OnlyAllowExtList  Ok = ok And ListContains(OnlyAllowExtList ,Upper(ExtractExt(D.FileName))) 'DebugLog "    Ext Check: "+D.FileName+" >>> "+Ok
								If OnlyAllowPathList Ok = Ok And ListContains(OnlyAllowPathList,Upper(ExtractDir(D.FileName))) 'DebugLog "    Dir Check: "+D.FileName+" >>> "+Ok
								If OK Then 
									AddGadgetItem lastlist,D.FileName
									'DebugLog "Added to list: "+D.filename
									Else
									'DebugLog "     Rejected: "+D.filename
									EndIf
								Next
						Case "@i"
							If Not lastlist error "No list to add this item to in line #"+linecount
							AddGadgetItem lastlist,SL[1]
						Default error "Unknown type '"+SL[0]+"' in line #"+linecount
						End Select
				Case "Records"
					TL = Trim(L)
					If Upper(Left(TL,4))="REC:"
						If MapContains(recs,Upper(Trim(Right(TL,Len(TL)-4))))
							Select Proceed("Duplicate record definition:~n~n"+Upper(Trim(Right(TL,Len(TL)-4)))+"~n~nShall I merge the data with the existing record?")
								Case -1 
									Print "Kill program by user's request"
								  	End
								Case 0
									Print "Destroying the old"
									TRec = New StringMap
									MapInsert Recs,Upper(Trim(Right(TL,Len(TL)-4))),TRec
								Case 1
									Print "Merging!"
									TRec = StringMap(MapValueForKey(Recs,	Upper(Trim(Right(TL,Len(TL)-4)))))
									For Local k$=EachIn MapKeys(TRec) Print K+" = "+TRec.Value(K) Next ' debug line
							End Select
						Else	
							TRec = New StringMap
							MapInsert Recs,Upper(Trim(Right(TL,Len(TL)-4))),TRec
						EndIf
					ElseIf TL.Find("=")<>"="
						If Not TRec error "Definition without starting a record first in line #"+linecount+"~n~n"+L
						SL = TL.split("=")
						For Local slak=0 Until Len(SL) SL[slak]=Trim(SL[slak]) Next
						If Not MapContains(fields,sl[0]) 
							If RemoveNonExistent 
								Select Proceed("Field does not exist ~q"+SL[0]+"~q in line "+linecount+"~n~nRemove this Field?")
									Case -1	End
									Case  0	MapInsert TRec,SL[0],SL[1]
									Case  1	Print "Field "+SL[0]+" has been removed from the database!"
									End Select
								Else
								error "Field does not exist ~q"+SL[0]+"~q in line "+linecount
								EndIf
							Else	
							MapInsert TRec,SL[0],SL[1]
							EndIf
					Else
						error "Syntax error in "+linecount+"~n~n"+L
						EndIf
				Case "Allow"
					TL = Trim(L)
					ListAddLast allowlist,TL; SortList allowlist
					Print "= Added: "+TL 
				Case "Default"
					TL = Trim(L)
					If TL.Find("=")<>"="
						SL = TL.split("=")
						For Local slak=0 Until Len(SL) SL[slak]=Trim(SL[slak]) Next
						If Not MapContains(fields,sl[0]) error "Field does not exist ~q"+SL[0]+"~q in line "+linecount
						MapInsert DefaultValues,SL[0],SL[1]
					Else
						error "Syntax error in "+linecount+"~n~n"+L
						EndIf	
				Default
					error "Internal error!~n~nUnknown Chunk!~n~n"+linecount+"/"+L	
				End Select		
			EndIf
		EndIf
	Next

' Update the GUI lists
ClearGadgetItems RecList
For Local K$=EachIn MapKeys(Recs)
	AddGadgetItem reclist,K
	Next
currentrec = ""	
update



' Functions
Function Error(Err$)
Notify "ERROR!~n~n"+Err
End
End Function


Function GadField:TGadget(Fld$)
	If Not MapContains(RecGadget,FLD) Print "WARNING! Call to a non-existent gadget field: "+Fld
	Return TGadget(MapValueForKey(RecGadget,Fld))
End Function

Function CanWeEdit()
For Local G:TGadget = EachIn MapValues(RecGadget)
	G.setenabled SelectedGadgetItem(RecList)>=0
	Next
Duplic.setenabled SelectedGadgetItem(RecList)>=0
RemRec.setenabled SelectedGadgetItem(RecList)>=0
RenRec.setenabled SelectedGadgetItem(RecList)>=0	
End Function

Function Update()
Local K$
Local c$[]
Local ak,ok
Local BoolValues$[] = ["FALSE","TRUE"]
If currentrec Then
	For K=EachIn MapKeys(fields)
		Select fields.value(k)
			Case "string"	MapInsert rec(currentrec),k,TextFieldText(gadfield(k))
			Case "int"		MapInsert rec(currentrec),k,TextFieldText(gadfield(k)).toint()+""
			Case "double"	MapInsert rec(currentrec),k,TextFieldText(gadfield(k)).todouble()+""
			Case "bool"		MapInsert rec(Currentrec),k,boolvalues[ButtonState(gadfield(k+".True"))]
			Case "color"    MapInsert rec(currentrec),k,TextFieldText(gadfield(k+".Red")).toint()+","+TextFieldText(gadfield(k+".Green")).toint()+","+TextFieldText(gadfield(k+".Blue")).toint()
			Case "mc"       If SelectedGadgetItem(gadfield(k))>=0
								MapInsert rec(currentrec),k,GadgetItemText(gadfield(k),SelectedGadgetItem(gadfield(k)))
							Else
								MapInsert Rec(currentrec),k,""
								EndIf
			End Select
		Next
	EndIf
If SelectedGadgetItem(reclist)>=0
	currentrec = GadgetItemText(reclist,SelectedGadgetItem(reclist))
	For K=EachIn MapKeys(fields)
		Select fields.value(k)
			Case "string"	SetGadgetText gadfield(k),Rec(Currentrec).Value(k)
			Case "int"		SetGadgetText gadfield(k),Rec(Currentrec).Value(k)
			Case "double"	SetGadgetText gadfield(k),Rec(Currentrec).Value(k)
			Case "color"    c = (rec(currentrec).value(k)+",0,0,0").split(",")
			                SetGadgetText gadfield(k+".Red"  ),c[0]+""
			                SetGadgetText gadfield(k+".Green"),c[1]+""			                
							SetGadgetText gadfield(k+".Blue" ),c[2]+""	
			Case "bool"		SetButtonState gadfield(k+".True"),Rec(CurrentRec).Value(k)="TRUE"
							SetButtonState gadfield(k+".False"),Not ButtonState(gadfield(k+".True"))
			Case "mc"		If rec(currentrec).Value(k)
								ok=False
								For ak=0 Until CountGadgetItems(gadfield(k))
									If GadgetItemText(gadfield(k),ak)=rec(currentrec).Value(k) SelectGadgetItem gadfield(k),ak; ok=True
									Next
								If Not ok 
									Notify "WARNING!~n~n Set value ~q"+rec(currentrec).value(k)+"~q has not been found in the list. Resetting value"
									If SelectedGadgetItem(gadfield(k))>=0 DeselectGadgetItem gadfield(k),SelectedGadgetItem(gadfield(k))
									If SelectedGadgetItem(gadfield(k))>=0 SelectGadgetItem gadfield(k),0
									EndIf
							Else
								If SelectedGadgetItem(gadfield(k))>=0 DeselectGadgetItem gadfield(k),SelectedGadgetItem(gadfield(k))
								If SelectedGadgetItem(gadfield(k))>=0 SelectGadgetItem gadfield(k),0
								EndIf												
			End Select
		Next
	Else
	currentrec = ""
	EndIf	
CanWeEdit
End Function

Function Rec:StringMap(RecName$)
Return StringMap(MapValueForKey(recs,Upper(RecName)))
End Function

Function CreateRecord(DuplicateFrom$="")	
HideGadget win
Local recname$ = Upper(MaxGUI_Input("Please give your entry a name:","",True,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWYZ_01234567890"))
Local cnt=-1,nidx,K$
ShowGadget win
If Not MaxGUI_InputAccepted Return
If Not recname Return
If MapContains(recs,recname) 
	If Not Confirm("A record with called ~q"+recname+"~q already exists!~n~nDo you wish To overwrite this record?") Return
	EndIf
MapInsert recs,recname,New StringMap
If duplicatefrom
	For K$=EachIn MapKeys(Rec(duplicatefrom))
		MapInsert rec(recname), k, rec(duplicatefrom).Value(k)
		Next
Else ' Are there any default values?
	For K$=EachIn MapKeys(DefaultValues)
		MapInsert Rec(RecName),K,DefaultValues.Value(k)		
		Next
	EndIf
ClearGadgetItems RecList
For K$=EachIn MapKeys(Recs)
	cnt:+1
	If K=recname nidx=cnt
	AddGadgetItem reclist,K
	Next
SelectGadgetItem reclist,nidx
Update	
End Function

Function RenameRecord()
HideGadget win
Local recname$ = Upper(MaxGUI_Input("Please give your entry a new name:",CurrentRec,True,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_01234567890"))
Local cnt=-1,nidx,K$
If Not recname Return
ShowGadget win
If recname=currentrec Return
If MapContains(recs,recname) Return Notify("Same named record already exists!")
MapInsert Recs,RecName,Rec(CurrentRec)
MapRemove Recs,CurrentRec
CurrentRec=""; ClearGadgetItems RecList; Update
CurrentRec=RecName
ClearGadgetItems RecList
For K$=EachIn MapKeys(Recs)
	cnt:+1
	If K=recname nidx=cnt
	AddGadgetItem reclist,K
	Next
Update
End Function

Function RemoveRecord()
If Not Confirm("Are you sure you wish to remove record ~q"+CurrentRec+"~q") Return
MapRemove recs,currentrec
ClearGadgetItems RecList
For Local K$=EachIn MapKeys(Recs)
	AddGadgetItem reclist,K
	Next
currentrec = ""	
update
End Function

Function EndSlash$(A$)
Local Ret$ = Replace(A,"\","/")
If Right(Ret,1)<>"/" Ret:+"/"
Return ret
End Function

Function Conv_RecLua(Chat=True)
Update
OutputLuaRec = endslash(OutputLuaRec)
If Not CreateDir(ExtractDir(OutputLuaRec),2) Return Notify("Cannot create Lua record dir: "+OutPutLuaRec)
Local RK$,FK$
Local RF,FF
Local C$[]
Local BT:TStream
For RK = EachIn MapKeys(Recs)
	Print "Writing: "+outputluarec+RK+".lua"
	BT = WriteFile(outputluarec+rk+".lua")
	If Not BT Return Notify("ERROR: File could not be written.~n~n"+OutputluaRec+rk+".lua")
	WriteLine BT,"-- This file has be generated by Tricky's MyData"
	WriteLine BT,"-- "+CurrentDate()+"; "+CurrentTime()
	If OutLicense WriteLine BT,"-- License: "+OutLicense
	WriteLine bt,"~tret = {"; FF=False
	For fk = EachIn MapKeys(fields)
		If FF WriteLine BT,"," Else FF=True
		Select fields.value(fk)
			Case "string","mc"
				WriteString bt,"~t~t[~q"+Fk+"~q] = ~q"+Replace(Rec(RK).Value(FK),"~q","\~q")+"~q"
			Case "int","double"
				WriteString bt,"~t~t[~q"+Fk+"~q] = "+Rec(RK).Value(FK)
			Case "color"
				C = (Rec(RK).Value(FK)+",0,0,0").split(",")
				WriteString bt,"~t~t[~q"+fk+"~q] = { R = "+C[0]+", G = "+C[1]+", B = "+C[2]+" }"	
			Case "time"
				C = (Rec(RK).Value(FK)+",0,0,0").split(",")
				WriteString bt,"~t~t[~q"+fk+"~q] = { H = "+C[0]+", M = "+C[1]+", S = "+C[2]+" }"
			Case "date"
				C = (Rec(RK).Value(FK)+",0,0,0").split(",")
				WriteString bt,"~t~t[~q"+fk+"~q] = { D = "+C[0]+", M = "+C[1]+", Y = "+C[2]+" }"
			Case "bool"
				If Rec(RK).value(fk) WriteString bt,"~t~t[~q"+fk+"~q] = "+Lower(Rec(RK).value(fk)) Else WriteString bt,"-- empty bool "+fk	
			Case "strike","info"
			     ' Just do nothing. :)				
			Default
				WriteString bt,"~t~t-- Unknown field type: "+fields.value(fk)+" for field: "+fk	
			End Select
		Next	
	WriteLine bt,"}~n~nreturn ret"
	CloseFile bt 
	Next
If Chat Notify "Base written to dir: "+OutputLuaRec
End Function	

Function Conv_BaseLua(Chat=True)
Update
Local BT:TStream = WriteStream(OutputLuaBase)
If Not BT Return Notify("Couldn't output to: "+OutputLuaBase)
WriteLine BT,"-- This file has be generated by Tricky's MyData"
WriteLine BT,"-- "+CurrentDate()+"; "+CurrentTime()
If OutLicense WriteLine BT,"-- License: "+OutLicense
WriteLine BT,"~n~n"
WriteLine bt,"ret = {"
Local RK$,FK$
Local RF,FF
Local C$[]
For RK = EachIn MapKeys(Recs)
	If RF WriteLine BT,"," Else RF = True
	FF = False
	WriteLine BT,"~t[~q"+RK+"~q] = {"
	For fk = EachIn MapKeys(fields)
		If FF WriteLine BT,"," Else FF=True
		Select fields.value(fk)
			Case "string","mc"
				WriteString bt,"~t~t[~q"+Fk+"~q] = ~q"+Replace(Rec(RK).Value(FK),"~q","\~q")+"~q"
			Case "int","double"
				WriteString bt,"~t~t[~q"+Fk+"~q] = "+Rec(RK).Value(FK)
			Case "color"
				C = (Rec(RK).Value(FK)+",0,0,0").split(",")
				WriteString bt,"~t~t[~q"+fk+"~q] = { R = "+C[0]+", G = "+C[1]+", B = "+C[2]+" }"	
			Case "time"
				C = (Rec(RK).Value(FK)+",0,0,0").split(",")
				WriteString bt,"~t~t[~q"+fk+"~q] = { H = "+C[0]+", M = "+C[1]+", S = "+C[2]+" }"
			Case "date"
				C = (Rec(RK).Value(FK)+",0,0,0").split(",")
				WriteString bt,"~t~t[~q"+fk+"~q] = { D = "+C[0]+", M = "+C[1]+", Y = "+C[2]+" }"
			Case "bool"
				If Rec(RK).value(fk) Then WriteString bt,"~t~t[~q"+fk+"~q] = "+Lower(Rec(RK).value(fk)) Else WriteString bt,"-- Empty boolean: "+fk				
			Default
				WriteString bt,"~t~t-- Unknown field type: "+fields.value(fk)+" for field: "+fk	
			End Select
		Next
	WriteString BT,"}"	
	Next
WriteLine BT,"}"
WriteLine BT,"~n~n~n-- Got all data, let's now return it!"
WriteLine BT,"return ret"
CloseFile BT
If Chat Notify "File saved as: "+OutputLuaBase	
End Function

Function Conv_BasePython(Chat=True)
Update
Local BT:TStream = WriteStream(OutputPythonBase)
If Not BT Return Notify("Couldn't output to: "+OutputPythonBase)
WriteLine BT,"# This file has be generated by Tricky's MyData"
WriteLine BT,"# "+CurrentDate()+"; "+CurrentTime()
If OutLicense WriteLine BT,"# License: "+OutLicense
WriteLine BT,"~n~nglobal MyData~n"
WriteLine bt,"MyData = {"
Local RK$,FK$
Local RF,FF
Local C$[]
For RK = EachIn MapKeys(Recs)
	If RF WriteLine BT,"," Else RF = True
	FF = False
	WriteLine BT,"~t~q"+RK+"~q : {"
	For fk = EachIn MapKeys(fields)
		If FF WriteLine BT,"," Else FF=True
		Select fields.value(fk)
			Case "string","mc"
				WriteString bt,"~t~t~q"+Fk+"~q : ~q"+Replace(Rec(RK).Value(FK),"~q","\~q")+"~q"
			Case "int","double"
				WriteString bt,"~t~t~q"+Fk+"~q : "+Rec(RK).Value(FK)
			Case "color"
				C = (Rec(RK).Value(FK)+",0,0,0").split(",")
				WriteString bt,"~t~t~q"+fk+"~q : { 'R' : "+C[0]+", 'G' : "+C[1]+", 'B' : "+C[2]+" }"
			Case "time"
				C = (Rec(RK).Value(FK)+",0,0,0").split(",")
				WriteString bt,"~t~t~q"+fk+"~q : { 'H' : "+C[0]+", 'M' : "+C[1]+", 'S' : "+C[2]+" }"
			Case "date"
				C = (Rec(RK).Value(FK)+",0,0,0").split(",")
				WriteString bt,"~t~t~q"+fk+"~q : { 'D' : "+C[0]+", 'M' : "+C[1]+", 'Y' : "+C[2]+" }"
			Case "bool"
				If Rec(RK).value(fk) WriteString bt,"~t~t~q"+fk+"~q : "+Upper(Left(Rec(RK).Value(fk+".True"),1))+Lower(Right(Rec(RK).value(fk),Len(Rec(RK).value(fk))-1)) Else WriteString bt,"~t~t~q"+fk+"~q : False"
			Default
				WriteString bt,"~t~t# Unknown field type: "+fields.value(fk)+" for field: "+fk	
			End Select
		Next
	WriteString BT,"}"	
	Next
WriteLine BT,"}"
WriteLine BT,"~n~n#When imported you should have a variable called "+StripAll(OutputPythonBase)+".MyData, when imported you may have a global MyData variable."
CloseFile BT
If Chat Notify "File saved as: "+OutputPythonBase	
End Function

Function Conv_BaseMySql(Chat=True)
Update
Local BT:TStream = WriteStream(OutputMysqlBase)
If Not BT Return Notify("Couldn't output to: "+OutputMySqlBase)
WriteLine BT,"# This file has be generated by Tricky's MyData"
WriteLine BT,"# "+CurrentDate()+"; "+CurrentTime()
If OutLicense WriteLine BT,"# License: "+OutLicense
'WriteLine BT,"~n~nglobal MyData~n"
'WriteLine bt,"INSERT INTO `mytable` set "
Local RK$,FK$
Local RF,FF
Local C$[]
For RK = EachIn MapKeys(Recs)
	If RF WriteLine BT,"~n~n" Else RF = True
	FF = False
	'WriteLine BT,"~t~q"+RK+"~q : {"
	WriteLine bt,"INSERT INTO `mytable` set "
	For fk = EachIn MapKeys(fields)
		If FF WriteLine BT,"," Else FF=True
		Select fields.value(fk)
			Case "string","mc"
				WriteString bt,"~t~t`"+Fk+"` = ~q"+Replace(Rec(RK).Value(FK),"~q","\~q")+"~q"
			Case "int","double"
				WriteString bt,"~t~t`"+Fk+"` : "+Rec(RK).Value(FK)
			'Case "color"
			'	C = (Rec(RK).Value(FK)+",0,0,0").split(",")
			'	WriteString bt,"~t~t~q"+fk+"~q : { 'R' : "+C[0]+", 'G' : "+C[1]+", 'B' : "+C[2]+" }"
			'Case "time"
			'	C = (Rec(RK).Value(FK)+",0,0,0").split(",")
			'	WriteString bt,"~t~t~q"+fk+"~q : { 'H' : "+C[0]+", 'M' : "+C[1]+", 'S' : "+C[2]+" }"
			'Case "date"
			'	C = (Rec(RK).Value(FK)+",0,0,0").split(",")
			'	WriteString bt,"~t~t~q"+fk+"~q : { 'D' : "+C[0]+", 'M' : "+C[1]+", 'Y' : "+C[2]+" }"
			Case "bool"
				If Rec(RK).value(fk) WriteString bt,"~t~t`"+fk+"` = "+Upper(Left(Rec(RK).Value(fk+".True"),1))+Lower(Right(Rec(RK).value(fk),Len(Rec(RK).value(fk))-1)) Else WriteString bt,"~t~t`"+fk+"` = False"
			Default
				WriteString bt,"~t~t# Unknown or incompatible field type: "+fields.value(fk)+" for field: "+fk	
			End Select
		Next
'	WriteString BT,"}"	
	Next
'WriteLine BT,"}"
'WriteLine BT,"~n~n#When imported you should have a variable called "+StripAll(OutputPythonBase)+".MyData, when imported you may have a global MyData variable."
WriteLine BT,"~n~n~n"
CloseFile BT
If Chat Notify "File saved as: "+OutputMySqlBase	
End Function


Function PerformSave(Resume=True)
HideGadget Win
Update
If AutoOutput
	If OutputLuaBase	Conv_BaseLua	False
	If outputPythonBase	Conv_BasePython	False
	If OutputLuaRec	Conv_RecLua	False
	If outputMySqlBase Conv_BaseMySql False
	EndIf
Local Ori:TList = Listfile("Databases/"+File$)
Local write = True
Local L$,TL$
Local BT:TStream = WriteFile("DataBases/"+File)
For l=EachIn ori
	TL = Trim(L)
	If Upper(TL)="[RECORDS]"
		write = False
	ElseIf Left(TL,1)="[" And Right(TL,1)="]"
		write = True
		EndIf		
	If write WriteLine BT,L
    Next
WriteLine BT,"[RECORDS]"
WriteLine BT,"# Everything below this line is the data itself"
WriteLine BT,"# It is updated by the MyData application"
WriteLine BT,"# automatically. Only change this if you know"
WriteLine BT,"# what you are doing. "
WriteLine BT,"# And placing comments here is pointless as"
WriteLine BT,"# they will be removed by MyData when you "
WriteLine BT,"# update this file :)~n"
Local RK$,FK$
For RK = EachIn MapKeys(Recs)
	WriteLine BT,"Rec: "+RK
	For fk = EachIn MapKeys(fields)
		WriteLine BT,"~t"+fk+" = "+Rec(RK).Value(FK)
		Next		
	WriteLine BT,""
	Next
CloseFile BT
If Resume
	Notify "File saved"	
	ShowGadget Win
	EndIf
End Function

Function Dance(fld$,BanList:TList,v:Byte)
	Local o = v And (Not ListContains(banlist,fld))
	Print "allow."+fld+" = "+o	
	If Not o ListAddLast banlist,fld
	Select fields.value(fld)
		Case "bool"
			gadfield(fld+".True").setenabled o
			gadfield(fld+".False").setenabled o
		Case "color"	
			gadfield(fld+".Red").setenabled o
			gadfield(fld+".Green").setenabled o
			gadfield(fld+".Blue").setenabled o
		Default
			gadfield(fld).setenabled o
	End Select
End Function		
	

Function RunAllow()
	Local key$,List:TList
	Local Boolean$[],v$,o,presult,work$
	Local OutCome:Byte
	Local r:StringMap = rec(currentrec)
	If Not r Return
	Local t$
	Local Blocked:TList = New TList
	For key$ = EachIn MapKeys(Allow)
		list = TList(MapValueForKey(Allow,key))
		boolean = key.split(" ")
		'If (Len boolean)<>1 And Len(Boolean)<>3 Error "Misformed Allow condition"
		v = boolean[0]
		If Prefixed(v,"!") v=Right(v,Len(v)-1); o=1
		Select (Len Boolean)
			Case 1				
				Select Fields.value(v)
					Case "string","mc","color"
							outcome = r.value(v)<>""
					Case "bool"	outcome = r.value(v)="TRUE"
					Case "int","double"	
							outcome = r.value(v).toInt()<>0
					Case ""
							error "Non-existent variable: "+v
					Default		error "Type ~q"+fields.value(v)+"~q is not (yet) compatible with the [ALLOW] conditional definitions"
				End Select
			Case 3
				Select Boolean[1]
					Case "=","=="
							outcome = r.value(v)=boolean[2]; 'Print v +" = "+r.value(v)+" = "+boolean[2]+" >>> "+outcome
					Case "{}"
							outcome = False
							For Local vvvv$=EachIn boolean[2].split(",") 
								outcome = outcome Or r.value(v)=vvvv
							Next			
					Case "!=","<>","~~=","=/="
							outcome = r.value(v)=boolean[2]	
					Case "<"
							Select fields.value(v)
								Case "int"	outcome = r.value(v).toint()<fields.value(boolean[2]).toint()
								Case "double"	outcome = r.value(v).todouble()<fields.value(boolean[2]).todouble()
								Default	error "Illegal type"
							End Select		
					Case ">"
							Select fields.value(v)
								Case "int"	outcome = r.value(v).toint()>fields.value(boolean[2]).toint()
								Case "double"	outcome = r.value(v).todouble()>fields.value(boolean[2]).todouble()
								Default	error "Illegal type"
							End Select		
					Case "<="
							Select fields.value(v)
								Case "int"	outcome = r.value(v).toint()<=fields.value(boolean[2]).toint()
								Case "double"	outcome = r.value(v).todouble()<=fields.value(boolean[2]).todouble()
								Default	error "Illegal type"
							End Select		
					Case ">="
							Select fields.value(v)
								Case "int"	outcome = r.value(v).toint()>=fields.value(boolean[2]).toint()
								Case "double"	outcome = r.value(v).todouble()>=fields.value(boolean[2]).todouble()
								Default	error "Illegal type"
							End Select	
					Default		Error "Unknown operand: "+boolean[1]	
				End Select													
			Default Error "Misformed Allow condition"
		End Select	
		If o outcome = Not outcome
		Local oc
		For Local wwork$ = EachIn TList(MapValueForKey(allow,key))
		 	work = wwork
			oc = outcome
			If Prefixed(work,"!") work=RemPrefix(work,"!") oc = Not outcome
			'presult = outcome And (Not ListContains(banned,work))	
			If Prefixed(work,"PREFIX:")
				For Local w$=EachIn MapKeys(fields)
					If RemPrefix(work,"PREFIX:")=w dance w,blocked,oc
				Next
			ElseIf Prefixed(work,"PAGE:")
				Print "Work with "+work+" >>> "+RemPrefix(work,"PAGE:")
				For Local w$=EachIn MapKeys(fieldonpage)
					'Print w+" = "+fieldonpage.value(w)+" "+remprefix(work,"PAGE:")+" "+Int(Trim(remprefix(work,"PAGE:"))=fieldonpage.value(w))
					If Trim(RemPrefix(work,"PAGE:"))=fieldonpage.value(w) dance w,blocked,oc
				Next
			Else
				dance work,blocked,oc	
			EndIf					
		Next	
	Next
End Function

'Main
Global ESource:TGadget
Global TFN$
CanWeEdit
recLua.setenabled OutPutLuaRec<>"" And OutputLuaRec<>"/"
Repeat
RunAllow
WaitEvent
ESource = TGadget(EventSource())
Select EventID()
	Case event_gadgetaction
		Select ESource
			Case tabber
				For Local ak=0 Until pages
					panels[ak].setshow ak=SelectedGadgetItem(tabber)
					Next
			Case NewRec
				CreateRecord 		
			Case duplic
				createrecord CurrentRec	
			Case remrec
				removerecord
			Case BasLua
				Conv_BaseLua	
			Case recLua
				Conv_RecLua
			Case BasPyt
				Conv_BasePython	
			Case RenRec
				RenameRecord	
			Case Save	
				PerformSave
			End Select
		For Local CG:TGadget = EachIn MapKeys(MapColor)
			tfn = String(MapValueForKey(MapColor,CG))
			If CG=ESource
				HideGadget win
				If RequestColor(TextFieldText(gadfield(tfn+".Red")).toint(),TextFieldText(gadfield(tfn+".Green")).toint(),TextFieldText(gadfield(tfn+".Blue")).toint())
					SetGadgetText gadfield(tfn+".Red"  ),RequestedRed()
					SetGadgetText gadfield(tfn+".Green"),RequestedGreen()
					SetGadgetText gadfield(tfn+".Blue" ),RequestedBlue()
					EndIf
				ShowGadget win	
				EndIf
			Next	
	Case EVENT_GADGETSELECT
		update	
	Case Event_AppTerminate,Event_Windowclose
		PerformSave False
		End	
	End Select	
update
Forever
