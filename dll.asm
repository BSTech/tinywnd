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
include strings.asm

bs_getprocaddress PROC ; void* (void* dllbase, char* fn_name)
    enter 0, 0
    
    mov esi, [ebp + 8] ; dllbase
    mov ebx, [ebp + 12] ; fn_name
    
    ;mov esi, [esi]
    
    push ecx
    push edx
    push edi
    
    xor eax, eax
    
    ; // check base and fn_name is valid and the first character of fn_name is not null (to check empty string)
    test esi, esi
    je Fn_exit
    test ebx, ebx
    je Fn_exit
    mov cl, byte ptr [ebx]
    test cl, cl
    je Fn_exit
    
    mov ecx, [esi + 60]             ; ecx = dos_hdr->e_lfanew
    add ecx, esi
    
    cmp dword ptr [ecx + 124], 0    ; is nt_hdr->directories[export].size == 0?
    je Fn_exit
    
    mov ecx, [ecx + 120]            ; ecx = nt_hdr->directories[export].va
    add ecx, esi
    mov edi, [ecx + 32]             ; edi = export_dir->name_addr
    
    
    mov edx, [ecx + 24]             ; edx = export_dir->num_names
    push ecx
    mov ecx, ebx
    
    dec edx                         ; edx -= 1
    mov ebx, edx                    ; ebx = edx
    shl edx, 2                      ; edx <<= 2 (or edx *= 4, 4 == sizeof(pointer))
    add edi, edx                    ; edi += edx; // make edi point to last name's pointer (names_ptr[num_names - 1]) and iterate backwards below (to reduce number of used registers)

find_name:
    mov edx, esi                    ; edx = esi
    add edx, [esi + edi]            ; edx += names_ptr[n]; // edx = base + names_ptr[n]
    push edx                        ; rhs (names[n])
    push ecx                        ; lhs (fn_name)
    
    call bs_stricomp                ; eax = bs_stricomp(lhs, rhs);

    test eax, eax                   ; if (eax)
    jne Found                       ;     goto Found;
    sub edi, 4                      ; edi -= sizeof(pointer); // --n;
    dec ebx                         ; if (--ebx == 0)
    jne Find_name                   ;     break;
    
    ; // not found and reached the "end" of the list
    ; // after the iteration, eax already holds our return value 0 since the comparator function has returned 0
    jmp Fn_exit
    
found:
    shl ebx, 1
    
    pop ecx
    
    mov edi, [ecx + 36]             ; edi = export_dir->ordn_addr
    add edi, ebx
    mov edx, [esi + edi]            ; edx = export_dir->ordn_addr
    
    shl edx, 16                     ; clear hiword of edx by shifting ...
    shr edx, 16                     ; ... left and right 2 bytes
    shl edx, 2                      ; then multiply edx by 4 (edx <<= 2 or edx *= 4, 4 == sizeof(pointer))
    
    mov edi, [ecx + 28]             ; edi = export_dir->func_addr
    add edi, edx                    ; edi += ordns_ptr[n]
    mov eax, [esi + edi]            ; eax = funcs_ptr[ordns[n]]
    add eax, esi                    ; eax += base + funcs[ordns[n]] == proc address
    
fn_exit:
    pop edi
    pop edx
    pop ecx
    
    leave
    ret 8
bs_getprocaddress ENDP