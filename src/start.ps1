$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

$Config = @{
    LastUpdateCheckDate = ''
    LatestReleaseId = ''
    SaveToFolder = ''
}

if (!(Test-Path -Path 'run/' -PathType Container)) {
    New-Item -ItemType Directory -Force -Path 'run/'
}

if (!(Test-Path -Path 'run/config.json')) {
    $Config | ConvertTo-Json | Out-File -FilePath 'run/config.json'
} else {
    $Config = Get-Content -Path 'run/config.json' | ConvertFrom-Json
}

$CheckForUpdate = (Get-Date -Format 'yyyy-MM-dd') -gt $Config.LastUpdateCheckDate
if ($CheckForUpdate) {
    $LatestReleaseInfo = Invoke-RestMethod -Method Get -Uri https://api.github.com/repos/ytdl-org/youtube-dl/releases/latest
    $LatestReleaseInfo = $LatestReleaseInfo.assets | Where-Object {$_.name -eq 'youtube-dl.exe'} | Select-Object -Property id,browser_download_url
    $Config.LastUpdateCheckDate = Get-Date -Format 'yyyy-MM-dd'

    if ($Config.LatestReleaseId -ne $LatestReleaseInfo.id) {
        Invoke-WebRequest -Uri $LatestReleaseInfo.browser_download_url -UseBasicParsing -OutFile 'run/youtube-dl.exe'
        $Config.LatestReleaseId = $LatestReleaseInfo.id
    }

}

if (!(Test-Path -Path $Config.SaveToFolder)) {
    $SaveToFolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $SaveToFolderDialog.Description = 'Download-Ordner (wird gemerkt)'
    $SaveToFolderDialog.rootfolder = 'MyComputer'
    if (!($SaveToFolderDialog.ShowDialog() -eq 'OK')) {
        Exit
    }
    $Config.SaveToFolder = $SaveToFolderDialog.SelectedPath
}

$Config | ConvertTo-Json | Out-File -FilePath 'run/config.json'

$VideoUrl = [Microsoft.VisualBasic.Interaction]::InputBox('Wie lautet die Adresse des Youtube-Videos?', 'Video-URL', 'https://youtu.be/dQw4w9WgXcQ')
if ($VideoUrl -eq '') {
    Exit
}

$YtDlExecFilePath = Resolve-Path -Path 'run/youtube-dl.exe'

Start-Process -FilePath $YtDlExecFilePath -ArgumentList $VideoUrl -WorkingDirectory $Config.SaveToFolder