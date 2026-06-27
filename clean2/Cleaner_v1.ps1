# ============================================
# Cleaner GUI — Nettoyage complet FR
# Auteur : ps81frt | MIT License | 2026
# GitHub : https://github.com/ps81frt/cleaner
# ============================================

# ---------------------------------------------------------------------------
# UAC
# ---------------------------------------------------------------------------
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $startArgs = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    try {
        Start-Process "powershell.exe" -ArgumentList $startArgs -Verb RunAs -ErrorAction Stop
    } catch { }
    exit 
}

# ----------------------------
# Variables / Config
# ----------------------------
$AppVersion     = "2.0.2"
$AppTitle       = "Cleaner"
$AppSubtitle    = "Optimisation Systeme par ps81frt"
$AppWidth       = 540
$AppHeight      = 680

# Chemins a nettoyer
$PathTempUser   = "$env:TEMP\*"
$PathTempSys    = "C:\Windows\Temp\*"
$PathPrefetch   = "C:\Windows\Prefetch\*"
$PathWinLogs    = "C:\Windows\*.log"
$PathRecent     = "$env:APPDATA\Microsoft\Windows\Recent\*"
$PathWER        = "$env:LOCALAPPDATA\Microsoft\Windows\WER\*"
$PathD3D        = "$env:LOCALAPPDATA\D3DSCache\*"
$PathIconLegacy = "$env:LOCALAPPDATA\IconCache.db"
$PathIconCache  = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*"
$PathDeliveryOpt = "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*"
$PathSysWER     = "C:\ProgramData\Microsoft\Windows\WER\*"
$PathCBS        = "C:\Windows\Logs\CBS\*"
$PathPanther    = "C:\Windows\Panther\*"
$PathMoSetup    = "C:\Windows\Logs\MoSetup\*"
$PathSetupApi   = "C:\Windows\inf\setupapi.offline.log"
$PathBranchCache = "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\BranchCache\*"
$PathEdgeCache  = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*"
$PathChromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*"
$PathFirefoxCache = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*"
$PathBraveCache  = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache\*"
$PathVivaldiCache = "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Cache\*"
$PathThumbCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*"
$PathSoftDist   = "C:\Windows\SoftwareDistribution\*"
$PathCatRoot    = "C:\Windows\System32\catroot2\*"
$PathFontCache  = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*"
$PathFntDat     = "C:\Windows\System32\FNTCACHE.DAT"
$PathSysTempLocal = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Temp\*"
$PathSysTempNet  = "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Temp\*"
$PathMemoryDump  = "C:\Windows\MEMORY.DMP"
$PathMinidumps   = "C:\Windows\Minidump\*"

# Cles registre UserAssist / BAM / DAM
$RegUserAssist  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
$RegMuiCache    = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
$RegBAM         = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
$RegDAM         = "HKLM:\SYSTEM\CurrentControlSet\Services\dam\State\UserSettings"

# Journaux evenements a vider
$EventLogs      = @("Application", "System")

# Variables GUI (initialisees apres chargement XAML)
$window        = $null
$logBox        = $null
$progress      = $null
$progressCalc  = $null
$btnStart      = $null
$btnCalc       = $null
$btnQuit       = $null
$btnAbout      = $null
$btnHelp       = $null
$scroll        = $null
$chkUserAssist = $null
$chkEventLogs  = $null
$chkWinSxS     = $null
$chkDumps      = $null
$chkFontCache  = $null
$chkSFC        = $null
$chkBrowsers    = $null
$chkVerbose    = $null
$txtFinal      = $null

# Global variables for runspace management
$global:activePowerShell = $null
$global:activeRunspace = $null
$global:activeAsyncResult = $null

# Hashtable synchronisee (initialisee apres liaison GUI)
$sync          = $null

