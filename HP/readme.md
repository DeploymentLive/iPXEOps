# Deployment of Sure-Recover to HP Machines

HP provides a method to preform HTTPS Boot of an iPXE file, but the way they do it is a bit... unique.

## Operation

Whereas most other OEM's will just allow us to put the URL of the iPXE executable into firmware, 
HP has a unique proprietary method for HTTPS booting where we put a signing Certificate and a URL *Path* into the firmware.

On Recovery `F11` the system will:
* download the recovery.mft manifest file from the saved URL path.
* download the recovery.sig signature file from the same URL path.
* We verify the recovery.mft and recovery.sig files were signed by the trusted certificate in firmware.
* The files in the recovery.mft manifest are downloaded, and their SHA256 hashes are compared to the manifest.
* The downloaded files are placed on a new virtual USB device, and the machine boots to whatever is on that device. 

For iPXE, we just need to add \EFI\BOOT\BOOTX64.EFI and \Autoexec.ipxe to the manifest, and can now boot to anywhere.

This system works well when downloading a virtual WinPE USB image, but it does seem a bit overkill for our simple iPXE binary.

## Crypto/Security.

Whereas most other OEM's will just load the public certificate of the HTTPS server into firmware to validate the iPXE binary, 
HP has a unique proprietary method for verifying the integrity of remote downloaded files, and for making modifications to the BIOS/Firmware.


The HP Sure Recover system will use the following Public/Private cryptographic Key/Cert pairs:

|Key|Name|Description|
|---|---|---|
|CA|Certificate Authority<br/>(Optiona)|The keys below can be setup within a Corporate Certificate Authority (CA)|
|KEK|Platform Endorsement Key<br/>(PC Platform Ownership)|This key should be kept very secure, kept by the corporate machine owner, and Applied to PC only once.|
|SK|Signing Key<br/>(PC Operational Ownership)|Secure key held by the Desktop Automation Team, signed once by the KEK once.|
|RE|Recovery Payload Key<br/>(Recovery Automation Team)|Secure Key held by the team managing the tools in the recovery.mft file. Signed by the SK each time a new manifest is created.|

Note that organizationally, ownership of the keys, and of signing can be distributed among different teams.  If you are using a 3rd party cloud provider to maintain the Recovery payload (iPXE and/or WinPE images), the cloud provider doesn't need to maintain ownership of the KEK or SK keys. They only need to sign with their RE key. The owner of the PC's can tell all HP PCs to *trust* the RE key with a management command using the Signing Key. The owner can also easily revoke the Trust of the RE key using another command. 

## Payloads

In most of the HP documentation, whenever they create a "Payload" using one of the `New-HPXxxxXxxxXxxxPayload` PowerShell cmdlets, they **immediately** pipe the command into the `Set-HPSecurePlatformPayload` PowerShell cmdlet.  This is not necessary, in fact in production environments it's not recommended.

The payloads in HP Secure Platform Management are **signed**, either with the KEK, or the SK, and the PowerShell cmdlets required to create the Payload files will require the KEK or SK private key. Note that in all public/private key environments, we do **not** want the private key to leave the administrators machine and travel to other machines in an unsecure fashion. But the signed Payload in this case can then be passed down to any machine, and the machine will verify the signature and load up the payload on the box with the `Set-HPSecurePlatformPayload` cmdlet. The advantage is that we never need to pass down the private keys, or pass down BIOS **passwords** to the remote machines to make modifications to each HP PC. This is a good secure design. 

## Physical Presence

When setting up the KEK for the first time on a machine, the BIOS will perform one extra step to ensure that loading up the new KEK is correct, and approved by the physical owner of the box. After applying the `New-HPSecurePlatformEndorsementKeyProvisioningPayload` command with our KEK, we are asked to reboot. During the reboot, the user at the machine will be prompted with a **Physical Presence** Prompt. This can NOT be automated, and some of your less technical users may be confused with the prompt on the screen.

Optimally, the KEK should be loaded at the HP Factory, or within your provisioning lab.


## Steps

### Step 1 - Create the KEK - Endorsement Key

On the local **KEK** Management Server: 
Run script `New-HPEndorsementKey.ps1`

This will create

* KEK Public/Private Key pair
* KEK Pfx file.
* KEK HP Payload File.

