<#
.SYNOPSIS
    Build a Provisioning package
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    https://oofhours.com/2023/02/14/simplify-the-process-of-generating-an-aad-bulk-enrollment-provisioning-package/
#>

[cmdletbinding()]
param(
    [string] $Path = "$env:temp\control.ppkg",
    [parameter(mandatory)]
    [pscredential] $DomainJoinCred = $cred,
    [string] $DomainName,
    [string] $ComputerName = 'Windows-%RAND:5%',
    [parameter(mandatory)]
    [string] $URL,
    [string] $Role
)

#region Create XML Package

if ( $DomainName ) {

    $ComputerAccount = @"
          <ComputerAccount>
            <Account>$( $DomainJoinCred.username )</Account>
            <ComputerName>$ComputerName</ComputerName>
            <DomainName>$DomainName</DomainName>
            <Password>$( $DomainJoinCred.GetNetworkCredential().Password )</Password>
          </ComputerAccount>
"@

}
else {

    $ComputerAccount = @"
            <ComputerAccount>
                <ComputerName>$ComputerName</ComputerName>
                </ComputerAccount>
            <Users>
                <User UserName="$( $DomainJoinCred.username )">
                    <Password>$( $DomainJoinCred.GetNetworkCredential().Password )</Password>
                    <UserGroup>Administrators</UserGroup>
                </User>
            </Users>
"@

}

@"
<?xml version="1.0" encoding="utf-8"?>
<WindowsCustomizations>
  <PackageConfig xmlns="urn:schemas-Microsoft-com:Windows-ICD-Package-Config.v1.0">
    <ID>{cf580d1f-b5ed-4262-ad30-2c56c7d10393}</ID>
    <Name>DeploymentLiveCorp</Name>
    <Version>1.3</Version>
    <OwnerType>OEM</OwnerType>
    <Rank>0</Rank>
    <Notes></Notes>
  </PackageConfig>
  <Settings xmlns="urn:schemas-microsoft-com:windows-provisioning">
    <Customizations>
      <Common>
        <Accounts>
$ComputerAccount
        </Accounts>
        <OOBE>
          <Desktop>
            <HideOobe>True</HideOobe>
          </Desktop>
        </OOBE>
        <Policies>
          <ApplicationManagement>
            <AllowAllTrustedApps>Yes</AllowAllTrustedApps>
          </ApplicationManagement>
        </Policies>
        <ProvisioningCommands>
          <PrimaryContext>
            <Command>
              <CommandConfig Name="Provisioning">
                <CommandFile>$PSscriptRoot\provision.cmd</CommandFile>
                <CommandLine>cmd.exe /c provision.cmd $URL $Role</CommandLine>
                <ContinueInstall>False</ContinueInstall>
                <DependencyPackages>
                  <Dependency Name="PsExec64">C:\ProgramData\chocolatey\lib\sysinternals\tools\Psexec64.exe</Dependency>
                </DependencyPackages>
                <RestartRequired>False</RestartRequired>
                <ReturnCodeRestart>3010</ReturnCodeRestart>
                <ReturnCodeSuccess>0</ReturnCodeSuccess>
              </CommandConfig>
            </Command>
          </PrimaryContext>
        </ProvisioningCommands>
      </Common>
    </Customizations>
  </Settings>
</WindowsCustomizations>

"@ | out-file -encoding utf8BOM -FilePath $env:temp\control.Xml

#endregion

#region Find ICD

$ICD = Find-Localfile -Name "icd.exe" -CommonLocation { "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Imaging and Configuration Designer\x86\icd.exe" }
$StoreFile = Join-Path (split-path $ICD) 'Microsoft-Desktop-Provisioning.dat' 

#endregion

$ICDArgs = @(
    '/Build-ProvisioningPackage'
    "/CustomizationXML:$env:temp\control.Xml"
    "/PackagePath:$Path"
    "/StoreFile:$env:temp\Microsoft-Desktop-Provisioning.dat"
    '+Overwrite'

)

# For some reason icd.exe does NOT like the long pathname here, so move to Temp during execution.
copy-item $storeFile $env:temp\Microsoft-Desktop-Provisioning.dat

$ICDArgs | Write-Verbose
& $icd $ICDArgs

remove-item $env:temp\Microsoft-Desktop-Provisioning.dat

