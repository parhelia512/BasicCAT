﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private rules As Map
	Private previousLang As String
End Sub

Sub readRules(lang As String,path As String)
	If rules.IsInitialized=False Then
		rules.Initialize
	End If
	If previousLang<>lang Then
		previousLang=lang
		Dim configPath As String=File.Combine(path,"config")
		If File.Exists(configPath,"segmentationRules.srx") Then
			rules=SRX.readRules(File.Combine(configPath,"segmentationRules.srx"),lang)
		Else
			rules=SRX.readRules(File.Combine(File.DirAssets,"segmentationRules.srx"),lang)
		End If
	End If
End Sub

Sub segmentedTxt(text As String,sentenceLevel As Boolean,sourceLang As String,path As String) As ResumableSub
	'Log("text"&text)
	readRules(sourceLang,path)
	Dim segments As List
	segments.Initialize
    If text.Trim="" Then
		segments.Add(text)
		Return segments
    End If
	Dim splitted As List
	splitted.Initialize
	splitted.AddAll(Regex.Split(CRLF,text))
	If sentenceLevel Then
		Dim index As Int=-1
		'Log("para"&splitted)
		For Each para As String In splitted
			index=index+1
			wait for (paragraphInSegments(para)) Complete (resultList As List)
			segments.AddAll(resultList)
			'Log(para)
			'Log(segments)
			'Log(segments.Size)
			If segments.Size>0 Then
				Dim last As String
				last=segments.Get(segments.Size-1)

				If index<>splitted.Size-1 Then
					last=last&CRLF
				Else if text.EndsWith(CRLF)=True Then
					last=last&CRLF
				End If
				segments.set(segments.Size-1,last)
			Else
				segments.Add(para&CRLF) ' if there are several LFs at the beginning
			End If
		Next
	Else
		segments.AddAll(splitted)
	End If

	'Log(segments)
	Return segments
End Sub

Sub paragraphInSegmentsCas(text As String) As List
	Dim breakRules,nonbreakRules As List
	breakRules=rules.Get("breakRules")
	nonbreakRules=rules.Get("nonbreakRules")
	
	Dim allRulesList As List
	allRulesList.Initialize
	allRulesList.Addall(nonbreakRules)
	allRulesList.Addall(breakRules)

	Dim previousText As String
	Dim segments As List
	segments.Initialize
	For i=0 To text.Length-1
		previousText=""
		'Log(i)

		For Each seg As String In segments

			previousText=previousText&seg
		Next
		Dim currentText As String
		currentText=text.SubString2(previousText.Length,i)
		'Log("ct"&currentText)
		'Log("pt"&previousText)
		'Log(currentText.Length+previousText.Length)
		'Log(text.Length)
		Dim matched As Boolean=False
		For Each rule As Map In allRulesList

			If matched Then
				Exit
			End If
			
			Dim beforeBreak,afterBreak As String
			beforeBreak=rule.Get("beforebreak")
			afterBreak=rule.Get("afterbreak")
			Dim bbm As Matcher
			bbm=Regex.Matcher2(beforeBreak,32,currentText)
			If beforeBreak<>"null" Then
				Do While bbm.find
					Log(i)
					Log(bbm.Match)
					'Log("end"&bbm.GetEnd(0))
					'Log("i"&i)
					If matched Then
						Exit
					End If
					If bbm.GetEnd(0)+previousText.Length<>i Then
						Continue
					End If
					'Log("bbmfind")
					'Log(bbm.Match)
					'Log(beforeBreak)

					If afterBreak="null" Then
						If rule.Get("break")="yes" Then
							segments.Add(currentText)
							'Log(currentText)
							'Log(rule)
						End If
						
						matched=True
						Exit
					End If
					
					Dim abm As Matcher
					abm=Regex.Matcher2(afterBreak,32,text.SubString2(previousText.Length,text.Length))
					'Log("at"&text.SubString2(previousText.Length,text.Length))
					Do While abm.Find
						Log("ab"&abm.Match)
						If abm.GetStart(0)=bbm.GetEnd(0) Then
							Log("abm")
							If rule.Get("break")="yes" Then
								segments.Add(currentText)
								'Log(currentText)
								'Log(rule)
							End If
							matched=True
							Exit
						End If
						If abm.GetStart(0)>currentText.Length Then
							Exit
						End If
					Loop
				Loop
			Else if afterBreak<>"null" Then
				Dim abm As Matcher
				abm=Regex.Matcher2(afterBreak,32,text.SubString2(previousText.Length,text.Length))
				Do While abm.Find
					If abm.GetStart(0)=bbm.GetEnd(0) Then
						If rule.Get("break")="yes" Then
							segments.Add(currentText)
							'Log(currentText)
							'Log(rule)
						End If
						matched=True
						Exit
					End If
                    If abm.GetStart(0)>currentText.Length Then
						Exit
                    End If
				Loop
			End If
		Next
	Next
	
	'Log(segments)
	previousText=""
	For Each seg As String In segments
		previousText=previousText&seg
	Next
	If previousText.Length<>text.Length Then
		segments.Add(text.SubString2(previousText.Length,text.Length))
	End If
	'Log(segments)
	Return segments
