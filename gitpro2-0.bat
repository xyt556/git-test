@echo off
chcp 936 >nul
setlocal EnableDelayedExpansion

title GitHub ???????????

:MAIN
cls
echo.
echo ========================================
echo     GitHub ???????????
echo ========================================
echo     1. ?????????????
echo     2. ???????????
echo     3. ?????????
echo     4. ???????
echo     5. ???????
echo     6. ???????
echo     7. ???? Git ??????
echo     8. ???? .gitignore
echo     9. ????????
echo     0. ???
echo ========================================
echo.

git --version >nul 2>nul
if errorlevel 1 (
    echo [????] Git ?????
    pause
    exit /b 1
)

for /f "delims=" %%v in ('git --version') do echo [???] %%v
echo [???] ??: %CD%

git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo [???] ??????? Git ???
    set "IN_REPO=0"
) else (
    set "IN_REPO=1"
    for /f "delims=" %%b in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%b"
    if not defined CURRENT_BRANCH set "CURRENT_BRANCH=unknown"
    echo [???] ???: !CURRENT_BRANCH!

    set "REMOTE_URL="
    for /f "delims=" %%r in ('git remote get-url origin 2^>nul') do set "REMOTE_URL=%%r"
    if defined REMOTE_URL (
        echo [???] ???: !REMOTE_URL!
    ) else (
        echo [???] ???: ??????
    )

    set "CHANGED=0"
    for /f %%c in ('git status --short 2^>nul ^| find /c /v ""') do set "CHANGED=%%c"
    echo [???] ???: !CHANGED! ?????
)

set "GIT_USER="
set "GIT_EMAIL="
for /f "delims=" %%n in ('git config --global user.name 2^>nul') do set "GIT_USER=%%n"
for /f "delims=" %%e in ('git config --global user.email 2^>nul') do set "GIT_EMAIL=%%e"

if not defined GIT_USER (
    echo [????] ???????????????????? 7
)
if not defined GIT_EMAIL (
    echo [????] ????????????????? 7
)
if defined GIT_USER if defined GIT_EMAIL (
    echo [???] ???: !GIT_USER!
)

echo.
set /p "choice=????? [0-9]: "

if "%choice%"=="1" goto FIRST_UPLOAD
if "%choice%"=="2" goto PUSH_UPDATE
if "%choice%"=="3" goto PULL_REMOTE
if "%choice%"=="4" goto VIEW_STATUS
if "%choice%"=="5" goto BRANCH_MANAGE
if "%choice%"=="6" goto VIEW_LOG
if "%choice%"=="7" goto CONFIG_USER
if "%choice%"=="8" goto GEN_GITIGNORE
if "%choice%"=="9" goto UNDO_MENU
if "%choice%"=="0" exit /b 0

echo ???????
timeout /t 2 >nul
goto MAIN


:FIRST_UPLOAD
cls
echo.
echo ========== ?????? ==========
echo.

if not defined GIT_USER (
    echo [????] ?????????????
    pause
    goto MAIN
)
if not defined GIT_EMAIL (
    echo [????] ????????????
    pause
    goto MAIN
)

if "%IN_REPO%"=="1" (
    echo [????] ???? Git ???
    set /p "confirm_reinit=???????????? (y/n): "
    if /i "!confirm_reinit!" neq "y" goto MAIN
    goto SET_REMOTE
)

set /p "repo=GitHub ?????: "
if not defined repo (
    echo [????] ??????????
    pause
    goto MAIN
)

echo.
echo [1/6] ?????...
git init
if errorlevel 1 goto ERR

if not exist ".gitignore" (
    set /p "need_ignore=???? .gitignore? (y/n): "
    if /i "!need_ignore!"=="y" call :CREATE_GITIGNORE general
)

echo.
echo [2/6] ???????...
git add .
if errorlevel 1 goto ERR

echo.
echo ???????:
echo ----------------------------------------
git diff --cached --name-status
echo ----------------------------------------

git diff --cached --quiet 2>nul
if not errorlevel 1 (
    echo [????] ????????????
    pause
    goto MAIN
)

echo.
set /p "commit_msg=????? (????????): "
if not defined commit_msg set "commit_msg=Initial Commit"

echo.
echo [3/6] ??...
git commit -m "!commit_msg!"
if errorlevel 1 goto ERR

echo.
echo [4/6] ???? main ???...
git branch -M main
if errorlevel 1 goto ERR