# ----------------------------
# Elevation Admin
# ----------------------------
# ----------------------------
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ----------------------------
# XAML GUI
# ----------------------------
[xml]$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        Title='$AppTitle' Height='$AppHeight' Width='$AppWidth'
        WindowStartupLocation='CenterScreen'
        ResizeMode='NoResize'
        Background='#1e1e2e'>
    <Window.Resources>
        <Style TargetType='Button'>
            <Setter Property='Template'>
                <Setter.Value>
                    <ControlTemplate TargetType='Button'>
                        <Border Name='border' Background='{TemplateBinding Background}' CornerRadius='5'>
                            <ContentPresenter HorizontalAlignment='Center' VerticalAlignment='Center'/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property='IsMouseOver' Value='True'>
                                <Setter TargetName='border' Property='Opacity' Value='0.8'/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid Margin='20'>
        <Grid.RowDefinitions>
            <RowDefinition Height='50'/>
            <RowDefinition Height='20'/>
            <RowDefinition Height='*'/>
            <RowDefinition Height='230'/>
            <RowDefinition Height='16'/> <!-- Progress Calc -->
            <RowDefinition Height='16'/> <!-- Progress Clean -->
            <RowDefinition Height='80'/>
            <RowDefinition Height='50'/>
        </Grid.RowDefinitions>

        <Grid Grid.Row='0' Margin='0,5,0,0'>
            <TextBlock Text='v$AppVersion' IsHitTestVisible='False' FontSize='10' Foreground='#6c7086' HorizontalAlignment='Left' VerticalAlignment='Top' Margin='5,0,0,0'/>
            <TextBlock Text='CLEANER' IsHitTestVisible='False' FontSize='28' FontWeight='Bold' Foreground='#89b4fa' HorizontalAlignment='Center' VerticalAlignment='Center'/>
            <StackPanel Orientation='Horizontal' HorizontalAlignment='Right' VerticalAlignment='Top'>
                <Button Name='BtnHelp' Content='❔' Width='24' Height='24' Background='#01000000' Foreground='#fab387' BorderThickness='0' FontSize='14' Cursor='Hand' ToolTip='Aide technique' Margin='0,0,8,0'/>
                <Button Name='BtnAbout' Content='ⓘ' Width='24' Height='24' Background='#01000000' Foreground='#89b4fa' BorderThickness='0' FontSize='16' Cursor='Hand' ToolTip='A Propos'/>
            </StackPanel>
        </Grid>
        <TextBlock Grid.Row='1' Text='$AppSubtitle' IsHitTestVisible='False' FontSize='12' Foreground='#6c7086' VerticalAlignment='Center' HorizontalAlignment='Center'/>
        <Border Grid.Row='2' Background='#181825' CornerRadius='6' Padding='10'>
            <ScrollViewer Name='Scroll' VerticalScrollBarVisibility='Auto'>
                <TextBox Name='Log' Background='Transparent' Foreground='#a6e3a1' FontFamily='Consolas' FontSize='12' BorderThickness='0' IsReadOnly='True' TextWrapping='Wrap' AcceptsReturn='True'/>
            </ScrollViewer>
        </Border>
        <StackPanel Grid.Row='3' Margin='4,10,4,4'>
            <CheckBox Name='ChkBrowsers' Content='Caches Navigateurs (Edge/Chrome/FF/Brave/Vivaldi)' ToolTip='Ferme les navigateurs et supprime les fichiers temporaires, caches de code et caches GPU pour tous les navigateurs installes.' Foreground='#89b4fa' FontSize='13' Margin='0,0,0,4' IsChecked='False'/>
            <CheckBox Name='ChkEventLogs' Content='Vider les journaux evenements (Application / System)' ToolTip='Supprime les logs Application et System de Windows.' Foreground='#fab387' FontSize='13' IsChecked='False'/>
            <CheckBox Name='ChkDumps' Content='Supprimer les rapports de crash (Dumps memoire)' ToolTip='ATTENTION : Supprime MEMORY.DMP et les Minidumps.' Foreground='#f9e2af' FontSize='13' Margin='0,4,0,0' IsChecked='False'/>
            <CheckBox Name='ChkFullLogs' Content='Logs : Nettoyage TOTAL (Decoche = > 30 jours)' ToolTip='Active : Purge complete. Desactive : Garde les 30 derniers jours.' Foreground='#94e2d5' FontSize='13' Margin='0,4,0,0' IsChecked='True'/>
            <CheckBox Name='ChkFontCache' Content='Nettoyer le cache des polices Windows' ToolTip='Reinitialise le cache des polices (Windows et WPF).' Foreground='#fab387' FontSize='13' Margin='0,4,0,0' IsChecked='False'/>
            <CheckBox Name='ChkUserAssist' Content='Nettoyer UserAssist / MuiCache / BAM / DAM' ToolTip='Reinitialise l historique de lancement, la MuiCache et les caches Shell.' Foreground='#a6e3a1' FontSize='13' Margin='0,4,0,0' IsChecked='False'/>
            <CheckBox Name='ChkWinSxS' Content='Nettoyage approfondi WinSxS (Long / Definitif)' ToolTip='Compresse et supprime les anciennes versions des composants Windows Update via DISM.' Foreground='#f38ba8' FontSize='13' Margin='0,4,0,0' IsChecked='False'/>
            <CheckBox Name='ChkSFC' Content='Lancer SFC /scannow apres WinSxS' ToolTip='Execute une verification complete de l integrite systeme.' Foreground='#cba6f7' FontSize='13' Margin='0,4,0,0' IsChecked='False'/>
            <CheckBox Name='ChkVerbose' Content='Affichage detaille (Ralentit le processus)' ToolTip='Affiche chaque fichier supprime dans le log en temps reel.' Foreground='#9399b2' FontSize='11' Margin='0,6,0,0' IsChecked='False'/>
            <CheckBox Name='ChkRegistry' Content='Nettoyer les traces HKCU (MRU / RecentDocs / ComDlg)' ToolTip='Purge HKCU uniquement : historique Executer, barre adresse Explorer, fichiers recents Shell, boites de dialogue Ouvrir/Enregistrer. Scope utilisateur — aucun risque systeme.' Foreground='#cba6f7' FontSize='13' Margin='0,4,0,0' IsChecked='False'/>
        </StackPanel>

        <ProgressBar Grid.Row='4' Name='ProgressCalc' Minimum='0' Maximum='100' Height='4' Margin='0,4,0,0' Background='#313244' Foreground='#fab387' Visibility='Hidden'/>
        <ProgressBar Grid.Row='5' Name='Progress' Minimum='0' Maximum='100' Height='6' Margin='0,6,0,0' Background='#313244' Foreground='#89b4fa'/>
        <WrapPanel Grid.Row='6' HorizontalAlignment='Center' VerticalAlignment='Center'>
            <Button Name='BtnCalc' Content='ESTIMER' Height='36' Width='100' Margin='4,5' Background='#fab387' Foreground='#1e1e2e' FontWeight='Bold' FontSize='12' BorderThickness='0' Cursor='Hand' ToolTip='Calcule l espace liberable sans rien supprimer.'/>
            <Button Name='BtnStart' Content='Lancer le nettoyage' Height='36' Width='155' Margin='4,5' Background='#89b4fa' Foreground='#1e1e2e' FontWeight='Bold' FontSize='12' BorderThickness='0' Cursor='Hand' ToolTip='Execute toutes les purges cochees.'/>
            <Button Name='BtnRegistry' Content='REGISTRE' Height='36' Width='100' Margin='4,5' Background='#cba6f7' Foreground='#1e1e2e' FontWeight='Bold' FontSize='12' BorderThickness='0' Cursor='Hand' ToolTip='Nettoie les traces HKCU (MRU, RecentDocs, ComDlg). Scope utilisateur uniquement, aucun risque systeme.'/>
            <Button Name='BtnQuit' Content='Quitter' Height='36' Width='75' Margin='4,5' Background='#ff5555' Foreground='#ffffff' FontWeight='Bold' FontSize='12' BorderThickness='0' Cursor='Hand'/>
        </WrapPanel>
        <TextBlock Grid.Row='7' Name='TxtFinal' Text='' Foreground='#a6e3a1' FontSize='22' FontWeight='Bold' HorizontalAlignment='Center' VerticalAlignment='Center' Visibility='Collapsed'/>
    </Grid>
</Window>
"@

# ----------------------------
# Liaison GUI
# ----------------------------
$reader        = [System.Xml.XmlNodeReader]::new($xaml)
$window        = [Windows.Markup.XamlReader]::Load($reader)
$logBox        = $window.FindName("Log")
$progress      = $window.FindName("Progress")
$progressCalc  = $window.FindName("ProgressCalc")
$btnStart      = $window.FindName("BtnStart")
$btnCalc       = $window.FindName("BtnCalc")
$btnQuit       = $window.FindName("BtnQuit")
$btnAbout      = $window.FindName("BtnAbout")
$btnHelp       = $window.FindName("BtnHelp")
$scroll        = $window.FindName("Scroll")
$chkUserAssist = $window.FindName("ChkUserAssist")
$chkEventLogs  = $window.FindName("ChkEventLogs")
$chkWinSxS     = $window.FindName("ChkWinSxS")
$chkBrowsers    = $window.FindName("ChkBrowsers")
$chkDumps      = $window.FindName("ChkDumps")
$chkFullLogs   = $window.FindName("ChkFullLogs")
$chkFontCache  = $window.FindName("ChkFontCache")
$chkSFC        = $window.FindName("ChkSFC")
$chkVerbose    = $window.FindName("ChkVerbose")
$btnRegistry   = $window.FindName("BtnRegistry")
$txtFinal      = $window.FindName("TxtFinal")

