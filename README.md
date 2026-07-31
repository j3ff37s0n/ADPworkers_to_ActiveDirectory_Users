# ADPworkers_to_ActiveDirectory_Users

Updates and creates Active Directory user accounts daily using ADP worker data when executed via Task Scheduler.

    [!IMPORTANT]
    Prerequisites: Requires PowerShell 7+ running with Administrator privileges on Windows. (Note: This script specifically requires PowerShell 7+ due to .NET cryptographic limitations present in Windows PowerShell 5.1).

ADP Certificate Setup Instructions

To establish secure communication with ADP's API, follow these steps to generate, format, and import the necessary networking certificate.
1. Generate the Certificate

    Obtain and download the certificate from api-central.adp.com.

    Note: ADP provides separate credentials for Development/Test and Production environments. Ensure you use the correct credentials for your target environment.

2. Store the Private Key

    Save the private key securely in 1Password under the ADP AD Integrations vault/folder.

3. Update the PEM File

    Open the .pem file in a plain text editor (such as Notepad).

    Append the private key to the very end of the .pem file.

        Why? This step is required so the certificate can later be converted to PFX format and imported directly into the server's Local Machine certificate store.

4. Copy the Certificate to the Server

    If you prepared the certificate on a machine other than the target server, securely copy the updated .pem file to the target server.

5. Import the Certificate

    Open PowerShell 7 or later with Administrator privileges.

    Run the script below. Replace <file-path> with the full path to your updated .pem file.

    When prompted, create a temporary password (must follow your organization's policy of 15+ characters). This password is only used temporarily during the PFX conversion and import process and does not need to be saved.

PowerShell

$p = Get-Credential;
[System.IO.File]::WriteAllBytes("$PWD/temp.pfx",
([System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPemFile("<file-path>")).Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx,
$p.GetNetworkCredential().Password));
Import-PfxCertificate -FilePath "$PWD/temp.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $p.Password;
Remove-Item "$PWD/temp.pfx"

6. Update the Certificate Thumbprint

    Navigate to the script directory corresponding to your target environment (C:\scripts\ADP for DEV or PROD).

    Search for the thumbprint variable (Ctrl + F).

    Replace the old thumbprint value with the thumbprint of the newly imported certificate.

        Caution: Certificates generated for the Development environment will not work in Production, and vice versa. Ensure you match the correct environment.
