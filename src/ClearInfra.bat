@echo off
@echo Protegendo o ZEOS de exclus�es
attrib +R Build\z*.*

@echo Apagando pacotes compilados no build
del Build\*.exe
del Build\*.dcp
del Build\*.bpl

@echo Copiando os dfm da guibuilder para o build
copy Core\GUIBuilder\*.dfm Build

@echo Apagando arquivos tempor�rios
del *.~* /s
del *.dcu /s
del *.ddp /s
