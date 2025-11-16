<#
.Synopsis
    Sync S3 Bucket
.DESCRIPTION
    Sync a local folder with a S3 Bucket
.NOTES
    Not intended for super large sync
.EXAMPLE
    Copy-S3BucketWithSync -path "...\www" -S3BucketName 'deploymentliveweb' 
#>

[cmdletbinding()]
param(
    $path,
    $S3BucketName,
    $S3Prefix = '/',
    $S3Region = 'us-east-2'
)

if ( $StoredAWSCredentials -eq $Null ) { throw "Missing AWS Credentials" }

$s3Objects = Get-S3Object -BucketName $S3BucketName -Prefix $S3KeyPrefix -Region $S3Region
# $s3objects | % Key | out-string | write-verbose

$LocalFiles = Get-ChildItem -Path $Path -File -Recurse 
foreach ( $file in $localFiles ) { 
    $S3key = $file.fullname.replace($path,"").trim('\').replace('\','/')
    add-member -InputObject $file -MemberType NoteProperty -name key -value $S3Key

    $S3Object = $S3Objects | where-object { $_.Key -eq $file.key }
    if (-not $S3Object) {
        Write-warning "Uploading new file      : $($file.key)"
        Write-S3Object -BucketName $S3BucketName -File $file.FullName -Key $file.key -Region $S3Region
    } elseif ($file.LastWriteTime -gt $S3Object.LastModified.ToLocalTime() ) {
        Write-warning "Uploading modified file : $($file.key)"
        Write-S3Object -BucketName $S3BucketName -File $file.FullName -Key $file.key -Region $S3Region 
    } else {
        Write-verbose "File unchanged, skipping: $($file.key)"
    }
}

# remove Object if required 
foreach ( $File in Compare-Object $s3Objects.key $localfiles.key | ? SideIndicator -eq '<=' ) { 
    write-verbose "Remove item: $($File.InputObject)"
    Remove-S3Object -BucketName $S3BucketName -Key $file.InputObject -Region $S3Region -Confirm:$False | Write-Verbose
}
