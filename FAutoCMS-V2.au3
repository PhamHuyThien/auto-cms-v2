#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=ezgif_com_webp_to_png_4u1_icon.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <_HttpRequest.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <Array.au3>
#include <Date.au3>
#include <IE.au3>


Global $hashKeySelect, $List=[], $quiz, $time=0, $first=False;

; GUI
$GUIForm = GUICreate("FAutoCMS V2.0 | FPT POLYTECHNIC", 394, 241, 328, 180);
GUISetBkColor(0xFFFFFF);
GUICtrlCreateGroup("Login with cookie", 8, 0, 377, 49);
$Gcookie = GUICtrlCreateInput("", 16, 16, 193, 21);
$Glogin = GUICtrlCreateButton("Login", 224, 16, 147, 25);
GUICtrlCreateGroup("Auto Form", 8, 48, 377, 89)
$Ghello = GUICtrlCreateLabel("Hello: ...................................................", 16, 64, 190, 17);
$Gmail = GUICtrlCreateLabel("Mail:......................................................", 16, 88, 188, 17);
$GuserID = GUICtrlCreateLabel("CMS_User_ID:......................................",  16, 112, 193, 17)
$GlistCourse = GUICtrlCreateCombo("Select Course...", 224, 64, 145, 25, BitOR($CBS_DROPDOWNLIST,$CBS_AUTOHSCROLL));
GUICtrlSetState($GlistCourse, $GUI_DISABLE);
$Gsolution = GUICtrlCreateButton("Solution", 224, 96, 147, 33)
GUICtrlSetState($Gsolution, $GUI_DISABLE);
GUICtrlCreateGroup("Process form:", 8, 136, 377, 57)
$Gquiz = GUICtrlCreateLabel("Quiz:.....", 16, 160, 43, 17)
$Gscore = GUICtrlCreateLabel("Score:........", 64, 160, 59, 17)
$Gtest = GUICtrlCreateLabel("Test:.......", 136, 160, 49, 17)
$Gprocess = GUICtrlCreateLabel("Process:...............................................", 192, 160, 186, 17)
GUICtrlCreateGroup("Contact Me", 8, 192, 377, 41)
GUICtrlCreateLabel("FAutoCMS v2.0 - @2020 - Code By ThienDz(SystemError) ", 16, 208, 274, 17)
$Gcontact = GUICtrlCreateButton("Contact Me", 304, 208, 75, 17)
GUISetState(@SW_SHOW)


;---------------------- Main --------------------------;
While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE;
			Exit
		Case $Glogin;
			GUICtrlSetState($Glogin, $GUI_DISABLE);
			GUICtrlSetState($Gcookie, $GUI_DISABLE);
			$infoCookie = _checkCookie(GUICtrlRead($Gcookie));
			If IsArray($infoCookie) Then
				$first = true;
				GUICtrlSetData($Ghello, "Hello: "&$infoCookie[1]);
				GUICtrlSetData($Gmail, "Email: "&$infoCookie[2]);
				GUICtrlSetData($GuserID, "CMS_User_ID: "&$infoCookie[3]);
				GUICtrlSetData($GlistCourse, $infoCookie[4]);
				GUICtrlSetState($GlistCourse, $GUI_ENABLE);
				GUICtrlSetState($Gsolution, $GUI_ENABLE);
			Else
				MsgBox(16, "Error", "Login fail, Cookie expired!");
				Exit;
			EndIf
		Case $Gsolution
			$Course = GUICtrlRead($GlistCourse);
			If $Course == "Select Course..." Then
				MsgBox(16, "Error", "Please select a course!");
			Else
				GUICtrlSetState($GlistCourse, $GUI_DISABLE);
				GUICtrlSetState($Gsolution, $GUI_DISABLE);
				GUICtrlSetState($Gcontact, $GUI_DISABLE);
				Solution($infoCookie[0], $Course, $infoCookie[5]);
			EndIf
		Case $Gcontact
			__contactMe();
	EndSwitch
WEnd

