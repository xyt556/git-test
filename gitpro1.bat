@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

title GitHub 自动管理工具 (增强版)

:: ============================================
:: 颜色/样式辅助（通过 findstr 实现彩色输出）
:: ============================================

:MAIN
cls
echo.
echo ╔═══════════════════════════════════════════╗
echo ║       GitHub 自动管理工具 (增强版)        ║
echo ╠═══════════════════════════════════════════╣
echo ║  1. 初始化并首次上传                      ║
echo ║  2. 提交并推送更新                        ║
echo ║  3. 拉取远程更新                          ║
echo ║  4. 查看仓库状态                          ║
echo ║  5. 分支管理                              ║
echo ║  6. 查看提交日志                          ║
echo ║  7. 配置 Git 用户信息                     ║
echo ║  8. 生成 .gitignore                       ║
echo ║  9. 撤销操作                              ║
echo ║  0. 退出                                  ║
echo ╚═══════════════════════════════════════════╝
echo.

:: ─────────────── 基础检测 ───────────────

:: 检测 Git 是否安装
git --version >nul 2>nul
if errorlevel 1 (
    echo [错误] Git 未安装或未加入系统 PATH！
    echo.
    echo 请前往 https://git-scm.com/downloads 下载安装
    pause
    exit /b 1
)

:: 显示 Git 版本
for /f "delims=" %%v in ('git --version') do echo [信息] 当前 %%v

:: 显示当前目录
echo [信息] 工作目录: %CD%

:: 检测是否在 Git 仓库中
git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo [信息] 当前目录不是 Git 仓库
    set "IN_REPO=0"
) else (
    set "IN_REPO=1"
    :: 获取当前分支名
    for /f "delims=" %%b in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%b"
    if not defined CURRENT_BRANCH set "CURRENT_BRANCH=未知"
    echo [信息] 当前分支: !CURRENT_BRANCH!

    :: 获取远程地址
    for /f "delims=" %%r in ('git remote get-url origin 2^>nul') do set "REMOTE_URL=%%r"
    if defined REMOTE_URL (
        echo [信息] 远程地址: !REMOTE_URL!
    ) else (
        echo [信息] 远程地址: 未配置
    )

    :: 显示未提交文件数
    set "CHANGED=0"
    for /f %%c in ('git status --short 2^>nul ^| find /c /v ""') do set "CHANGED=%%c"
    echo [信息] 未提交变更: !CHANGED! 个文件
)

:: 检测用户配置
for /f "delims=" %%n in ('git config --global user.name 2^>nul') do set "GIT_USER=%%n"
for /f "delims=" %%e in ('git config --global user.email 2^>nul') do set "GIT_EMAIL=%%e"

if not defined GIT_USER (
    echo.
    echo [警告] 未配置 Git 用户名！请先选择选项 7 进行配置
)
if not defined GIT_EMAIL (
    echo [警告] 未配置 Git 邮箱！请先选择选项 7 进行配置
) else (
    echo [信息] 用户: !GIT_USER! ^<!GIT_EMAIL!^>
)

echo.
set /p "choice=请选择操作 [0-9]："

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

echo [错误] 无效选择！
timeout /t 2 >nul
goto MAIN


:: ═══════════════════════════════════════
:: 1. 首次上传
:: ═══════════════════════════════════════
:FIRST_UPLOAD
cls
echo.
echo ══════════ 首次上传 ══════════
echo.

:: 检查用户配置
if not defined GIT_USER (
    echo [错误] 请先配置 Git 用户名（选项 7）
    pause
    goto MAIN
)
if not defined GIT_EMAIL (
    echo [错误] 请先配置 Git 邮箱（选项 7）
    pause
    goto MAIN
)

:: 如果已经是仓库，给出警告
if "%IN_REPO%"=="1" (
    echo [警告] 当前目录已经是一个 Git 仓库！
    echo.
    set /p "confirm_reinit=是否要重新配置远程地址？(y/n)："
    if /i "!confirm_reinit!" neq "y" goto MAIN
    goto SET_REMOTE
)

:: 输入仓库地址
set /p "repo=请输入 GitHub 仓库地址："
if not defined repo (
    echo [错误] 仓库地址不能为空！
    pause
    goto MAIN
)

