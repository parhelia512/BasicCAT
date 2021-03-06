﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private parser As SaxParser
	Private tuvs As List
	Private tus As List
	Private aSourceLang,aTargetLang As String
	Private numbers As Int
End Sub

Sub parse(dir As String,filename As String)
	tus.Initialize
	tuvs.Initialize
	parser.Initialize
	Dim in As InputStream
	in = File.OpenInput(dir, filename) 'This file was added with the file manager.
	parser.Parse(in, "Parser") '"Parser" is the events subs prefix.
	in.Close
	Log("tus:"&tus)
End Sub

Sub Parser_StartElement (Uri As String, Name As String, Attributes As Attributes)
    If Name="tuv" Or Name="tu" Then
		Dim map1 As Map
		map1.Initialize
		Dim attr As Map
		attr.Initialize
		For i=0 To Attributes.Size-1
			attr.Put(Attributes.GetName(i),Attributes.GetValue(i))
		Next
		map1.Put("Attributes",attr)
		Select Name 
			Case "tuv"
				tuvs.Add(map1)
			Case "tu"
				tus.Add(map1)
		End Select
		
	End If
End Sub

Sub Parser_EndElement (Uri As String, Name As String, Text As StringBuilder)
	If Name="seg" Then
		numbers=numbers+1
		Dim map1 As Map = tuvs.Get(tuvs.Size-1)
		Dim Attributes As Map =map1.Get("Attributes")
		'Log(Attributes.GetValue2("","xml:lang"))
		Dim lang As String
		If Attributes.ContainsKey("xml:lang") Then
			lang=Attributes.Get("xml:lang")
		else if Attributes.ContainsKey("lang") Then
			lang=Attributes.Get("lang")
		End If
		lang=lang.ToLowerCase
		'Log("lang: "&lang)
		If lang.StartsWith(aSourceLang) Or lang.StartsWith(aTargetLang) Then
			map1.Put("Text",Text.ToString)
		Else
			tuvs.RemoveAt(tuvs.Size-1)
		End If
		'Log(map1)
		'Log(numbers)
	else if Name="note" Then
		Dim map1 As Map = tus.Get(tus.Size-1)
		map1.Put("note",Text.ToString)
	Else if Name = "tu" Then
		Dim newList As List
		newList.Initialize
		newList.AddAll(tuvs)
		Dim map1 As Map = tus.Get(tus.Size-1)
		map1.Put("tuv",newList)
		tuvs.Clear
	End If
End Sub


Sub importedListQuick(dir As String,filename As String,sourceLang As String,targetLang As String) As List
	Dim segments As List
	segments.Initialize
	aSourceLang=sourceLang.ToLowerCase
	aTargetLang=targetLang.ToLowerCase
	
	parse(dir,filename)
	For Each tu As Map In tus
		Dim tuvList As List= tu.Get("tuv")
		Dim bitext As List
		bitext.Initialize
		Dim targetMap As Map
		targetMap.Initialize
		bitext.Add("source")
		bitext.Add("target")
		Dim addedTimes As Int=0
		For Each tuv As Map In tuvList
			Dim Attributes As Map =tuv.Get("Attributes")
			'Log(Attributes.GetValue2("","xml:lang"))
			Dim lang As String
			If Attributes.ContainsKey("xml:lang") Then
				lang=Attributes.Get("xml:lang")
			else if Attributes.ContainsKey("lang") Then
				lang=Attributes.Get("lang")
			End If
			lang=lang.ToLowerCase
			If lang.StartsWith(sourceLang) Then
				bitext.Set(0,tuv.Get("Text"))
				addedTimes=addedTimes+1
			else if lang.StartsWith(targetLang) Then
				bitext.Set(1,tuv.Get("Text"))
				addedTimes=addedTimes+1
			Else 
				Continue
			End If
			If Attributes.ContainsKey("creationid") And Attributes.ContainsKey("creationdate") Then
				Try
					Dim creationdate As String
					creationdate=Attributes.Get("creationdate")
					DateTime.DateFormat="yyyyMMdd"
					DateTime.TimeFormat="HHmmss"
					Dim date As String
					Dim time As String
					date=creationdate.SubString2(0,creationdate.IndexOf("T"))
					time=creationdate.SubString2(creationdate.IndexOf("T")+1,creationdate.IndexOf("Z"))
					targetMap.Put("createdTime",DateTime.DateTimeParse(date,time))
					targetMap.Put("creator",Attributes.Get("creationid"))
				Catch
					Log(LastException)
				End Try
			End If
		Next
		If addedTimes<>2 Then
			Continue
		End If
		If tu.ContainsKey("note") Then
			targetMap.Put("note",tu.Get("note"))
		End If
		bitext.Add(filename)
		bitext.Add(targetMap)
		segments.Add(bitext)
	Next

	Return segments
End Sub

