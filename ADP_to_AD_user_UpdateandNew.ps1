#jeffersonpengJune2026
#ADP to AD for new users/edits, sends back user employee business email
#starting the main script here to grab records from adp and push updates into active directory

#Import-Module ActiveDirectory import on an AD server if not already completed

###################################
#add number to email address till new
#====================================

function newUniqueEmail {

    param (
    [string]$email
    )

    $name, $domain = $email -split '@'
    $num = 1

#keep looping and adding numbers until we find an email thats not taken yet

    do{
    
    $emailCheck = if($num -eq 1){ $email } else{ "$($name)$($num)@$($domain)" }
    #$userNameVaue = "$($name)$($num)"
    $usercheck = Get-ADuser -Filter "samAccountName -eq '$emailCheck'" -ErrorAction SilentlyContinue #change to $userNameValue when live
    $num++

    }
    while ($null -ne $usercheck)
    
    return $emailCheck

}

#======================================
###################################
#random password
#====================================

function randomPass {

#setting the length for temporary passwords

    $length = 16;

#making a random string using letters and numbers

    $pass = -join (
        (65..90) + (97..122) + (48..57) |
        Get-Random -Count $length |
        ForEach-Object { [char]$_ }
    );

    return $pass;
};

###############################
#cleanup csv exports older than 60 days
#=======================================

#clearing out old csv logs so the folder doesnt get too cluttered

Get-ChildItem "C:\Scripts\ADP\60_day_report\*ADP*.csv" -ErrorAction SilentlyContinue |
Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-60) } |
Remove-Item -Force

##############################
# FUNCTION TO CREATE OR UPDATE USERS
#=================================

