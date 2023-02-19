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

bs_stricomp PROC ; bool (char*, char*)
    enter 0, 0
    
    push ebx
    push ecx
    push esi
    
    mov ecx, [ebp + 8]          ; ecx = [esp + offset of "lhs" parameter]
    mov esi, [ebp + 12]         ; esi = [esp + offset of "rhs" parameter]

    xor eax, eax                ; eax low (al) will store the result, currently 0
    
    test ecx, ecx               ; if (!lhs)
    je short Fn_exit            ;     goto fn_exit;
    test esi, esi               ; else if (!rhs)
    je short Fn_exit            ;     goto fn_exit;
    
next_char:                      ; while (1) {
    mov bl, byte ptr [ecx]      ;     bl = *lhs;
    test bl, bl                 ;     if (!bl)
    je Fn_exit                  ;         goto fn_exit;
    
    mov bh, byte ptr [esi]      ;     bh = *rhs;
    test bh, bh                 ;     if (!bh)
    je Fn_exit                  ;         goto fn_exit;
    
    xor bl, bh                  ;     bl ^= bh;         // we xor both characters to fast compare lower side of character index (ex. A = 0x41, a = 0x61, we compare 0xN1)
    test bl, -33                ;     if (bl & -33)     // then we check if both characters have their 0x40 or 0x60 "bit" is set (ex. A = 0x41, a = 0x61, we check 0x4N/0x6N)
                                ;     {                 // "-33" == bitwise not of "32"
    sete al                     ;         al = 0;       // (al = !(bl & -33)) --> this is automatically "1" when the comparison result is success ...
    jne Fn_exit                 ;         goto fn_exit; // ... and don't be deceived by its place in "if" block since it is free of the condition
                                ;     }                 // when the condition is true, it means the comparison has failed hence al == 0
    
    
    inc ecx                     ;     lhs++;
    inc esi                     ;     rhs++;
    jmp Next_char               ; }
    
fn_exit:
    pop esi
    pop ecx
    pop ebx
    
    leave
    ret 8
bs_stricomp ENDP

bs_wcsicomp PROC ; bool (wchar_t*, wchar_t*)
    enter 0, 0
    
    push ebx
    push ecx
    push edx
    push esi
    
    mov ecx, [ebp + 8]          ; ecx = [esp + offset of "lhs" parameter]
    mov esi, [ebp + 12]         ; esi = [esp + offset of "rhs" parameter]
    
    xor eax, eax                ; eax low (al) will store the result, currently 0
    
    test ecx, ecx               ; if (!lhs)
    je short Fn_exit            ;     goto fn_exit;
    test esi, esi               ; else if (!rhs)
    je short Fn_exit            ;     goto fn_exit;
    
next_char:                      ; while (1) {
    mov bx, word ptr [ecx]      ;     bx = *lhs;
    test bx, bx                 ;     if (!bx)
    je Fn_exit                  ;         goto fn_exit;
    
    mov dx, word ptr [esi]      ;     dx = *rhs;
    test dx, dx                 ;     if (!dx)
    je Fn_exit                  ;         goto fn_exit;
    
    xor bx, dx                  ;     bx ^= dx          // we xor both characters to fast compare lower side of character index (ex. A = 0x41, a = 0x61, we compare 0xN1)
    test bx, -33                ;     if (bx & -33)     // then we check if both characters have their 0x40 or 0x60 "bit" is set (ex. A = 0x41, a = 0x61, we check 0x4N/0x6N)
                                ;     {                 // "-33" == bitwise not of "32"
    sete al                     ;         al = 0        // (al = !(bx & -33)) --> this is automatically "1" when the comparison result is success ...
    jne Fn_exit                 ;         goto fn_exit; // ... and don't be deceived by its place in "if" block since it is free of the condition
                                ;     }                 // when the condition is true, it means the comparison has failed hence al == 0
    
    
    add ecx, 2                  ;     lhs += 2; // 2 == sizeof(wchar_t)
    add esi, 2                  ;     rhs += 2;
    jmp Next_char               ; }
    
fn_exit:
    pop esi
    pop edx
    pop ecx
    pop ebx
    
    leave
    ret 8
bs_wcsicomp ENDP