:SET_REMOTE
if not defined repo (
    set /p "repo=GitHub ?????: "
    if not defined repo (
        echo [????] ??????????
        pause
        goto MAIN
    )
)

echo.
echo [5/6] ???????...
git remote get-url origin >nul 2>nul
if errorlevel 1 (
    git remote add origin "!repo!"
) else (
    git remote set-url origin "!repo!"
)
if errorlevel 1 goto ERR

echo.
echo [6/6] ????...

git push -u origin main 2>nul
if errorlevel 1 (
    echo.
    echo [????] ????????????????
    echo   1. ???????
    echo   2. ???????????
    echo   3. ???
    set /p "push_choice=??? [1-3]: "

    if "!push_choice!"=="1" (
        set /p "force_confirm=??????? (yes/no): "
        if /i "!force_confirm!"=="yes" (
            git push -u origin main --force
            if errorlevel 1 goto ERR
        ) else (
            goto MAIN
        )
    ) else if "!push_choice!"=="2" (
        git pull origin main --rebase --allow-unrelated-histories
        if errorlevel 1 goto ERR
        git push -u origin main
        if errorlevel 1 goto ERR
    ) else (
        goto MAIN
    )
)

echo.
echo [OK] ?????????
echo ???: !repo!
echo ???: main
echo.
pause
goto MAIN


:PUSH_UPDATE
cls
echo.
echo ========== ?????? ==========
echo.

if "%IN_REPO%"=="0" (
    echo [????] ???? Git ???????????
    pause
    goto MAIN
)

git remote get-url origin >nul 2>nul
if errorlevel 1 (
    echo [????] ???????????
    pause
    goto MAIN
)

echo ??:
echo ----------------------------------------
git status --short
echo ----------------------------------------

set "HAS_CHANGES=0"
for /f %%x in ('git status --porcelain 2^>nul ^| find /c /v ""') do (
    if %%x gtr 0 set "HAS_CHANGES=1"
)

if "!HAS_CHANGES!"=="0" (
    echo.
    echo [???] ??????
    set /p "force_push=??????????? (y/n): "
    if /i "!force_push!"=="y" (
        git push
        if errorlevel 1 goto ERR
        echo [OK] ???
    )
    pause
    goto MAIN
)

echo.
git diff --stat
echo.

set /p "msg=????? (????????): "
if not defined msg set "msg=update %date% %time:~0,8%"

echo.
echo [1/3] ???...
git add .
if errorlevel 1 goto ERR

echo [2/3] ??...
git commit -m "!msg!"
if errorlevel 1 goto ERR

echo [3/3] ????...
for /f "delims=" %%b in ('git branch --show-current 2^>nul') do set "PUSH_BRANCH=%%b"
if not defined PUSH_BRANCH set "PUSH_BRANCH=main"

git push -u origin "!PUSH_BRANCH!"
if errorlevel 1 (
    echo.
    echo [????] ???????
    set /p "try_pull=?????????? (y/n): "
    if /i "!try_pull!"=="y" (
        git pull --rebase origin "!PUSH_BRANCH!"
        if errorlevel 1 goto ERR
        git push -u origin "!PUSH_BRANCH!"
        if errorlevel 1 goto ERR
    ) else (
        goto ERR
    )
)

echo.
echo [OK] ???????
echo ???: !PUSH_BRANCH!
echo ???: !msg!
echo.
pause
goto MAIN


:PULL_REMOTE
cls
echo.
echo ========== ??????? ==========
echo.

if "%IN_REPO%"=="0" (
    echo [????] ???? Git ???
    pause
    goto MAIN
)

git remote get-url origin >nul 2>nul
if errorlevel 1 (
    echo [????] ?????????
    pause
    goto MAIN
)

for /f "delims=" %%b in ('git branch --show-current 2^>nul') do set "PULL_BRANCH=%%b"
if not defined PULL_BRANCH set "PULL_BRANCH=main"

echo ???: !PULL_BRANCH!
echo.
echo   1. merge
echo   2. rebase
echo   3. fetch
echo.
set /p "pull_type=??? [1-3]: "

if "!pull_type!"=="1" (
    git pull origin "!PULL_BRANCH!"
) else if "!pull_type!"=="2" (
    git pull --rebase origin "!PULL_BRANCH!"
) else if "!pull_type!"=="3" (
    git fetch origin
    echo.
    git log "!PULL_BRANCH!..origin/!PULL_BRANCH!" --oneline 2>nul
) else (
    echo ???????
    pause
    goto MAIN
)