# ----------------------------
# Runspace Monitor (DispatcherTimer)
# ----------------------------
$global:runspaceMonitorTimer = New-Object System.Windows.Threading.DispatcherTimer
$global:runspaceMonitorTimer.Interval = New-Object TimeSpan -ArgumentList 0,0,0,0,100 # 100ms interval
$global:runspaceMonitorTimer.Add_Tick({
    if ($global:activeAsyncResult -and $global:activeAsyncResult.IsCompleted) {
        $global:runspaceMonitorTimer.Stop()
        try {
            $global:activePowerShell.EndInvoke($global:activeAsyncResult)
        } catch {
            $sync.Log.AppendText("[!] Erreur lors de la finalisation du runspace: $($_.Exception.Message)`n")
        } finally {
            $global:activePowerShell.Dispose()
            $global:activeRunspace.Dispose()
            $global:activePowerShell = $null
            $global:activeRunspace = $null
            $global:activeAsyncResult = $null
        }
    }
})

# ----------------------------
# Hashtable synchronisee (UI <-> Runspace)
# ----------------------------
$sync = [hashtable]::Synchronized(@{
    Log            = $logBox
    Progress       = $progress
    ProgressCalc   = $progressCalc
    Scroll         = $scroll
    TxtFinal       = $txtFinal
    BtnStart       = $btnStart
    Window         = $window
    chkDumps       = $chkDumps
    chkFontCache   = $chkFontCache
    chkUserAssist  = $chkUserAssist
    BtnRegistry    = $btnRegistry
    Stop           = $false
    CleanUserAssist= $false
    CleanEventLogs = $false
    CleanWinSxS    = $false
    CleanBrowsers  = $false
    CleanDumps     = $false
    CleanFontCache = $false
    FullLogs       = $false
    RunSFC         = $false
    VerboseMode    = $false
    TotalFreed     = 0
    PathTempUser   = $PathTempUser
    PathTempSys    = $PathTempSys
    PathPrefetch   = $PathPrefetch
    PathWinLogs    = $PathWinLogs
    PathPanther    = $PathPanther
    PathMoSetup    = $PathMoSetup
    PathSetupApi   = $PathSetupApi
    PathCBS        = $PathCBS
    PathBranchCache = $PathBranchCache
    PathEdgeCache  = $PathEdgeCache
    PathChromeCache = $PathChromeCache
    PathFirefoxCache = $PathFirefoxCache
    PathBraveCache  = $PathBraveCache
    PathVivaldiCache = $PathVivaldiCache
    PathRecent     = $PathRecent
    PathSysTempLocal = $PathSysTempLocal
    PathSysTempNet  = $PathSysTempNet
    PathWER        = $PathWER
    PathD3D        = $PathD3D
    PathIconCache  = $PathIconCache
    PathIconLegacy = $PathIconLegacy
    PathThumbCache = $PathThumbCache
    PathDeliveryOpt = $PathDeliveryOpt
    PathSysWER     = $PathSysWER
    PathSoftDist   = $PathSoftDist
    PathCatRoot    = $PathCatRoot
    PathFontCache  = $PathFontCache
    PathFntDat     = $PathFntDat
    PathMemoryDump  = $PathMemoryDump
    PathMinidumps   = $PathMinidumps
    RegUserAssist  = $RegUserAssist
    RegMuiCache    = $RegMuiCache
    RegBAM         = $RegBAM
    RegDAM         = $RegDAM
    EventLogs      = $EventLogs
})

