# inspired from https://smsagent.blog/2014/02/07/installing-and-configuring-wsus-with-powershell/
# Create Database folder
New-Item -Path C: -Name WSUS -ItemType Directory -Force
# Install Wsus
Install-WindowsFeature -Name UpdateServices -IncludeManagementTools