Func Solution($Cookie, $Course, $csrfToken)

	$listURLQuiz = __getURLQuiz($Cookie, $Course);
	For $i=0 to UBound($listURLQuiz)-1
		GUICtrlSetData($Gprocess, "Process: check URL...");
		$hashKeySelect = __getInputHashKey($Cookie, $listURLQuiz[$i]);
		if $hashKeySelect <> 0 Then
			$quiz+=1;
			GUICtrlSetData($Gquiz, "Quiz: "&$quiz);
			$hashKey = StringSplit($hashKeySelect[1][0], "_", 2);
			$URLPost = "https://cms.poly.edu.vn/courses/course-v1:FPOLY+"&$Course&"/xblock/block-v1:FPOLY+"&$Course&"+type@problem+block@"&$hashKey[1]&"/handler/xmodule_handler/problem_check";
			$ParamPost = __setChoice();
			While 1
				If _checkTime($time, 60) Then
					$time = _getTime();
					$JSONResp = _HttpRequest(2, $URLPost, $ParamPost, $Cookie, $listURLQuiz[$i], "X-CSRFToken:"&$csrfToken);
					$jsonObj = _HttpRequest_ParseJson($JSONResp);
					if IsObj($jsonObj) Then
						GUICtrlSetData($Gscore, "Score: "&Round($jsonObj.current_score, 2));
						GUICtrlSetData($Gtest, "Test: "&$jsonObj.attempts_used);
						GUICtrlSetData($Gprocess, "Process: "&$jsonObj.progress_changed&" - Status: "&$jsonObj.success);
						If $jsonObj.current_score < $jsonObj.total_possible Then
							$arrAnalys = __analysisData($jsonObj.contents);
							$ParamPost = __setChoice($arrAnalys);
						Else
							$time = 0;
							MsgBox(64, "Success!", "QUIZ "&$quiz&" Success!"&@CRLF&"Code by ThienDz(SystemError)"&@CRLF&"https://Fb.com/ThienDz.SystemError", 3);
							ExitLoop;
						EndIf
					Else
						MsgBox(16, "Error!", "Parse JSON Error, POST Data Fail!");
						ExitLoop;
					EndIf
				EndIf
				GUICtrlSetData($Gprocess, "Process: Sleep "&(60-(_getTime()-$time))&"s...");
				sleep(100);
			WEnd
		EndIf
	Next
	GUICtrlSetState($Gcontact, $GUI_ENABLE);
	MsgBox(64, "success!", "Finish "&$quiz&" Quiz!"&@CRLF&"Code by ThienDz(SystemError)"&@CRLF&"https://Fb.com/ThienDz.SystemError");
	__contactMe();
EndFunc
;-----------------------------------------------------------------------------------

;function		__getURLQuiz
;param 			- $cookie: cookie Request CMS
;return			- success	:arr List URL QUIZ
;				- fail		:false
;ý nghĩa		- lấy URL tất cả bài quiz
Func __getURLQuiz($Cookie, $Course)
	$URLgetQuiz = "https://cms.poly.edu.vn/courses/course-v1:FPOLY+"&$Course&"/course/";
	$html = _HttpRequest(2, $URLgetQuiz, "", $Cookie);
	$listURLQuiz = StringRegExp($html, 'href\="(https\:\/\/cms.+?)\"', 3);
	If $listURLQuiz <> 1 Then
		_ArrayDelete($listURLQuiz, 0);
		Return $listURLQuiz;
	EndIf
	return False;
EndFunc

;function:		__setChoice
;param:			$arrAnalys: 	- isArr:	 tạo param post mới từ danh sách các đáp án trả về (lấy từ __analysisData)
;								- false: 	tạo mới param post cho lượt đầu tiên
;return:		PARAM POSt CHO REQUEST
;ý nghĩa:		tạo param post cho request
Func __setChoice($arrAnalys=False)
	dim $Result;
	$UHashKeySelect = UBound($hashKeySelect);
	if Not IsArray($arrAnalys) Then
		Dim $arrAnalys[$UHashKeySelect];
		For $i=0 to $UHashKeySelect-1
			$arrAnalys[$i]=1;
		Next
	EndIf
	For $i=0 to $UHashKeySelect-1
		if $arrAnalys[$i] == 0 Then
			$hashKeySelect[$i][2] += 1;
		EndIf
		If ___checkInputType($hashKeySelect[$i][0]) Then
			$Result &= $hashKeySelect[$i][0]&"=choice_"&$hashKeySelect[$i][2]&"&";
		Else
			$Result &= ___recursiveD($hashKeySelect[$i][2], $hashKeySelect[$i][1], $hashKeySelect[$i][0])&"&";
		EndIf
	Next
	Return $Result;
