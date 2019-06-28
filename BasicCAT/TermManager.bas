﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.51
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private frm As Form
	Private SearchView1 As SearchView
	Private kvs As KeyValueStore
	Private externalTermRadioButton As RadioButton
	Private projectTermRadioButton As RadioButton
	Private tagList As List
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	frm.Initialize("frm",600,600)
	frm.RootPane.LoadLayout("TermManager")
	init
End Sub

Public Sub Show
	frm.Show
End Sub


Sub init
	tagList.Initialize
	kvs=Main.currentProject.projectTerm.terminology
	setItems
	Sleep(0)
	SearchView1.show
	addContextMenuToLV
End Sub

Sub setItems
	tagList.Clear
	Dim items As List
	items.Initialize
	For Each key As String In kvs.ListKeys
		Dim targetMap As Map
		targetMap=kvs.Get(key)
		For Each target As String In targetMap.Keys
			Dim terminfo As Map
			terminfo=targetMap.Get(target)
			Dim tag,note As String
			
			If terminfo.ContainsKey("tag") Then
				tag=terminfo.Get("tag")
				If tag.Trim<>"" And tagList.IndexOf(tag)=-1 Then
					tagList.Add(tag)
				End If
			End If
			If terminfo.ContainsKey("note") Then
				note=terminfo.Get("note")
			End If
			items.Add(buildItemText(key,target,note,tag))
		Next
	Next
	SearchView1.SetItems(items)
End Sub

Sub addContextMenuToLV
	Dim cm As ContextMenu
	cm.Initialize("cm")
	Dim mi As MenuItem
	mi.Initialize("Edit","mi")
	Dim mi2 As MenuItem
	mi2.Initialize("Remove","mi")
	Dim mi3 As MenuItem
	mi3.Initialize("View History","mi")
	cm.MenuItems.Add(mi)
	cm.MenuItems.Add(mi2)
	cm.MenuItems.Add(mi3)
	SearchView1.addContextMenuToLV(cm)
End Sub