End Sub

Sub paragraphInSegments(text As String) As ResumableSub

	Dim breakRules,nonbreakRules As List
	breakRules=rules.Get("breakRules")
	nonbreakRules=rules.Get("nonbreakRules")
	Dim previousText As String
	Dim segments As List
	segments.Initialize
	

	Dim breakPositions As List
	breakPositions.Initialize
	breakPositions.AddAll(getPositions(breakRules,text))
	breakPositions.Sort(True)
	removeDuplicated(breakPositions)
	
	Dim nonbreakPositions As List
	nonbreakPositions.Initialize
	nonbreakPositions.AddAll(getPositions(nonbreakRules,text))
	nonbreakPositions.Sort(True)
	removeDuplicated(nonbreakPositions)

	Dim finalBreakPositions As List
	finalBreakPositions.Initialize
	For Each index As Int In breakPositions
		If nonbreakPositions.IndexOf(index)=-1 Then
			finalBreakPositions.Add(index)
		End If
	Next
	'Log(breakPositions)
	'Log(nonbreakPositions)
	'Log(finalBreakPositions)
	For Each index As Int In finalBreakPositions
		Dim textTobeAdded As String
		textTobeAdded=text.SubString2(previousText.Length,index)
		segments.Add(textTobeAdded)
		previousText=text.SubString2(0,index)
	Next
	If previousText.Length<>text.Length Then
		segments.Add(text.SubString2(previousText.Length,text.Length))
	End If
	
	Return segments
End Sub

Sub removeDuplicated(source As List)
	Dim newList As List
	newList.Initialize
	For Each index As Int In source
		If newList.IndexOf(index)=-1 Then
			newList.Add(index)
		End If
	Next
	source.Clear
	source.AddAll(newList)
End Sub

