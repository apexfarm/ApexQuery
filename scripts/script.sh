# force:package:create only execute for the first time
# sfdx force:package:create -n ApexQuery -t Unlocked -r apex-query
sfdx force:package:version:create -p ApexQuery -x -c --wait 10 --codecoverage
sfdx force:package:version:list
sfdx force:package:version:promote -p 04t2v000007Cg2zAAC
sfdx force:package:version:report -p 04t2v000007Cg2zAAC