function New-ADuserbyEmployeeID {

    param (
        [string]$employeeID,
        [string]$FirstName,
        [string]$LastName,
        [string]$department,
        [string]$jobTitle,
        [string]$description,
        [string]$terminationDate,
        [string]$personalEmail,
        [string]$manager,
        [string]$personalNumber,
        [string]$hrStatus,
        [string]$streetAddress,
        [string]$city,
        [string]$state,
        [string]$postalCode,
        [string]$country,
        [string]$companyStreet,
        [string]$companyCity,
        [string]$companyState,
        [string]$companyPostalCode,
        [string]$companyCountry,
    [string]$token,
    [string]$associateOID
    )

#skipping test accounts that start with 19999

    if($employeeID -like "19999*") {return;}

    $reportDate = [System.DateTime]::UtcNow.ToString("yyyy-MM-dd")
    $rdate = $reportDate -replace ':', '-'
    $rfile = "C:\Scripts\ADP\60_day_report\NewADUsersImported_ADP_$($rdate).csv"

#cleaning weird characters out of names so AD doesnt break

    $FirstName = -join ($FirstName.ToCharArray() | Where-Object {
        [int][char]$_ -ge 32 -and [int][char]$_ -le 126
    }) -replace '[^a-zA-Z ]',''

    $LastName = -join ($LastName.ToCharArray() | Where-Object {
        [int][char]$_ -ge 32 -and [int][char]$_ -le 126
    }) -replace '[^a-zA-Z ]',''

    $employeeID = $employeeID.Trim() -replace '[^0-9]', ''

#assign user variables for AD

    $userName = ($FirstName +"."+ $LastName) -replace '\s','' -replace '\.+','.' -replace "'",""

    $email = ($FirstName + "." + $LastName + "@transpak.com") -replace '\s','' -replace '\.+','.'

    $Name = "$FirstName $LastName".Trim()

    $Name = -join ($Name.ToCharArray() | Where-Object {
        [int][char]$_ -ge 32 -and [int][char]$_ -le 126
    })

    $Name = $Name -replace '([,\\#+="<>;/|?*])', ''



    $usercheck = Get-ADuser -Filter "samAccountName -eq '$userName'" -ErrorAction SilentlyContinue

    $dManager = Get-ADuser -Filter "employeeID -eq '$manager'" -Properties distinguishedName

#spalt for new user

#putting all user properties into a hashtable for AD creation

    $NewADUser = @{

        Name                    = $Name
        GivenName           = $FirstName
        Surname             = $LastName
        EmployeeID          = $employeeID

        SamAccountName      = $userName.Trim().Substring(
                                    0,
                                    [math]::Min(20,$userName.Trim().Length)
                                )

        UserPrincipalName   = $email
        EmailAddress        = $email
    DisplayName         = "$($FirstName) $($LastName)"
        AccountPassword     = (
                                    ConvertTo-SecureString (
                                        randomPass
                                    ) -AsPlainText -Force
                                )

        Enabled             = $false

        Path                = "OU=HR-Software-User-Auto-Import,OU=Locations,DC=transpak,DC=com"

        Department          = $department
        Title               = $jobTitle
        Description         = $description

        Mobile              = $personalNumber

        Manager             = $dManager.DistinguishedName

        StreetAddress       = $streetAddress
        City                = $city
        State               = $state
        PostalCode          = $postalCode
        Country             = $country

        Office              = $companyCity

        Company             = "TransPak"

        OtherAttributes     = @{
            extensionAttribute5 = $hrStatus
        }
    }

#Check if it is a new user for new user addition

    $user = Get-ADuser -Filter "employeeID -eq '$employeeID'" -Properties employeeID, distinguishedName, emailAddress

    

    if ($user) {

        Write-Host "This employee ID $($employeeID) already exists"

        try {

    write-host "check that $($user.distinguishedName) exists 1" #remove!!! or comment out
        #Set-ADUser -Identity $user.distinguishedName -EmployeeID $employeeID -Department $department -Title $jobTitle -Description $description -Mobile $personalNumber -StreetAddress $streetAddress -City $city -State $state -PostalCode $postalCode -Country $country -Manager $dManager.DistinguishedName -Replace @{extensionAttribute5 = $hrStatus}
        if ($department) { Set-ADUser -Identity $user.DistinguishedName -Replace @{department = $department} }

        if ($jobTitle) { Set-ADUser -Identity $user.DistinguishedName -Replace @{title = $jobTitle}}

        if ($description) { Set-ADUser -Identity $user.DistinguishedName -Replace @{description = $description}}

        if ($personalNumber) { Set-ADUser -Identity $user.DistinguishedName -Replace @{mobile = $personalNumber}}

        if ($streetAddress) { Set-ADUser -Identity $user.DistinguishedName -Replace @{streetAddress = $streetAddress}}

        if ($city) { Set-ADUser -Identity $user.DistinguishedName -Replace @{l = $city}}

        if ($state) { Set-ADUser -Identity $user.DistinguishedName -Replace @{st = $state}}

        if ($postalCode) { Set-ADUser -Identity $user.DistinguishedName -Replace @{postalCode = $postalCode}}

        if ($country) { Set-ADUser -Identity $user.DistinguishedName -Replace @{c = $country}}
        
        if ($dManager) { Set-ADUser -Identity $user.DistinguishedName -Replace @{manager = $dManager.DistinguishedName}}

        if ($hrStatus) { Set-ADUser -Identity $user.DistinguishedName -Replace @{extensionAttribute5 = $hrStatus}; if ($hrStatus -eq "Terminated"){Set-ADAccountPassword -Identity $user.DistinguishedName -NewPassword $AccountPassword -Reset -whatif} }

        Add-ADGroupMember -Identity "CN=SG-Moodle,OU=Moodle,OU=Security Groups,DC=transpak,DC=com" -Members $user.distinguishedName -whatif
    
        Set-ADPCompanyEmail -associateOID $associateOID -companyEmail $user.emailAddress -token $token    
            $result = "Updated Existing User"

        }
        catch {

            $result = "Update Failed"

        }

    }

#create the new user block

    else {

        if($usercheck){

            write-host "Username already exists"
        #newUniqueEmail -email $userName
        #update block here that will make a new user once username is checked by updating the splat, this would be try block below combination, ONLY AFTER ALL EMPLOYEE IDS ARE CORRECT
            $result = "Username already exists, user details not updated, mismatch with employeeID"
    
    $emailUpdate = newUniqueEmail -email $email
    $userNameUpdate = $emailUpdate.Split("@")[0]
    
    write-host "Old username was $($email) and new username is $($userNameUpdate), new email is $($emailUpdate)"
    
    $NewADUser = @{

        Name                    = $Name
        GivenName           = $FirstName
        Surname             = $LastName
        EmployeeID          = $employeeID

        SamAccountName      = $userNameUpdate
        UserPrincipalName   = $emailUpdate
        EmailAddress        = $emailUpdate
    DisplayName         = "$($FirstName) $($LastName)"

        AccountPassword     = (ConvertTo-SecureString (randomPass) -AsPlainText -Force)

        Enabled             = $false

        Path                = "OU=HR-Software-User-Auto-Import,OU=Locations,DC=transpak,DC=com"

        Department          = $department
        Title               = $jobTitle
        Description         = $description

        Mobile              = $personalNumber

        Manager             = $dManager.DistinguishedName

        StreetAddress       = $streetAddress
        City                = $city
        State               = $state
        PostalCode          = $postalCode
        Country             = $country

        Office              = $companyCity

        Company             = "TransPak"

        OtherAttributes     = @{
            extensionAttribute5 = $hrStatus
        }
    }

    #Set-ADUser -Identity $user.distinguishedName -EmployeeID $employeeID #remove when dayforce2adp complete!!! or comment out -whatif
    if ($hrStatus -ne "Terminated") { try {New-ADUser @NewADUser ; $result = "Success"; Set-ADPCompanyEmail -associateOID $associateOID -companyEmail $user.emailAddress -token $token} 
                    catch { $result = "Failed to make new user: $($emailUpdate) and email for different user similar $($username) and $($email)"} }

        }

        else {

            try {

               if ($hrStatus -ne "Terminated") { New-ADUser @NewADUser ; $result = "Success"; Set-ADPCompanyEmail -associateOID $associateOID -companyEmail $user.emailAddress -token $token}
                 write-host "check that $($user.distinguishedName) exists 3" #remove!!! or comment out

                Write-Host "New User Created"

            }

            catch {

                $result = "Failed after Termination Check"

            }

        }

    }

#generate a report

#building the object to export the results to our log csv

    $csvObj = [PSCustomObject]@{

        EmployeeID    = $employeeID
        FirstName     = $FirstName
        LastName      = $LastName
        JobTitle      = $jobTitle
        Department    = $department
        Manager       = $manager
        HRStatus      = $hrStatus    
        ADAutoResult  = $result

    }

    $csvObj | Export-Csv -Path $rfile -NoTypeInformation -Append



}

