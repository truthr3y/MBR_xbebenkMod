; #FUNCTION# ====================================================================================================================
; Name ..........: PrepareSearch
; Description ...: Goes into searching for a match, breaks shield if it has to
; Syntax ........: PrepareSearch()
; Parameters ....:
; Return values .: None
; Author ........: Code Monkey #4
; Modified ......: KnowJack (Aug 2015), MonkeyHunter(2015-12)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
Func PrepareSearch($Mode = $DB) ;Click attack button and find match button, will break shield

	SetLog("Going to Attack", $COLOR_INFO)
	If Not $g_bRunState Then Return
	; RestartSearchPickupHero - Check Remaining Heal Time
	If $g_bSearchRestartPickupHero And $Mode <> $DT Then
		For $pTroopType = $eKing To $eChampion ; check all 4 hero
			For $pMatchMode = $DB To $g_iModeCount - 1 ; check all attack modes
				If IsUnitUsed($pMatchMode, $pTroopType) Then
					If Not _DateIsValid($g_asHeroHealTime[$pTroopType - $eKing]) Then
						getArmyHeroTime("All", True, True)
						ExitLoop 2
					EndIf
				EndIf
			Next
		Next
	EndIf

	ChkAttackCSVConfig()
	If $Mode = $DT Then $g_bRestart = False
	For $i = 1 To 3
		If isOnMainVillage() Then
			ClickP($aAttackButton)
			SetLog("Opening Multiplayer Tab!", $COLOR_INFO)
			If _Sleep(1500) Then Return
			If IsMultiplayerTabOpen() Then 
				ExitLoop
			Else
				SetLog("Couldn't find the Attack Button!", $COLOR_ERROR)
				If $g_bDebugImageSave Then SaveDebugImage("AttackButtonNotFound")
				Return
			EndIf
		Else
			checkObstacles()
		EndIf
		If _Sleep(1000) Then Return
		ClickAway()
		SetLog("Waiting For MainPage #" & $i, $COLOR_ACTION)
		If $i = 3 Then 
			SetLog("PrepareSearch: MainPage Not Found!", $COLOR_ERROR)
			Return
		EndIf
	Next

	$g_bCloudsActive = True ; early set of clouds to ensure no android suspend occurs that might cause infinite waits
	$g_bLeagueAttack = False
	Do
		Local $bSignedUpLegendLeague = False
		Local $sSearchDiamond = GetDiamondFromRect("275,190,835,545")
		Local $avAttackButton = findMultiple($g_sImgPrepareLegendLeagueSearch, $sSearchDiamond, $sSearchDiamond, 0, 1000, 1, "objectname,objectpoints", True)
		If IsArray($avAttackButton) And UBound($avAttackButton, 1) > 0 Then
			$g_bLeagueAttack = True
			Local $avAttackButtonSubResult = $avAttackButton[0]
			Local $sButtonState = $avAttackButtonSubResult[0]
			If StringInStr($sButtonState, "Ended", 0) > 0 Then
				SetLog("League Day ended already! Trying again later", $COLOR_INFO)
				$g_bRestart = True
				CloseClangamesWindow()
				$g_bForceSwitch = True     ; set this switch accounts next check
				Return
			ElseIf StringInStr($sButtonState, "Made", 0) > 0 Then
				SetLog("All Attacks already made! Returning home", $COLOR_INFO)
				$g_bRestart = True
				CloseClangamesWindow()
				$g_bForceSwitch = True     ; set this switch accounts next check
				Return
			ElseIf StringInStr($sButtonState, "FindMatchLegend", 0) > 0 Then
				Local $aCoordinates = StringSplit($avAttackButtonSubResult[1], ",", $STR_NOCOUNT)
				ClickP($aCoordinates, 1, 0, "#0149")
				Local $aConfirmAttackButton
				For $i = 0 To 10
					If _Sleep(200) Then Return
					$aConfirmAttackButton = findButton("ConfirmAttack", Default, 1, True)
					If IsArray($aConfirmAttackButton) And UBound($aConfirmAttackButton, 1) = 2 Then
						ClickP($aConfirmAttackButton, 1, 0)
						ExitLoop
					EndIf
				Next
				If Not IsArray($aConfirmAttackButton) And UBound($aConfirmAttackButton, 1) < 2 Then
					SetLog("Couldn't find the confirm attack button!", $COLOR_ERROR)
					Return
				EndIf
			ElseIf StringInStr($sButtonState, "FindMatchNormal") > 0 Then
				Local $aCoordinates = StringSplit($avAttackButtonSubResult[1], ",", $STR_NOCOUNT)
				If IsArray($aCoordinates) And UBound($aCoordinates, 1) = 2 Then
					$g_bLeagueAttack = False
					ClickP($aCoordinates, 1, 0, "#0150")
					ExitLoop
				Else
					SetLog("Couldn't find the Find a Match Button!", $COLOR_ERROR)
					If $g_bDebugImageSave Then SaveDebugImage("FindAMatchBUttonNotFound")
					Return
				EndIf
			ElseIf StringInStr($sButtonState, "Sign", 0) > 0 Then
				SetLog("Sign-up to Legend League", $COLOR_INFO)
				Local $aCoordinates = StringSplit($avAttackButtonSubResult[1], ",", $STR_NOCOUNT)
				ClickP($aCoordinates, 1, 0, "#0000")
				For $i = 1 To 3
					If IsOKCancelPage() Then
						ClickP($aConfirmSurrender)
						SetLog("Sign-up to Legend League done", $COLOR_INFO)
						$bSignedUpLegendLeague = True
						If _Sleep(1000) Then Return
						ExitLoop
					Else
						SetLog("Wait for OK Button to SignUp Legend League #" & $i, $COLOR_WARNING)
					EndIf
					_Sleep(500)
				Next
				SetLog("Problem SignUp to Legend League", $COLOR_ERROR)
			ElseIf StringInStr($sButtonState, "Oppo", 0) > 0 Then
				SetLog("Finding opponents! Waiting 5 minutes and then try again to find a match", $COLOR_INFO)
				If _Sleep(300000) Then Return     ; Wait 5mins before searching again
				$bSignedUpLegendLeague = True
			Else
				$g_bLeagueAttack = False
				SetLog("Unknown Find a Match Button State: " & $sButtonState, $COLOR_WARNING)
				Return
			EndIf
		ElseIf Number($g_aiCurrentLoot[$eLootTrophy]) >= Number($g_asLeagueDetails[21][4]) Then
			SetLog("Couldn't find the Attack Button!", $COLOR_ERROR)
			Return
		EndIf
	Until Not $bSignedUpLegendLeague

	#cs
		If Not $g_bLeagueAttack Then
			Local $aFindMatch = findButton("FindMatch", Default, 1, True)
			If IsArray($aFindMatch) And UBound($aFindMatch, 1) = 2 Then
				ClickP($aFindMatch, 1, 0, "#0150")
			Else
				SetLog("Couldn't find the Find a Match Button!", $COLOR_ERROR)
				If $g_bDebugImageSave Then SaveDebugImage("FindAMatchBUttonNotFound")
				Return
			EndIf
		EndIf
	#ce
	If $g_iTownHallLevel <> "" And $g_iTownHallLevel > 0 Then
		$g_iSearchCost += $g_aiSearchCost[$g_iTownHallLevel - 1]
		$g_iStatsTotalGain[$eLootGold] -= $g_aiSearchCost[$g_iTownHallLevel - 1]
	EndIf
	UpdateStats()

	If _Sleep($DELAYPREPARESEARCH2) Then Return

	Local $Result = getAttackDisable(346, 182) ; Grab Ocr for TakeABreak check

	If isGemOpen(True) Then ; Check for gem window open)
		SetLog(" Not enough gold to start searching!", $COLOR_ERROR)
		Click(585, 252, 1, 0, "#0151") ; Click close gem window "X"
		If _Sleep($DELAYPREPARESEARCH1) Then Return
		Click(822, 32, 1, 0, "#0152") ; Click close attack window "X"
		If _Sleep($DELAYPREPARESEARCH1) Then Return
		$g_bOutOfGold = True ; Set flag for out of gold to search for attack
	EndIf

	checkAttackDisable($g_iTaBChkAttack, $Result) ;See If TakeABreak msg on screen

	SetDebugLog("PrepareSearch exit check $g_bRestart= " & $g_bRestart & ", $g_bOutOfGold= " & $g_bOutOfGold, $COLOR_DEBUG)

	If $g_bRestart Or $g_bOutOfGold Then ; If we have one or both errors, then return
		$g_bIsClientSyncError = False ; reset fast restart flag to stop OOS mode, collecting resources etc.
		Return
	EndIf
	If IsAttackWhileShieldPage(False) Then ; check for shield window and then button to lose time due attack and click okay
		If WaitforPixel(430, 455, 431, 456, Hex(0x6FBD1F, 6), 6, 1) Then
			If $g_bDebugClick Or $g_bDebugSetlog Then
				SetDebugLog("Shld Btn Pixel color found: " & _GetPixelColor(430, 455, True), $COLOR_DEBUG)
			EndIf
			Click(430,455)
		EndIf
	EndIf
EndFunc   ;==>PrepareSearch
