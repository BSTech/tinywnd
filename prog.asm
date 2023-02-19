; tinywnd - A tiny PoC Win32 GUI Application written in x86 Assembly
; Copyright (C) 2023  bstech_
; 
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.

.686
.model flat
.stack 4096

include init.asm
include dll.asm

.data
    hKernel32                   dd 0
    hUser32                     dd 0
    hComctl32                   dd 0
    hShell32                    dd 0
    hGdi32                      dd 0
    
    hFont                       dd 0
    hBrush                      dd 0
    
    pfnLoadLibrary              dd 0
    pfnExitProcess              dd 0
    pfnMessageBoxA              dd 0
    pfnRegisterClassExA         dd 0
    pfnCreateWindowExA          dd 0
    pfnDestroyWindow            dd 0
    pfnInitCommonControlsEx     dd 0
    pfnPostQuitMessage          dd 0
    pfnSendMessageA             dd 0
    pfnShellExecuteW            dd 0
    pfnDefWindowProcA           dd 0
    pfnGetMessageA              dd 0
    pfnTranslateMessage         dd 0
    pfnDispatchMessageA         dd 0
    pfnCreateFontIndirectA      dd 0
    pfnDeleteObject             dd 0
    pfnSystemParametersInfoA    dd 0
    pfnLoadCursorA              dd 0
    
    wszKernel32Dll              dw 'k', 'e', 'r', 'n', 'e', 'l', '3', '2', '.', 'd', 'l', 'l', 0 ; L"kernel32.dll"
    szUser32Dll                 db "user32.dll"             , 0
    szComctl32Dll               db "comctl32.dll"           , 0
    szShell32Dll                db "shell32.dll"            , 0
    szGdi32Dll                  db "gdi32.dll"              , 0
    
    szLoadLibrary               db "LoadLibraryA"           , 0
    szExitProcess               db "ExitProcess"            , 0
    szMessageBox                db "MessageBoxA"            , 0
    szRegisterClassExA          db "RegisterClassExA"       , 0
    szCreateWindowExA           db "CreateWindowExA"        , 0
    szDestroyWindow             db "DestroyWindow"          , 0
    szInitCommonControlsEx      db "InitCommonControlsEx"   , 0
    szPostQuitMessage           db "PostQuitMessage"        , 0
    szSendMessageA              db "SendMessageA"           , 0
    szShellExecuteW             db "ShellExecuteW"          , 0
    szDefWindowProcA            db "DefWindowProcA"         , 0
    szGetMessageA               db "GetMessageA"            , 0
    szTranslateMessage          db "TranslateMessage"       , 0
    szDispatchMessageA          db "DispatchMessageA"       , 0
    szCreateFontIndirectA       db "CreateFontIndirectA"    , 0
    szDeleteObject              db "DeleteObject"           , 0
    szSystemParametersInfoA     db "SystemParametersInfoA"  , 0
    szLoadCursorA               db "LoadCursorA"            , 0
    
    szClsName                   db "BSWnd"                  , 0
    szClsSymLink                db "SYSLINK"                , 0
    szClsBtn                    db "BUTTON"                 , 0
    
    szWndTitle                  db "tinywnd"                , 0
    szBtn1Text                  db "Close"                  , 0
    szBtn2Text                  db "Go to the link"         , 0
    
    szWelcomeTitle              db "Welcome!"               , 0
    szWelcomeMsg                db "bstech_ says hi!"       , 0
    
    szWndText                   db "Simple PoC Win32 GUI app all written in Assembly! (my first time with no experience)"                       , 13, 10
                                db "More information: <a HREF=", 34, "https://github.com/BSTech/tinywnd", 34, ">"
                                db "https://github.com/BSTech/tinywnd</a>"                                                                      , 13, 10
                                db                                                                                                                13, 10
                                db "Features:"                                                                                                  , 13, 10
                                db 149, " No MASM macros (invoke, struct, etc.) are used except equ"                                            , 13, 10
                                db 149, " No structure definition - everything is pure data and offsets"                                        , 13, 10
                                db 149, " No local variables - just globals, registers, and the stack as a way of passing parameters"           , 13, 10
                                db 149, " No lea instruction"                                                                                   , 13, 10
                                db 149, " No includes of libraries and definitions (including WinAPI library files)"                            , 13, 10
                                db 149, " No import address table - all functions, including LoadLibrary(), are dynamically loaded from"
                                db      " <a HREF=", 34, "https://en.wikipedia.org/wiki/Process_Environment_Block", 34, ">PEB</a>"              , 13, 10
                                db 149, " Has a ", 34, "proper", 34, " message loop implemented"                                                , 13, 10
                                db 149, " Uses Common Controls v6 controls (links, modern buttons, etc.)"                                       , 13, 10
                                db 149, " Utilizes the default GUI font instead of the default VGA console font"                                , 13, 10
                                db 149, " Last but not least, a tiny executable file (around 7 kilobytes, which could be shrunk more)"          , 13, 10
                                db                                                                                                                13, 10
                                db "For the list of bugs, or for feedback, visit the GitHub link!"                                              , 13, 10
                                db                                                                                                                13, 10
                                db 169, " bstech_, 2023 - to everyone who says writing a GUI app in Assembly is crazy!"                         , 0
    
    
    pMsg                        db 32  dup(0)   ; MSG struct initialized with zeros, 32 == sizeof(MSG)
    pWndClassExA                db 48  dup(0)   ; WNDCLASSEXA same as MSG, 48 == sizeof(WNDCLASSEXA)
    pICCEX                      db 8   dup(0)   ; INITCOMMONCONTROLSEX struct, 8 == sizeof that
    pNCM                        db 344 dup(0)   ; NONCLIENTMETRICSA struct, 344 == sizeof(NONCLIENTMETRICSA)