:: 验证地址格式（简单检查）
echo !repo! | findstr /i "github.com" >nul
if errorlevel 1 (
    echo [警告] 输入的地址似乎不是 GitHub 地址
    set /p "confirm_url=是否继续？(y/n)："
    if /i "!confirm_url!" neq "y" goto MAIN
)

echo.
echo [步骤 1/6] 初始化仓库...
git init
if errorlevel 1 goto ERR

:: 检查是否需要生成 .gitignore
if not exist ".gitignore" (
    echo.
    set /p "need_ignore=检测到没有 .gitignore 文件，是否自动生成？(y/n)："
    if /i "!need_ignore!"=="y" call :CREATE_GITIGNORE
)

echo.
echo [步骤 2/6] 添加所有文件...
git add .
if errorlevel 1 goto ERR

:: 显示将要提交的文件
echo.
echo 即将提交以下文件：
echo ─────────────────────
git diff --cached --name-status
echo ─────────────────────

:: 检查是否有内容可提交
git diff --cached --quiet 2>nul
if not errorlevel 1 (
    echo.
    echo [警告] 没有可提交的文件！
    echo 请确认当前目录下有文件，且没有被 .gitignore 忽略
    pause
    goto MAIN
)

echo.
set /p "commit_msg=请输入首次提交说明 (直接回车使用默认)："
if not defined commit_msg set "commit_msg=Initial Commit"

echo.
echo [步骤 3/6] 提交文件...
git commit -m "!commit_msg!"
if errorlevel 1 goto ERR

echo.
echo [步骤 4/6] 设置主分支为 main...
git branch -M main
if errorlevel 1 goto ERR

:SET_REMOTE
if not defined repo (
    set /p "repo=请输入 GitHub 仓库地址："
    if not defined repo (
        echo [错误] 仓库地址不能为空！
        pause
        goto MAIN
    )
)

echo.
echo [步骤 5/6] 配置远程地址...
git remote get-url origin >nul 2>nul
if errorlevel 1 (
    git remote add origin "!repo!"
) else (
    echo [信息] origin 已存在，更新为新地址...
    git remote set-url origin "!repo!"
)
if errorlevel 1 goto ERR

echo.
echo [步骤 6/6] 推送到远程仓库...
echo.

:: 尝试推送
git push -u origin main 2>nul
if errorlevel 1 (
    echo.
    echo [警告] 普通推送失败，可能是远程仓库非空
    echo.
    echo 选择处理方式：
    echo   1. 强制推送（会覆盖远程内容）
    echo   2. 先拉取合并再推送
    echo   3. 取消操作
    echo.
    set /p "push_choice=请选择 [1-3]："

    if "!push_choice!"=="1" (
        echo.
        set /p "force_confirm=确认强制推送？远程内容将被覆盖！(yes/no)："
        if /i "!force_confirm!"=="yes" (
            git push -u origin main --force
            if errorlevel 1 goto ERR
        ) else (
            echo 已取消。
            pause
            goto MAIN
        )
    ) else if "!push_choice!"=="2" (
        git pull origin main --rebase --allow-unrelated-histories
        if errorlevel 1 (
            echo [错误] 合并失败，可能需要手动解决冲突
            goto ERR
        )
        git push -u origin main
        if errorlevel 1 goto ERR
    ) else (
        echo 已取消。
        pause
        goto MAIN
    )
)

echo.
echo ✓ 首次上传完成！
echo.
echo 仓库地址: !repo!
echo 分    支: main
echo.
pause
goto MAIN


:: ═══════════════════════════════════════
:: 2. 提交并推送更新
:: ═══════════════════════════════════════
:PUSH_UPDATE
cls
echo.
echo ══════════ 提交并推送 ══════════
echo.

:: 检查是否是仓库
if "%IN_REPO%"=="0" (
    echo [错误] 当前目录不是 Git 仓库！请先执行首次上传。
    pause
    goto MAIN
)

:: 检查是否配置了远程
git remote get-url origin >nul 2>nul
if errorlevel 1 (
    echo [错误] 未配置远程地址！请先执行首次上传或手动添加 remote。
    pause
    goto MAIN
)