####################################
#function to send business email back to adp
#=====================================

function Set-ADPCompanyEmail {



param(
        [string]$associateOID,
        [string]$companyEmail,
        [string]$token 
    )

    # Define headers and certificate based on variables above
    $headers = @{
        "Authorization" = "Bearer $token"
        "roleCode"      = "employee"
    "content-type"    = "application/json"
    }
#grab the certificate using the thumbprint var
$cert = Get-ChildItem -Path Cert:\LocalMachine\My\$thumbprint

#variables 
$thumbprint = "5067D109C40E5E7DAFCEB75EAFD19DADE4D651D0"
$clientId = "5fb56167-6a33-4058-a935-8f5e0a36f7bd"
$cert = Get-ChildItem -Path Cert:\LocalMachine\My\$thumbprint

    $emailBody = @{
        events = @(
            @{
                data = @{
            eventContext = @{
                worker = @{
                    associateOID = $associateOID
                }
            }
        
                    transform = @{
                            worker = @{
                    businessCommunication = @{
                        email = @{
                            emailUri = $companyEmail
                        }
                    }
                }
            }
        }
            actor = @{
                associateOID = $associateOID
            }
            serviceCategoryCode = @{
                codeValue = "workerInformationManagement"
            }
            eventNameCode = @{
                codeValue = "worker.businessCommunication.email.add"
            }
    })} | convertto-json -depth 10
    
                        

    try {

        Invoke-RestMethod `
            -Uri "https://api.adp.com/events/hr/v1/worker.business-communication.email.add" `
            -Method Post `
            -Headers $headers `
            -Certificate $cert `
            -Body $emailBody `

        Invoke-RestMethod `
            -Uri "https://api.adp.com/events/hr/v1/worker.business-communication.email.change" `
            -Method Post `
            -Headers $headers `
            -Certificate $cert `
            -Body $emailBody `
           

        Write-Host "$companyEmail pushed to ADP"

    }

    catch {

        Write-Warning "Failed to push email to ADP: $($_.Exception.Message)"


    }

}


#########################################
#adp api calls, all functions above
#=========================================

#setup variabels for calls
#variables 
$thumbprint = "shhhh"
$clientId = "shhhh"
$key = Get-Content 'C:\Scripts\ADP\aes_adp_prod.key' #make this
$pHold = Get-Content 'C:\Scripts\ADP\adp_client_secret_prod.enc' -Raw
$pTrans = $pHold | ConvertTo-SecureString -Key $key
$pNor = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pTrans)
$clientSecret = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pNor)

[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pNor)

$tokenUrl = "https://accounts.adp.com/auth/oauth/v2/token"

#path to certificate
$cert = Get-ChildItem -Path Cert:\LocalMachine\My\$thumbprint

#post body for token grant_type and client_id
$body = @{
    grant_type = "client_credentials"
    client_id  = $clientId
    client_secret = $clientSecret
}

#get token
$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -Certificate $cert

#bearer token
#$tokenResponse.access_token

##Set the date range to collect employee data###

$time  = "Years" #Days, Months, or Years#
$timeCount = 50

$startDate = switch ($time) {
    "Days"   { (Get-Date).AddDays(-$timeCount) }
    "Months" { (Get-Date).AddMonths(-$timeCount) }
    "Years"  { (Get-Date).AddYears(-$timeCount) }
}

