﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private menus As Map
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub get_isEnabled(key As String,parentmap As Map) As Boolean
	If parentmap.ContainsKey(key) = False Then
		Return False
	Else
		Return parentmap.Get(key)
	End If
End Sub

Sub getTextFromPane(index As Int,p As Pane) As String
	Dim ta As TextArea
	ta=p.GetNode(index)
	Return ta.Text 
End Sub

Sub enableMenuItems(mb As MenuBar,menuText As List)
	If menus.IsInitialized=False Then
		menus.Initialize
		CollectMenuItems(mb.Menus)
	End If
	For Each text As String In menuText
		Dim mi As MenuItem = menus.Get(text)
		mi.Enabled = True
	Next
End Sub

Sub disableMenuItems(mb As MenuBar,menuText As List)
	If menus.IsInitialized=False Then
		menus.Initialize
		CollectMenuItems(mb.Menus)
	End If
	For Each text As String In menuText
		Dim mi As MenuItem = menus.Get(text)
		mi.Enabled = False
	Next
End Sub

Sub CollectMenuItems(Items As List)
	For Each mi As MenuItem In Items
		If mi.Text <> Null And mi.Text <> "" Then menus.Put(mi.Text, mi)
		If mi Is Menu Then
			Dim mn As Menu = mi
			CollectMenuItems(mn.MenuItems)
		End If
	Next
End Sub

Sub ListViewParent_Resize(clv As CustomListView)
	If clv.Size=0 Then
		Return
	End If
	Dim itemWidth As Double = clv.AsView.Width
	Log(itemWidth)
	For i =  0 To clv.Size-1
		Dim p As Pane
		p=clv.GetPanel(i)
		If p.NumberOfNodes=0 Then
			Continue
		End If
		Dim sourcelbl,targetlbl As Label
		sourcelbl=p.GetNode(0)
		sourcelbl.SetSize(itemWidth/2,10)
		sourcelbl.WrapText=True
		targetlbl=p.GetNode(1)
		targetlbl.SetSize(itemWidth/2,10)
		targetlbl.WrapText=True
		Dim jo As JavaObject = p
		'force the label to refresh its layout.
		jo.RunMethod("applyCss", Null)
		jo.RunMethod("layout", Null)
		Dim h As Int = Max(Max(50, sourcelbl.Height + 20), targetlbl.Height + 20)
		p.SetLayoutAnimated(0, 0, 0, itemWidth, h + 10dip)
		sourcelbl.SetLayoutAnimated(0, 0, 0, itemWidth/2, h+5dip)
		targetlbl.SetLayoutAnimated(0, itemWidth/2, 0, itemWidth/2, h+5dip)
		clv.ResizeItem(i,h+10dip)
	Next
End Sub


Sub buildHtmlString(raw As String) As String
	Dim su As ApacheSU
	Dim result As String
	Dim htmlhead As String
	htmlhead="<!DOCTYPE HTML><html><head><meta charset="&Chr(34)&"utf-8"&Chr(34)&" /><style type="&Chr(34)&"text/css"&Chr(34)&">p {font-size: 18px}</style></head><body>"
	Dim htmlend As String
	htmlend="</body></html>"
	result=result&"<p>"&raw&"</p>"
	result=htmlhead&result&htmlend
	Return result
End Sub