:: 显示详细状态
echo 当前仓库状态：
echo ─────────────────────
git status --short
echo ─────────────────────

:: 检查是否有变更
git status --porcelain >nul 2>nul
set "HAS_CHANGES=0"
for /f %%x in ('git status --porcelain 2^>nul ^| find /c /v ""') do (
    if %%x gtr 0 set "HAS_CHANGES=1"
)

if "!HAS_CHANGES!"=="0" (
    echo.
    echo [信息] 没有检测到任何变更，无需提交。
    echo.
    set /p "force_push=是否仍要尝试推送本地未推送的提交？(y/n)："
    if /i "!force_push!"=="y" (
        git push
        if errorlevel 1 goto ERR
        echo.
        echo ✓ 推送完成！
    )
    pause
    goto MAIN
)

echo.
echo 变更文件详情：
echo ─────────────────────
git diff --stat
echo ─────────────────────

echo.
set /p "msg=请输入提交说明（直接回车使用默认）："
if not defined msg set "msg=update %date% %time:~0,8%"

echo.
echo [步骤 1/3] 暂存所有变更...
git add .
if errorlevel 1 goto ERR

echo.
echo [步骤 2/3] 提交...
git commit -m "!msg!"
if errorlevel 1 goto ERR

echo.
echo [步骤 3/3] 推送到远程...

:: 获取当前分支
for /f "delims=" %%b in ('git branch --show-current 2^>nul') do set "PUSH_BRANCH=%%b"
if not defined PUSH_BRANCH set "PUSH_BRANCH=main"

git push -u origin "!PUSH_BRANCH!"
if errorlevel 1 (
    echo.
    echo [警告] 推送失败！可能需要先拉取远程更新
    echo.
    set /p "try_pull=是否先拉取再推送？(y/n)："
    if /i "!try_pull!"=="y" (
        git pull --rebase origin "!PUSH_BRANCH!"
        if errorlevel 1 (
            echo [错误] 拉取合并失败，可能有冲突需要手动解决
            goto ERR
        )
        git push -u origin "!PUSH_BRANCH!"
        if errorlevel 1 goto ERR
    ) else (
        goto ERR
    )
)

echo.
echo ✓ 推送完成！
echo.
echo 分    支: !PUSH_BRANCH!
echo 提交说明: !msg!
echo.
pause
goto MAIN


:: ═══════════════════════════════════════
:: 3. 拉取远程更新
:: ═══════════════════════════════════════
:PULL_REMOTE
cls
echo.
echo ══════════ 拉取远程更新 ══════════
echo.

if "%IN_REPO%"=="0" (
    echo [错误] 当前目录不是 Git 仓库！
    pause
    goto MAIN
)

git remote get-url origin >nul 2>nul
if errorlevel 1 (
    echo [错误] 未配置远程地址！
    pause
    goto MAIN
)

:: 获取当前分支
for /f "delims=" %%b in ('git branch --show-current 2^>nul') do set "PULL_BRANCH=%%b"
if not defined PULL_BRANCH set "PULL_BRANCH=main"

echo 当前分支: !PULL_BRANCH!
echo.

echo 选择拉取方式：
echo   1. 普通拉取 (merge)
echo   2. 变基拉取 (rebase) - 更干净的历史
echo   3. 仅获取不合并 (fetch)
echo.
set /p "pull_type=请选择 [1-3]："

if "!pull_type!"=="1" (
    echo.
    echo 正在拉取...
    git pull origin "!PULL_BRANCH!"
) else if "!pull_type!"=="2" (
    echo.
    echo 正在变基拉取...
    git pull --rebase origin "!PULL_BRANCH!"
) else if "!pull_type!"=="3" (
    echo.
    echo 正在获取远程信息...
    git fetch origin
    echo.
    echo 远程与本地的差异：
    git log "!PULL_BRANCH!..origin/!PULL_BRANCH!" --oneline 2>nul
) else (
    echo [错误] 无效选择！
    pause
    goto MAIN
)

if errorlevel 1 (
    echo.
    echo [错误] 拉取失败！可能存在冲突
    echo.
    echo 冲突文件：
    git diff --name-only --diff-filter=U 2>nul
    echo.
    echo 请手动解决冲突后再提交
) else (
    echo.
    echo ✓ 拉取完成！
)

