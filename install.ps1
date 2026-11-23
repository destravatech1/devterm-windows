<#
  devterm-windows — terminal de desenvolvimento no Windows em um comando.
  Adaptação do devterm (https://github.com/skaisser/devterm, Apache 2.0) para Windows Terminal + WSL2 (Ubuntu).

  Como usar (PowerShell como administrador):
    irm https://raw.githubusercontent.com/destravatech1/devterm-windows/main/install.ps1 | iex
  ou, com a pasta já baixada:
    powershell -ExecutionPolicy Bypass -File .\install.ps1

  Pode rodar de novo quantas vezes quiser: só instala o que falta.
#>
$ErrorActionPreference = 'Continue'   # programas externos (git, winget, wsl) escrevem no stderr sem ser erro
$RepoUrl = 'https://github.com/destravatech1/devterm-windows.git'   # troque pelo seu repositório
$Distro  = 'Ubuntu'
$WtGuid  = '{6d7e2c5a-3b1f-4c8e-9a2d-de0e7e2b0001}'

function Ok($m)   { Write-Host "  OK  $m" -ForegroundColor Green }
function Info($m) { Write-Host "  ->  $m" -ForegroundColor Cyan }
function Falha($m){ Write-Host "  XX  $m" -ForegroundColor Red }

# ── 0. Administrador ───────────────────────────────────────────────────────────
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    if ($PSCommandPath) {
        # Rodando de um arquivo (ex.: depois de reiniciar): pede administrador e continua
        Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`""
    } else {
        Write-Host 'Abra o PowerShell como ADMINISTRADOR (botão direito > Executar como administrador) e rode de novo.' -ForegroundColor Yellow
    }
    return
}

# ── 1. Pasta do projeto (quando roda pelo irm | iex não existe pasta local) ─────
$Root = $PSScriptRoot
if (-not $Root -or -not (Test-Path (Join-Path $Root 'linux\install.sh'))) {
    $Root = Join-Path $HOME 'devterm-windows'
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Info 'Instalando Git para baixar o projeto...'
        winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements --silent | Out-Null
        $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
    }
    if (Test-Path $Root) { git -C $Root pull --ff-only | Out-Null } else { git -c core.autocrlf=false clone $RepoUrl $Root | Out-Null }
}
Write-Host "`ndevterm-windows  (pasta: $Root)`n" -ForegroundColor Magenta

# ── 2. Programas do Windows (winget) ───────────────────────────────────────────
$apps = @(
    @{ id = 'Microsoft.WindowsTerminal'; nome = 'Windows Terminal' },
    @{ id = 'Microsoft.PowerShell';      nome = 'PowerShell 7' },
    @{ id = 'Git.Git';                   nome = 'Git' }
)
foreach ($a in $apps) {
    $lista = winget list -e --id $a.id 2>$null | Out-String
    if ($lista -match [regex]::Escape($a.id)) { Ok "$($a.nome) já instalado"; continue }
    Info "Instalando $($a.nome)..."
    winget install -e --id $a.id --accept-source-agreements --accept-package-agreements --silent | Out-Null
    if ($LASTEXITCODE -eq 0) { Ok $a.nome } else { Falha $a.nome }
}
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')

# ── 3. Fonte com ícones (MesloLGS Nerd Font) ───────────────────────────────────
$temFonte = Get-ChildItem "$env:WINDIR\Fonts" -Filter 'MesloLGS*NerdFontMono*' -ErrorAction SilentlyContinue
if ($temFonte) { Ok 'Fonte MesloLGS Nerd Font já instalada' }
else {
    Info 'Baixando e instalando a fonte MesloLGS Nerd Font...'
    try {
        $tmp = Join-Path $env:TEMP 'devterm-meslo'
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force -Path $tmp | Out-Null
        $zip = Join-Path $tmp 'Meslo.zip'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip' -OutFile $zip -UseBasicParsing
        Expand-Archive $zip -DestinationPath $tmp -Force
        $chave = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        $n = 0
        Get-ChildItem $tmp -Filter 'MesloLGSNerdFontMono-*.ttf' | ForEach-Object {
            Copy-Item $_.FullName (Join-Path "$env:WINDIR\Fonts" $_.Name) -Force
            $nomeFonte = ($_.BaseName -replace 'MesloLGSNerdFontMono-', 'MesloLGS Nerd Font Mono ') + ' (TrueType)'
            Set-ItemProperty -Path $chave -Name $nomeFonte -Value $_.Name
            $n++
        }
        if ($n -gt 0) { Ok "Fonte MesloLGS Nerd Font Mono ($n arquivos)" } else { Falha 'Fonte: nenhum arquivo MesloLGS encontrado no pacote' }
    } catch { Falha "Fonte: $($_.Exception.Message)" }
}

# ── 4. WSL2 + Ubuntu ───────────────────────────────────────────────────────────
$distros = (wsl.exe -l -q 2>$null) -replace "`0", '' | Where-Object { $_.Trim() }
if (-not ($distros -contains $Distro)) {
    Info "Instalando WSL2 + $Distro (pode pedir para reiniciar o computador)..."
    wsl.exe --install -d $Distro --no-launch
    $distros = (wsl.exe -l -q 2>$null) -replace "`0", '' | Where-Object { $_.Trim() }
}
if (-not ($distros -contains $Distro)) {
    # Continua sozinho depois de reiniciar
    $cmd = "powershell -ExecutionPolicy Bypass -NoExit -File `"$Root\install.ps1`""
    Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'devterm-windows' -Value $cmd
    Write-Host "`nREINICIE O COMPUTADOR AGORA (Iniciar > Ligar/Desligar > Reiniciar)." -ForegroundColor Yellow
    Write-Host "Depois de entrar de novo, a instalação continua sozinha: aceite o pedido de administrador que vai aparecer." -ForegroundColor Yellow
    Write-Host "Se não aparecer nada, abra o PowerShell como administrador e rode o mesmo comando de instalação." -ForegroundColor Yellow
    return
}
Ok "WSL2 + $Distro"
Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'devterm-windows' -ErrorAction SilentlyContinue

# Primeiro uso do Ubuntu: criar usuário e senha
$usuario = (wsl.exe -d $Distro -- whoami 2>$null) -replace "`0", ''
if (-not $usuario -or $usuario.Trim() -eq 'root') {
    Write-Host "`nVai abrir o Ubuntu pela primeira vez. Crie um usuário e uma senha (guarde a senha)." -ForegroundColor Yellow
    Write-Host 'Quando aparecer o prompt do Ubuntu, digite  exit  e aperte Enter para voltar aqui.' -ForegroundColor Yellow
    & "$env:LOCALAPPDATA\Microsoft\WindowsApps\ubuntu.exe" 2>$null
    if ($LASTEXITCODE -ne 0) { wsl.exe -d $Distro }
}

# ── 5. Parte Linux: zsh, Oh My Posh, plugins, atalhos, Node, Claude Code ──────
Info 'Configurando o Ubuntu (zsh, prompt, plugins, Node, Claude Code)...'
$caminhoLinux = (wsl.exe -d $Distro -- wslpath -a ($Root -replace '\\','/')) -replace "`0", ''
wsl.exe -d $Distro -- bash -lc "sed -i 's/\r$//' '$caminhoLinux/linux/install.sh' '$caminhoLinux/assets/zshrc.wsl' '$caminhoLinux/assets/statusline.sh' 2>/dev/null; bash '$caminhoLinux/linux/install.sh'"

# ── 6. Windows Terminal: cores skaisser, fonte e perfil padrão ─────────────────
$scheme = Get-Content (Join-Path $Root 'assets\skaisser.wt-scheme.json') -Raw | ConvertFrom-Json
$fragDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\devterm'
New-Item -ItemType Directory -Force -Path $fragDir | Out-Null
$fragment = [ordered]@{
    schemes  = @($scheme)
    profiles = @([ordered]@{
        guid              = $WtGuid
        name              = 'devterm (Ubuntu)'
        commandline       = "wsl.exe -d $Distro --cd ~"
        icon              = 'ms-appx:///ProfileIcons/{9acb9455-ca41-5af7-950f-6bca1bc9722f}.png'
        colorScheme       = 'skaisser'
        font              = @{ face = 'MesloLGS Nerd Font Mono'; size = 13 }
        cursorShape       = 'bar'
        historySize       = 32767
        padding           = '8'
        antialiasingMode  = 'cleartype'
    })
}
$fragment | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $fragDir 'devterm.json')
Ok 'Perfil "devterm (Ubuntu)" com as cores skaisser'

# Perfil padrão (só troca a linha defaultProfile; o resto do settings.json fica igual)
$wtSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (-not (Test-Path $wtSettings)) {
    Start-Process wt.exe; Start-Sleep -Seconds 6
    Get-Process WindowsTerminal -ErrorAction SilentlyContinue | Stop-Process -Force
}
if (Test-Path $wtSettings) {
    Copy-Item $wtSettings "$wtSettings.backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
    $txt = Get-Content $wtSettings -Raw
    if ($txt -match '"defaultProfile"\s*:\s*"[^"]*"') {
        $txt = $txt -replace '"defaultProfile"\s*:\s*"[^"]*"', ('"defaultProfile": "' + $WtGuid + '"')
        Set-Content -Encoding UTF8 $wtSettings $txt
        Ok 'devterm (Ubuntu) é o perfil padrão do Windows Terminal'
    } else { Info 'Não achei "defaultProfile": escolha o perfil "devterm (Ubuntu)" em Configurações > Inicialização.' }
} else { Info 'Abra o Windows Terminal uma vez e rode este instalador de novo para definir o perfil padrão.' }

Write-Host "`nPronto! Abra o Windows Terminal: o perfil 'devterm (Ubuntu)' já abre com zsh, prompt e cores." -ForegroundColor Green
Write-Host "Para usar o Claude Code: digite  claude  dentro do Ubuntu.`n" -ForegroundColor Green
