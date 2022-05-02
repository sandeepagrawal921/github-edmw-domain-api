param 
(
    [Parameter(Mandatory=$true)]$gitBranchName,
    [Parameter(Mandatory=$true)]$awsS3Bucket,
    [Parameter(Mandatory=$true)]$publishPath
)


function Write-ArtifactsMaster($gitBranchName, $awsS3Bucket)
{
  $s3 = "s3://" + $awsS3Bucket + "/DomainValueApiService/" + $gitBranchName

  Write-Host "Uploading artifacts to S3:  $s3"

  Write-S3Object -BucketName $awsS3Bucket -Folder "$publishPath" -KeyPrefix DomainValueApiService\$gitBranchName\ -Recurse
}


function Write-ArtifactsDevelop($gitBranchName, $awsS3Bucket)
{
  $s3 = "s3://" + $awsS3Bucket + "/DomainValueApiService/" + $gitBranchName  # To Do -- discuss version 

  Write-Host "Uploading artifacts to S3:  $s3"

  Write-S3Object -BucketName $awsS3Bucket -Folder "$publishPath" -KeyPrefix DomainValueApiService\$gitBranchName\ -Recurse
}


function Write-ArtifactsRelease($gitBranchName, $awsS3Bucket) # To Do -- discuss version 
{
  $s3 = "s3://" + $awsS3Bucket + "/DomainValueApiService/" + "Release/" + $gitBranchName

  Write-Host "Uploading artifacts to S3:  $s3"

  Write-S3Object -BucketName $awsS3Bucket -Folder "$publishPath" -KeyPrefix DomainValueApiService\$gitBranchName\ -Recurse
}

function Write-ArtifactsFeatureBranch($gitBranchName, $awsS3Bucket)
{
  $s3 = "s3://" + $awsS3Bucket + "/DomainValueApiService/" + "feature/" + $gitBranchName

  Write-Host "Uploading artifacts to S3:  $s3"

  Write-S3Object -BucketName $awsS3Bucket -Folder "$publishPath" -KeyPrefix DomainValueApiService\feature\$gitBranchName\ -Recurse
}

function Write-AWSS3($gitBranchName, $awsS3Bucket)
{
   switch ($gitBranchName)
   {
      "master"  {
                   Write-ArtifactsMaster $gitBranchName $awsS3Bucket
                   break
                }

      "develop" { 
                   Write-ArtifactsDevelop $gitBranchName $awsS3Bucket
                   break
                }

      "Release" { 
                   Write-ArtifactsRelease $gitBranchName $awsS3Bucket
                   break
                }

      default   { 
                   if($gitBranchName.Contains('feature/'))
                    {
                      $branchName= $gitBranchName.Split('/')
                      $gitBranchName = $branchName[1]
                    }
                   
                   if($gitBranchName.Contains('Release'))
                   {
                      Write-ArtifactsRelease $gitBranchName $awsS3Bucket
                              }
                   else
                   {
                      Write-Host "BranchName: $gitBranchName and AWSS3: $awsS3Bucket "
                      Write-ArtifactsFeatureBranch $gitBranchName $awsS3Bucket
                              }
                   
                   break  
                }
   }
}


Write-AWSS3 $gitBranchName $awsS3Bucket