if errorlevel 1 (
    echo [????] ??????
    git diff --name-only --diff-filter=U 2>nul
) else (
    echo [OK] ???
)

echo.
pause
goto MAIN


:VIEW_STATUS
cls
echo.
echo ========== ????? ==========
echo.

if "%IN_REPO%"=="0" (
    echo [????] ???? Git ???
    pause
    goto MAIN
)

echo -- ?? --
git status
echo.
echo -- ??? --
git remote -v
echo.
echo -- ??? --
git branch -a
echo.
echo -- ???5???? --
git log --oneline -5 2>nul
echo.
echo -- ?????? --
for /f "delims=" %%b in ('git branch --show-current 2^>nul') do set "STATUS_BRANCH=%%b"
git log "origin/!STATUS_BRANCH!..!STATUS_BRANCH!" --oneline 2>nul

echo.
pause
goto MAIN


:BRANCH_MANAGE
cls
echo.
echo ========== ??????? ==========
echo.

if "%IN_REPO%"=="0" (
    echo [????] ???? Git ???
    pause
    goto MAIN
)

echo ???????:
echo ----------------------------------------
git branch -a
echo ----------------------------------------
echo.

for /f "delims=" %%b in ('git branch --show-current 2^>nul') do set "NOW_BRANCH=%%b"
echo ???: !NOW_BRANCH!
echo.
echo   1. ???????
echo   2. ???????
echo   3. ??????
echo   4. ??????
echo   5. ??????
echo   6. ????
echo.
set /p "br_choice=??? [1-6]: "

if "!br_choice!"=="1" (
    set /p "new_branch=?????: "
    if not defined new_branch (
        echo [????] ???????
        pause
        goto BRANCH_MANAGE
    )
    git checkout -b "!new_branch!"
    if errorlevel 1 goto ERR
    echo [OK] ?????: !new_branch!

) else if "!br_choice!"=="2" (
    set /p "switch_branch=?????: "
    if not defined switch_branch (
        echo [????] ???????
        pause
        goto BRANCH_MANAGE
    )
    git checkout "!switch_branch!"
    if errorlevel 1 goto ERR
    echo [OK] ??????: !switch_branch!

) else if "!br_choice!"=="3" (
    set /p "merge_branch=?????????: "
    if not defined merge_branch (
        echo [????] ???????
        pause
        goto BRANCH_MANAGE
    )
    git merge "!merge_branch!"
    if errorlevel 1 (
        echo [????] ?????
        git diff --name-only --diff-filter=U 2>nul
    ) else (
        echo [OK] ??????
    )

) else if "!br_choice!"=="4" (
    set /p "del_branch=?????????: "
    if not defined del_branch (
        echo [????] ???????
        pause
        goto BRANCH_MANAGE
    )
    if "!del_branch!"=="!NOW_BRANCH!" (
        echo [????] ?????????????
        pause
        goto BRANCH_MANAGE
    )
    set /p "del_confirm=???? (y/n): "
    if /i "!del_confirm!"=="y" (
        git branch -d "!del_branch!"
        if errorlevel 1 (
            set /p "force_del=??????? (y/n): "
            if /i "!force_del!"=="y" (
                git branch -D "!del_branch!"
                if errorlevel 1 goto ERR
            )
        )
        echo [OK] ?????
    )

) else if "!br_choice!"=="5" (
    set /p "push_br=????? (???=???): "
    if not defined push_br set "push_br=!NOW_BRANCH!"
    git push -u origin "!push_br!"
    if errorlevel 1 goto ERR
    echo [OK] ??????: !push_br!

) else if "!br_choice!"=="6" (
    goto MAIN
)

echo.
pause
goto BRANCH_MANAGE


:VIEW_LOG
cls
echo.
echo ========== ????? ==========
echo.

if "%IN_REPO%"=="0" (
    echo [????] ???? Git ???
    pause
    goto MAIN
)

echo   1. ??? (20??)
echo   2. ??? (10??)
echo   3. ???? (30??)
echo   4. ??????
echo   5. ???????
echo   6. ????
echo.
set /p "log_choice=??? [1-6]: "