# ----------------------------
# Script de nettoyage (Runspace)
# ----------------------------
$cleanScript = {
    param($sync)

    $reportLog = New-Object System.Collections.Generic.List[string]
    $reportLog.Add("=== RAPPORT DE NETTOYAGE CLEANER - $(Get-Date) ===")
    $reportLog.Add("Version: $($sync.AppVersion)")
    $reportLog.Add("-" * 50)

    # ----------------------------
    # Fonctions utilitaires
    # ----------------------------
    function Write-Log($msg) {
        $reportLog.Add($msg)
        $sync.Window.Dispatcher.Invoke([Action]{
            if ($sync.Log.LineCount -gt 1000) { $sync.Log.Clear() }
            $sync.Log.AppendText("$msg`n")
            $sync.Scroll.ScrollToEnd()
        })
    }


    function Set-Prog($val) {
        $sync.Window.Dispatcher.Invoke([action]{
            $sync.Progress.Value = $val
        })
    }

function Remove-VerboseModern($path, $days = $null) {
    if ($sync.Stop) { return }
    $limitDate = if ($days) { (Get-Date).AddDays(-$days) } else { $null }

    try {
        $resolvedPaths = Resolve-Path $path -ErrorAction SilentlyContinue
        if (-not $resolvedPaths) { return }

        foreach ($r in $resolvedPaths) {
            if ($sync.Stop) { return }
            if ([System.IO.File]::Exists($r.Path)) {
                if ($r.Path -like "*layout.ini") { continue }
                try {
                    $fInfo = [System.IO.FileInfo]::new($r.Path)
                    if ($limitDate -and $fInfo.LastWriteTime -gt $limitDate) { continue }
                    $size = $fInfo.Length
                    [System.IO.File]::Delete($r.Path)
                    $sync.TotalFreed += $size
                    if ($sync.VerboseMode) { Write-Log "   -> Supprime : $([System.IO.Path]::GetFileName($r.Path))" }
                } catch { }
                continue
            }
            if (-not [System.IO.Directory]::Exists($r.Path)) { continue }

            foreach ($file in [System.IO.Directory]::EnumerateFiles($r.Path, "*", [System.IO.SearchOption]::AllDirectories)) {
                if ($sync.Stop) { return }
                if ($file -like "*layout.ini") { continue }
                try {
                    $fInfo = [System.IO.FileInfo]::new($file)
                    if ($limitDate -and $fInfo.LastWriteTime -gt $limitDate) { continue }
                    $size = $fInfo.Length
                    [System.IO.File]::Delete($file)
                    $sync.TotalFreed += $size
                    if ($sync.VerboseMode) { Write-Log "   -> Supprime : $([System.IO.Path]::GetFileName($file))" }
                } catch { }
            }
        }
    } catch { Write-Log "[!] Erreur critique lors du traitement de : $path" }
}

    function Start-CleanMgrStopable {
        if ($sync.Stop) { return }
        $proc = Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -PassThru
        while (-not $proc.HasExited) {
            Start-Sleep -Milliseconds 300
            if ($sync.Stop) {
                $proc.Kill()
                return
            }
        }
    }

    # ----------------------------
    # Nettoyage UserAssist / BAM / DAM + cache icones
    # (Explorer arrete une seule fois pour les deux)
    # ----------------------------
    if ($sync.CleanUserAssist) {
        Write-Log "[+] Arret Explorer pour nettoyage..."
        try {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Write-Log "   -> Explorer arrete"
            Start-Sleep -Seconds 3
            
            Remove-Item $sync.RegUserAssist -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item $sync.RegMuiCache   -Recurse -Force -ErrorAction SilentlyContinue
            
            Remove-Item $sync.RegBAM -Recurse -Force -ErrorAction SilentlyContinue
            New-Item $sync.RegBAM -Force -ErrorAction SilentlyContinue | Out-Null
            Remove-Item $sync.RegDAM -Recurse -Force -ErrorAction SilentlyContinue
            New-Item $sync.RegDAM -Force -ErrorAction SilentlyContinue | Out-Null
            
            Write-Log "[+] Nettoyage cache icones et miniatures..."
            Remove-VerboseModern $sync.PathIconCache
            Remove-VerboseModern $sync.PathIconLegacy
            Remove-VerboseModern $sync.PathThumbCache
            Start-Sleep -Milliseconds 800
            
            Write-Log "[!] NOTE : Un redemarrage est requis pour finaliser le reset BAM/DAM."
        } finally {
            Start-Process explorer
            Write-Log "   -> Explorer relance"
        }
    } else {
        Write-Log "[i] UserAssist / BAM / DAM + cache icones ignores"
    }
    Set-Prog 10

    # ----------------------------
    # Nettoyage Temp et Prefetch
    # ----------------------------
    $ParallelPaths = @(
        $sync.PathTempUser,
        $sync.PathTempSys,
        $sync.PathPrefetch,
        $sync.PathWinLogs,
        $sync.PathRecent,
        $sync.PathCBS,
        $sync.PathPanther,
        $sync.PathMoSetup,
        $sync.PathSetupApi,
        $sync.PathBranchCache,
        $sync.PathSysTempLocal,
        $sync.PathSysTempNet,
        $sync.PathWER,
        $sync.PathSysWER,
        $sync.PathDeliveryOpt,
        $sync.PathD3D
    )

    Write-Log "[!] Lancement du nettoyage des caches systeme..."
    foreach ($path in $ParallelPaths) {
        if ($sync.Stop) { break }
        $days = $null
        if (-not $sync.FullLogs -and ($path -eq $sync.PathWinLogs -or $path -eq $sync.PathCBS -or $path -eq $sync.PathMoSetup)) {
            $days = 30
        }
        Remove-VerboseModern $path $days
    }
    if ($sync.CleanBrowsers -and -not $sync.Stop) {
        Write-Log "[!] Fermeture des navigateurs pour liberation des verrous..."
        $browserProcs = @("chrome", "msedge", "firefox", "brave", "vivaldi")
        foreach ($procName in $browserProcs) {
            if (Get-Process $procName -ErrorAction SilentlyContinue) {
                Stop-Process -Name $procName -Force -ErrorAction SilentlyContinue
                Write-Log "   -> $procName ferme"
            }
        }
        Write-Log "[+] Nettoyage caches Navigateurs..."
        Remove-VerboseModern $sync.PathEdgeCache
        Remove-VerboseModern $sync.PathChromeCache
        Remove-VerboseModern $sync.PathFirefoxCache
        Remove-VerboseModern $sync.PathBraveCache
        Remove-VerboseModern $sync.PathVivaldiCache
    }
    if ($sync.CleanFontCache -and -not $sync.Stop) {
        Write-Log "[+] Nettoyage du cache des polices Windows..."
        $fontServices = @("FontCache", "FontCache3.0.0.0")
        foreach ($svc in $fontServices) { Stop-Service $svc -Force -ErrorAction SilentlyContinue }
        Start-Sleep -Seconds 1
        Remove-VerboseModern $sync.PathFontCache
        Remove-VerboseModern $sync.PathFntDat
        foreach ($svc in $fontServices) { Start-Service $svc -ErrorAction SilentlyContinue }
        Write-Log "   -> Cache polices purge"
    }
    if ($sync.CleanDumps -and -not $sync.Stop) {
        Write-Log "[+] Nettoyage des rapports de crash (Dumps)..."
        Remove-VerboseModern $sync.PathMemoryDump
        Remove-VerboseModern $sync.PathMinidumps
    }
    Set-Prog 50

    # ----------------------------
    # Vidage cache DNS et ARP
    # ----------------------------
    if (-not $sync.Stop) {
        Write-Log "[+] Vidage des caches reseau (DNS/ARP)..."
        ipconfig /flushdns | Out-Null
        arp -d * 2>&1 | Out-Null
        Write-Log "   -> Caches reseau purges"
    }
    Set-Prog 60

    # ----------------------------
    # Nettoyage Windows Update (SoftwareDistribution)
    # ----------------------------
    if (-not $sync.Stop) {
        Write-Log "[+] Nettoyage Windows Update (SoftwareDist & Catroot2)..."
        $services = @("wuauserv", "bits", "cryptsvc", "msiserver")
        foreach ($svc in $services) { 
            Stop-Service $svc -Force -ErrorAction SilentlyContinue 
        }
        # Latence nécessaire pour libérer les handles fichiers
        Start-Sleep -Seconds 2
        Remove-VerboseModern $sync.PathSoftDist
        Remove-VerboseModern $sync.PathCatRoot

        foreach ($svc in $services) { 
            Start-Service $svc -ErrorAction SilentlyContinue 
        }
        Write-Log "   -> Services de maintenance relances"
    }
    Set-Prog 75

    # ----------------------------
    # Nettoyage journaux d'evenements
    # ----------------------------
    if ($sync.CleanEventLogs) {
        Write-Log "[+] Suppression journaux d evenements..."
        $logsToClear = $sync.EventLogs # Correction : Utilise la variable d'instance
        foreach ($log in $logsToClear) {
            wevtutil cl $log 2>&1 | Out-Null
            Write-Log "   -> $log vide"
        }
    } else {
        Write-Log "[i] Journaux d evenements ignores"
    }
    Set-Prog 78

    # ----------------------------
    # Nettoyage cache Windows Store
    # ----------------------------
    if ($sync.CleanWinSxS -and -not $sync.Stop) { # Seulement si nettoyage profond demande
        Write-Log "[+] Nettoyage cache Windows Store (wsreset)..."
        Start-Process wsreset.exe -WindowStyle Hidden
        Write-Log "   -> wsreset lance en arriere-plan"
    }
    Set-Prog 83

    # ----------------------------
    # Nettoyage WinSxS (Pro)
    # ----------------------------
    if ($sync.CleanWinSxS -and -not $sync.Stop) {
        Write-Log "[+] Nettoyage WinSxS (Composants obsoletes + ResetBase)..."
        Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase /NoRestart | Out-Null
        
        if ($sync.RunSFC -and -not $sync.Stop) {
            Write-Log "[+] Verification de l integrite systeme (SFC /scannow)..."
            sfc /scannow | Out-Null
            Write-Log "   -> SFC termine"
        }
    } else {
        Write-Log "[i] Nettoyage WinSxS ignore"
    }

    # ----------------------------
    # Vidage corbeille
    # ----------------------------
    if (-not $sync.Stop) {
        Write-Log "[+] Vidage corbeille..."
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Log "   -> Corbeille videe"
    }
    Set-Prog 88

    # ----------------------------
    # Lancement CleanMgr
    # ----------------------------
    if ($sync.CleanWinSxS -and -not $sync.Stop) { # Seulement si nettoyage profond demande
        Write-Log "[+] Lancement CleanMgr..."
        Start-CleanMgrStopable
    }
    Set-Prog 100

    if ($sync.CleanWinSxS) {
    Write-Log "[*] Nettoyage approfondi du magasin de composants (ResetBase)..."
    & dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase /NoRestart
    }
    # ----------------------------
    # Generation du rapport sur le bureau
    # ----------------------------
    try {
        $desktopPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "cleaner_$(Get-Date -Format 'yyyyMMdd_HHmm').log")
        $reportLog | Out-File -FilePath $desktopPath -Encoding utf8
        $reportLog.Clear()
        Write-Log "[i] Rapport complet enregistre sur le bureau : $(Split-Path $desktopPath -Leaf)"
    } catch { Write-Log "[!] Impossible de generer le rapport sur le bureau." }


    # ----------------------------
    # Fin
    # ----------------------------
    $sync.Window.Dispatcher.Invoke([action]{
        if (-not $sync.Stop) {
            $bytes = $sync.TotalFreed
            $displayText = ""
            if ($bytes -gt 1GB) { $displayText = "$([math]::Round($bytes / 1GB, 2)) GB" }
            elseif ($bytes -gt 1MB) { $displayText = "$([math]::Round($bytes / 1MB, 1)) MB" }
            else { $displayText = "$([math]::Round($bytes / 1KB, 0)) KB" }

            $sync.TxtFinal.Text = "LIBERE : $displayText"
            $sync.TxtFinal.Visibility = 'Visible'
            $sync.Log.AppendText("[+] Nettoyage termine ! Taille totale liberee : $displayText`n")
            $sync.Scroll.ScrollToEnd()
        }
        $sync.BtnStart.IsEnabled = $true
    })
}

