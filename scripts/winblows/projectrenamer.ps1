#TODO: check for version 3


$oldProjectName = Read-Host 'Enter the _old_ project name';

$newProjectName = Read-Host 'Enter the _new_ project name';
#TODO: ADD DATABASE

$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path

# get all directories in calling path
$dir = Get-ChildItem $directorypath\Bootstrap* -Directory


# delete certain files
Write-Host "Deleting SUO"
Get-ChildItem $directorypath\*.suo -Hidden -File | Remove-Item -Force

$dbmdFile = "$directorypath\$oldProjectName" + '.Database\' + "$oldProjectName" + '.Database.dbmdl';
$dbUserFile = "$directorypath\$oldProjectName" + '.Database\' + "$oldProjectName" + '.Database.sqlproj.user';

Write-Host "Deleting DMBDL"
if(Test-Path $dbmdFile) { Remove-Item -Path $dbmdFile }

Write-Host "Deleting sqlproj.user"
if(Test-Path $dbUserFile) { Remove-Item -Path $dbUserFile }


# renaming directories
Write-Host "Removing DLLs"
Write-Host "Removing entities files"
Write-Host "Renaming files and directories"
$dir | ForEach-Object -Process {

    #Removing bin files
    if(Test-Path $_\bin) {
        Get-ChildItem $_\bin\* -Recurse -Include ("$oldProjectName" + '.*.dll'), ("$oldProjectName" + '.*.pdb') -File | Remove-Item -Force
    }

    #deleting entity files
    if(Test-Path $_\Models) {
        Get-ChildItem $_\Models\* -Recurse -Include ("$oldProjectName" + 'Entities.*') -File | Remove-Item -Force
    }
    
    #working with PROJ files
    # TODO: DON'T RENAME Bootstrap framework
    $projFile = Get-ChildItem $_\*.* -Include *.sqlproj, *.csproj -File

    if($projFile -ne $null) {
        $newProjFileName = $projFile.Name -replace (($oldProjectName + "."), ($newProjectName + "."));
        Rename-Item -Path $projFile.FullName -NewName ($projFile.DirectoryName + '\' + $newProjFileName)
    }
    
    #renaming folder
    Rename-item -Path $_.FullName -NewName ($_.FullName -replace (($oldProjectName + "."), ($newProjectName + "."))) 
}


 #rename within solution file
 $solutionFile = Get-Item ("$directorypath\$oldProjectName" + '.sln');

if($solutionFile -ne $null) {

    Write-Host "Fixing solution file"
    (Get-Content ("$directorypath\$oldProjectName" + '.sln') | 
    Foreach-Object -Process {$_ -replace ($oldProjectName + "."), ($newProjectName + ".") }) | 
    Set-Content ("$directorypath\$oldProjectName" + '.sln')

    Write-Host "Renaming solution file"
    Rename-Item -Path ("$directorypath\$oldProjectName" + '.sln') -NewName ("$directorypath\$newProjectName" + '.sln')
}



#Replacing all occurrences of BoostrapEntities
Write-Host "Search / replace Entities"
Get-ChildItem $directorypath -Recurse -Include *.cs, *.cshtml, *.tt, *.config, *.csproj, *.sqlproj -File | ForEach-Object -Process {
    (Get-Content $_.FullName) -Replace ($oldProjectName + "Entities"), ($newProjectName + "Entities") | Set-Content $_.FullName
}

Write-Host "Search / replace project name"
Get-ChildItem $directorypath -Recurse -Include *.cs, *.cshtml, *.tt, *.config, *.csproj, *.sqlproj, *.asax -File | ForEach-Object -Process {
    (Get-Content $_.FullName) -Replace ($oldProjectName), ($newProjectName) | Set-Content $_.FullName
}

Write-Host "Removing connection strings from Data\App.Config"

$file = ("$directorypath\$newProjectName" + '.Data\App.config')

[xml]$xml = Get-Content $file

$node = $xml.SelectNodes("//connectionStrings/add") | % {
    $_.ParentNode.RemoveChild($_)
}

$xml.Save($file)

Write-Host "*** DON'T FORGET: create a localhost database named: $newProjectName"
Write-Host "*** DON'T FORGET: publish your database project to your $newProjectName database"
Write-Host "*** DON'T FORGET: Remove and recreate $newProjectName`Entities.edmx in the Data project"

Read-Host "When you're done reviewing the above, press enter to exit"