Sub buildItemText(source As String,target As String,descrip As String,tag As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("- source: ").Append(source).Append(CRLF)
	sb.Append("- target: ").Append(target).Append(CRLF)
	sb.Append("- note: ").Append(descrip).Append(CRLF)
	sb.Append("- tag: ").Append(tag)
	Return sb.ToString
End Sub

Sub mi_Action
	Dim mi As MenuItem
	mi=Sender
	Select mi.Text
		Case "Edit"
			Dim p As Pane
			p=SearchView1.GetSelected
			Dim text As String
			text=p.Tag
			Dim source,target,tag,note As String
			source=Regex.Split(CRLF&"- ",text)(0).Replace("- source: ","")
			target=Regex.Split(CRLF&"- ",text)(1).Replace("target: ","")
			note=Regex.Split(CRLF&"- ",text)(2).Replace("note: ","")
			tag=Regex.Split(CRLF&"- ",text)(3).Replace("tag: ","")
			Dim targetMap As Map
			targetMap.Initialize
			targetMap=kvs.Get(source)
			Dim termEd As TermEditor
			termEd.Initialize(source,target,note,tag,tagList)
			Dim termData As Map
			termData.Initialize
			termData=termEd.showAndWait
			Dim terminfo As Map
			terminfo.Initialize
			terminfo.Put("tag",termData.Get("tag"))
			terminfo.Put("note",termData.Get("note"))
			Main.currentProject.projectTerm.editTerm(termData.Get("source"),target,termData.Get("target"),terminfo)
			setItems
			SearchView1.replaceItem(buildItemText(termData.Get("source"),termData.Get("target"),termData.Get("note"),termData.Get("tag")),SearchView1.GetSelectedIndex)
		Case "Remove"
			Dim result As Int=fx.Msgbox2(frm,"Will delete this entry, continue?","","Yes","","Cancel",fx.MSGBOX_CONFIRMATION)
			If result=fx.DialogResponse.POSITIVE Then
				Dim p As Pane
				p=SearchView1.GetSelected
				Dim text As String
				text=p.Tag
				Dim source,target As String
				source=Regex.Split(CRLF&"- ",text)(0).Replace("- source: ","")
				target=Regex.Split(CRLF&"- ",text)(1).Replace("target: ","")
				Dim targetMap As Map
				targetMap=kvs.Get(source)
				If targetMap.Size>1 Then
					Main.currentProject.projectTerm.removeOneTarget(source,target,True)
				Else
					kvs.Remove(source)
					Main.currentProject.projectTerm.removeFromSharedTerm(source)
				End If
				setItems
				SearchView1.GetItems.RemoveAt(SearchView1.GetSelectedIndex)
			End If
		Case "View History"
			Dim p As Pane
			p=SearchView1.GetSelected
			Dim text As String
			text=p.Tag
			Dim source,target As String
			source=Regex.Split(CRLF&"- ",text)(0).Replace("- source: ","")
			Dim hisViewer As HistoryViewer
			hisViewer.Initialize
			hisViewer.Show(Main.currentProject.projectHistory.getTermHistory(source))
	End Select
End Sub

Sub projectTermRadioButton_SelectedChange(Selected As Boolean)
	If Selected Then
		kvs=Main.currentProject.projectTerm.terminology
		setItems
		SearchView1.show
	End If
End Sub

Sub externalTermRadioButton_SelectedChange(Selected As Boolean)
	If Selected Then
		kvs=Main.currentProject.projectTerm.externalTerminology
		setItems
		SearchView1.show
	End If
End Sub

Sub ExportButton_MouseClicked (EventData As MouseEvent)
	Dim path As String
	Dim fc As FileChooser
	fc.Initialize
	'fc.SetExtensionFilter("tbx;txt",Array As String("*.tbx","*.txt"))
	FileChooserUtils.AddExtensionFilters4(fc,Array As String("TBX","tab-delimitted text","XLSX"),Array As String("*.tbx","*.txt","*.xlsx"),False,"All",False)
	path=fc.ShowSave(frm)
	If path="" Then
		Return
	End If
	If path.EndsWith(".tbx") Then
		TBX.export(kvs,Main.currentProject.projectFile.Get("source"),Main.currentProject.projectFile.Get("target"),path)
	Else if path.EndsWith(".txt") Then
		exportToTXT(path)
	Else if path.EndsWith(".xlsx") Then
		exportToXLSX(path)
	End If
End Sub

Sub exportToTXT(path As String)
	Main.currentProject.projectTerm.exportToTXT(TermsList,path)
	fx.Msgbox(frm,"exported","")
End Sub

Sub exportToXLSX(path As String)
	Dim wb As PoiWorkbook
	wb.InitializeNew(True)
	Dim sheet1 As PoiSheet=wb.AddSheet("Sheet1",0)
	Dim index As Int=0

	For Each segment As List In TermsList
		Dim row As PoiRow=	sheet1.CreateRow(index)
		row.CreateCellString(0,segment.Get(0))
		row.CreateCellString(1,segment.Get(1))
		row.CreateCellString(2,segment.Get(2))
		row.CreateCellString(3,segment.Get(3))
		index=index+1
	Next
	wb.Save(path,"")
	wb.Close
	fx.Msgbox(frm,"exported","")
End Sub

Sub TermsList As List
	Dim segments As List
	segments.Initialize
	For Each key As String In kvs.ListKeys
		Dim targetMap As Map
		targetMap=kvs.Get(key)
		For Each target As String In targetMap.Keys
			Dim bitext As List
			bitext.Initialize
			bitext.Add(key)
			bitext.Add(target)
			Dim terminfo As Map
			terminfo=targetMap.Get(targetMap.GetKeyAt(0))
			If terminfo.ContainsKey("note") Then
				bitext.Add(terminfo.Get("note"))
			Else
				bitext.Add("")
			End If
			If terminfo.ContainsKey("tag") Then
				bitext.Add(terminfo.Get("tag"))
			Else
				bitext.Add("")
			End If
			segments.Add(bitext)
		Next
	Next
	Return segments
End Sub