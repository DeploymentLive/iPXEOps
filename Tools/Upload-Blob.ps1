<#


For now I'm using OSD.Workspace to build WinPE images.

import-module osd.workspace -force ;  Build-OSDWorkspaceWinPE -name "MyBootMedia" -Architecture amd64 ; Build-OSDWorkspaceWinPE -Name "MyBootMedia" -Architecture arm64

#>

[cmdletbinding()]
param(
    $Path = ( get-item C:\OSDWorkspace\build\windows-pe\*\WinPE-Media\sources\boot.wim | select-object -last 2 )
)

#region Login to Azure)
if ( -not ( get-azcontext -ErrorAction SilentlyContinue )) {
    Connect-AzAccount | out-string | Write-verbose
}
#endregion

#region connect to storage account

$StorageAccount = @{
    name = 'deploymentlivefiles'
    resourcegroupname = 'DefaultResourceGroup-WUS2'
}

$StorageAccount = get-azStorageAccount @StorageAccount
$StorageAccount | out-string | write-verbose

#endregion 

#region check files and upload if changed 

$BlobContext = @{
    Context = $StorageAccount.Context
    Container = 'ipxebootfiles'
}

foreach ( $File in $Path ) {
    $File | out-string | write-verbose
    if ( $File -match 'arm64' ) { $arch = 'arm64' } else { $arch = 'x86_64' }

    $blob = Get-AzStorageBlob @BlobContext -Blob "$Arch/boot.wim" -ErrorAction SilentlyContinue
    $blob | out-string | write-verbose

    if ( $blob ) {
        if ( $blob.Length -ne ( ( get-item $file ).length ) ) {
            Write-Verbose "$File size changed. Upload New version"
        }
        elseif ( $blob.LastModified.UtcDateTime -lt ( get-item $file ).LastWriteTimeUtc  ) {
            Write-Verbose "$File is newer than blob. Upload New version"
        }
        else {
            Write-Verbose "$File is unchanged, skipping upload"
            continue
        }
    }

    write-warning "Uploading $File to $arch/boot.wim"
    Set-AzStorageBlobContent @BlobContext -file $File -Blob ( "$arch/boot.wim" ) -force | write-verbose
    get-filehash $file -Algorithm SHA256  >> "$PSScriptRoot\bootwimhashes.txt"

}

#endregion 