# ----------------------------
# Evenement Bouton Calcul
# ----------------------------
$btnCalc.Add_Click({
    $logBox.Text = "Analyse de l espace en cours...`n"
    
    if ($global:activePowerShell) {
        try { $global:activePowerShell.Stop() } catch {}
        $global:activePowerShell.Dispose()
        $global:activeRunspace.Dispose()
        $global:activePowerShell = $null
        $global:activeRunspace = $null
        $global:activeAsyncResult = $null
        $global:runspaceMonitorTimer.Stop()
    }

    $btnCalc.IsEnabled = $false
    $btnStart.IsEnabled = $false
    $progressCalc.Visibility = 'Visible'
    $progressCalc.Value = 0
    
    $calcScript = {
        param($sync)
        $total = [long]0
        
        function Get-Size-Robust($p, $days = $null) {
            $s = [long]0
            $limitDate = if ($days) { (Get-Date).AddDays(-$days) } else { $null }
            try {
                $resolved = Resolve-Path $p -ErrorAction SilentlyContinue
                if (-not $resolved) { return 0 }
                
                foreach ($r in $resolved) {
                    if ([System.IO.Directory]::Exists($r.Path)) {
                        # Optimisation RAM : EnumerateFiles ne charge pas la collection complete en mémoire
                        foreach ($file in [System.IO.Directory]::EnumerateFiles($r.Path, "*", [System.IO.SearchOption]::AllDirectories)) {
                            $fInfo = [System.IO.FileInfo]::new($file)
                            if ($limitDate -and $fInfo.LastWriteTime -gt $limitDate) { continue }
                            $s += $fInfo.Length
                        }
                    } elseif ([System.IO.File]::Exists($r.Path)) {
                        $fInfo = [System.IO.FileInfo]::new($r.Path)
                        if ($limitDate -and $fInfo.LastWriteTime -gt $limitDate) { continue }
                        $s += $fInfo.Length
                    }
                }
            } catch {}
            return $s
        }

        # Synchronisation avec la liste reelle du nettoyage
        $paths = @(
            $sync.PathTempUser, $sync.PathTempSys, $sync.PathPrefetch, $sync.PathWinLogs,
            $sync.PathRecent, $sync.PathCBS, $sync.PathPanther, $sync.PathMoSetup,
            $sync.PathSetupApi, $sync.PathBranchCache, $sync.PathSysTempLocal, $sync.PathSysTempNet,
            $sync.PathWER, $sync.PathSysWER, $sync.PathDeliveryOpt, $sync.PathD3D,
            $sync.PathSoftDist, $sync.PathCatRoot, $sync.PathFontCache, $sync.PathFntDat,
            $sync.PathIconCache, $sync.PathIconLegacy, $sync.PathThumbCache
        )
        if ($sync.CleanBrowsers) { $paths += @($sync.PathEdgeCache, $sync.PathChromeCache, $sync.PathFirefoxCache, $sync.PathBraveCache, $sync.PathVivaldiCache) }
        if ($sync.CleanDumps) { $paths += @($sync.PathMemoryDump, $sync.PathMinidumps) }

        $step = 0
        foreach ($p in $paths) {
            $step++
            $days = $null
            if (-not $sync.FullLogs -and ($p -eq $sync.PathWinLogs -or $p -eq $sync.PathCBS -or $p -eq $sync.PathMoSetup)) {
                $days = 30
            }
            $size = Get-Size-Robust $p $days
            $total += $size
            $sync.Window.Dispatcher.Invoke([Action]{
                $cleanPath = $p.Replace('*','')
                if ($cleanPath.Length -gt 40) { $cleanPath = "..." + $cleanPath.Substring($cleanPath.Length - 37) }
                $sync.Log.AppendText("   [+] $cleanPath : $([math]::Round($size/1MB, 2)) MB`n")
                $sync.Scroll.ScrollToEnd()
                $sync.ProgressCalc.Value = ($step / $paths.Count) * 100
            })
        }

        $sync.Window.Dispatcher.Invoke([Action]{
            $formatted = if ($total -gt 1GB) { "$([math]::Round($total/1GB, 2)) GB" } else { "$([math]::Round($total/1MB, 1)) MB" }
            $sync.Log.AppendText("`nEstimation totale : $formatted`n")
            $sync.BtnStart.IsEnabled = $true
            $sync.BtnCalc.IsEnabled = $true
            $sync.ProgressCalc.Visibility = 'Hidden'
        })
    }

    $sync.CleanBrowsers = [bool]$chkBrowsers.IsChecked
    $sync.CleanDumps    = [bool]$chkDumps.IsChecked
    $sync.FullLogs      = [bool]$chkFullLogs.IsChecked
    $sync.BtnCalc       = $btnCalc

    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions  = "ReuseThread"
    $rs.Open()

    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript($calcScript).AddArgument($sync) | Out-Null

    $global:activePowerShell = $ps
    $global:activeRunspace = $rs
    $global:activeAsyncResult = $ps.BeginInvoke()

    $global:runspaceMonitorTimer.Start()
})