.code

WndProc PROC    ; int (void* hWnd, uint uMsg, uint wParam, long lParam)
    hWnd   equ 8
    uMsg   equ 12
    wParam equ 16
    lParam equ 20
    
    enter 0, 0
    
    cmp dword ptr [ebp + uMsg], 1       ; uMsg == WM_CREATE (1)
    je OnCreate
    cmp dword ptr [ebp + uMsg], 2       ; uMsg == WM_DESTROY (2)
    je OnDestroy
    cmp dword ptr [ebp + uMsg], 111h    ; uMsg == WM_COMMAND (0x111)
    je OnCommand
    cmp dword ptr [ebp + uMsg], 4Eh     ; uMsg == WM_NOTIFY (0x4E)
    je OnNotify
    
    jmp DefHandler                      ; pass other messages to DefWindowProc
    
onCreate:
    push ebx
    mov ebx, [ebp + lParam]             ; ebx = lParam (LPCREATESTRUCTA)
    mov ebx, [ebx + 4]                  ; ebx = LPCREATESTRUCTA->hInstance
    
    ; create default ui font
    
    mov dword ptr [pNCM], 340           ; cbSize = sizeof(NONCLIENTMETRICSA) - 4 (sizeof(iPaddedBorderWidth))
    
    push 0                              ; fWinIni - FALSE
    push offset pNCM                    ; pvParam - &pNCM
    push 344                            ; uiParam - sizeof(NONCLIENTMETRICSA)
    push 41                             ; uiAction - 41 == SPI_GETNONCLIENTMETRICS
    call pfnSystemParametersInfoA
    
    push offset [pNCM + 280]            ; pNCM->lfMessageFont
    call pfnCreateFontIndirectA         ; create HFONT from LOGFONTA
    mov hFont, eax
    
    ; create one syslink text and a button and set their font
    
    push 0                              ; lpParam
    push ebx                            ; hInstance
    push 0                              ; menu (ID of the button in this case)
    push [ebp + hWnd]                   ; parent
    push 380                            ; height
    push 600                            ; width
    push 10                             ; y
    push 10                             ; x
    push 50000000h                      ; dwStyle (WS_CHILD | WS_VISIBLE)
    push offset szWndText               ; lpWindowName
    push offset szClsSymLink            ; lpClassName
    push 0                              ; dwExStyle
    call pfnCreateWindowExA
    
    push 1                              ; lParam - TRUE to redraw the window immediately
    push hFont                          ; wParam - hFont
    push 48                             ; uMsg WM_SETFONT
    push eax                            ; hWnd (use the return value of previous CreateWindowEx() call directly since it is not used anywhere else)
    call pfnSendMessageA
    
    push 0                              ; lpParam
    push ebx                            ; hInstance
    push 123                            ; menu (ID of the button in this case)
    push [ebp + hWnd]                   ; parent
    push 30                             ; height
    push 100                            ; width
    push 400                            ; y
    push 270                            ; x
    push 50000000h                      ; dwStyle (WS_CHILD | WS_VISIBLE)
    push offset szBtn1Text              ; lpWindowName
    push offset szClsBtn                ; lpClassName
    push 0                              ; dwExStyle
    call pfnCreateWindowExA
    
    push 1                              ; lParam - TRUE to redraw the window immediately
    push hFont                          ; wParam - hFont
    push 48                             ; uMsg WM_SETFONT
    push eax                            ; hWnd (again use the return value of previous CreateWindowEx() call directly since it is not used anywhere else)
    call pfnSendMessageA
    
    jmp Fn_return                       ; return 0 to continue window creation

