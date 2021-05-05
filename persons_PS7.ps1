#Configuration
$config = ConvertFrom-Json $configuration;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

function Get-NextPageLink {
    Param (
        [string]$Link
    ) 
    if ($null -ne $Link -and "" -ne $Link) {
        return $Link.TrimStart('<').Remove($Link.LastIndexOf('>')).TrimEnd('>').Replace('cursor', 'paging.cursor');
    }
    else {
        return $null;
    }
}

#Build access token request
$tokenRequestUri = $config.Url + "/token";

$headers = @{
	'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $config.clientId,$config.secret)))
	'Accept' = 'application/JSON'
	'Content-Type' = 'application/x-www-form-urlencoded'
};	

$body = "grant_type=password&username=$($config.Key)&password=$($config.Password)";

#Request access token
$authResponse = Invoke-RestMethod -Method POST -Uri $tokenRequestUri -Headers $headers -Body $body -TimeoutSec 300;
$accessToken = $authResponse.access_token;

#Add the authorization header to the request
$authorization = @{
    Authorization = "Bearer $accesstoken";
    'Content-Type' = "application/json";
    Accept = "application/json";
};

#Get students
$students = @();
$studentsUri = $config.Url + "/v1/students?paging.limit=1000&paging.cursor=";
do { 
    $studentsResponse = Invoke-RestMethod -Method GET -Uri $studentsUri -Headers $authorization -ResponseHeadersVariable 'responseHeaders' -TimeoutSec 300;
    
    $students += $studentsResponse;
    
    $studentsUri = Get-NextPageLink -Link $responseHeaders.link;
}
while ($null -ne $studentsUri)

Write-Host "Students retrieved: $($students.Count)";

#Get schools
$schools = @();
$schoolsUri = $config.Url + "/v1/schools?paging.limit=1000&paging.cursor=";
do { 
    $schoolsResponse = Invoke-RestMethod -Method GET -Uri $schoolsUri -Headers $authorization -ResponseHeadersVariable 'responseHeaders' -TimeoutSec 300;
    
    $schools += $schoolsResponse;

    $schoolsUri = Get-NextPageLink -Link $responseHeaders.link;
}
while ($null -ne $schoolsUri)

Write-Host "Schools retrieved: $($schools.Count)";

foreach ($student in $students) {
    $person = $student;
    $person | Add-Member -Name "ExternalId" -Value $student.NameId -MemberType NoteProperty;
    $person | Add-Member -Name "DisplayName" -Value "$($student.FirstName) $($student.LastName)" -MemberType NoteProperty;

    #Add students schools to person object
    $studentSchools = @();
    foreach ($schoolId in $student.schoolIds) {
        $studentSchools += $schools | Where-Object { $_.SchoolId -eq $schoolId };
    }    
    $person | Add-Member -Name "Schools" -Value $studentSchools -MemberType NoteProperty;

    #Get enrollments and add to person object
    $enrollments = @();
    $enrollmentsUri = $config.Url + "/v1/students/$($student.NameId)/enrollments?paging.limit=1000&paging.cursor=";
    do { 
        $enrollmentsResponse = Invoke-RestMethod -Method GET -Uri $enrollmentsUri -Headers $authorization -ResponseHeadersVariable 'responseHeaders' -TimeoutSec 300;

        $enrollments += $enrollmentsResponse;
        
        $enrollmentsUri = Get-NextPageLink -Link $responseHeaders.link;
    }
    while ($null -ne $enrollmentsUri)

    #Add dummy contract for users with no enrollments
    if ($enrollments.Count -eq 0) {
        $dummyEnrollment = @{
            'EnrollmentId' = $null
            'CourseId' = $null
            'SectionId' = $null
            'SchoolId' = $null
            'NameId' = $null
            'EnrType' = $null
            'EnrStatus' = $null
            'StartDate' = '0001-01-01T00:00:00'
            'EndDate' = '0001-01-01T023:59:999'
            'ExternalId' = $student.NameId
        };
        $enrollments += $dummyEnrollment;
    }

    $enrollments | Add-Member -Name "ExternalId" -Value $student.NameId -MemberType NoteProperty;
    $person | Add-Member -Name "Contracts" -Value $enrollments -MemberType NoteProperty;
    
    Write-Output ($person | ConvertTo-Json -Depth 20);
}