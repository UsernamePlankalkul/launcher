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
    
    LauncherGui.SetFont("s14 cYellow", 'Lilex Nerd Font Mono')
    SearchInput := LauncherGui.Add("Edit", "w500 r1 Background333333 -E0x200")
    SearchInput.OnEvent("Change", UpdateResults)
    
    LauncherGui.SetFont("s12 cLime" ,'Lilex Nerd Font Mono')
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
            
            if OverlapMatch(LowerItem, Query) {
                Score := 100 ; Base score
                
                ; 1. Sequential Match + Proximity Calculation
                lastPos := 1
                firstMatch := 0
                totalDistance := 0
                
                Loop Parse, Query {
                    foundPos := InStr(LowerItem, A_LoopField, false, lastPos)
                    if (foundPos) {
                        if (A_Index == 1)
                            firstMatch := foundPos
                        
                        totalDistance += (foundPos - lastPos)
                        lastPos := foundPos + 1
                        Score += 50 ; Sequential bonus
                    } else {
                        ; If sequence breaks, penalize heavily but keep in list due to overlap
                        Score -= 20
                    }
                }

                ; 2. Tightness Bonus: Fewer chars between matches = higher score
                Score -= (totalDistance * 2)

                ; 3. Starting Position Bonus: Matching at the start of the string is best
                if (firstMatch == 1)
                    Score += 100
                
                ; 4. Exact Match Bonus
                if (LowerItem == Query)
                    Score += 1000

                ScoredItems.Push({Name: item, Rank: Score})
            }
        }

        SortByRank(ScoredItems)

        for obj in ScoredItems
            ResultList.Add([obj.Name])
        
        if (ScoredItems.Length > 0)
            ResultList.Value := 1
    }

    ; --- Helpers ---

    OverlapMatch(Haystack, Needle) {
        Loop Parse, Needle {
            if !InStr(Haystack, A_LoopField)
                return false
        }
        return true
    }

    SortByRank(arr) {
        n := arr.Length
        Loop n {
            i := A_Index
            Loop n - i {
                j := A_Index
                if (arr[j].Rank < arr[j+1].Rank) {
                    temp := arr[j], arr[j] := arr[j+1], arr[j+1] := temp
                }
            }
        }
    }

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
