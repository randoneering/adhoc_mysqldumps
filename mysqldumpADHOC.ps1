<#

Background info on issues with parameters I ran into

Official MySQL documentation on mysqldump: https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html

Why --defaults-extra-file option needs to be first: https://stackoverflow.com/questions/3836214/problem-with-mysqldump-defaults-extra-file-option-is-not-working-as-expecte

Avoid gtid errors when restoring to another database: https://superuser.com/questions/906843/import-mysql-data-failed-with-error-1839

Description:
The following script runs mysqldump with necessary parameters to generate a dump, gzip the file, and upload to an s3 bucket.
#>

#Credentials for backup user

$user = "svc_backup"

$mysqlpassword = "path\to\.my.cnf"



# Setup alias for 7zip for easy gziping

$7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"

Set-Alias Compress-7Zip $7ZipPath



#Location of mysqldump and backup destination

$mysqldumpLocation = "\path\to\mysqldump.exe"

$backupDest = "path\to\dumps\$($database)"



#Use for testing script

$serverlist = @(

@{

hostname = ""

databases = @(

""

)

}

)


#Script to run mysqldump and gzip for each database instance(and db) that are mentioned in the Array(s) above)

foreach ($server in $serverlist) {

foreach ($database in $server.databases){

#write logging, in case we automate this in some task scheduler

Start-Transcript "path\to\logs\mysqldump\env\$("env"+$date+$server.hostname).log" -Append

Write-Host "Running backup for $database"

#Set dump location

$dumpfile = "path\to\dumps\$($database).sql"



#Check if file is already there, if so delete.

if(Test-Path $dumpfile){

Remove-Item $dumpfile

Write-Host "$dumpfile removed"

}else{

Write-Host "$dumpfile does not exist. Proceeding"

}

#Execute pg_dump with parameters

.\mysqldump.exe --defaults-file=$mysqlpassword -u $user -h $server.hostname -B $database --set-gtid-purged=OFF --result-file=$dumpfile


#Variables for 7zip

$Source = $dumpfile

#Check if file is already there, if so delete

$Destination = "path\to\gzip\$($database).gz"

if(Test-Path $Destination){

Remove-Item $Destination

Write-Host "$Destination removed"

}else{

Write-Host "$Destination does not exist. Proceeding"

}

#Compress to gzip at highest compression

Compress-7zip a -mx=5 $Destination $Source


Stop-Transcript

}

}

#Upload to s3 bucket

aws s3 cp \path\to\dumps s3://s3bucket --recursive