echo.
pause
goto MAIN


:: ═══════════════════════════════════════
:: 4. 查看仓库状态
:: ═══════════════════════════════════════
:VIEW_STATUS
cls
echo.
echo ══════════ 仓库状态 ══════════
echo.

if "%IN_REPO%"=="0" (
    echo [错误] 当前目录不是 Git 仓库！
    pause
    goto MAIN
)

echo ── 基本状态 ──
git status
echo.

echo ── 远程仓库 ──
git remote -v
echo.

echo ── 所有分支 ──
git branch -a
echo.

echo ── 最近 5 次提交 ──
git log --oneline -5 2>nul
echo.

echo ── 未推送的提交 ──
for /f "delims=" %%b in ('git branch --show-current 2^>nul') do set "STATUS_BRANCH=%%b"
git log "origin/!STATUS_BRANCH!..!STATUS_BRANCH!" --oneline 2>nul
if errorlevel 1 echo (无法获取，可能未设置上游分支)
echo.

pause
goto MAIN


:: ═══════════════════════════════════════
:: 5. 分支管理
:: ═══════════════════════════════════════
:BRANCH_MANAGE
cls
echo.
echo ══════════ 分支管理 ══════════
echo.

if "%IN_REPO%"=="0" (
    echo [错误] 当前目录不是 Git 仓库！
    pause
    goto MAIN
)

echo 当前分支列表：
echo ─────────────────────
git branch -a
echo ─────────────────────
echo.

for /f "delims=" %%b in ('git branch --show-current 2^>nul') do set "NOW_BRANCH=%%b"
echo 当前在: !NOW_BRANCH!
echo.

echo 选择操作：
echo   1. 创建新分支
echo   2. 切换分支
echo   3. 合并分支到当前分支
echo   4. 删除本地分支
echo   5. 推送分支到远程
echo   6. 返回主菜单
echo.
set /p "br_choice=请选择 [1-6]："

if "!br_choice!"=="1" (
    set /p "new_branch=请输入新分支名："
    if not defined new_branch (
        echo [错误] 分支名不能为空！
        pause
        goto BRANCH_MANAGE
    )
    git checkout -b "!new_branch!"
    if errorlevel 1 goto ERR
    echo.
    echo ✓ 已创建并切换到分支: !new_branch!

) else if "!br_choice!"=="2" (
    set /p "switch_branch=请输入要切换的分支名："
    if not defined switch_branch (
        echo [错误] 分支名不能为空！
        pause
        goto BRANCH_MANAGE
    )
    git checkout "!switch_branch!"
    if errorlevel 1 goto ERR
    echo.
    echo ✓ 已切换到分支: !switch_branch!

) else if "!br_choice!"=="3" (
    set /p "merge_branch=请输入要合并的分支名："
    if not defined merge_branch (
        echo [错误] 分支名不能为空！
        pause
        goto BRANCH_MANAGE
    )
    git merge "!merge_branch!"
    if errorlevel 1 (
        echo.
        echo [错误] 合并冲突！请手动解决
        echo 冲突文件：
        git diff --name-only --diff-filter=U 2>nul
    ) else (
        echo.
        echo ✓ 合并完成！
    )

) else if "!br_choice!"=="4" (
    set /p "del_branch=请输入要删除的分支名："
    if not defined del_branch (
        echo [错误] 分支名不能为空！
        pause
        goto BRANCH_MANAGE
    )
    if "!del_branch!"=="!NOW_BRANCH!" (
        echo [错误] 不能删除当前所在的分支！
        pause
        goto BRANCH_MANAGE
    )
    set /p "del_confirm=确认删除分支 !del_branch!？(y/n)："
    if /i "!del_confirm!"=="y" (
        git branch -d "!del_branch!"
        if errorlevel 1 (
            echo.
            set /p "force_del=分支未合并，是否强制删除？(y/n)："
            if /i "!force_del!"=="y" (
                git branch -D "!del_branch!"
                if errorlevel 1 goto ERR
                echo ✓ 已强制删除分支: !del_branch!
            )
        ) else (
            echo ✓ 已删除分支: !del_branch!
        )
    )

) else if "!br_choice!"=="5" (
    set /p "push_br=请输入要推送的分支名（直接回车推送当前分支）："
    if not defined push_br set "push_br=!NOW_BRANCH!"
    git push -u origin "!push_br!"
    if errorlevel 1 goto ERR
    echo.
    echo ✓ 已推送分支 !push_br! 到远程！

) else if "!br_choice!"=="6" (
    goto MAIN
)