onDestroy:
    push hFont                          ; delete the font we created before
    call pfnDeleteObject
    push 0
    call pfnPostQuitMessage             ; PostQuitMessage(exitCode: 0);
    jmp Fn_return                       ; return 0 to indicate the message is processed

onCommand:
    push ebx
    mov ebx, [ebp + wParam]             ; ebx = wParam
    cmp bx, 123                         ; is loword(ebx) == 123 (our first button)?
    pop ebx                             ; restore ebx before we go
    je DestroyWindow                    ; make the button destroy the window
    jmp Fn_return                       ; return 0 as always

onNotify:
    push ebx
    mov ebx, [ebp + lParam]             ; ebx = lParam (LPNMHDR)
    cmp dword ptr [ebx + 8], -2         ; is lpnmhdr->code == NM_CLICK?
    je HandleLink                       ; then go to link handler
    cmp dword ptr [ebx + 8], -4         ; or is lpnmhdr->code == NM_RETURN?
    je HandleLink                       ; then go to link handler again
    pop ebx                             ; restore ebx before return
    jmp Fn_return                       ; and return 0 as always

handleLink:
    add ebx, 124                        ; ebx = ((PNMLINK)ebx)->item->szUrl; (UNICODE!)
    push 1                              ; nShowCmd (1 == SW_SHOWNORMAL)
    push 0                              ; lpDirectory
    push 0                              ; lpParameters
    push ebx                            ; lpFile
    push 0                              ; lpOperation (0 makes it "open" or lets the system decide what it should be)
    push [ebp + hWnd]                   ; hWnd
    call pfnShellExecuteW
    pop ebx                             ; lets restore ebx here because of the onNofity logic
    jmp Fn_return

destroyWindow:
    push [ebp + hWnd]
    call pfnDestroyWindow               ; DestroyWindow(hWnd);
    jmp Fn_return                       ; we have nothing left to do, just return 0

defHandler:
    push [ebp + lParam]
    push [ebp + wParam]
    push [ebp + uMsg]
    push [ebp + hWnd]
    call pfnDefWindowProcA              ; return value is passed to the next lines directly (no operation over eax)
    leave
    ret 16

fn_return:
    xor eax, eax
    leave
    ret 16
    
WndProc ENDP

