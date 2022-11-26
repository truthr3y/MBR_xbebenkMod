; #FUNCTION# ====================================================================================================================
; Name ..........: GetVillageSize
; Description ...: Measures the size of village. After CoC October 2016 update, max'ed zoomed out village is 440 (reference!)
;                  But usually sizes around 470 - 490 pixels are measured due to lock on max zoom out.
; Syntax ........: GetVillageSize()
; Parameters ....:
; Return values .: 0 if not identified or Array with index
;                      0 = Size of village (float)
;                      1 = Zoom factor based on 440 village size (float)
;                      2 = X offset of village center (int)
;                      3 = Y offset of village center (int)
;                      4 = X coordinate of stone
;                      5 = Y coordinate of stone
;                      6 = stone image file name
;                      7 = X coordinate of tree
;                      8 = Y coordinate of tree
;                      9 = tree image file name
; Author ........: Cosote (Oct 17th 2016)
; Modified ......: xbebenk (June 2022)
; Removed Fix village measurement if using shared_prefs as I dont know how it works :(
; Change the logic for measure village size, zoomlevel now measured from tree to stone
; And then compare it with Reference size
; All scenery (as this code modified: 01 June 2022) is supported
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func GetVillageSize($DebugLog = Default, $sStonePrefix = Default, $sTreePrefix = Default, $sFixedPrefix = Default, $bOnBuilderBase = Default)
	FuncEnter(GetVillageSize)
	Local $stone = [0, 0, 0, 0, 0, ""], $tree = [0, 0, 0, 0, 0, ""]
	If $DebugLog = Default Then $DebugLog = False
	If $sStonePrefix = Default Then $sStonePrefix = "stone"
	If $sTreePrefix = Default Then $sTreePrefix = "tree"
	
	If IsFullScreenWindow() Then
		Click(825,45)
		_Sleep(2000)
	EndIf
	
	If $bOnBuilderBase = Default Then
		$bOnBuilderBase = isOnBuilderBase(True)
	EndIf
	
	Local $sDirectory
	If $bOnBuilderBase Then
		$sDirectory = $g_sImgZoomOutDirBB
		$g_sSceneryCode = "BB"
	Else
		$sDirectory = $g_sImgZoomOutDir
	EndIf
	
	Local $iAdditionalX = 100
	Local $iAdditionalY = 100
	Local $aResult = 0, $stone, $tree, $x, $y
	
	$stone = FindStone($sDirectory, $sStonePrefix, $iAdditionalX, $iAdditionalY)
	SetDebugLog("stone: " & _ArrayToString($stone))
	If $stone[0] = 0 Then
		SetDebugLog("GetVillageSize cannot find stone", $COLOR_WARNING)
		If $bOnBuilderBase Then ZoomOutHelperBB("GetVillageSize")
		Return FuncReturn($aResult)
	EndIf
	
	$tree = FindTree($sDirectory, $sTreePrefix, $iAdditionalX, $iAdditionalY, $stone[4])
	SetDebugLog("tree: " & _ArrayToString($tree))
	If $tree[0] = 0 Then
		SetDebugLog("GetVillageSize cannot find tree", $COLOR_ACTION)
		If $bOnBuilderBase Then ZoomOutHelperBB("GetVillageSize")
		Return FuncReturn($aResult)
	Else
		; calculate village size, see https://en.wikipedia.org/wiki/Pythagorean_theorem
		Local $a = $tree[0] - $stone[0]
		Local $b = $stone[1] - $tree[1]
		Local $c = Sqrt($a * $a + $b * $b) ;measure distance from stone to tree
			
		Local $iRefSize = 600
		Local $iIndex = _ArraySearch($g_aVillageRefSize, $stone[4])
		If $iIndex <> -1 Then 
			$iRefSize = $g_aVillageRefSize[$iIndex][2]
			$g_sSceneryCode = $g_aVillageRefSize[$iIndex][0]
			$g_sCurrentScenery = $g_aVillageRefSize[$iIndex][1]
			$InnerDiamondLeft = $g_aVillageRefSize[$iIndex][3]
			$InnerDiamondRight = $g_aVillageRefSize[$iIndex][4]
			$InnerDiamondTop = $g_aVillageRefSize[$iIndex][5]
			$InnerDiamondBottom = $g_aVillageRefSize[$iIndex][6]
			SetDebugLog("LRTB: " & $InnerDiamondLeft & "," & $InnerDiamondRight & "," & $InnerDiamondTop & "," & $InnerDiamondBottom)
		Else
			SetLog("Reference Size no match", $COLOR_ERROR)
			Return FuncReturn($aResult)
		EndIf
		
		Local $z = $c / $iRefSize
		SetDebugLog("Scenery = " & $g_sCurrentScenery, $COLOR_INFO)
		SetDebugLog("Stone2tree = " & $c)
		SetDebugLog("Reference = " & $iRefSize)
		SetDebugLog("ZoomLevel = " & $z)
		
		Local $stone_x_exp = $stone[2]
		Local $stone_y_exp = $stone[3]
		ConvertVillagePos($stone_x_exp, $stone_y_exp, $z) ; expected x, y position of stone
		$x = $stone[0] - $stone_x_exp
		$y = $stone[1] - $stone_y_exp
		
		$g_iZoomFactor = $z
		$g_ixOffset = $x
		$g_iyOffset = $y
		
		SetDebugLog("GetVillageSize measured: " & $c & ", Zoom factor: " & $z & ", Offset: " & $x & ", " & $y, $COLOR_INFO)

		Dim $aResult[10]
		$aResult[0] = $c
		$aResult[1] = $z
		$aResult[2] = $x
		$aResult[3] = $y
		$aResult[4] = $stone[0]
		$aResult[5] = $stone[1]
		$aResult[6] = $stone[5]
		$aResult[7] = $tree[0]
		$aResult[8] = $tree[1]
		$aResult[9] = $tree[5]

		$g_aVillageSize = $aResult
		
		Return FuncReturn($aResult)
	EndIf
	FuncReturn()
EndFunc   ;==>GetVillageSize

Func FindStone($sDirectory = $g_sImgZoomOutDir, $sStonePrefix = "stone", $iAdditionalX = 100, $iAdditionalY = 100)
	Local $stone = [0, 0, 0, 0, 0, ""]
	Local $x0, $y0, $d0, $x, $y, $x1, $y1, $right, $bottom, $a, $b
	Local $aStoneFiles
	
	For $check = 1 To 2
		If $check = 1 Then 
			SetDebugLog("Checking for same scenery: " & $g_sSceneryCode)
			$aStoneFiles = _FileListToArray($sDirectory & "stone\", $sStonePrefix & $g_sSceneryCode & "*.*", $FLTA_FILES)
		Else
			$aStoneFiles = _FileListToArray($sDirectory & "stone\", $sStonePrefix & "*.*", $FLTA_FILES)
		EndIf
		
		If @error Then
			SetDebugLog("Error: Missing stone files (" & @error & ")", $COLOR_ERROR)
			ContinueLoop
		EndIf
		
		Local $i, $findImage, $sArea, $StoneName
		For $i = 1 To $aStoneFiles[0]
			$findImage = $aStoneFiles[$i]
			$a = StringRegExp($findImage, "stone([0-9A-Z]+)-(\d+)-(\d+)_.*[.](xml|png|bmp)$", $STR_REGEXPARRAYMATCH)
			If UBound($a) = 4 Then
				$StoneName = $a[0]
				$d0 = $StoneName
				$x0 = $a[1]
				$y0 = $a[2]
				$x1 = $x0 - $iAdditionalX
				$y1 = $y0 - $iAdditionalY
				$right = $x0 + $iAdditionalX
				$bottom = $y0 + $iAdditionalY
				$sArea = Int($x1) & "," & Int($y1) & "|" & Int($right) & "," & Int($y1) & "|" & Int($right) & "," & Int($bottom) & "|" & Int($x1) & "," & Int($bottom)
				SetDebugLog("GetVillageSize check for image " & $findImage)
				$b = decodeSingleCoord(findImage("stone" & $StoneName, $sDirectory & "stone\" & $findImage, $sArea, 1, True))
				If UBound($b) = 2 Then
					$x = Int($b[0])
					$y = Int($b[1])
					SetDebugLog("Found stone image at " & $x & ", " & $y & ": " & $findImage, $COLOR_INFO)
					$stone[0] = $x ; x center of stone found
					$stone[1] = $y ; y center of stone found
					$stone[2] = $x0 ; x center of reference stone
					$stone[3] = $y0 ; y center of reference stone
					$stone[4] = $d0 ; distance from stone to tree in pixel
					$stone[5] = $findImage
					ExitLoop 2
				EndIf
			Else
				SetDebugLog("GetVillageSize ignore image " & $findImage & ", reason: " & UBound($a), $COLOR_WARNING)
			EndIf
		Next
	Next
	Return $stone
EndFunc

Func FindTree($sDirectory = $g_sImgZoomOutDir, $sTreePrefix = "tree", $iAdditionalX = 100, $iAdditionalY = 100, $sStoneName = "DS")
	Local $tree = [0, 0, 0, 0, 0, ""]
	Local $x0, $y0, $d0, $x, $y, $x1, $y1, $right, $bottom, $a, $b, $i, $findImage, $sArea
	Local $aTreeFiles = _FileListToArray($sDirectory & "tree\", $sTreePrefix & "*.*", $FLTA_FILES)
	If @error Then
		SetLog("Error: Missing tree (" & @error & ")", $COLOR_ERROR)
		Return $tree
	EndIf
	
	Local $scenerycode = "tree" & $sStoneName
	For $i = 1 To $aTreeFiles[0]
		$findImage = $aTreeFiles[$i]
		If StringRegExp($findImage, $scenerycode, $STR_REGEXPMATCH) <> 1 Then ; if stone found is DS, filter only DS tree
			;SetDebugLog("Image skipped: " & $findImage)
			ContinueLoop
		EndIf
		$a = StringRegExp($findImage, "(tree[0-9A-Z]+)-(\d+)-(\d+)_.*[.](xml|png|bmp)$", $STR_REGEXPARRAYMATCH)
		If UBound($a) = 4 Then
			$x0 = $a[1]
			$y0 = $a[2]
			$d0 = "notused"
			
			$x1 = $x0 - $iAdditionalX
			$y1 = $y0 - $iAdditionalY
			$right = $x0 + $iAdditionalX
			$bottom = $y0 + $iAdditionalY
			$sArea = Int($x1) & "," & Int($y1) & "|" & Int($right) & "," & Int($y1) & "|" & Int($right) & "," & Int($bottom) & "|" & Int($x1) & "," & Int($bottom)
			SetDebugLog("GetVillageSize check for image " & $findImage)
			$b = decodeSingleCoord(findImage($scenerycode, $sDirectory & "tree\" & $findImage, $sArea, 1, True))
			; sort by x because there can be a 2nd at the right that should not be used
			If UBound($b) = 2 Then
				$x = Int($b[0])
				$y = Int($b[1])
				SetDebugLog("Found tree image at " & $x & ", " & $y & ": " & $findImage, $COLOR_INFO)
				$tree[0] = $x ; x center of tree found
				$tree[1] = $y ; y center of tree found
				$tree[2] = $x0 ; x ref. center of tree
				$tree[3] = $y0 ; y ref. center of tree
				$tree[4] = $d0 ; distance from stone to tree in pixel
				$tree[5] = $findImage
				ExitLoop
			EndIf

		Else
			SetDebugLog("GetVillageSize ignore image " & $findImage & ", reason: " & UBound($a), $COLOR_WARNING)
		EndIf
	Next
	Return $tree
EndFunc

Func UpdateGlobalVillageOffset($x, $y)

	Local $updated = False

	If $g_sImglocRedline <> "" Then

		Local $newReadLine = ""
		Local $aPoints = StringSplit($g_sImglocRedline, "|", $STR_NOCOUNT)

		For $sPoint In $aPoints

			Local $aPoint = GetPixel($sPoint, ",")
			$aPoint[0] += $x
			$aPoint[1] += $y

			If StringLen($newReadLine) > 0 Then $newReadLine &= "|"
			$newReadLine &= ($aPoint[0] & "," & $aPoint[1])

		Next

		; set updated red line
		$g_sImglocRedline = $newReadLine

		$updated = True
	EndIf

	If $g_aiTownHallDetails[0] <> 0 And $g_aiTownHallDetails[1] <> 0 Then
		$g_aiTownHallDetails[0] += $x
		$g_aiTownHallDetails[1] += $y
		$updated = True
	EndIf
	If $g_iTHx <> 0 And $g_iTHy <> 0 Then
		$g_iTHx += $x
		$g_iTHy += $y
		$updated = True
	EndIf

	ConvertInternalExternArea()

	Return $updated

EndFunc   ;==>UpdateGlobalVillageOffset

Func DetectScenery($stone = "None")
	Local $sScenery = ""
	Local $iIndex = 0
	Local $a = StringRegExp($stone, "stone([0-9A-Z]+)", $STR_REGEXPARRAYMATCH)
	If IsArray($a) Then 
		$iIndex = _ArraySearch($g_aVillageRefSize, $a[0])
		$sScenery = $g_aVillageRefSize[$iIndex][1]
	Else
		$sScenery = "Failed scenery detection"
	EndIf

	Return $sScenery
EndFunc