echo.
pause
goto BRANCH_MANAGE


:: ═══════════════════════════════════════
:: 6. 查看提交日志
:: ═══════════════════════════════════════
:VIEW_LOG
cls
echo.
echo ══════════ 提交日志 ══════════
echo.

if "%IN_REPO%"=="0" (
    echo [错误] 当前目录不是 Git 仓库！
    pause
    goto MAIN
)

echo 选择查看方式：
echo   1. 简洁模式（最近 20 条）
echo   2. 详细模式（最近 10 条）
echo   3. 图形模式（分支图）
echo   4. 指定作者
echo   5. 搜索关键词
echo   6. 返回主菜单
echo.
set /p "log_choice=请选择 [1-6]："

if "!log_choice!"=="1" (
    echo.
    git log --oneline -20
) else if "!log_choice!"=="2" (
    echo.
    git log --format="──────────────────────────────────%%nhash:    %%H%%n作者:    %%an ^<%%ae^>%%n日期:    %%ai%%n说明:    %%s%%n" -10
) else if "!log_choice!"=="3" (
    echo.
    git log --oneline --graph --all -30
) else if "!log_choice!"=="4" (
    set /p "log_author=请输入作者名："
    echo.
    git log --oneline --author="!log_author!" -20
) else if "!log_choice!"=="5" (
    set /p "log_keyword=请输入搜索关键词："
    echo.
    git log --oneline --grep="!log_keyword!" -20
) else if "!log_choice!"=="6" (
    goto MAIN
) else (
    echo [错误] 无效选择！
)

echo.
pause
goto VIEW_LOG


:: ═══════════════════════════════════════
:: 7. 配置 Git 用户信息
:: ═══════════════════════════════════════
:CONFIG_USER
cls
echo.
echo ══════════ 配置 Git 用户信息 ══════════
echo.

:: 显示当前配置
echo 当前全局配置：
echo ─────────────────────
for /f "delims=" %%n in ('git config --global user.name 2^>nul') do echo 用户名: %%n
for /f "delims=" %%e in ('git config --global user.email 2^>nul') do echo 邮  箱: %%e
echo ─────────────────────
echo.

echo 选择操作：
echo   1. 设置全局用户名和邮箱
echo   2. 设置当前仓库用户名和邮箱
echo   3. 查看所有 Git 配置
echo   4. 配置代理（加速访问）
echo   5. 清除代理设置
echo   6. 返回主菜单
echo.
set /p "config_choice=请选择 [1-6]："

if "!config_choice!"=="1" (
    set /p "cfg_name=请输入用户名："
    set /p "cfg_email=请输入邮箱："
    if defined cfg_name git config --global user.name "!cfg_name!"
    if defined cfg_email git config --global user.email "!cfg_email!"
    echo.
    echo ✓ 全局用户配置完成！

) else if "!config_choice!"=="2" (
    if "%IN_REPO%"=="0" (
        echo [错误] 当前目录不是 Git 仓库！
        pause
        goto CONFIG_USER
    )
    set /p "cfg_name=请输入用户名："
    set /p "cfg_email=请输入邮箱："
    if defined cfg_name git config user.name "!cfg_name!"
    if defined cfg_email git config user.email "!cfg_email!"
    echo.
    echo ✓ 当前仓库用户配置完成！

) else if "!config_choice!"=="3" (
    echo.
    echo ── 全局配置 ──
    git config --global --list 2>nul
    echo.

) else if "!config_choice!"=="4" (
    echo.
    echo 代理类型：
    echo   1. HTTP 代理（如 http://127.0.0.1:7890）
    echo   2. SOCKS5 代理（如 socks5://127.0.0.1:7891）
    echo.
    set /p "proxy_type=请选择 [1-2]："
    set /p "proxy_addr=请输入代理地址："

    if defined proxy_addr (
        git config --global http.proxy "!proxy_addr!"
        git config --global https.proxy "!proxy_addr!"
        echo.
        echo ✓ 代理已设置为: !proxy_addr!
    )

) else if "!config_choice!"=="5" (
    git config --global --unset http.proxy 2>nul
    git config --global --unset https.proxy 2>nul
    echo.
    echo ✓ 代理设置已清除！

) else if "!config_choice!"=="6" (
    goto MAIN
)