# ----------------------------
# Script d'initialisation (Background au chargement)
# ----------------------------
$initScript = {
    param($sync)

    function Get-Size-Fast($path) {
        $size = [long]0
        try {
            $resolved = Resolve-Path $path -ErrorAction SilentlyContinue
            if (-not $resolved) { return 0 }
            foreach ($r in $resolved) {
                if ([System.IO.Directory]::Exists($r.Path)) {
                    foreach ($file in [System.IO.Directory]::EnumerateFiles($r.Path, "*", [System.IO.SearchOption]::AllDirectories)) {
                        $size += [System.IO.FileInfo]::new($file).Length
                    }
                } elseif ([System.IO.File]::Exists($r.Path)) {
                    $size += [System.IO.FileInfo]::new($r.Path).Length
                }
            }
        } catch {}
        return $size
    }

    function Format-Size($bytes) {
        if ($bytes -eq 0) { return "0 KB" }
        if ($bytes -gt 1GB) { return "$([math]::Round($bytes / 1GB, 2)) GB" }
        if ($bytes -gt 1MB) { return "$([math]::Round($bytes / 1MB, 1)) MB" }
        return "$([math]::Round($bytes / 1KB, 0)) KB"
    }

    # 1. Calculs des tailles (Dumps, Fonts, Icons)
    $dumpTotal = (Get-Size-Fast $sync.PathMemoryDump) + (Get-Size-Fast $sync.PathMinidumps)
    $fontTotal = (Get-Size-Fast $sync.PathFontCache) + (Get-Size-Fast $sync.PathFntDat)
    $iconTotal = (Get-Size-Fast $sync.PathIconCache) + (Get-Size-Fast $sync.PathIconLegacy)

    $sync.Window.Dispatcher.Invoke([Action]{
        if ($dumpTotal -gt 0) { $sync.chkDumps.Content += " (~$(Format-Size $dumpTotal))" }
        if ($fontTotal -gt 0) { $sync.chkFontCache.Content += " (~$(Format-Size $fontTotal))" }
        if ($iconTotal -gt 0) { $sync.chkUserAssist.Content += " (~$(Format-Size $iconTotal))" }
    })

    # 2. Verification S.M.A.R.T.
    try {
        $smartFailures = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue | Where-Object { $_.PredictFailure }
        if ($smartFailures) {
            $alertMsg = "ALERTE S.M.A.R.T. : Defaillance imminente detectee !`n`n"
            foreach ($f in $smartFailures) {
                $instanceId = $f.InstanceName.Split('_')[0]
                $disk = Get-CimInstance -ClassName Win32_DiskDrive | Where-Object { $_.PNPDeviceID -like "*$instanceId*" }
                if ($disk) { $alertMsg += "- $($disk.Model)`n" }
            }
            $alertMsg += "`nIl est deconseille de lancer WinSxS / SFC."
            $sync.Window.Dispatcher.Invoke([Action]{
                [System.Windows.MessageBox]::Show($sync.Window, $alertMsg, "Danger Materiel", "OK", "Warning")
            })
        }
    } catch {}
}

$window.Add_Loaded({
    $rsInit = [runspacefactory]::CreateRunspace()
    $rsInit.ApartmentState = "STA"
    $rsInit.ThreadOptions  = "ReuseThread"
    $rsInit.Open()
    $psInit = [powershell]::Create().AddScript($initScript).AddArgument($sync)
    $psInit.Runspace = $rsInit
    $psInit.BeginInvoke()
})

$btnAbout.Add_Click({
    $aboutXaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' Title='A Propos - Cleaner' Height='420' Width='440' WindowStartupLocation='CenterOwner' Background='#1e1e2e' ResizeMode='NoResize'>
    <Grid Margin='24'>
        <Grid.RowDefinitions>
            <RowDefinition Height='*'/>
            <RowDefinition Height='Auto'/>
        </Grid.RowDefinitions>
        <ScrollViewer Grid.Row='0' VerticalScrollBarVisibility='Auto' Margin='0,0,0,10'>
            <StackPanel>
                <TextBlock Text='CLEANER' FontSize='28' FontWeight='Bold' Foreground='#89b4fa' HorizontalAlignment='Center' Margin='0,0,0,4'/>
                <TextBlock Text='v$AppVersion' FontSize='13' Foreground='#6c7086' HorizontalAlignment='Center' Margin='0,0,0,20'/>
                <TextBlock Text='Auteur' FontWeight='Bold' Foreground='#fab387' FontSize='11' Margin='0,0,0,2'/>
                <TextBlock Text='ps81frt' Foreground='#cdd6f4' Margin='0,0,0,14'/>
                <TextBlock Text='Depot' FontWeight='Bold' Foreground='#fab387' FontSize='11' Margin='0,0,0,2'/>
                <TextBlock Margin='0,0,0,14'>
                    <Hyperlink Name='GithubLink' NavigateUri='https://github.com/ps81frt/cleaner' Foreground='#89b4fa'>https://github.com/ps81frt/cleaner</Hyperlink>
                </TextBlock>
                <TextBlock Text='Licence' FontWeight='Bold' Foreground='#fab387' FontSize='11' Margin='0,0,0,2'/>
                <Border Background='#181825' CornerRadius='5' Padding='10'>
                    <TextBlock Foreground='#a6e3a1' TextWrapping='Wrap' FontSize='10' FontFamily='Consolas'>Copyright (c) 2026 ps81frt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.</TextBlock>
                </Border>
            </StackPanel>
        </ScrollViewer>
        <Button Grid.Row='1' Name='BtnCloseAbout' Content='Fermer' Height='34' Background='#313244' Foreground='#cdd6f4' FontWeight='Bold' BorderThickness='0' Cursor='Hand'/>
    </Grid>
</Window>
"@
    $aboutWin = [Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new([xml]$aboutXaml))
    $aboutWin.Owner = $window
    $aboutWin.FindName("BtnCloseAbout").Add_Click({ $aboutWin.Close() })
    $aboutWin.FindName("GithubLink").Add_RequestNavigate({ Start-Process $_.Uri.AbsoluteUri })
    $aboutWin.ShowDialog() | Out-Null
})

