# ============================================
# Cleaner GUI — Nettoyage complet FR
# ============================================

# ----------------------------
# Variables / Config
# ----------------------------
$AppTitle       = "Cleaner"
$AppSubtitle    = "Nettoyage complet detaille"
$AppWidth       = 520
$AppHeight      = 580

# Chemins a nettoyer
$PathTempUser   = "$env:TEMP\*"
$PathTempSys    = "C:\Windows\Temp\*"
$PathPrefetch   = "C:\Windows\Prefetch\*"
$PathWinLogs    = "C:\Windows\*.log"
$PathRecent     = "$env:APPDATA\Microsoft\Windows\Recent\*"
$PathWER        = "$env:LOCALAPPDATA\Microsoft\Windows\WER\*"
$PathD3D        = "$env:LOCALAPPDATA\D3DSCache\*"
$PathIconCache  = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*"
$PathThumbCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*"
$PathSoftDist   = "C:\Windows\SoftwareDistribution\*"

# Cles registre UserAssist / BAM / DAM
$RegUserAssist  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
$RegBAM         = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
$RegDAM         = "HKLM:\SYSTEM\CurrentControlSet\Services\dam\State\UserSettings"

# Journaux evenements a vider
$EventLogs      = @("Application", "System")

# Variables GUI (initialisees apres chargement XAML)
$window        = $null
$logBox        = $null
$progress      = $null
$btnStart      = $null
$btnQuit       = $null
$scroll        = $null
$chkUserAssist = $null
$chkEventLogs  = $null
$txtFinal      = $null

# Hashtable synchronisee (initialisee apres liaison GUI)
$sync          = $null

# ----------------------------
# Elevation Admin
# ----------------------------
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ----------------------------
# Hide Console
# ----------------------------
Add-Type -Name ConsoleHelper -Namespace WinAPI -MemberDefinition '
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); 
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
[WinAPI.ConsoleHelper]::ShowWindow([WinAPI.ConsoleHelper]::GetConsoleWindow(), 0) | Out-Null

# ----------------------------
# Import Assemblies GUI
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
    <Grid Margin='20'>
        <Grid.RowDefinitions>
            <RowDefinition Height='55'/>
            <RowDefinition Height='30'/>
            <RowDefinition Height='*'/>
            <RowDefinition Height='Auto'/>
            <RowDefinition Height='16'/>
            <RowDefinition Height='60'/>
            <RowDefinition Height='50'/>
        </Grid.RowDefinitions>

        <!-- Titre -->
        <TextBlock Grid.Row='0' Text='$AppTitle' FontSize='28' FontWeight='Bold'
                   Foreground='#cdd6f4' VerticalAlignment='Center' HorizontalAlignment='Center'/>

        <!-- Sous-titre -->
        <TextBlock Grid.Row='1' Text='$AppSubtitle' FontSize='12'
                   Foreground='#6c7086' VerticalAlignment='Center' HorizontalAlignment='Center'/>

        <!-- Zone log -->
        <Border Grid.Row='2' Background='#181825' CornerRadius='6' Padding='10'>
            <ScrollViewer Name='Scroll' VerticalScrollBarVisibility='Auto'>
                <TextBox Name='Log' Background='Transparent' Foreground='#a6e3a1'
                         FontFamily='Consolas' FontSize='12' BorderThickness='0'
                         IsReadOnly='True' TextWrapping='Wrap' AcceptsReturn='True'/>
            </ScrollViewer>
        </Border>

        <!-- Checkboxes options -->
        <StackPanel Grid.Row='3' Margin='4,10,4,4'>
            <CheckBox Name='ChkUserAssist' Content='Nettoyer UserAssist / BAM / DAM + cache icones'
                      Foreground='#a6e3a1' FontSize='13' Margin='0,0,0,4' IsChecked='False'/>
            <CheckBox Name='ChkEventLogs' Content='Vider les journaux evenements (Application / System)'
                      Foreground='#fab387' FontSize='13' IsChecked='False'/>
        </StackPanel>

        <!-- Barre de progression -->
        <ProgressBar Grid.Row='4' Name='Progress' Minimum='0' Maximum='100'
                     Height='6' Margin='0,6,0,0' Background='#313244' Foreground='#89b4fa'/>

        <!-- Boutons -->
        <StackPanel Grid.Row='5' Orientation='Horizontal' HorizontalAlignment='Center'>
            <Button Name='BtnStart' Content='Demarrer le nettoyage'
                    Height='36' Width='200' Margin='5,0'
                    Background='#89b4fa' Foreground='#1e1e2e' FontWeight='Bold'
                    FontSize='13' BorderThickness='0' Cursor='Hand'/>
            <Button Name='BtnQuit' Content='Quitter'
                    Height='36' Width='100' Margin='5,0'
                    Background='#ff5555' Foreground='#ffffff' FontWeight='Bold'
                    FontSize='13' BorderThickness='0' Cursor='Hand'/>
        </StackPanel>

        <!-- Message final -->
        <TextBlock Grid.Row='6' Name='TxtFinal' Text='' Foreground='#a6e3a1' FontSize='22' FontWeight='Bold'
                   HorizontalAlignment='Center' VerticalAlignment='Center' Visibility='Collapsed'/>
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
$btnStart      = $window.FindName("BtnStart")
$btnQuit       = $window.FindName("BtnQuit")
$scroll        = $window.FindName("Scroll")
$chkUserAssist = $window.FindName("ChkUserAssist")
$chkEventLogs  = $window.FindName("ChkEventLogs")
$txtFinal      = $window.FindName("TxtFinal")

