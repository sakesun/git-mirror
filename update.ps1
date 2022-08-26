$SOURCES_FILE = (Join-Path $PSScriptRoot "sources.json")

function checkSourcesFile {
    $sourcesExists = Test-Path $SOURCES_FILE -PathType Leaf
    if (! $sourcesExists) {
        $sampleContent = (
            @{
                sample = @{
                    repo = "https://github.com/sample/sample.git"
                }
            }
            | ConvertTo-Json
        )
        [Console]::Error.WriteLine("Need $SOURCES_FILE")
        [Console]::Error.WriteLine("`nGenerate sample content:`n")
        [Console]::Error.WriteLine("$sampleContent")
        $sampleContent | Out-File $SOURCES_FILE
    }
    return $sourcesExists
}

function loadSources {
    return (Get-Content -Path $SOURCES_FILE | ConvertFrom-Json -AsHashtable)
}

function processSource($name, $repo, $reset) {
    $target = (Join-Path $PSScriptRoot $name)
    $targetExists = Test-Path $target -PathType Container
    if (! $targetExists) {
        git clone "$repo" "$target"
    } else {
        Push-Location $target
        if ($reset) {
            Write-Output "  Resetting..."
            git reset --hard
            Write-Output "  Cleaning..."
            git clean --force -d -x
            Write-Output "  Checking out HEAD..."
            git checkout HEAD
        }
        Write-Output "  Pulling..."
        git pull
        Pop-Location
    }
}

function Main {
    param (
        [string] $filter,
        [switch] $reset
    )
    if (! (checkSourcesFile)) { return }
    $sources = loadSources
    foreach ($s in $sources.GetEnumerator()) {
        if ($s.Key.StartsWith("_")) { continue; }
        if (! [string]::IsNullOrEmpty($filter)) {
            if ($s.Key -notmatch "`^$filter`$") { continue; }
        }
        Write-Output "Updating $($s.Key)..."
        processSource `
          -name $s.Key `
          -repo $s.Value.repo `
          -reset $reset.IsPresent
        Write-Output ""
    }
}

#-----
Main @args
#-----
