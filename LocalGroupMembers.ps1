<#Author   : Kugan
# Creation Date: 12-12-2019 
# Usage      : Local Security Group Users Export
#**************************************************************************
# Date                     Version      Changes
#------------------------------------------------------------------------
# 09-01-2020                1.0       Intial Version
#***************************************************************************
#>


$strComputer = get-content env:computername #Enter the name of the target computer, localhost is used by default
Write-Host "Computer: $strComputer"
$computer = [ADSI]"WinNT://$strComputer"
$objCount = ($computer.psbase.children | measure-object).count
Write-Host "Q-ty objects for computer '$strComputer' = $objCount"
$Counter = 1
$result = @()
foreach($adsiObj in $computer.psbase.children)
{
  switch -regex($adsiObj.psbase.SchemaClassName)
    {
      "group"
      {
        $group = $adsiObj.name
        $LocalGroup = [ADSI]"WinNT://$strComputer/$group,group"
        $Members = @($LocalGroup.psbase.Invoke("Members"))
        $objCount = ($Members | measure-object).count
        Write-Host "Q-ty objects for group '$group' = $objCount"
        $GName = $group.tostring()

        ForEach ($Member In $Members) {
          $Name = $Member.GetType().InvokeMember("Name", "GetProperty", $Null, $Member, $Null)
          $Path = $Member.GetType().InvokeMember("ADsPath", "GetProperty", $Null, $Member, $Null)
          Write-Host " Object = $Path"

                   $isGroup = ($Member.GetType().InvokeMember("Class", "GetProperty", $Null, $Member, $Null) -eq "group")
          If (($Path -like "*/$strComputer/*") -Or ($Path -like "WinNT://NT*")) { $Type = "Local"
          } Else {$Type = "Domain"}
          $result += New-Object PSObject -Property @{
            Computername = $strComputer
            NameMember = $Name
            PathMember = $Path
            TypeMemeber = $Type
            ParentGroup = $GName
            isGroupMemeber = $isGroup
            Depth = $Counter
          }
        }
      }
    } #end switch
} #end foreach
Write-Host "Total objects = " ($result | measure-object).count
$result = $result | select-object Computername, ParentGroup, NameMember, TypeMemeber, PathMember, isGroupMemeber, Depth
$result | Export-Csv -path ("C:\LocalGroups({0})-{1:yyyyMMddHHmm}.csv" -f
$env:COMPUTERNAME,(Get-Date)) -Delimiter ";" -Encoding "UTF8" -force -NoTypeInformation