init_external_functions PROC            ; returns 1 always
    enter 0, 0
    
    push offset wszKernel32Dll          ; loaded module list only contains unicode names, hence wszKernel32Dll is in unicode
    call bs_find_loaded_module          ; the list is internally read by this function, so no need to specify it externally
    mov hKernel32, eax
    
    push offset szLoadLibrary           ; pfnLoadLibrary = GetProcAddress(hKernel32, "LoadLibraryA");
    push hKernel32
    call bs_getprocaddress
    mov pfnLoadLibrary, eax
    
    push offset szExitProcess           ; pfnExitProcess = GetProcAddress(hKernel32, "ExitProcess");
    push hKernel32
    call bs_getprocaddress
    mov pfnExitProcess, eax
    
    push offset szUser32Dll             ; hUser32 = LoadLibraryA("user32.dll");
    call pfnLoadLibrary
    mov hUser32, eax
    
    push offset szComctl32Dll           ; hComctl32 = LoadLibraryA("comctl32.dll");
    call pfnLoadLibrary
    mov hComctl32, eax
    
    push offset szShell32Dll            ; hShell32 = LoadLibraryA("shell32.dll");
    call pfnLoadLibrary
    mov hShell32, eax
    
    push offset szGdi32Dll              ; hGdi32 = LoadLibraryA("gdi32.dll");
    call pfnLoadLibrary
    mov hGdi32, eax
    
    push offset szMessageBox            ; pfnMessageBoxA = GetProcAddress(hUser32, "MessageBoxA");
    push hUser32
    call bs_getprocaddress
    mov pfnMessageBoxA, eax
    
    push offset szRegisterClassExA      ; pfnRegisterClassExA = GetProcAddress(hUser32, "RegisterClassExA");
    push hUser32
    call bs_getprocaddress
    mov pfnRegisterClassExA, eax
    
    push offset szCreateWindowExA       ; pfnCreateWindowExA = GetProcAddress(hUser32, "CreateWindowExA");
    push hUser32
    call bs_getprocaddress
    mov pfnCreateWindowExA, eax
    
    push offset szDestroyWindow         ; pfnDestroyWindow = GetProcAddress(hUser32, "DestroyWindow");
    push hUser32
    call bs_getprocaddress
    mov pfnDestroyWindow, eax

    push offset szInitCommonControlsEx  ; pfnInitCommonControlsEx = GetProcAddress(hComctl32, "InitCommonControlsEx");
    push hComctl32
    call bs_getprocaddress
    mov pfnInitCommonControlsEx, eax
    
    push offset szPostQuitMessage       ; pfnPostQuitMessage = GetProcAddress(hUser32, "PostQuitMessage");
    push hUser32
    call bs_getprocaddress
    mov pfnPostQuitMessage, eax
    
    push offset szSendMessageA          ; pfnSendMessageA = GetProcAddress(hUser32, "SendMessageA");
    push hUser32
    call bs_getprocaddress
    mov pfnSendMessageA, eax
    
    push offset szShellExecuteW         ; pfnShellExecuteW = GetProcAddress(hShell32, "ShellExecuteW");
    push hShell32
    call bs_getprocaddress
    mov pfnShellExecuteW, eax
    
    push offset szDefWindowProcA        ; pfnDefWindowProcA = GetProcAddress(hUser32, "DefWindowProcA");
    push hUser32
    call bs_getprocaddress
    mov pfnDefWindowProcA, eax
    
    push offset szGetMessageA           ; pfnGetMessageA = GetProcAddress(hUser32, "GetMessageA");
    push hUser32
    call bs_getprocaddress
    mov pfnGetMessageA, eax
    
    push offset szTranslateMessage      ; pfnTranslateMessage = GetProcAddress(hUser32, "TranslateMessage");
    push hUser32
    call bs_getprocaddress
    mov pfnTranslateMessage, eax
    
    push offset szDispatchMessageA      ; pfnDispatchMessageA = GetProcAddress(hUser32, "DispatchMessageA");
    push hUser32
    call bs_getprocaddress
    mov pfnDispatchMessageA, eax
    
    push offset szCreateFontIndirectA   ; pfnCreateFontIndirectA = GetProcAddress(hGdi32, "CreateFontIndirectA");
    push hGdi32
    call bs_getprocaddress
    mov pfnCreateFontIndirectA, eax
    
    push offset szDeleteObject          ; pfnDeleteObject = GetProcAddress(hGdi32, "DeleteObject");
    push hGdi32
    call bs_getprocaddress
    mov pfnDeleteObject, eax
    
    push offset szSystemParametersInfoA ; pfnSystemParametersInfoA = GetProcAddress(hUser32, "SystemParametersInfoA");
    push hUser32
    call bs_getprocaddress
    mov pfnSystemParametersInfoA, eax
    
    push offset szLoadCursorA           ; pfnLoadCursorA = GetProcAddress(hUser32, "LoadCursorA");
    push hUser32
    call bs_getprocaddress
    mov pfnLoadCursorA, eax
    
    mov eax, 1
    leave
    ret
