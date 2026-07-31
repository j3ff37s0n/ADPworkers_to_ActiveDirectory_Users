# ADPworkers_to_ActiveDirectory_Users
Updates/creates ADP workers to Active Directory Daily when run with task scheduler
Requires powershell 7+

Steps necessary to generate a new certificate for networking:
ADP Certificate Setup Instructions
Generate the certificate
Generate and obtain the certificate from api-central.adp.com.
ADP provides separate credentials for Development/Test and Production environments.
Store the private key
Save the private key in 1Password under the ADP AD Integrations vault/folder.
Update the PEM file
Open the .pem file in Notepad (or another plain text editor).
Append the private key to the end of the .pem file.
This step is required so the certificate can later be converted to PFX format and imported into the server's Local Machine certificate store.
Copy the certificate to the server
If the certificate preparation was completed on another machine, copy the updated .pem file to the target server.
Import the certificate
$p = Get-Credential;
[System.IO.File]::WriteAllBytes("$PWD/temp.pfx",
([System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPemFile("<file-path>")).Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx,
$p.GetNetworkCredential().Password));
Import-PfxCertificate -FilePath "$PWD/temp.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $p.Password;
Remove-Item "$PWD/temp.pfx"
Open PowerShell 7 or later with Administrator privileges.
This will only work with windows 7 because of the .net limitations of PS5+.
Replace <file-path> in the command below with the full path to the updated .pem file.
You will be prompted to create a temporary password, which is used only during the PFX conversion and import process. No need to preserve; it functions to encrypt the pfx during this process only.
Please follow our password policy of 15+ characters
Update the certificate thumbprint
Navigate to the appropriate script in C:\scripts\ADP for the target environment (DEV or PROD).
Search for thumbprint (Ctrl + F).
Update thumbprint values with the thumbprint of the newly imported certificate depending on which environment. Cert from dev will not work in prod and vice versa.