echo.
pause
goto CONFIG_USER


:: ═══════════════════════════════════════
:: 8. 生成 .gitignore
:: ═══════════════════════════════════════
:GEN_GITIGNORE
cls
echo.
echo ══════════ 生成 .gitignore ══════════
echo.

if exist ".gitignore" (
    echo [警告] 当前目录已存在 .gitignore 文件！
    echo.
    echo 当前内容：
    echo ─────────────────────
    type .gitignore
    echo.
    echo ─────────────────────
    echo.
    set /p "overwrite_ignore=是否覆盖？(y/n)："
    if /i "!overwrite_ignore!" neq "y" goto MAIN
)

echo 选择项目类型：
echo   1. 通用项目
echo   2. Node.js 项目
echo   3. Python 项目
echo   4. Java 项目
echo   5. C/C++ 项目
echo   6. Unity 项目
echo   7. 自定义
echo.
set /p "ignore_type=请选择 [1-7]："

if "!ignore_type!"=="1" call :CREATE_GITIGNORE general
if "!ignore_type!"=="2" call :CREATE_GITIGNORE node
if "!ignore_type!"=="3" call :CREATE_GITIGNORE python
if "!ignore_type!"=="4" call :CREATE_GITIGNORE java
if "!ignore_type!"=="5" call :CREATE_GITIGNORE cpp
if "!ignore_type!"=="6" call :CREATE_GITIGNORE unity
if "!ignore_type!"=="7" (
    echo 请输入要忽略的规则（每行一条，输入 END 结束）：
    echo.
    if exist ".gitignore" del .gitignore
    :CUSTOM_IGNORE_LOOP
    set /p "ignore_line=  > "
    if /i "!ignore_line!"=="END" (
        echo.
        echo ✓ .gitignore 已生成！
        goto SHOW_IGNORE
    )
    echo !ignore_line!>> .gitignore
    goto CUSTOM_IGNORE_LOOP
)

:SHOW_IGNORE
echo.
echo 生成的 .gitignore 内容：
echo ─────────────────────
type .gitignore
echo.
echo ─────────────────────
echo.
pause
goto MAIN


:: ═══════════════════════════════════════
:: 9. 撤销操作
:: ═══════════════════════════════════════
:UNDO_MENU
cls
echo.
echo ══════════ 撤销操作 ══════════
echo.

if "%IN_REPO%"=="0" (
    echo [错误] 当前目录不是 Git 仓库！
    pause
    goto MAIN
)

echo [警告] 撤销操作可能导致数据丢失，请谨慎操作！
echo.

echo 选择撤销类型：
echo   1. 撤销工作区的修改（未 add 的文件）
echo   2. 撤销暂存区（已 add 未 commit）
echo   3. 撤销最近一次提交（保留修改）
echo   4. 撤销最近一次提交（丢弃修改）
echo   5. 回退到指定提交
echo   6. 返回主菜单
echo.
set /p "undo_choice=请选择 [1-6]："

