@echo off
chcp 65001 > nul
title Subir DB_JDRefrigeracion a GitHub
color 0A
echo ======================================================================
echo          SUBIENDO PROYECTO JD REFRIGERACION A GITHUB
echo ======================================================================
echo.

cd /d "D:\Tareas\UPeU\ciclo 4\base de datos\DB_JDRefrigeracion"

echo [1/4] Verificando repositorio remoto...
git remote set-url origin https://github.com/ApazaMamaniWilsonR/DB_JDRefrigeracion.git 2>nul || git remote add origin https://github.com/ApazaMamaniWilsonR/DB_JDRefrigeracion.git

echo [2/4] Creando y cambiando a la rama feature/administracion-unidad-2...
git checkout -B feature/administracion-unidad-2

echo [3/4] Preparando archivos y generando commit...
git add .
git commit -m "feat(db): administracion empresarial unidad 2 - tablespaces, rbac, auditoria, awr y particionamiento"

echo [4/4] Subiendo cambios a GitHub (git push)...
git push -u origin feature/administracion-unidad-2

echo.
echo ======================================================================
echo   ¡TODO SUBIDO CON EXITO! ABRIENDO GITHUB PARA CREAR EL PULL REQUEST...
echo ======================================================================
echo.

start https://github.com/ApazaMamaniWilsonR/DB_JDRefrigeracion/compare

pause
