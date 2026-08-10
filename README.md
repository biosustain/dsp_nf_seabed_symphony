# Dataset used for testing
Installed from Zenodo repository:

```bash
wget -O all.fastq.gz "https://zenodo.org/record/7995806/files/guppy_basecalled.fastq.gz?download=1"
```

Subset using `seqkit`:

```bash
seqkit sample -n 500000 -s 42 all.fastq.gz -o subsample.fastq.gz
```

# Raw reads QC: nanoplot