#today
$endDate = Get-Date

#format to string
$startDateString = $startDate.ToString("yyyy-MM-dd")
$endDateString   = $endDate.ToString("yyyy-MM-dd")
$filter = "workers/workerDates/originalHireDate ge '$startDateString' and workers/workerDates/originalHireDate lt '$endDateString'"

$urlFilter = [System.Web.HttpUtility]::UrlEncode($filter)

$top = 100
$skip = 0

$workers = @()

$headers = @{
    Authorization = "Bearer $($tokenResponse.access_token)"
    Accept        = "application/json"
}

#paging through results in batches since adp has limits on how many records come back at once

do {

    $workersUrl = "https://api.adp.com/hr/v2/workers?`$top=$top&`$skip=$skip&`$filter=$urlFilter"

    Write-Host "Getting workers: skip=$skip"

    $workerResponse = Invoke-RestMethod `
        -Uri $workersUrl `
        -Method Get `
        -Headers $headers `
        -Certificate $cert

    if ($workerResponse.workers) {

        $workers += $workerResponse.workers

        $returnedCount = $workerResponse.workers.Count

    }

    else {

        $returnedCount = 0

    }

    $skip += $top

} while ($returnedCount -eq $top)

#process each user

foreach ($worker in $workers) {

    try {

    #user details for AD

        $employeeID = $worker.workerID.idValue
    
        $FirstName = $worker.person.legalName.givenName
        $LastName  = $worker.person.legalName.familyName1

        $jobTitle = $worker.workAssignments[0].jobTitle

        $department = "$($worker.workAssignments[0].assignmentCostCenters.costCenterName) ($($worker.workAssignments[0].assignmentCostCenters.costCenterID))"

        $description = "$($workers.workAssignments[0].assignedOrganizationalUnits.nameCode.longName) - $($workers.workAssignments[0].assignedWorkLocations.nameCode.shortName) $($worker.workAssignments[0].jobTitle)"

        $manager = $worker.workAssignments[0].reportsTo[0].workerID.idValue

        $hrStatus = $worker.workerStatus.statusCode.codeValue
    
    #contact info

        $personalEmail = $worker.person.communication.emails.emailUri

        $personalNumber = $worker.person.communication.mobile.formattedNumber

    #home address

        $streetAddress = $worker.person.legalAddress.lineOne
        $city          = $worker.person.legalAddress.cityName
        $state         = $worker.person.legalAddress.countrySubdivisionLevel1.codeValue
        $postalCode    = $worker.person.legalAddress.postalCode
        $country       = $worker.person.legalAddress.countryCode

    #work location

        $companyStreet = $worker.workAssignments[0].assignedWorkLocations[0].address.lineOne
        $companyCity   = $worker.workAssignments[0].assignedWorkLocations[0].address.cityName
        $companyState  = $worker.workAssignments[0].assignedWorkLocations[0].address.countrySubdivisionLevel1.codeValue
        $companyPostalCode = $worker.workAssignments[0].assignedWorkLocations[0].address.postalCode
        $companyCountry = $worker.workAssignments[0].assignedWorkLocations[0].address.countryCode

    #ADP specefic info
    $associateOID = $worker.associateOID

    #send to function for AD User

        New-ADuserbyEmployeeID `
            -employeeID $employeeID `
            -FirstName $FirstName `
            -LastName $LastName `
            -department $department `
            -jobTitle $jobTitle `
            -description $description `
            -personalEmail $personalEmail `
            -manager $manager `
            -personalNumber $personalNumber `
            -hrStatus $hrStatus `
            -streetAddress $streetAddress `
            -city $city `
            -state $state `
            -postalCode $postalCode `
            -country $country `
            -companyStreet $companyStreet `
            -companyCity $companyCity `
            -companyState $companyState `
            -companyPostalCode $companyPostalCode `
            -companyCountry $companyCountry `
        -token $tokenResponse.access_token`
        -associateOID $associateOID

    #Set-ADPCompanyEmail -associateOID $associateOID -companyEmail $email -token $token

    }

    catch {

        Write-Warning "Failed processing employee: $($_.Exception.Message) | $($employeeID), $($associateOID), $($tokenResponse.access_token), `
            ($companyCountry), $($companyPostalCode), $($companyState), $($companyCity), $($companyStreet), $($country), $($postalCode),`
             $($state), $($city), $($streetAddress), $($hrStatus), $($personalNumber), $($manager), $($personalEmail), $($personalEmail), $($description), $($jobTitle), $($department), $($LastName), $($FirstName)"


    }

}