EndFunc

;function:		___recursiveD
;param:			$d:		- lựa chọn lần thứ $d
;				$sl:	- số lượng lựa chọn
;				$name	- ten param
;return: 		- tổ hợp các cách lựa chọn từ 1-n cho input checkbox
;ý nghĩa: 		- return các cách lựa chọn
Func ___recursiveD($d, $sl, $name)
	___arrayUnshift();
	_ArrayAdd($List, "");
	For $i=2 to $sl
		$arrRes = ____getArrResAm1(100);
		___toHop($i, $sl, 1, $arrRes);
	Next
	$result = "";
	For $i=1 to StringLen($List[$d])
		$result &= _URIEncode($name)&"=choice_"&StringMid($List[$d], $i, 1)&"&";
	Next
	Return StringMid($result, 1, StringLen($result)-1);
EndFunc

;ys nghĩa:		- xóa tất cả phần tử trong mảng List
Func ___arrayUnshift()
	For $i=0 to UBound($List)-1
		_ArrayDelete($List, 0);
	Next
	if UBound($List) == 0 Then
		return 1;
	EndIf
	Return 0;
EndFunc


;ý nghĩa:		-tạo 1 tổ hợp chập k của n phần tử
Func ___toHop($k, $n, $i, $arrRes)
	For $j=$arrRes[$i-1]+1 to $n-$k+$i
		$arrRes[$i] = $j;
		if $i==$k Then
			$value = "";
			For $m=1 to $k
				$value &= $arrRes[$m]-1;
			Next
			_ArrayAdd($List, $value);
		Else
			___toHop($k, $n, $i+1, $arrRes);
		EndIf
	Next
EndFunc

;ý nghĩa:		-hỗ trợ ___toHop
Func ____getArrResAm1($sl)
	Dim $arrRes[$sl];
	For $i=0 to $sl-1
		$arrRes[$i] = 0;
	Next
	Return $arrRes;
EndFunc
;--------------------------------------------------------------------------



; function 		___checkInputType
; param:		- $hashKeySelect: lấy từ __getInputHashKey
; return:		- SUCCESS: 	input type radio
;				- FAIL:		input type checkBOX
;ý nghĩa:		- trả về kiểu của hashKeySelect
Func ___checkInputType($hashKeySelect)
	if StringInStr($hashKeySelect, "[]") Then
		Return 0;
	EndIf
	Return 1;
EndFunc


; function:		__analysisData
; param:		- $data : json data nhận từ POST request trả về
; return:		- SUCCESS: 	- arr kết quả đúng sai của các bài question
;				- FAIL: 	- false
;ý nghĩa:		- kiểm tra đúng sai của các cách đệ quy (đúng rồi thì loại bỏ đệ quy)
Func __analysisData($data)
	$Result = StringRegExp($data, 'class\=\"sr\"\>(.+?)\<', 3);
	if $Result <> 1 Then
		_ArrayDelete($Result, UBound($Result)-1);
		For $i=0 to UBound($Result)-1
			if $Result[$i]=="correct" Then
				$Result[$i]=1;
			Else
				$Result[$i]=0;
			EndIf
		Next
		Return $Result;
	EndIf
	Return False;
EndFunc


; funciton		__getInputHashKey
; param:		- $Cookie: 	cookie
;				- $URL: url request get hashkey
; return:		- array $ListHashKey[ubount][3] => [0]=hashkey, [1]=số lượng đáp án, [2]=lượt chọn đáp án thứ i
; ý nghĩa: 		- request URL bài cần giải rồi lấy các input name, và số lượng đáp án để tý tạo parampost bài viết
Func __getInputHashKey($Cookie, $URL)
	$html = _HttpRequest(2, $URL, "", $Cookie);
	$hashKey = StringRegExp($html, "label\sid\=\&amp\;\#34\;(.+?)\&amp\;\#34\;", 3);
	if $hashKey==1 Then
		Return 0;
	EndIf
	For $i=0 to UBound($hashKey)-1
		$splitHashKey = StringSplit($hashKey[$i], "-", 2);
		If StringInStr($html, "input_"&$splitHashKey[0]&"[]") Then
			$hashKey[$i] = "input_"&$splitHashKey[0]&"[]";
		Else
			$hashKey[$i] = "input_"&$splitHashKey[0];
		EndIf
	Next
	dim $List[1];
	For $i=0 to UBound($hashKey)-1
		If _ArraySearch($List, $hashKey[$i])==-1 Then
			_ArrayAdd($List, $hashKey[$i]);
		EndIf
	Next
	Dim $List2[UBound($List)][3];
	For $i=0 to UBound($List2)-1
		$List2[$i][0] = $List[$i]; // choice
		$List2[$i][1] = 0; // count
		$List2[$i][2] = 0; // select
		For $j=0 to UBound($hashKey)-1
			if $List2[$i][0] == $hashKey[$j] Then
				$List2[$i][1] += 1;
			EndIf
		Next
	Next
	_ArrayDelete($List2, 0);
	return $List2;
