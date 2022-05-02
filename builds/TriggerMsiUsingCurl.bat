echo "Calling curl to trigger msi build"

if "%~1" == "" goto PARAMS
if "%~2" == "" goto PARAMS

SET APIBRANCHNAME=%~1
SET MSIBRANCHNAME=%~2

echo curl parameters %APIBRANCHNAME% %MSIBRANCHNAME%

curl --request POST --form token=0daee3189ca43b9dfc649e5937dabb --form variables[BRANCH_NAME]=%APIBRANCHNAME% --form ref=%MSIBRANCHNAME% -k https://git.mdevlab.com/api/v4/projects/20054/trigger/pipeline


:PARAMS

echo Usage TriggerMsiUsingCurl.bat "feature/artifactsS31" "feature/EWR-16630-advanced-installer"

:END