if "!undo_choice!"=="1" (
    echo.
    echo 将要撤销以下文件的修改：
    git diff --name-only
    echo.
    set /p "undo_confirm=确认撤销？修改将丢失！(yes/no)："
    if /i "!undo_confirm!"=="yes" (
        git checkout -- .
        echo ✓ 工作区修改已撤销！
    )

) else if "!undo_choice!"=="2" (
    echo.
    git reset HEAD .
    echo.
    echo ✓ 暂存区已清空，文件修改保留在工作区

) else if "!undo_choice!"=="3" (
    echo.
    echo 即将撤销的提交：
    git log --oneline -1
    echo.
    set /p "undo_confirm=确认撤销？(y/n)："
    if /i "!undo_confirm!"=="y" (
        git reset --soft HEAD~1
        echo ✓ 提交已撤销，修改保留在暂存区
    )

) else if "!undo_choice!"=="4" (
    echo.
    echo 即将撤销的提交：
    git log --oneline -1
    echo.
    echo [危险] 此操作将丢弃所有修改！
    set /p "undo_confirm=确认撤销？请输入 yes："
    if /i "!undo_confirm!"=="yes" (
        git reset --hard HEAD~1
        echo ✓ 提交已撤销，修改已丢弃！
    )

) else if "!undo_choice!"=="5" (
    echo.
    echo 最近 10 次提交：
    git log --oneline -10
    echo.
    set /p "target_hash=请输入要回退到的提交哈希值："
    if defined target_hash (
        echo.
        echo 选择回退方式：
        echo   1. 保留修改（soft）
        echo   2. 丢弃修改（hard）
        set /p "reset_type=请选择 [1-2]："
        if "!reset_type!"=="1" (
            git reset --soft "!target_hash!"
        ) else if "!reset_type!"=="2" (
            set /p "hard_confirm=确认硬回退？所有修改将丢失！(yes/no)："
            if /i "!hard_confirm!"=="yes" (
                git reset --hard "!target_hash!"
            )
        )
        echo ✓ 已回退！
    )

) else if "!undo_choice!"=="6" (
    goto MAIN
)

echo.
pause
goto UNDO_MENU


:: ═══════════════════════════════════════
:: 生成 .gitignore 子函数
:: ═══════════════════════════════════════
:CREATE_GITIGNORE

set "type=%~1"
if not defined type set "type=general"

:: 通用部分
(
echo # ═══ 系统文件 ═══
echo .DS_Store
echo Thumbs.db
echo Desktop.ini
echo *.swp
echo *.swo
echo *~
echo.
echo # ═══ IDE/编辑器 ═══
echo .idea/
echo .vscode/
echo *.sublime-project
echo *.sublime-workspace
echo *.code-workspace
echo.
echo # ═══ 环境变量 ═══
echo .env
echo .env.local
echo .env.*.local
) > .gitignore

:: 根据类型追加
if /i "%type%"=="node" (
    (
    echo.
    echo # ═══ Node.js ═══
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
    echo .nyc_output/
    ) >> .gitignore
)

if /i "%type%"=="python" (
    (
    echo.
    echo # ═══ Python ═══
    echo __pycache__/
    echo *.py[cod]
    echo *$py.class
    echo *.so
    echo .Python
    echo venv/
    echo env/
    echo .venv/
    echo pip-log.txt
    echo pip-delete-this-directory.txt
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
    echo # ═══ Java ═══
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
    echo # ═══ C/C++ ═══
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
    echo Makefile
    echo *.vcxproj*
    echo .vs/
    echo x64/
    echo Debug/
    echo Release/
    ) >> .gitignore
)

if /i "%type%"=="unity" (
    (
    echo.
    echo # ═══ Unity ═══
    echo [Ll]ibrary/
    echo [Tt]emp/
    echo [Oo]bj/
    echo [Bb]uild/
    echo [Bb]uilds/
    echo [Ll]ogs/
    echo [Uu]ser[Ss]ettings/
    echo MemoryCaptures/
    echo /[Aa]ssets/AssetStoreTools*
    echo .vs/
    echo *.csproj
    echo *.unityproj
    echo *.sln
    echo *.suo
    echo *.user
    echo *.pidb
    echo *.booproj
    echo crashlytics-build.properties
    ) >> .gitignore
)

echo.
echo ✓ .gitignore 已生成！（类型: %type%）

goto :eof


:: ═══════════════════════════════════════
:: 错误处理
:: ═══════════════════════════════════════
:ERR
echo.
echo ╔═══════════════════════════════════════════╗
echo ║  操作失败！请查看上方错误信息             ║
echo ╠═══════════════════════════════════════════╣
echo ║  常见原因：                               ║
echo ║  · 网络连接问题                           ║
echo ║  · GitHub 认证失败                        ║
echo ║  · 远程仓库不存在                         ║
echo ║  · 文件冲突需要手动解决                   ║
echo ║  · 未配置 Git 用户信息                    ║
echo ╚═══════════════════════════════════════════╝
echo.
pause
goto MAIN