This should be preformed only once, By the corporate owner.
*If possible, have HP load the Payload file in the factory.*

Example:
```
    $cred = Get-Credential -UserName 'admin' -Message 'KEK Password'
    .\New-HPEndorsementKey.ps1 -KEKPass $Cred.Password -Subject "/C=US/ST=AZ/L=Tucson/O=DeploymentLive/OU=Dev/CN=DeploymentLive.com"
```

### Step 2 - Create the SK - Signing Key

On the local **KEK/SK** Management Server: 
Run script `New-HPSigningKey.ps1`

This will create

* SK Public/Private Key pair
* SK Pfx file.
* SK HP Payload File.

This should be preformed only once, By the Desktop Automation owner.

Example:
```
    $credkek = Get-Credential -UserName 'admin' -Message 'KEK Password'
    $credsk = Get-Credential -UserName 'admin' -Message 'SK Password'
    .\New-HPSigningKey.ps1 -KEKPass $credkek.Password -SKPass $Credsk.Password -Subject "/C=US/ST=AZ/L=Tucson/O=DeploymentLive/OU=Dev/CN=DeploymentLive.com"
```

### Step 3 - Create the RE - Imaging Recovery Key

On the local **Imaging Recovery** Management Server:
Run script `New-HPRecoveryKey.ps1`

This will create

* RE Public/Private Key pair

Example:
```
    $credre = Get-Credential -UserName 'admin' -Message 'RE Password'
    .\New-HPRecoveryKey.ps1 -REPass $Credre.Password -Subject "/C=US/ST=AZ/L=Tucson/O=DeploymentLive/OU=Dev/CN=DeploymentLive.com"
```

### Step 4 - Create the RE - Imaging Recovery Payload

On the local **Signing Recovery** Management Server:
Run script `New-HPRecoveryPayload.ps1`

You should be given the `RE-cert.pem` file from the Recovery Server.

This will create:

* RE HP Payload File

Example:
```
    $credsk = Get-Credential -UserName 'admin' -Message 'RE Password'
    .\New-HPRecoveryPayload.ps1 -SKPass $Credsk.Password -url 'http://MyServer.org/boot/hp'
```

### Step 5 - Create RE - Imaging Recovery Manifest 

On the local **Imaging Recovery** Management Server:
Run script `New-HPRecoveryManifest.ps1`

This will create:

* HP recovery.mft Manifest File.
* HP recovery.sig Signature File.

Example:
```
    $credre = Get-Credential -UserName 'admin' -Message 'RE Password'
    .\New-HPRecoveryManifest.ps1 -REPass $CredRE.Password -FilePath 'd:\build\1002\HP\x64\'
```

**NOTE** The manifest, signature, and all files in the manifest can now be uploaded to your HTTP Server.

### Step 6 - Provision endpoints with KEK, SK and RE payloads

We are now ready to load the provisioning payloads onto the HP Endpoints.
Optimally, HP should be loading the KEK into the firmware at the factory so we avoid the *Physical Presence* Prompt.

However, if you haven't loaded the KEK on the Endpoint, On the local **Signing Recovery** Management Server
Run script `Build-HPDeploymentPackage`

This script requires:
* `kek.payload`
* `sk.payload`
* `re.payload`

and will create a **NEW** powershell script called `Deploy-HPSureRecovery.ps1`. This script will contain the code necessary to test and provision a HP Sure Recover on an Endpoint.

Copy the new `Deploy-HPSureRecovery.ps1` to the HP Endpoint Machine.

#####################################################

### Step 7 - Provision endpoints with and SK and Recovery Manifest

We can now provision the HP machine For Sure Recovery.
Run script `Deploy-HPSureRecovery.ps1` on the HP Endpoint.

We may need to reboot the machine if the KEK hasn't been pre-provisioned. 

Once the files are up on your HTTP(S) server, boot your HP endpoint and enter recover by pressing `F11`.

Fin.

## Open questions

* Does HP have a method for uploading KEK - Platform Endorsement Keys into firmware at the factory. <br/>This would make remote autopilot configuration easier.

## Links

https://www.deploymentresearch.com/configuring-hp-firmware-for-https-download-and-boot-of-your-favorite-boot-image/
https://garytown.com/category/hp/sure-recover 