Sub getPositions(rulesList As List,text As String) As List
	Dim breakPositions As List
	breakPositions.Initialize
	Dim textLeft As String
	For Each rule As Map In rulesList
		'Log(rule)
		textLeft=text
		Dim beforeBreak,afterBreak As String
		beforeBreak=rule.Get("beforebreak")
		afterBreak=rule.Get("afterbreak")

		Dim bbm As Matcher
		bbm=Regex.Matcher2(beforeBreak,32,textLeft)

		If beforeBreak<>"null" Then
			Do While bbm.Find
				If afterBreak="null" Then
					breakPositions.Add(bbm.GetEnd(0)+text.Length-textLeft.Length)
					textLeft=textLeft.SubString2(bbm.GetEnd(0),textLeft.Length)
					bbm=Regex.Matcher2(beforeBreak,32,textLeft)

				End If
			
				Dim abm As Matcher
				abm=Regex.Matcher2(afterBreak,32,textLeft)
				Do While abm.Find
					If bbm.GetEnd(0)=abm.GetStart(0) Then
						breakPositions.Add(bbm.GetEnd(0)+text.Length-textLeft.Length)
						textLeft=textLeft.SubString2(bbm.GetEnd(0),textLeft.Length)
						abm=Regex.Matcher2(afterBreak,32,textLeft)
						bbm=Regex.Matcher2(beforeBreak,32,textLeft)

						Exit
					End If
				Loop
			Loop
		Else if afterBreak<>"null" Then
			Dim abm As Matcher
			abm=Regex.Matcher2(afterBreak,32,textLeft)
			Do While abm.Find
				breakPositions.Add(abm.GetEnd(0)+text.Length-textLeft.Length)
				textLeft=textLeft.SubString2(abm.GetEnd(0),textLeft.Length)
				abm=Regex.Matcher2(afterBreak,32,textLeft)
			Loop
		End If
	Next
	
	Return breakPositions
End Sub

Sub removeSpacesAtBothSides(path As String,targetLang As String,text As String,removeRedundantSpaces As Boolean) As String
	readRules(targetLang,path)
	Dim breakRules As List=rules.Get("breakRules")
	Dim breakPositions As List
	breakPositions=getPositions(breakRules,text)
	breakPositions.Sort(False)
	removeDuplicated(breakPositions)
	For Each position As Int In breakPositions
		Try
			'Log(position)
			'Log(text)
			'Log("charat"&text.CharAt(position))
			'Log("remove space:")
			'Log(text.CharAt(position)=" ")
			Dim offsetToRight As Int=0
			For i=0 To Max(text.Length-1-position,0)
				If position+i<=text.Length-1 Then
					If text.CharAt(position+i)=" " Then
						offsetToRight=offsetToRight+1
					Else
						Exit
					End If
				End If
			Next
			Dim rightText As String
			If position+offsetToRight<=text.Length-1 Then
				rightText=text.SubString2(position+offsetToRight,text.Length)
			End If
			text=text.SubString2(0,position)&rightText
		Catch
			Log(LastException)
		End Try
	Next
	If removeRedundantSpaces Then
		text=Regex.Replace2("\b *\B",32,text,"")
		text=Regex.Replace2("\B *\b",32,text,"")
	Else
		If text.StartsWith(" ") Then
			text=text.SubString2(1,text.Length)
		End If
	End If

	Return text
End Sub

Public Sub segmentedTxtSimpleway(text As String,Trim As Boolean,sourceLang As String,filetype As String) As List
	
	'File.WriteString(File.DirApp,"1-before",text)
	Dim segmentationRule As List
	If filetype="idml" Then
		segmentationRule=File.ReadList(File.DirAssets,"segmentation_"&sourceLang&"_idml.conf")
	Else
		segmentationRule=File.ReadList(File.DirAssets,"segmentation_"&sourceLang&".conf")
	End If
	
	Dim segmentationExceptionRule As List
	segmentationExceptionRule=File.ReadList(File.DirAssets,"segmentation_"&sourceLang&"_exception.conf")
	
	Dim seperator As String
	seperator="------"&CRLF
	
	Dim seperated As String
	seperated=text
	For Each rule As String In segmentationRule
		seperated=Regex.Replace(rule,seperated,"$0"&seperator)
	Next

	For Each rule As String In segmentationExceptionRule
		seperated=seperated.Replace(rule&seperator,rule)
	Next
	Dim out As List
	out.Initialize
	For Each sentence As String In Regex.Split(seperator,seperated)
		If Trim Then
			sentence=sentence.Trim
		End If
		out.Add(sentence)
	Next
	
	Dim after As String
	For Each sentence As String In out
		after=after&sentence
	Next
	'File.WriteString(File.DirApp,"1-after",after)
	Return out
End Sub