$btnHelp.Add_Click({
    $helpXaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' Title='Aide Technique' Height='740' Width='500' WindowStartupLocation='CenterOwner' Background='#1e1e2e' ResizeMode='NoResize'>
    <Grid Margin='20'>
        <Grid.RowDefinitions>
            <RowDefinition Height='Auto'/>
            <RowDefinition Height='*'/>
            <RowDefinition Height='Auto'/>
        </Grid.RowDefinitions>
        <TextBlock Grid.Row='0' Text='AIDE TECHNIQUE' FontSize='18' FontWeight='Bold' Foreground='#fab387' Margin='0,0,0,12'/>
        <ScrollViewer Grid.Row='1' VerticalScrollBarVisibility='Auto' Margin='0,0,0,10'>
            <StackPanel>
                <TextBlock Text='CE QUE CLEANER NETTOIE' FontWeight='Bold' Foreground='#a6e3a1' FontSize='12' Margin='0,0,0,6'/>
                <Border Background='#181825' CornerRadius='5' Padding='10' Margin='0,0,0,10'>
                    <StackPanel>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• %TEMP%, C:\Windows\Temp — temporaires utilisateur et systeme</TextBlock>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• C:\Windows\Prefetch — traces prefetch (layout.ini preserve)</TextBlock>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• WER %LOCALAPPDATA% et %PROGRAMDATA% — rapports Watson</TextBlock>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• D3DSCache, DeliveryOptimization, BranchCache</TextBlock>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• Logs CBS, Panther, MoSetup, setupapi.offline.log</TextBlock>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• SoftwareDistribution, catroot2 (arret services WU)</TextBlock>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• iconcache*.db, thumbcache*.db, IconCache.db (legacy)</TextBlock>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap'>• Corbeille, cache DNS/ARP, Recent Shell</TextBlock>
                    </StackPanel>
                </Border>
                <TextBlock Text='BOUTONS' FontWeight='Bold' Foreground='#89b4fa' FontSize='12' Margin='0,0,0,6'/>
                <Border Background='#181825' CornerRadius='5' Padding='10' Margin='0,0,0,10'>
                    <StackPanel>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11' Margin='0,0,0,5'><Run FontWeight='Bold' Foreground='#fab387'>ESTIMER :</Run> Analyse les dossiers sans suppression. Evalue le gain potentiel selon les options cochees.</TextBlock>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11' Margin='0,0,0,5'><Run FontWeight='Bold' Foreground='#89b4fa'>LANCER :</Run> Execute les purges reelles. Arret temporaire d explorer.exe et des services Windows Update requis.</TextBlock>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11'><Run FontWeight='Bold' Foreground='#cba6f7'>REGISTRE :</Run> Purge les traces MRU et RecentDocs dans HKCU. Aucun service arrete, aucun risque systeme. Effet apres reconnexion.</TextBlock>
                    </StackPanel>
                </Border>
                <TextBlock Text='NETTOYAGE REGISTRE HKCU' FontWeight='Bold' Foreground='#cba6f7' FontSize='12' Margin='0,0,0,6'/>
                <Border Background='#181825' CornerRadius='5' Padding='10' Margin='0,0,0,4'>
                    <StackPanel>
                        <TextBlock Text='Scope exclusif HKCU — zero impact systeme.' Foreground='#f9e2af' FontSize='11' FontStyle='Italic' TextWrapping='Wrap' Margin='0,0,0,8'/>
                        <TextBlock Text='Cles purgees :' FontWeight='Bold' Foreground='#a6e3a1' FontSize='11' Margin='0,0,0,4'/>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• RunMRU — historique boite Executer (Win+R)</TextBlock>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• TypedPaths — chemins tapes dans la barre adresse Explorer</TextBlock>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• RecentDocs — fichiers recents dans le menu Shell</TextBlock>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• ComDlg32\OpenSavePidlMRU — boites Ouvrir/Enregistrer</TextBlock>
                        <TextBlock Foreground='#cdd6f4' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,10'>• LastVisitedPidlMRU — dernier dossier visite par application</TextBlock>
                        <TextBlock Text='A NE JAMAIS MODIFIER :' FontWeight='Bold' Foreground='#f38ba8' FontSize='11' Margin='0,0,0,4'/>
                        <TextBlock Foreground='#9399b2' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• HKLM\SYSTEM — pilotes, services, configuration materielle</TextBlock>
                        <TextBlock Foreground='#9399b2' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• HKLM\SOFTWARE — installations, licences applicatives</TextBlock>
                        <TextBlock Foreground='#9399b2' FontSize='11' TextWrapping='Wrap' Margin='0,0,0,2'>• HKCU\Software\[app] — preferences et parametres utilisateur</TextBlock>
                        <TextBlock Foreground='#9399b2' FontSize='11' TextWrapping='Wrap'>• HKLM\SAM / SECURITY — hachages et politiques de securite</TextBlock>
                    </StackPanel>
                </Border>
                <TextBlock Text='OPTIONS AVANCEES' FontWeight='Bold' Foreground='#89b4fa' FontSize='12' Margin='0,10,0,6'/>
                <Border Background='#181825' CornerRadius='5' Padding='10' Margin='0,0,0,10'>
                    <StackPanel>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11' Margin='0,0,0,4'><Run FontWeight='Bold'>WinSxS :</Run> Operation longue et definitive. Compresse le magasin des composants Windows Update. Empeche le rollback des KB.</TextBlock>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11' Margin='0,0,0,4'><Run FontWeight='Bold'>UserAssist / BAM :</Run> Arret Explorer, purge des cles HKCU et HKLM bam/dam. Redemarrage recommande apres.</TextBlock>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11' Margin='0,0,0,4'><Run FontWeight='Bold'>Logs retention :</Run> Coche = purge totale. Decoche = conserve les 30 derniers jours.</TextBlock>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11'><Run FontWeight='Bold'>Dumps :</Run> Supprime MEMORY.DMP et Minidumps. Desactivez si un crash est en cours d analyse.</TextBlock>
                    </StackPanel>
                </Border>
                <TextBlock Text='DEPANNAGE' FontWeight='Bold' Foreground='#f38ba8' FontSize='12' Margin='0,0,0,6'/>
                <Border Background='#181825' CornerRadius='5' Padding='10'>
                    <StackPanel>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11' Margin='0,0,0,3'>• Erreur acces : verifiez l elevation UAC (lancer en tant qu administrateur).</TextBlock>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11' Margin='0,0,0,3'>• Shell absent : Gestionnaire des taches &gt; Fichier &gt; Executer &gt; explorer.exe</TextBlock>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11' Margin='0,0,0,3'>• Alerte SMART : defaillance disque imminente. Sauvegardez avant tout I/O lourd.</TextBlock>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11' Margin='0,0,0,3'>• Services WU bloques apres nettoyage : net start wuauserv en admin.</TextBlock>
                        <TextBlock Foreground='#cdd6f4' TextWrapping='Wrap' FontSize='11'>• Rapport genere sur le Bureau : cleaner_AAAAMMJJ_HHMM.log</TextBlock>
                    </StackPanel>
                </Border>
            </StackPanel>
        </ScrollViewer>
        <Button Grid.Row='2' Name='BtnCloseHelp' Content='Compris' Height='34' Background='#313244' Foreground='#cdd6f4' FontWeight='Bold' BorderThickness='0' Cursor='Hand'/>
    </Grid>
</Window>
"@
    $helpWin = [Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new([xml]$helpXaml))
    $helpWin.Owner = $window
    $helpWin.FindName("BtnCloseHelp").Add_Click({ $helpWin.Close() })
    $helpWin.ShowDialog() | Out-Null
})