if "!log_choice!"=="1" (
    echo.
    git log --oneline -20
) else if "!log_choice!"=="2" (
    echo.
    git log -10
) else if "!log_choice!"=="3" (
    echo.
    git log --oneline --graph --all -30
) else if "!log_choice!"=="4" (
    set /p "log_author=????: "
    git log --oneline --author="!log_author!" -20
) else if "!log_choice!"=="5" (
    set /p "log_keyword=?????: "
    git log --oneline --grep="!log_keyword!" -20
) else if "!log_choice!"=="6" (
    goto MAIN
)

echo.
pause
goto VIEW_LOG


:CONFIG_USER
cls
echo.
echo ========== ??????? ==========
echo.

echo ???????:
echo ----------------------------------------
for /f "delims=" %%n in ('git config --global user.name 2^>nul') do echo ?????: %%n
for /f "delims=" %%e in ('git config --global user.email 2^>nul') do echo ????: %%e
echo ----------------------------------------
echo.
echo   1. ??????????
echo   2. ??????????
echo   3. ?????????
echo   4. ???????
echo   5. ???????
echo   6. ????
echo.
set /p "config_choice=??? [1-6]: "

if "!config_choice!"=="1" (
    set /p "cfg_name=?????: "
    set /p "cfg_email=????: "
    if defined cfg_name git config --global user.name "!cfg_name!"
    if defined cfg_email git config --global user.email "!cfg_email!"
    echo [OK] ??????

) else if "!config_choice!"=="2" (
    if "%IN_REPO%"=="0" (
        echo [????] ??????
        pause
        goto CONFIG_USER
    )
    set /p "cfg_name=?????: "
    set /p "cfg_email=????: "
    if defined cfg_name git config user.name "!cfg_name!"
    if defined cfg_email git config user.email "!cfg_email!"
    echo [OK] ??????

) else if "!config_choice!"=="3" (
    echo.
    git config --global --list 2>nul

) else if "!config_choice!"=="4" (
    set /p "proxy_addr=???????: "
    if defined proxy_addr (
        git config --global http.proxy "!proxy_addr!"
        git config --global https.proxy "!proxy_addr!"
        echo [OK] ????: !proxy_addr!
    )

) else if "!config_choice!"=="5" (
    git config --global --unset http.proxy 2>nul
    git config --global --unset https.proxy 2>nul
    echo [OK] ?????

) else if "!config_choice!"=="6" (
    goto MAIN
)

echo.
pause
goto CONFIG_USER


:GEN_GITIGNORE
cls
echo.
echo ========== gitignore ==========
echo.

if exist ".gitignore" (
    echo [????] ????? .gitignore
    echo ----------------------------------------
    type .gitignore
    echo.
    echo ----------------------------------------
    set /p "overwrite_ignore=????? (y/n): "
    if /i "!overwrite_ignore!" neq "y" goto MAIN
)

echo   1. ???
echo   2. Node.js
echo   3. Python
echo   4. Java
echo   5. C/C++
echo   6. Unity
echo   7. ?????
echo.
set /p "ignore_type=??? [1-7]: "

if "!ignore_type!"=="1" call :CREATE_GITIGNORE general
if "!ignore_type!"=="2" call :CREATE_GITIGNORE node
if "!ignore_type!"=="3" call :CREATE_GITIGNORE python
if "!ignore_type!"=="4" call :CREATE_GITIGNORE java
if "!ignore_type!"=="5" call :CREATE_GITIGNORE cpp
if "!ignore_type!"=="6" call :CREATE_GITIGNORE unity
if "!ignore_type!"=="7" (
    if exist ".gitignore" del .gitignore
    echo ??????????, ???? END ????:
    :CUSTOM_IGNORE_LOOP
    set /p "ignore_line=  > "
    if /i "!ignore_line!"=="END" (
        echo [OK] ??????
        goto SHOW_IGNORE
    )
    echo !ignore_line!>> .gitignore
    goto CUSTOM_IGNORE_LOOP
)

:SHOW_IGNORE
echo.
echo ????:
echo ----------------------------------------
type .gitignore 2>nul
echo.
echo ----------------------------------------
pause
goto MAIN


:UNDO_MENU
cls
echo.
echo ========== ???????? ==========
echo.

if "%IN_REPO%"=="0" (
    echo [????] ???? Git ???
    pause
    goto MAIN
)

echo [????] ??????????????
echo.
echo   1. ????????????? (??add)
echo   2. ??????? (??add??commit)
echo   3. ????????? (???????)
echo   4. ????????? (???????)
echo   5. ??????????
echo   6. ????
echo.
set /p "undo_choice=??? [1-6]: "

