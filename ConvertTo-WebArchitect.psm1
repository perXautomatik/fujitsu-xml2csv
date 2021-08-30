<#
.Synopsis
Convert Fujitsu XML to CSV format

.Description
The `ConvertTo-WebArchitect` cmdlet import transaction Fujitsu XML into a series of character-separated value (CSV) strings.

.Parameter InputObject
Specifies the objects that are converted to CSV strings. Enter a variable that contains the objects or type a command or expression that gets the objects.

.Parameter OutputObject
Specifies the output filename of CSV.

.Parameter Token
File path of WebArchitect master database.

.Example
ConvertTo-WebArchitect -inFile input.xml

.LINK
Project homepage: https://github.com/scout249/fujitsu-xml2csv

#>

#Installation
#Install-Module -Name JoinModule

function Convert-WebArchitect {

[CmdletBinding()]
Param(
    [string]$inFile,
    [string]$outFile,
    [switch]$master
)

$path = [Environment]::GetFolderPath('ApplicationData')
$Colors = @{
ForegroundColor = "White"
BackgroundColor = "Red"
}

if ($master -ne $true) {
    if ((Test-Path "$path\WebArchitectMaster.txt") -ne $true) {
      Write-Host "Please run 'Convert-WebArchitect -master' to provide master database (Missing)" @colors
    }
    elseif ($inFile -eq '') {
      Write-Host "Please run 'Convert-WebArchitect -inFile <<YOUR XML FILE>>' to convert to CSV (Missing)" @colors
    }
    else {
      ## Define variables
      $masterFile = gc "$path\WebArchitectMaster.txt"

            #Define Variable
            #$baseDir = "C:\XML2CSV"
            #$inFile = "Multi Configuration.xml"
            $outFile = -join($inFile, ".csv")
            $temp = "temp.txt"

            #Remove <Components> Tag
            (gc $inFile -raw) | % {
                $_ -replace '</Components>\s*</Component>' `
                   -replace '<Components>', '</Component>'
                } | sc $temp

            #Convert XML to CSV
            [xml]$xmlin = Get-Content $temp
            $xmlin.Order.Systems.Component | select `
                @{N="Product Name"; E={$_.name}},
                @{N="Part Number"; E={$_.SachNr}},
                @{N="Quantity"; E={$_.Count}},
                @{N="Unit Price"; E={"0"}} | epcsv $outFile -NoTypeInformation


            #Merge Tables
            $importMaster = ipcsv $masterFile | 
                Select "Part Number", "CP Figure Number"
            ipcsv $outFile | 
                InnerJoin $importMaster -On "Part Number" | 
                Select "Product Name", "Part Number", "CP Figure Number", "Quantity", "Unit Price" | 
                epcsv temp.txt -NoTypeInformation

            #Append to CSV file
            ac $temp ",,,,Total Price`n,,,,0"
            del $outFile
            rni $temp $outFile
            
           }
}


}
Export-ModuleMember -Function ConvertTo-WebArchitect