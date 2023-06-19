# Config file

**Documentation**

* [workflow config file guide](https://docs.nextstrain.org/projects/ncov/en/latest/guides/workflow-config-file.html)
* [workflow config file reference](https://docs.nextstrain.org/projects/ncov/en/latest/reference/workflow-config-file.html)

## 1. The most basic config file

Given a `sequences.fasta` and `metadata.tsv` file pair, a nextstrain config file may look like:

```
inputs:
  - name: nameofdataset
    metadata: metadata.tsv
    sequences: sequences.fasta
```

Or if we have an array of sequences and metadata files

```
inputs
  - name: washington
    metadata: metadata_wa.tsv
    sequences: sequences_wa.fasta
  - name: idaho
    metadata: metadata_id.tsv
    sequences: sequences_id.tsv
```

## 2. Decide to include all or no subsampling

Add a subsampling scheme if necessary. By default, the data is subsampled down but can be turned off by adding the following to config.yaml. This has been pulled from the [default_config.yaml](https://github.com/nextstrain/ncov/blob/8ac72893adab0162476a4c88e1d6393ff217b6fd/defaults/parameters.yaml#LL205C1-L209C27)

```
subsampling:
  all:
    all:
      no_subsampling: true
```

## 3. Subsampling schemes by dataset

Pull examples from [here](https://github.com/nextstrain/ncov/blob/8ac72893adab0162476a4c88e1d6393ff217b6fd/defaults/parameters.yaml#L211-L327)



