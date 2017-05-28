# flow-GFE
Run fasta files through GFE with nextflow

## Deploy AWS Cluster

```bash
# nextflow.config
cloud {
    imageId = 'ami-f34507e5'
    instanceType = 'm4.xlarge'
    userName = 'your_username'
    keyName = 'your_keyname'
}

# create config
sh config.sh

# installation and cluster setup
curl -fsSL get.nextflow.io | bash
./nextflow cloud create gfe-cluster -c 3
ssh -i ~/.ssh/your_keyname your_username@ip.returned.above.step
```
I recommend using the **ami-f34507e5** image because it was specifically built for running this process. You can change or remove the autoscale properties depending on the resources you require. For more information on this configuration please refer to the [nextflow documentation](https://www.nextflow.io/docs/latest/awscloud.html).

### Usage
```bash
./nextflow run nmdp-bioinformatics/flow-GFE \
    --fasta /location/of/fasta/files --outfile typing_results.txt
```
Running this will pull down this repository and run the main.nf nextflow script. 

### Nextflow Reference
Di Tommaso, P., Chatzou, M., Floden, E. W., Barja, P. P., Palumbo, E., & Notredame, C. (2017). Nextflow enables reproducible computational workflows. Nat Biotech, 35(4), 316–319. 