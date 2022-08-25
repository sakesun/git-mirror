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
        "$sampleContent" | Out-File $SOURCES_FILE
        Exit
    }
}

function loadSources {
    checkSourcesFile
    return (Get-Content -Path $SOURCES_FILE | ConvertFrom-Json -AsHashtable)
}

function processSource($name, $repo) {
    $target = (Join-Path $PSScriptRoot $name)
    $targetExists = Test-Path $target -PathType Container
    if (! $targetExists) {
        git clone "$repo" "$target"
    } else {
        Push-Location $target
        git reset --hard
        git clean --force -d -x
        git checkout HEAD
        Pop-Location
    }
}

function Main {
    $sources = loadSources
    foreach ($s in $sources.GetEnumerator()) {
        if ($s.Key.StartsWith("_")) { continue; }
        processSource `
          -name $s.Key `
          -repo $s.Value.repo
    }

}

#-----
Main
#-----
