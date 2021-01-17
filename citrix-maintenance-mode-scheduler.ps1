#Requires -Version 3
function New-DialogBox {
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [ValidateSet('Asterisk', 'Error', 'Exclamation', 'Hand', 'Information', 'None', 'Question', 'Stop', 'Warning')]
        [string]$MessageBoxIcon,

        [Parameter(Mandatory)]
        [ValidateSet('AbortRetryIgnore', 'OK', 'OKCancel', 'RetryCancel', 'YesNo', 'YesNoCancel')]
        [string]$MessageBoxButtons = 'OK'
    )

    $Icon = [System.Windows.Forms.MessageBoxIcon]::$MessageBoxIcon
    
    return [System.Windows.Forms.MessageBox]::Show($Message, $Title, $MessageBoxButtons, $Icon)
}

function Load-OptionsFile {
    try {
        if (-not(Test-Path (Join-Path $PSScriptRoot config.json))) {
            New-DialogBox -Message $Error[0].Exception.Message -Title 'Options.json File Not Found' -MessageBoxIcon Error -MessageBoxButtons OK
            Exit    
        }
        $Json = Get-Content (Join-Path $PSScriptRoot options.json) | Out-String | ConvertFrom-Json
    }
    catch {
        New-DialogBox -Message $Error[0].Exception.Message -Title 'Unhandled Exception' -MessageBoxIcon Error -MessageBoxButtons OK
        Exit
    }
}

[xml]$XAML_Form = Get-Content -Raw (Join-Path $PSScriptRoot Main_Window.xaml)
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles() | Out-Null

try {
    $XML_Node_Reader = (New-Object System.Xml.XmlNodeReader $XAML_Form)
    $Form = [Windows.Markup.XamlReader]::Load($XML_Node_Reader)
}
catch {
    New-DialogBox -Title 'Unhandled Exception' -Message $Error[0].Exception.Message -MessageBoxIcon Error -MessageBoxButtons OK
    Exit
}

$XAML_Form.SelectNodes('//*[@Name]') | ForEach-Object {
    Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name) -Scope Script
}

$Form.ShowDialog() | Out-Null