init_external_functions ENDP

_start PROC
    enter 0, 0
    
    call bs_init                        ; initialize PEB, image base, loader's module list and "is debugger present" flag (maybe it will be useful in the future)
    call init_external_functions        ; load winapi functions
    
    mov dword ptr [pICCEX],     8       ; dwSize = sizeof the structure
    mov dword ptr [pICCEX + 4], 4000h   ; dwICC = ICC_STANDARD_CLASSES
    push offset pICCEX
    call pfnInitCommonControlsEx
    
    push 64                             ; MessageBoxA(0, szWelcomeMsg, szWelcomeTitle, 64); 64 == MB_INFORMATION
    push offset szWelcomeTitle
    push offset szWelcomeMsg
    push 0
    call pfnMessageBoxA
    
    push 32512                          ; IDC_ARROW
    push 0                              ; hInstance == NULL (to load from system itself)
    call pfnLoadCursorA                 ; use return value below directly
    
    mov dword ptr [pWndClassExA],      48                   ; cbSize = sizeof(WNDCLASSEXA);
    mov dword ptr [pWndClassExA + 4],  0                    ; style = 0;
    mov dword ptr [pWndClassExA + 8],  offset WndProc       ; lpfnWndProc = WndProc;
    mov dword ptr [pWndClassExA + 20], offset _image_base   ; hInstance = _image_base;
    mov dword ptr [pWndClassExA + 28], eax                  ; hCursor = LoadCursorA(...);
    mov dword ptr [pWndClassExA + 32], 6                    ; hbrBackground = COLOR_WINDOW + 1; // to avoid writing more code
    mov dword ptr [pWndClassExA + 40], offset szClsName     ; lpszClassName = szClsName;
    
    push offset pWndClassExA
    call pfnRegisterClassExA
    test eax, eax
    je Fn_exit
    
    push 0                  ; lpParam
    push offset _image_base ; hInstance
    push 0                  ; menu
    push 0                  ; parent
    push 480                ; height
    push 640                ; width
    push 80000000h          ; y - CW_USEDEFAULT to spawn window at a "random" default place
    push 80000000h          ; x - CW_USEDEFAULT to spawn window at a "random" default place
    push 10CA0000h          ; dwStyle - WS_OVERLAPPEDWINDOW ^ WS_THICKFRAME | WS_VISIBLE (WS_VISIBLE is used here to skip using ShowWindow() + UpdateWindow() combo)
    push offset szWndTitle  ; lpWindowName - the title of the window
    push eax                ; lpClassName - class name or the return value of RegisterClassExA(), both are valid
    push 300h               ; dwExStyle - WS_EX_OVERLAPPEDWINDOW
    call pfnCreateWindowExA
    
    m_uMsg   equ 4
    m_wParam equ 8
message_loop:
    push 0
    push 0
    push 0
    push offset pMsg
    call pfnGetMessageA
    test eax, eax                           ; can be "test al, al" too
    je Fn_exit                              ; when GetMessage() fails it returns (sets eax to) 0, which we will recycle at the
                                            ; end with "push eax" for ExitProcess(0) like we did at RegisterClassExA() above
    push offset pMsg
    call pfnTranslateMessage
    push offset pMsg
    call pfnDispatchMessageA                ; i don't care what values do TranslateMessage() and DispatchMessageA() return
    sub esp, 4                              ; BUG: DispatchMessage() seems to increase esp one dword (?) so we subtract 4 from it to make it fixed
    
    cmp dword ptr [pMsg+m_uMsg], 18         ; 18 == WM_QUIT
    cmove eax, dword ptr [pMsg+m_wParam]    ; "return" msg.wParam;
    jne Message_loop

fn_exit:
    push eax
    call pfnExitProcess                     ; we need to call ExitProcess() otherwise we will return back to the deep pits of ntdll ...
    xor eax, eax                            ; ... with an exception (access violation reading location 0xC)
    leave
    ret
_start ENDP
END