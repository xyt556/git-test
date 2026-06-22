@echo off
chcp 65001 >nul

title GitHub 自动管理工具

echo.
echo =====================================
echo GitHub 自动管理工具
echo =====================================
echo.

:: 检测Git
git --version >nul 2>nul

if errorlevel 1 (
    echo Git未安装！
    pause
    exit /b
)

:: 判断是否首次上传
if not exist ".git" goto FIRST

goto UPDATE

:FIRST

echo 检测到当前目录尚未初始化Git
echo.

set /p repo=请输入GitHub仓库地址：

git init

git add .

git commit -m "Initial Commit"

git branch -M main

git remote add origin %repo%

git push -u origin main

echo.
echo 首次上传完成！
pause
exit

:UPDATE

echo 当前仓库状态：
git status --short

echo.
set /p msg=请输入提交说明：

if "%msg%"=="" set msg=update

git add .

git commit -m "%msg%"

git push

echo.
echo 推送完成！
pause