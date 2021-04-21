#Configuration
$config = ConvertFrom-Json $configuration;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

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

    if ($null -ne $responseHeaders.link) {
        $link = $responseHeaders.link;
        $studentsUri = $link.TrimStart('<').Remove($link.LastIndexOf('>')).TrimEnd('>').Replace('cursor', 'paging.cursor');
    }
    else {
        $studentsUri = $null;
    }
}
while ($null -ne $studentsUri)

Write-Host "Students retrieved: $($students.Count)";

#Get schools
$schools = @();
$schoolsUri = $config.Url + "/v1/schools?paging.limit=1000&paging.cursor=";
do { 
    $schoolsResponse = Invoke-RestMethod -Method GET -Uri $schoolsUri -Headers $authorization -ResponseHeadersVariable 'responseHeaders' -TimeoutSec 300;
    
    $schools += $schoolsResponse;

    if ($null -ne $responseHeaders.link) {
        $link = $responseHeaders.link;
        $schoolsUri = $link.TrimStart('<').Remove($link.LastIndexOf('>')).TrimEnd('>').Replace('cursor', 'paging.cursor');
    }
    else {
        $schoolsUri = $null;
    }
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

        if ($null -ne $responseHeaders.link) {
            $link = $responseHeaders.link;
            $enrollmentsUri = $link.TrimStart('<').Remove($link.LastIndexOf('>')).TrimEnd('>').Replace('cursor', 'paging.cursor');
        }
        else {
            $enrollmentsUri = $null;
        }
    }
    while ($null -ne $enrollmentsUri)

    $enrollments | Add-Member -Name "ExternalId" -Value $student.NameId -MemberType NoteProperty;
    $person | Add-Member -Name "Contracts" -Value $enrollments -MemberType NoteProperty;
    
    Write-Output ($person | ConvertTo-Json -Depth 20);
}