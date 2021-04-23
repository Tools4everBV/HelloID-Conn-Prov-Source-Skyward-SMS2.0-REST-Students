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

#Get schools
$schools = @();
$schoolsUri = $config.Url + "/v1/schools?paging.limit=1000&paging.cursor=";
do { 
    $schoolsResponse = Invoke-RestMethod -Method GET -Uri $schoolsUri -Headers $authorization -ResponseHeadersVariable 'responseHeaders' -TimeoutSec 300;
    
    $schools += $schoolsResponse;
    
    $schoolsUri = Get-NextPageLink -Link $responseHeaders.link;
}
while ($null -ne $schoolsUri)

foreach ($school in $schools) {
    $school | Add-Member -Name "ExternalId" -Value $school.SchoolId -MemberType NoteProperty;
    $school | Add-Member -Name "DisplayName" -Value $school.SchoolName -MemberType NoteProperty;

    Write-Output ($school | ConvertTo-Json -Depth 20);
}