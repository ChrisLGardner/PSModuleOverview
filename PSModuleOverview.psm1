function New-ModuleOverview {
    <#
    .SYNOPSIS
    Generates a Markdown file with a short description of each public command in a module.

    .DESCRIPTION
    Finds all the public commands in a specified module and produces a simple Markdown file detailing the description or synopsis (user choice) for each.

    .PARAMETER ModuleName
    Name of the module to generate an overview for. If the module isn't already loaded then it will be loaded.

    .PARAMETER Path
    Output path for the Markdown file. Must end in .md.

    .PARAMETER HelpContent
    Which piece of help content should be used in the generated content, either Synopsis or Description. Defaults to Synopsis

    .PARAMETER Append
    Append to the end of an existing Markdown file.

    .EXAMPLE
    New-ModuleOverview -ModuleName TLS -Path .\readme.md

    This will generate an overview of the TLS module and output it to readme.md in the current directory.

    .EXAMPLE
    New-ModuleOverview -ModuleName DISM -Path .\readme.md -Append

    This will generate an overview of the DISM module and output it to an existing readme.md in the current directory.

    .EXAMPLE
    New-ModuleOverview -ModuleName PSScheduledJob -Path .\readme.md -HelpContent Description

    This will generate an overview of the PSScheduledJob module using the description from each help comment and output it to readme.md in the current directory.

    #>

    [cmdletbinding()]
    param (
        [Alias('Name')]
        [string]$ModuleName,

        [ValidateScript({
            if ($_.Extension -ne '.md') {
                throw 'Path should be to a Markdown (md) file.'
            }
            $true
        })]
        [Alias('Fullname','FilePath')]
        [System.Io.Fileinfo]$Path,

        [ValidateSet('Description','Synopsis')]
        [string]$HelpContent = 'Synopsis',

        [Switch]$Append
    )

    if (-not(Get-Module $ModuleName)) {
        Import-Module -Name $ModuleName
    }

    $OutString = "# About $ModuleName*`n`n"
    $Commands = Get-Command -Module $ModuleName

    Foreach ($Command in $Commands) {
        $OutString += "## $($Command.Name)`n`n"
        try {
            if ($HelpContent -eq 'Description') {
                $OutString += "$((Get-Help $Command.Name).Description.Text)`n`n`n"
            }
            else {
                $OutString += "$((Get-Help $Command.Name).Synopsis)`n`n`n"
            }
        }
        catch {
            if ($_.FullyQualifiedErrorId -like 'TypeNotFound*') {
                Write-Warning "Failed to get help for $($Command.Name) due to: $($_.Exception.Message)"
            }
            else {
                Write-Error $_ -ErrorAction Continue
            }
        }
    }

    if ($Append) {
        Add-Content -Value $OutString -Path $Path
    }
    else {
        Set-Content -Value $OutString -Path $Path -Force
    }

}