if "!undo_choice!"=="1" (
    echo.
    git diff --name-only
    echo.
    set /p "undo_confirm=??????? (yes/no): "
    if /i "!undo_confirm!"=="yes" (
        git checkout -- .
        echo [OK] ?????
    )

) else if "!undo_choice!"=="2" (
    git reset HEAD .
    echo [OK] ????????

) else if "!undo_choice!"=="3" (
    echo.
    git log --oneline -1
    set /p "undo_confirm=???? (y/n): "
    if /i "!undo_confirm!"=="y" (
        git reset --soft HEAD~1
        echo [OK] ?????, ??????
    )

) else if "!undo_choice!"=="4" (
    echo.
    git log --oneline -1
    echo [????] ???????
    set /p "undo_confirm=???? yes ???: "
    if /i "!undo_confirm!"=="yes" (
        git reset --hard HEAD~1
        echo [OK] ?????, ??????
    )

) else if "!undo_choice!"=="5" (
    echo.
    git log --oneline -10
    echo.
    set /p "target_hash=?????: "
    if defined target_hash (
        echo   1. ??????? (soft)
        echo   2. ??????? (hard)
        set /p "reset_type=??? [1-2]: "
        if "!reset_type!"=="1" (
            git reset --soft "!target_hash!"
            echo [OK] ?????
        ) else if "!reset_type!"=="2" (
            set /p "hard_confirm=???? (yes/no): "
            if /i "!hard_confirm!"=="yes" (
                git reset --hard "!target_hash!"
                echo [OK] ?????
            )
        )
    )

) else if "!undo_choice!"=="6" (
    goto MAIN
)

echo.
pause
goto UNDO_MENU


:CREATE_GITIGNORE

set "type=%~1"
if not defined type set "type=general"

(
echo # System
echo .DS_Store
echo Thumbs.db
echo Desktop.ini
echo *.swp
echo *.swo
echo *~
echo.
echo # IDE
echo .idea/
echo .vscode/
echo *.sublime-project
echo *.sublime-workspace
echo.
echo # Env
echo .env
echo .env.local
echo .env.*.local
) > .gitignore

if /i "%type%"=="node" (
    (
    echo.
    echo # Node.js
    echo node_modules/
    echo npm-debug.log*
    echo yarn-debug.log*
    echo yarn-error.log*
    echo package-lock.json
    echo yarn.lock
    echo dist/
    echo build/
    echo .cache/
    echo coverage/
    ) >> .gitignore
)

if /i "%type%"=="python" (
    (
    echo.
    echo # Python
    echo __pycache__/
    echo *.py[cod]
    echo *.so
    echo .Python
    echo venv/
    echo env/
    echo .venv/
    echo *.egg-info/
    echo dist/
    echo build/
    echo .mypy_cache/
    echo .pytest_cache/
    ) >> .gitignore
)

if /i "%type%"=="java" (
    (
    echo.
    echo # Java
    echo *.class
    echo *.jar
    echo *.war
    echo *.ear
    echo target/
    echo .gradle/
    echo build/
    echo out/
    echo .settings/
    echo .classpath
    echo .project
    echo *.iml
    ) >> .gitignore
)

if /i "%type%"=="cpp" (
    (
    echo.
    echo # C/C++
    echo *.o
    echo *.obj
    echo *.exe
    echo *.dll
    echo *.so
    echo *.dylib
    echo *.lib
    echo *.a
    echo *.out
    echo build/
    echo cmake-build-*/
    echo CMakeFiles/
    echo CMakeCache.txt
    echo .vs/
    echo x64/
    echo Debug/
    echo Release/
    ) >> .gitignore
)

if /i "%type%"=="unity" (
    (
    echo.
    echo # Unity
    echo [Ll]ibrary/
    echo [Tt]emp/
    echo [Oo]bj/
    echo [Bb]uild/
    echo [Bb]uilds/
    echo [Ll]ogs/
    echo [Uu]ser[Ss]ettings/
    echo MemoryCaptures/
    echo .vs/
    echo *.csproj
    echo *.unityproj
    echo *.sln
    echo *.suo
    ) >> .gitignore
)

echo [OK] .gitignore (%type%)
goto :eof


:ERR
echo.
echo ========================================
echo   [????] ???????
echo ----------------------------------------
echo   - ???????????
echo   - ??? GitHub ???
echo   - ??????????????
echo   - ???????????
echo   - ??????????
echo ========================================
echo.
pause
goto MAIN