# flow-GFE
Run fasta files through GFE with nextflow

## Deploy AWS Cluster

```bash
# nextflow.config
cloud {
    imageId = 'ami-d1f9a6aa'
    instanceType = 'm4.xlarge'
    userName = 'ec2-user'
    keyName = 'your_keyname'
    securityGroup = 'sg-yoursgid'
    sharedStorageId = 'fs-yourfsid'
    subnetId = 'subnet-yoursubnetid'
}

# create config
sh config.sh

# installation and cluster setup
curl -fsSL get.nextflow.io | bash
./nextflow cloud create gfe-cluster -c 3
ssh -i ~/.ssh/your_keyname your_username@ip.returned.above.step
```
I recommend using the **ami-d1f9a6aa** image because it was specifically built for running this process. You can change or remove the autoscale properties depending on the resources you require. For more information on this configuration please refer to the [nextflow documentation](https://www.nextflow.io/docs/latest/awscloud.html).

### Usage
```bash
./nextflow run nmdp-bioinformatics/flow-GFE \
 	-with-docker nmdpbioinformatics/service-gfe-submission \
    --input s3://bucket/data/directory --outfile typing_results.txt \
    --type xml
```
Running this will pull down this repository and run the main.nf nextflow script. 

### Nextflow Reference
Di Tommaso, P., Chatzou, M., Floden, E. W., Barja, P. P., Palumbo, E., & Notredame, C. (2017). Nextflow enables reproducible computational workflows. Nat Biotech, 35(4), 316–319. 