@echo off
:: powershell messes up the manifest parameter so here's a separate command shell for that
ml /c /coff /nologo /Zi /Foprog.obj prog.asm & ^
link ^
/manifest:embed ^
/manifestinput:prog.exe.manifest ^
/debug:none ^
/subsystem:windows ^
/entry:start ^
prog.obj
@echo on