EndFunc


; funciton:		_checkCookie
; param:		- $Cookie: Cookie CMS
; Return: 		- SUCCESS: info account [6] => cookie, username, mail, userid, course, csrf
;		 		- FAIL: false;
; ý nghĩa: 		- kiểm tra cookie xem có auto đc không?
Func _checkCookie($Cookie)
	$html  = _HttpRequest(2, "https://cms.poly.edu.vn/dashboard", "", $Cookie);
	if StringInStr($html, "Dashboard | FPT Polytechnic | Course Management System")<>0 Then
		Dim $arrInfo[6];
		$nickName = StringRegExp($html, '\"username\"\:\s\"(.+?)\"', 3);
		$userId = StringRegExp($html, '\"user\_id\"\:\s([0-9]+?)\,', 3);
		$csrf = StringRegExp($Cookie, "csrftoken\=(.+?)\;", 3);
		$course = __getCourse($html);
		if $nickName<>1 and $userId<>1 and $csrf<>1 and $course<>0 Then
			$arrInfo[0] = $Cookie;
			$arrInfo[1] = $nickName[0];
			$arrInfo[2] = $arrInfo[1]&"@fpt.edu.vn";
			$arrInfo[3] = $userId[0];
			$arrInfo[4] = _ArrayToString($course);
			$arrInfo[5] = $csrf[0];
			Return $arrInfo;
		EndIf
	EndIf
	Return False;
EndFunc

;function 		__getCourse
;param 			$html = html source dashboard (/dashboard)
;return 		- success: list Course []
;				- fail: false
;ý nghĩa		- lấy tất cả các course (các môn)
Func __getCourse($html)
	$course = StringRegExp($html, 'course\-title\-course\-v1\:FPOLY\+(.+?)\"\sid=', 3);
	if $course <> 1 Then
		Dim $ArrResult[1];
		For $i=0 to UBound($course)-1
			if _ArraySearch($ArrResult, $course[$i])==-1 Then
				_ArrayAdd($ArrResult, $course[$i]);
			EndIf
		Next
		_ArrayDelete($ArrResult, 0);
		Return $ArrResult;
	EndIf
	Return 0;
EndFunc



;function		_checkTime
;param			- $time = thời gian cũ
;				- $s = số s cần so sánh
;return			- 1: đủ thời gian
;				- 0: thiếu thời gian
;ý nghĩa:		- kiểm tra thời gian hiện tại có lớn hơn $s không?
Func _checkTime($time, $s)
	If _getTime()-$time > $s Then
		Return 1;
	EndIf
	Return 0;
EndFunc

;function		_getTime
;param			-
;return			- thời gian hiện tại tính bằng s( time từ 0:0:0 1/1/1970)
;ý nghĩa:		- lấy thời gian hiện tại tính bằng s
Func _getTime()
	Return _DateDiff("s","1970/01/01 00:00:00",@YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC);
EndFunc


;function 		__contactMe
;param			-
;return 		-
;ý nghĩa		- mở trình duyệt, chuyển hướng đến trang fb của author :D
Func __contactMe()
	$UrlContact = "https://facebook.com/ThienDz.SystemError";
	$paramShellChrome = $UrlContact&" --new-tab --full-screen";
	if ShellExecute("chrome.exe", $paramShellChrome) Then
		Return 1;
	EndIf
	If ShellExecute("C:\Users\"&@UserName&"\AppData\Local\CocCoc\Browser\Application\browser.exe", $paramShellChrome) Then
		Return 1;
	EndIf
	if IsObj(_IECreate($UrlContact)) Then
		Return 1;
	EndIf
	Return 0;
EndFunc