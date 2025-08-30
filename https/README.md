# Certificate creation for HTTPS from CA

Devices that support HTTPS boot from UEFI do not connect with standard Internet Certificate Trust Infrastructure. 
Instead, IT administrators will create a HTTPS web site that is signed by a Certificate Authority (CA),
and the root trust CA.crt is loaded into the UEFI Firmware as a trusted root, so it knows which web sites to use. 

To create the Web site we need to follow these steps:

## Step 0 - Create the Certificate Authority (CA)

This has already been done with the script `New-CryptoAssets.ps1`.
* ca.crt - Certificate Authority Public Cert. 
* ca.key - Certificate Authority Private Key. 

Subject should be `CN=%hostname%`

## Step 1 - Create the request on the HTTPS Server. 

Run the script: `New-KeyAndCSR.ps1`. Will generate:
* %hostname%.key - Private Key 
* %hostname%.req - Certificate Request

Certificate request is passed back to CA for signing

## Step 2 - Sign the request with the CA

Run the script: `Complete-CertificateRequest.ps1`
Will take the request and output:
* %hostname%.crt - Certificate for HTTPS server.

Certificate is passed back to the HTTPS server for installation 

## Step 3 - The Certificate is installed 

Certificate is installed into Windows along with the Private key.

Adjust Bindings in IIS to use the new Certificate and Private Key.

## Step 4 - Install the CA Cert into UEFI

The ca.crt file is copied to a USB key and installed on a machine using Firmware Setup.
Along with the HTTPS URL for connecting back to the HTTPS server.

Example: https://boot.deploymentlive.com:8050/boot/snp_x64.efi

You should now be able to HTTPS Boot.

