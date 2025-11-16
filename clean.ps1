get-childitem "$PSscriptRoot\Build" -Exclude signed,UnSigned | % {
    write-verbose "Removing $($_.FullName)"
    remove-item $_.FullName -recurse -force
}
