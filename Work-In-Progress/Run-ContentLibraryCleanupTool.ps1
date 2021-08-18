# Site configuration
$SiteCode = "PS1" # Site code 
$ProviderMachineName = "CM01.corp.viamonstra.com" # SMS Provider machine name

# Customizations
$initParams = @{}

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}


# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams


Set-Location -Path $env:SystemDrive
$ToolPath = "\\CM01\E$\Program Files\Microsoft Configuration Manager\cd.latest\SMSSETUP\TOOLS\ContentLibraryCleanup"
$DistributionPoints = @(
    "Cd1"
)

if ($DistributionPoints -eq "") {
    try {
        $DistributionPoints = @(Get-CMDistributionPoint -ErrorAction Stop).NetworkOSPath
    }
    catch {
        Write-Output "Could not get DistributionPoints: $($_.Exception.Message)"; Exit 1
    }
}

$TrimmedDPName = $DistributionPoints.trim("\")

#Set Params and run CleanupTool
foreach ($DP in $TrimmedDPName) {
    if ($DP -like "*DPServer*") {
        Write-Output "$DP found in exceptionlist, skipping..."
    }
    Else {
        $ContentLibCleanupTool = @{
            FilePath               = "$ToolPath\ContentLibraryCleanup.exe"
            ArgumentList           = @(
                "/DP $DP", `
                "/Mode $Mode", `
                "/q"
            )
            Wait                   = $true
            Passthru               = $true
            RedirectStandardOutput = "$ToolPath\Logs\$DP-LibraryCleanup.log"
        }
        try {
            Start-Process @ContentLibCleanupTool -ErrorAction Stop
        }
        catch {
            Write-Output "Could not start process: $($_.Exception.Message)"; Exit 1
        }
    }
}