Sub importedList(dir As String,filename As String,sourceLang As String,targetLang As String) As List
	Dim segments As List
	segments.Initialize
	Dim tmxString As String
	tmxString=XMLUtils.escapedText(File.ReadString(dir,filename),"seg","tmx")
	Dim tmxMap As Map
	tmxMap=XMLUtils.getXmlMap(tmxString)
	'Log(tmxMap)
	Dim tmxroot As Map
	tmxroot=tmxMap.Get("tmx")
	Dim body As Map
	body=tmxroot.Get("body")
	Dim tuList As List
	tuList=XMLUtils.GetElements(body,"tu")
	For Each tu As Map In tuList
		Dim bitext As List
		bitext.Initialize
		Dim tuvList As List
		tuvList=XMLUtils.GetElements(tu,"tuv")
		Dim targetMap As Map
		targetMap.Initialize
		bitext.Add("source")
		bitext.Add("target")
		For Each tuv As Map In tuvList
			Dim attributes As Map
			attributes=tuv.Get("Attributes")
			Dim lang As String
			If attributes.ContainsKey("lang") Then
				lang=attributes.Get("lang")
			else if attributes.ContainsKey("xml:lang") Then
				lang=attributes.Get("xml:lang")
			End If
			lang=lang.ToLowerCase
			If lang.StartsWith(sourceLang) Then
				bitext.Set(0,tuv.Get("seg"))
			else if lang.StartsWith(targetLang) Then
				bitext.Set(1,tuv.Get("seg"))
				targetMap.Put("text",tuv.Get("seg"))
				If tuv.ContainsKey("Attributes") Then
					Dim attributes As Map
					attributes=tuv.Get("Attributes")
					If attributes.ContainsKey("creationid") And attributes.ContainsKey("creationdate") Then
						Try
							Dim creationdate As String
							creationdate=attributes.Get("creationdate")
							DateTime.DateFormat="yyyyMMdd"
							DateTime.TimeFormat="HHmmss"
							Dim date As String
							Dim time As String
							date=creationdate.SubString2(0,creationdate.IndexOf("T"))
							time=creationdate.SubString2(creationdate.IndexOf("T")+1,creationdate.IndexOf("Z"))
							'Log("date: "&date)
							'Log("time: "&time)
							'Log(DateTime.DateTimeParse(date,time))
							targetMap.Put("createdTime",DateTime.DateTimeParse(date,time))
							targetMap.Put("creator",attributes.Get("creationid"))
						Catch
							Log(LastException)
						End Try
					End If
				End If
			End If
		Next
		If tu.ContainsKey("note") Then
			targetMap.Put("note",tu.Get("note"))
		End If
        'Log(tu)
		
		
		bitext.Add(filename)
		bitext.Add(targetMap)
		segments.Add(bitext)
	Next
	Return segments
End Sub

Sub export(segments As List,sourceLang As String,targetLang As String,path As String,includeTag As Boolean,isUniversal As Boolean)
	Dim rootmap As Map
	rootmap.Initialize
	Dim tmxMap As Map
	tmxMap.Initialize
	tmxMap.Put("Attributes",CreateMap("version":"1.4"))
	Dim headerAttributes As Map
	headerAttributes.Initialize
	headerAttributes.Put("creationtool","BasicCAT")
	headerAttributes.Put("creationtoolversion","1.0.0")
	headerAttributes.put("adminlang",sourceLang)
	headerAttributes.put("srclang",sourceLang)
	headerAttributes.put("segtype","sentence")
	headerAttributes.put("o-tmf","BasicCAT")
	tmxMap.Put("header",headerAttributes)
	Dim body As Map
	body.Initialize
	Dim tuList As List
	tuList.Initialize
	For Each bitext As List In segments
		Dim tuMap As Map
		tuMap.Initialize
		Dim tuvList As List
		tuvList.Initialize

		Dim index As Int=0
		For Each seg As String In bitext
			Dim targetMap As Map
			targetMap=bitext.Get(2)
			
			If includeTag=False Then
				seg=Regex.Replace2("<.*?>",32,seg,"")
			End If
			index=index+1
			If index = 2 Then
				Dim targetTuvMap As Map
				targetTuvMap=CreateMap("seg":seg)
				Dim attributes As Map
				attributes.Initialize
				attributes.Put("xml:lang",targetLang)
				If targetMap.ContainsKey("creator") Then
					attributes.Put("creationid",targetMap.Get("creator"))
				End If
				If targetMap.ContainsKey("createdTime") Then
					Dim creationDate As String
					DateTime.DateFormat="yyyyMMdd"
					DateTime.TimeFormat="HHmmss"
					creationDate=DateTime.Date(targetMap.Get("createdTime"))&"T"&DateTime.Time(targetMap.Get("createdTime"))&"Z"
					attributes.Put("creationdate",creationDate)
				End If
		
				If attributes.Size<>0 Then
					targetTuvMap.Put("Attributes",attributes)
				End If
				tuvList.Add(targetTuvMap)
			Else if index = 1 Then 
				tuvList.Add(CreateMap("Attributes":CreateMap("xml:lang":sourceLang),"seg":seg))
			End If
		Next
		

		
		If targetMap.ContainsKey("note") Then
			If targetMap.Get("note")<>"" Then
				tuMap.Put("note",targetMap.Get("note"))
			End If
		End If
		
		
		
		tuMap.Put("tuv",tuvList)
		tuList.Add(tuMap)
	Next
	body.Put("tu",tuList)
	tmxMap.Put("body",body)
	rootmap.Put("tmx",tmxMap)
	Dim tmxstring As String
	Try
		tmxstring=XMLUtils.getXmlFromMap(rootmap)
	Catch
		fx.Msgbox(Main.MainForm,"export failed because of tag problem","")
		Return
		Log(LastException)
	End Try

	If includeTag=True And isUniversal=True Then
		tmxstring=XMLUtils.unescapedText(tmxstring,"seg","tmx")
		tmxstring=convertTags(tmxstring)
		
	End If
	
	File.WriteString(path,"",tmxstring)