# ----------------------------
# Evenement Bouton Registre
# ----------------------------
$btnRegistry.Add_Click({
    $confirm = [System.Windows.MessageBox]::Show(
        $window,
        "Purge des traces utilisateur dans le registre (HKCU) :`n`n  - RunMRU            (historique Executer Win+R)`n  - TypedPaths        (barre adresse Explorer)`n  - RecentDocs        (fichiers recents Shell)`n  - OpenSavePidlMRU   (boites Ouvrir/Enregistrer)`n  - LastVisitedPidlMRU (dernier dossier par app)`n`nScope : HKCU uniquement. Aucun service arrete.`nAucun risque systeme. Effet apres reconnexion.`n`nConfirmer ?",
        "Nettoyage Registre HKCU",
        "YesNo",
        "Question"
    )
    if ($confirm -ne "Yes") { return }

    $btnRegistry.IsEnabled = $false
    $logBox.Text = ""

    $regScript = {
        param($sync)

        function Write-RegLog($msg) {
            $sync.Window.Dispatcher.Invoke([Action]{
                $sync.Log.AppendText("$msg`n")
                $sync.Scroll.ScrollToEnd()
            })
        }

        Write-RegLog "[+] Nettoyage registre HKCU..."

        $regKeys = @(
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU";                    Label = "RunMRU" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths";               Label = "TypedPaths" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs";               Label = "RecentDocs" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU"; Label = "OpenSavePidlMRU" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU"; Label = "LastVisitedPidlMRU" }
        )

        foreach ($entry in $regKeys) {
            try {
                if (Test-Path $entry.Path) {
                    $props = Get-ItemProperty $entry.Path -ErrorAction SilentlyContinue
                    $valuesToRemove = $props.PSObject.Properties |
                        Where-Object { $_.Name -notin @("PSPath","PSParentPath","PSChildName","PSDrive","PSProvider","MRUList","MRUListEx") }
                    foreach ($v in $valuesToRemove) {
                        Remove-ItemProperty -Path $entry.Path -Name $v.Name -Force -ErrorAction SilentlyContinue
                    }
                    Remove-ItemProperty -Path $entry.Path -Name "MRUList"   -Force -ErrorAction SilentlyContinue
                    Remove-ItemProperty -Path $entry.Path -Name "MRUListEx" -Force -ErrorAction SilentlyContinue
                    Write-RegLog "   -> $($entry.Label) purge"
                } else {
                    Write-RegLog "   [i] $($entry.Label) absent (deja propre)"
                }
            } catch {
                Write-RegLog "   [!] Echec $($entry.Label) : $($_.Exception.Message)"
            }
        }

        Write-RegLog "[+] Registre HKCU nettoye. Effet complet apres deconnexion/reconnexion."
        $sync.Window.Dispatcher.Invoke([Action]{
            $sync.BtnRegistry.IsEnabled = $true
        })
    }

    $sync.BtnRegistry = $btnRegistry

    $rsReg = [runspacefactory]::CreateRunspace()
    $rsReg.ApartmentState = "STA"
    $rsReg.ThreadOptions  = "ReuseThread"
    $rsReg.Open()
    $psReg = [powershell]::Create()
    $psReg.Runspace = $rsReg
    $psReg.AddScript($regScript).AddArgument($sync) | Out-Null
    $psReg.BeginInvoke() | Out-Null
})

# ----------------------------
# Evenements boutons
# ----------------------------
$btnQuit.Add_Click({
    $sync.Window.Close()
})

$window.Add_Closing({
    $sync.Stop = $true
    if ($global:runspaceMonitorTimer) { $global:runspaceMonitorTimer.Stop() }
    if ($global:activePowerShell) {
        try {
            if ($global:activeAsyncResult -and -not $global:activeAsyncResult.IsCompleted) {
                $global:activePowerShell.Stop()
            }
        } catch {} finally {
            $global:activePowerShell.Dispose()
            $global:activeRunspace.Dispose()
        }
    }
    [Environment]::Exit(0)
})

$btnStart.Add_Click({
    $sync.TotalFreed = 0
    $sync.CleanUserAssist = [bool]$chkUserAssist.IsChecked
    $sync.CleanEventLogs  = [bool]$chkEventLogs.IsChecked
    $sync.CleanWinSxS     = [bool]$chkWinSxS.IsChecked
    $sync.CleanBrowsers   = [bool]$chkBrowsers.IsChecked
    $sync.CleanDumps      = [bool]$chkDumps.IsChecked
    $sync.CleanFontCache  = [bool]$chkFontCache.IsChecked
    $sync.FullLogs        = [bool]$chkFullLogs.IsChecked
    $sync.RunSFC          = [bool]$chkSFC.IsChecked
    $sync.VerboseMode     = [bool]$chkVerbose.IsChecked
    $sync.AppVersion      = $AppVersion

    $sync.Stop = $false
    $btnStart.IsEnabled = $false
    $logBox.Text = ""
    $progress.Value = 0
    $txtFinal.Visibility = 'Collapsed'

    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions  = "ReuseThread"
    $rs.Open()

    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript($cleanScript).AddArgument($sync) | Out-Null

    $global:activePowerShell = $ps
    $global:activeRunspace = $rs
    $global:activeAsyncResult = $ps.BeginInvoke()

    $global:runspaceMonitorTimer.Start()
})

# ----------------------------
# Lancement GUI
# ----------------------------
$window.ShowDialog() | Out-Null

<# Licence MIT - Copyright (c) 2026 ps81frt #>
