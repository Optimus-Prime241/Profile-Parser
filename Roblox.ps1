# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Cod PC CHECK"
$form.Width = 500
$form.Height = 400
$form.StartPosition = 'CenterScreen'  # Center the form

# Create controls
$processButton = New-Object System.Windows.Forms.Button
$processButton.Text = "Get Logs"
$processButton.Width = 150
$processButton.Height = 30
$processButton.Location = New-Object System.Drawing.Point(50, 50)

$logsTextBox = New-Object System.Windows.Forms.TextBox
$logsTextBox.Width = 300
$logsTextBox.Height = 30
$logsTextBox.Location = New-Object System.Drawing.Point(220, 50)
$logsTextBox.ReadOnly = $true  # Make it read-only since we auto-fill the path

# Create RichTextBox control for displaying results
$richTextBox = New-Object System.Windows.Forms.RichTextBox
$richTextBox.Width = 400
$richTextBox.Height = 200
$richTextBox.Location = New-Object System.Drawing.Point(50, 100)
$richTextBox.DetectUrls = $true  # Enable URL detection

# Add controls to the form
$form.Controls.Add($processButton)
$form.Controls.Add($logsTextBox)
$form.Controls.Add($richTextBox)

# Automatically set the path to the Roblox logs folder
$logsFolder = "C:\Users\$env:USERNAME\AppData\Local\Roblox\logs"
$logsTextBox.Text = $logsFolder  # Display it in the text box

# Add event handler for Process button click
$processButton.Add_Click({
    if (-not (Test-Path -Path $logsFolder -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show("Roblox logs folder not found.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $pattern = 'userid:\s*(\d+)'  # Adjusted for numeric IDs
    $fileCount = 0
    $userIds = New-Object System.Collections.Generic.HashSet[string]

    # Process .txt and .log files
    $files = Get-ChildItem -Path $logsFolder -File -Recurse -Include *.txt, *.log
    if ($files.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No .txt or .log files found in the Roblox logs folder.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    foreach ($file in $files) {
        try {
            $fileContents = Get-Content -Path $file.FullName -Raw  # Read entire file at once
            $matches = [regex]::Matches($fileContents, $pattern)
            foreach ($match in $matches) {
                [void]$userIds.Add($match.Groups[1].Value)
            }
        } catch {
            Write-Output "Error processing $($file.Name): $_"
        }
        $fileCount++
    }

    if ($userIds.Count -eq 0) {
        $richTextBox.Text = "`nNo User IDs found in any file."
    } else {
        $userLinks = $userIds | ForEach-Object { "https://www.roblox.com/users/$_/profile" }
        $userLinksText = ($userLinks | ForEach-Object { "$($_)" }) -join "`n`n"
        $richTextBox.Text = "`nProcessed $fileCount .txt and .log files:`n`n$userLinksText"
    }

    [System.Windows.Forms.MessageBox]::Show("`nProcessed $fileCount .txt and .log files.", "Processing Complete")
})

# Add event handler for RichTextBox LinkClicked event
$richTextBox.add_LinkClicked({
    param([System.Object]$sender, [System.Windows.Forms.LinkClickedEventArgs]$e)
    [System.Diagnostics.Process]::Start($e.LinkText)
})

# Start the form
[Windows.Forms.Application]::Run($form)
