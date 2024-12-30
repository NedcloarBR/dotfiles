# Set PowerShell to UTF-8
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Set Config Variables
[string]$1080_Theme = Join-Path $PSScriptRoot ".\NedcloarBR-1080.omp.json"

# Init Oh My Posh
oh-my-posh --init --shell pwsh --config $1080_Theme | Invoke-Expression

# Import Modules
Import-Module -Name posh-git
Import-Module -Name Terminal-Icons
Import-Module -Name PSReadLine

# PSReadLine Config
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -EditMode Windows

# Aliases
Set-Alias -Name Projects -Value GoToProjects
Set-Alias -Name Home -Value GoToHome

# Functions
function GoToProjects ([string]$folder) { Set-Location "D:\Projetos\$folder" }
function GoToHome () { Set-Location $HOME}

# function SetTheme ([string] $theme) {
#     if(!$theme) {
#       Write-Error "Invalid Theme 
#       Usage: 1080 | 1920 | 2560"
#     } elseif($theme = "1080") {
#       oh-my-posh --init --shell pwsh --config $1080_Theme | Invoke-Expression
#     }
# }

# function Reset() {
  
# }

Clear-Host