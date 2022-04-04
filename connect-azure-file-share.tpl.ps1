$connectTestResult = Test-NetConnection -ComputerName ${storage_account_file_host} -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    cmd.exe /C "cmdkey /add:`"${storage_account_file_host}`" /user:`"Azure\${storage_account_name}`" /pass:`"${storage_account_key}`""
    New-PSDrive -Name ${drive_letter} -PSProvider FileSystem -Root "\\${storage_account_file_host}\${file_share_name}" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}