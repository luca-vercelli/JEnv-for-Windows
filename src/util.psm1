function Open-Prompt {
    param (
        [Parameter(Mandatory = $true)][string]$title,
        [Parameter(Mandatory = $true)][string]$question,
        [Parameter(Mandatory = $true)][string[]]$choices,
        [Parameter(Mandatory = $true)][string[]]$choice_descriptions,
        [Parameter(Mandatory = $true)][int]$default_choice
    )

    [System.Management.Automation.Host.ChoiceDescription[]] $options = @()
    for ($i = 0; $i -lt $choices.Length; $i++) {
        $options += New-Object System.Management.Automation.Host.ChoiceDescription ("&{0}" -f $choices[$i]), $choice_descriptions[$i]
    }

    return $Host.UI.PromptForChoice($title, $question, $options, $default_choice)
}

function Get-JavaVersion {
    param (
        [Parameter(Mandatory = $true)][string]$javaexe
    )
    # https://learn.microsoft.com/en-us/dotnet/api/system.version.tostring?view=netcore-1.0#system-version-tostring(system-int32)
    $version = (Get-Command $javaexe | Select-Object -ExpandProperty Version).toString(3)
    return $version
}

function Get-JavaMajorVersion {
    param (
        [Parameter(Mandatory = $true)][string]$javaexe
    )
    $version = Get-JavaVersion $javaexe
    if ("0.0.0" -eq $version) {
        return $null
    }
    $endIndex = $version.IndexOf(".")
    if ($version.StartsWith("1.")) {
        $endIndex = $version.IndexOf(".", $endIndex + 1)
    }
    return $version.Substring(0, $endIndex)
}

function Initialize-Profile {

    if ($null -ne $PROFILE -and $PROFILE -ne '') {
        $SNIPPET = @"
# JENV-INIT-START Do not remove any of this comment
function jenv {
    . "$PSScriptRoot\jenv.ps1" @args
}
# JENV-INIT-END Do not remove any of this comment
"@

        $profilePath = $PROFILE
        if (!(Test-Path $profilePath)) {
            New-Item -ItemType File -Path $profilePath -Force | Out-Null
        }
        $lines = Get-Content $profilePath

        $inside = $false
        $newLines = @()
        $oldSnippet = @()
        foreach ($line in $lines) {
            if ($line.StartsWith('# JENV-INIT-START')) {
                $inside = $true
                $oldSnippet += $line
            } elseif ($line.StartsWith('# JENV-INIT-END')) {
                $inside = $false
                $oldSnippet += $line
            } elseif ($inside) {
                $oldSnippet += $line
            } else {
                $newLines += $line
            }
        }
        if (($oldSnippet.Count -eq 0) -or (($oldSnippet -join "`r`n") -ne $SNIPPET)) {
            $newLines += $SNIPPET
            $newLines | Set-Content $profilePath
            if ($oldSnippet.Count -eq 0) {
                Write-Host "Added Jenv to profile file $PROFILE"
            } else {
                Write-Host "Updated Jenv in profile file $PROFILE"
            }
        }
    }
}
