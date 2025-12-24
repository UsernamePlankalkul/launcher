AppsKey & space:: Launcher()

Launcher() {
    static LauncherGui := "", SearchInput := "", ResultList := ""
    static AllItems := ["Notepad", "Calculator", "Command Prompt", "Control Panel", "Task Manager", "Powershell"]

    if (LauncherGui) {
        SearchInput.Value := ""
        UpdateResults()
        LauncherGui.Show("Center")
        return
    }

    LauncherGui := Gui("+AlwaysOnTop -Caption +Border", "AHK Launcher")
    LauncherGui.BackColor := "1e1e1e"
    OnMessage(0x100, HandleKeyDown)
    
    LauncherGui.SetFont("s14 cWhite", "Segoe UI")
    SearchInput := LauncherGui.Add("Edit", "w500 r1 Background333333 -E0x200")
    SearchInput.OnEvent("Change", UpdateResults)
    
    LauncherGui.SetFont("s12 cCCCCCC")
    ResultList := LauncherGui.Add("ListBox", "w500 r10 Background1e1e1e -HScroll -VScroll")
    
    BtnSubmit := LauncherGui.Add("Button", "Default w0 h0 Hidden")
    BtnSubmit.OnEvent("Click", ExecuteSelection)

    LauncherGui.OnEvent("Escape", (*) => LauncherGui.Hide())
    LauncherGui.Show("Center")
    UpdateResults()

    UpdateResults(*) {
        Query := StrLower(SearchInput.Value)
        ResultList.Delete()
        
        if (Query == "") {
            ResultList.Add(AllItems)
            ResultList.Value := 1
            return
        }

        ScoredItems := []
        for item in AllItems {
            LowerItem := StrLower(item)
            
            ; 1. Check if all characters exist (Overlap Match)
            if OverlapMatch(LowerItem, Query) {
                Score := 1 ; Base score for just having the letters
                
                ; 2. Bonus for Sequential Match (letters in order)
                if SequentialMatch(LowerItem, Query)
                    Score += 2
                
                ; 3. Bonus for starting with the same letter
                if (SubStr(LowerItem, 1, 1) == SubStr(Query, 1, 1))
                    Score += 1
                
                ScoredItems.Push({Name: item, Rank: Score})
            }
        }

        ; Sort by Rank (Descending)
        SortByRank(ScoredItems)

        ; Add sorted results to ListBox
        for obj in ScoredItems
            ResultList.Add([obj.Name])
        
        if (ScoredItems.Length > 0)
            ResultList.Value := 1
    }

    ; --- Helper Functions ---

    OverlapMatch(Haystack, Needle) {
        Loop Parse, Needle {
            if !InStr(Haystack, A_LoopField)
                return false
        }
        return true
    }

    SequentialMatch(Haystack, Needle) {
        lastPos := 1
        Loop Parse, Needle {
            lastPos := InStr(Haystack, A_LoopField, false, lastPos)
            if !lastPos
                return false
            lastPos++
        }
        return true
    }

    SortByRank(arr) {
        ; Simple Bubble Sort for ranking
        n := arr.Length
        Loop n {
            i := A_Index
            Loop n - i {
                j := A_Index
                if (arr[j].Rank < arr[j+1].Rank) {
                    temp := arr[j]
                    arr[j] := arr[j+1]
                    arr[j+1] := temp
                }
            }
        }
    }

    ; --- Navigation and Execution (Same as before) ---
    HandleKeyDown(wParam, lParam, msg, hwnd) {
        if (hwnd != SearchInput.Hwnd && hwnd != ResultList.Hwnd && hwnd != LauncherGui.Hwnd)
            return
        if (wParam = 0x26 || wParam = 0x28) {
            ResultList.Focus()
            Send("{Blind}{VK" Format("{:X}", wParam) "}")
            SearchInput.Focus()
            return 0
        }
    }

    ExecuteSelection(*) {
        Selection := ResultList.Text
        if (Selection == "") 
            return
        LauncherGui.Hide()
        switch Selection {
            case "Notepad": Run("notepad.exe")
            case "Calculator": Run("calc.exe")
            case "Command Prompt": Run("cmd.exe")
            case "Control Panel": Run("control.exe")
            case "Task Manager": Run("taskmgr.exe")
            case "Powershell": Run("powershell.exe")
            default: try Run(Selection)
        }
    }
}
