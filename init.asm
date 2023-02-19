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
assume fs:nothing

.data
    _image_base     dd 0
    _peb            dd 0
    _is_dbg_present db 0
    _ldr_list       dd 0

.code
bs_init PROC
    enter 0, 0
    push ebx
    push ecx
    push edx
    push esi

    mov eax, dword ptr fs:48        ; eax = ppeb
    mov _peb, eax


    mov ebx, [eax + 2]              ; ebx = ppeb->is_debugger_present (1/0)
    mov _is_dbg_present, bl


    mov ebx, [eax + 12]             ; ebx = ppeb->ldr
    mov ebx, [ebx + 20]             ; ebx = ldr->module_list
    mov ebx, [ebx]                  ; ebx = module_list->flink
    mov _ldr_list, ebx


    mov ebx, [eax + 8]              ; ppeb->image_base
    mov _image_base, ebx            ; ppeb->image_base

    mov cx, word ptr [ebx]
    cmp cx, 23117                   ; check MZ signature at base
    setz al
    jne Fn_exit


    mov ecx, [ebx + 60]             ; ecx = dos_header->e_lfanew
    mov edx, [ebx + ecx]            ; ecx = file_header

    cmp dx, 17744                   ; check PE signature
    setz dl
    mov al, dl
    jne Fn_exit

    mov edx, ebx
    add edx, ecx
    add edx, 4
    mov ecx, edx                    ; ecx = nthdr

    mov dx, [ecx + 2]               ; number of sections
    test dx, dx                     ; is number of sections zero?
    je Fn_exit


    and ecx, 1
    mov al, cl
    ;mov eax, ecx                   ; return result(s) of cmp instructions above (from cl)
    
fn_exit:
    
    pop esi
    pop edx
    pop ecx
    pop ebx
    
    leave
    ret
bs_init ENDP


bs_find_loaded_module PROC ; void* (wchar_t* dllname)
    enter 0, 0
    ;mov esi, [ebp + 8]
    
    xor eax, eax
    push ebx
    push ecx
    
    mov ebx, _ldr_list              ; _ldr_list is a bidirectional linked list
    
iterate_module_list:
    mov ecx, dword ptr [ebx + 16]   ; ecx = current_elem->dll_base
    test ecx, ecx                   ; if (!ecx)
    je Fn_exit                      ;     goto Fn_exit;
    cmp word ptr [ebx + 36], 0      ; if (current_elem->basedllname.length == 0) // offsets: full = 28, base = 36
    je Fn_exit                      ;     goto Fn_exit;
    
    push dword ptr [ebx + 40]       ; current_elem->basedllname.buffer
    push [ebp + 8]                  ; dllname
    call bs_wcsicomp
    test eax, eax
    jne Found
    mov ebx, [ebx]                  ; current_elem = current_elem->next;
    jmp Iterate_module_list
    
found:
    mov eax, ecx
    
fn_exit:
    pop ecx
    pop ebx
    leave
    ret 4
bs_find_loaded_module ENDP

assume fs:error