End Sub

Sub convertTags(xmlstring As String) As String
	Dim inSegMatcher As Matcher
	inSegMatcher=Regex.Matcher2("<seg>(.*?)</seg>",32,xmlstring)
	Dim replacements As List
	replacements.Initialize
	Do While inSegMatcher.Find

		Dim group As String 
		group=convertOneSeg(inSegMatcher.Group(1))
		If group<>inSegMatcher.Group(1) Then
			Dim replacement As Map
			replacement.Initialize
			replacement.Put("start",inSegMatcher.GetStart(1))
			replacement.Put("end",inSegMatcher.GetEnd(1))
			replacement.Put("group",group)
			replacements.InsertAt(0,replacement)
		End If
	Loop
	
	Dim new As String=xmlstring
	For Each replacement As Map In replacements
		Dim startIndex,endIndex As Int
		Dim group As String
		startIndex=replacement.Get("start")
		endIndex=replacement.Get("end")
		group=replacement.Get("group")
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append(new.SubString2(0,startIndex))
		sb.Append(group)
		sb.Append(new.SubString2(endIndex,new.Length))
		new=sb.ToString
	Next
	
	Return new
End Sub

Sub convertOneSeg(seg As String) As String
	Dim tagMatcher As Matcher
	tagMatcher=Regex.Matcher2("<(bpt|ept|hi|it|ph|sub|ut).*?>",32,seg)
	Dim replacements As List
	replacements.Initialize
	Do While tagMatcher.Find
		Dim group As String
		If tagMatcher.Match.Contains("/>")=False Then
			group=convertToUniversalTag(tagMatcher.Group(0)&"</"&tagMatcher.Group(1)&">")
			group=group.Replace("</"&tagMatcher.Group(1)&">","")
			group=group.Replace("/>",">")
		Else
			group=convertToUniversalTag(tagMatcher.Group(0))
		End If
		If group<>tagMatcher.Group(0) Then
			Dim replacement As Map
			replacement.Initialize
			replacement.Put("start",tagMatcher.GetStart(0))
			replacement.Put("end",tagMatcher.GetEnd(0))
			replacement.Put("group",group)
			replacements.InsertAt(0,replacement)
		End If

	Loop
	
	Dim new As String=seg
	For Each replacement As Map In replacements
		Dim startIndex,endIndex As Int
		Dim group As String
		startIndex=replacement.Get("start")
		endIndex=replacement.Get("end")
		group=replacement.Get("group")
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append(new.SubString2(0,startIndex))
		sb.Append(group)
		sb.Append(new.SubString2(endIndex,new.Length))
		new=sb.ToString
	Next
	
	Return new
End Sub

Sub convertToUniversalTag(xmlstring As String) As String
	Log("xml"&xmlstring)
	Try
		Dim inlineTagMap As Map
		inlineTagMap=XMLUtils.getXmlMap(xmlstring)
		
		Dim innerMap As Map
		innerMap=inlineTagMap.GetValueAt(0)

		Dim attributes As Map
		attributes=innerMap.Get("Attributes")
		If attributes.ContainsKey("id") And attributes.ContainsKey("x")=False Then
			attributes.Put("x",attributes.Get("id"))
		End If
	
		Dim keys As List
		keys.Initialize
		For Each key As String In attributes.keys
			keys.add(key)
		Next
	
		For Each key As String In keys
			If key<>"x" And key<>"pos" And key<>"datatype" And key<>"i" And key<>"assoc" And key<>"type" Then
				attributes.Remove(key)
			End If
		Next

		Dim result As String=XMLUtils.getXmlFromMap(inlineTagMap)
		result=Regex.Replace("<\?xml.*?>",result,"")
		result=result.Trim

	Catch
		Log(LastException)
		result=xmlstring
		
	End Try
	Log(result&"result")
	Return result
End Sub
