get-childitem "$PSscriptRoot\Build" -Exclude Winpe.amd64,winpe.arm64,signed,UnSigned | % {
    write-verbose "Removing $($_.FullName)"
    remove-item $_.FullName -recurse -force
}