# ----------------------------
# Hashtable synchronisee (UI <-> Runspace)
# ----------------------------
$sync = [hashtable]::Synchronized(@{
    Log            = $logBox
    Progress       = $progress
    Scroll         = $scroll
    TxtFinal       = $txtFinal
    BtnStart       = $btnStart
    Window         = $window
    Stop           = $false
    CleanUserAssist= $false
    CleanEventLogs = $false
    # Chemins
    PathTempUser   = $PathTempUser
    PathTempSys    = $PathTempSys
    PathPrefetch   = $PathPrefetch
    PathWinLogs    = $PathWinLogs
    PathRecent     = $PathRecent
    PathWER        = $PathWER
    PathD3D        = $PathD3D
    PathIconCache  = $PathIconCache
    PathThumbCache = $PathThumbCache
    PathSoftDist   = $PathSoftDist
    # Registre
    RegUserAssist  = $RegUserAssist
    RegBAM         = $RegBAM
    RegDAM         = $RegDAM
    # Event logs
    EventLogs      = $EventLogs
})

# ----------------------------
# Script de nettoyage (Runspace)
# ----------------------------
$cleanScript = {
    param($sync)

    # ----------------------------
    # Fonctions utilitaires
    # ----------------------------
    function Write-Log($msg) {
        $sync.Window.Dispatcher.Invoke([action]{
            $sync.Log.AppendText("$msg`n")
            $sync.Scroll.ScrollToEnd()
        })
    }

    function Set-Prog($val) {
        $sync.Window.Dispatcher.Invoke([action]{
            $sync.Progress.Value = $val
        })
    }

    function Remove-VerboseModern($path) {
        if ($sync.Stop) { return }
        $items = Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue
        if (-not $items -or $items.Count -eq 0) {
            Write-Log "   -> Rien a supprimer : $path"
            return
        }
        $i = 0
        foreach ($item in $items) {
            if ($sync.Stop) { Write-Log "[!] Nettoyage interrompu"; return }
            $i++
            Write-Log ("   [{0}/{1}] Supprime : {2}" -f $i, $items.Count, $item.FullName)
            Remove-Item $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
        }
    }

    function Start-CleanMgrStopable {
        if ($sync.Stop) { return }
        $proc = Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -PassThru
        while (-not $proc.HasExited) {
            Start-Sleep -Milliseconds 300
            if ($sync.Stop) {
                Write-Log "[!] CleanMgr interrompu par l utilisateur !"
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
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Write-Log "   -> Explorer arrete"
        Write-Log "[+] Nettoyage UserAssist / BAM / DAM..."
        Remove-Item $sync.RegUserAssist -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $sync.RegBAM        -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $sync.RegDAM        -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "[+] Nettoyage cache icones et miniatures..."
        Remove-Item $sync.PathIconCache  -Force -ErrorAction SilentlyContinue
        Remove-Item $sync.PathThumbCache -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 600
        Start-Process explorer
        Write-Log "   -> Explorer relance"
    } else {
        Write-Log "[i] UserAssist / BAM / DAM + cache icones ignores"
    }
    Set-Prog 10

    # ----------------------------
    # Nettoyage Temp et Prefetch
    # ----------------------------
    if (-not $sync.Stop) {
        Write-Log "[+] Nettoyage Temp utilisateur..."
        Remove-VerboseModern $sync.PathTempUser
    }
    if (-not $sync.Stop) {
        Write-Log "[+] Nettoyage Temp systeme..."
        Remove-VerboseModern $sync.PathTempSys
    }
    if (-not $sync.Stop) {
        Write-Log "[+] Nettoyage Prefetch..."
        Remove-VerboseModern $sync.PathPrefetch
    }
    Set-Prog 28

    # ----------------------------
    # Nettoyage logs et documents recents
    # ----------------------------
    if (-not $sync.Stop) {
        Write-Log "[+] Nettoyage fichiers .log Windows..."
        Remove-VerboseModern $sync.PathWinLogs
    }
    if (-not $sync.Stop) {
        Write-Log "[+] Nettoyage documents recents..."
        Remove-VerboseModern $sync.PathRecent
    }
    Set-Prog 38

    # ----------------------------
    # Vidage cache DNS
    # ----------------------------
    if (-not $sync.Stop) {
        Write-Log "[+] Vidage cache DNS..."
        ipconfig /flushdns 2>&1 | Out-Null
        Write-Log "   -> Cache DNS vide"
    }
    Set-Prog 43

    # ----------------------------
    # Nettoyage cache IE / Edge Legacy
    # ----------------------------
    if (-not $sync.Stop) {
        Write-Log "[+] Nettoyage cache IE / Edge Legacy..."
        Start-Process rundll32.exe -ArgumentList "InetCpl.cpl,ClearMyTracksByProcess 8" -Wait -WindowStyle Hidden
        Start-Process rundll32.exe -ArgumentList "InetCpl.cpl,ClearMyTracksByProcess 2" -Wait -WindowStyle Hidden
        Start-Process rundll32.exe -ArgumentList "InetCpl.cpl,ClearMyTracksByProcess 1" -Wait -WindowStyle Hidden
        Write-Log "   -> Cache IE / Edge Legacy nettoye"
    }
    Set-Prog 50

    # ----------------------------
    # Nettoyage cache Windows Update
    # ----------------------------
    if (-not $sync.Stop) {
        Write-Log "[+] Nettoyage cache Windows Update..."
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service bits     -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Remove-VerboseModern $sync.PathSoftDist
        Start-Service wuauserv -ErrorAction SilentlyContinue
        Start-Service bits     -ErrorAction SilentlyContinue
        Write-Log "   -> Services wuauserv / bits relances"
    }
    Set-Prog 63

    # ----------------------------
    # Nettoyage WER et DirectX Shader Cache
    # ----------------------------
    if (-not $sync.Stop) {
        Write-Log "[+] Nettoyage WER..."
        Remove-VerboseModern $sync.PathWER
    }
    if (-not $sync.Stop) {
        Write-Log "[+] Nettoyage DirectX Shader Cache..."
        Remove-VerboseModern $sync.PathD3D
    }
    Set-Prog 72

    # ----------------------------
    # Nettoyage journaux d'evenements
    # ----------------------------
    if ($sync.CleanEventLogs) {
        Write-Log "[+] Suppression journaux d evenements..."
        foreach ($log in $sync.EventLogs) {
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
    if (-not $sync.Stop) {
        Write-Log "[+] Nettoyage cache Windows Store (wsreset)..."
        Start-Process wsreset.exe -WindowStyle Hidden
        Write-Log "   -> wsreset lance en arriere-plan"
    }
    Set-Prog 83

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
    if (-not $sync.Stop) {
        Write-Log "[+] Lancement CleanMgr..."
        Start-CleanMgrStopable
    }
    Set-Prog 100

    # ----------------------------
    # Fin
    # ----------------------------
    $sync.Window.Dispatcher.Invoke([action]{
        if (-not $sync.Stop) {
            $sync.TxtFinal.Text = "NETTOYAGE TERMINE !"
            $sync.TxtFinal.Visibility = 'Visible'
            $sync.Log.AppendText("[+] Nettoyage termine !`n")
            $sync.Scroll.ScrollToEnd()
        }
        $sync.BtnStart.IsEnabled = $true
    })
}

# ----------------------------
# Evenements boutons
# ----------------------------
$btnQuit.Add_Click({
    $sync.Stop = $true
    $sync.Window.Close()
})

$btnStart.Add_Click({
    # Lecture des checkboxes sur le thread UI avant lancement Runspace
    $sync.CleanUserAssist = [bool]$chkUserAssist.IsChecked
    $sync.CleanEventLogs  = [bool]$chkEventLogs.IsChecked

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
    $ps.BeginInvoke() | Out-Null
})

# ----------------------------
# Lancement GUI
# ----------------------------
$window.ShowDialog() | Out-Null
