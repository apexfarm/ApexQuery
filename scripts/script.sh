# force:package:create only execute for the first time
# sfdx force:package:create -n ApexQuery -t Unlocked -r apex-query
sfdx force:package:version:create -p ApexQuery -x -c --wait 10 --code-coverage
sfdx force:package:version:list
sfdx force:package:version:promote -p 04tGC000007TORgYAO
sfdx force:package:version:report -p 04tGC000007TORgYAO